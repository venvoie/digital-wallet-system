using System;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Authentication
{
	public partial class Register : Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			if (Session["UserID"] != null)
				Response.Redirect("~/Pages/Main/Dashboard.aspx");
		}

		protected void btnRegister_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// terms checkbox must be ticked before proceeding
			if (!chkTerms.Checked)
			{
				ShowError("You must agree to the Terms and Conditions to register.");
				return;
			}

			string fullName = txtFirstName.Text.Trim() + " " + txtLastName.Text.Trim();
			string email = txtEmail.Text.Trim();
			string username = txtUsername.Text.Trim();
			string plainPassword = txtPassword.Text;
			string passHash = HashPassword(plainPassword);

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (var conn = new SqlConnection(connStr))
			{
				conn.Open();

				// block duplicate email or username before inserting
				if (EmailExists(email, conn)) { ShowError("That email address is already registered."); return; }
				if (UsernameExists(username, conn)) { ShowError("That username is already taken. Please choose another."); return; }

				// generate a collision-free 10-digit account number
				string accountNumber = GenerateAccountNumber(conn);

				// insert the new user record and get the auto-generated UserID
				string insertUser = @"INSERT INTO Users
                                          (AccountNumber, FullName, Username, PasswordHash, Email, DateRegistered, IsActive)
                                      OUTPUT INSERTED.UserID
                                      VALUES (@AccountNumber, @FullName, @Username, @PasswordHash, @Email, GETDATE(), 1)";

				int newUserID;
				using (var cmd = new SqlCommand(insertUser, conn))
				{
					cmd.Parameters.AddWithValue("@AccountNumber", accountNumber);
					cmd.Parameters.AddWithValue("@FullName", fullName);
					cmd.Parameters.AddWithValue("@Username", username);
					cmd.Parameters.AddWithValue("@PasswordHash", passHash);
					cmd.Parameters.AddWithValue("@Email", email);
					newUserID = (int)cmd.ExecuteScalar();
				}

				// create the wallet record with zero starting balance
				string insertWallet = @"INSERT INTO Wallets (UserID, CurrentBalance, TotalSentAmount, LastUpdated)
                                        VALUES (@UserID, 0.00, 0.00, GETDATE())";

				using (var cmd = new SqlCommand(insertWallet, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", newUserID);
					cmd.ExecuteNonQuery();
				}

				// write a REGISTER entry to the audit log
				LogAudit(newUserID, "REGISTER", conn);

				// bake credentials directly into the JS call so the postback cannot wipe them
				string script = string.Format(
					"showSuccessAndRedirect('{0}', '{1}', '{2}', '{3}');",
					accountNumber,
					fullName.Replace("'", "\\'"),
					username,
					plainPassword.Replace("'", "\\'")
				);

				ScriptManager.RegisterStartupScript(this, GetType(), "successPopup", script, true);
			}
		}

		// returns true if the email is already in the Users table
		private bool EmailExists(string email, SqlConnection conn)
		{
			using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE Email = @Email", conn))
			{
				cmd.Parameters.AddWithValue("@Email", email);
				return (int)cmd.ExecuteScalar() > 0;
			}
		}

		// returns true if the username is already in the Users table
		private bool UsernameExists(string username, SqlConnection conn)
		{
			using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE Username = @Username", conn))
			{
				cmd.Parameters.AddWithValue("@Username", username);
				return (int)cmd.ExecuteScalar() > 0;
			}
		}

		// loops until it finds a 10-digit account number not already used
		private string GenerateAccountNumber(SqlConnection conn)
		{
			var rng = new Random();
			string accountNumber;
			bool exists;

			do
			{
				accountNumber = rng.Next(1000000000, 2000000000).ToString();
				using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE AccountNumber = @AN", conn))
				{
					cmd.Parameters.AddWithValue("@AN", accountNumber);
					exists = (int)cmd.ExecuteScalar() > 0;
				}
			} while (exists);

			return accountNumber;
		}

		// makes the error panel visible with the given message
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			lblError.Text = message;
		}

		// returns a SHA-256 hex hash of the plain-text password
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
			catch { }
		}
	}
}