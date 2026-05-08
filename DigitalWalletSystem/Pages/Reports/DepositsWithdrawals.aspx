<%@ Page Title="Deposits & Withdrawals" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="DepositsWithdrawals.aspx.cs" Inherits="DigitalWalletSystem.Pages.Reports.DepositsWithdrawals" %>

<%-- head content placeholder — font fix for number cells --%>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        <%-- ensure numeric cells inherit the page font instead of the browser default monospace --%>
        .cm-table td {
            font-family: inherit;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- filter card: date range inputs, type dropdown, and list button --%>
    <div class="card" style="margin-bottom: 20px;">
        <div class="card-title">Deposits &amp; Withdrawals</div>

        <%-- error alert: shown when validation fails --%>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert alert-error">
                <asp:Label ID="lblError" runat="server" Text="" />
            </div>
        </asp:Panel>

        <div style="display: flex; gap: 16px; align-items: flex-end; flex-wrap: wrap;">

            <%-- from date input — pre-filled with registration date on load --%>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">From</label>
                <asp:TextBox ID="txtFrom" runat="server"
                    TextMode="Date"
                    CssClass="form-control"
                    style="width: 180px;" />
                <asp:RequiredFieldValidator ID="rfvFrom" runat="server"
                    ControlToValidate="txtFrom"
                    ErrorMessage="From date is required."
                    CssClass="alert alert-error"
                    Display="Dynamic"
                    ValidationGroup="ReportGroup" />
            </div>

            <%-- to date input — pre-filled with today's date on load --%>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">To</label>
                <asp:TextBox ID="txtTo" runat="server"
                    TextMode="Date"
                    CssClass="form-control"
                    style="width: 180px;" />
                <asp:RequiredFieldValidator ID="rfvTo" runat="server"
                    ControlToValidate="txtTo"
                    ErrorMessage="To date is required."
                    CssClass="alert alert-error"
                    Display="Dynamic"
                    ValidationGroup="ReportGroup" />
            </div>

            <%-- type filter dropdown — all, deposit, or withdrawal --%>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">Type</label>
                <asp:DropDownList ID="ddlType" runat="server" CssClass="form-control" style="width: 160px;">
                    <asp:ListItem Text="All"        Value="All" Selected="True" />
                    <asp:ListItem Text="Deposit"    Value="D" />
                    <asp:ListItem Text="Withdrawal" Value="W" />
                </asp:DropDownList>
            </div>

            <%-- list button — triggers validation and reloads the table --%>
            <asp:Button ID="btnList" runat="server"
                Text="List"
                CssClass="btn btn-primary"
                OnClick="btnList_Click"
                ValidationGroup="ReportGroup"
                style="width: auto; padding: 10px 28px;" />

        </div>
    </div>

    <%-- results card — visible on initial load and after list is clicked --%>
    <asp:Panel ID="pnlResults" runat="server" Visible="false">
        <div class="card">

            <%-- section header: shows active date range, type filter, and record count --%>
            <div class="section-header">
                <div class="section-title">
                    Results &nbsp;
                    <span style="font-size:13px; font-weight:400; color:var(--text-muted);">
                        (<asp:Label ID="lblDateRange" runat="server" Text="" />)
                    </span>
                </div>
                <span style="font-size:13px; color:var(--text-secondary);">
                    <asp:Label ID="lblRowCount" runat="server" Text="" /> record(s)
                </span>
            </div>

            <%-- transaction table --%>
            <div class="table-wrap">
                <table class="cm-table">
                    <thead>
                        <tr>
                            <th>Seq. #</th>
                            <th>Type</th>
                            <th>Date &amp; Time</th>
                            <th>Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%-- repeater: one row per transaction --%>
                        <asp:Repeater ID="rptResults" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <%-- sequential row number --%>
                                    <td><%# Container.ItemIndex + 1 %></td>

                                    <%-- colored badge showing deposit or withdrawal --%>
                                    <td>
                                        <span class="txn-badge <%# Eval("TransactionType").ToString() == "D" ? "deposit" : "withdraw" %>">
                                            <%# Eval("TransactionType").ToString() == "D" ? "Deposit" : "Withdrawal" %>
                                        </span>
                                    </td>

                                    <%-- formatted transaction date and time --%>
                                    <td><%# Eval("TransactionDate", "{0:MM/dd/yyyy hh:mm tt}") %></td>

                                    <%-- amount: green for deposits, red for withdrawals --%>
                                    <td class='<%# Eval("TransactionType").ToString() == "D" ? "amount-pos" : "amount-neg" %>'>
                                        &#8369;<%# Eval("Amount", "{0:N2}") %>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>

            <%-- empty state: shown when no records match the selected range and type --%>
            <asp:Panel ID="pnlNoRecords" runat="server" Visible="false">
                <div style="text-align:center; padding:48px 24px; color:var(--text-muted);">
                    <div style="font-size:48px; margin-bottom:12px;">🧾</div>
                    <div style="font-size:15px; font-weight:600; color:var(--text-secondary); margin-bottom:6px;">
                        No Records Found
                    </div>
                    <p style="font-size:13px; margin:0;">
                        No transactions found for the selected date range and type.
                    </p>
                </div>
            </asp:Panel>

        </div>
    </asp:Panel>

</asp:Content>
