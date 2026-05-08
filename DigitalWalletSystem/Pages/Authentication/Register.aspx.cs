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
		// ── page load — skip registration if the user is already logged in ──
		protected void Page_Load(object sender, EventArgs e)
		{
			// redirect straight to dashboard if a valid session already exists
			if (Session["UserID"] != null)
				Response.Redirect("~/Pages/Main/Dashboard.aspx");
		}

		// ── handles the create account button click ──
		protected void btnRegister_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// user must accept the terms and conditions before registering
			if (!chkTerms.Checked)
			{
				ShowError("You must agree to the Terms and Conditions to register.");
				return;
			}

			// build the full name from first and last name inputs
			string firstName = txtFirstName.Text.Trim();
			string lastName = txtLastName.Text.Trim();
			string fullName = firstName + " " + lastName;
			string email = txtEmail.Text.Trim();
			string username = txtUsername.Text.Trim();
			string password = txtPassword.Text;

			// hash the password before storing — never saved as plain text
			string passHash = HashPassword(password);

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// reject registration if the email is already in use
				if (EmailExists(email, conn))
				{
					ShowError("That email address is already registered.");
					return;
				}

				// reject registration if the username is already taken
				if (UsernameExists(username, conn))
				{
					ShowError("That username is already taken. Please choose another.");
					return;
				}

				// generate a unique 10-digit account number for the new user
				string accountNumber = GenerateAccountNumber(conn);

				// insert the new user record and retrieve the generated userid
				string insertUser = @"
                    INSERT INTO Users
                        (AccountNumber, FullName, Username, PasswordHash, Email, DateRegistered, IsActive)
                    OUTPUT INSERTED.UserID
                    VALUES
                        (@AccountNumber, @FullName, @Username, @PasswordHash, @Email, GETDATE(), 1)";

				int newUserID;
				using (SqlCommand cmd = new SqlCommand(insertUser, conn))
				{
					cmd.Parameters.AddWithValue("@AccountNumber", accountNumber);
					cmd.Parameters.AddWithValue("@FullName", fullName);
					cmd.Parameters.AddWithValue("@Username", username);
					cmd.Parameters.AddWithValue("@PasswordHash", passHash);
					cmd.Parameters.AddWithValue("@Email", email);

					newUserID = (int)cmd.ExecuteScalar();
				}

				// create an empty wallet record for the new user starting at zero balance
				string insertWallet = @"
                    INSERT INTO Wallets (UserID, CurrentBalance, TotalSentAmount, LastUpdated)
                    VALUES (@UserID, 0.00, 0.00, GETDATE())";

				using (SqlCommand cmd = new SqlCommand(insertWallet, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", newUserID);
					cmd.ExecuteNonQuery();
				}

				// write a registration entry to the audit log
				LogAudit(newUserID, "REGISTER", conn);
			}

			// trigger the success overlay and redirect via javascript
			ScriptManager.RegisterStartupScript(this, GetType(),
				"successPopup", "showSuccessAndRedirect();", true);
		}

		// ── returns true if the email is already registered ──
		private bool EmailExists(string email, SqlConnection conn)
		{
			using (SqlCommand cmd = new SqlCommand(
				"SELECT COUNT(1) FROM Users WHERE Email = @Email", conn))
			{
				cmd.Parameters.AddWithValue("@Email", email);
				return (int)cmd.ExecuteScalar() > 0;
			}
		}

		// ── returns true if the username is already taken ──
		private bool UsernameExists(string username, SqlConnection conn)
		{
			using (SqlCommand cmd = new SqlCommand(
				"SELECT COUNT(1) FROM Users WHERE Username = @Username", conn))
			{
				cmd.Parameters.AddWithValue("@Username", username);
				return (int)cmd.ExecuteScalar() > 0;
			}
		}

		// ── generates a unique 10-digit account number not already in the database ──
		private string GenerateAccountNumber(SqlConnection conn)
		{
			Random rng = new Random();
			string accountNumber;
			bool exists;

			// keep generating random numbers until a unique one is found
			do
			{
				accountNumber = rng.Next(1000000000, 2000000000).ToString();
				using (SqlCommand cmd = new SqlCommand(
					"SELECT COUNT(1) FROM Users WHERE AccountNumber = @AN", conn))
				{
					cmd.Parameters.AddWithValue("@AN", accountNumber);
					exists = (int)cmd.ExecuteScalar() > 0;
				}
			} while (exists);

			return accountNumber;
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
			catch { /* audit log failure should not break the registration flow */ }
		}
	}
}