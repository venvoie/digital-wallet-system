<%@ Page Title="Statement of Account" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="StatementOfAccount.aspx.cs" Inherits="DigitalWalletSystem.Pages.Reports.StatementOfAccount" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
         /* inherit page font instead of default monospace */
        .cm-table td { font-family: inherit; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- filter card: date range inputs and list button --%>
    <div class="card" style="margin-bottom: 20px;">
        <div class="card-title">Statement of Account</div>

        <%-- error alert --%>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert alert-error">
                <asp:Label ID="lblError" runat="server" Text="" />
            </div>
        </asp:Panel>

        <div style="display: flex; gap: 16px; align-items: flex-end; flex-wrap: wrap;">

            <%-- from date — pre-filled with registration date --%>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">From</label>
                <asp:TextBox ID="txtFrom" runat="server"
                    TextMode="Date" CssClass="form-control" style="width: 180px;" />
                <asp:RequiredFieldValidator ID="rfvFrom" runat="server"
                    ControlToValidate="txtFrom"
                    ErrorMessage="From date is required."
                    CssClass="alert alert-error" Display="Dynamic" ValidationGroup="ReportGroup" />
            </div>

            <%-- to date — pre-filled with today's date --%>
            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label">To</label>
                <asp:TextBox ID="txtTo" runat="server"
                    TextMode="Date" CssClass="form-control" style="width: 180px;" />
                <asp:RequiredFieldValidator ID="rfvTo" runat="server"
                    ControlToValidate="txtTo"
                    ErrorMessage="To date is required."
                    CssClass="alert alert-error" Display="Dynamic" ValidationGroup="ReportGroup" />
            </div>

            <%-- list button --%>
            <asp:Button ID="btnList" runat="server"
                Text="List" CssClass="btn btn-primary"
                OnClick="btnList_Click" ValidationGroup="ReportGroup"
                style="width: auto; padding: 10px 28px;" />

        </div>
    </div>

    <%-- results card --%>
    <asp:Panel ID="pnlResults" runat="server" Visible="false">
        <div class="card">

            <%-- section header: date range and record count --%>
            <div class="section-header">
                <div class="section-title">
                    Transaction History &nbsp;
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
                            <th>Debit</th>
                            <th>Credit</th>
                            <th>Balance</th>
                            <th>Sent To</th>
                            <th>Received From</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%-- repeater: one row per transaction --%>
                        <asp:Repeater ID="rptStatement" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td><%# Container.ItemIndex + 1 %></td>

                                    <%-- colored badge for transaction type --%>
                                    <td>
                                        <span class="txn-badge <%# GetBadgeClass(Eval("TransactionType").ToString()) %>">
                                            <%# GetTypeLabel(Eval("TransactionType").ToString()) %>
                                        </span>
                                    </td>

                                    <%-- formatted transaction date and time --%>
                                    <td><%# Eval("TransactionDate", "{0:MM/dd/yyyy hh:mm tt}") %></td>

                                    <%-- debit: shown for withdrawals and sends --%>
                                    <td class="amount-neg"><%# Eval("Debit") != DBNull.Value ? "₱" + string.Format("{0:N2}", Eval("Debit")) : "—" %></td>

                                    <%-- credit: shown for deposits and receives --%>
                                    <td class="amount-pos"><%# Eval("Credit") != DBNull.Value ? "₱" + string.Format("{0:N2}", Eval("Credit")) : "—" %></td>

                                    <%-- running balance after each transaction --%>
                                    <td><strong>₱<%# Eval("BalanceAfter", "{0:N2}") %></strong></td>

                                    <%-- recipient account number --%>
                                    <td><%# Eval("SentToAccountNo") != DBNull.Value && Eval("SentToAccountNo").ToString() != "" ? Eval("SentToAccountNo").ToString() : "—" %></td>

                                    <%-- sender account number --%>
                                    <td><%# Eval("ReceivedFromAccountNo") != DBNull.Value && Eval("ReceivedFromAccountNo").ToString() != "" ? Eval("ReceivedFromAccountNo").ToString() : "—" %></td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>

            <%-- empty state: shown when no transactions exist for the selected range --%>
            <asp:Panel ID="pnlNoRecords" runat="server" Visible="false">
                <div style="text-align:center; padding:48px 24px; color:var(--text-muted);">
                    <div style="font-size:48px; margin-bottom:12px;">🧾</div>
                    <div style="font-size:15px; font-weight:600; color:var(--text-secondary); margin-bottom:6px;">No Records Found</div>
                    <p style="font-size:13px; margin:0;">No transactions found for the selected date range.</p>
                </div>
            </asp:Panel>

        </div>
    </asp:Panel>

</asp:Content>