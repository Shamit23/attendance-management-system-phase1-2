package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.SubjectDAO;
import com.ams.dao.TeacherDAO;
import com.ams.model.ClassSection;
import com.ams.model.Subject;
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
 * SubjectServlet.java
 * Purpose: Administrative CRUD controller for subjects catalogs.
 * 
 * Mapping: Mapped to /admin/subjects
 */
@WebServlet("/admin/subjects")
public class SubjectServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private SubjectDAO subjectDAO;
    private TeacherDAO teacherDAO;
    private ClassDAO classDAO;

    @Override
    public void init() throws ServletException {
        subjectDAO = new SubjectDAO();
        teacherDAO = new TeacherDAO();
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
        List<Subject> subjects = subjectDAO.getAllSubjects();
        List<Teacher> teachers = teacherDAO.getAllTeachers();
        List<ClassSection> classes = classDAO.getAllClasses();

        request.setAttribute("subjects", subjects);
        request.setAttribute("teachers", teachers);
        request.setAttribute("classes", classes);
        request.getRequestDispatcher("/admin/manage-subjects.jsp").forward(request, response);
    }

    private void handleAdd(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String code = request.getParameter("code");
        String name = request.getParameter("name");
        String teacherIdStr = request.getParameter("teacherId");
        String classIdStr = request.getParameter("classId");

        if (code == null || code.trim().isEmpty() ||
            name == null || name.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "Required fields (Subject Code, Subject Name, and Class Section) cannot be empty.");
            request.setAttribute("errorMessage", "Required fields (Subject Code, Subject Name, and Class Section) cannot be empty.");
            handleList(request, response);
            return;
        }

        try {
            int classId = Integer.parseInt(classIdStr);
            int teacherId = 0;
            if (teacherIdStr != null && !teacherIdStr.trim().isEmpty()) {
                teacherId = Integer.parseInt(teacherIdStr);
            }

            // Subject Code uniqueness check
            if (subjectDAO.isCodeExists(code.trim().toUpperCase())) {
                request.setAttribute("errorMsg", "Subject code is already registered.");
                request.setAttribute("errorMessage", "Subject code is already registered.");
                handleList(request, response);
                return;
            }

            Subject subject = new Subject();
            subject.setCode(code.trim().toUpperCase());
            subject.setName(name.trim());
            subject.setTeacherId(teacherId);
            subject.setClassId(classId);

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> subjectDAO.addSubject(subject),
                "Subject catalog registered successfully.",
                "Failed to register subject."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=added");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Class and Teacher ID identifiers must contain valid integers.");
            request.setAttribute("errorMessage", "Class and Teacher ID identifiers must contain valid integers.");
            handleList(request, response);
        }
    }

    private void handleEdit(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("subjectId");
        String code = request.getParameter("code");
        String name = request.getParameter("name");
        String teacherIdStr = request.getParameter("teacherId");
        String classIdStr = request.getParameter("classId");

        if (idStr == null || code == null || code.trim().isEmpty() ||
            name == null || name.trim().isEmpty() ||
            classIdStr == null || classIdStr.trim().isEmpty()) {
            
            request.setAttribute("errorMsg", "All subject fields are required for updates.");
            request.setAttribute("errorMessage", "All subject fields are required for updates.");
            handleList(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            int classId = Integer.parseInt(classIdStr);
            int teacherId = 0;
            if (teacherIdStr != null && !teacherIdStr.trim().isEmpty()) {
                teacherId = Integer.parseInt(teacherIdStr);
            }

            // Subject Code uniqueness check
            if (subjectDAO.isCodeExistsForOther(code.trim().toUpperCase(), id)) {
                request.setAttribute("errorMsg", "Subject code is already registered by another subject.");
                request.setAttribute("errorMessage", "Subject code is already registered by another subject.");
                handleList(request, response);
                return;
            }

            Subject subject = new Subject();
            subject.setId(id);
            subject.setCode(code.trim().toUpperCase());
            subject.setName(name.trim());
            subject.setTeacherId(teacherId);
            subject.setClassId(classId);

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> subjectDAO.updateSubject(subject),
                "Subject catalog updated successfully.",
                "Failed to update subject."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=updated");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Subject, Class, and Teacher ID identifiers must contain valid integers.");
            request.setAttribute("errorMessage", "Subject, Class, and Teacher ID identifiers must contain valid integers.");
            handleList(request, response);
        }
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=error");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);

            // Safety restriction: cannot delete a subject that has recorded attendance
            if (subjectDAO.hasAttendance(id)) {
                request.setAttribute("errorMsg", "Cannot delete subject that has recorded attendance logs.");
                request.setAttribute("errorMessage", "Cannot delete subject that has recorded attendance logs.");
                handleList(request, response);
                return;
            }

            Result<Boolean> result = ErrorHandler.executeSafely(
                () -> subjectDAO.deleteSubject(id),
                "Subject catalog deleted successfully.",
                "Failed to delete subject."
            );

            if (result.isSuccess() && result.getData()) {
                response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=deleted");
            } else {
                request.setAttribute("errorMsg", result.getMessage());
                request.setAttribute("errorMessage", result.getMessage());
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMsg", "Invalid subject ID identifier.");
            request.setAttribute("errorMessage", "Invalid subject ID identifier.");
            handleList(request, response);
        }
    }
}
