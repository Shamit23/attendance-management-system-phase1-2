<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.dao.StudentDAO" %>
<%@ page import="com.ams.dao.ClassDAO" %>
<%@ page import="com.ams.dao.SubjectDAO" %>
<%@ page import="com.ams.model.Student" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.util.DBConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.GregorianCalendar" %>
<%@ page import="java.sql.Date" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Verify session credentials using standard server-side guards
    if (session == null || !"STUDENT".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    Integer studentId = (Integer) session.getAttribute("studentId");
    if (studentId == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    // Initialize DAOs
    StudentDAO studentDAO = new StudentDAO();
    ClassDAO classDAO = new ClassDAO();
    SubjectDAO subjectDAO = new SubjectDAO();

    Student student = studentDAO.getStudentById(studentId);
    if (student == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=profile_not_found");
        return;
    }

    ClassSection cls = classDAO.getClassById(student.getClassId());
    List<Subject> subjects = subjectDAO.getSubjectsByClass(student.getClassId());

    // Pull calendar parameters
    Calendar today = Calendar.getInstance();
    String monthStr = request.getParameter("month");
    String yearStr = request.getParameter("year");

    int currentMonth = (monthStr != null && !monthStr.isEmpty()) ? Integer.parseInt(monthStr) - 1 : today.get(Calendar.MONTH);
    int currentYear = (yearStr != null && !yearStr.isEmpty()) ? Integer.parseInt(yearStr) : today.get(Calendar.YEAR);

    // Calculate dates of selected calendar month
    Calendar cal = new GregorianCalendar(currentYear, currentMonth, 1);
    int leadDays = cal.get(Calendar.DAY_OF_WEEK) - 1; // Sunday is 1
    int daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH);

    // Date range parameters for log list tab
    String startDateStr = request.getParameter("startDate");
    String endDateStr = request.getParameter("endDate");
    String filterSubjectStr = request.getParameter("filterSubject");

    int filterSubjectId = 0;
    if (filterSubjectStr != null && !filterSubjectStr.isEmpty()) {
        try {
            filterSubjectId = Integer.parseInt(filterSubjectStr);
        } catch (NumberFormatException e) {}
    }

    // Tab active switcher
    String activeTab = request.getParameter("tab");
    if (activeTab == null || (!activeTab.equals("date") && !activeTab.equals("subject"))) {
        activeTab = "date";
    }

    // Database connections to fetch attendance logs
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // 1. Fetch all detailed logs for the student inside range/filters
    List<Map<String, Object>> attendanceLogs = new ArrayList<>();
    try {
        conn = DBConnection.getInstance().getConnection();
        StringBuilder sql = new StringBuilder(
            "SELECT a.attendance_date, a.slot, s.subject_name, s.subject_code, s.subject_id, ad.status, ad.remarks " +
            "FROM attendance a " +
            "JOIN attendance_details ad ON a.attendance_id = ad.attendance_id " +
            "JOIN subjects s ON a.subject_id = s.subject_id " +
            "WHERE ad.student_id = ? "
        );

        List<Object> params = new ArrayList<>();
        params.add(studentId);

        if (filterSubjectId > 0) {
            sql.append("AND s.subject_id = ? ");
            params.add(filterSubjectId);
        }
        if (startDateStr != null && !startDateStr.isEmpty()) {
            sql.append("AND a.attendance_date >= ? ");
            params.add(Date.valueOf(startDateStr));
        }
        if (endDateStr != null && !endDateStr.isEmpty()) {
            sql.append("AND a.attendance_date <= ? ");
            params.add(Date.valueOf(endDateStr));
        }

        sql.append("ORDER BY a.attendance_date DESC, a.slot ASC");

        ps = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) {
            ps.setObject(i + 1, params.get(i));
        }

        rs = ps.executeQuery();
        while (rs.next()) {
            Map<String, Object> log = new HashMap<>();
            log.put("date", rs.getDate("attendance_date"));
            log.put("slot", rs.getString("slot"));
            log.put("subjectName", rs.getString("subject_name"));
            log.put("subjectCode", rs.getString("subject_code"));
            log.put("subjectId", rs.getInt("subject_id"));
            log.put("status", rs.getString("status"));
            log.put("remarks", rs.getString("remarks"));
            attendanceLogs.add(log);
        }
    } catch (Exception e) {
        System.err.println("[AMS Student view-attendance] Logs fetch error: " + e.getMessage());
        e.printStackTrace();
    } finally {
        DBConnection.closeResultSet(rs);
        DBConnection.closeStatement(ps);
        DBConnection.closeConnection(conn);
    }

    // 2. Fetch specific month's attendance maps for calendar view
    Map<Integer, List<String>> dayStatusesMap = new HashMap<>();
    try {
        conn = DBConnection.getInstance().getConnection();
        String sql = 
            "SELECT DAY(a.attendance_date) as day_num, ad.status " +
            "FROM attendance a " +
            "JOIN attendance_details ad ON a.attendance_id = ad.attendance_id " +
            "WHERE ad.student_id = ? " +
            "  AND MONTH(a.attendance_date) = ? " +
            "  AND YEAR(a.attendance_date) = ?";

        ps = conn.prepareStatement(sql);
        ps.setInt(1, studentId);
        ps.setInt(2, currentMonth + 1);
        ps.setInt(3, currentYear);

        rs = ps.executeQuery();
        while (rs.next()) {
            int d = rs.getInt("day_num");
            String stat = rs.getString("status");
            if (!dayStatusesMap.containsKey(d)) {
                dayStatusesMap.put(d, new ArrayList<>());
            }
            dayStatusesMap.get(d).add(stat);
        }
    } catch (Exception e) {
        System.err.println("[AMS Student view-attendance] Calendar fetch error: " + e.getMessage());
        e.printStackTrace();
    } finally {
        DBConnection.closeResultSet(rs);
        DBConnection.closeStatement(ps);
        DBConnection.closeConnection(conn);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Student Portal - View Attendance</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        /* Tabs styles */
        .tab-buttons {
            display: flex;
            border-bottom: 2px solid var(--border-color);
            margin-bottom: 24px;
            gap: 16px;
        }
        .tab-btn {
            background: none;
            border: none;
            padding: 12px 16px;
            font-size: 15px;
            font-weight: 600;
            color: var(--text-secondary);
            cursor: pointer;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
            transition: all 0.3s ease;
        }
        .tab-btn:hover {
            color: var(--accent);
        }
        .tab-btn.active {
            color: var(--accent);
            border-bottom-color: var(--accent);
        }
        .tab-pane {
            display: none;
        }
        .tab-pane.active {
            display: block;
        }

        /* Calendar month view grid layout */
        .calendar-control-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            padding: 16px 20px;
            border-radius: var(--border-radius-sm);
        }
        .calendar-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 8px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            padding: 16px;
            border-radius: var(--border-radius-md);
            box-shadow: var(--shadow-sm);
        }
        .calendar-header-day {
            text-align: center;
            font-weight: 600;
            font-size: 13px;
            color: var(--text-secondary);
            padding: 10px 0;
            text-transform: uppercase;
        }
        .calendar-day-cell {
            position: relative;
            background-color: var(--bg-app);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            aspect-ratio: 1.2;
            padding: 8px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: flex-end;
            transition: transform 0.2s ease;
        }
        .calendar-day-cell.empty {
            background-color: transparent;
            border-color: transparent;
        }
        .calendar-day-cell .day-num {
            font-weight: 600;
            font-size: 13px;
            color: var(--text-primary);
        }
        .calendar-dot-indicators {
            display: flex;
            gap: 4px;
            margin-top: auto;
            align-self: center;
        }
        .indicator-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
        }
        .indicator-dot.present { background-color: var(--success-color); }
        .indicator-dot.absent { background-color: var(--danger-color); }
        .indicator-dot.late { background-color: var(--warning-color); }

        /* Filter layout card */
        .filter-panel {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            padding: 16px 20px;
            margin-bottom: 24px;
        }
        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)) auto;
            gap: 16px;
            align-items: flex-end;
        }
    </style>
</head>
<body>
    <div class="app-wrapper">
        <!-- Reusable student sidebar Navigation include -->
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
                    <h2>View Attendance Records</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Tab switcher navigation menu -->
                <div class="tab-buttons">
                    <a href="view-attendance.jsp?tab=date" class="tab-btn <%= activeTab.equals("date") ? "active" : "" %>">By Date (Calendar)</a>
                    <a href="view-attendance.jsp?tab=subject" class="tab-btn <%= activeTab.equals("subject") ? "active" : "" %>">By Subject (Logs List)</a>
                </div>

                <!-- Tab Pane 1: By Date calendar grid -->
                <div class="tab-pane <%= activeTab.equals("date") ? "active" : "" %> animate-fade">
                    <div class="calendar-control-bar animate-fade">
                        <a href="view-attendance.jsp?tab=date&month=<%= (currentMonth == 0) ? 12 : currentMonth %>&year=<%= (currentMonth == 0) ? currentYear - 1 : currentYear %>" class="btn btn-secondary" style="padding: 8px 16px;">
                            &larr; Previous Month
                        </a>
                        <h3 style="margin: 0; font-size: 18px; color: var(--text-primary);">
                            <%= new java.text.DateFormatSymbols().getMonths()[currentMonth] %> <%= currentYear %>
                        </h3>
                        <a href="view-attendance.jsp?tab=date&month=<%= (currentMonth == 11) ? 1 : currentMonth + 2 %>&year=<%= (currentMonth == 11) ? currentYear + 1 : currentYear %>" class="btn btn-secondary" style="padding: 8px 16px;">
                            Next Month &rarr;
                        </a>
                    </div>

                    <!-- Calendar Grid Wrapper -->
                    <div class="calendar-grid animate-fade">
                        <!-- Week Header labels -->
                        <div class="calendar-header-day">Sun</div>
                        <div class="calendar-header-day">Mon</div>
                        <div class="calendar-header-day">Tue</div>
                        <div class="calendar-header-day">Wed</div>
                        <div class="calendar-header-day">Thu</div>
                        <div class="calendar-header-day">Fri</div>
                        <div class="calendar-header-day">Sat</div>

                        <!-- Lead padding days -->
                        <% for (int i = 0; i < leadDays; i++) { %>
                            <div class="calendar-day-cell empty"></div>
                        <% } %>

                        <!-- Days of Month cells loop -->
                        <% 
                            for (int day = 1; day <= daysInMonth; day++) {
                                List<String> dayStatuses = dayStatusesMap.get(day);
                                String dayDotColor = null;
                                if (dayStatuses != null && !dayStatuses.isEmpty()) {
                                    boolean hasAbsent = dayStatuses.contains("A") || dayStatuses.contains("ABSENT");
                                    boolean hasPresent = dayStatuses.contains("P") || dayStatuses.contains("PRESENT") ||
                                                         dayStatuses.contains("L") || dayStatuses.contains("LATE") ||
                                                         dayStatuses.contains("E") || dayStatuses.contains("EXCUSED");
                                    if (hasPresent && !hasAbsent) {
                                        dayDotColor = "present"; // Present in all slots
                                    } else if (!hasPresent && hasAbsent) {
                                        dayDotColor = "absent"; // Absent in all slots
                                    } else {
                                        dayDotColor = "late"; // Mixed or Late
                                    }
                                }
                        %>
                            <div class="calendar-day-cell">
                                <span class="day-num"><%= day %></span>
                                <% if (dayDotColor != null) { %>
                                    <div class="calendar-dot-indicators">
                                        <div class="indicator-dot <%= dayDotColor %>" title="<%= dayDotColor.substring(0, 1).toUpperCase() + dayDotColor.substring(1) %> status today"></div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Tab Pane 2: By Subject Logs list -->
                <div class="tab-pane <%= activeTab.equals("subject") ? "active" : "" %> animate-fade">
                    <!-- Filters section -->
                    <div class="filter-panel animate-fade">
                        <form method="GET" action="view-attendance.jsp">
                            <input type="hidden" name="tab" value="subject">
                            <div class="filter-grid">
                                <div class="form-group" style="margin-bottom: 0;">
                                    <label class="form-label">Subject</label>
                                    <select name="filterSubject" class="form-control">
                                        <option value="">-- All Subjects --</option>
                                        <% for (Subject s : subjects) { %>
                                            <option value="<%= s.getId() %>" <%= filterSubjectId == s.getId() ? "selected" : "" %>><%= s.getCode() %> - <%= s.getName() %></option>
                                        <% } %>
                                    </select>
                                </div>
                                <div class="form-group" style="margin-bottom: 0;">
                                    <label class="form-label">Start Date</label>
                                    <input type="date" name="startDate" class="form-control" value="<%= startDateStr != null ? startDateStr : "" %>">
                                </div>
                                <div class="form-group" style="margin-bottom: 0;">
                                    <label class="form-label">End Date</label>
                                    <input type="date" name="endDate" class="form-control" value="<%= endDateStr != null ? endDateStr : "" %>">
                                </div>
                                <div style="display: flex; gap: 8px;">
                                    <button type="submit" class="btn btn-primary" style="padding: 10px 18px;">Apply</button>
                                    <a href="view-attendance.jsp?tab=subject" class="btn btn-secondary" style="padding: 10px 14px;">Reset</a>
                                </div>
                            </div>
                        </form>
                    </div>

                    <!-- Attendance logs list table -->
                    <div class="card animate-fade" style="padding: 24px;">
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Date</th>
                                        <th>Subject</th>
                                        <th>Slot</th>
                                        <th>Status</th>
                                        <th>Remarks</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (attendanceLogs.isEmpty()) { %>
                                        <tr>
                                            <td colspan="5" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                                No attendance logs found matching selected criteria.
                                            </td>
                                        </tr>
                                    <% } else {
                                        for (Map<String, Object> log : attendanceLogs) {
                                            String status = (String) log.get("status");
                                            String badgeClass = "badge-success";
                                            String statusLabel = "Present";
                                            if ("A".equals(status) || "ABSENT".equals(status)) {
                                                badgeClass = "badge-danger";
                                                statusLabel = "Absent";
                                            } else if ("L".equals(status) || "LATE".equals(status)) {
                                                badgeClass = "badge-warning";
                                                statusLabel = "Late";
                                            } else if ("E".equals(status) || "EXCUSED".equals(status)) {
                                                badgeClass = "badge-info";
                                                statusLabel = "Excused";
                                            }
                                    %>
                                        <tr>
                                            <td><strong><%= log.get("date") %></strong></td>
                                            <td><strong><%= log.get("subjectCode") %></strong> - <%= log.get("subjectName") %></td>
                                            <td><span style="font-size: 12px; color: var(--text-secondary);"><%= log.get("slot") %></span></td>
                                            <td><span class="badge <%= badgeClass %>"><%= statusLabel %></span></td>
                                            <td><span style="font-style: italic; color: var(--text-secondary);"><%= log.get("remarks") != null && !log.get("remarks").toString().isEmpty() ? log.get("remarks") : "-" %></span></td>
                                        </tr>
                                    <% } 
                                    } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
