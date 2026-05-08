using System;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Main
{
	public partial class Withdraw : Page
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

		// handles the withdraw button click after user confirms via the modal
		protected void btnWithdraw_Click(object sender, EventArgs e)
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

			// enforce minimum withdrawal rule
			if (amount < 100)
			{
				ShowError("Minimum withdrawal amount is ₱100.00.");
				return;
			}

			// enforce maximum withdrawal per transaction
			if (amount > 2000)
			{
				ShowError("Maximum withdrawal amount per transaction is ₱2,000.00.");
				return;
			}

			// amount must be a clean multiple of 100
			if (amount % 100 != 0)
			{
				ShowError("Amount must be divisible by ₱100.00 (e.g. 100, 200, 500, 1000).");
				return;
			}

			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// retrieve the user's current balance before applying the withdrawal
				decimal currentBalance;
				string sqlBalance = "SELECT CurrentBalance FROM Wallets WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlBalance, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					currentBalance = Convert.ToDecimal(cmd.ExecuteScalar());
				}

				// check that the user has enough funds to cover the withdrawal
				if (amount > currentBalance)
				{
					ShowError($"Insufficient funds. Your current balance is ₱{currentBalance:N2}.");
					LoadCurrentBalance();
					return;
				}

				// compute the new balance after deducting the withdrawal
				decimal newBalance = currentBalance - amount;

				// insert a new transaction record with type 'W' for withdrawal
				string sqlTxn = @"
                    INSERT INTO Transactions
                        (UserID, TransactionType, Amount, BalanceAfter, TransactionDate, Remarks)
                    VALUES
                        (@UserID, 'W', @Amount, @BalanceAfter, GETDATE(), 'Withdrawal')";

				using (SqlCommand cmd = new SqlCommand(sqlTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@Amount", amount);
					cmd.Parameters.AddWithValue("@BalanceAfter", newBalance);
					cmd.ExecuteNonQuery();
				}

				// update the wallet table with the new balance and timestamp
				string sqlWallet = @"
                    UPDATE Wallets
                    SET    CurrentBalance = @NewBalance,
                           LastUpdated   = GETDATE()
                    WHERE  UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlWallet, conn))
				{
					cmd.Parameters.AddWithValue("@NewBalance", newBalance);
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.ExecuteNonQuery();
				}
			}

			// clear the input, refresh the balance display, and show success
			txtAmount.Text = "";
			LoadCurrentBalance();
			ShowSuccess($"Successfully withdrew ₱{amount:N2} from your account!");
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
	}
}