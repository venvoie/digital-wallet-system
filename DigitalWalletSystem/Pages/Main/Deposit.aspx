<%@ Page Title="Deposit" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Deposit.aspx.cs" Inherits="DigitalWalletSystem.Pages.Main.Deposit" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* confirmation modal overlay */
        #depositModal {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.45);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }

        /* show class toggled by js */
        #depositModal.show {
            display: flex;
        }

        /* modal box */
        .modal-box {
            background: #fff;
            border-radius: 12px;
            padding: 28px 32px;
            max-width: 400px;
            width: 90%;
            box-shadow: 0 8px 32px rgba(0,0,0,0.18);
        }

        /* modal title */
        .modal-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 10px;
        }

        /* modal body text */
        .modal-body {
            font-size: 15px;
            color: #555;
            margin-bottom: 24px;
        }

        /* modal action row */
        .modal-actions {
            display: flex;
            gap: 12px;
            justify-content: flex-end;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- confirmation modal (shown before actual form submit) --%>
    <div id="depositModal">
        <div class="modal-box">
            <div class="modal-title">Confirm deposit</div>
            <div class="modal-body" id="modalMessage">Are you sure you want to deposit this amount?</div>
            <div class="modal-actions">
                <%-- cancel button — closes modal without submitting --%>
                <button type="button" class="btn" onclick="closeModal()"
                    style="padding: 10px 24px; background: #f0f0f0; border: none; border-radius: 6px; cursor: pointer;">
                    Cancel
                </button>
                <%-- confirm button — proceeds with the actual deposit --%>
                <button type="button" class="btn btn-primary" id="btnConfirm"
                    style="padding: 10px 24px; cursor: pointer;"
                    onclick="confirmDeposit()">
                    Confirm
                </button>
            </div>
        </div>
    </div>

    <%-- main deposit card — full width with left/right margin --%>
    <div class="card" style="max-width: 100%; margin: 0 24px;">
        <div class="card-title">Deposit Funds</div>

        <%-- current balance display --%>
        <div class="balance-card" style="margin-bottom: 24px; padding: 16px 20px;">
            <div>
                <div class="balance-label">Current Balance</div>
                <div class="balance-amount" style="font-size: 26px;">
                    &#8369; <asp:Label ID="lblCurrentBalance" runat="server" Text="0.00" />
                </div>
            </div>
        </div>

        <%-- error alert panel --%>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert alert-error">
                <asp:Label ID="lblError" runat="server" Text="" />
            </div>  
        </asp:Panel>

        <%-- success alert panel --%>
        <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
            <div class="alert alert-success">
                <asp:Label ID="lblSuccess" runat="server" Text="" />
            </div>
        </asp:Panel>

        <%-- amount input field --%>
        <div class="form-group">
            <label class="form-label">Amount to Deposit</label>
            <asp:TextBox ID="txtAmount" runat="server"
                CssClass="form-control"
                placeholder="e.g. 500"
                MaxLength="10" />

            <%-- required field validator --%>
            <asp:RequiredFieldValidator ID="rfvAmount" runat="server"
                ControlToValidate="txtAmount"
                ErrorMessage="Please enter an amount."
                CssClass="alert alert-error"
                Display="Dynamic" />

            <%-- format validator: allows whole numbers or decimals up to 2 places --%>
            <asp:RegularExpressionValidator ID="revAmount" runat="server"
                ControlToValidate="txtAmount"
                ValidationExpression="^\d+(\.\d{1,2})?$"
                ErrorMessage="Please enter a valid amount."
                CssClass="alert alert-error"
                Display="Dynamic" />
        </div>

        <%-- deposit rules info box --%>
        <div class="alert alert-info" style="margin-bottom: 20px;">
            <strong>Deposit Rules:</strong><br />
            &#8226; Minimum deposit: <strong>&#8369;100.00</strong><br />
            &#8226; Maximum deposit per transaction: <strong>&#8369;2,000.00</strong><br />
            &#8226; Amount must be divisible by <strong>&#8369;100.00</strong><br />
            &#8226; Total balance must not exceed <strong>&#8369;10,000.00</strong>
        </div>

        <%-- deposit button — triggers js confirmation modal instead of direct postback --%>
        <asp:Button ID="btnDeposit" runat="server"
            Text="Deposit"
            CssClass="btn btn-primary"
            OnClick="btnDeposit_Click"
            OnClientClick="return openModal();"
            style="width: auto; padding: 10px 32px;" />

        <%-- hidden trigger used by js to actually fire the postback after confirmation --%>
        <asp:Button ID="btnDepositConfirmed" runat="server"
            Text=""
            OnClick="btnDeposit_Click"
            style="display: none;" />
    </div>

    <script>
        // open the confirmation modal after client-side validation passes
        function openModal() {
            // run asp.net validators first
            if (typeof Page_ClientValidate === 'function' && !Page_ClientValidate()) {
                return false; // stop if validation fails
            }

            // grab the entered amount to display in the modal message
            var amount = document.getElementById('<%= txtAmount.ClientID %>').value;
            document.getElementById('modalMessage').innerText =
                'Are you sure you want to deposit ₱' + parseFloat(amount).toLocaleString('en-PH', { minimumFractionDigits: 2 }) + '?';

            // show the modal
            document.getElementById('depositModal').classList.add('show');

            // prevent default form submit — modal handles it
            return false;
        }

        // close modal without submitting
        function closeModal() {
            document.getElementById('depositModal').classList.remove('show');
        }

        // user confirmed — trigger the hidden button to fire the real postback
        function confirmDeposit() {
            closeModal();
            document.getElementById('<%= btnDepositConfirmed.ClientID %>').click();
        }

        // close modal if user clicks outside the box
        document.getElementById('depositModal').addEventListener('click', function (e) {
            if (e.target === this) closeModal();
        });
	</script>

</asp:Content>
