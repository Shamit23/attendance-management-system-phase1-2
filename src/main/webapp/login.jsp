<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Portal - Sign In</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 50%, var(--accent-hover) 100%);
            padding: 20px;
        }
        .login-card {
            width: 100%;
            max-width: 440px;
            padding: 40px 36px;
            border-radius: var(--border-radius-lg);
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.25), 0 10px 10px -5px rgba(0, 0, 0, 0.15);
            background-color: rgba(255, 255, 255, 0.98);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.3);
            margin-bottom: 24px;
        }
        .login-header {
            text-align: center;
            margin-bottom: 28px;
        }
        .login-header h1 {
            font-size: 28px;
            color: var(--primary);
            margin-bottom: 6px;
            letter-spacing: -0.5px;
        }
        .login-header p {
            color: var(--text-secondary);
            font-size: 14px;
        }
        .login-brand-icon {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 58px;
            height: 58px;
            background-color: var(--accent-light);
            color: var(--accent);
            border-radius: var(--border-radius-md);
            margin-bottom: 16px;
        }
        .alert {
            padding: 12px 16px;
            border-radius: var(--border-radius-sm);
            font-size: 13.5px;
            font-weight: 500;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-danger {
            background-color: var(--danger-light);
            color: var(--danger);
            border: 1px solid rgba(231, 76, 60, 0.2);
        }
        .alert-success {
            background-color: var(--success-light);
            color: var(--success);
            border: 1px solid rgba(39, 174, 96, 0.2);
        }
        .alert-warning {
            background-color: var(--warning-light);
            color: var(--warning);
            border: 1px solid rgba(241, 196, 15, 0.2);
        }
        .footer {
            color: rgba(255, 255, 255, 0.7);
            font-size: 12.5px;
            text-align: center;
            font-weight: 400;
        }
        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%232C3E50' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right 16px center;
            background-size: 16px;
            padding-right: 40px;
        }
    </style>
</head>
<body>

    <div class="login-card card animate-fade">
        <div class="login-header">
            <div class="login-brand-icon">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                    <line x1="12" y1="11" x2="12" y2="17"></line>
                    <line x1="9" y1="14" x2="15" y2="14"></line>
                </svg>
            </div>
            <h1>AMS Portal</h1>
            <p>Sign in to access your attendance workspace</p>
        </div>

        <!-- Server-Side Context Notifications -->
        <c:if test="${not empty errorMessage}">
            <div class="alert alert-danger animate-fade">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                <span>${errorMessage}</span>
            </div>
        </c:if>
        
        <c:if test="${param.logout eq 'success'}">
            <div class="alert alert-success animate-fade">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
                <span>Logged out successfully.</span>
            </div>
        </c:if>
        
        <c:if test="${param.error eq 'unauthorized'}">
            <div class="alert alert-danger animate-fade">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                <span>Session expired or unauthorized. Please sign in.</span>
            </div>
        </c:if>
        
        <c:if test="${param.error eq 'forbidden'}">
            <div class="alert alert-warning animate-fade">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                <span>Forbidden. You do not possess privileges to access that section.</span>
            </div>
        </c:if>

        <!-- Authentication Form -->
        <form id="loginForm" method="POST" action="${pageContext.request.contextPath}/login">
            <div class="form-group">
                <label class="form-label" for="username">Username</label>
                <input type="text" id="username" name="username" class="form-control" placeholder="Enter username" autocomplete="username">
            </div>

            <div class="form-group">
                <label class="form-label" for="password">Password</label>
                <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" autocomplete="current-password">
            </div>

            <div class="form-group" style="margin-bottom: 28px;">
                <label class="form-label" for="role">Select Portal Role</label>
                <select id="role" name="role" class="form-control">
                    <option value="" disabled selected>-- Choose Authorization Role --</option>
                    <option value="ADMIN">System Administrator</option>
                    <option value="TEACHER">Faculty Teacher</option>
                    <option value="STUDENT">College Student</option>
                </select>
            </div>

            <button type="submit" class="btn btn-primary btn-block animate-pulse-btn" style="height: 48px; border-radius: var(--border-radius-sm);">
                Sign In to Dashboard
            </button>
        </form>
    </div>

    <!-- Footer Copyright -->
    <div class="footer animate-fade">
        &copy; 2026 College Attendance Management System (AMS). All rights reserved.
    </div>

    <!-- Core Javascript Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        document.getElementById("loginForm").addEventListener("submit", function(e) {
            // Validation schema targets all input items
            const schema = {
                username: { required: true, minLength: 3, message: "Username must be at least 3 characters." },
                password: { required: true, minLength: 6, message: "Password must be at least 6 characters." },
                role: { required: true, message: "Please select your portal authorization role." }
            };

            // Process form validation helper
            if (!validateForm(this, schema)) {
                e.preventDefault();
                showToast("Please correct the form errors.", "danger");
            } else {
                showToast("Sending credentials, please wait...", "success");
            }
        });
    </script>
</body>
</html>
