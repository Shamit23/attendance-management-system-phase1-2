package com.ams.servlet;

import com.ams.dao.ClassDAO;
import com.ams.dao.SubjectDAO;
import com.ams.dao.TeacherDAO;
import com.ams.model.ClassSection;
import com.ams.model.Subject;
import com.ams.model.Teacher;

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

            Subject subject = new Subject();
            subject.setCode(code.trim().toUpperCase());
            subject.setName(name.trim());
            subject.setTeacherId(teacherId);
            subject.setClassId(classId);

            boolean success = subjectDAO.addSubject(subject);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=added");
            } else {
                request.setAttribute("errorMessage", "Error adding subject. Code may already exist.");
                handleList(request, response);
            }
        } catch (NumberFormatException e) {
            request.setAttribute("errorMessage", "Invalid numeric identifier selected.");
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
            
            request.setAttribute("errorMessage", "All subject fields are required for update.");
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

            Subject subject = new Subject();
            subject.setId(id);
            subject.setCode(code.trim().toUpperCase());
            subject.setName(name.trim());
            subject.setTeacherId(teacherId);
            subject.setClassId(classId);

            boolean success = subjectDAO.updateSubject(subject);
            if (success) {
                response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=updated");
            } else {
                request.setAttribute("errorMessage", "Error updating subject. Code may clash with another subject.");
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
                boolean success = subjectDAO.deleteSubject(id);
                if (success) {
                    response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=deleted");
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        response.sendRedirect(request.getContextPath() + "/admin/subjects?msg=error");
    }
}
