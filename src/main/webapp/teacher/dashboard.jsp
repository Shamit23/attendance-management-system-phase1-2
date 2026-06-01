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

    // Initialize DAOs to fetch dynamic metrics
    StudentDAO studentDAO = new StudentDAO();
    SubjectDAO subjectDAO = new SubjectDAO();
    ClassDAO classDAO = new ClassDAO();
    AttendanceDAO attendanceDAO = new AttendanceDAO();

    // Fetch assigned subjects
    List<Subject> subjects = subjectDAO.getSubjectsByTeacher(teacherId);
    int assignedSubjectsCount = subjects.size();

    // Total distinct students taught
    java.util.Set<Integer> classIds = new java.util.HashSet<>();
    for (Subject s : subjects) {
        classIds.add(s.getClassId());
    }

    int totalStudents = 0;
    for (Integer cid : classIds) {
        totalStudents += studentDAO.getStudentsByClass(cid).size();
    }

    int classesToday = classIds.size();

    // Average attendance for this teacher
    double avgAttendance = attendanceDAO.getTeacherAverageAttendance(teacherId);

    // Fetch pending attendance alerts for today
    Date today = new Date(System.currentTimeMillis());
    List<Subject> pendingSubjects = new ArrayList<>();
    for (Subject s : subjects) {
        if (attendanceDAO.getAttendanceByDate(s.getId(), today) == null) {
            pendingSubjects.add(s);
        }
    }

    // Fetch last 5 attendance logs marked by this teacher
    List<Map<String, Object>> recentSessions = new ArrayList<>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getInstance().getConnection();
        String sql = "SELECT a.attendance_id, a.attendance_date, a.slot, c.class_name, s.subject_name, s.subject_code " +
                     "FROM attendance a " +
                     "JOIN classes c ON a.class_id = c.class_id " +
                     "JOIN subjects s ON a.subject_id = s.subject_id " +
                     "WHERE a.teacher_id = ? " +
                     "ORDER BY a.attendance_date DESC, a.attendance_id DESC LIMIT 5";
        ps = conn.prepareStatement(sql);
        ps.setInt(1, teacherId);
        rs = ps.executeQuery();

        while (rs.next()) {
            Map<String, Object> sessionMap = new HashMap<>();
            sessionMap.put("id", rs.getInt("attendance_id"));
            sessionMap.put("date", rs.getDate("attendance_date"));
            sessionMap.put("slot", rs.getString("slot"));
            sessionMap.put("className", rs.getString("class_name"));
            sessionMap.put("subjectName", rs.getString("subject_name"));
            sessionMap.put("subjectCode", rs.getString("subject_code"));
            recentSessions.add(sessionMap);
        }
    } catch (Exception e) {
        System.err.println("[AMS Teacher Dashboard] Error pulling recent sessions: " + e.getMessage());
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
    <title>AMS Teacher - Dashboard</title>
    <!-- Core UI CSS Stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }
        .stat-card {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: var(--shadow-sm);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 4px;
            height: 100%;
            background-color: var(--accent);
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-md);
            border-color: var(--accent);
        }
        .stat-card:hover::before {
            opacity: 1;
        }
        .stat-card-blue::before { background-color: #3498db; }
        .stat-card-green::before { background-color: var(--accent); }
        .stat-card-purple::before { background-color: #9b59b6; }
        .stat-card-yellow::before { background-color: var(--warning); }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: var(--border-radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .stat-icon-blue { background-color: rgba(52, 152, 219, 0.1); color: #3498db; }
        .stat-icon-green { background-color: var(--accent-light); color: var(--accent); }
        .stat-icon-purple { background-color: rgba(155, 89, 182, 0.1); color: #9b59b6; }
        .stat-icon-yellow { background-color: rgba(241, 196, 15, 0.1); color: var(--warning); }

        .stat-value {
            font-size: 28px;
            font-weight: 700;
            color: var(--text-primary);
            line-height: 1.2;
            margin-bottom: 4px;
        }
        .stat-label {
            font-size: 13px;
            color: var(--text-secondary);
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .dashboard-layout-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
            margin-bottom: 32px;
        }
        @media (max-width: 992px) {
            .dashboard-layout-grid {
                grid-template-columns: 1fr;
            }
        }
        .assigned-subjects-list {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .subject-item-card {
            background-color: var(--bg-app);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            padding: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: border-color var(--transition-fast);
        }
        .subject-item-card:hover {
            border-color: var(--accent);
        }
        .alert-banner {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 16px;
            background-color: var(--danger-light);
            border: 1px solid rgba(231, 76, 60, 0.15);
            border-radius: var(--border-radius-sm);
            color: var(--danger);
            margin-bottom: 12px;
        }
        .alert-banner svg {
            flex-shrink: 0;
            margin-top: 2px;
        }
    </style>
</head>
<body>
    <div class="app-wrapper">
        <!-- Sidebar Navigation Inclusion -->
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
                    <h2>Teacher Portal</h2>
                </div>
            </header>

            <main class="app-main-content">
                <!-- Welcome section -->
                <div class="card animate-fade" style="padding: 24px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h1 style="font-size: 26px; margin: 0; color: var(--primary);">Welcome back, <%= session.getAttribute("fullName") %>!</h1>
                        <p style="color: var(--text-secondary); margin: 6px 0 0 0;">Manage your student classes and record daily attendance efficiently.</p>
                    </div>
                    <div style="background-color: var(--accent-light); color: var(--accent); padding: 8px 16px; border-radius: 20px; font-weight: 600; font-size: 14px;">
                        <%= new java.text.SimpleDateFormat("EEEE, MMMM d, yyyy").format(today) %>
                    </div>
                </div>

                <!-- Pending Attendance Alerts -->
                <% if (!pendingSubjects.isEmpty()) { %>
                    <div class="card animate-fade" style="padding: 20px; border-color: rgba(231, 76, 60, 0.2); margin-bottom: 24px;">
                        <h3 style="margin-top: 0; margin-bottom: 16px; color: var(--danger); font-size: 16px; display: flex; align-items: center; gap: 8px;">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
                            Pending Attendance Alerts (Today)
                        </h3>
                        <div>
                            <% for (Subject s : pendingSubjects) { 
                                ClassSection c = classDAO.getClassById(s.getClassId());
                            %>
                                <div class="alert-banner">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
                                    <div style="flex-grow: 1;">
                                        Attendance for <strong><%= s.getCode() %> - <%= s.getName() %></strong> (<%= c != null ? c.getName() : "Unassigned Class" %>) has not been marked yet today.
                                    </div>
                                    <a href="mark-attendance.jsp?subjectId=<%= s.getId() %>" class="btn btn-danger btn-sm" style="padding: 4px 10px; font-size: 12px; background-color: var(--danger); border: none; color: white; border-radius: var(--border-radius-sm);">Mark Now</a>
                                </div>
                            <% } %>
                        </div>
                    </div>
                <% } %>

                <!-- Stat Cards Row -->
                <div class="dashboard-grid">
                    <div class="stat-card stat-card-blue animate-fade">
                        <div>
                            <div class="stat-value"><%= assignedSubjectsCount %></div>
                            <div class="stat-label">Assigned Subjects</div>
                        </div>
                        <div class="stat-icon stat-icon-blue">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="12 2 2 7 12 12 22 7 12 2 2 7"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
                        </div>
                    </div>

                    <div class="stat-card stat-card-green animate-fade">
                        <div>
                            <div class="stat-value"><%= classesToday %></div>
                            <div class="stat-label">Total Classes</div>
                        </div>
                        <div class="stat-icon stat-icon-green">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
                        </div>
                    </div>

                    <div class="stat-card stat-card-purple animate-fade">
                        <div>
                            <div class="stat-value"><%= totalStudents %></div>
                            <div class="stat-label">Total Students</div>
                        </div>
                        <div class="stat-icon stat-icon-purple">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                        </div>
                    </div>

                    <div class="stat-card stat-card-yellow animate-fade">
                        <div>
                            <div class="stat-value"><%= String.format("%.1f", avgAttendance) %>%</div>
                            <div class="stat-label">Avg Attendance</div>
                        </div>
                        <div class="stat-icon stat-icon-yellow">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
                        </div>
                    </div>
                </div>

                <!-- Dashboard Layout Grid: Subjects & History -->
                <div class="dashboard-layout-grid">
                    <!-- My Subjects Card -->
                    <div class="card animate-fade" style="padding: 24px;">
                        <h3 style="margin-top: 0; margin-bottom: 20px; font-weight: 700; color: var(--text-primary);">My Subjects & Classes</h3>
                        <div class="assigned-subjects-list">
                            <% if (subjects.isEmpty()) { %>
                                <div style="text-align: center; color: var(--text-secondary); padding: 20px 0;">
                                    No subject allocations found in the academic catalog for you.
                                </div>
                            <% } else { 
                                for (Subject s : subjects) {
                                    ClassSection c = classDAO.getClassById(s.getClassId());
                            %>
                                <div class="subject-item-card">
                                    <div>
                                        <div style="font-weight: 700; font-size: 15px; color: var(--primary);"><%= s.getName() %></div>
                                        <div style="font-size: 12px; color: var(--text-secondary); margin-top: 4px;">
                                            Code: <strong><%= s.getCode() %></strong> | Class: <strong><%= c != null ? c.getName() : "Unassigned Class" %></strong>
                                        </div>
                                    </div>
                                    <a href="mark-attendance.jsp?subjectId=<%= s.getId() %>" class="btn btn-accent" style="padding: 8px 16px; font-size: 13px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px;">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M9 11l3 3L22 4"></path><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path></svg>
                                        Mark Attendance
                                    </a>
                                </div>
                            <% } 
                            } %>
                        </div>
                    </div>

                    <!-- Recent Activity Cards -->
                    <div class="card animate-fade" style="padding: 24px;">
                        <h3 style="margin-top: 0; margin-bottom: 20px; font-weight: 700; color: var(--text-primary);">Recent Sessions</h3>
                        <div style="display: flex; flex-direction: column; gap: 14px;">
                            <% if (recentSessions.isEmpty()) { %>
                                <div style="text-align: center; color: var(--text-secondary); padding: 20px 0; font-size: 13px;">
                                    No logged sessions.
                                </div>
                            <% } else {
                                for (Map<String, Object> s : recentSessions) {
                            %>
                                <div style="padding: 12px; border: 1px solid var(--border-color); border-radius: var(--border-radius-sm); font-size: 13px; display: flex; flex-direction: column; gap: 4px;">
                                    <div style="display: flex; justify-content: space-between; align-items: center;">
                                        <strong style="color: var(--primary);"><%= s.get("subjectCode") %></strong>
                                        <span style="color: var(--text-muted); font-size: 11px;"><%= s.get("date") %></span>
                                    </div>
                                    <div style="color: var(--text-secondary);"><%= s.get("className") %></div>
                                    <div style="color: var(--text-muted); font-size: 11px;"><%= s.get("slot") %></div>
                                </div>
                            <% }
                            } %>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Javascript Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
