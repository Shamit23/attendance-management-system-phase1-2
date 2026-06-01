<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.ams.dao.StudentDAO" %>
<%@ page import="com.ams.dao.SubjectDAO" %>
<%@ page import="com.ams.dao.ClassDAO" %>
<%@ page import="com.ams.dao.AttendanceDAO" %>
<%@ page import="com.ams.model.Subject" %>
<%@ page import="com.ams.model.ClassSection" %>
<%@ page import="com.ams.model.Attendance" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Verify session credentials using standard server-side guards
    if (session == null || !"TEACHER".equals(session.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    Integer teacherId = (Integer) session.getAttribute("teacherId");
    if (teacherId == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=unauthorized");
        return;
    }

    // Initialize DAOs to fetch dynamic metrics
    SubjectDAO subjectDAO = new SubjectDAO();
    StudentDAO studentDAO = new StudentDAO();
    ClassDAO classDAO = new ClassDAO();
    AttendanceDAO attendanceDAO = new AttendanceDAO();

    List<Subject> subjects = subjectDAO.getSubjectsByTeacher(teacherId);

    // Get parameters
    String subjectIdStr = request.getParameter("subjectId");
    String dateStr = request.getParameter("date");
    String slotStr = request.getParameter("slot");

    int selectedSubjectId = 0;
    if (subjectIdStr != null && !subjectIdStr.isEmpty()) {
        try {
            selectedSubjectId = Integer.parseInt(subjectIdStr);
        } catch (NumberFormatException e) {
            // invalid input
        }
    }

    Date selectedDate = new Date(System.currentTimeMillis());
    if (dateStr != null && !dateStr.isEmpty()) {
        try {
            selectedDate = Date.valueOf(dateStr);
        } catch (IllegalArgumentException e) {
            // invalid date fallback to today
        }
    }

    String selectedSlot = "09:00 - 10:00 AM";
    if (slotStr != null && !slotStr.isEmpty()) {
        selectedSlot = slotStr;
    }

    Subject selectedSubject = null;
    ClassSection selectedClass = null;
    if (selectedSubjectId > 0) {
        final int targetId = selectedSubjectId;
        selectedSubject = subjects.stream().filter(s -> s.getId() == targetId).findFirst().orElse(null);
        if (selectedSubject != null) {
            selectedClass = classDAO.getClassById(selectedSubject.getClassId());
        }
    }

    boolean showStep2 = (selectedSubject != null);
    boolean isEditMode = false;
    int attendanceId = 0;
    List<Map<String, Object>> studentList = new ArrayList<>();

    if (showStep2) {
        // Check if attendance already exists for this subject and date
        Attendance existing = attendanceDAO.getAttendanceByDate(selectedSubject.getId(), selectedDate);
        if (existing != null) {
            isEditMode = true;
            attendanceId = existing.getId();
            selectedSlot = existing.getSlot();

            // Load existing student detail grades in edit mode
            List<com.ams.model.AttendanceDetail> details = attendanceDAO.getAttendanceDetailsByMasterId(attendanceId);
            for (com.ams.model.AttendanceDetail detail : details) {
                com.ams.model.Student s = studentDAO.getStudentById(detail.getStudentId());
                if (s != null) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", s.getId());
                    map.put("rollNo", s.getRollNo());
                    map.put("name", s.getFirstName() + " " + s.getLastName());
                    map.put("status", detail.getStatus()); // 'P', 'A', 'L', 'E'
                    map.put("remarks", detail.getRemarks() != null ? detail.getRemarks() : "");
                    studentList.add(map);
                }
            }
        } else {
            // Load students belonging to class cohort with default Present status
            List<com.ams.model.Student> students = studentDAO.getStudentsByClass(selectedSubject.getClassId());
            for (com.ams.model.Student s : students) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", s.getId());
                map.put("rollNo", s.getRollNo());
                map.put("name", s.getFirstName() + " " + s.getLastName());
                map.put("status", "P");
                map.put("remarks", "");
                studentList.add(map);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMS Teacher - Mark Attendance</title>
    <!-- Core UI CSS -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .step-container {
            margin-bottom: 24px;
        }
        .step-title {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--primary);
        }
        .step-number {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background-color: var(--accent);
            color: white;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
        }
        .attendance-row {
            transition: background-color var(--transition-fast);
        }
        .attendance-row:hover {
            background-color: var(--accent-light);
        }
        /* Custom radio buttons styling */
        .status-options {
            display: flex;
            gap: 12px;
        }
        .status-btn {
            position: relative;
            cursor: pointer;
            padding: 8px 16px;
            border-radius: var(--border-radius-sm);
            border: 1px solid var(--border-color);
            background-color: var(--bg-card);
            font-size: 13px;
            font-weight: 600;
            transition: all var(--transition-fast);
            user-select: none;
            display: flex;
            align-items: center;
            justify-content: center;
            min-width: 60px;
        }
        .status-radio {
            position: absolute;
            opacity: 0;
            width: 0;
            height: 0;
        }
        /* Status variations */
        .status-btn-present { color: var(--success); }
        .status-btn-absent { color: var(--danger); }
        .status-btn-late { color: var(--warning); }

        .status-radio:checked + .status-btn-present {
            background-color: var(--success);
            border-color: var(--success);
            color: white;
        }
        .status-radio:checked + .status-btn-absent {
            background-color: var(--danger);
            border-color: var(--danger);
            color: white;
        }
        .status-radio:checked + .status-btn-late {
            background-color: var(--warning);
            border-color: var(--warning);
            color: white;
        }
        .remarks-input {
            width: 100%;
            padding: 8px 12px;
            font-size: 13px;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            outline: none;
            transition: border-color var(--transition-fast);
        }
        .remarks-input:focus {
            border-color: var(--accent);
        }
        .student-meta {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .student-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background-color: var(--border-color);
            color: var(--text-secondary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="app-wrapper">
        <!-- Reusable Sidebar -->
        <%@ include file="teacher-sidebar.jsp" %>

        <div class="app-content-wrapper">
            <!-- Header bar layout -->
            <header class="app-header">
                <button class="sidebar-toggle-btn hamburger-btn" aria-label="Toggle Navigation">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                </button>
                <div class="header-title-area">
                    <h2>Record Attendance</h2>
                </div>
            </header>

            <main class="app-main-content animate-fade">
                <!-- Selection Form: Step 1 -->
                <div class="card step-container">
                    <div class="step-title">
                        <span class="step-number">1</span>
                        <span>Select Subject & Academic Session Details</span>
                    </div>

                    <form method="GET" action="mark-attendance.jsp" id="step1Form">
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; align-items: flex-end;">
                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Subject Allocation *</label>
                                <select name="subjectId" class="form-control" required onchange="document.getElementById('step1Form').submit();">
                                    <option value="">-- Choose Subject --</option>
                                    <% for (Subject s : subjects) { 
                                        ClassSection c = classDAO.getClassById(s.getClassId());
                                    %>
                                        <option value="<%= s.getId() %>" <%= selectedSubjectId == s.getId() ? "selected" : "" %>>
                                            <%= s.getCode() %> - <%= s.getName() %> (<%= c != null ? c.getName() : "Unassigned" %>)
                                        </option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Attendance Date *</label>
                                <input type="date" name="date" class="form-control" value="<%= selectedDate %>" required onchange="document.getElementById('step1Form').submit();">
                            </div>

                            <div class="form-group" style="margin-bottom: 0;">
                                <label class="form-label">Time Window Slot *</label>
                                <select name="slot" class="form-control" required>
                                    <option value="09:00 - 10:00 AM" <%= "09:00 - 10:00 AM".equals(selectedSlot) ? "selected" : "" %>>09:00 - 10:00 AM</option>
                                    <option value="10:30 - 11:30 AM" <%= "10:30 - 11:30 AM".equals(selectedSlot) ? "selected" : "" %>>10:30 - 11:30 AM</option>
                                    <option value="01:30 - 02:30 PM" <%= "01:30 - 02:30 PM".equals(selectedSlot) ? "selected" : "" %>>01:30 - 02:30 PM</option>
                                    <option value="03:00 - 04:00 PM" <%= "03:00 - 04:00 PM".equals(selectedSlot) ? "selected" : "" %>>03:00 - 04:00 PM</option>
                                </select>
                            </div>

                            <div>
                                <button type="submit" class="btn btn-primary" style="width: 100%;">Load Class list</button>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- Student List Form: Step 2 -->
                <% if (showStep2) { %>
                    <div class="card animate-fade">
                        <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 16px; margin-bottom: 20px; flex-wrap: wrap; gap: 12px;">
                            <div class="step-title" style="margin-bottom: 0;">
                                <span class="step-number">2</span>
                                <span>
                                    <%= isEditMode ? "Edit Existing Attendance Record" : "Mark Student Attendance status" %> 
                                    - <span style="font-weight: 500;"><%= selectedSubject.getName() %> (<%= selectedClass != null ? selectedClass.getName() : "" %>)</span>
                                </span>
                            </div>
                            <div style="display: flex; gap: 8px;">
                                <button type="button" class="btn btn-secondary" onclick="selectAllPresent()" style="padding: 8px 14px; font-size: 13px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px;">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                    Select All Present
                                </button>
                            </div>
                        </div>

                        <!-- Main Attendance Posting Form -->
                        <form method="POST" action="${pageContext.request.contextPath}/teacher/attendance" id="attendanceForm">
                            <input type="hidden" name="action" value="mark">
                            <input type="hidden" name="subjectId" value="<%= selectedSubjectId %>">
                            <input type="hidden" name="date" value="<%= selectedDate %>">
                            <input type="hidden" name="slot" id="postSlot" value="<%= selectedSlot %>">
                            <input type="hidden" name="isEdit" value="<%= isEditMode %>">
                            <input type="hidden" name="attendanceId" value="<%= attendanceId %>">

                            <div class="table-responsive" style="margin-bottom: 24px;">
                                <table class="table" id="attendanceTable" style="width: 100%;">
                                    <thead>
                                        <tr>
                                            <th style="width: 250px;">Student Information</th>
                                            <th style="width: 280px; text-align: center;">Status (P / A / L)</th>
                                            <th>Comments & Remarks</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (studentList.isEmpty()) { %>
                                            <tr>
                                                <td colspan="3" style="text-align: center; color: var(--text-secondary); padding: 30px 0;">
                                                    No students enrolled in this class section.
                                                </td>
                                            </tr>
                                        <% } else { 
                                            for (Map<String, Object> student : studentList) {
                                                int sId = (Integer) student.get("id");
                                                String status = (String) student.get("status");
                                                String remarks = (String) student.get("remarks");
                                                String initials = "";
                                                String name = (String) student.get("name");
                                                if (name != null && name.trim().length() > 0) {
                                                    String[] parts = name.split(" ");
                                                    if (parts.length > 0 && parts[0].length() > 0) initials += parts[0].charAt(0);
                                                    if (parts.length > 1 && parts[1].length() > 0) initials += parts[1].charAt(0);
                                                }
                                        %>
                                            <tr class="attendance-row">
                                                <td>
                                                    <input type="hidden" name="studentIds" value="<%= sId %>">
                                                    <div class="student-meta">
                                                        <div class="student-avatar"><%= initials.toUpperCase() %></div>
                                                        <div>
                                                            <div style="font-weight: 700; color: var(--primary);"><%= name %></div>
                                                            <div style="font-size: 11px; color: var(--text-secondary); margin-top: 2px;">Roll No: <%= student.get("rollNo") %></div>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td>
                                                    <div class="status-options" style="justify-content: center;">
                                                        <label>
                                                            <input type="radio" name="status_<%= sId %>" value="P" class="status-radio status-radio-p" <%= "P".equals(status) ? "checked" : "" %>>
                                                            <span class="status-btn status-btn-present">Present</span>
                                                        </label>
                                                        <label>
                                                            <input type="radio" name="status_<%= sId %>" value="A" class="status-radio status-radio-a" <%= "A".equals(status) ? "checked" : "" %>>
                                                            <span class="status-btn status-btn-absent">Absent</span>
                                                        </label>
                                                        <label>
                                                            <input type="radio" name="status_<%= sId %>" value="L" class="status-radio status-radio-l" <%= "L".equals(status) ? "checked" : "" %>>
                                                            <span class="status-btn status-btn-late">Late</span>
                                                        </label>
                                                    </div>
                                                </td>
                                                <td>
                                                    <input type="text" name="remarks_<%= sId %>" class="remarks-input" placeholder="Optional comments..." value="<%= remarks %>">
                                                </td>
                                            </tr>
                                        <% } 
                                        } %>
                                    </tbody>
                                </table>
                            </div>

                            <% if (!studentList.isEmpty()) { %>
                                <div style="display: flex; align-items: center; justify-content: flex-end; gap: 12px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                                    <a href="dashboard.jsp" class="btn btn-secondary">Cancel</a>
                                    <button type="submit" class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 8px;">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                        <%= isEditMode ? "Update Attendance" : "Submit Attendance" %>
                                    </button>
                                </div>
                            <% } %>
                        </form>
                    </div>
                <% } %>
            </main>
        </div>
    </div>

    <!-- Core Scripts -->
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
    <script>
        // Synchronize slot dropdown changes to the POST form action
        const step1Slot = document.querySelector('select[name="slot"]');
        const postSlot = document.getElementById('postSlot');
        if (step1Slot && postSlot) {
            step1Slot.addEventListener('change', () => {
                postSlot.value = step1Slot.value;
            });
        }

        // Sets all radio options to Present
        function selectAllPresent() {
            const pRadios = document.querySelectorAll('.status-radio-p');
            pRadios.forEach(radio => {
                radio.checked = true;
            });
            showToast("Set all students status to Present", "info");
        }

        // Trigger Success Toasts
        window.addEventListener("DOMContentLoaded", () => {
            const urlParams = new URLSearchParams(window.location.search);
            const status = urlParams.get("status");
            if (status === "success") {
                showToast("Attendance successfully saved!", "success");
            } else if (status === "failed") {
                showToast("Failed to save attendance details.", "danger");
            } else if (status === "error") {
                showToast("An unexpected error occurred while processing transaction.", "danger");
            } else if (urlParams.get("error") === "no_students") {
                showToast("Cannot submit attendance: Class has no registered students.", "warning");
            }
        });
    </script>
</body>
</html>
