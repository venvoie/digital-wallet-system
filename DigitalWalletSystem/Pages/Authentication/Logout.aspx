<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Logout.aspx.cs" Inherits="DigitalWalletSystem.Pages.Authentication.Logout" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Logging Out — CloudMoney</title>
    <link href="~/Styles/Site.css" rel="stylesheet" type="text/css" runat="server" />
    <style>
        /* icon circle styled in red to signal a destructive action */
        .logout-icon {
            width: 68px;
            height: 68px;
            border-radius: 50%;
            background: #fee2e2;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 28px;
        }

        /* subtitle text below the heading */
        .logout-sub {
            font-size: 13px;
            color: var(--text-secondary);
            margin-bottom: 28px;
            line-height: 1.6;
            text-align: center;
        }

        /* side-by-side button row */
        .btn-row {
            display: flex;
            gap: 10px;
        }

        .btn-row .btn {
            flex: 1;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="auth-page">
            <div class="auth-card">

                <%-- red icon circle indicating a logout action --%>
                <div class="logout-icon">&#9099;</div>

                <div class="auth-heading">Log Out</div>

                <%-- confirmation message before the user proceeds --%>
                <div class="logout-sub">
                    Are you sure you want to log out of CloudMoney?<br />
                    You will be redirected to the login page.
                </div>

                <%-- cancel and confirm buttons side by side --%>
                <div class="btn-row">
                    <%-- cancel button — returns the user to the dashboard --%>
                    <asp:Button ID="btnCancel" runat="server"
                        Text="Cancel"
                        CssClass="btn btn-secondary"
                        OnClick="btnCancel_Click" />

                    <%-- confirm button — clears session and redirects to login --%>
                    <asp:Button ID="btnLogout" runat="server"
                        Text="Yes, Log Out"
                        CssClass="btn btn-danger"
                        OnClick="btnLogout_Click" />
                </div>

            </div>
        </div>
    </form>
</body>
</html>
