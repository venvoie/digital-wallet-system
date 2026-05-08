using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem
{
	public partial class SiteMaster : MasterPage
	{
		// ── page load — enforce session auth and populate topbar on every page ──
		protected void Page_Load(object sender, EventArgs e)
		{
			// redirect to login if the user session has expired or was never set
			if (Session["UserID"] == null)
			{
				string path = Request.Url.AbsolutePath.ToLower();
				bool isAuthPage = path.Contains("login") || path.Contains("register");
				if (!isAuthPage)
					Response.Redirect("~/Pages/Authentication/Login.aspx");
			}
			else
			{
				// populate the topbar from session on every request
				SetUserInfo(
					Session["FullName"].ToString(),
					Session["AccountNumber"].ToString()
				);

				// load the notification bell count and dropdown list
				LoadNotifications();
			}
		}

		// ── populates the topbar name, account number, and avatar initials ──
		public void SetUserInfo(string fullName, string accountNumber)
		{
			lblUserName.Text = fullName;
			lblAccountNo.Text = accountNumber;

			// build initials from the first and last word of the full name (e.g. "Juan Dela Cruz" → "JC")
			string[] parts = fullName.Split(' ');
			string initials = "";
			if (parts.Length >= 2)
				initials = parts[0][0].ToString() + parts[parts.Length - 1][0].ToString();
			else if (parts.Length == 1 && parts[0].Length > 0)
				initials = parts[0][0].ToString();

			lblInitials.Text = initials.ToUpper();
		}

		// ── fetches recent transactions and compares against the persisted last-read datetime ──
		private void LoadNotifications()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				conn.Open();

				// fetch the user's last-read timestamp from the database
				// this persists across logouts so the read state is remembered
				DateTime? lastRead = null;
				string sqlLastRead = "SELECT NotifLastRead FROM Users WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sqlLastRead, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					object result = cmd.ExecuteScalar();

					// null means the user has never marked notifications as read
					if (result != null && result != DBNull.Value)
						lastRead = Convert.ToDateTime(result);
				}

				// fetch the 20 most recent transactions to display as notifications
				string sql = @"
                    SELECT TOP 20
                        t.TransactionID,
                        t.TransactionType,
                        t.Amount,
                        t.TransactionDate,
                        COALESCE(u2.FullName, '') AS OtherPartyName
                    FROM Transactions t
                    LEFT JOIN Users u2 ON u2.UserID = CASE
                        WHEN t.TransactionType = 'S' THEN t.SentToUserID
                        WHEN t.TransactionType = 'R' THEN t.ReceivedFromUserID
                        ELSE NULL
                    END
                    WHERE t.UserID = @UserID
                    ORDER BY t.TransactionDate DESC";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					SqlDataAdapter da = new SqlDataAdapter(cmd);
					DataTable dt = new DataTable();
					da.Fill(dt);

					// count transactions that occurred after the last-read timestamp
					int unreadCount = 0;
					foreach (DataRow row in dt.Rows)
					{
						DateTime txnDate = Convert.ToDateTime(row["TransactionDate"]);

						// a transaction is unread if it happened after the last mark-all-read
						bool isUnread = lastRead == null || txnDate > lastRead.Value;
						if (isUnread) unreadCount++;
					}

					// cache last-read in session so the repeater's IsUnread helper can use it
					Session["NotifLastRead"] = lastRead;

					// show or hide the badge based on unread count
					if (unreadCount > 0)
					{
						lblNotifCount.Text = unreadCount > 99 ? "99+" : unreadCount.ToString();
						pnlNotifBadge.Visible = true;
					}
					else
					{
						pnlNotifBadge.Visible = false;
					}

					// bind the notification list to the repeater
					rptNotifications.DataSource = dt;
					rptNotifications.DataBind();

					// show the empty state panel if no transactions exist yet
					pnlNoNotifs.Visible = dt.Rows.Count == 0;
				}
			}
		}

		// ── mark all as read — saves the current datetime to the database ──
		protected void btnMarkAllRead_Click(object sender, EventArgs e)
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			using (SqlConnection conn = new SqlConnection(connStr))
			{
				// persist the current datetime as the new last-read timestamp in the database
				// any transaction before this moment will now be considered read on future logins too
				string sql = "UPDATE Users SET NotifLastRead = GETDATE() WHERE UserID = @UserID";

				using (SqlCommand cmd = new SqlCommand(sql, conn))
				{
					cmd.Parameters.AddWithValue("@UserID", userID);
					conn.Open();
					cmd.ExecuteNonQuery();
				}
			}

			// reload so the badge clears and the dropdown reflects the updated read state
			LoadNotifications();
		}

		// ── returns true if a transaction date is after the last-read timestamp ──
		protected bool IsUnread(object txnDateObj)
		{
			// retrieve the cached last-read value that was set during LoadNotifications
			DateTime? lastRead = Session["NotifLastRead"] as DateTime?;
			DateTime txnDate = Convert.ToDateTime(txnDateObj);

			// if the user has never marked as read, everything is unread
			return lastRead == null || txnDate > lastRead.Value;
		}

		// ── builds a human-readable message for each notification row ──
		protected string GetNotifMessage(string type, string amount, string otherParty)
		{
			string formatted = "₱" + string.Format("{0:N2}", Convert.ToDecimal(amount));
			switch (type)
			{
				case "D": return $"You deposited {formatted}.";
				case "W": return $"You withdrew {formatted}.";
				case "S": return $"You sent {formatted} to {otherParty}.";
				case "R": return $"{otherParty} sent you {formatted}.";
				default: return $"Transaction of {formatted}.";
			}
		}

		// ── returns the css class for the colored icon beside each notification ──
		protected string GetNotifIcon(string type)
		{
			switch (type)
			{
				case "D": return "notif-icon deposit";
				case "W": return "notif-icon withdraw";
				case "S": return "notif-icon send";
				case "R": return "notif-icon receive";
				default: return "notif-icon";
			}
		}
	}
}