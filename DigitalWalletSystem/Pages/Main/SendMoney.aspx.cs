using System;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Main
{
	public partial class SendMoney : Page
	{
		// page load — only fetch balance on first load, not on postbacks
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				LoadCurrentBalance();
			}
		}

		// fetches and displays the current wallet balance for the logged-in user
		private void LoadCurrentBalance()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// query only the balance column for this user
				string sql = "SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					conn.Open();

					object result = cmd.ExecuteScalar();

					// default to 0.00 if no wallet record exists
					decimal balance = result != null ? Convert.ToDecimal(result) : 0;
					lblCurrentBalance.Text = balance.ToString("N2");
				}
			}
		}

		// step 1: looks up the recipient account and populates the verified panel
		protected void btnVerify_Click(object sender, EventArgs e)
		{
			// clear previous alerts and hide recipient panel before re-verifying
			pnlError.Visible = false;
			pnlSuccess.Visible = false;
			pnlRecipient.Visible = false;

			string recipientAccount = txtRecipientAccount.Text.Trim();

			// recipient account number must not be empty
			if (string.IsNullOrEmpty(recipientAccount))
			{
				ShowError("Please enter a recipient account number.");
				return;
			}

			// prevent the user from sending money to themselves
			if (recipientAccount == Session["AccountNumber"].ToString())
			{
				ShowError("You cannot send CloudMoney to your own account.");
				return;
			}

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// look up an active user matching the entered account number
				string sql = @"
                    SELECT UserID, FullName, AccountNumber
                    FROM   Users
                    WHERE  AccountNumber = @AccountNumber
                    AND    IsActive      = 1";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@AccountNumber", recipientAccount);
					conn.Open();
					SqlDataReader dr = cmd.ExecuteReader();

					if (dr.Read())
					{
						// populate the recipient details panel with the found user's info
						lblRecipientName.Text = dr["FullName"].ToString();
						lblRecipientAccountNo.Text = dr["AccountNumber"].ToString();
						hfRecipientUserID.Value = dr["UserID"].ToString();
						pnlRecipient.Visible = true;
					}
					else
					{
						// account not found or deactivated
						ShowError("Account number not found or is inactive. Please check and try again.");
					}
				}
			}
		}

		// step 2: processes the money transfer after the user confirms via the modal
		protected void btnSend_Click(object sender, EventArgs e)
		{
			// stop if server-side validators fail
			if (!Page.IsValid) return;

			// parse the entered amount from the text box
			decimal amount;
			if (!decimal.TryParse(txtAmount.Text.Trim(), out amount))
			{
				ShowError("Please enter a valid amount.");
				return;
			}

			// enforce minimum send amount rule
			if (amount < 100)
			{
				ShowError("Minimum send amount is ₱100.00.");
				return;
			}

			// enforce maximum send amount per transaction
			if (amount > 2000)
			{
				ShowError("Maximum send amount per transaction is ₱2,000.00.");
				return;
			}

			// amount must be a clean multiple of 100
			if (amount % 100 != 0)
			{
				ShowError("Amount must be divisible by ₱100.00 (e.g. 100, 200, 500, 1000).");
				return;
			}

			// recipient must have been verified via step 1 before sending
			if (string.IsNullOrEmpty(hfRecipientUserID.Value))
			{
				ShowError("Please verify the recipient account number first.");
				return;
			}

			int senderID = Convert.ToInt32(Session["UserID"]);
			int recipientID = Convert.ToInt32(hfRecipientUserID.Value);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// hash the entered password and compare it against the stored hash
				string passwordHash = HashPassword(txtPassword.Text);
				string sqlCheckPw = @"
                    SELECT COUNT(1) FROM Users
                    WHERE  UserID = @UserID AND PasswordHash = @Hash";

				using (SqlCommand cmd = new SqlCommand(sqlCheckPw, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.Parameters.AddWithValue("@Hash", passwordHash);
					int match = (int)cmd.ExecuteScalar();

					// abort the transaction if the password does not match
					if (match == 0)
					{
						ShowError("Incorrect password. Transaction cancelled for security.");
						return;
					}
				}

				// retrieve the sender's current balance
				decimal senderBalance;
				string sqlSenderBal = "SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID";
				using (SqlCommand cmd = new SqlCommand(sqlSenderBal, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					senderBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				// check that the sender has enough funds to cover the transfer
				if (amount > senderBalance)
				{
					ShowError($"Insufficient funds. Your current balance is ₱{senderBalance:N2}.");
					LoadCurrentBalance();
					return;
				}

				// retrieve the recipient's current balance
				decimal recipientBalance;
				string sqlRecipBal = "SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID";
				using (SqlCommand cmd = new SqlCommand(sqlRecipBal, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					recipientBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				// compute new balances for both parties
				decimal senderNewBalance = senderBalance - amount;
				decimal recipientNewBalance = recipientBalance + amount;

				// insert a send transaction record (type 'S') for the sender
				string sqlSendTxn = @"
                    INSERT INTO Transactions
                        (UserID, TransactionType, Amount, BalanceAfter, SentToUserID, TransactionDate, Remarks)
                    VALUES
                        (@UserID, 'S', @Amount, @BalanceAfter, @SentToUserID, GETDATE(), 'Send CloudMoney')";

				using (SqlCommand cmd = new SqlCommand(sqlSendTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", senderNewBalance);
					cmd.Parameters.AddWithValue("@SentToUserID", recipientID);
					cmd.ExecuteNonQuery();
				}

				// insert a receive transaction record (type 'R') for the recipient
				string sqlRecvTxn = @"
                    INSERT INTO Transactions
                        (UserID, TransactionType, Amount, BalanceAfter, ReceivedFromUserID, TransactionDate, Remarks)
                    VALUES
                        (@UserID, 'R', @Amount, @BalanceAfter, @ReceivedFromUserID, GETDATE(), 'Received CloudMoney')";

				using (SqlCommand cmd = new SqlCommand(sqlRecvTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", recipientNewBalance);
					cmd.Parameters.AddWithValue("@ReceivedFromUserID", senderID);
					cmd.ExecuteNonQuery();
				}

				// update the sender's wallet: deduct amount and increment total sent
				string sqlUpdateSender = @"
                    UPDATE Wallets
                    SET    CurrentBalance  = @NewBalance,
                           TotalSentAmount = TotalSentAmount + @Amount,
                           LastUpdated     = GETDATE()
                    WHERE  UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlUpdateSender, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", senderNewBalance);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.ExecuteNonQuery();
				}

				// update the recipient's wallet: add the received amount
				string sqlUpdateRecip = @"
                    UPDATE Wallets
                    SET    CurrentBalance = @NewBalance,
                           LastUpdated   = GETDATE()
                    WHERE  UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlUpdateRecip, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", recipientNewBalance);
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					cmd.ExecuteNonQuery();
				}
			}

			// save the recipient name before resetting the form fields
			string recipientName = lblRecipientName.Text;

			// clear all form inputs and hide the recipient panel
			txtAmount.Text = "";
			txtPassword.Text = "";
			txtRecipientAccount.Text = "";
			hfRecipientUserID.Value = "";
			pnlRecipient.Visible = false;

			// refresh the balance display and show success message
			LoadCurrentBalance();
			ShowSuccess($"Successfully sent ₱{amount:N2} to {recipientName}!");
		}

		// displays an error alert and hides the success panel
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			pnlSuccess.Visible = false;
			lblError.Text = message;
		}

		// displays a success alert and hides the error panel
		private void ShowSuccess(string message)
		{
			pnlSuccess.Visible = true;
			pnlError.Visible = false;
			lblSuccess.Text = message;
		}

		// hashes the given password using sha256 and returns a hex string
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
	}
}