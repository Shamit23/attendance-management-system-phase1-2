package com.ams.servlet;

import com.ams.dao.AttendanceDAO;
import com.ams.dao.SubjectDAO;
import com.ams.model.Attendance;
import com.ams.model.AttendanceDetail;
import com.ams.model.Subject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

/**
 * AttendanceServlet.java
 * Controller managing recording and modifications of student attendance logs.
 *
 * Mapped to /teacher/attendance
 */
@WebServlet("/teacher/attendance")
public class AttendanceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private AttendanceDAO attendanceDAO;
    private SubjectDAO subjectDAO;

    @Override
    public void init() throws ServletException {
        attendanceDAO = new AttendanceDAO();
        subjectDAO = new SubjectDAO();
    }

    /**
     * Handles HTTP GET requests. Forwards back to dashboard or redirects as fallback.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"TEACHER".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }
        response.sendRedirect(request.getContextPath() + "/teacher/dashboard.jsp");
    }

    /**
     * Handles POST requests for saving or updating attendance sessions.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"TEACHER".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        Integer teacherId = (Integer) session.getAttribute("teacherId");
        if (teacherId == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
            return;
        }

        String action = request.getParameter("action");
        if ("mark".equals(action)) {
            try {
                int subjectId = Integer.parseInt(request.getParameter("subjectId"));
                Date date = Date.valueOf(request.getParameter("date"));
                String slot = request.getParameter("slot");
                if (slot == null || slot.trim().isEmpty()) {
                    slot = "09:00 - 10:00 AM";
                }

                Subject subject = subjectDAO.getAllSubjects().stream()
                        .filter(s -> s.getId() == subjectId)
                        .findFirst()
                        .orElse(null);

                if (subject == null) {
                    response.sendRedirect(request.getContextPath() + "/teacher/mark-attendance.jsp?error=invalid_subject");
                    return;
                }

                int classId = subject.getClassId();
                String[] studentIdsRaw = request.getParameterValues("studentIds");

                if (studentIdsRaw == null || studentIdsRaw.length == 0) {
                    response.sendRedirect(request.getContextPath() + "/teacher/mark-attendance.jsp?subjectId=" + subjectId + "&date=" + date + "&error=no_students");
                    return;
                }

                List<AttendanceDetail> details = new ArrayList<>();
                for (String studentIdStr : studentIdsRaw) {
                    int studentId = Integer.parseInt(studentIdStr);
                    String status = request.getParameter("status_" + studentId);
                    if (status == null) {
                        status = "P"; // Default fallback to Present
                    }
                    String remarks = request.getParameter("remarks_" + studentId);

                    AttendanceDetail detail = new AttendanceDetail();
                    detail.setStudentId(studentId);
                    detail.setStatus(status);
                    detail.setRemarks(remarks);
                    details.add(detail);
                }

                // Check if editing or existing record
                String isEditStr = request.getParameter("isEdit");
                boolean isEdit = "true".equalsIgnoreCase(isEditStr);
                Attendance existing = attendanceDAO.getAttendanceByDate(subjectId, date);

                boolean operationSuccess;
                if (isEdit && existing != null) {
                    operationSuccess = attendanceDAO.updateAttendance(existing.getId(), details);
                } else if (existing != null) {
                    // Implicit update for duplicate inserts to prevent duplicate errors
                    operationSuccess = attendanceDAO.updateAttendance(existing.getId(), details);
                } else {
                    Attendance newAttendance = new Attendance();
                    newAttendance.setClassId(classId);
                    newAttendance.setSubjectId(subjectId);
                    newAttendance.setTeacherId(teacherId);
                    newAttendance.setAttendanceDate(date);
                    newAttendance.setSlot(slot);
                    operationSuccess = attendanceDAO.markAttendance(newAttendance, details);
                }

                if (operationSuccess) {
                    response.sendRedirect(request.getContextPath() + "/teacher/mark-attendance.jsp?status=success&subjectId=" + subjectId + "&date=" + date);
                } else {
                    response.sendRedirect(request.getContextPath() + "/teacher/mark-attendance.jsp?status=failed&subjectId=" + subjectId + "&date=" + date);
                }
            } catch (Exception e) {
                System.err.println("[AMS AttendanceServlet] Error processing attendance marking: " + e.getMessage());
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/teacher/mark-attendance.jsp?status=error");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/teacher/dashboard.jsp");
        }
    }
}
