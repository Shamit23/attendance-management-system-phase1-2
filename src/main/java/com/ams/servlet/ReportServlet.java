package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.SubjectDAO;
import com.ams.dao.TeacherDAO;
import com.ams.model.ClassSection;
import com.ams.model.Subject;
import com.ams.model.Teacher;
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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ReportServlet.java
 * Purpose: Generates administrative and teacher-level attendance aggregates and reports.
 * 
 * Mapping: Mapped to both /admin/reports and /teacher/reports
 */
@WebServlet(urlPatterns = {"/admin/reports", "/teacher/reports"})
public class ReportServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ClassDAO classDAO;
    private SubjectDAO subjectDAO;
    private TeacherDAO teacherDAO;

    @Override
    public void init() throws ServletException {
        classDAO = new ClassDAO();
        subjectDAO = new SubjectDAO();
        teacherDAO = new TeacherDAO();
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
        boolean isTeacher = "TEACHER".equals(role);
        boolean isAdmin = "ADMIN".equals(role);

        if (!isAdmin && !isTeacher) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        String action = request.getParameter("action");
        
        // Retrieve filter parameters
        String classIdStr = request.getParameter("classId");
        String subjectIdStr = request.getParameter("subjectId");
        String teacherIdStr = request.getParameter("teacherId");
        String startDateStr = request.getParameter("startDate");
        String endDateStr = request.getParameter("endDate");

        if (isTeacher) {
            // Force teacherId to be the logged-in teacher's id to prevent security escalation
            Integer sessionTeacherId = (Integer) session.getAttribute("teacherId");
            if (sessionTeacherId == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
                return;
            }
            teacherIdStr = String.valueOf(sessionTeacherId);
        }

        List<Map<String, Object>> reportData = new ArrayList<>();
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            
            // Build dynamic query: we calculate percentage of attendance for students based on session logs
            // Statuses can be 'P', 'A', 'L', or full strings 'PRESENT', 'ABSENT', 'LATE'
            // We support both single-char or full-string states by comparing using IN.
            StringBuilder queryBuilder = new StringBuilder(
                "SELECT s.student_id, s.first_name, s.last_name, s.roll_number, c.class_name, " +
                "COUNT(DISTINCT a.attendance_id) as total_sessions, " +
                "SUM(CASE WHEN ad.status IN ('P', 'L', 'E', 'PRESENT', 'LATE', 'EXCUSED') THEN 1 ELSE 0 END) as attended_sessions " +
                "FROM students s " +
                "JOIN classes c ON s.class_id = c.class_id " +
                "LEFT JOIN attendance a ON a.class_id = c.class_id "
            );

            // If subjectId is set, join attendance on subject
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
            System.err.println("[AMS ReportServlet] Error building attendance report: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }

        if ("export".equals(action)) {
            // Generate CSV download
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

        if (isTeacher) {
            // Fetch dropdown options filtered by teacher
            int tId = Integer.parseInt(teacherIdStr);
            List<Subject> subjects = subjectDAO.getSubjectsByTeacher(tId);
            
            List<ClassSection> classes = new ArrayList<>();
            java.util.Set<Integer> cids = new java.util.HashSet<>();
            for (Subject s : subjects) {
                cids.add(s.getClassId());
            }
            for (Integer cid : cids) {
                ClassSection c = classDAO.getClassById(cid);
                if (c != null) classes.add(c);
            }

            request.setAttribute("classes", classes);
            request.setAttribute("subjects", subjects);
            request.setAttribute("reportData", reportData);
            
            request.getRequestDispatcher("/teacher/teacher-report.jsp").forward(request, response);
        } else {
            // Fetch all options for admin
            List<ClassSection> classes = classDAO.getAllClasses();
            List<Subject> subjects = subjectDAO.getAllSubjects();
            List<Teacher> teachers = teacherDAO.getAllTeachers();

            request.setAttribute("classes", classes);
            request.setAttribute("subjects", subjects);
            request.setAttribute("teachers", teachers);
            request.setAttribute("reportData", reportData);
            
            request.getRequestDispatcher("/admin/attendance-report.jsp").forward(request, response);
        }
    }
}
