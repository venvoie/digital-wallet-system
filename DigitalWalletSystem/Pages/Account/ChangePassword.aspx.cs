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
		// ── page load — no data to fetch, master page handles the topbar ──
		protected void Page_Load(object sender, EventArgs e)
		{
		}

		// ── handles the update password button click ──
		protected void btnChangePassword_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			int userID = Convert.ToInt32(Session["UserID"]);
			string currentPassword = txtCurrentPassword.Text;
			string newPassword = txtNewPassword.Text;
			string currentHash = HashPassword(currentPassword);
			string newHash = HashPassword(newPassword);

			// new password must be different from the current one
			if (currentHash == newHash)
			{
				ShowError("Your new password must be different from your current password.");
				return;
			}

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// verify that the entered current password matches the stored hash
				string sqlCheck = @"
                    SELECT COUNT(1)
                    FROM   Users
                    WHERE  UserID       = @UserID
                    AND    PasswordHash = @CurrentHash";

				using (SqlCommand cmd = new SqlCommand(sqlCheck, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@CurrentHash", currentHash);

					int match = (int)cmd.ExecuteScalar();
					if (match == 0)
					{
						ShowError("Your current password is incorrect. Please try again.");
						return;
					}
				}

				// update the password hash in the database
				string sqlUpdate = @"
                    UPDATE Users
                    SET    PasswordHash = @NewHash
                    WHERE  UserID       = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlUpdate, conn))
				{
					cmd.Parameters.AddWithValue("@NewHash", newHash);
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.ExecuteNonQuery();
				}

				// write a change password entry to the audit log
				LogAudit(userID, "CHANGE_PASSWORD", conn);
			}

			// clear all password fields after a successful update
			txtCurrentPassword.Text = "";
			txtNewPassword.Text = "";
			txtConfirmPassword.Text = "";

			ShowSuccess("Your password has been updated successfully!");
		}

		// ── shows the error alert and hides the success alert ──
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			pnlSuccess.Visible = false;
			lblError.Text = message;
		}

		// ── shows the success alert and hides the error alert ──
		private void ShowSuccess(string message)
		{
			pnlSuccess.Visible = true;
			pnlError.Visible = false;
			lblSuccess.Text = message;
		}

		// ── returns a sha256 hex hash of the given plain-text password ──
		private string HashPassword(string password)
		{
			using (SHA256 sha256 = SHA256.Create())
			{
				byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
				StringBuilder sb = new StringBuilder();
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
			catch { /* audit failure should not break the page */ }
		}
	}
}