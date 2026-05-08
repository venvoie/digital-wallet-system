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
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack) LoadCurrentBalance();
		}

		private void LoadCurrentBalance()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (var conn = new SqlConnection(connStr))
			using (var cmd = new SqlCommand("SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID", conn))
			{
				cmd.Parameters.AddWithValue("@UserID", userID);
				conn.Open();
				object result = cmd.ExecuteScalar();

				// default to 0.00 if no wallet record exists
				lblCurrentBalance.Text = (result != null ? Convert.ToDecimal(result) : 0).ToString("N2");
			}
		}

		// step 1: looks up the recipient account and populates the verified panel
		protected void btnVerify_Click(object sender, EventArgs e)
		{
			// clear previous alerts and hide recipient panel before re-verifying
			pnlError.Visible = pnlSuccess.Visible = pnlRecipient.Visible = false;

			string recipientAccount = txtRecipientAccount.Text.Trim();
			if (string.IsNullOrEmpty(recipientAccount)) { ShowError("Please enter a recipient account number."); return; }
			if (recipientAccount == Session["AccountNumber"].ToString()) { ShowError("You cannot send CloudMoney to your own account."); return; }

			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			// look up an active user matching the entered account number
			string sql = @"SELECT UserID, FullName, AccountNumber
                           FROM   Users
                           WHERE  AccountNumber = @AccountNumber AND IsActive = 1";

			using (var conn = new SqlConnection(connStr))
			using (var cmd = new SqlCommand(sql, conn))
			{
				cmd.Parameters.AddWithValue("@AccountNumber", recipientAccount);
				conn.Open();

				using (var dr = cmd.ExecuteReader())
				{
					if (dr.Read())
					{
						// populate the recipient panel with the found user's info
						lblRecipientName.Text = dr["FullName"].ToString();
						lblRecipientAccountNo.Text = dr["AccountNumber"].ToString();
						hfRecipientUserID.Value = dr["UserID"].ToString();
						pnlRecipient.Visible = true;
					}
					else
					{
						ShowError("Account number not found or is inactive. Please check and try again.");
					}
				}
			}
		}

		// step 2: processes the money transfer after the user confirms via the modal
		protected void btnSend_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// parse and validate the entered amount
			if (!decimal.TryParse(txtAmount.Text.Trim(), out decimal amount)) { ShowError("Please enter a valid amount."); return; }
			if (amount < 100) { ShowError("Minimum send amount is ₱100.00."); return; }
			if (amount > 2000) { ShowError("Maximum send amount per transaction is ₱2,000.00."); return; }
			if (amount % 100 != 0) { ShowError("Amount must be divisible by ₱100.00 (e.g. 100, 200, 500, 1000)."); return; }
			if (string.IsNullOrEmpty(hfRecipientUserID.Value)) { ShowError("Please verify the recipient account number first."); return; }

			int senderID = Convert.ToInt32(Session["UserID"]);
			int recipientID = Convert.ToInt32(hfRecipientUserID.Value);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (var conn = new SqlConnection(connStr))
			{
				conn.Open();

				// verify the sender's password using the hidden field value
				using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Users WHERE UserID = @UserID AND PasswordHash = @Hash", conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.Parameters.AddWithValue("@Hash", HashPassword(hfPassword.Value));
					if ((int)cmd.ExecuteScalar() == 0) { ShowError("Incorrect password. Transaction cancelled for security."); return; }
				}

				// retrieve the sender's current balance
				decimal senderBalance;
				using (var cmd = new SqlCommand("SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID", conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					senderBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				// reject if insufficient funds
				if (amount > senderBalance) { ShowError($"Insufficient funds. Your current balance is ₱{senderBalance:N2}."); LoadCurrentBalance(); return; }

				// retrieve the recipient's current balance
				decimal recipientBalance;
				using (var cmd = new SqlCommand("SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID", conn))
				{
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					recipientBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				decimal senderNewBalance = senderBalance - amount;
				decimal recipientNewBalance = recipientBalance + amount;

				// insert a send transaction record (type 'S') for the sender
				string sqlSendTxn = @"INSERT INTO Transactions (UserID, TransactionType, Amount, BalanceAfter, SentToUserID, TransactionDate, Remarks)
                                      VALUES (@UserID, 'S', @Amount, @BalanceAfter, @SentToUserID, GETDATE(), 'Send CloudMoney')";

				using (var cmd = new SqlCommand(sqlSendTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", senderNewBalance);
					cmd.Parameters.AddWithValue("@SentToUserID", recipientID);
					cmd.ExecuteNonQuery();
				}

				// insert a receive transaction record (type 'R') for the recipient
				string sqlRecvTxn = @"INSERT INTO Transactions (UserID, TransactionType, Amount, BalanceAfter, ReceivedFromUserID, TransactionDate, Remarks)
                                      VALUES (@UserID, 'R', @Amount, @BalanceAfter, @ReceivedFromUserID, GETDATE(), 'Received CloudMoney')";

				using (var cmd = new SqlCommand(sqlRecvTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", recipientNewBalance);
					cmd.Parameters.AddWithValue("@ReceivedFromUserID", senderID);
					cmd.ExecuteNonQuery();
				}

				// update sender's wallet: deduct amount and increment total sent
				string sqlUpdateSender = @"UPDATE Wallets
                                           SET CurrentBalance = @NewBalance, TotalSentAmount = TotalSentAmount + @Amount, LastUpdated = GETDATE()
                                           WHERE UserID = @UserID";

				using (var cmd = new SqlCommand(sqlUpdateSender, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", senderNewBalance);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@UserID", senderID);
					cmd.ExecuteNonQuery();
				}

				// update recipient's wallet: add the received amount
				string sqlUpdateRecip = @"UPDATE Wallets SET CurrentBalance = @NewBalance, LastUpdated = GETDATE()
                                          WHERE UserID = @UserID";

				using (var cmd = new SqlCommand(sqlUpdateRecip, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", recipientNewBalance);
					cmd.Parameters.AddWithValue("@UserID", recipientID);
					cmd.ExecuteNonQuery();
				}
			}

			// save recipient name before clearing the form
			string recipientName = lblRecipientName.Text;

			// clear all inputs and hide the recipient panel
			txtAmount.Text = "";
			txtPassword.Text = "";
			txtRecipientAccount.Text = "";
			hfRecipientUserID.Value = "";
			hfPassword.Value = "";
			pnlRecipient.Visible = false;

			LoadCurrentBalance();
			ShowSuccess($"Successfully sent ₱{amount:N2} to {recipientName}!");
		}

		// shows the error alert 
		private void ShowError(string message)
		{
			pnlError.Visible = true; pnlSuccess.Visible = false;
			lblError.Text = message;
		}

		// shows the success alert 
		private void ShowSuccess(string message)
		{
			pnlSuccess.Visible = true; pnlError.Visible = false;
			lblSuccess.Text = message;
		}

		// returns a sha256 hex hash of the given password
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
	}
}