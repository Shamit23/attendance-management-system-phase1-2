<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.model.Student" %>
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
    <title>AMS Admin - Manage Students</title>
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
            max-width: 550px;
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
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }
        @media (max-width: 480px) {
            .form-row {
                grid-template-columns: 1fr;
                gap: 0;
            }
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
                    <h2>Manage Students</h2>
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
                        <input type="text" id="searchInput" class="form-control search-input-field" placeholder="Search by name or roll number...">
                    </div>
                    <button class="btn btn-primary" onclick="openAddModal()">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                        <span>Add Student</span>
                    </button>
                </div>

                <!-- Students Table Card -->
                <div class="table-responsive">
                    <table class="table" id="studentsTable">
                        <thead>
                            <tr>
                                <th>Roll No</th>
                                <th>Student Name</th>
                                <th>Class Cohort</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${empty students}">
                                    <tr>
                                        <td colspan="6" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                            No student records found in the database.
                                        </td>
                                    </tr>
                                </c:when>
                                <c:otherwise>
                                    <c:forEach var="student" items="${students}">
                                        <tr>
                                            <td><strong>${student.rollNo}</strong></td>
                                            <td>${student.firstName} ${student.lastName}</td>
                                            <td>
                                                <c:forEach var="cls" items="${classes}">
                                                    <c:if test="${cls.id == student.classId}">
                                                        <span class="badge badge-info">${cls.name}</span>
                                                    </c:if>
                                                </c:forEach>
                                            </td>
                                            <td>${student.email}</td>
                                            <td>${student.phone != null ? student.phone : '-'}</td>
                                            <td>
                                                <div style="display: flex; gap: 8px;">
                                                    <button class="btn btn-secondary" style="padding: 6px 12px; font-size: 13px;" 
                                                            onclick="openEditModal({
                                                                id: '${student.id}',
                                                                userId: '${student.userId}',
                                                                classId: '${student.classId}',
                                                                firstName: '${student.firstName}',
                                                                lastName: '${student.lastName}',
                                                                rollNo: '${student.rollNo}',
                                                                email: '${student.email}',
                                                                phone: '${student.phone}',
                                                                dob: '${student.dateOfBirth}'
                                                            })">
                                                        Edit
                                                    </button>
                                                    <a href="${pageContext.request.contextPath}/admin/students?action=delete&id=${student.id}" 
                                                       class="btn btn-danger" style="padding: 6px 12px; font-size: 13px;"
                                                       onclick="return confirmDelete(event, '${student.firstName} ${student.lastName}')">
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

    <!-- Student Edit/Add Modal Overlay -->
    <div class="modal-overlay" id="studentModal">
        <div class="modal-container">
            <div class="modal-header">
                <h3 id="modalTitle">Register Student Profile</h3>
                <button class="modal-close-btn" onclick="closeModal()">&times;</button>
            </div>
            <form id="studentForm" method="POST" action="${pageContext.request.contextPath}/admin/students">
                <div class="modal-body">
                    <!-- Action Parameter Hidden Input -->
                    <input type="hidden" name="action" id="formAction" value="add">
                    <input type="hidden" name="studentId" id="studentId">
                    <input type="hidden" name="userId" id="userId">

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">First Name *</label>
                            <input type="text" name="firstName" id="firstName" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Last Name *</label>
                            <input type="text" name="lastName" id="lastName" class="form-control" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Roll Number *</label>
                            <input type="text" name="rollNo" id="rollNo" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Class Section *</label>
                            <select name="classId" id="classId" class="form-control" required>
                                <option value="">-- Choose Class --</option>
                                <c:forEach var="cls" items="${classes}">
                                    <option value="${cls.id}">${cls.name}</option>
                                </c:forEach>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Email Address *</label>
                        <input type="email" name="email" id="email" class="form-control" required>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Contact Phone</label>
                            <input type="text" name="phone" id="phone" class="form-control">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Date of Birth *</label>
                            <input type="date" name="dateOfBirth" id="dateOfBirth" class="form-control" required>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Student</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Initialize client-side table searching
        initTableSearch("studentsTable", "searchInput", [0, 1, 3]);

        // Schema validation definitions
        const studentSchema = {
            firstName: { required: true, message: "First name is required." },
            lastName: { required: true, message: "Last name is required." },
            rollNo: { required: true, minLength: 3, message: "Roll number must be at least 3 characters." },
            classId: { required: true, message: "Please select a class cohort." },
            email: { required: true, email: true, message: "Please enter a valid email address." },
            dateOfBirth: { required: true, message: "Date of Birth is required." }
        };

        // Form Submit Validation Binder
        const form = document.getElementById("studentForm");
        form.addEventListener("submit", (e) => {
            if (!validateForm(form, studentSchema)) {
                e.preventDefault();
                showToast("Please correct the validation errors in the form.", "danger");
            }
        });

        // Toast Messages Auto triggers based on query params
        window.addEventListener("DOMContentLoaded", () => {
            const urlParams = new URLSearchParams(window.location.search);
            const msg = urlParams.get("msg");
            if (msg === "added") {
                showToast("Student profile successfully registered!", "success");
            } else if (msg === "updated") {
                showToast("Student profile successfully updated!", "success");
            } else if (msg === "deleted") {
                showToast("Student profile successfully removed.", "success");
            } else if (msg === "error") {
                showToast("Failed to complete the operation. Database error occurred.", "danger");
            }
        });

        // Modal Action Toggles
        const modal = document.getElementById("studentModal");

        function openAddModal() {
            document.getElementById("modalTitle").innerText = "Register Student Profile";
            document.getElementById("formAction").value = "add";
            document.getElementById("studentId").value = "";
            document.getElementById("userId").value = "";
            form.reset();
            modal.classList.add("active");
        }

        function openEditModal(student) {
            document.getElementById("modalTitle").innerText = "Edit Student Profile";
            document.getElementById("formAction").value = "edit";
            document.getElementById("studentId").value = student.id;
            document.getElementById("userId").value = student.userId;
            
            document.getElementById("firstName").value = student.firstName;
            document.getElementById("lastName").value = student.lastName;
            document.getElementById("rollNo").value = student.rollNo;
            document.getElementById("classId").value = student.classId;
            document.getElementById("email").value = student.email;
            document.getElementById("phone").value = student.phone === "null" ? "" : student.phone;
            document.getElementById("dateOfBirth").value = student.dob;
            
            modal.classList.add("active");
        }

        function closeModal() {
            modal.classList.remove("active");
        }
    </script>
</body>
</html>
