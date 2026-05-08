<%@ Page Title="Withdraw" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Withdraw.aspx.cs" Inherits="DigitalWalletSystem.Pages.Main.Withdraw" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        #withdrawModal {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.45);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }

        #withdrawModal.show { display: flex; }

        .modal-box {
            background: #fff;
            border-radius: 12px;
            padding: 28px 32px;
            max-width: 400px;
            width: 90%;
            box-shadow: 0 8px 32px rgba(0,0,0,0.18);
        }

        .modal-title  { font-size: 18px; font-weight: 600; margin-bottom: 10px; }
        .modal-body   { font-size: 15px; color: #555; margin-bottom: 24px; }
        .modal-actions { display: flex; gap: 12px; justify-content: flex-end; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- confirmation modal --%>
    <div id="withdrawModal">
        <div class="modal-box">
            <div class="modal-title">Confirm withdrawal</div>
            <div class="modal-body" id="modalMessage">Are you sure you want to withdraw this amount?</div>
            <div class="modal-actions">

                <button type="button" class="btn" onclick="closeModal()"
                    style="padding: 10px 24px; background: #f0f0f0; border: none; border-radius: 6px; cursor: pointer;">
                    Cancel
                </button>

                <button type="button" class="btn btn-primary" id="btnConfirm"
                    style="padding: 10px 24px; cursor: pointer;" onclick="confirmWithdraw()">
                    Confirm
                </button>

            </div>
        </div>
    </div>

    <%-- main withdraw card --%>
    <div class="card" style="max-width: 100%; margin: 0 24px;">
        <div class="card-title">Withdraw Funds</div>

        <%-- current balance display --%>
        <div class="balance-card" style="margin-bottom: 24px; padding: 16px 20px;">
            <div>
                <div class="balance-label">Current Balance</div>
                <div class="balance-amount" style="font-size: 26px;">
                    &#8369; <asp:Label ID="lblCurrentBalance" runat="server" Text="0.00" />
                </div>
            </div>
        </div>

        <%-- error and success alert panels --%>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert alert-error"><asp:Label ID="lblError" runat="server" /></div>
        </asp:Panel>
        <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
            <div class="alert alert-success"><asp:Label ID="lblSuccess" runat="server" /></div>
        </asp:Panel>

        <%-- amount input with validators --%>
        <div class="form-group">
            <label class="form-label">Amount to Withdraw</label>
            <asp:TextBox ID="txtAmount" runat="server" CssClass="form-control" placeholder="e.g. 500" MaxLength="10" />

            <%-- required field validator --%>
            <asp:RequiredFieldValidator ID="rfvAmount" runat="server"
                ControlToValidate="txtAmount" ErrorMessage="Please enter an amount."
                CssClass="alert alert-error" Display="Dynamic" />

            <%-- format validator --%>
            <asp:RegularExpressionValidator ID="revAmount" runat="server"
                ControlToValidate="txtAmount" ValidationExpression="^\d+(\.\d{1,2})?$"
                ErrorMessage="Please enter a valid amount."
                CssClass="alert alert-error" Display="Dynamic" />
        </div>

        <%-- withdrawal rules info box --%>
        <div class="alert alert-info" style="margin-bottom: 20px;">
            <strong>Withdrawal Rules:</strong><br />
            &#8226; Minimum withdrawal: <strong>&#8369;100.00</strong><br />
            &#8226; Maximum withdrawal per transaction: <strong>&#8369;2,000.00</strong><br />
            &#8226; Amount must be divisible by <strong>&#8369;100.00</strong><br />
            &#8226; Withdrawal will be rejected if funds are insufficient
        </div>

        <%-- triggers js confirmation modal before postback --%>
        <asp:Button ID="btnWithdraw" runat="server" Text="Withdraw" CssClass="btn btn-primary"
            OnClick="btnWithdraw_Click" OnClientClick="return openModal();"
            style="width: auto; padding: 10px 32px;" />

        <%-- hidden button used by js to fire the real postback after confirmation --%>
        <asp:Button ID="btnWithdrawConfirmed" runat="server" Text="" OnClick="btnWithdraw_Click" style="display: none;" />
    </div>

    <script>
		function openModal() {
			if (typeof Page_ClientValidate === 'function' && !Page_ClientValidate()) return false;

			// show the entered amount in the modal message
			var amount = document.getElementById('<%= txtAmount.ClientID %>').value;
            document.getElementById('modalMessage').innerText =
                'Are you sure you want to withdraw ₱' + parseFloat(amount).toLocaleString('en-PH', { minimumFractionDigits: 2 }) + '?';

            document.getElementById('withdrawModal').classList.add('show');
            return false; // prevent default form submit
        }

        // close modal without submitting
        function closeModal() { document.getElementById('withdrawModal').classList.remove('show'); }

        // user confirmed
        function confirmWithdraw() {
            closeModal();
            document.getElementById('<%= btnWithdrawConfirmed.ClientID %>').click();
		}

		// close modal on outside click
		document.getElementById('withdrawModal').addEventListener('click', function (e) {
			if (e.target === this) closeModal();
		});
	</script>

</asp:Content>