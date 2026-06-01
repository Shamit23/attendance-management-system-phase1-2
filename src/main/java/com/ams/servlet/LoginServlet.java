package com.ams.servlet;

import com.ams.dao.StudentDAO;
import com.ams.dao.TeacherDAO;
import com.ams.dao.UserDAO;
import com.ams.model.Student;
import com.ams.model.Teacher;
import com.ams.model.User;
import com.ams.util.ErrorHandler;
import com.ams.util.Result;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;

/**
 * LoginServlet.java
 * Controller Servlet mapping user authentications and initiating portal sessions.
 * 
 * Mapping: Registered on /login
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private UserDAO userDAO;
    private TeacherDAO teacherDAO;
    private StudentDAO studentDAO;

    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
        teacherDAO = new TeacherDAO();
        studentDAO = new StudentDAO();
    }

    /**
     * Handles HTTP GET request. Routes the browser directly to the central login JSP.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        // If already logged in, bypass the login screen and route directly to portals
        if (session != null && session.getAttribute("role") != null) {
            redirectToDashboard(response, request.getContextPath(), (String) session.getAttribute("role"));
            return;
        }
        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }

    /**
     * Handles HTTP POST logins. Inspects username, password, and selected role.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String role = request.getParameter("role");

        // 1. Server-side validation
        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty() ||
            role == null || role.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All credentials and portal role selections are required.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        username = username.trim();
        role = role.trim().toUpperCase();

        // 2. Perform authentication query wrapped with ErrorHandler
        final String finalUsername = username;
        final String finalPassword = password;
        Result<User> result = ErrorHandler.executeSafely(
            () -> userDAO.authenticate(finalUsername, finalPassword),
            "Authentication check complete.",
            "Authentication failed due to database server connection issue."
        );

        if (!result.isSuccess()) {
            request.setAttribute("errorMessage", result.getMessage());
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        User user = result.getData();

        if (user != null) {
            // Verify role matching
            if (user.getRole().equalsIgnoreCase(role)) {
                // Initialize central session
                HttpSession session = request.getSession(true);
                session.setAttribute("userId", user.getId());
                session.setAttribute("username", user.getUsername());
                session.setAttribute("role", user.getRole());
                session.setAttribute("email", user.getEmail());

                // Fetch concrete profiles to simplify downstream queries
                if ("TEACHER".equals(user.getRole())) {
                    List<Teacher> teachers = teacherDAO.getAllTeachers();
                    for (Teacher t : teachers) {
                        if (t.getUserId() == user.getId()) {
                            session.setAttribute("teacherId", t.getId());
                            session.setAttribute("fullName", t.getFirstName() + " " + t.getLastName());
                            break;
                        }
                    }
                } else if ("STUDENT".equals(user.getRole())) {
                    List<Student> students = studentDAO.getAllStudents();
                    for (Student s : students) {
                        if (s.getUserId() == user.getId()) {
                            session.setAttribute("studentId", s.getId());
                            session.setAttribute("fullName", s.getFirstName() + " " + s.getLastName());
                            session.setAttribute("classId", s.getClassId());
                            break;
                        }
                    }
                } else {
                    session.setAttribute("fullName", "System Administrator");
                }

                // Redirect to matching portal
                redirectToDashboard(response, request.getContextPath(), user.getRole());
            } else {
                // Authentication succeeded but role selection was incorrect
                request.setAttribute("errorMessage", "Role authorization mismatch. Access denied.");
                request.getRequestDispatcher("/login.jsp").forward(request, response);
            }
        } else {
            // Authentication failed
            request.setAttribute("errorMessage", "Invalid username or password. Please try again.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    /**
     * Helper mapping portal redirects.
     */
    private void redirectToDashboard(HttpServletResponse response, String contextPath, String role) 
            throws IOException {
        switch (role.toUpperCase()) {
            case "ADMIN":
                response.sendRedirect(contextPath + "/admin/dashboard.jsp");
                break;
            case "TEACHER":
                response.sendRedirect(contextPath + "/teacher/dashboard.jsp");
                break;
            case "STUDENT":
                response.sendRedirect(contextPath + "/student/dashboard.jsp");
                break;
            default:
                response.sendRedirect(contextPath + "/login.jsp");
        }
    }
}
