<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.model.Student" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%
    // Verify session credentials using standard server-side guards
    if (session == null || !"STUDENT".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Student Portal - Attendance Report Card</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .report-card-container {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 30px;
            margin-bottom: 24px;
            box-shadow: var(--shadow-sm);
        }
        .report-card-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 20px;
            margin-bottom: 24px;
        }
        .report-student-meta {
            font-size: 14px;
            line-height: 1.6;
            color: var(--text-secondary);
        }
        .report-section-title {
            font-size: 16px;
            font-weight: 700;
            color: var(--primary);
            margin-top: 24px;
            margin-bottom: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        /* Print Styles */
        @media print {
            .sidebar,
            .app-header,
            .action-buttons,
            .btn {
                display: none !important;
            }
            .app-content-wrapper {
                margin-left: 0 !important;
                padding: 0 !important;
            }
            .app-main-content {
                padding: 0 !important;
            }
            .report-card-container {
                border: none !important;
                box-shadow: none !important;
                padding: 0 !important;
            }
            .print-header {
                display: block !important;
                text-align: center;
                margin-bottom: 20px;
            }
        }
        .print-header {
            display: none;
        }
    </style>
</head>
<body>
    <div class="app-wrapper">
        <!-- Reusable sidebar navigation include -->
        <%@ include file="student-sidebar.jsp" %>

        <div class="app-content-wrapper">
            <!-- Header bar layout -->
            <header class="app-header">
                <button class="sidebar-toggle-btn hamburger-btn" aria-label="Toggle Navigation">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                </button>
                <div class="header-title-area">
                    <h2>Attendance Report Card</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Action Buttons bar -->
                <div class="action-buttons" style="display: flex; justify-content: flex-end; gap: 12px; margin-bottom: 24px;">
                    <button class="btn btn-secondary" onclick="window.print()">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
                        <span>Print Report</span>
                    </button>
                    <a href="${pageContext.request.contextPath}/student/reports?action=studentReport&format=csv" class="btn btn-success">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        <span>Export CSV</span>
                    </a>
                </div>

                <!-- Printable Report Card Container -->
                <div class="report-card-container animate-fade">
                    <div class="print-header">
                        <h2>Attendance Management System (AMS)</h2>
                        <h3>Official Student Attendance Transcript</h3>
                        <hr style="border: 0; border-top: 1px solid var(--border-color); margin: 16px 0;">
                    </div>

                    <div class="report-card-header">
                        <div class="report-student-meta">
                            <h3 style="margin: 0 0 8px 0; color: var(--text-primary); font-size: 20px;">
                                ${student.firstName} ${student.lastName}
                            </h3>
                            <div><strong>Roll Number:</strong> ${student.rollNo}</div>
                            <div><strong>Class Cohort:</strong> ${className}</div>
                            <div><strong>Generated on:</strong> <%= new java.util.Date() %></div>
                        </div>
                    </div>

                    <!-- Breakdown Table -->
                    <div class="report-section-title">Academic Subject Breakdown</div>
                    <div class="table-responsive" style="margin-bottom: 24px;">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Subject Code</th>
                                    <th>Subject Name</th>
                                    <th style="text-align: center;">Total Classes</th>
                                    <th style="text-align: center;">Attended</th>
                                    <th style="text-align: center;">Attendance %</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="sub" items="${subjectBreakdown}">
                                    <tr>
                                        <td><strong>${sub.code}</strong></td>
                                        <td>${sub.name}</td>
                                        <td style="text-align: center;">${sub.total}</td>
                                        <td style="text-align: center;">${sub.attended}</td>
                                        <td style="text-align: center;">
                                            <c:choose>
                                                <c:when test="${sub.percentage >= 75.0}">
                                                    <span class="badge badge-success" style="padding: 4px 10px;">
                                                        <fmt:formatNumber value="${sub.percentage}" maxFractionDigits="1" />%
                                                    </span>
                                                </c:when>
                                                <c:when test="${sub.percentage >= 60.0}">
                                                    <span class="badge badge-warning" style="padding: 4px 10px;">
                                                        <fmt:formatNumber value="${sub.percentage}" maxFractionDigits="1" />%
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-danger" style="padding: 4px 10px;">
                                                        <fmt:formatNumber value="${sub.percentage}" maxFractionDigits="1" />%
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>

                    <!-- Absence logs breakdown -->
                    <div class="report-section-title">Log of Recorded Absences</div>
                    <div class="table-responsive">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Slot</th>
                                    <th>Subject Code</th>
                                    <th>Subject Name</th>
                                    <th>Remarks / Reason</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${empty absenceLogs}">
                                        <tr>
                                            <td colspan="5" style="text-align: center; color: var(--text-secondary); padding: 20px 0;">
                                                Congratulations! No absences have been recorded for your profile.
                                            </td>
                                        </tr>
                                    </c:when>
                                    <c:otherwise>
                                        <c:forEach var="abs" items="${absenceLogs}">
                                            <tr>
                                                <td><strong>${abs.date}</strong></td>
                                                <td><span style="font-size: 12px; color: var(--text-secondary);">${abs.slot}</span></td>
                                                <td><strong>${abs.code}</strong></td>
                                                <td>${abs.name}</td>
                                                <td><span style="font-style: italic; color: var(--text-muted);">${not empty abs.remarks ? abs.remarks : '-'}</span></td>
                                            </tr>
                                        </c:forEach>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
