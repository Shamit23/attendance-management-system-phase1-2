package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.StudentDAO;
import com.ams.model.ClassSection;
import com.ams.model.Student;

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

        // 1. Server-side validations
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            rollNo == null || rollNo.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            dobStr == null || dobStr.trim().isEmpty()) {
            
            request.setAttribute("errorMessage", "Required fields (First Name, Last Name, Roll No, Class, Email, and Date of Birth) cannot be empty.");
            handleList(request, response);
            return;
        }

        try {
            int classId = Integer.parseInt(classIdStr);
            Date dob = Date.valueOf(dobStr);

            Student student = new Student();
            student.setFirstName(firstName.trim());
            student.setLastName(lastName.trim());
            student.setRollNo(rollNo.trim().toUpperCase());
            student.setClassId(classId);
            student.setEmail(email.trim());
            student.setPhone(phone != null ? phone.trim() : null);
            student.setDateOfBirth(dob);

            boolean success = studentDAO.addStudent(student);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/admin/students?msg=added");
            } else {
                request.setAttribute("errorMessage", "Error saving student profile. Roll number or Email might already exist.");
                handleList(request, response);
            }
        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMessage", "Invalid Date of Birth format. Please select a valid date.");
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

        // 1. Server-side validations
        if (idStr == null || userIdStr == null ||
            firstName == null || firstName.trim().isEmpty() ||
            lastName == null || lastName.trim().isEmpty() ||
            rollNo == null || rollNo.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            dobStr == null || dobStr.trim().isEmpty()) {
            
            request.setAttribute("errorMessage", "All profile fields are required for update.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            int userId = Integer.parseInt(userIdStr);
            int classId = Integer.parseInt(classIdStr);
            Date dob = Date.valueOf(dobStr);

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

            boolean success = studentDAO.updateStudent(student);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/admin/students?msg=updated");
            } else {
                request.setAttribute("errorMessage", "Error updating student. Email or Roll Number may collide with another profile.");
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMessage", "Invalid numeric identifier properties passed.");
            handleList(request, response);
        } catch (IllegalArgumentException e) {
            request.setAttribute("errorMessage", "Invalid Date of Birth format.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int id = Integer.parseInt(idStr);
                boolean success = studentDAO.deleteStudent(id);
                if (success) {
                    response.sendRedirect(request.getContextPath() + "/admin/students?msg=deleted");
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        response.sendRedirect(request.getContextPath() + "/admin/students?msg=error");
    }
}
