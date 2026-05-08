using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Main
{
	public partial class Dashboard : Page
	{
		// ── page load — fetch and render all dashboard data on first visit ──
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				LoadDashboard();
			}
		}

		// ── queries user info, wallet stats, notifications, and recent transactions ──
		private void LoadDashboard()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// fetch user profile and wallet balance in a single joined query
				string sqlUser = @"
                    SELECT  u.FullName,
                            u.AccountNumber,
                            u.DateRegistered,
                            w.CurrentBalance,
                            w.TotalSentAmount
                    FROM    Users  u
                    JOIN    Wallets w ON w.UserID = u.UserID
                    WHERE   u.UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlUser, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					SqlDataReader dr = cmd.ExecuteReader();

					if (dr.Read())
					{
						// populate the hero balance card and user info labels
						lblFullName.Text = dr["FullName"].ToString();
						lblAccountNo.Text = dr["AccountNumber"].ToString();
						lblBalance.Text = Convert.ToDecimal(dr["CurrentBalance"]).ToString("N2");
						lblTotalSent.Text = Convert.ToDecimal(dr["TotalSentAmount"]).ToString("N2");
						lblDateRegistered.Text = Convert.ToDateTime(dr["DateRegistered"]).ToString("MMMM dd, yyyy");

						// pass name and account number up to the master page topbar
						SiteMaster master = (SiteMaster)this.Master;
						if (master != null)
						{
							master.SetUserInfo(
								dr["FullName"].ToString(),
								dr["AccountNumber"].ToString()
							);
						}
					}
					dr.Close();
				}

				// fetch transaction counts and totals grouped by type for the stats row
				string sqlStats = @"
                    SELECT  TransactionType,
                            COUNT(*)        AS TxnCount,
                            SUM(Amount)     AS TotalAmount
                    FROM    Transactions
                    WHERE   UserID = @UserID
                    GROUP BY TransactionType";

				using (SqlCommand cmd = new SqlCommand(sqlStats, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					SqlDataReader dr = cmd.ExecuteReader();

					while (dr.Read())
					{
						string type = dr["TransactionType"].ToString();
						int count = Convert.ToInt32(dr["TxnCount"]);
						decimal total = Convert.ToDecimal(dr["TotalAmount"]);

						// assign each stat to the matching label based on transaction type
						switch (type)
						{
							case "R":
								lblTotalReceived.Text = total.ToString("N2");
								lblReceivedCount.Text = count.ToString();
								break;
							case "D":
								lblTotalDeposited.Text = total.ToString("N2");
								lblDepositCount.Text = count.ToString();
								break;
							case "W":
								lblTotalWithdrawn.Text = total.ToString("N2");
								lblWithdrawCount.Text = count.ToString();
								break;
							case "S":
								lblSentCount.Text = count.ToString();
								break;
						}
					}
					dr.Close();
				}

				// fetch the five most recent received transactions for the notifications panel
				string sqlNotifs = @"
                    SELECT  TOP 5
                            t.Amount,
                            t.TransactionDate,
                            u.FullName  AS SenderName
                    FROM    Transactions t
                    JOIN    Users u ON u.UserID = t.ReceivedFromUserID
                    WHERE   t.UserID          = @UserID
                    AND     t.TransactionType = 'R'
                    ORDER BY t.TransactionDate DESC";

				using (SqlCommand cmd = new SqlCommand(sqlNotifs, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					SqlDataAdapter da = new SqlDataAdapter(cmd);
					DataTable dt = new DataTable();
					da.Fill(dt);

					// show the empty state panel if no received transactions exist
					if (dt.Rows.Count == 0)
						pnlNoNotifs.Visible = true;
					else
						rptNotifications.DataSource = dt;

					rptNotifications.DataBind();
				}

				// fetch the five most recent transactions of any type for the activity panel
				string sqlTxn = @"
                    SELECT  TOP 5
                            TransactionType,
                            Amount,
                            TransactionDate
                    FROM    Transactions
                    WHERE   UserID = @UserID
                    ORDER BY TransactionDate DESC";

				using (SqlCommand cmd = new SqlCommand(sqlTxn, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					SqlDataAdapter da = new SqlDataAdapter(cmd);
					DataTable dt = new DataTable();
					da.Fill(dt);

					// show the empty state panel if no transactions exist yet
					if (dt.Rows.Count == 0)
						pnlNoTxn.Visible = true;
					else
						rptTransactions.DataSource = dt;

					rptTransactions.DataBind();
				}
			}
		}

		// ── returns the css badge class for a given transaction type ──
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

		// ── returns a human-readable label for a given transaction type ──
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

		// ── returns true if the transaction type adds to the balance (deposit or receive) ──
		protected bool IsCredit(string type)
		{
			return type == "D" || type == "R";
		}
	}
}