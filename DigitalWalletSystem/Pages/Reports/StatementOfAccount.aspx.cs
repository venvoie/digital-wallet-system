using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Reports
{
	public partial class StatementOfAccount : Page
	{
		// ── page load — auto-display all transactions from registration date to today ──
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				int userID = Convert.ToInt32(Session["UserID"]);
				string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

				// fetch the user's registration date from the database
				DateTime registeredDate = GetRegistrationDate(userID, connStr);

				// pre-fill the date fields with the registration date and today
				txtFrom.Text = registeredDate.ToString("yyyy-MM-dd");
				txtTo.Text = DateTime.Today.ToString("yyyy-MM-dd");

				// load all transactions using the registration date as the starting point
				LoadTransactions(userID, connStr, registeredDate, DateTime.Today);
			}
		}

		// ── list button — reloads based on user-selected date range ──
		protected void btnList_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// parse the from date
			DateTime fromDate, toDate;

			if (!DateTime.TryParse(txtFrom.Text, out fromDate))
			{
				ShowError("Please enter a valid From date.");
				return;
			}

			// parse the to date
			if (!DateTime.TryParse(txtTo.Text, out toDate))
			{
				ShowError("Please enter a valid To date.");
				return;
			}

			// from date must not be a future date
			if (fromDate.Date > DateTime.Today)
			{
				ShowError("From date must not be a future date.");
				return;
			}

			// to date must not be a future date
			if (toDate.Date > DateTime.Today)
			{
				ShowError("To date must not be a future date.");
				return;
			}

			// from date must be earlier than or equal to to date
			if (fromDate.Date > toDate.Date)
			{
				ShowError("From date must be earlier than or equal to the To date.");
				return;
			}

			pnlError.Visible = false;

			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			LoadTransactions(userID, connStr, fromDate, toDate);
		}

		// ── fetches the user's registration date from the users table ──
		private DateTime GetRegistrationDate(int userID, string connStr)
		{
			DateTime registeredDate = DateTime.Today;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "SELECT DateRegistered FROM Users WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					conn.Open();

					object result = cmd.ExecuteScalar();

					// use the fetched date if valid, otherwise fall back to today
					if (result != null && result != DBNull.Value)
						registeredDate = Convert.ToDateTime(result);
				}
			}

			return registeredDate;
		}

		// ── queries and displays transactions for the given date range ──
		private void LoadTransactions(int userID, string connStr, DateTime fromDate, DateTime toDate)
		{
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// extend to date to include the full day up to 23:59:59
				DateTime toDateEnd = toDate.Date.AddDays(1).AddSeconds(-1);

				string sql = @"
                    SELECT
                        t.TransactionType,
                        t.TransactionDate,
                        CASE WHEN t.TransactionType IN ('W','S') THEN t.Amount ELSE NULL END AS Debit,
                        CASE WHEN t.TransactionType IN ('D','R') THEN t.Amount ELSE NULL END AS Credit,
                        t.BalanceAfter,
                        su.AccountNumber AS SentToAccountNo,
                        ru.AccountNumber AS ReceivedFromAccountNo
                    FROM    Transactions t
                    LEFT JOIN Users su ON su.UserID = t.SentToUserID
                    LEFT JOIN Users ru ON ru.UserID = t.ReceivedFromUserID
                    WHERE   t.UserID          = @UserID
                    AND     t.TransactionDate >= @FromDate
                    AND     t.TransactionDate <= @ToDate
                    ORDER BY t.TransactionDate ASC";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@FromDate", fromDate.Date);
					cmd.Parameters.AddWithValue("@ToDate", toDateEnd);

					SqlDataAdapter da = new SqlDataAdapter(cmd);
					DataTable dt = new DataTable();
					da.Fill(dt);

					pnlResults.Visible = true;

					if (dt.Rows.Count == 0)
					{
						// no transactions found for the selected date range
						pnlNoRecords.Visible = true;
						rptStatement.Visible = false;
						lblRowCount.Text = "0";
					}
					else
					{
						// bind the result set to the repeater
						pnlNoRecords.Visible = false;
						rptStatement.Visible = true;
						rptStatement.DataSource = dt;
						rptStatement.DataBind();
						lblRowCount.Text = dt.Rows.Count.ToString();
					}

					// display the active date range in the section header
					lblDateRange.Text = $"{fromDate:MMM dd, yyyy} — {toDate:MMM dd, yyyy}";
				}
			}
		}

		// ── returns the css badge class based on transaction type ──
		protected string GetBadgeClass(string type)
		{
			switch (type)
			{
				case "D": return "deposit";
				case "W": return "withdraw";
				case "S": return "send";
				case "R": return "receive";
				default: return "";
			}
		}

		// ── returns a human-readable label for each transaction type ──
		protected string GetTypeLabel(string type)
		{
			switch (type)
			{
				case "D": return "Deposit";
				case "W": return "Withdraw";
				case "S": return "Send";
				case "R": return "Receive";
				default: return type;
			}
		}

		// ── shows the error panel with the given message and hides the results ──
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			lblError.Text = message;
			pnlResults.Visible = false;
		}
	}
}