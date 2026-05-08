using System;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Main
{
	public partial class Withdraw : Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack) LoadCurrentBalance();
		}

		private void LoadCurrentBalance()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID";
				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					conn.Open();
					object result = cmd.ExecuteScalar();

					// default to 0.00 if no wallet record exists
					lblCurrentBalance.Text = (result != null ? Convert.ToDecimal(result) : 0).ToString("N2");
				}
			}
		}

		protected void btnWithdraw_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// parse and validate the entered amount
			if (!decimal.TryParse(txtAmount.Text.Trim(), out decimal amount)) { ShowError("Please enter a valid amount."); return; }
			if (amount < 100) { ShowError("Minimum withdrawal amount is ₱100.00."); return; }
			if (amount > 2000) { ShowError("Maximum withdrawal amount per transaction is ₱2,000.00."); return; }
			if (amount % 100 != 0) { ShowError("Amount must be divisible by ₱100.00 (e.g. 100, 200, 500, 1000)."); return; }

			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// get current balance before applying the withdrawal
				decimal currentBalance;
				using (SqlCommand cmd = new SqlCommand("SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID", conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					currentBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				// reject if insufficient funds
				if (amount > currentBalance)
				{
					ShowError($"Insufficient funds. Your current balance is ₱{currentBalance:N2}.");
					LoadCurrentBalance();
					return;
				}

				decimal newBalance = currentBalance - amount;

				// insert a withdrawal transaction record
				string sqlTxn = @"
                    INSERT INTO Transactions (UserID, TransactionType, Amount, BalanceAfter, TransactionDate, Remarks)
                    VALUES (@UserID, 'W', @Amount, @BalanceAfter, GETDATE(), 'Withdrawal')";

				using (SqlCommand cmd = new SqlCommand(sqlTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", newBalance);
					cmd.ExecuteNonQuery();
				}

				// update the wallet with the new balance and timestamp
				string sqlWallet = @"
                    UPDATE Wallets SET CurrentBalance = @NewBalance, LastUpdated = GETDATE()
                    WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlWallet, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", newBalance);
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.ExecuteNonQuery();
				}
			}

			// clear input, refresh balance, show success
			txtAmount.Text = "";
			LoadCurrentBalance();
			ShowSuccess($"Successfully withdrew ₱{amount:N2} from your account!");
		}

		// shows error alert 
		private void ShowError(string message)
		{
			pnlError.Visible = true; pnlSuccess.Visible = false;
			lblError.Text = message;
		}

		// shows success alert 
		private void ShowSuccess(string message)
		{
			pnlSuccess.Visible = true; pnlError.Visible = false;
			lblSuccess.Text = message;
		}
	}
}