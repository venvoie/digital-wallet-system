using System;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Authentication
{
	public partial class Logout : Page
	{
		// ── page load — skip the logout screen if no session exists ──
		protected void Page_Load(object sender, EventArgs e)
		{
			// redirect to login immediately if the user is not logged in
			if (Session["UserID"] == null)
				Response.Redirect("~/Pages/Authentication/Login.aspx");
		}

		// ── handles the confirm logout button click ──
		protected void btnLogout_Click(object sender, EventArgs e)
		{
			// write a logout entry to the audit log before clearing the session
			if (Session["UserID"] != null)
			{
				int userID = Convert.ToInt32(Session["UserID"]);
				LogAudit(userID, "LOGOUT");
			}

			// clear all session data and invalidate the session
			Session.Clear();
			Session.Abandon();

			// send the user back to the login page
			Response.Redirect("~/Pages/Authentication/Login.aspx");
		}

		// ── handles the cancel button click — returns to the dashboard ──
		protected void btnCancel_Click(object sender, EventArgs e)
		{
			Response.Redirect("~/Pages/Main/Dashboard.aspx");
		}

		// ── inserts a row into the audit log; silently ignores failures ──
		private void LogAudit(int userID, string action)
		{
			try
			{
				string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

				using (SqlConnection conn = new SqlConnection(connStr))
				{
					conn.Open();

					string sql = @"
                        INSERT INTO AuditLog (UserID, Action, ActionDate, IPAddress)
                        VALUES (@UserID, @Action, GETDATE(), @IP)";

					using (SqlCommand cmd = new SqlCommand(sql, conn))
					{
						cmd.Parameters.AddWithValue("@UserID", userID);
						cmd.Parameters.AddWithValue("@Action", action);
						cmd.Parameters.AddWithValue("@IP", Request.UserHostAddress ?? "unknown");
						cmd.ExecuteNonQuery();
					}
				}
			}
			catch { /* audit log failure should not break the logout flow */ }
		}
	}
}