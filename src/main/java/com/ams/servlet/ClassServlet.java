package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.model.ClassSection;
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
            
            request.setAttribute("errorMsg", "Required fields (Class Name, Semester/Section, and Academic Year) cannot be empty.");
            request.setAttribute("errorMessage", "Required fields (Class Name, Semester/Section, and Academic Year) cannot be empty.");
            handleList(request, response);
            return;
        }

        // Class name uniqueness check
        if (classDAO.isClassNameExists(name.trim())) {
            request.setAttribute("errorMsg", "Class name is already registered.");
            request.setAttribute("errorMessage", "Class name is already registered.");
            handleList(request, response);
            return;
        }

        ClassSection classSection = new ClassSection();
        classSection.setName(name.trim());
        classSection.setSection(section.trim());
        classSection.setAcademicYear(academicYear.trim());

        Result<Boolean> result = ErrorHandler.executeSafely(
            () -> classDAO.addClass(classSection),
            "Class cohort registered successfully.",
            "Failed to register class cohort."
        );

        if (result.isSuccess() && result.getData()) {
            response.sendRedirect(request.getContextPath() + "/admin/classes?msg=added");
        } else {
            request.setAttribute("errorMsg", result.getMessage());
            request.setAttribute("errorMessage", result.getMessage());
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
            
            request.setAttribute("errorMsg", "All class fields are required for updates.");
            request.setAttribute("errorMessage", "All class fields are required for updates.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            // Class name uniqueness check
            if (classDAO.isClassNameExistsForOther(name.trim(), id)) {
                request.setAttribute("errorMsg", "Class name is already registered by another class cohort.");
                request.setAttribute("errorMessage", "Class name is already registered by another class cohort.");
                handleList(request, response);
                return;
            }

            ClassSection classSection = new ClassSection();
            classSection.setId(id);
            classSection.setName(name.trim());
            classSection.setSection(section.trim());
            classSection.setAcademicYear(academicYear.trim());

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> classDAO.updateClass(classSection),
                "Class cohort updated successfully.",
                "Failed to update class cohort."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/classes?msg=updated");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Class ID identifier must contain a valid integer.");
            request.setAttribute("errorMessage", "Class ID identifier must contain a valid integer.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/classes?msg=error");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            // Safety restriction: cannot delete a class cohort that has enrolled students or registered subjects
            if (classDAO.hasDependentStudentsOrSubjects(id)) {
                request.setAttribute("errorMsg", "Cannot delete class cohort that contains enrolled students or registered subjects.");
                request.setAttribute("errorMessage", "Cannot delete class cohort that contains enrolled students or registered subjects.");
                handleList(request, response);
                return;
            }

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> classDAO.deleteClass(id),
                "Class cohort deleted successfully.",
                "Failed to delete class cohort."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/classes?msg=deleted");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Invalid class ID identifier.");
            request.setAttribute("errorMessage", "Invalid class ID identifier.");
            handleList(request, response);
        }
    }
}
