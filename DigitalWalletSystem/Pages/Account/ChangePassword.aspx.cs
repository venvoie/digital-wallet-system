using System;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Account
{
	public partial class ChangePassword : Page
	{
		protected void Page_Load(object sender, EventArgs e) { }

		protected void btnChangePassword_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			int userID = Convert.ToInt32(Session["UserID"]);
			string currentHash = HashPassword(txtCurrentPassword.Text);
			string newHash = HashPassword(txtNewPassword.Text);

			// new password must differ from the current one
			if (currentHash == newHash)
			{
				ShowError("Your new password must be different from your current password.");
				return;
			}

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (var conn = new SqlConnection(connStr))
			{
				conn.Open();

				// verify the entered current password matches the stored hash
				string sqlCheck = @"SELECT COUNT(1) FROM Users
                                    WHERE UserID = @UserID AND PasswordHash = @CurrentHash";

				using (var cmd = new SqlCommand(sqlCheck, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@CurrentHash", currentHash);

					if ((int)cmd.ExecuteScalar() == 0)
					{
						ShowError("Your current password is incorrect. Please try again.");
						return;
					}
				}

				// update the stored password hash
				string sqlUpdate = @"UPDATE Users SET PasswordHash = @NewHash WHERE UserID = @UserID";

				using (var cmd = new SqlCommand(sqlUpdate, conn))
				{
					cmd.Parameters.AddWithValue("@NewHash", newHash);
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.ExecuteNonQuery();
				}

				// log the password change to the audit table
				LogAudit(userID, "CHANGE_PASSWORD", conn);
			}

			// clear all fields after a successful update
			txtCurrentPassword.Text = "";
			txtNewPassword.Text = "";
			txtConfirmPassword.Text = "";

			ShowSuccess("Your password has been updated successfully!");
		}

		// shows the error alert and hides the success alert
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			pnlSuccess.Visible = false;
			lblError.Text = message;
		}

		// shows the success alert and hides the error alert
		private void ShowSuccess(string message)
		{
			pnlSuccess.Visible = true;
			pnlError.Visible = false;
			lblSuccess.Text = message;
		}

		// returns a sha256 hex hash of the given plain-text password
		private string HashPassword(string password)
		{
			using (var sha256 = SHA256.Create())
			{
				byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
				StringBuilder sb = new StringBuilder();
				foreach (byte b in bytes) sb.Append(b.ToString("x2"));
				return sb.ToString();
			}
		}

		// inserts a row into the audit log — silently ignores failures
		private void LogAudit(int userID, string action, SqlConnection conn)
		{
			try
			{
				string sql = @"INSERT INTO AuditLog (UserID, Action, ActionDate, IPAddress)
                               VALUES (@UserID, @Action, GETDATE(), @IP)";

				using (var cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@Action", action);
					cmd.Parameters.AddWithValue("@IP", Request.UserHostAddress ?? "unknown");
					cmd.ExecuteNonQuery();
				}
			}
			catch {  }
		}
	}
}