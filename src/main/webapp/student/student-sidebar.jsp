<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Detect active tab from request URI and parameters
    String currentURI = request.getRequestURI();
    String activeTab = "dashboard";
    if (currentURI.contains("view-attendance.jsp")) {
        String tabParam = request.getParameter("tab");
        if ("subject".equals(tabParam)) {
            activeTab = "subject";
        } else {
            activeTab = "myattendance";
        }
    }
%>
<!-- Dynamic Theme Override for Student Module -->
<style>
:root {
    --accent: #3498DB !important;
    --accent-hover: #2980B9 !important;
    --accent-light: rgba(52, 152, 219, 0.1) !important;
}
</style>

<aside class="sidebar">
    <div class="sidebar-header">
        <div class="sidebar-logo">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                <path d="M12 11l2 2 4-4"></path>
            </svg>
            <span>AMS Student</span>
        </div>
        <button class="sidebar-close-btn sidebar-toggle-btn" aria-label="Close Sidebar" style="background: none; border: none; color: white; display: none;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
        </button>
    </div>

    <!-- Student Identity Profile Widget -->
    <div style="padding: 16px 20px; border-bottom: 1px solid rgba(255, 255, 255, 0.08); margin-bottom: 12px; display: flex; align-items: center; gap: 12px;">
        <div style="width: 38px; height: 38px; border-radius: 50%; background-color: var(--accent); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; text-transform: uppercase;">
            <c:choose>
                <c:when test="${not empty sessionScope.fullName}">
                    <c:out value="${sessionScope.fullName.substring(0, 2)}" />
                </c:when>
                <c:otherwise>ST</c:otherwise>
            </c:choose>
        </div>
        <div>
            <div style="color: white; font-size: 13.5px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 130px;">
                <c:out value="${sessionScope.fullName != null ? sessionScope.fullName : 'Student Portal'}" />
            </div>
            <div style="color: var(--accent); font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">
                <c:out value="${sessionScope.role != null ? sessionScope.role : 'STUDENT'}" />
            </div>
        </div>
    </div>

    <nav class="sidebar-nav">
        <ul>
            <li>
                <a href="${pageContext.request.contextPath}/student/dashboard.jsp" class="<%= "dashboard".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/student/view-attendance.jsp?tab=date" class="<%= "myattendance".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    <span>My Attendance</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/student/view-attendance.jsp?tab=subject" class="<%= "subject".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
                    <span>Attendance by Subject</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/student/reports?action=studentReport&format=csv">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                    <span>Download Report</span>
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
