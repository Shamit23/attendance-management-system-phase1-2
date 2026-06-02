<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="com.ams.model.Teacher" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%
    // Verify session role standard guards
    if (session == null || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    String reportType = (String) request.getAttribute("reportType");
    if (reportType == null) {
        reportType = "general";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Admin - Advanced Attendance Reports</title>
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
            .main-header,
            .filter-card,
            .action-buttons-group,
            .btn {
                display: none !important;
            }
            .main-content {
                margin-left: 0 !important;
                padding: 0 !important;
            }
            .content-body {
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
        <!-- Reusable Sidebar Include -->
        <%@ include file="admin-sidebar.jsp" %>

        <div class="main-content">
            <!-- Header bar layout -->
            <header class="main-header">
                <button class="sidebar-toggle-btn hamburger-btn" aria-label="Toggle Navigation">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                </button>
                <div class="header-title">
                    <h2>Advanced Attendance Reports</h2>
                </div>
            </header>

            <main class="content-body animate-fade">
                
                <!-- Print Heading -->
                <div class="print-title">
                    <h2>AMS Attendance Analysis Report</h2>
                    <p>Report Category: <span style="text-transform: uppercase;"><%= reportType %></span></p>
                    <p>Generated on: <span id="printDate"></span></p>
                </div>

                <!-- Filter Controls Card -->
                <div class="card filter-card">
                    <div class="card-header" style="margin-bottom: 12px; padding-bottom: 0;">
                        <h4 class="card-title" style="margin: 0; color: var(--primary);">Filter Selection & Report Types</h4>
                    </div>
                    <div class="card-body">
                        <form method="GET" action="${pageContext.request.contextPath}/admin/reports" id="filterForm">
                            <div class="form-group" style="max-width: 320px; margin-bottom: 16px;">
                                <label class="form-label">Select Report Type</label>
                                <select name="action" id="reportTypeSelect" class="form-control" onchange="toggleFilterFields()">
                                    <option value="" <%= "general".equals(reportType) ? "selected" : "" %>>General Cumulative Filter Report</option>
                                    <option value="dailyReport" <%= "daily".equals(reportType) ? "selected" : "" %>>Daily Conducted Classes Report</option>
                                    <option value="monthlyReport" <%= "monthly".equals(reportType) ? "selected" : "" %>>Monthly Attendance Summary</option>
                                    <option value="subjectReport" <%= "subject".equals(reportType) ? "selected" : "" %>>Subject Performance Report</option>
                                    <option value="lowAttendance" <%= "low".equals(reportType) ? "selected" : "" %>>Critical Low Attendance (<75%)</option>
                                </select>
                            </div>

                            <div class="filter-form-grid">
                                <!-- Field group: Class -->
                                <div class="form-group filter-field" id="fieldClass">
                                    <label class="form-label">Class Cohort</label>
                                    <select name="classId" id="classFilter" class="form-control">
                                        <option value="">-- All Classes --</option>
                                        <c:forEach var="cls" items="${classes}">
                                            <option value="${cls.id}" ${param.classId == cls.id || selectedClassId == cls.id ? 'selected' : ''}>${cls.name}</option>
                                        </c:forEach>
                                    </select>
                                </div>

                                <!-- Field group: Subject -->
                                <div class="form-group filter-field" id="fieldSubject">
                                    <label class="form-label">Subject</label>
                                    <select name="subjectId" id="subjectFilter" class="form-control">
                                        <option value="">-- All Subjects --</option>
                                        <c:forEach var="sub" items="${subjects}">
                                            <option value="${sub.id}" ${param.subjectId == sub.id || selectedSubjectId == sub.id ? 'selected' : ''}>${sub.name} (${sub.code})</option>
                                        </c:forEach>
                                    </select>
                                </div>

                                <!-- Field group: Teacher -->
                                <div class="form-group filter-field" id="fieldTeacher">
                                    <label class="form-label">Teacher</label>
                                    <select name="teacherId" id="teacherFilter" class="form-control">
                                        <option value="">-- All Teachers --</option>
                                        <c:forEach var="t" items="${teachers}">
                                            <option value="${t.id}" ${param.teacherId == t.id ? 'selected' : ''}>${t.firstName} ${t.lastName}</option>
                                        </c:forEach>
                                    </select>
                                </div>

                                <!-- Field group: Start Date -->
                                <div class="form-group filter-field" id="fieldStartDate">
                                    <label class="form-label">Start Date</label>
                                    <input type="date" name="startDate" id="startDateFilter" class="form-control" value="${param.startDate}">
                                </div>

                                <!-- Field group: End Date -->
                                <div class="form-group filter-field" id="fieldEndDate">
                                    <label class="form-label">End Date</label>
                                    <input type="date" name="endDate" id="endDateFilter" class="form-control" value="${param.endDate}">
                                </div>

                                <!-- Field group: Single Date -->
                                <div class="form-group filter-field" id="fieldSingleDate" style="display: none;">
                                    <label class="form-label">Select Date</label>
                                    <input type="date" name="date" id="singleDateFilter" class="form-control" value="${selectedDate}">
                                </div>

                                <!-- Field group: Month -->
                                <div class="form-group filter-field" id="fieldMonth" style="display: none;">
                                    <label class="form-label">Month</label>
                                    <select name="month" id="monthFilter" class="form-control">
                                        <option value="1" ${selectedMonth == 1 ? 'selected' : ''}>January</option>
                                        <option value="2" ${selectedMonth == 2 ? 'selected' : ''}>February</option>
                                        <option value="3" ${selectedMonth == 3 ? 'selected' : ''}>March</option>
                                        <option value="4" ${selectedMonth == 4 ? 'selected' : ''}>April</option>
                                        <option value="5" ${selectedMonth == 5 ? 'selected' : ''}>May</option>
                                        <option value="6" ${selectedMonth == 6 ? 'selected' : ''}>June</option>
                                        <option value="7" ${selectedMonth == 7 ? 'selected' : ''}>July</option>
                                        <option value="8" ${selectedMonth == 8 ? 'selected' : ''}>August</option>
                                        <option value="9" ${selectedMonth == 9 ? 'selected' : ''}>September</option>
                                        <option value="10" ${selectedMonth == 10 ? 'selected' : ''}>October</option>
                                        <option value="11" ${selectedMonth == 11 ? 'selected' : ''}>November</option>
                                        <option value="12" ${selectedMonth == 12 ? 'selected' : ''}>December</option>
                                    </select>
                                </div>

                                <!-- Field group: Year -->
                                <div class="form-group filter-field" id="fieldYear" style="display: none;">
                                    <label class="form-label">Year</label>
                                    <select name="year" id="yearFilter" class="form-control">
                                        <option value="2025" ${selectedYear == 2025 ? 'selected' : ''}>2025</option>
                                        <option value="2026" ${selectedYear == 2026 ? 'selected' : ''}>2026</option>
                                        <option value="2027" ${selectedYear == 2027 ? 'selected' : ''}>2027</option>
                                    </select>
                                </div>

                                <div class="form-group" style="display: flex; gap: 8px;">
                                    <button type="submit" class="btn btn-primary" style="flex: 1; height: 45px;">Apply</button>
                                    <a href="${pageContext.request.contextPath}/admin/reports" class="btn btn-secondary" style="flex: 1; height: 45px; display: flex; align-items: center; justify-content: center;">Reset</a>
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

                <!-- Stats summary block -->
                <% if (!"daily".equals(reportType)) { %>
                    <div class="report-summary-stats animate-fade">
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
                <% } %>

                <!-- Report Result Table -->
                <div class="card animate-fade" style="padding: 24px;">
                    <div class="table-responsive">
                        <table class="table" id="reportTable">
                            
                            <!-- Case A: Daily log layout -->
                            <% if ("daily".equals(reportType)) { %>
                                <thead>
                                    <tr>
                                        <th>Class Cohort</th>
                                        <th>Subject Code</th>
                                        <th>Subject Name</th>
                                        <th>Faculty Teacher</th>
                                        <th>Slot</th>
                                        <th style="text-align: center;">Total Enrolled</th>
                                        <th style="text-align: center;">Present</th>
                                        <th style="text-align: center;">Absent</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:choose>
                                        <c:when test="${empty dailyReportData}">
                                            <tr>
                                                <td colspan="8" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                                    No classes recorded conducted on the selected date.
                                                </td>
                                            </tr>
                                        </c:when>
                                        <c:otherwise>
                                            <c:forEach var="row" items="${dailyReportData}">
                                                <tr>
                                                    <td><span class="badge badge-accent">${row.className}</span></td>
                                                    <td><strong>${row.subjectCode}</strong></td>
                                                    <td>${row.subjectName}</td>
                                                    <td>${row.teacherName}</td>
                                                    <td><span style="font-size: 12px; color: var(--text-secondary);">${row.slot}</span></td>
                                                    <td style="text-align: center;">${row.total}</td>
                                                    <td style="text-align: center;"><span class="badge badge-success">${row.present}</span></td>
                                                    <td style="text-align: center;"><span class="badge badge-danger">${row.absent}</span></td>
                                                </tr>
                                            </c:forEach>
                                        </c:otherwise>
                                    </c:choose>
                                </tbody>

                            <!-- Case B: Monthly summaries, subject summaries, low defaults, and standard cumulative tables -->
                            <% } else { %>
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
                                    <% 
                                        String listAttr = "reportData";
                                        if ("monthly".equals(reportType)) listAttr = "monthlyReportData";
                                        else if ("subject".equals(reportType)) listAttr = "subjectReportData";
                                        else if ("low".equals(reportType)) listAttr = "lowReportData";
                                        request.setAttribute("activeList", request.getAttribute(listAttr));
                                    %>
                                    <c:choose>
                                        <c:when test="${empty activeList}">
                                            <tr>
                                                <td colspan="6" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                                    No attendance logs found matching selected criteria.
                                                </td>
                                            </tr>
                                        </c:when>
                                        <c:otherwise>
                                            <c:forEach var="row" items="${activeList}">
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
                                                                    <fmt:formatNumber value="${row.percentage}" maxFractionDigits="1" />%
                                                                </span>
                                                            </c:when>
                                                            <c:when test="${row.percentage >= 60.0}">
                                                                <span class="badge badge-warning" style="font-size: 13px; padding: 4px 12px;">
                                                                    <fmt:formatNumber value="${row.percentage}" maxFractionDigits="1" />%
                                                                </span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge badge-danger" style="font-size: 13px; padding: 4px 12px;">
                                                                    <fmt:formatNumber value="${row.percentage}" maxFractionDigits="1" />%
                                                                </span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                        </c:otherwise>
                                    </c:choose>
                                </tbody>
                            <% } %>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Init client table filter search
        initTableSearch("reportTable", "searchInput", [0, 1, 2]);

        // Toggle filter view fields dynamically on selection change
        function toggleFilterFields() {
            const reportType = document.getElementById("reportTypeSelect").value;
            
            // Default: show class, subject, teacher, start/end dates
            document.querySelectorAll(".filter-field").forEach(el => el.style.display = "block");
            
            // Hide special fields
            document.getElementById("fieldSingleDate").style.display = "none";
            document.getElementById("fieldMonth").style.display = "none";
            document.getElementById("fieldYear").style.display = "none";

            if (reportType === "dailyReport") {
                // Daily report: Only show Single Date field
                document.querySelectorAll(".filter-field").forEach(el => el.style.display = "none");
                document.getElementById("fieldSingleDate").style.display = "block";
            } else if (reportType === "monthlyReport") {
                // Monthly summary: Show Class, Month, Year
                document.querySelectorAll(".filter-field").forEach(el => el.style.display = "none");
                document.getElementById("fieldClass").style.display = "block";
                document.getElementById("fieldMonth").style.display = "block";
                document.getElementById("fieldYear").style.display = "block";
            } else if (reportType === "subjectReport") {
                // Subject: Only show Subject selector
                document.querySelectorAll(".filter-field").forEach(el => el.style.display = "none");
                document.getElementById("fieldSubject").style.display = "block";
            } else if (reportType === "lowAttendance") {
                // Low attendance: Hide all filters (it lists all defaults automatically)
                document.querySelectorAll(".filter-field").forEach(el => el.style.display = "none");
            }
        }

        // Calculate aggregate statistics on table rows
        function calculateSummary() {
            const rows = document.querySelectorAll(".report-row");
            if (rows.length === 0) return;

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

            const stEl = document.getElementById("statStudents");
            const avEl = document.getElementById("statAverage");
            const blEl = document.getElementById("statBelow");

            if(stEl) stEl.innerText = totalStudents;
            if(avEl) avEl.innerText = avgPercentage.toFixed(1) + "%";
            if(blEl) blEl.innerText = countBelowThreshold;
        }

        // Run calculations on load
        calculateSummary();
        toggleFilterFields();

        // Print date timestamp
        document.getElementById("printDate").innerText = new Date().toLocaleString();

        // Export URL Builder Function
        function exportToCSV() {
            const reportType = document.getElementById("reportTypeSelect").value;
            const classId = document.getElementById("classFilter").value;
            const subjectId = document.getElementById("subjectFilter").value;
            const teacherId = document.getElementById("teacherFilter").value;
            const startDate = document.getElementById("startDateFilter").value;
            const endDate = document.getElementById("endDateFilter").value;
            const singleDate = document.getElementById("singleDateFilter").value;
            const month = document.getElementById("monthFilter").value;
            const year = document.getElementById("yearFilter").value;
            
            let url = `${pageContext.request.contextPath}/admin/reports?format=csv`;
            if (reportType) {
                url += `&action=${reportType}`;
            }
            
            if (reportType === "dailyReport") {
                if(singleDate) url += `&date=${singleDate}`;
            } else if (reportType === "monthlyReport") {
                if(classId) url += `&classId=${classId}`;
                if(month) url += `&month=${month}`;
                if(year) url += `&year=${year}`;
            } else if (reportType === "subjectReport") {
                if(subjectId) url += `&subjectId=${subjectId}`;
            } else {
                if(classId) url += `&classId=${classId}`;
                if(subjectId) url += `&subjectId=${subjectId}`;
                if(teacherId) url += `&teacherId=${teacherId}`;
                if(startDate) url += `&startDate=${startDate}`;
                if(endDate) url += `&endDate=${endDate}`;
            }
            
            window.location.href = url;
        }
    </script>
</body>
</html>
