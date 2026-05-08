using System;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Web.UI;

namespace DigitalWalletSystem.Pages.Account
{
	public partial class AccountInfo : Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack) LoadAccountInfo();
		}

		// queries users and wallets tables and populates all labels
		private void LoadAccountInfo()
		{
			int userID = Convert.ToInt32(Session["UserID"]);
			string connStr = WebConfigurationManager.ConnectionStrings["CloudMoneyDB"].ConnectionString;

			// join wallets to get balance and total sent alongside user details
			string sql = @"SELECT  u.AccountNumber, u.FullName, u.Username,
                                   u.Email, u.DateRegistered, u.IsActive,
                                   w.CurrentBalance, w.TotalSentAmount
                           FROM    Users   u
                           JOIN    Wallets w ON w.UserID = u.UserID
                           WHERE   u.UserID = @UserID";

			using (var conn = new SqlConnection(connStr))
			using (var cmd = new SqlCommand(sql, conn))
			{
				cmd.Parameters.AddWithValue("@UserID", userID);
				conn.Open();

				using (var dr = cmd.ExecuteReader())
				{
					if (!dr.Read()) return;

					// populate basic account fields
					lblAccountNumber.Text = dr["AccountNumber"].ToString();
					lblFullName.Text = dr["FullName"].ToString();
					lblUsername.Text = dr["Username"].ToString();
					lblEmail.Text = dr["Email"].ToString();

					// format registration date as readable date and time
					lblDateRegistered.Text = Convert.ToDateTime(dr["DateRegistered"])
													 .ToString("MMMM dd, yyyy hh:mm tt");

					// format balance and total sent to two decimal places
					lblBalance.Text = Convert.ToDecimal(dr["CurrentBalance"]).ToString("N2");
					lblTotalSent.Text = Convert.ToDecimal(dr["TotalSentAmount"]).ToString("N2");

					// render active or inactive badge based on the isactive flag
					bool isActive = Convert.ToBoolean(dr["IsActive"]);
					lblStatus.Text = isActive
						? "<span class='badge-active'>Active</span>"
						: "<span class='badge-inactive'>Inactive</span>";
				}
			}
		}
	}
}