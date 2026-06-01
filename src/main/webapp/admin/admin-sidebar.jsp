<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Auto-detect active page from the request URI for high-fidelity tab highlighting
    String currentURI = request.getRequestURI();
    String activeTab = "dashboard"; // default
    if (currentURI.contains("manage-students.jsp") || currentURI.contains("students")) {
        activeTab = "students";
    } else if (currentURI.contains("manage-teachers.jsp") || currentURI.contains("teachers")) {
        activeTab = "teachers";
    } else if (currentURI.contains("manage-subjects.jsp") || currentURI.contains("subjects")) {
        activeTab = "subjects";
    } else if (currentURI.contains("manage-classes.jsp") || currentURI.contains("classes")) {
        activeTab = "classes";
    } else if (currentURI.contains("attendance-report.jsp") || currentURI.contains("reports")) {
        activeTab = "reports";
    } else if (currentURI.contains("dashboard.jsp")) {
        activeTab = "dashboard";
    }
%>
<aside class="sidebar">
    <div class="sidebar-header">
        <div class="sidebar-logo">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                <circle cx="12" cy="13" r="3"></circle>
            </svg>
            <span>AMS Admin</span>
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
        <div style="width: 38px; height: 38px; border-radius: 50%; background-color: var(--accent); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px;">
            AD
        </div>
        <div>
            <div style="color: white; font-size: 13.5px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 130px;">
                ${sessionScope.username != null ? sessionScope.username : "Administrator"}
            </div>
            <div style="color: var(--accent); font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">
                ${sessionScope.role != null ? sessionScope.role : "ADMIN"}
            </div>
        </div>
    </div>

    <nav class="sidebar-nav">
        <ul>
            <li>
                <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="<%= "dashboard".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    <span>Dashboard</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/admin/students" class="<%= "students".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                    <span>Manage Students</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/admin/teachers" class="<%= "teachers".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
                    <span>Manage Teachers</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/admin/subjects" class="<%= "subjects".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2 2 7"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
                    <span>Manage Subjects</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/admin/classes" class="<%= "classes".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
                    <span>Manage Classes</span>
                </a>
            </li>
            <li>
                <a href="${pageContext.request.contextPath}/admin/reports" class="<%= "reports".equals(activeTab) ? "active" : "" %>">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                    <span>Reports Dashboard</span>
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
