using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Reports
{
	public partial class DepositsWithdrawals : Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				int userID = Convert.ToInt32(Session["UserID"]);
				string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

				// pre-fill date range: registration date to today
				DateTime registeredDate = GetRegistrationDate(userID, connStr);
				txtFrom.Text = registeredDate.ToString("yyyy-MM-dd");
				txtTo.Text = DateTime.Today.ToString("yyyy-MM-dd");

				LoadTransactions(userID, connStr, registeredDate, DateTime.Today, ddlType.SelectedValue);
			}
		}

		// reloads the table based on user-selected filters
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

			LoadTransactions(userID, connStr, fromDate, toDate, ddlType.SelectedValue);
		}

		// fetches user's registration date from the users table
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

					// fall back to today if no record found
					if (result != null && result != DBNull.Value)
						registeredDate = Convert.ToDateTime(result);
				}
			}

			return registeredDate;
		}

		// queries and displays d/w for given date range and type filter
		private void LoadTransactions(int userID, string connStr, DateTime fromDate, DateTime toDate, string type)
		{
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// extend to date to include the full day up to 23:59:59
				DateTime toDateEnd = toDate.Date.AddDays(1).AddSeconds(-1);

				// base query — always restricts to deposits and withdrawals
				string sql = @"
                    SELECT TransactionType, TransactionDate, Amount
                    FROM   Transactions
                    WHERE  UserID          = @UserID
                    AND    TransactionDate >= @FromDate
                    AND    TransactionDate <= @ToDate
                    AND    TransactionType IN ('D', 'W')";

				// append specific type filter if selected
				if (type == "D") sql += " AND TransactionType = 'D'";
				else if (type == "W") sql += " AND TransactionType = 'W'";

				sql += " ORDER BY TransactionDate ASC";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					cmd.Parameters.AddWithValue("@FromDate", fromDate.Date);
					cmd.Parameters.AddWithValue("@ToDate", toDateEnd);

					DataTable dt = new DataTable();
					new SqlDataAdapter(cmd).Fill(dt);

					pnlResults.Visible = true;

					if (dt.Rows.Count == 0)
					{
						// no records found for the selected range and type
						pnlNoRecords.Visible = true;
						rptResults.Visible = false;
						lblRowCount.Text = "0";
					}
					else
					{
						pnlNoRecords.Visible = false;
						rptResults.Visible = true;
						rptResults.DataSource = dt;
						rptResults.DataBind();
						lblRowCount.Text = dt.Rows.Count.ToString();
					}

					// build label for the active type filter
					string typeLabel = type == "D" ? "Deposits" : type == "W" ? "Withdrawals" : "All";

					// display the date range and type in the section header
					lblDateRange.Text = $"{fromDate:MMM dd, yyyy} — {toDate:MMM dd, yyyy} · {typeLabel}";
				}
			}
		}

		// shows error with message and hides the results
		private void ShowError(string message)
		{
			pnlError.Visible = true;
			lblError.Text = message;
			pnlResults.Visible = false;
		}
	}
}