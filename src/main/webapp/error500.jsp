<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Error (500) - AMS</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        body {
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background-color: var(--bg-app);
            padding: 20px;
        }
        .error-card {
            text-align: center;
            max-width: 520px;
            padding: 48px 40px;
            border-radius: var(--border-radius-lg);
            background-color: var(--white);
            box-shadow: var(--shadow-lg);
            border: 1px solid var(--border-color);
        }
        .error-code {
            font-family: 'Outfit', sans-serif;
            font-size: 80px;
            font-weight: 800;
            line-height: 1;
            color: var(--danger);
            margin-bottom: 16px;
        }
        .error-title {
            font-size: 24px;
            margin-bottom: 12px;
            color: var(--primary);
        }
        .error-desc {
            color: var(--text-secondary);
            margin-bottom: 32px;
            font-size: 15px;
        }
        .error-illustration {
            color: var(--danger);
            margin-bottom: 24px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="error-card animate-fade">
        <div class="error-illustration">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
        </div>
        <div class="error-code">500</div>
        <h2 class="error-title">Internal Server Error</h2>
        <p class="error-desc">We encountered an unexpected error on our servers while processing your request. Our technical staff has been notified.</p>
        <a href="${pageContext.request.contextPath}/" class="btn btn-danger" style="padding: 12px 28px;">
            Return to Login Portal
        </a>
    </div>
</body>
</html>
