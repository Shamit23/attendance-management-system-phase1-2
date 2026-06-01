package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.StudentDAO;
import com.ams.model.ClassSection;
import com.ams.model.Student;
import com.ams.util.ErrorHandler;
import com.ams.util.Result;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Date;
import java.util.List;

/**
 * StudentServlet.java
 * Purpose: Administrative CRUD controller for student accounts and profiles.
 * 
 * Mapping: Mapped to /admin/students
 */
@WebServlet("/admin/students")
public class StudentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private StudentDAO studentDAO;
    private ClassDAO classDAO;

    @Override
    public void init() throws ServletException {
        studentDAO = new StudentDAO();
        classDAO = new ClassDAO();
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
        List<Student> students = studentDAO.getAllStudents();
        List<ClassSection> classes = classDAO.getAllClasses();
        
        request.setAttribute("students", students);
        request.setAttribute("classes", classes);
        request.getRequestDispatcher("/admin/manage-students.jsp").forward(request, response);
    }

    private void handleAdd(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String rollNo = request.getParameter("rollNo");
        String classIdStr = request.getParameter("classId");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String dobStr = request.getParameter("dateOfBirth");

        // 1. Server-side validation
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            rollNo == null || rollNo.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            dobStr == null || dobStr.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "Required fields (First Name, Last Name, Roll No, Class, Email, and Date of Birth) cannot be empty.");
            request.setAttribute("errorMessage", "Required fields (First Name, Last Name, Roll No, Class, Email, and Date of Birth) cannot be empty.");
            handleList(request, response);
            return;
        }

        try {
            int classId = Integer.parseInt(classIdStr);
            Date dob = Date.valueOf(dobStr);

            // Duplicate Detection Check
            if (studentDAO.isRollNumberExists(rollNo.trim().toUpperCase())) {
                request.setAttribute("errorMsg", "Roll number is already in use by another student.");
                request.setAttribute("errorMessage", "Roll number is already in use by another student.");
                handleList(request, response);
                return;
            }
            if (studentDAO.isEmailExists(email.trim())) {
                request.setAttribute("errorMsg", "Email address is already in use.");
                request.setAttribute("errorMessage", "Email address is already in use.");
                handleList(request, response);
                return;
            }

            Student student = new Student();
            student.setFirstName(firstName.trim());
            student.setLastName(lastName.trim());
            student.setRollNo(rollNo.trim().toUpperCase());
            student.setClassId(classId);
            student.setEmail(email.trim());
            student.setPhone(phone != null ? phone.trim() : null);
            student.setDateOfBirth(dob);

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> studentDAO.addStudent(student),
                "Student account registered successfully.",
                "Failed to register student profile."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/students?msg=added");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Class ID must be a numeric integer.");
            request.setAttribute("errorMessage", "Class ID must be a numeric integer.");
            handleList(request, response);
        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMsg", "Invalid Date of Birth selection.");
            request.setAttribute("errorMessage", "Invalid Date of Birth selection.");
            handleList(request, response);
        }
    }

    private void handleEdit(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("studentId");
        String userIdStr = request.getParameter("userId");
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String rollNo = request.getParameter("rollNo");
        String classIdStr = request.getParameter("classId");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String dobStr = request.getParameter("dateOfBirth");

        // 1. Server-side validation
        if (idStr == null || userIdStr == null ||
            firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            rollNo == null || rollNo.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            dobStr == null || dobStr.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "All profile fields are required for updates.");
            request.setAttribute("errorMessage", "All profile fields are required for updates.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            int userId = Integer.parseInt(userIdStr);
            int classId = Integer.parseInt(classIdStr);
            Date dob = Date.valueOf(dobStr);

            // Duplicate Detection Check
            if (studentDAO.isRollNumberExistsForOther(rollNo.trim().toUpperCase(), id)) {
                request.setAttribute("errorMsg", "Roll number is already in use by another student.");
                request.setAttribute("errorMessage", "Roll number is already in use by another student.");
                handleList(request, response);
                return;
            }
            if (studentDAO.isEmailExistsForOther(email.trim(), userId)) {
                request.setAttribute("errorMsg", "Email address is already in use.");
                request.setAttribute("errorMessage", "Email address is already in use.");
                handleList(request, response);
                return;
            }

            Student student = new Student();
            student.setId(id);
            student.setUserId(userId);
            student.setFirstName(firstName.trim());
            student.setLastName(lastName.trim());
            student.setRollNo(rollNo.trim().toUpperCase());
            student.setClassId(classId);
            student.setEmail(email.trim());
            student.setPhone(phone != null ? phone.trim() : null);
            student.setDateOfBirth(dob);

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> studentDAO.updateStudent(student),
                "Student account updated successfully.",
                "Failed to update student profile."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/students?msg=updated");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Numeric identifier fields must contain valid integers.");
            request.setAttribute("errorMessage", "Numeric identifier fields must contain valid integers.");
            handleList(request, response);
        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMsg", "Invalid Date of Birth selection format.");
            request.setAttribute("errorMessage", "Invalid Date of Birth selection format.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/students?msg=error");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            // Business Rule: cannot delete a student who has attendance records (show friendly error)
            if (studentDAO.hasAttendanceRecords(id)) {
                request.setAttribute("errorMsg", "Cannot delete student who has recorded attendance logs.");
                request.setAttribute("errorMessage", "Cannot delete student who has recorded attendance logs.");
                handleList(request, response);
                return;
            }

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> studentDAO.deleteStudent(id),
                "Student deleted successfully.",
                "Failed to delete student."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/students?msg=deleted");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Invalid student ID identifier.");
            request.setAttribute("errorMessage", "Invalid student ID identifier.");
            handleList(request, response);
        }
    }
}
