<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Verify session credentials using standard server-side guards
    if (session == null || !"TEACHER".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Teacher - Attendance Reports</title>
    <!-- Core UI CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .filter-card {
            margin-bottom: 24px;
        }
        .filter-form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            align-items: flex-end;
        }
        .action-buttons-group {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }
        .report-summary-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        /* Print-friendly overrides */
        @media print {
            .sidebar,
            .app-header,
            .filter-card,
            .action-buttons-group,
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
            .table-responsive {
                border: none !important;
                box-shadow: none !important;
            }
            .table th, .table td {
                padding: 8px 10px !important;
                border-bottom: 1px solid #000 !important;
                color: #000 !important;
            }
            .print-title {
                display: block !important;
                margin-bottom: 20px;
                text-align: center;
            }
        }
        .print-title {
            display: none;
        }
    </style>
</head>
<body>
    <div class="app-wrapper">
        <!-- Reusable Sidebar -->
        <%@ include file="teacher-sidebar.jsp" %>

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
                    <h2>Attendance Performance Reports</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Print Heading -->
                <div class="print-title">
                    <h2>AMS Academic Attendance Report (Teacher View)</h2>
                    <p>Generated on: <span id="printDate"></span></p>
                </div>

                <!-- Filter Controls Card -->
                <div class="card filter-card">
                    <div class="card-header" style="margin-bottom: 12px; padding-bottom: 0;">
                        <h4 class="card-title" style="margin: 0; color: var(--primary);">Filter Criteria</h4>
                    </div>
                    <div class="card-body">
                        <form method="GET" action="${pageContext.request.contextPath}/teacher/reports" id="filterForm">
                            <div class="filter-form-grid">
                                <div class="form-group">
                                    <label class="form-label">Class Cohort</label>
                                    <select name="classId" id="classFilter" class="form-control">
                                        <option value="">-- All Classes --</option>
                                        <c:forEach var="cls" items="${classes}">
                                            <option value="${cls.id}" ${param.classId == cls.id ? 'selected' : ''}>${cls.name}</option>
                                        </c:forEach>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Subject</label>
                                    <select name="subjectId" id="subjectFilter" class="form-control">
                                        <option value="">-- All Subjects --</option>
                                        <c:forEach var="sub" items="${subjects}">
                                            <option value="${sub.id}" ${param.subjectId == sub.id ? 'selected' : ''}>${sub.name} (${sub.code})</option>
                                        </c:forEach>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Start Date</label>
                                    <input type="date" name="startDate" id="startDateFilter" class="form-control" value="${param.startDate}">
                                </div>
                                <div class="form-group">
                                    <label class="form-label">End Date</label>
                                    <input type="date" name="endDate" id="endDateFilter" class="form-control" value="${param.endDate}">
                                </div>
                                <div class="form-group" style="display: flex; gap: 8px;">
                                    <button type="submit" class="btn btn-primary" style="flex: 1; height: 45px;">Apply</button>
                                    <a href="${pageContext.request.contextPath}/teacher/reports" class="btn btn-secondary" style="flex: 1; height: 45px; display: flex; align-items: center; justify-content: center;">Reset</a>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Export/Print Action Buttons -->
                <div class="action-buttons-group">
                    <div>
                        <input type="text" id="searchInput" class="form-control" placeholder="Search report list..." style="max-width: 300px; width: 250px;">
                    </div>
                    <div style="display: flex; gap: 12px;">
                        <button class="btn btn-secondary" onclick="window.print()">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
                            <span>Print Report</span>
                        </button>
                        <button class="btn btn-success" onclick="exportToCSV()">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                            <span>Export CSV</span>
                        </button>
                    </div>
                </div>

                <!-- Aggregate Statistics summary block -->
                <div class="report-summary-stats">
                    <div class="card stat-card">
                        <div class="card-title" style="font-size: 13px; color: var(--text-secondary); text-transform: uppercase;">Total Listed Students</div>
                        <div class="stat-value" id="statStudents">0</div>
                    </div>
                    <div class="card stat-card success">
                        <div class="card-title" style="font-size: 13px; color: var(--text-secondary); text-transform: uppercase;">Average Attendance</div>
                        <div class="stat-value" id="statAverage">0.0%</div>
                    </div>
                    <div class="card stat-card danger">
                        <div class="card-title" style="font-size: 13px; color: var(--text-secondary); text-transform: uppercase;">Below Threshold (&lt;75%)</div>
                        <div class="stat-value" id="statBelow">0</div>
                    </div>
                </div>

                <!-- Report Result Table -->
                <div class="table-responsive">
                    <table class="table" id="reportTable">
                        <thead>
                            <tr>
                                <th>Roll Number</th>
                                <th>Student Name</th>
                                <th>Class Cohort</th>
                                <th>Total Sessions</th>
                                <th>Sessions Attended</th>
                                <th>Attendance %</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${empty reportData}">
                                    <tr>
                                        <td colspan="6" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                            No attendance logs found matching selected criteria.
                                        </td>
                                    </tr>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="row" items="${reportData}">
                                        <tr class="report-row" data-percentage="${row.percentage}">
                                            <td><strong>${row.rollNumber}</strong></td>
                                            <td>${row.studentName}</td>
                                            <td>${row.className}</td>
                                            <td>${row.totalSessions}</td>
                                            <td>${row.attendedSessions}</td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${row.percentage >= 75.0}">
                                                        <span class="badge badge-success" style="font-size: 13px; padding: 4px 12px;">
                                                            <c:formatNumber value="${row.percentage}" maxFractionDigits="1" />%
                                                        </span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge badge-danger" style="font-size: 13px; padding: 4px 12px;">
                                                            <c:formatNumber value="${row.percentage}" maxFractionDigits="1" />%
                                                        </span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Init client table filter search
        initTableSearch("reportTable", "searchInput", [0, 1, 2]);

        // Calculate aggregate statistics on table rows
        function calculateSummary() {
            const rows = document.querySelectorAll(".report-row");
            let totalStudents = rows.length;
            let sumPercentage = 0;
            let countBelowThreshold = 0;

            rows.forEach(row => {
                const percentage = parseFloat(row.getAttribute("data-percentage"));
                sumPercentage += percentage;
                if (percentage < 75.0) {
                    countBelowThreshold++;
                }
            });

            const avgPercentage = totalStudents > 0 ? (sumPercentage / totalStudents) : 0.0;

            document.getElementById("statStudents").innerText = totalStudents;
            document.getElementById("statAverage").innerText = avgPercentage.toFixed(1) + "%";
            document.getElementById("statBelow").innerText = countBelowThreshold;
        }

        // Run calculations on load
        calculateSummary();

        // Print date timestamp
        document.getElementById("printDate").innerText = new Date().toLocaleString();

        // Export URL Builder Function
        function exportToCSV() {
            const classId = document.getElementById("classFilter").value;
            const subjectId = document.getElementById("subjectFilter").value;
            const startDate = document.getElementById("startDateFilter").value;
            const endDate = document.getElementById("endDateFilter").value;
            
            let url = `${pageContext.request.contextPath}/teacher/reports?action=export`;
            if(classId) url += `&classId=${classId}`;
            if(subjectId) url += `&subjectId=${subjectId}`;
            if(startDate) url += `&startDate=${startDate}`;
            if(endDate) url += `&endDate=${endDate}`;
            
            window.location.href = url;
        }
    </script>
</body>
</html>
