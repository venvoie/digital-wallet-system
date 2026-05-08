<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="DigitalWalletSystem.Pages.Authentication.Register" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Create Account — CloudMoney</title>
    <link href="~/Styles/Site.css" rel="stylesheet" type="text/css" />
    <style>
        .register-card { max-width: 520px; }

        /* two-column grid for the registration form fields */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0 16px;
        }
        .form-grid .form-group { margin-bottom: 14px; }
        .form-group-full { grid-column: 1 / -1; }

        /* terms and conditions checkbox row */
        .cb-row {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            margin-bottom: 16px;
            margin-top: 4px;
        }
        .cb-row input[type="checkbox"] {
            width: 16px; height: 16px;
            margin-top: 3px;
            flex-shrink: 0;
            accent-color: var(--accent);
        }
        .cb-row label {
            font-size: 12.5px;
            color: var(--text-secondary);
            line-height: 1.6;
        }
        .cb-row label a {
            color: var(--accent);
            font-weight: 600;
            cursor: pointer;
            text-decoration: underline;
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
            line-height: 1;
        }
        .pw-toggle:focus { outline: none; }

        /* success overlay shown after successful registration */
        .success-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 30, 60, 0.55);
            z-index: 999;
            align-items: center;
            justify-content: center;
        }
        .success-overlay.show { display: flex; }
        .success-box {
            background: #fff;
            border-radius: 18px;
            padding: 48px 40px;
            text-align: center;
            width: 320px;
            box-shadow: 0 8px 40px rgba(0,0,0,0.18);
        }
        .success-icon {
            width: 68px; height: 68px;
            border-radius: 50%;
            background: #dbeafe;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 18px;
            font-size: 32px;
        }
        .success-title {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 8px;
        }
        .success-sub {
            font-size: 13px;
            color: var(--text-secondary);
            margin-bottom: 20px;
        }
        .progress-bar {
            height: 5px;
            background: #e5e7eb;
            border-radius: 3px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: var(--accent);
            width: 0%;
            transition: width 2.8s linear;
        }

        /* shared modal overlay for terms and privacy policy */
        .legal-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }
        .legal-overlay.show { display: flex; }

        /* modal box containing the legal text */
        .legal-box {
            background: var(--card-bg, #fff);
            border-radius: 14px;
            width: 90%;
            max-width: 560px;
            max-height: 80vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 8px 40px rgba(0,0,0,0.22);
            overflow: hidden;
        }

        /* modal header with title and close button */
        .legal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 18px 24px;
            border-bottom: 1px solid var(--border, rgba(0,0,0,0.08));
            flex-shrink: 0;
        }
        .legal-header-title {
            font-size: 15px;
            font-weight: 700;
            color: var(--text-primary);
        }
        .legal-close {
            background: none;
            border: none;
            font-size: 20px;
            cursor: pointer;
            color: var(--text-muted);
            line-height: 1;
            padding: 0;
        }
        .legal-close:hover { color: var(--text-primary); }

        /* scrollable body area for the legal text */
        .legal-body {
            padding: 20px 24px;
            overflow-y: auto;
            font-size: 13px;
            color: var(--text-secondary);
            line-height: 1.75;
        }
        .legal-body h3 {
            font-size: 13px;
            font-weight: 700;
            color: var(--text-primary);
            margin: 16px 0 4px;
        }
        .legal-body h3:first-child { margin-top: 0; }
        .legal-body p { margin: 0 0 10px; }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <%-- success overlay: shown after account is created, redirects after 3 seconds --%>
        <div class="success-overlay" id="successOverlay">
            <div class="success-box">
                <div class="success-icon">&#10003;</div>
                <div class="success-title">Account Created!</div>
                <div class="success-sub">Welcome to CloudMoney. Redirecting to login...</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
        </div>

        <%-- terms and conditions modal --%>
        <div class="legal-overlay" id="termsOverlay">
            <div class="legal-box">
                <div class="legal-header">
                    <span class="legal-header-title">Terms and Conditions</span>
                    <button type="button" class="legal-close" onclick="closeLegal('termsOverlay')">&#10005;</button>
                </div>
                <div class="legal-body">
                    <p>Last updated: May 2026. By creating an account with CloudMoney, you agree to be bound by these Terms and Conditions.</p>

                    <h3>1. Acceptance of Terms</h3>
                    <p>By accessing or using the CloudMoney Digital Wallet system, you confirm that you are at least 18 years old and have the legal capacity to enter into this agreement. If you do not agree to these terms, you must not use the service.</p>

                    <h3>2. Account Registration</h3>
                    <p>You must provide accurate, complete, and current information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.</p>

                    <h3>3. Wallet and Transactions</h3>
                    <p>CloudMoney provides a digital wallet for deposits, withdrawals, and peer-to-peer transfers. All transactions are final once confirmed. We reserve the right to reverse transactions in cases of fraud, error, or policy violation. Send limits and minimum amounts apply per transaction as displayed in the application.</p>

                    <h3>4. Prohibited Activities</h3>
                    <p>You agree not to use CloudMoney for any unlawful purpose, including but not limited to money laundering, fraud, or unauthorized access to other accounts. Accounts found in violation will be deactivated immediately and reported to appropriate authorities.</p>

                    <h3>5. Fees</h3>
                    <p>CloudMoney currently does not charge fees for standard transactions. We reserve the right to introduce fees in the future with prior notice to registered users.</p>

                    <h3>6. Limitation of Liability</h3>
                    <p>CloudMoney is provided for demonstration and educational purposes. We are not liable for any loss of funds, data, or damages arising from your use of the system. Use the service at your own risk.</p>

                    <h3>7. Termination</h3>
                    <p>We reserve the right to suspend or terminate your account at any time for violation of these terms, suspicious activity, or at our sole discretion. You may also close your account at any time by contacting support.</p>

                    <h3>8. Changes to Terms</h3>
                    <p>We may update these Terms and Conditions from time to time. Continued use of CloudMoney after changes are posted constitutes your acceptance of the updated terms.</p>

                    <h3>9. Governing Law</h3>
                    <p>These terms are governed by the laws of the Republic of the Philippines. Any disputes shall be resolved in the appropriate courts of the Philippines.</p>
                </div>
            </div>
        </div>

        <%-- privacy policy modal --%>
        <div class="legal-overlay" id="privacyOverlay">
            <div class="legal-box">
                <div class="legal-header">
                    <span class="legal-header-title">Privacy Policy</span>
                    <button type="button" class="legal-close" onclick="closeLegal('privacyOverlay')">&#10005;</button>
                </div>
                <div class="legal-body">
                    <p>Last updated: May 2026. CloudMoney is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data.</p>

                    <h3>1. Information We Collect</h3>
                    <p>We collect the following personal information when you register: full name, email address, username, and a hashed version of your password. We also collect transaction data, IP addresses for audit purposes, and the date and time of your account activities.</p>

                    <h3>2. How We Use Your Information</h3>
                    <p>Your information is used to operate and maintain your account, process transactions, send notifications about account activity, ensure the security of the platform, and comply with legal obligations. We do not use your data for advertising.</p>

                    <h3>3. Data Storage and Security</h3>
                    <p>Your data is stored in a secured database. Passwords are never stored in plain text — they are hashed using SHA-256 before storage. We implement reasonable technical and organizational measures to protect your information from unauthorized access, loss, or disclosure.</p>

                    <h3>4. Sharing of Information</h3>
                    <p>We do not sell, trade, or rent your personal information to third parties. We may disclose information if required by law, court order, or to protect the rights and safety of CloudMoney and its users.</p>

                    <h3>5. Transaction Data Visibility</h3>
                    <p>When you send or receive money, the other party's account number and name will be visible in your transaction history, and your account number and name will be visible in theirs. This is necessary for the operation of peer-to-peer transfers.</p>

                    <h3>6. Your Rights</h3>
                    <p>You have the right to access the personal data we hold about you, request corrections to inaccurate data, and request deletion of your account and associated data, subject to any legal retention requirements.</p>

                    <h3>7. Cookies</h3>
                    <p>CloudMoney uses session cookies to maintain your logged-in state during a browsing session. These cookies are deleted when you log out or close your browser. We do not use tracking or advertising cookies.</p>

                    <h3>8. Changes to This Policy</h3>
                    <p>We may update this Privacy Policy periodically. We will notify registered users of significant changes. Continued use of the service after changes are posted constitutes your acceptance of the updated policy.</p>

                    <h3>9. Contact</h3>
                    <p>If you have questions about this Privacy Policy or how your data is handled, please contact the CloudMoney support team through the in-app support channels.</p>
                </div>
            </div>
        </div>

        <div class="auth-page">
            <div class="auth-card register-card">

                <%-- logo: icon, name, and tagline --%>
                <div class="auth-logo">
                    <div class="auth-logo-icon">&#9729;</div>
                    <div class="auth-logo-name">CloudMoney</div>
                    <div class="auth-logo-sub">Create Your Account</div>
                </div>

                <div class="auth-heading">Register a new account</div>

                <%-- error alert: shown when registration fails --%>
                <asp:Panel ID="pnlError" runat="server" Visible="false">
                    <div class="alert alert-error">
                        <asp:Label ID="lblError" runat="server" Text="" />
                    </div>
                </asp:Panel>

                <%-- success alert (inline fallback, main success uses the overlay) --%>
                <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                    <div class="alert alert-success">
                        <asp:Label ID="lblSuccess" runat="server" Text="" />
                    </div>
                </asp:Panel>

                <div class="form-grid">

                    <%-- first name input --%>
                    <div class="form-group">
                        <label class="form-label">First Name</label>
                        <asp:TextBox ID="txtFirstName" runat="server"
                            CssClass="form-control"
                            placeholder="Juan"
                            MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvFirstName" runat="server"
                            ControlToValidate="txtFirstName"
                            ErrorMessage="First name is required."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                    </div>

                    <%-- last name input --%>
                    <div class="form-group">
                        <label class="form-label">Last Name</label>
                        <asp:TextBox ID="txtLastName" runat="server"
                            CssClass="form-control"
                            placeholder="Dela Cruz"
                            MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvLastName" runat="server"
                            ControlToValidate="txtLastName"
                            ErrorMessage="Last name is required."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                    </div>

                    <%-- email address input --%>
                    <div class="form-group">
                        <label class="form-label">Email Address</label>
                        <asp:TextBox ID="txtEmail" runat="server"
                            CssClass="form-control"
                            placeholder="juan@email.com"
                            MaxLength="100" />
                        <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
                            ControlToValidate="txtEmail"
                            ErrorMessage="Email is required."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revEmail" runat="server"
                            ControlToValidate="txtEmail"
                            ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$"
                            ErrorMessage="Enter a valid email address."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                    </div>

                    <%-- username input --%>
                    <div class="form-group">
                        <label class="form-label">Username</label>
                        <asp:TextBox ID="txtUsername" runat="server"
                            CssClass="form-control"
                            placeholder="juandc"
                            MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvUsername" runat="server"
                            ControlToValidate="txtUsername"
                            ErrorMessage="Username is required."
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
                                placeholder="Create a password" />
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
                        <asp:RegularExpressionValidator ID="revPassword" runat="server"
                            ControlToValidate="txtPassword"
                            ValidationExpression=".{6,}"
                            ErrorMessage="Password must be at least 6 characters."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                    </div>

                    <%-- confirm password input with eye toggle --%>
                    <div class="form-group">
                        <label class="form-label">Confirm Password</label>
                        <div class="pw-wrap">
                            <asp:TextBox ID="txtConfirmPassword" runat="server"
                                TextMode="Password"
                                CssClass="form-control"
                                placeholder="Re-enter password" />
                            <%-- eye-slash icon by default: password is hidden, click to reveal --%>
                            <button type="button" class="pw-toggle" onclick="togglePassword('txtConfirmPassword', this)" title="Show/hide password">
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                            </button>
                        </div>
                        <asp:RequiredFieldValidator ID="rfvConfirmPassword" runat="server"
                            ControlToValidate="txtConfirmPassword"
                            ErrorMessage="Please confirm your password."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                        <asp:CompareValidator ID="cvPassword" runat="server"
                            ControlToValidate="txtConfirmPassword"
                            ControlToCompare="txtPassword"
                            ErrorMessage="Passwords do not match."
                            CssClass="alert alert-error"
                            Display="Dynamic" />
                    </div>

                </div>

                <%-- terms and conditions checkbox — links open their respective modals --%>
                <div class="cb-row">
                    <asp:CheckBox ID="chkTerms" runat="server" />
                    <label for="<%= chkTerms.ClientID %>">
                        I have read and agree to the
                        <a onclick="openLegal('termsOverlay')">Terms and Conditions</a> and
                        <a onclick="openLegal('privacyOverlay')">Privacy Policy</a> of CloudMoney.
                    </label>
                </div>

                <%-- create account submit button --%>
                <asp:Button ID="btnRegister" runat="server"
                    Text="Create Account"
                    CssClass="btn btn-primary"
                    OnClick="btnRegister_Click" />

                <%-- link back to login for existing users --%>
                <div class="auth-footer">
                    Already have an account?
                    <a href="~/Pages/Authentication/Login.aspx" runat="server">Sign in</a>
                </div>

            </div>
        </div>

    </form>

    <script>
		// svg icon: open eye — shown when password is visible
		var iconEye = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';

		// svg icon: eye with slash — shown when password is hidden (default)
		var iconEyeOff = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';

		// toggles a password field between hidden and visible
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

		// opens the specified legal modal overlay
		function openLegal(overlayId) {
			document.getElementById(overlayId).classList.add('show');
		}

		// closes the specified legal modal overlay
		function closeLegal(overlayId) {
			document.getElementById(overlayId).classList.remove('show');
		}

		// close a legal modal when the user clicks outside the box
		document.querySelectorAll('.legal-overlay').forEach(function (overlay) {
			overlay.addEventListener('click', function (e) {
				if (e.target === overlay) closeLegal(overlay.id);
			});
		});

		// triggered from code-behind via scriptmanager after successful registration
		function showSuccessAndRedirect() {
			var overlay = document.getElementById('successOverlay');
			overlay.classList.add('show');
			var fill = document.getElementById('progressFill');
			setTimeout(function () { fill.style.width = '100%'; }, 50);
			setTimeout(function () {
				window.location.href = '/Pages/Authentication/Login.aspx';
			}, 3000);
		}
	</script>
</body>
</html>
