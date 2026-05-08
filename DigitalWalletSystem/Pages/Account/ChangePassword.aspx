<%@ Page Title="Change Password" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="ChangePassword.aspx.cs" Inherits="DigitalWalletSystem.Pages.Account.ChangePassword" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        input[type="password"]::-ms-reveal,
        input[type="password"]::-ms-clear { display: none; }

        .pw-wrap { position: relative; display: flex; align-items: center; }
        .pw-wrap .form-control { width: 100%; padding-right: 42px; }

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
        .pw-toggle:focus { outline: none; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%-- change password card --%>
    <div class="card" style="max-width: 100%; margin-left: 0; margin-right: 0;">
        <div class="card-title">Change Password</div>

        <%-- error alert --%>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert alert-error"><asp:Label ID="lblError" runat="server" Text="" /></div>
        </asp:Panel>

        <%-- success alert --%>
        <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
            <div class="alert alert-success"><asp:Label ID="lblSuccess" runat="server" Text="" /></div>
        </asp:Panel>

        <%-- current password field --%>
        <div class="form-group">
            <label class="form-label">Current Password</label>
            <div class="pw-wrap">
                <asp:TextBox ID="txtCurrentPassword" runat="server"
                    TextMode="Password" CssClass="form-control"
                    placeholder="Enter your current password" />
                <button type="button" class="pw-toggle" onclick="togglePassword('txtCurrentPassword', this)" title="Show/hide password">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
            </div>
            <asp:RequiredFieldValidator ID="rfvCurrentPassword" runat="server"
                ControlToValidate="txtCurrentPassword"
                ErrorMessage="Current password is required."
                CssClass="alert alert-error" Display="Dynamic" />
        </div>

        <%-- new password field --%>
        <div class="form-group">
            <label class="form-label">New Password</label>
            <div class="pw-wrap">
                <asp:TextBox ID="txtNewPassword" runat="server"
                    TextMode="Password" CssClass="form-control"
                    placeholder="Enter your new password" />
                <button type="button" class="pw-toggle" onclick="togglePassword('txtNewPassword', this)" title="Show/hide password">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
            </div>
            <asp:RequiredFieldValidator ID="rfvNewPassword" runat="server"
                ControlToValidate="txtNewPassword"
                ErrorMessage="New password is required."
                CssClass="alert alert-error" Display="Dynamic" />
            <asp:RegularExpressionValidator ID="revNewPassword" runat="server"
                ControlToValidate="txtNewPassword"
                ValidationExpression=".{8,}"
                ErrorMessage="New password must be at least 8 characters."
                CssClass="alert alert-error" Display="Dynamic" />
        </div>

        <%-- confirm new password field --%>
        <div class="form-group">
            <label class="form-label">Confirm New Password</label>
            <div class="pw-wrap">
                <asp:TextBox ID="txtConfirmPassword" runat="server"
                    TextMode="Password" CssClass="form-control"
                    placeholder="Re-enter your new password" />
                <button type="button" class="pw-toggle" onclick="togglePassword('txtConfirmPassword', this)" title="Show/hide password">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
            </div>
            <asp:RequiredFieldValidator ID="rfvConfirmPassword" runat="server"
                ControlToValidate="txtConfirmPassword"
                ErrorMessage="Please confirm your new password."
                CssClass="alert alert-error" Display="Dynamic" />
            <asp:CompareValidator ID="cvPasswords" runat="server"
                ControlToValidate="txtConfirmPassword"
                ControlToCompare="txtNewPassword"
                ErrorMessage="Passwords do not match."
                CssClass="alert alert-error" Display="Dynamic" />
        </div>

        <%-- submit and cancel buttons --%>
        <div style="display: flex; gap: 10px; margin-top: 8px;">
            <asp:Button ID="btnChangePassword" runat="server"
                Text="Update Password" CssClass="btn btn-primary"
                OnClick="btnChangePassword_Click"
                style="width: auto; padding: 10px 24px;" />
            <a href="~/Pages/Account/AccountInfo.aspx" runat="server"
                class="btn btn-secondary"
                style="text-decoration: none; width: auto; padding: 10px 20px;">
                Cancel
            </a>
        </div>

    </div>

    <script>
		var iconEye = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
		var iconEyeOff = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';

		// toggles a password field between hidden and visible
		function togglePassword(fieldId, btn) {
			var input = document.querySelector("input[id$='" + fieldId + "']");
			if (!input) return;

			if (input.type === "password") {
				input.type = "text";
				btn.innerHTML = iconEye;
			} else {
				input.type = "password";
				btn.innerHTML = iconEyeOff;
			}
		}
	</script>

</asp:Content>