<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.dao.StudentDAO" %>
<%@ page import="com.ams.dao.SubjectDAO" %>
<%@ page import="com.ams.dao.ClassDAO" %>
<%@ page import="com.ams.dao.AttendanceDAO" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.util.DBConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Verify session credentials using standard server-side guards
    if (session == null || !"TEACHER".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    Integer teacherId = (Integer) session.getAttribute("teacherId");
    if (teacherId == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    // Initialize DAOs
    SubjectDAO subjectDAO = new SubjectDAO();
    ClassDAO classDAO = new ClassDAO();
    AttendanceDAO attendanceDAO = new AttendanceDAO();
    StudentDAO studentDAO = new StudentDAO();

    List<Subject> subjects = subjectDAO.getSubjectsByTeacher(teacherId);

    // Filters
    String filterSubjectStr = request.getParameter("filterSubject");
    String filterMonthStr = request.getParameter("filterMonth");
    String filterYearStr = request.getParameter("filterYear");

    int filterSubjectId = 0;
    if (filterSubjectStr != null && !filterSubjectStr.isEmpty()) {
        try {
            filterSubjectId = Integer.parseInt(filterSubjectStr);
        } catch (NumberFormatException e) {}
    }

    int filterMonth = 0;
    if (filterMonthStr != null && !filterMonthStr.isEmpty()) {
        try {
            filterMonth = Integer.parseInt(filterMonthStr);
        } catch (NumberFormatException e) {}
    }

    int filterYear = 0;
    if (filterYearStr != null && !filterYearStr.isEmpty()) {
        try {
            filterYear = Integer.parseInt(filterYearStr);
        } catch (NumberFormatException e) {}
    }

    // Fetch and count attendance sessions dynamically
    List<Map<String, Object>> sessionsList = new ArrayList<>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getInstance().getConnection();
        StringBuilder sql = new StringBuilder(
            "SELECT a.attendance_id, a.attendance_date, a.slot, c.class_name, s.subject_id, s.subject_name, s.subject_code " +
            "FROM attendance a " +
            "JOIN classes c ON a.class_id = c.class_id " +
            "JOIN subjects s ON a.subject_id = s.subject_id " +
            "WHERE a.teacher_id = ? "
        );
        
        List<Object> params = new ArrayList<>();
        params.add(teacherId);

        if (filterSubjectId > 0) {
            sql.append("AND a.subject_id = ? ");
            params.add(filterSubjectId);
        }
        if (filterMonth > 0) {
            sql.append("AND MONTH(a.attendance_date) = ? ");
            params.add(filterMonth);
        }
        if (filterYear > 0) {
            sql.append("AND YEAR(a.attendance_date) = ? ");
            params.add(filterYear);
        }

        sql.append("ORDER BY a.attendance_date DESC, a.attendance_id DESC");

        ps = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) {
            ps.setObject(i + 1, params.get(i));
        }

        rs = ps.executeQuery();
        while (rs.next()) {
            int attId = rs.getInt("attendance_id");
            Date date = rs.getDate("attendance_date");
            String slot = rs.getString("slot");
            String className = rs.getString("class_name");
            String subjectName = rs.getString("subject_name");
            String subjectCode = rs.getString("subject_code");
            int subId = rs.getInt("subject_id");

            // Calculate present/absent/late counts
            List<com.ams.model.AttendanceDetail> details = attendanceDAO.getAttendanceDetailsByMasterId(attId);
            int presentCount = 0;
            int absentCount = 0;
            int lateCount = 0;

            List<Map<String, Object>> studentDetailsList = new ArrayList<>();

            for (com.ams.model.AttendanceDetail detail : details) {
                String status = detail.getStatus();
                if ("P".equals(status)) presentCount++;
                else if ("A".equals(status)) absentCount++;
                else if ("L".equals(status)) lateCount++;

                com.ams.model.Student studentObj = studentDAO.getStudentById(detail.getStudentId());
                if (studentObj != null) {
                    Map<String, Object> detMap = new HashMap<>();
                    detMap.put("rollNo", studentObj.getRollNo());
                    detMap.put("name", studentObj.getFirstName() + " " + studentObj.getLastName());
                    detMap.put("status", status);
                    detMap.put("remarks", detail.getRemarks() != null ? detail.getRemarks() : "");
                    studentDetailsList.add(detMap);
                }
            }

            Map<String, Object> sessionMap = new HashMap<>();
            sessionMap.put("id", attId);
            sessionMap.put("subjectId", subId);
            sessionMap.put("date", date);
            sessionMap.put("slot", slot);
            sessionMap.put("className", className);
            sessionMap.put("subjectName", subjectName);
            sessionMap.put("subjectCode", subjectCode);
            sessionMap.put("presentCount", presentCount);
            sessionMap.put("absentCount", absentCount);
            sessionMap.put("lateCount", lateCount);
            sessionMap.put("studentDetails", studentDetailsList);

            sessionsList.add(sessionMap);
        }
    } catch (Exception e) {
        System.err.println("[AMS History] Query error: " + e.getMessage());
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
    <title>AMS Teacher - Attendance History</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .filter-section {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 20px;
            margin-bottom: 24px;
            box-shadow: var(--shadow-sm);
        }
        .filter-grid {
            display: grid;
            grid-template-columns: 2fr 1fr 1fr auto;
            gap: 16px;
            align-items: flex-end;
        }
        @media (max-width: 768px) {
            .filter-grid {
                grid-template-columns: 1fr;
            }
        }
        .details-table {
            width: 100%;
            border-collapse: collapse;
            background-color: var(--bg-card);
            border-radius: var(--border-radius-sm);
            overflow: hidden;
            margin: 10px 0;
            border: 1px solid var(--border-color);
        }
        .details-table th, .details-table td {
            padding: 10px 16px;
            font-size: 13px;
            border-bottom: 1px solid var(--border-color);
            text-align: left;
        }
        .details-table th {
            background-color: var(--primary-light);
            color: white;
            font-weight: 600;
        }
        .details-row-container {
            padding: 16px 24px;
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
                    <h2>Attendance Logs & History</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Filters panel -->
                <div class="filter-section animate-fade">
                    <form method="GET" action="attendance-history.jsp">
                        <div class="filter-grid">
                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Filter by Subject</label>
                                <select name="filterSubject" class="form-control">
                                    <option value="">-- All Subjects --</option>
                                    <% for (Subject s : subjects) { 
                                        ClassSection c = classDAO.getClassById(s.getClassId());
                                    %>
                                        <option value="<%= s.getId() %>" <%= filterSubjectId == s.getId() ? "selected" : "" %>>
                                            <%= s.getCode() %> - <%= s.getName() %> (<%= c != null ? c.getName() : "Unassigned" %>)
                                        </option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Month</label>
                                <select name="filterMonth" class="form-control">
                                    <option value="">-- All Months --</option>
                                    <option value="1" <%= filterMonth == 1 ? "selected" : "" %>>January</option>
                                    <option value="2" <%= filterMonth == 2 ? "selected" : "" %>>February</option>
                                    <option value="3" <%= filterMonth == 3 ? "selected" : "" %>>March</option>
                                    <option value="4" <%= filterMonth == 4 ? "selected" : "" %>>April</option>
                                    <option value="5" <%= filterMonth == 5 ? "selected" : "" %>>May</option>
                                    <option value="6" <%= filterMonth == 6 ? "selected" : "" %>>June</option>
                                    <option value="7" <%= filterMonth == 7 ? "selected" : "" %>>July</option>
                                    <option value="8" <%= filterMonth == 8 ? "selected" : "" %>>August</option>
                                    <option value="9" <%= filterMonth == 9 ? "selected" : "" %>>September</option>
                                    <option value="10" <%= filterMonth == 10 ? "selected" : "" %>>October</option>
                                    <option value="11" <%= filterMonth == 11 ? "selected" : "" %>>November</option>
                                    <option value="12" <%= filterMonth == 12 ? "selected" : "" %>>December</option>
                                </select>
                            </div>

                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Year</label>
                                <select name="filterYear" class="form-control">
                                    <option value="">-- All Years --</option>
                                    <option value="2025" <%= filterYear == 2025 ? "selected" : "" %>>2025</option>
                                    <option value="2026" <%= filterYear == 2026 ? "selected" : "" %>>2026</option>
                                    <option value="2027" <%= filterYear == 2027 ? "selected" : "" %>>2027</option>
                                </select>
                            </div>

                            <div style="display: flex; gap: 8px;">
                                <button type="submit" class="btn btn-primary" style="padding: 10px 20px;">Filter</button>
                                <a href="attendance-history.jsp" class="btn btn-secondary" style="padding: 10px 16px;">Clear</a>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- History Table Cards -->
                <div class="card animate-fade" style="padding: 24px;">
                    <div class="table-responsive">
                        <table class="table" style="width: 100%;">
                            <thead>
                                <tr>
                                    <th>Session Date</th>
                                    <th>Class Section</th>
                                    <th>Subject Description</th>
                                    <th style="text-align: center;">Present</th>
                                    <th style="text-align: center;">Absent</th>
                                    <th style="text-align: center;">Late</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (sessionsList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="7" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                            No recorded attendance sessions matching the selected filter options.
                                        </td>
                                    </tr>
                                <% } else { 
                                    for (Map<String, Object> s : sessionsList) {
                                        int sId = (Integer) s.get("id");
                                %>
                                    <!-- Main Session Info Row -->
                                    <tr style="border-bottom: 1px solid var(--border-color);">
                                        <td><strong><%= s.get("date") %></strong><br><span style="font-size: 11px; color: var(--text-muted);"><%= s.get("slot") %></span></td>
                                        <td><span class="badge badge-accent"><%= s.get("className") %></span></td>
                                        <td><strong><%= s.get("subjectCode") %></strong> - <%= s.get("subjectName") %></td>
                                        <td style="text-align: center;"><span class="badge badge-success"><%= s.get("presentCount") %></span></td>
                                        <td style="text-align: center;"><span class="badge badge-danger"><%= s.get("absentCount") %></span></td>
                                        <td style="text-align: center;"><span class="badge badge-warning"><%= s.get("lateCount") %></span></td>
                                        <td>
                                            <div style="display: flex; gap: 8px;">
                                                <button class="btn btn-secondary" onclick="toggleDetails(<%= sId %>)" style="padding: 6px 12px; font-size: 13px;">
                                                    View Details
                                                </button>
                                                <a href="mark-attendance.jsp?subjectId=<%= s.get("subjectId") %>&date=<%= s.get("date") %>&slot=<%= s.get("slot") %>" 
                                                   class="btn btn-accent" style="padding: 6px 12px; font-size: 13px;">
                                                    Edit
                                                </a>
                                            </div>
                                        </td>
                                    </tr>

                                    <!-- Collapsible Detail Log Row -->
                                    <tr id="details-<%= sId %>" style="display: none; background-color: var(--bg-app);">
                                        <td colspan="7">
                                            <div class="details-row-container animate-fade">
                                                <h4 style="margin-top: 0; margin-bottom: 12px; font-size: 14px; color: var(--primary);">Detailed Student Log for Session #<%= sId %></h4>
                                                
                                                <table class="details-table">
                                                    <thead>
                                                        <tr>
                                                            <th>Roll No</th>
                                                            <th>Student Name</th>
                                                            <th>Attendance Status</th>
                                                            <th>Remarks</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <% 
                                                            List<Map<String, Object>> studDetails = (List<Map<String, Object>>) s.get("studentDetails");
                                                            for (Map<String, Object> sd : studDetails) {
                                                                String status = (String) sd.get("status");
                                                                String badgeClass = "badge-success";
                                                                String statusLabel = "Present";
                                                                if ("A".equals(status)) {
                                                                    badgeClass = "badge-danger";
                                                                    statusLabel = "Absent";
                                                                } else if ("L".equals(status)) {
                                                                    badgeClass = "badge-warning";
                                                                    statusLabel = "Late";
                                                                } else if ("E".equals(status)) {
                                                                    badgeClass = "badge-info";
                                                                    statusLabel = "Excused";
                                                                }
                                                        %>
                                                            <tr>
                                                                <td><strong><%= sd.get("rollNo") %></strong></td>
                                                                <td><%= sd.get("name") %></td>
                                                                <td><span class="badge <%= badgeClass %>"><%= statusLabel %></span></td>
                                                                <td><span style="font-style: italic; color: var(--text-secondary);"><%= sd.get("remarks") != null && !sd.get("remarks").toString().isEmpty() ? sd.get("remarks") : "-" %></span></td>
                                                            </tr>
                                                        <% } %>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </td>
                                    </tr>
                                <% } 
                                } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Collapsible Detail rows selector toggles
        function toggleDetails(sessionId) {
            const detailRow = document.getElementById('details-' + sessionId);
            if (detailRow.style.display === 'none') {
                detailRow.style.display = 'table-row';
            } else {
                detailRow.style.display = 'none';
            }
        }
    </script>
</body>
</html>
