package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.SubjectDAO;
import com.ams.dao.TeacherDAO;
import com.ams.dao.StudentDAO;
import com.ams.model.ClassSection;
import com.ams.model.Subject;
import com.ams.model.Teacher;
import com.ams.model.Student;
import com.ams.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ReportServlet.java
 * Purpose: Unified reporting portal for administrators, teachers, and students.
 */
@WebServlet(urlPatterns = {"/admin/reports", "/teacher/reports", "/student/reports"})
public class ReportServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ClassDAO classDAO;
    private SubjectDAO subjectDAO;
    private TeacherDAO teacherDAO;
    private StudentDAO studentDAO;

    @Override
    public void init() throws ServletException {
        classDAO = new ClassDAO();
        subjectDAO = new SubjectDAO();
        teacherDAO = new TeacherDAO();
        studentDAO = new StudentDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        String role = (String) session.getAttribute("role");
        if (role == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        String action = request.getParameter("action");
        String format = request.getParameter("format"); // "csv" or "html"

        if ("studentReport".equals(action)) {
            handleStudentReport(request, response, session, format);
        } else if ("dailyReport".equals(action)) {
            handleDailyReport(request, response, session, format);
        } else if ("monthlyReport".equals(action)) {
            handleMonthlyReport(request, response, session, format);
        } else if ("subjectReport".equals(action)) {
            handleSubjectReport(request, response, session, format);
        } else if ("lowAttendance".equals(action)) {
            handleLowAttendance(request, response, session, format);
        } else {
            // Default filter query report (from Phase 3 / 4)
            handleGeneralReport(request, response, session, role, format);
        }
    }

    /**
     * Action: studentReport
     * Generates subject-wise breakdowns and absence logs for the student.
     */
    private void handleStudentReport(HttpServletRequest request, HttpServletResponse response, 
                                     HttpSession session, String format) throws ServletException, IOException {
        Integer studentId = (Integer) session.getAttribute("studentId");
        if (studentId == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        Student student = studentDAO.getStudentById(studentId);
        if (student == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=profile_not_found");
            return;
        }

        ClassSection cls = classDAO.getClassById(student.getClassId());
        String className = (cls != null) ? cls.getName() : "Unassigned";

        List<Map<String, Object>> subjectBreakdown = new ArrayList<>();
        List<Map<String, Object>> absenceLogs = new ArrayList<>();
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            
            // 1. Subject metrics query
            String subSql = 
                "SELECT s.subject_id, s.subject_name, s.subject_code, " +
                "       COUNT(DISTINCT a.attendance_id) as total, " +
                "       SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended " +
                "FROM subjects s " +
                "LEFT JOIN attendance a ON a.subject_id = s.subject_id AND a.class_id = ? " +
                "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = ? " +
                "WHERE s.class_id = ? " +
                "GROUP BY s.subject_id, s.subject_name, s.subject_code";
            
            ps = conn.prepareStatement(subSql);
            ps.setInt(1, student.getClassId());
            ps.setInt(2, studentId);
            ps.setInt(3, student.getClassId());
            
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("code", rs.getString("subject_code"));
                map.put("name", rs.getString("subject_name"));
                int total = rs.getInt("total");
                int attended = rs.getInt("attended");
                double pct = (total > 0) ? ((double) attended / total * 100.0) : 100.0;
                map.put("total", total);
                map.put("attended", attended);
                map.put("percentage", pct);
                subjectBreakdown.add(map);
            }
            
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);

            // 2. Absence logs query
            String absSql = 
                "SELECT a.attendance_date, a.slot, s.subject_code, s.subject_name, ad.remarks " +
                "FROM attendance a " +
                "JOIN attendance_details ad ON a.attendance_id = ad.attendance_id " +
                "JOIN subjects s ON a.subject_id = s.subject_id " +
                "WHERE ad.student_id = ? AND ad.status IN ('A', 'ABSENT') " +
                "ORDER BY a.attendance_date DESC";
            
            ps = conn.prepareStatement(absSql);
            ps.setInt(1, studentId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("date", rs.getDate("attendance_date"));
                map.put("slot", rs.getString("slot"));
                map.put("code", rs.getString("subject_code"));
                map.put("name", rs.getString("subject_name"));
                map.put("remarks", rs.getString("remarks"));
                absenceLogs.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"student_attendance_report.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("AMS STUDENT ATTENDANCE REPORT");
                writer.println("Student Name," + student.getFirstName() + " " + student.getLastName());
                writer.println("Roll Number," + student.getRollNo());
                writer.println("Class Cohort," + className);
                writer.println();
                writer.println("SUBJECT BREAKDOWN");
                writer.println("Subject Code,Subject Name,Total Classes,Attended Classes,Attendance Percentage");
                for (Map<String, Object> sub : subjectBreakdown) {
                    writer.println(sub.get("code") + "," +
                                   "\"" + sub.get("name") + "\"" + "," +
                                   sub.get("total") + "," +
                                   sub.get("attended") + "," +
                                   String.format("%.1f%%", (Double) sub.get("percentage")));
                }
                writer.println();
                writer.println("RECORDED ABSENCES");
                writer.println("Date,Slot,Subject Code,Subject Name,Remarks");
                for (Map<String, Object> abs : absenceLogs) {
                    writer.println(abs.get("date") + "," +
                                   abs.get("slot") + "," +
                                   abs.get("code") + "," +
                                   "\"" + abs.get("name") + "\"" + "," +
                                   "\"" + (abs.get("remarks") != null ? abs.get("remarks") : "") + "\"");
                }
            }
            return;
        }

        request.setAttribute("student", student);
        request.setAttribute("className", className);
        request.setAttribute("subjectBreakdown", subjectBreakdown);
        request.setAttribute("absenceLogs", absenceLogs);
        request.getRequestDispatcher("/student/student-report.jsp").forward(request, response);
    }

    /**
     * Action: dailyReport
     * Generates a snapshot of classes conducted on a chosen date.
     */
    private void handleDailyReport(HttpServletRequest request, HttpServletResponse response, 
                                   HttpSession session, String format) throws ServletException, IOException {
        String dateStr = request.getParameter("date");
        if (dateStr == null || dateStr.isEmpty()) {
            dateStr = LocalDate.now().toString();
        }

        List<Map<String, Object>> dailyData = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = 
                "SELECT c.class_name, s.subject_code, s.subject_name, t.first_name, t.last_name, a.slot, " +
                "       COUNT(ad.detail_id) as total_students, " +
                "       SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as present_count, " +
                "       SUM(CASE WHEN ad.status IN ('A', 'ABSENT') THEN 1 ELSE 0 END) as absent_count " +
                "FROM attendance a " +
                "JOIN classes c ON a.class_id = c.class_id " +
                "JOIN subjects s ON a.subject_id = s.subject_id " +
                "JOIN teachers t ON a.teacher_id = t.teacher_id " +
                "JOIN attendance_details ad ON a.attendance_id = ad.attendance_id " +
                "WHERE a.attendance_date = ? " +
                "GROUP BY a.attendance_id, c.class_name, s.subject_code, s.subject_name, t.first_name, t.last_name, a.slot";

            ps = conn.prepareStatement(sql);
            ps.setDate(1, Date.valueOf(dateStr));
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("className", rs.getString("class_name"));
                map.put("subjectCode", rs.getString("subject_code"));
                map.put("subjectName", rs.getString("subject_name"));
                map.put("teacherName", rs.getString("first_name") + " " + rs.getString("last_name"));
                map.put("slot", rs.getString("slot"));
                map.put("total", rs.getInt("total_students"));
                map.put("present", rs.getInt("present_count"));
                map.put("absent", rs.getInt("absent_count"));
                dailyData.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"daily_attendance_report.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("DAILY ATTENDANCE LOG REPORT - " + dateStr);
                writer.println("Class,Subject Code,Subject Name,Teacher,Slot,Total,Present,Absent");
                for (Map<String, Object> row : dailyData) {
                    writer.println("\"" + row.get("className") + "\"" + "," +
                                   row.get("subjectCode") + "," +
                                   "\"" + row.get("subjectName") + "\"" + "," +
                                   "\"" + row.get("teacherName") + "\"" + "," +
                                   row.get("slot") + "," +
                                   row.get("total") + "," +
                                   row.get("present") + "," +
                                   row.get("absent"));
                }
            }
            return;
        }

        request.setAttribute("dailyReportData", dailyData);
        request.setAttribute("reportType", "daily");
        request.setAttribute("selectedDate", dateStr);
        forwardToReportView(request, response, session);
    }

    /**
     * Action: monthlyReport
     * Summary of student monthly attendance aggregates.
     */
    private void handleMonthlyReport(HttpServletRequest request, HttpServletResponse response, 
                                     HttpSession session, String format) throws ServletException, IOException {
        String monthStr = request.getParameter("month");
        String yearStr = request.getParameter("year");
        String classIdStr = request.getParameter("classId");

        LocalDate today = LocalDate.now();
        int month = (monthStr != null && !monthStr.isEmpty()) ? Integer.parseInt(monthStr) : today.getMonthValue();
        int year = (yearStr != null && !yearStr.isEmpty()) ? Integer.parseInt(yearStr) : today.getYear();

        List<Map<String, Object>> monthlyData = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            StringBuilder sql = new StringBuilder(
                "SELECT s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name, " +
                "       COUNT(DISTINCT a.attendance_id) as total_sessions, " +
                "       SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_sessions " +
                "FROM students s " +
                "JOIN classes c ON s.class_id = c.class_id " +
                "LEFT JOIN attendance a ON a.class_id = c.class_id AND MONTH(a.attendance_date) = ? AND YEAR(a.attendance_date) = ? " +
                "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = s.student_id " +
                "WHERE 1=1 "
            );

            List<Object> params = new ArrayList<>();
            params.add(month);
            params.add(year);

            if (classIdStr != null && !classIdStr.trim().isEmpty()) {
                sql.append("AND s.class_id = ? ");
                params.add(Integer.parseInt(classIdStr));
            }

            sql.append("GROUP BY s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name " +
                       "ORDER BY c.class_name ASC, s.roll_number ASC");

            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("rollNumber", rs.getString("roll_number"));
                map.put("studentName", rs.getString("first_name") + " " + rs.getString("last_name"));
                map.put("className", rs.getString("class_name"));
                int total = rs.getInt("total_sessions");
                int attended = rs.getInt("attended_sessions");
                double pct = (total > 0) ? ((double) attended / total * 100.0) : 100.0;
                map.put("totalSessions", total);
                map.put("attendedSessions", attended);
                map.put("percentage", pct);
                monthlyData.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"monthly_attendance_report.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("MONTHLY ATTENDANCE SUMMARY - " + month + "/" + year);
                writer.println("Roll Number,Student Name,Class,Total Sessions,Attended Sessions,Percentage");
                for (Map<String, Object> row : monthlyData) {
                    writer.println(row.get("rollNumber") + "," +
                                   "\"" + row.get("studentName") + "\"" + "," +
                                   "\"" + row.get("className") + "\"" + "," +
                                   row.get("totalSessions") + "," +
                                   row.get("attendedSessions") + "," +
                                   String.format("%.1f%%", (Double) row.get("percentage")));
                }
            }
            return;
        }

        request.setAttribute("monthlyReportData", monthlyData);
        request.setAttribute("reportType", "monthly");
        request.setAttribute("selectedMonth", month);
        request.setAttribute("selectedYear", year);
        request.setAttribute("selectedClassId", classIdStr);
        forwardToReportView(request, response, session);
    }

    /**
     * Action: subjectReport
     * Subject-specific attendance metrics across all enrolled cohort students.
     */
    private void handleSubjectReport(HttpServletRequest request, HttpServletResponse response, 
                                     HttpSession session, String format) throws ServletException, IOException {
        String subjectIdStr = request.getParameter("subjectId");
        if (subjectIdStr == null || subjectIdStr.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/reports?error=invalid_subject");
            return;
        }

        int subjectId = Integer.parseInt(subjectIdStr);
        Subject subject = subjectDAO.getSubjectById(subjectId);
        String subjectName = (subject != null) ? subject.getName() + " (" + subject.getCode() + ")" : "Unknown Subject";

        List<Map<String, Object>> subjectData = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = 
                "SELECT s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name, " +
                "       COUNT(DISTINCT a.attendance_id) as total_sessions, " +
                "       SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_sessions " +
                "FROM students s " +
                "JOIN classes c ON s.class_id = c.class_id " +
                "JOIN subjects sub ON s.class_id = sub.class_id " +
                "LEFT JOIN attendance a ON a.subject_id = sub.subject_id AND a.class_id = s.class_id " +
                "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = s.student_id " +
                "WHERE sub.subject_id = ? " +
                "GROUP BY s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name " +
                "ORDER BY s.roll_number ASC";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, subjectId);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("rollNumber", rs.getString("roll_number"));
                map.put("studentName", rs.getString("first_name") + " " + rs.getString("last_name"));
                map.put("className", rs.getString("class_name"));
                int total = rs.getInt("total_sessions");
                int attended = rs.getInt("attended_sessions");
                double pct = (total > 0) ? ((double) attended / total * 100.0) : 100.0;
                map.put("totalSessions", total);
                map.put("attendedSessions", attended);
                map.put("percentage", pct);
                subjectData.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"subject_attendance_report.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("SUBJECT ATTENDANCE PERFORMANCE - " + subjectName);
                writer.println("Roll Number,Student Name,Class,Total Sessions,Attended Sessions,Percentage");
                for (Map<String, Object> row : subjectData) {
                    writer.println(row.get("rollNumber") + "," +
                                   "\"" + row.get("studentName") + "\"" + "," +
                                   "\"" + row.get("className") + "\"" + "," +
                                   row.get("totalSessions") + "," +
                                   row.get("attendedSessions") + "," +
                                   String.format("%.1f%%", (Double) row.get("percentage")));
                }
            }
            return;
        }

        request.setAttribute("subjectReportData", subjectData);
        request.setAttribute("reportType", "subject");
        request.setAttribute("selectedSubjectId", subjectIdStr);
        request.setAttribute("subjectName", subjectName);
        forwardToReportView(request, response, session);
    }

    /**
     * Action: lowAttendance
     * Identifies students whose total academic attendance falls under the critical 75% bar.
     */
    private void handleLowAttendance(HttpServletRequest request, HttpServletResponse response, 
                                     HttpSession session, String format) throws ServletException, IOException {
        List<Map<String, Object>> lowData = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = 
                "SELECT s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name, " +
                "       COUNT(DISTINCT a.attendance_id) as total_sessions, " +
                "       SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_sessions " +
                "FROM students s " +
                "JOIN classes c ON s.class_id = c.class_id " +
                "LEFT JOIN attendance a ON a.class_id = c.class_id " +
                "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = s.student_id " +
                "GROUP BY s.student_id, s.roll_number, s.first_name, s.last_name, c.class_name " +
                "HAVING total_sessions > 0 AND (attended_sessions / total_sessions * 100.0) < 75.0 " +
                "ORDER BY (attended_sessions / total_sessions * 100.0) ASC, c.class_name ASC, s.roll_number ASC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("rollNumber", rs.getString("roll_number"));
                map.put("studentName", rs.getString("first_name") + " " + rs.getString("last_name"));
                map.put("className", rs.getString("class_name"));
                int total = rs.getInt("total_sessions");
                int attended = rs.getInt("attended_sessions");
                double pct = ((double) attended / total * 100.0);
                map.put("totalSessions", total);
                map.put("attendedSessions", attended);
                map.put("percentage", pct);
                lowData.add(map);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"low_attendance_defaulters.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("CRITICAL ATTENDANCE DEFAULTERS LIST (<75%)");
                writer.println("Roll Number,Student Name,Class,Total Sessions,Attended Sessions,Percentage");
                for (Map<String, Object> row : lowData) {
                    writer.println(row.get("rollNumber") + "," +
                                   "\"" + row.get("studentName") + "\"" + "," +
                                   "\"" + row.get("className") + "\"" + "," +
                                   row.get("totalSessions") + "," +
                                   row.get("attendedSessions") + "," +
                                   String.format("%.1f%%", (Double) row.get("percentage")));
                }
            }
            return;
        }

        request.setAttribute("lowReportData", lowData);
        request.setAttribute("reportType", "low");
        forwardToReportView(request, response, session);
    }

    /**
     * Default fallback query filtering reports.
     */
    private void handleGeneralReport(HttpServletRequest request, HttpServletResponse response, 
                                      HttpSession session, String role, String format) throws ServletException, IOException {
        String classIdStr = request.getParameter("classId");
        String subjectIdStr = request.getParameter("subjectId");
        String teacherIdStr = request.getParameter("teacherId");
        String startDateStr = request.getParameter("startDate");
        String endDateStr = request.getParameter("endDate");

        if ("TEACHER".equals(role)) {
            Integer sessionTeacherId = (Integer) session.getAttribute("teacherId");
            teacherIdStr = String.valueOf(sessionTeacherId);
        }

        List<Map<String, Object>> reportData = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            StringBuilder queryBuilder = new StringBuilder(
                "SELECT s.student_id, s.first_name, s.last_name, s.roll_number, c.class_name, " +
                "COUNT(DISTINCT a.attendance_id) as total_sessions, " +
                "SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_sessions " +
                "FROM students s " +
                "JOIN classes c ON s.class_id = c.class_id " +
                "LEFT JOIN attendance a ON a.class_id = c.class_id "
            );

            if (subjectIdStr != null && !subjectIdStr.trim().isEmpty()) {
                queryBuilder.append("AND a.subject_id = ? ");
            }
            if (teacherIdStr != null && !teacherIdStr.trim().isEmpty()) {
                queryBuilder.append("AND a.teacher_id = ? ");
            }
            if (startDateStr != null && !startDateStr.trim().isEmpty()) {
                queryBuilder.append("AND a.attendance_date >= ? ");
            }
            if (endDateStr != null && !endDateStr.trim().isEmpty()) {
                queryBuilder.append("AND a.attendance_date <= ? ");
            }

            queryBuilder.append(
                "LEFT JOIN attendance_details ad ON ad.attendance_id = a.attendance_id AND ad.student_id = s.student_id " +
                "WHERE 1=1 "
            );

            if (classIdStr != null && !classIdStr.trim().isEmpty()) {
                queryBuilder.append("AND s.class_id = ? ");
            }

            queryBuilder.append("GROUP BY s.student_id, s.first_name, s.last_name, s.roll_number, c.class_name " +
                                 "ORDER BY c.class_name ASC, s.roll_number ASC");

            ps = conn.prepareStatement(queryBuilder.toString());
            
            int paramIndex = 1;
            if (subjectIdStr != null && !subjectIdStr.trim().isEmpty()) {
                ps.setInt(paramIndex++, Integer.parseInt(subjectIdStr));
            }
            if (teacherIdStr != null && !teacherIdStr.trim().isEmpty()) {
                ps.setInt(paramIndex++, Integer.parseInt(teacherIdStr));
            }
            if (startDateStr != null && !startDateStr.trim().isEmpty()) {
                ps.setDate(paramIndex++, Date.valueOf(startDateStr));
            }
            if (endDateStr != null && !endDateStr.trim().isEmpty()) {
                ps.setDate(paramIndex++, Date.valueOf(endDateStr));
            }
            if (classIdStr != null && !classIdStr.trim().isEmpty()) {
                ps.setInt(paramIndex++, Integer.parseInt(classIdStr));
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("studentId", rs.getInt("student_id"));
                row.put("studentName", rs.getString("first_name") + " " + rs.getString("last_name"));
                row.put("rollNumber", rs.getString("roll_number"));
                row.put("className", rs.getString("class_name"));
                int total = rs.getInt("total_sessions");
                int attended = rs.getInt("attended_sessions");
                double percentage = (total > 0) ? ((double) attended / total * 100.0) : 100.0;
                row.put("totalSessions", total);
                row.put("attendedSessions", attended);
                row.put("percentage", percentage);
                reportData.add(row);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("csv".equals(format)) {
            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"attendance_report.csv\"");
            try (PrintWriter writer = response.getWriter()) {
                writer.println("Roll Number,Student Name,Class,Total Sessions,Attended Sessions,Attendance Percentage");
                for (Map<String, Object> record : reportData) {
                    writer.println(record.get("rollNumber") + "," +
                                   "\"" + record.get("studentName") + "\"" + "," +
                                   "\"" + record.get("className") + "\"" + "," +
                                   record.get("totalSessions") + "," +
                                   record.get("attendedSessions") + "," +
                                   String.format("%.1f%%", (Double) record.get("percentage")));
                }
            }
            return;
        }

        // Add filter attributes
        if ("TEACHER".equals(role)) {
            int tId = Integer.parseInt(teacherIdStr);
            request.setAttribute("classes", getTeacherClasses(tId));
            request.setAttribute("subjects", subjectDAO.getSubjectsByTeacher(tId));
            request.setAttribute("reportData", reportData);
            request.getRequestDispatcher("/teacher/teacher-report.jsp").forward(request, response);
        } else {
            request.setAttribute("classes", classDAO.getAllClasses());
            request.setAttribute("subjects", subjectDAO.getAllSubjects());
            request.setAttribute("teachers", teacherDAO.getAllTeachers());
            request.setAttribute("reportData", reportData);
            request.getRequestDispatcher("/admin/attendance-report.jsp").forward(request, response);
        }
    }

    /**
     * Dispatch routing utility for HTML admin/teacher pages.
     */
    private void forwardToReportView(HttpServletRequest request, HttpServletResponse response, HttpSession session) 
            throws ServletException, IOException {
        String role = (String) session.getAttribute("role");
        
        // Fetch all generic lists for dropdown dropdowns
        if ("TEACHER".equals(role)) {
            int tId = (Integer) session.getAttribute("teacherId");
            request.setAttribute("classes", getTeacherClasses(tId));
            request.setAttribute("subjects", subjectDAO.getSubjectsByTeacher(tId));
            request.getRequestDispatcher("/teacher/teacher-report.jsp").forward(request, response);
        } else {
            request.setAttribute("classes", classDAO.getAllClasses());
            request.setAttribute("subjects", subjectDAO.getAllSubjects());
            request.setAttribute("teachers", teacherDAO.getAllTeachers());
            request.getRequestDispatcher("/admin/attendance-report.jsp").forward(request, response);
        }
    }

    private List<ClassSection> getTeacherClasses(int teacherId) {
        List<Subject> subjects = subjectDAO.getSubjectsByTeacher(teacherId);
        List<ClassSection> classes = new ArrayList<>();
        java.util.Set<Integer> cids = new java.util.HashSet<>();
        for (Subject s : subjects) {
            cids.add(s.getClassId());
        }
        for (Integer cid : cids) {
            ClassSection c = classDAO.getClassById(cid);
            if (c != null) classes.add(c);
        }
        return classes;
    }
}
