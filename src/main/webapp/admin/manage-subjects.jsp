<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="com.ams.model.Teacher" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="java.util.List" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Verify session role standard guards
    if (session == null || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Admin - Manage Subjects</title>
    <!-- Core UI CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        /* Premium Backdrop Blur Modal Styles */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(30, 41, 59, 0.4);
            backdrop-filter: blur(8px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .modal-overlay.active {
            display: flex;
            opacity: 1;
        }
        .modal-container {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            width: 100%;
            max-width: 500px;
            box-shadow: var(--shadow-lg);
            overflow: hidden;
            transform: translateY(-20px);
            transition: transform 0.3s ease;
        }
        .modal-overlay.active .modal-container {
            transform: translateY(0);
        }
        .modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .modal-header h3 {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            color: var(--primary);
        }
        .modal-close-btn {
            background: none;
            border: none;
            color: var(--text-secondary);
            font-size: 24px;
            cursor: pointer;
            line-height: 1;
        }
        .modal-close-btn:hover {
            color: var(--danger);
        }
        .modal-body {
            padding: 24px;
            max-height: 65vh;
            overflow-y: auto;
        }
        .modal-footer {
            padding: 16px 24px;
            border-top: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 12px;
            background-color: var(--bg-app);
        }
        .search-action-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }
        .search-box-wrapper {
            position: relative;
            flex: 1;
            max-width: 400px;
        }
        .search-box-wrapper svg {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
        }
        .search-input-field {
            padding-left: 42px !important;
        }
    </style>
</head>
<body>

    <div class="app-wrapper">
        <!-- Reusable Sidebar -->
        <%@ include file="admin-sidebar.jsp" %>

        <div class="main-content">
            <!-- Header bar layout -->
            <header class="main-header">
                <button class="sidebar-toggle-btn hamburger-btn" aria-label="Toggle Navigation">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                </button>
                <div class="header-title">
                    <h2>Manage Subjects</h2>
                </div>
                <div class="user-profile-menu">
                    <div class="avatar">AD</div>
                </div>
            </header>

            <main class="content-body animate-fade">
                <!-- Server-Side Error Alert Box -->
                <c:if test="${not empty errorMessage}">
                    <div style="background-color: var(--danger-light); color: var(--danger); border: 1px solid var(--danger); padding: 14px 20px; border-radius: var(--border-radius-sm); margin-bottom: 24px; font-weight: 500;" class="animate-fade">
                        ${errorMessage}
                    </div>
                </c:if>

                <!-- Search and Add Header Actions -->
                <div class="search-action-bar">
                    <div class="search-box-wrapper">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                        <input type="text" id="searchInput" class="form-control search-input-field" placeholder="Search by name or subject code...">
                    </div>
                    <button class="btn btn-primary" onclick="openAddModal()">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                        <span>Add Subject</span>
                    </button>
                </div>

                <!-- Subjects Table Card -->
                <div class="table-responsive">
                    <table class="table" id="subjectsTable">
                        <thead>
                            <tr>
                                <th>Subject Code</th>
                                <th>Subject Name</th>
                                <th>Assigned Teacher</th>
                                <th>Class Cohort</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${empty subjects}">
                                    <tr>
                                        <td colspan="5" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                            No subject records found in the database.
                                        </td>
                                    </tr>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="subject" items="${subjects}">
                                        <tr>
                                            <td><strong>${subject.code}</strong></td>
                                            <td>${subject.name}</td>
                                            <td>
                                                <c:set var="teacherFound" value="false" />
                                                <c:forEach var="t" items="${teachers}">
                                                    <c:if test="${t.id == subject.teacherId}">
                                                        ${t.firstName} ${t.lastName}
                                                        <c:set var="teacherFound" value="true" />
                                                    </c:if>
                                                </c:forEach>
                                                <c:if test="${!teacherFound}">
                                                    <span style="color: var(--text-muted); font-style: italic;">Unassigned</span>
                                                </c:if>
                                            </td>
                                            <td>
                                                <c:forEach var="cls" items="${classes}">
                                                    <c:if test="${cls.id == subject.classId}">
                                                        <span class="badge badge-info">${cls.name}</span>
                                                    </c:if>
                                                </c:forEach>
                                            </td>
                                            <td>
                                                <div style="display: flex; gap: 8px;">
                                                    <button class="btn btn-secondary" style="padding: 6px 12px; font-size: 13px;" 
                                                            onclick="openEditModal({
                                                                id: '${subject.id}',
                                                                code: '${subject.code}',
                                                                name: '${subject.name}',
                                                                teacherId: '${subject.teacherId}',
                                                                classId: '${subject.classId}'
                                                            })">
                                                        Edit
                                                    </button>
                                                    <a href="${pageContext.request.contextPath}/admin/subjects?action=delete&id=${subject.id}" 
                                                       class="btn btn-danger" style="padding: 6px 12px; font-size: 13px;"
                                                       onclick="return confirmDelete(event, '${subject.name} (${subject.code})')">
                                                        Delete
                                                    </a>
                                                </div>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>
            </main>
        </div>
    </div>

    <!-- Subject Edit/Add Modal Overlay -->
    <div class="modal-overlay" id="subjectModal">
        <div class="modal-container">
            <div class="modal-header">
                <h3 id="modalTitle">Add Subject Catalog</h3>
                <button class="modal-close-btn" onclick="closeModal()">&times;</button>
            </div>
            <form id="subjectForm" method="POST" action="${pageContext.request.contextPath}/admin/subjects">
                <div class="modal-body">
                    <!-- Action Parameter Hidden Input -->
                    <input type="hidden" name="action" id="formAction" value="add">
                    <input type="hidden" name="subjectId" id="subjectId">

                    <div class="form-group">
                        <label class="form-label">Subject Code *</label>
                        <input type="text" name="code" id="code" class="form-control" placeholder="e.g. CS101" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Subject Name *</label>
                        <input type="text" name="name" id="name" class="form-control" placeholder="e.g. Data Structures" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Target Class Cohort *</label>
                        <select name="classId" id="classId" class="form-control" required>
                            <option value="">-- Select Class --</option>
                            <c:forEach var="cls" items="${classes}">
                                <option value="${cls.id}">${cls.name}</option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Assigned Lecturer</label>
                        <select name="teacherId" id="teacherId" class="form-control">
                            <option value="">-- Unassigned --</option>
                            <c:forEach var="t" items="${teachers}">
                                <option value="${t.id}">${t.firstName} ${t.lastName} (${t.specialization})</option>
                            </c:forEach>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Subject</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Initialize client-side table searching
        initTableSearch("subjectsTable", "searchInput", [0, 1, 2]);

        // Schema validation definitions
        const subjectSchema = {
            code: { required: true, minLength: 3, message: "Subject Code is required and must be at least 3 characters." },
            name: { required: true, message: "Subject Name is required." },
            classId: { required: true, message: "Please select a target class cohort." }
        };

        // Form Submit Validation Binder
        const form = document.getElementById("subjectForm");
        form.addEventListener("submit", (e) => {
            if (!validateForm(form, subjectSchema)) {
                e.preventDefault();
                showToast("Please correct the validation errors in the form.", "danger");
            }
        });

        // Toast Messages Auto triggers based on query params
        window.addEventListener("DOMContentLoaded", () => {
            const urlParams = new URLSearchParams(window.location.search);
            const msg = urlParams.get("msg");
            if (msg === "added") {
                showToast("Subject successfully added to catalog!", "success");
            } else if (msg === "updated") {
                showToast("Subject details successfully updated!", "success");
            } else if (msg === "deleted") {
                showToast("Subject successfully removed.", "success");
            } else if (msg === "error") {
                showToast("Failed to complete the operation. Database error occurred.", "danger");
            }
        });

        // Modal Action Toggles
        const modal = document.getElementById("subjectModal");

        function openAddModal() {
            document.getElementById("modalTitle").innerText = "Add Subject Catalog";
            document.getElementById("formAction").value = "add";
            document.getElementById("subjectId").value = "";
            form.reset();
            modal.classList.add("active");
        }

        function openEditModal(sub) {
            document.getElementById("modalTitle").innerText = "Edit Subject Details";
            document.getElementById("formAction").value = "edit";
            document.getElementById("subjectId").value = sub.id;
            
            document.getElementById("code").value = sub.code;
            document.getElementById("name").value = sub.name;
            document.getElementById("classId").value = sub.classId;
            document.getElementById("teacherId").value = (sub.teacherId === "0" || sub.teacherId === "") ? "" : sub.teacherId;
            
            modal.classList.add("active");
        }

        function closeModal() {
            modal.classList.remove("active");
        }
    </script>
</body>
</html>
