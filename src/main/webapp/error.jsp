<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Portal - Error Occurred</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        body {
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background-color: var(--bg-primary);
            padding: 24px;
        }
        .error-container {
            text-align: center;
            max-width: 580px;
            padding: 48px;
            background-color: var(--bg-card);
            border-radius: var(--border-radius-lg);
            box-shadow: var(--shadow-lg);
            border: 1px solid var(--border-color);
        }
        .error-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 82px;
            height: 82px;
            background-color: var(--danger-light);
            color: var(--danger);
            border-radius: 50%;
            margin-bottom: 28px;
        }
        .error-title {
            font-size: 26px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 12px;
            letter-spacing: -0.5px;
        }
        .error-description {
            color: var(--text-secondary);
            font-size: 15px;
            line-height: 1.6;
            margin-bottom: 32px;
        }
        .diagnostic-card {
            background-color: var(--bg-primary);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            padding: 16px;
            text-align: left;
            margin-bottom: 32px;
            font-family: 'Courier New', Courier, monospace;
            font-size: 13px;
            overflow-x: auto;
        }
        .diagnostic-card h4 {
            color: var(--text-primary);
            margin-bottom: 8px;
            font-family: inherit;
        }
        .diagnostic-card p {
            color: var(--danger);
            margin: 0;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>

    <div class="error-container card animate-fade">
        <div class="error-badge">
            <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
        </div>

        <c:choose>
            <c:when test="${pageContext.errorData.statusCode eq 404}">
                <h2 class="error-title">Page Not Found</h2>
                <p class="error-description">
                    The portal workspace URL you requested doesn't exist or may have migrated. 
                    Please verify your path or return to your account console.
                </p>
            </c:when>
            <c:otherwise>
                <h2 class="error-title">Server Exception Occurred</h2>
                <p class="error-description">
                    The server encountered an unexpected internal query or configuration error while processing your request. 
                    Our database logs have captured this diagnostic error.
                </p>
            </c:otherwise>
        </c:choose>

        <!-- Dynamic JSP Exception Diagnostic Block -->
        <c:if test="${not empty pageContext.exception or not empty pageContext.errorData.throwable}">
            <div class="diagnostic-card">
                <h4>System Diagnostic Summary:</h4>
                <p>
                    <c:choose>
                        <c:when test="${not empty pageContext.exception}">
                            ${pageContext.exception.message}
                        </c:when>
                        <c:otherwise>
                            ${pageContext.errorData.throwable.message}
                        </c:otherwise>
                    </c:choose>
                </p>
            </div>
        </c:if>

        <div style="display: flex; gap: 16px; justify-content: center;">
            <button onclick="window.history.back()" class="btn btn-outline" style="height: 44px; padding: 0 24px;">
                Go Back
            </button>
            <a href="${pageContext.request.contextPath}/login" class="btn btn-primary" style="height: 44px; display: inline-flex; align-items: center; justify-content: center; padding: 0 24px; text-decoration: none;">
                Sign In Screen
            </a>
        </div>
    </div>

</body>
</html>
