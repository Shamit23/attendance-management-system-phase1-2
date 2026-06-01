package com.ams.servlet;

import com.ams.dao.TeacherDAO;
import com.ams.model.Teacher;
import com.ams.util.ErrorHandler;
import com.ams.util.Result;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * TeacherServlet.java
 * Purpose: Administrative CRUD controller for faculty accounts and profiles.
 * 
 * Mapping: Mapped to /admin/teachers
 */
@WebServlet("/admin/teachers")
public class TeacherServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private TeacherDAO teacherDAO;

    @Override
    public void init() throws ServletException {
        teacherDAO = new TeacherDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        switch (action) {
            case "delete":
                handleDelete(request, response);
                break;
            case "list":
            default:
                handleList(request, response);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) {
            action = "add";
        }

        switch (action) {
            case "add":
                handleAdd(request, response);
                break;
            case "edit":
                handleEdit(request, response);
                break;
            default:
                handleList(request, response);
                break;
        }
    }

    private void handleList(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        List<Teacher> teachers = teacherDAO.getAllTeachers();
        request.setAttribute("teachers", teachers);
        request.getRequestDispatcher("/admin/manage-teachers.jsp").forward(request, response);
    }

    private void handleAdd(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String specialization = request.getParameter("specialization");

        // Server-side validations
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            specialization == null || specialization.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "Required fields (First Name, Last Name, Email, and Specialization) cannot be empty.");
            request.setAttribute("errorMessage", "Required fields (First Name, Last Name, Email, and Specialization) cannot be empty.");
            handleList(request, response);
            return;
        }

        // Email uniqueness check
        if (teacherDAO.isEmailExists(email.trim())) {
            request.setAttribute("errorMsg", "Email address is already in use.");
            request.setAttribute("errorMessage", "Email address is already in use.");
            handleList(request, response);
            return;
        }

        Teacher teacher = new Teacher();
        teacher.setFirstName(firstName.trim());
        teacher.setLastName(lastName.trim());
        teacher.setEmail(email.trim());
        teacher.setPhone(phone != null ? phone.trim() : null);
        teacher.setSpecialization(specialization.trim());

        Result<Boolean> result = ErrorHandler.executeSafely(
            () -> teacherDAO.addTeacher(teacher),
            "Teacher profile registered successfully.",
            "Failed to register teacher profile."
        );

        if (result.isSuccess() && result.getData()) {
            response.sendRedirect(request.getContextPath() + "/admin/teachers?msg=added");
        } else {
            request.setAttribute("errorMsg", result.getMessage());
            request.setAttribute("errorMessage", result.getMessage());
            handleList(request, response);
        }
    }

    private void handleEdit(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("teacherId");
        String userIdStr = request.getParameter("userId");
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String specialization = request.getParameter("specialization");

        if (idStr == null || userIdStr == null ||
            firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            specialization == null || specialization.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "All profile fields are required for updates.");
            request.setAttribute("errorMessage", "All profile fields are required for updates.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            int userId = Integer.parseInt(userIdStr);

            // Email uniqueness check
            if (teacherDAO.isEmailExistsForOther(email.trim(), userId)) {
                request.setAttribute("errorMsg", "Email address is already in use.");
                request.setAttribute("errorMessage", "Email address is already in use.");
                handleList(request, response);
                return;
            }

            Teacher teacher = new Teacher();
            teacher.setId(id);
            teacher.setUserId(userId);
            teacher.setFirstName(firstName.trim());
            teacher.setLastName(lastName.trim());
            teacher.setEmail(email.trim());
            teacher.setPhone(phone != null ? phone.trim() : null);
            teacher.setSpecialization(specialization.trim());

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> teacherDAO.updateTeacher(teacher),
                "Teacher profile updated successfully.",
                "Failed to update teacher profile."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/teachers?msg=updated");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Numeric identifier fields must contain valid integers.");
            request.setAttribute("errorMessage", "Numeric identifier fields must contain valid integers.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/teachers?msg=error");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            // Safety check: Cannot delete teacher who has recorded sessions
            if (teacherDAO.hasAttendanceSessions(id)) {
                request.setAttribute("errorMsg", "Cannot delete teacher who has recorded attendance sessions.");
                request.setAttribute("errorMessage", "Cannot delete teacher who has recorded attendance sessions.");
                handleList(request, response);
                return;
            }

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> teacherDAO.deleteTeacher(id),
                "Teacher deleted successfully.",
                "Failed to delete teacher."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/teachers?msg=deleted");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Invalid teacher ID identifier.");
            request.setAttribute("errorMessage", "Invalid teacher ID identifier.");
            handleList(request, response);
        }
    }
}
