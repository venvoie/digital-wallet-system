using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Reports
{
	public partial class StatementOfAccount : Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			if (IsPostBack) return;

			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			// pre-fill date fields and load all transactions since registration
			DateTime registeredDate = GetRegistrationDate(userID, connStr);
			txtFrom.Text = registeredDate.ToString("yyyy-MM-dd");
			txtTo.Text = DateTime.Today.ToString("yyyy-MM-dd");

			LoadTransactions(userID, connStr, registeredDate, DateTime.Today);
		}

		// reloads the table based on the user-selected date range
		protected void btnList_Click(object sender, EventArgs e)
		{
			if (!Page.IsValid) return;

			// parse and validate both dates
			if (!DateTime.TryParse(txtFrom.Text, out DateTime fromDate)) { ShowError("Please enter a valid From date."); return; }
			if (!DateTime.TryParse(txtTo.Text, out DateTime toDate)) { ShowError("Please enter a valid To date."); return; }
			if (fromDate.Date > DateTime.Today) { ShowError("From date must not be a future date."); return; }
			if (toDate.Date > DateTime.Today) { ShowError("To date must not be a future date."); return; }
			if (fromDate.Date > toDate.Date) { ShowError("From date must be earlier than or equal to the To date."); return; }

			pnlError.Visible = false;

			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			LoadTransactions(userID, connStr, fromDate, toDate);
		}

		// fetches the user's registration date from the users table
		private DateTime GetRegistrationDate(int userID, string connStr)
		{
			using (var conn = new SqlConnection(connStr))
			using (var cmd = new SqlCommand("SELECT DateRegistered FROM Users WHERE UserID = @UserID", conn))
			{
				cmd.Parameters.AddWithValue("@UserID", userID);
				conn.Open();
				object result = cmd.ExecuteScalar();

				// fall back to today if no date is found
				return (result != null && result != DBNull.Value) ? Convert.ToDateTime(result) : DateTime.Today;
			}
		}

		// queries and binds transactions for the given date range
		private void LoadTransactions(int userID, string connStr, DateTime fromDate, DateTime toDate)
		{
			// extend to date to include the full day up to 23:59:59
			DateTime toDateEnd = toDate.Date.AddDays(1).AddSeconds(-1);

			string sql = @"SELECT t.TransactionType, t.TransactionDate,
                                  CASE WHEN t.TransactionType IN ('W','S') THEN t.Amount ELSE NULL END AS Debit,
                                  CASE WHEN t.TransactionType IN ('D','R') THEN t.Amount ELSE NULL END AS Credit,
                                  t.BalanceAfter,
                                  su.AccountNumber AS SentToAccountNo,
                                  ru.AccountNumber AS ReceivedFromAccountNo
                           FROM   Transactions t
                           LEFT JOIN Users su ON su.UserID = t.SentToUserID
                           LEFT JOIN Users ru ON ru.UserID = t.ReceivedFromUserID
                           WHERE  t.UserID          = @UserID
                           AND    t.TransactionDate >= @FromDate
                           AND    t.TransactionDate <= @ToDate
                           ORDER BY t.TransactionDate ASC";

			using (var conn = new SqlConnection(connStr))
			using (var cmd = new SqlCommand(sql, conn))
			{
				cmd.Parameters.AddWithValue("@UserID", userID);
				cmd.Parameters.AddWithValue("@FromDate", fromDate.Date);
				cmd.Parameters.AddWithValue("@ToDate", toDateEnd);

				var dt = new DataTable();
				new SqlDataAdapter(cmd).Fill(dt);

				pnlResults.Visible = true;

				if (dt.Rows.Count == 0)
				{
					// no transactions found for the selected range
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

				// show the active date range in the section header
				lblDateRange.Text = $"{fromDate:MMM dd, yyyy} — {toDate:MMM dd, yyyy}";
			}
		}

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

		// error panel with message and hides results
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			lblError.Text = message;
			pnlResults.Visible = false;
		}
	}
}