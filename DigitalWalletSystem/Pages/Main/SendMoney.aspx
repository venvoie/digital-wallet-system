<%@ Page Title="Send CloudMoney" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="SendMoney.aspx.cs" Inherits="DigitalWalletSystem.Pages.Main.SendMoney" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* confirmation modal overlay */
        #sendModal {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.45);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }

        /* show class toggled by js */
        #sendModal.show {
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

        /* suppress edge and ie native password reveal button */
        input[type="password"]::-ms-reveal,
        input[type="password"]::-ms-clear {
            display: none;
        }

        /* wrapper positions the toggle button inside the input */
        .pw-wrap {
            position: relative;
            display: flex;
            align-items: center;
        }

        .pw-wrap .form-control {
            width: 100%;
            padding-right: 42px;
        }

        /* toggle button sits on the right edge of the input */
        .pw-toggle {
            position: absolute;
            right: 12px;
            background: none;
            border: none;
            cursor: pointer;
            padding: 0;
            color: var(--text-muted);
            font-size: 16px;
            line-height: 1;
        }

        .pw-toggle:focus {
            outline: none;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- confirmation modal (shown before actual form submit) --%>
    <div id="sendModal">
        <div class="modal-box">
            <div class="modal-title">Confirm transaction</div>
            <div class="modal-body" id="modalMessage">Are you sure you want to send this amount?</div>
            <div class="modal-actions">
                <%-- cancel button — closes modal without submitting --%>
                <button type="button" class="btn" onclick="closeModal()"
                    style="padding: 10px 24px; background: #f0f0f0; border: none; border-radius: 6px; cursor: pointer;">
                    Cancel
                </button>
                <%-- confirm button — proceeds with the actual send --%>
                <button type="button" class="btn btn-primary"
                    style="padding: 10px 24px; cursor: pointer;"
                    onclick="confirmSend()">
                    Confirm
                </button>
            </div>
        </div>
    </div>

    <%-- main send money card — full width with left/right margin --%>
    <div class="card" style="max-width: 100%; margin: 0 24px;">
        <div class="card-title">Send CloudMoney</div>

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

        <%-- step 1: recipient account number input with verify button --%>
        <div class="form-group">
            <label class="form-label">Recipient Account Number</label>
            <div style="display: flex; gap: 8px;">
                <asp:TextBox ID="txtRecipientAccount" runat="server"
                    CssClass="form-control"
                    placeholder="Enter 10-digit account number"
                    MaxLength="10"
                    style="flex: 1;" />
                <%-- verify button does not trigger send validators --%>
                <asp:Button ID="btnVerify" runat="server"
                    Text="Verify"
                    CssClass="btn btn-secondary"
                    OnClick="btnVerify_Click"
                    CausesValidation="false"
                    style="width: auto; padding: 10px 20px;" />
            </div>

            <%-- required validator for the recipient account field --%>
            <asp:RequiredFieldValidator ID="rfvRecipient" runat="server"
                ControlToValidate="txtRecipientAccount"
                ErrorMessage="Please enter a recipient account number."
                CssClass="alert alert-error"
                Display="Dynamic"
                ValidationGroup="SendGroup" />
        </div>

        <%-- recipient details panel — revealed after successful verification --%>
        <asp:Panel ID="pnlRecipient" runat="server" Visible="false">
            <div class="alert alert-success" style="margin-bottom: 20px;">
                <strong>Recipient Verified &#10003;</strong><br />
                <table style="margin-top: 8px; font-size: 13px; width: 100%;">
                    <tr>
                        <td style="width: 120px; color: var(--text-secondary);">Account No.</td>
                        <td><strong><asp:Label ID="lblRecipientAccountNo" runat="server" Text="" /></strong></td>
                    </tr>
                    <tr>
                        <td style="color: var(--text-secondary);">Name</td>
                        <td><strong><asp:Label ID="lblRecipientName" runat="server" Text="" /></strong></td>
                    </tr>
                </table>
            </div>

            <%-- hidden field to carry the recipient's userid through the postback --%>
            <asp:HiddenField ID="hfRecipientUserID" runat="server" Value="" />

            <%-- amount input field --%>
            <div class="form-group">
                <label class="form-label">Amount to Send</label>
                <asp:TextBox ID="txtAmount" runat="server"
                    CssClass="form-control"
                    placeholder="e.g. 500"
                    MaxLength="10" />

                <%-- required validator for amount --%>
                <asp:RequiredFieldValidator ID="rfvAmount" runat="server"
                    ControlToValidate="txtAmount"
                    ErrorMessage="Please enter an amount."
                    CssClass="alert alert-error"
                    Display="Dynamic"
                    ValidationGroup="SendGroup" />

                <%-- format validator: allows whole numbers or decimals up to 2 places --%>
                <asp:RegularExpressionValidator ID="revAmount" runat="server"
                    ControlToValidate="txtAmount"
                    ValidationExpression="^\d+(\.\d{1,2})?$"
                    ErrorMessage="Please enter a valid amount."
                    CssClass="alert alert-error"
                    Display="Dynamic"
                    ValidationGroup="SendGroup" />
            </div>

            <%-- password field with eye toggle — required as a security confirmation step --%>
            <div class="form-group">
                <label class="form-label">Your Password <span style="color:var(--text-muted); font-weight:400;">(required for security)</span></label>
                <div class="pw-wrap">
                    <asp:TextBox ID="txtPassword" runat="server"
                        TextMode="Password"
                        CssClass="form-control"
                        placeholder="Enter your password to confirm" />
                    <%-- eye-slash icon by default: password is hidden, click to reveal --%>
                    <button type="button" class="pw-toggle" onclick="togglePassword('txtPassword', this)" title="Show/hide password">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    </button>
                </div>

                <%-- required validator for password --%>
                <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
                    ControlToValidate="txtPassword"
                    ErrorMessage="Please enter your password to confirm."
                    CssClass="alert alert-error"
                    Display="Dynamic"
                    ValidationGroup="SendGroup" />
            </div>

            <%-- send rules info box --%>
            <div class="alert alert-info" style="margin-bottom: 20px;">
                <strong>Send Rules:</strong><br />
                &#8226; Minimum amount: <strong>&#8369;100.00</strong><br />
                &#8226; Maximum amount per transaction: <strong>&#8369;2,000.00</strong><br />
                &#8226; Amount must be divisible by <strong>&#8369;100.00</strong><br />
                &#8226; Transaction will be rejected if funds are insufficient
            </div>

            <%-- send button — triggers js confirmation modal instead of direct postback --%>
            <asp:Button ID="btnSend" runat="server"
                Text="Send CloudMoney"
                CssClass="btn btn-primary"
                OnClick="btnSend_Click"
                ValidationGroup="SendGroup"
                OnClientClick="return openModal();"
                style="width: auto; padding: 10px 32px;" />

            <%-- hidden trigger used by js to actually fire the postback after confirmation --%>
            <asp:Button ID="btnSendConfirmed" runat="server"
                Text=""
                OnClick="btnSend_Click"
                ValidationGroup="SendGroup"
                style="display: none;" />

        </asp:Panel>

    </div>

    <script>
		// svg icon: open eye — shown when password is visible
		var iconEye = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';

		// svg icon: eye with slash — shown when password is hidden (default)
		var iconEyeOff = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';

		// toggles a password field between hidden and visible
		// default state: eye-slash shown = password is hidden
		// after click: open eye shown = password is visible
		function togglePassword(fieldId, btn) {
			// asp.net renders textbox ids with the full client id so we search by the ending
			var input = document.querySelector("input[id$='" + fieldId + "']");
			if (!input) return;

			if (input.type === "password") {
				// reveal the password and switch to open eye (no slash)
				input.type = "text";
				btn.innerHTML = iconEye;
			} else {
				// hide the password and switch back to eye-slash
				input.type = "password";
				btn.innerHTML = iconEyeOff;
			}
		}

		// open the confirmation modal after client-side validation passes
		function openModal() {
			// run asp.net validators for the send group first
			if (typeof Page_ClientValidate === 'function' && !Page_ClientValidate('SendGroup')) {
				return false; // stop if validation fails
			}

			// grab amount and recipient name to display in the modal message
			var amount = document.getElementById('<%= txtAmount.ClientID %>').value;
			var recipientName = document.getElementById('<%= lblRecipientName.ClientID %>').innerText;

            document.getElementById('modalMessage').innerText =
                'Are you sure you want to send ₱' +
                parseFloat(amount).toLocaleString('en-PH', { minimumFractionDigits: 2 }) +
                ' to ' + recipientName + '?';

            // show the modal
            document.getElementById('sendModal').classList.add('show');

            // prevent default form submit — modal handles it
            return false;
        }

        // close modal without submitting
        function closeModal() {
            document.getElementById('sendModal').classList.remove('show');
        }

        // user confirmed — trigger the hidden button to fire the real postback
        function confirmSend() {
            closeModal();
            document.getElementById('<%= btnSendConfirmed.ClientID %>').click();
		}

		// close modal if user clicks outside the box
		document.getElementById('sendModal').addEventListener('click', function (e) {
			if (e.target === this) closeModal();
		});
	</script>

</asp:Content>
