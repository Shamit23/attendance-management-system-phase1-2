<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Auto-detect active page from the request URI for high-fidelity tab highlighting
    String currentURI = request.getRequestURI();
    String activeTab = "dashboard"; // default
    if (currentURI.contains("mark-attendance.jsp") || currentURI.contains("attendance")) {
        activeTab = "mark";
    } else if (currentURI.contains("attendance-history.jsp")) {
        activeTab = "history";
    } else if (currentURI.contains("teacher-report.jsp") || currentURI.contains("reports")) {
        activeTab = "reports";
    } else if (currentURI.contains("dashboard.jsp")) {
        activeTab = "dashboard";
    }
%>
<!-- Dynamic Theme Override for Teacher Module -->
<style>
:root {
    --accent: #27AE60 !important;
    --accent-hover: #219653 !important;
    --accent-light: rgba(39, 174, 96, 0.1) !important;
}
</style>

<aside class="sidebar">
    <div class="sidebar-header">
        <div class="sidebar-logo">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                <circle cx="12" cy="13" r="3"></circle>
            </svg>
            <span>AMS Teacher</span>
        </div>
        <button class="sidebar-close-btn sidebar-toggle-btn" aria-label="Close Sidebar" style="background: none; border: none; color: white; display: none;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
        </button>
    </div>

    <!-- User identity snippet -->
    <div style="padding: 16px 20px; border-bottom: 1px solid rgba(255, 255, 255, 0.08); margin-bottom: 12px; display: flex; align-items: center; gap: 12px;">
        <div style="width: 38px; height: 38px; border-radius: 50%; background-color: var(--accent); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; text-transform: uppercase;">
            <c:choose>
                <c:when test="${not empty sessionScope.fullName}">
                    <c:out value="${sessionScope.fullName.substring(0, 2)}" />
                </c:when>
                <c:otherwise>TE</c:otherwise>
            </c:choose>
        </div>
        <div>
            <div style="color: white; font-size: 13.5px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 130px;">
                <c:out value="${sessionScope.fullName != null ? sessionScope.fullName : 'Teacher Portal'}" />
            </div>
            <div style="color: var(--accent); font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">
                <c:out value="${sessionScope.role != null ? sessionScope.role : 'TEACHER'}" />
            </div>
        </div>
    </div>

    <nav class="sidebar-nav">
        <ul>
            <li>
                <a href="${pageContext.request.contextPath}/teacher/dashboard.jsp" class="<%= "dashboard".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/teacher/mark-attendance.jsp" class="<%= "mark".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path></svg>
                    <span>Mark Attendance</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/teacher/attendance-history.jsp" class="<%= "history".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                    <span>Attendance History</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/teacher/reports" class="<%= "reports".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                    <span>Reports</span>
                </a>
            </li>
        </ul>
        <div style="margin-top: auto; padding-top: 24px; border-top: 1px solid rgba(255, 255, 255, 0.08);">
            <ul>
                <li>
                    <a href="${pageContext.request.contextPath}/logout" style="color: #e74c3c;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                        <span>Logout</span>
                    </a>
                </li>
            </ul>
        </div>
    </nav>
</aside>
