<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="DigitalWalletSystem.Pages.Authentication.Login" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sign In — CloudMoney</title>
    <link href="~/Styles/Site.css" rel="stylesheet" type="text/css" />
    <style>
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
</head>
<body>
    <form id="form1" runat="server">
        <div class="auth-page">
            <div class="auth-card">

                <%-- logo: icon, name, and tagline --%>
                <div class="auth-logo">
                    <div class="auth-logo-icon">&#9729;</div>
                    <div class="auth-logo-name">CloudMoney</div>
                    <div class="auth-logo-sub">Digital Wallet</div>
                </div>

                <div class="auth-heading">Sign in to your account</div>

                <%-- error alert: shown when login fails --%>
                <asp:Panel ID="pnlError" runat="server" Visible="false">
                    <div class="alert alert-error">
                        <asp:Label ID="lblError" runat="server" Text="" />
                    </div>
                </asp:Panel>

                <%-- account number input --%>
                <div class="form-group">
                    <label class="form-label">Account Number</label>
                    <asp:TextBox ID="txtAccountNumber" runat="server"
                        CssClass="form-control"
                        placeholder="Enter your account number"
                        MaxLength="10" />
                    <asp:RequiredFieldValidator ID="rfvAccountNumber" runat="server"
                        ControlToValidate="txtAccountNumber"
                        ErrorMessage="Account number is required."
                        CssClass="alert alert-error"
                        Display="Dynamic" />
                </div>

                <%-- password input with eye toggle --%>
                <div class="form-group">
                    <label class="form-label">Password</label>
                    <div class="pw-wrap">
                        <asp:TextBox ID="txtPassword" runat="server"
                            TextMode="Password"
                            CssClass="form-control"
                            placeholder="Enter your password" />
                        <%-- eye-slash icon by default: password is hidden, click to reveal --%>
                        <button type="button" class="pw-toggle" onclick="togglePassword('txtPassword', this)" title="Show/hide password">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                        </button>
                    </div>
                    <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
                        ControlToValidate="txtPassword"
                        ErrorMessage="Password is required."
                        CssClass="alert alert-error"
                        Display="Dynamic" />
                </div>

                <%-- sign in submit button --%>
                <asp:Button ID="btnLogin" runat="server"
                    Text="Sign In"
                    CssClass="btn btn-primary"
                    OnClick="btnLogin_Click" />

                <%-- link to registration page for new users --%>
                <div class="auth-footer">
                    Not registered yet?
                    <a href="~/Pages/Authentication/Register.aspx" runat="server">Create an account</a>
                </div>

            </div>
        </div>
    </form>

    <script>
		// svg icon: open eye — shown when password is visible
		var iconEye = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';

		// svg icon: eye with slash — shown when password is hidden (default)
		var iconEyeOff = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';

		// toggles the password field between hidden and visible
		// default state: eye-slash = password hidden; click → open eye = password visible
		function togglePassword(fieldId, btn) {
			// asp.net renders textbox ids with the full client id so we search by the ending
			var input = document.querySelector("input[id$='" + fieldId + "']");
			if (!input) return;

			if (input.type === "password") {
				// reveal the password and switch to the open eye icon
				input.type = "text";
				btn.innerHTML = iconEye;
			} else {
				// hide the password and switch back to the eye-slash icon
				input.type = "password";
				btn.innerHTML = iconEyeOff;
			}
		}
	</script>

</body>
</html>
