using System;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Authentication
{
	public partial class Login : Page
	{
		// ── page load — skip login screen if the user is already in a session ──
		protected void Page_Load(object sender, EventArgs e)
		{
			// redirect straight to dashboard if a valid session already exists
			if (Session["UserID"] != null)
				Response.Redirect("~/Pages/Main/Dashboard.aspx");
		}

		// ── handles the sign in button click ──
		protected void btnLogin_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			string accountNumber = txtAccountNumber.Text.Trim();
			string password = txtPassword.Text;

			// hash the entered password before comparing against the stored hash
			string passwordHash = HashPassword(password);

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// look up a user matching the account number and hashed password
				string sql = @"
                    SELECT u.UserID, u.FullName, u.AccountNumber, u.Username, u.IsActive
                    FROM   Users u
                    WHERE  u.AccountNumber = @AccountNumber
                    AND    u.PasswordHash  = @PasswordHash";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@AccountNumber", accountNumber);
					cmd.Parameters.AddWithValue("@PasswordHash", passwordHash);

					conn.Open();
					SqlDataReader reader = cmd.ExecuteReader();

					if (reader.Read())
					{
						// reject login if the account has been deactivated
						if (!Convert.ToBoolean(reader["IsActive"]))
						{
							ShowError("Your account has been deactivated. Please contact support.");
							return;
						}

						// store user details in session for use across all pages
						Session["UserID"] = reader["UserID"].ToString();
						Session["FullName"] = reader["FullName"].ToString();
						Session["AccountNumber"] = reader["AccountNumber"].ToString();
						Session["Username"] = reader["Username"].ToString();

						// close the reader before reusing the connection for the audit log
						reader.Close();

						// write a login entry to the audit log
						LogAudit(Convert.ToInt32(Session["UserID"]), "LOGIN", conn);

						Response.Redirect("~/Pages/Main/Dashboard.aspx");
					}
					else
					{
						// credentials did not match any active user
						ShowError("Invalid account number or password. Please try again.");
					}
				}
			}
		}

		// ── shows the error alert with the given message ──
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			lblError.Text = message;
		}

		// ── returns a sha256 hex hash of the given plain-text password ──
		private string HashPassword(string password)
		{
			using (SHA256 sha256 = SHA256.Create())
			{
				byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
				StringBuilder sb = new StringBuilder();

				// convert each byte to a two-character hex string
				foreach (byte b in bytes)
					sb.Append(b.ToString("x2"));

				return sb.ToString();
			}
		}

		// ── inserts a row into the audit log; silently ignores failures ──
		private void LogAudit(int userID, string action, SqlConnection conn)
		{
			try
			{
				string ip = Request.UserHostAddress;
				string sql = "INSERT INTO AuditLog (UserID, Action, ActionDate, IPAddress) VALUES (@UserID, @Action, GETDATE(), @IP)";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					// reopen the connection if it was closed after the reader finished
					if (conn.State != ConnectionState.Open) conn.Open();

					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@Action", action);
					cmd.Parameters.AddWithValue("@IP", ip ?? "unknown");
					cmd.ExecuteNonQuery();
				}
			}
			catch { /* audit log failure should not break the login flow */ }
		}
	}
}