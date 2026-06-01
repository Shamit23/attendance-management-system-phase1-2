<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.dao.StudentDAO" %>
<%@ page import="com.ams.dao.ClassDAO" %>
<%@ page import="com.ams.dao.SubjectDAO" %>
<%@ page import="com.ams.model.Student" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.util.DBConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
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

    Student student = studentDAO.getStudentById(studentId);
    if (student == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=profile_not_found");
        return;
    }

    ClassSection cls = classDAO.getClassById(student.getClassId());
    String className = (cls != null) ? cls.getName() : "Unassigned Class";

    // Run consolidated SQL query for student subject metrics
    List<Map<String, Object>> subjectMetrics = new ArrayList<>();
    int grandTotal = 0;
    int grandAttended = 0;
    int grandAbsent = 0;
    int grandLate = 0;
    boolean hasLowAttendance = false;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        conn = DBConnection.getInstance().getConnection();
        String sql = 
            "SELECT " +
            "    s.subject_id, " +
            "    s.subject_name, " +
            "    s.subject_code, " +
            "    COUNT(DISTINCT a.attendance_id) as total_classes, " +
            "    SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_classes, " +
            "    SUM(CASE WHEN ad.status IN ('A', 'ABSENT') THEN 1 ELSE 0 END) as absent_classes, " +
            "    SUM(CASE WHEN ad.status IN ('L', 'LATE') THEN 1 ELSE 0 END) as late_classes " +
            "FROM subjects s " +
            "LEFT JOIN attendance a ON a.subject_id = s.subject_id AND a.class_id = ? " +
            "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = ? " +
            "WHERE s.class_id = ? " +
            "GROUP BY s.subject_id, s.subject_name, s.subject_code " +
            "ORDER BY s.subject_name ASC";

        ps = conn.prepareStatement(sql);
        ps.setInt(1, student.getClassId());
        ps.setInt(2, studentId);
        ps.setInt(3, student.getClassId());

        rs = ps.executeQuery();
        while (rs.next()) {
            int subId = rs.getInt("subject_id");
            String subName = rs.getString("subject_name");
            String subCode = rs.getString("subject_code");
            int total = rs.getInt("total_classes");
            int attended = rs.getInt("attended_classes");
            int absent = rs.getInt("absent_classes");
            int late = rs.getInt("late_classes");

            double percentage = (total > 0) ? ((double) attended / total * 100.0) : 100.0;
            if (percentage < 75.0 && total > 0) {
                hasLowAttendance = true;
            }

            grandTotal += total;
            grandAttended += attended;
            grandAbsent += absent;
            grandLate += late;

            Map<String, Object> map = new HashMap<>();
            map.put("id", subId);
            map.put("name", subName);
            map.put("code", subCode);
            map.put("total", total);
            map.put("attended", attended);
            map.put("absent", absent);
            map.put("late", late);
            map.put("percentage", percentage);

            subjectMetrics.add(map);
        }
    } catch (Exception e) {
        System.err.println("[AMS Student Dashboard] SQL error: " + e.getMessage());
        e.printStackTrace();
    } finally {
        DBConnection.closeResultSet(rs);
        DBConnection.closeStatement(ps);
        DBConnection.closeConnection(conn);
    }

    double overallPercentage = (grandTotal > 0) ? ((double) grandAttended / grandTotal * 100.0) : 100.0;
    
    // Choose progress color code
    String progressColor = "#27AE60"; // Green
    if (overallPercentage < 75.0) {
        progressColor = "#F39C12"; // Amber
    }
    if (overallPercentage < 60.0) {
        progressColor = "#E74C3C"; // Red
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Student Portal - Dashboard</title>
    <!-- Core UI CSS stylesheet -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .student-welcome {
            background: linear-gradient(135deg, var(--accent) 0%, #2980B9 100%);
            color: white;
            border-radius: var(--border-radius-md);
            padding: 24px 30px;
            margin-bottom: 24px;
            box-shadow: var(--shadow-sm);
        }
        .student-welcome h1 {
            margin: 0 0 8px 0;
            font-size: 24px;
            font-weight: 700;
        }
        .student-welcome p {
            margin: 0;
            opacity: 0.9;
            font-size: 14px;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: 1fr 2fr;
            gap: 24px;
            margin-bottom: 24px;
        }
        @media (max-width: 992px) {
            .dashboard-grid {
                grid-template-columns: 1fr;
            }
        }
        .circular-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 30px;
            background-color: var(--bg-card);
            border-radius: var(--border-radius-md);
            border: 1px solid var(--border-color);
            text-align: center;
        }
        .stats-summary-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }
        @media (max-width: 768px) {
            .stats-summary-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
        .mini-card {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            padding: 16px 20px;
            text-align: center;
            box-shadow: var(--shadow-sm);
        }
        .mini-card .val {
            font-size: 22px;
            font-weight: 700;
            margin-top: 4px;
            color: var(--text-primary);
        }
        .subject-progress-card {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 24px;
            box-shadow: var(--shadow-sm);
        }
        .subject-progress-row {
            margin-bottom: 20px;
        }
        .subject-progress-row:last-child {
            margin-bottom: 0;
        }
        .subject-info-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            font-size: 13.5px;
        }
        .progress-bar-container {
            width: 100%;
            height: 10px;
            background-color: var(--bg-app);
            border-radius: 5px;
            overflow: hidden;
            border: 1px solid var(--border-color);
        }
        .progress-bar-fill {
            height: 100%;
            border-radius: 5px;
            width: 0; /* Animated via client-side transition */
            transition: width 1s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .alert-banner {
            background-color: rgba(231, 76, 60, 0.08);
            border: 1px solid rgba(231, 76, 60, 0.2);
            border-radius: var(--border-radius-sm);
            color: #c0392b;
            padding: 16px 20px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 14px;
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
                    <h2>Academic Dashboard</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Welcome greeting -->
                <div class="student-welcome animate-fade">
                    <h1>Welcome, <%= student.getFirstName() %>!</h1>
                    <p>Logged in student profile for cohort: <strong><%= className %></strong> | Roll: <%= student.getRollNo() %></p>
                </div>

                <!-- Alert banner for underperforming indicators -->
                <% if (hasLowAttendance) { %>
                    <div class="alert-banner animate-fade">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                            <line x1="12" y1="9" x2="12" y2="13"></line>
                            <line x1="12" y1="17" x2="12.01" y2="17"></line>
                        </svg>
                        <span><strong>Warning:</strong> Your attendance in one or more subjects is below the required 75% threshold. Please attend classes regularly to prevent attendance shortages.</span>
                    </div>
                <% } %>

                <!-- Metric stats panel -->
                <div class="stats-summary-grid animate-fade">
                    <div class="mini-card">
                        <div style="font-size: 11px; text-transform: uppercase; color: var(--text-secondary); font-weight: 600;">Total Classes</div>
                        <div class="val"><%= grandTotal %></div>
                    </div>
                    <div class="mini-card" style="border-bottom: 3px solid var(--success-color);">
                        <div style="font-size: 11px; text-transform: uppercase; color: var(--success-color); font-weight: 600;">Attended</div>
                        <div class="val" style="color: var(--success-color);"><%= grandAttended %></div>
                    </div>
                    <div class="mini-card" style="border-bottom: 3px solid var(--danger-color);">
                        <div style="font-size: 11px; text-transform: uppercase; color: var(--danger-color); font-weight: 600;">Absent Sessions</div>
                        <div class="val" style="color: var(--danger-color);"><%= grandAbsent %></div>
                    </div>
                    <div class="mini-card" style="border-bottom: 3px solid var(--warning-color);">
                        <div style="font-size: 11px; text-transform: uppercase; color: var(--warning-color); font-weight: 600;">Late Logins</div>
                        <div class="val" style="color: var(--warning-color);"><%= grandLate %></div>
                    </div>
                </div>

                <!-- Dashboard Content Layout Grid -->
                <div class="dashboard-grid animate-fade">
                    <!-- Circular Summary Chart -->
                    <div class="circular-container">
                        <h4 style="margin-top: 0; margin-bottom: 24px; color: var(--text-primary);">Attendance Performance</h4>
                        
                        <svg width="200" height="200" viewBox="0 0 200 200" class="circular-progress">
                            <circle cx="100" cy="100" r="80" stroke="var(--border-color)" stroke-width="12" fill="transparent" />
                            <circle cx="100" cy="100" r="80" stroke="<%= progressColor %>" stroke-width="12" fill="transparent"
                                    stroke-dasharray="502.4" stroke-dashoffset="502.4"
                                    id="overallCircle"
                                    stroke-linecap="round" style="transition: stroke-dashoffset 1s cubic-bezier(0.4, 0, 0.2, 1); transform: rotate(-90deg); transform-origin: 50% 50%;" />
                            <text x="100" y="105" text-anchor="middle" font-size="28" font-weight="bold" fill="var(--text-primary)">
                                <%= String.format("%.1f%%", overallPercentage) %>
                            </text>
                            <text x="100" y="130" text-anchor="middle" font-size="12" fill="var(--text-secondary)">
                                Overall Average
                            </text>
                        </svg>
                    </div>

                    <!-- Subject Progress Listing -->
                    <div class="subject-progress-card">
                        <h4 style="margin-top: 0; margin-bottom: 20px; color: var(--text-primary);">Subject Breakdown</h4>
                        
                        <% if (subjectMetrics.isEmpty()) { %>
                            <div style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                No academic subjects assigned to your class cohort yet.
                            </div>
                        <% } else {
                            for (Map<String, Object> sub : subjectMetrics) {
                                double p = (Double) sub.get("percentage");
                                String barColor = "var(--success-color)";
                                if (p < 75.0) {
                                    barColor = "var(--warning-color)";
                                }
                                if (p < 60.0) {
                                    barColor = "var(--danger-color)";
                                }
                        %>
                            <div class="subject-progress-row">
                                <div class="subject-info-header">
                                    <div><strong><%= sub.get("code") %></strong> - <%= sub.get("name") %></div>
                                    <div style="font-weight: 600; color: <%= barColor %>;"><%= String.format("%.1f%%", p) %> (<%= sub.get("attended") %>/<%= sub.get("total") %>)</div>
                                </div>
                                <div class="progress-bar-container">
                                    <div class="progress-bar-fill" data-width="<%= p %>%" style="background-color: <%= barColor %>;"></div>
                                </div>
                            </div>
                        <% } 
                        } %>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Animate circular progress on load
        window.addEventListener("DOMContentLoaded", () => {
            const circle = document.getElementById("overallCircle");
            if (circle) {
                const percentage = <%= overallPercentage %>;
                const strokeDashOffset = 502.4 - (502.4 * percentage / 100.0);
                setTimeout(() => {
                    circle.style.strokeDashoffset = strokeDashOffset;
                }, 100);
            }

            // Animate subject horizontal progress bars on load
            const progressBars = document.querySelectorAll(".progress-bar-fill");
            setTimeout(() => {
                progressBars.forEach(bar => {
                    bar.style.width = bar.getAttribute("data-width");
                });
            }, 100);
        });
    </script>
</body>
</html>
