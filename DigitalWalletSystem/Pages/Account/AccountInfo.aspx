<%@ Page Title="Account Info" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="AccountInfo.aspx.cs" Inherits="DigitalWalletSystem.Pages.Account.AccountInfo" %>

<%-- head content placeholder --%>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- account info card — full width with symmetric horizontal margins --%>
    <div class="card" style="max-width: 100%; margin-left: 0; margin-right: 0;">
        <div class="card-title">Account Information</div>

        <%-- account number --%>
        <div class="info-row">
            <div class="info-key">Account Number</div>
            <div class="info-val mono">
                <asp:Label ID="lblAccountNumber" runat="server" Text="" />
            </div>
        </div>

        <%-- full name --%>
        <div class="info-row">
            <div class="info-key">Full Name</div>
            <div class="info-val">
                <asp:Label ID="lblFullName" runat="server" Text="" />
            </div>
        </div>

        <%-- username --%>
        <div class="info-row">
            <div class="info-key">Username</div>
            <div class="info-val">
                <asp:Label ID="lblUsername" runat="server" Text="" />
            </div>
        </div>

        <%-- email address --%>
        <div class="info-row">
            <div class="info-key">Email Address</div>
            <div class="info-val">
                <asp:Label ID="lblEmail" runat="server" Text="" />
            </div>
        </div>

        <%-- date registered --%>
        <div class="info-row">
            <div class="info-key">Date Registered</div>
            <div class="info-val">
                <asp:Label ID="lblDateRegistered" runat="server" Text="" />
            </div>
        </div>

        <%-- current balance — green, same font size as surrounding text --%>
        <div class="info-row">
            <div class="info-key">Current Balance</div>
            <div class="info-val">
                <span style="color: var(--green); font-weight: 700;">
                    &#8369; <asp:Label ID="lblBalance" runat="server" Text="0.00" />
                </span>
            </div>
        </div>

        <%-- total sent — red, same font size as surrounding text --%>
        <div class="info-row">
            <div class="info-key">Total Sent</div>
            <div class="info-val">
                <span style="color: var(--red); font-weight: 600;">
                    &#8369; <asp:Label ID="lblTotalSent" runat="server" Text="0.00" />
                </span>
            </div>
        </div>

        <%-- account status — rendered as an active or inactive badge --%>
        <div class="info-row">
            <div class="info-key">Account Status</div>
            <div class="info-val">
                <asp:Label ID="lblStatus" runat="server" Text="" />
            </div>
        </div>



    </div>

</asp:Content>