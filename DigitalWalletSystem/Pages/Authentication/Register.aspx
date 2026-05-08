<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="DigitalWalletSystem.Pages.Authentication.Register" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CloudMoney • Register</title>
    <link href="~/Styles/Site.css" rel="stylesheet" type="text/css" />
    <style>
        .register-card { max-width: 520px; }

        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 16px; }
        .form-grid .form-group { margin-bottom: 14px; }
        .form-group-full { grid-column: 1 / -1; }

        .cb-row { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 16px; margin-top: 4px; }
        .cb-row input[type="checkbox"] { width: 16px; height: 16px; margin-top: 3px; flex-shrink: 0; accent-color: var(--accent); }
        .cb-row label { font-size: 12.5px; color: var(--text-secondary); line-height: 1.6; }
        .cb-row label a { color: var(--accent); font-weight: 600; cursor: pointer; text-decoration: underline; }

        input[type="password"]::-ms-reveal,
        input[type="password"]::-ms-clear { display: none; }

        .pw-wrap { position: relative; display: flex; align-items: center; }
        .pw-wrap .form-control { width: 100%; padding-right: 42px; }

        .pw-toggle { position: absolute; right: 12px; background: none; border: none; cursor: pointer; padding: 0; color: var(--text-muted); line-height: 1; }
        .pw-toggle:focus { outline: none; }

        .success-overlay { display: none; position: fixed; inset: 0; background: rgba(15,30,60,0.55); z-index: 999; align-items: center; justify-content: center; }
        .success-overlay.show { display: flex; }
        .success-box { background: #fff; border-radius: 18px; padding: 40px 36px; text-align: center; width: 400px; box-shadow: 0 8px 40px rgba(0,0,0,0.18); position: relative; }

        .success-close { position: absolute; top: 14px; right: 16px; background: none; border: none; font-size: 20px; cursor: pointer; color: var(--text-muted, #94a3b8); line-height: 1; padding: 0; }
        .success-close:hover { color: var(--text-primary, #1e293b); }

        .success-icon { width: 68px; height: 68px; border-radius: 50%; background: #dbeafe; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px; font-size: 32px; }
        .success-title { font-size: 18px; font-weight: 700; color: var(--text-primary); margin-bottom: 4px; }
        .success-sub { font-size: 13px; color: var(--text-secondary); margin-bottom: 16px; }

        .cred-box { background: #f1f5f9; border-radius: 10px; padding: 14px 16px; margin-bottom: 16px; text-align: left; }
        .cred-row { display: flex; justify-content: space-between; align-items: center; padding: 5px 0; border-bottom: 1px solid rgba(0,0,0,0.06); font-size: 13px; }
        .cred-row:last-child { border-bottom: none; }
        .cred-label { color: var(--text-secondary); }
        .cred-value { font-weight: 700; color: var(--text-primary); font-family: monospace; letter-spacing: 0.5px; }

        .cred-pw-wrap { display: flex; align-items: center; gap: 8px; }
        .cred-pw-toggle { background: none; border: none; cursor: pointer; padding: 0; color: var(--text-muted, #94a3b8); line-height: 1; }
        .cred-pw-toggle:focus { outline: none; }

        .progress-bar { height: 5px; background: #e5e7eb; border-radius: 3px; overflow: hidden; }
        .progress-fill { height: 100%; background: var(--accent); width: 0%; transition: width 29.8s linear; }

        .save-note { font-size: 12px; color: #b45309; background: #fef9c3; border-radius: 8px; padding: 8px 12px; margin-bottom: 14px; line-height: 1.5; }

        .legal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 9999; align-items: center; justify-content: center; }
        .legal-overlay.show { display: flex; }

        .legal-box { background: var(--card-bg, #fff); border-radius: 14px; width: 90%; max-width: 560px; max-height: 80vh; display: flex; flex-direction: column; box-shadow: 0 8px 40px rgba(0,0,0,0.22); overflow: hidden; }

        .legal-header { display: flex; align-items: center; justify-content: space-between; padding: 18px 24px; border-bottom: 1px solid var(--border, rgba(0,0,0,0.08)); flex-shrink: 0; }
        .legal-header-title { font-size: 15px; font-weight: 700; color: var(--text-primary); }
        .legal-close { background: none; border: none; font-size: 20px; cursor: pointer; color: var(--text-muted); line-height: 1; padding: 0; }
        .legal-close:hover { color: var(--text-primary); }

        .legal-body { padding: 20px 24px; overflow-y: auto; font-size: 13px; color: var(--text-secondary); line-height: 1.75; }
        .legal-body h3 { font-size: 13px; font-weight: 700; color: var(--text-primary); margin: 16px 0 4px; }
        .legal-body h3:first-child { margin-top: 0; }
        .legal-body p { margin: 0 0 10px; }

        .site-brand { position: fixed; top: 18px; left: 24px; display: flex; flex-direction: column; gap: 2px; pointer-events: none; z-index: 100; }
        .site-brand-name { font-size: 15px; font-weight: 700; color: var(--text-muted); }
        .site-brand-sub  { font-size: 11px; font-weight: 400; color: var(--text-muted); opacity: 0.6; }

        .site-footer { position: fixed; bottom: 0; left: 0; width: 100%; text-align: center; padding: 12px; font-size: 12px; color: var(--text-muted); opacity: 0.6; }
    </style>
</head>

<body>

    <%-- top-left cloudmoney --%>
    <div class="site-brand">
        <div class="site-brand-name">&#9729; CloudMoney</div>
        <div class="site-brand-sub">Digital Wallet</div>
    </div>

    <%-- copyright footer --%>
    <div class="site-footer">&copy; <%= DateTime.Now.Year %> CloudMoney. All rights reserved.</div>

    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" />
        <asp:Label ID="lblNewAccountNumber" runat="server" Text="" style="display:none;" />
        <asp:Label ID="lblNewFullName"      runat="server" Text="" style="display:none;" />
        <asp:Label ID="lblNewUsername"      runat="server" Text="" style="display:none;" />
        <asp:Label ID="lblNewPassword"      runat="server" Text="" style="display:none;" />

        <%-- success overlay --%>
        <div class="success-overlay" id="successOverlay">
            <div class="success-box">

                <%-- close button  --%>
                <button type="button" class="success-close" onclick="goToLogin()" title="Close and go to login">&#10005;</button>

                <div class="success-icon">&#10003;</div>
                <div class="success-title">Account Created!</div>
                <div class="success-sub">Welcome to CloudMoney! Save your credentials below before continuing.</div>

                <%-- yellow reminder to note credentials --%>
                <div class="save-note">&#9888; Please note down your Account Number and Password — you will need them to log in.</div>

                <%-- credential display --%>
                <div class="cred-box">
                    <div class="cred-row">
                        <span class="cred-label">Account No.</span>
                        <span class="cred-value" id="dispAccountNumber"></span>
                    </div>
                    <div class="cred-row">
                        <span class="cred-label">Full Name</span>
                        <span class="cred-value" id="dispFullName"></span>
                    </div>
                    <div class="cred-row">
                        <span class="cred-label">Username</span>
                        <span class="cred-value" id="dispUsername"></span>
                    </div>
                    <div class="cred-row">
                        <span class="cred-label">Password</span>
                        <span class="cred-value">
                            <span class="cred-pw-wrap">
                                <span id="dispPassword" style="letter-spacing:3px;">&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;</span>
                                <button type="button" class="cred-pw-toggle" onclick="toggleCredPassword(this)" title="Show/hide password">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                                </button>
                            </span>
                        </span>
                    </div>
                </div>

                <div class="success-sub">Redirecting to login in 30 seconds&hellip; or click &#10005; to go now.</div>
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

                <div class="auth-heading">Register a new account</div>

                <%-- error alert --%>
                <asp:Panel ID="pnlError" runat="server" Visible="false">
                    <div class="alert alert-error">
                        <asp:Label ID="lblError" runat="server" Text="" />
                    </div>
                </asp:Panel>

                <div class="form-grid">

                    <%-- first name input — letters and spaces only, no symbols --%>
                    <div class="form-group">
                        <label class="form-label">First Name</label>
                        <asp:TextBox ID="txtFirstName" runat="server"
                            CssClass="form-control" placeholder="Juan" MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvFirstName" runat="server"
                            ControlToValidate="txtFirstName"
                            ErrorMessage="First name is required."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revFirstName" runat="server"
                            ControlToValidate="txtFirstName"
                            ValidationExpression="^[A-Za-z\s\-'\.]+$"
                            ErrorMessage="First name must contain letters only (no numbers or symbols)."
                            CssClass="alert alert-error" Display="Dynamic" />
                    </div>

                    <%-- last name input — letters and spaces only, no symbols --%>
                    <div class="form-group">
                        <label class="form-label">Last Name</label>
                        <asp:TextBox ID="txtLastName" runat="server"
                            CssClass="form-control" placeholder="Dela Cruz" MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvLastName" runat="server"
                            ControlToValidate="txtLastName"
                            ErrorMessage="Last name is required."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revLastName" runat="server"
                            ControlToValidate="txtLastName"
                            ValidationExpression="^[A-Za-z\s\-'\.]+$"
                            ErrorMessage="Last name must contain letters only (no numbers or symbols)."
                            CssClass="alert alert-error" Display="Dynamic" />
                    </div>

                    <%-- email address input — must be a valid email format --%>
                    <div class="form-group">
                        <label class="form-label">Email Address</label>
                        <asp:TextBox ID="txtEmail" runat="server"
                            CssClass="form-control" placeholder="juan@email.com" MaxLength="100" />
                        <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
                            ControlToValidate="txtEmail"
                            ErrorMessage="Email is required."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revEmail" runat="server"
                            ControlToValidate="txtEmail"
                            ValidationExpression="^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$"
                            ErrorMessage="Enter a valid email address (e.g. juan@email.com)."
                            CssClass="alert alert-error" Display="Dynamic" />
                    </div>

                    <%-- username input — alphanumeric and underscores only, no symbols --%>
                    <div class="form-group">
                        <label class="form-label">Username</label>
                        <asp:TextBox ID="txtUsername" runat="server"
                            CssClass="form-control" placeholder="juandc" MaxLength="50" />
                        <asp:RequiredFieldValidator ID="rfvUsername" runat="server"
                            ControlToValidate="txtUsername"
                            ErrorMessage="Username is required."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revUsername" runat="server"
                            ControlToValidate="txtUsername"
                            ValidationExpression="^[A-Za-z0-9_]+$"
                            ErrorMessage="Username may only contain letters, numbers, and underscores."
                            CssClass="alert alert-error" Display="Dynamic" />
                    </div>

                    <%-- password input --%>
                    <div class="form-group">
                        <label class="form-label">Password</label>
                        <div class="pw-wrap">
                            <asp:TextBox ID="txtPassword" runat="server"
                                TextMode="Password" CssClass="form-control"
                                placeholder="Create a password" />
                            <button type="button" class="pw-toggle" onclick="togglePassword('txtPassword', this)" title="Show/hide password">
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                            </button>
                        </div>
                        <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
                            ControlToValidate="txtPassword"
                            ErrorMessage="Password is required."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revPassword" runat="server"
                            ControlToValidate="txtPassword"
                            ValidationExpression=".{6,}"
                            ErrorMessage="Password must be at least 6 characters."
                            CssClass="alert alert-error" Display="Dynamic" />
                    </div>

                    <%-- confirm password input --%>
                    <div class="form-group">
                        <label class="form-label">Confirm Password</label>
                        <div class="pw-wrap">
                            <asp:TextBox ID="txtConfirmPassword" runat="server"
                                TextMode="Password" CssClass="form-control"
                                placeholder="Re-enter password" />
                            <button type="button" class="pw-toggle" onclick="togglePassword('txtConfirmPassword', this)" title="Show/hide password">
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                            </button>
                        </div>
                        <asp:RequiredFieldValidator ID="rfvConfirmPassword" runat="server"
                            ControlToValidate="txtConfirmPassword"
                            ErrorMessage="Please confirm your password."
                            CssClass="alert alert-error" Display="Dynamic" />
                        <asp:CompareValidator ID="cvPassword" runat="server"
                            ControlToValidate="txtConfirmPassword"
                            ControlToCompare="txtPassword"
                            ErrorMessage="Passwords do not match."
                            CssClass="alert alert-error" Display="Dynamic" />
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
                    Text="Create Account" CssClass="btn btn-primary"
                    OnClick="btnRegister_Click" />

                <%-- link back to login for existing users --%>
                <div class="auth-footer">
                    Already have an account?
                    <a href="~/Pages/Authentication/Login.aspx" runat="server">Sign in</a>
                </div>

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

			// password toggle in success modal
			var _plainPassword = "";

			// toggles the password display in the success credential box
			function toggleCredPassword(btn) {
				var span = document.getElementById('dispPassword');
				if (span.getAttribute('data-visible') === '1') {
					// hide it
					span.textContent = '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022';
					span.style.letterSpacing = '3px';
					span.setAttribute('data-visible', '0');
					btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';
				} else {
					// show it
					span.textContent = _plainPassword;
					span.style.letterSpacing = '0.5px';
					span.setAttribute('data-visible', '1');
					btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
				}
			}

			// opens and closes the specified legal modal overlay
			function openLegal(overlayId) { document.getElementById(overlayId).classList.add('show'); }
			function closeLegal(overlayId) { document.getElementById(overlayId).classList.remove('show'); }

			// close a legal modal when clicking outside the box
			document.querySelectorAll('.legal-overlay').forEach(function (overlay) {
				overlay.addEventListener('click', function (e) {
					if (e.target === overlay) closeLegal(overlay.id);
				});
			});

			// converts string to title case 
			function toTitleCase(str) {
				return str.replace(/\w\S*/g, function (word) {
					return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
				});
			}

			// auto title-case first and last name fields on every keystroke
			document.addEventListener('DOMContentLoaded', function () {
				['txtFirstName', 'txtLastName'].forEach(function (fieldId) {
					var input = document.querySelector("input[id$='" + fieldId + "']");
					if (!input) return;
					input.addEventListener('input', function () {
						var pos = this.selectionStart;
						this.value = toTitleCase(this.value);
						this.setSelectionRange(pos, pos);
					});
				});

				// auto lowercase username field on every keystroke
				var usernameInput = document.querySelector("input[id$='txtUsername']");
				if (usernameInput) {
					usernameInput.addEventListener('input', function () {
						var pos = this.selectionStart;
						this.value = this.value.toLowerCase();
						this.setSelectionRange(pos, pos);
					});
				}
			});

			// redirect immediately to login
			window.goToLogin = function () {
				window.location.href = '/Pages/Authentication/Login.aspx';
			}

			// called by RegisterStartupScript from code-behind after successful registration
			window.showSuccessAndRedirect = function (accountNumber, fullName, username, password) {
				document.getElementById('dispAccountNumber').textContent = accountNumber;
				document.getElementById('dispFullName').textContent = fullName;
				document.getElementById('dispUsername').textContent = username;
				_plainPassword = password;

				document.getElementById('successOverlay').classList.add('show');
				setTimeout(function () { document.getElementById('progressFill').style.width = '100%'; }, 50);
				setTimeout(goToLogin, 30000);
			}
		</script>
    </form>

</body>
</html>