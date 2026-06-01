package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.model.ClassSection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * ClassServlet.java
 * Purpose: Administrative CRUD controller for class cohorts and sections.
 * 
 * Mapping: Mapped to /admin/classes
 */
@WebServlet("/admin/classes")
public class ClassServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private ClassDAO classDAO;

    @Override
    public void init() throws ServletException {
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
        List<ClassSection> classes = classDAO.getAllClasses();
        request.setAttribute("classes", classes);
        request.getRequestDispatcher("/admin/manage-classes.jsp").forward(request, response);
    }

    private void handleAdd(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String name = request.getParameter("className");
        String section = request.getParameter("section");
        String academicYear = request.getParameter("academicYear");

        if (name == null || name.trim().isEmpty() ||
            section == null || section.trim().isEmpty() ||
            academicYear == null || academicYear.trim().isEmpty()) {
            
            request.setAttribute("errorMessage", "Required fields (Class Name, Semester/Section, and Academic Year) cannot be empty.");
            handleList(request, response);
            return;
        }

        ClassSection classSection = new ClassSection();
        classSection.setName(name.trim());
        classSection.setSection(section.trim());
        classSection.setAcademicYear(academicYear.trim());

        boolean success = classDAO.addClass(classSection);
        if (success) {
            response.sendRedirect(request.getContextPath() + "/admin/classes?msg=added");
        } else {
            request.setAttribute("errorMessage", "Error adding class cohort. Class Name may already exist.");
            handleList(request, response);
        }
    }

    private void handleEdit(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("classId");
        String name = request.getParameter("className");
        String section = request.getParameter("section");
        String academicYear = request.getParameter("academicYear");

        if (idStr == null || name == null || name.trim().isEmpty() ||
            section == null || section.trim().isEmpty() ||
            academicYear == null || academicYear.trim().isEmpty()) {
            
            request.setAttribute("errorMessage", "All class fields are required for update.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            ClassSection classSection = new ClassSection();
            classSection.setId(id);
            classSection.setName(name.trim());
            classSection.setSection(section.trim());
            classSection.setAcademicYear(academicYear.trim());

            boolean success = classDAO.updateClass(classSection);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/admin/classes?msg=updated");
            } else {
                request.setAttribute("errorMessage", "Error updating class cohort. Class Name may clash with another section.");
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMessage", "Invalid numeric identifier passed.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int id = Integer.parseInt(idStr);
                boolean success = classDAO.deleteClass(id);
                if (success) {
                    response.sendRedirect(request.getContextPath() + "/admin/classes?msg=deleted");
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        response.sendRedirect(request.getContextPath() + "/admin/classes?msg=error");
    }
}
