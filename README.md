# Attendance Management System

A production-ready, feature-rich Attendance Management System built on a modern Java EE (Servlets/JSPs), Maven, and MySQL stack. Designed for educational institutions to manage administrative configurations, faculty mappings, student cohorts, daily attendance tracking, and comprehensive report generation.

---

## 🌟 Key Features & Phase 6 Enhancements
- **Centralized Admin Dashboard:** Comprehensive CRUD administration for Students, Teachers, Subjects, and Class Cohorts.
- **Teacher Attendance Workspace:** Daily attendance logging and history tracking by subject/class slot.
- **Student Profile Hub:** Attendance percentage lookup and progress reviews.
- **Reporting Engine:** Generate student attendance profiles and export reports to CSV.
- **Phase 6 Polish:**
  - **Aesthetic Dark Mode:** Automatic user-agent interface adjustment via media queries matching system preferences.
  - **Production-grade Form Validation:** Standardized client-side checking (`validateRequired`, `validateEmail`, `validatePhone`, `validateRollNo`, `validateDate`).
  - **Security Audits & Exception Hardening:** Integrated a centralized `ErrorHandler` wrapper returning robust `Result<T>` envelopes; prevents database errors from leaking stack traces.
  - **Relational Business Safeguards:** Prevent deleting records with dependent entries (e.g., student/teacher with recorded attendance, class with enrolled students).
  - **Session Warning Timeout:** Integrates a warning modal at 28 minutes to prompt actions before the strict 30-minute Tomcat session termination.
  - **Print Stylesheets:** Configured `@media print` directives to hide navigation headers and action buttons, leaving clean tables for physical print/PDF conversion.

---

## 🛠️ System Prerequisites
- **Java JDK 11 or 21**
- **Apache Tomcat 9.x+**
- **MySQL Server 8.0+**
- **Apache Maven 3.6+**

---

## 📂 Project Directory Structure

```text
attendance-management-system/
├── pom.xml                           # Maven dependencies and build definitions
├── attendance_db.sql                 # SQL schema and seed data
└── src/
    └── main/
        ├── java/
        │   └── com/
        │       └── ams/
        │           ├── dao/          # Database persistence classes (DAO Pattern)
        │           │   ├── AttendanceDAO.java
        │           │   ├── ClassDAO.java
        │           │   ├── StudentDAO.java
        │           │   ├── SubjectDAO.java
        │           │   └── UserDAO.java
        │           ├── database/     # DB Connection Pool Management
        │           │   └── DBConnection.java
        │           ├── model/        # Data Entity models (POJOs)
        │           │   ├── Attendance.java
        │           │   ├── AttendanceDetail.java
        │           │   ├── ClassSection.java
        │           │   ├── Student.java
        │           │   ├── Subject.java
        │           │   └── User.java
        │           ├── servlet/      # Web controller servlets (MVC Pattern)
        │           │   ├── AttendanceServlet.java
        │           │   ├── ClassServlet.java
        │           │   ├── LoginServlet.java
        │           │   ├── LogoutServlet.java
        │           │   ├── ReportServlet.java
        │           │   ├── SessionFilter.java
        │           │   ├── StudentServlet.java
        │           │   └── TeacherServlet.java
        │           └── util/         # Logging and centralized handling utilities
        │               ├── ErrorHandler.java
        │               └── Result.java
        └── webapp/                   # HTML/JSP views, stylesheets, and scripts
            ├── WEB-INF/
            │   └── web-app.xml       # Session filters and timeouts configuration
            ├── css/
            │   └── style.css         # Styling system, print rules, and dark mode
            ├── js/
            │   └── main.js          # Forms validation and session warnings
            ├── admin/                # Admin Panel pages
            ├── teacher/              # Faculty Workspaces
            ├── student/              # Student Portals
            ├── login.jsp
            └── error.jsp             # Centralized User-friendly Error Page
```

---

## 💾 Database Setup & Initialization

1. Log into your local MySQL server:
   ```bash
   mysql -u root -p
   ```
2. Create the target schema database:
   ```sql
   CREATE DATABASE IF NOT EXISTS attendance_db;
   ```
3. Initialize the database schema and populate seed accounts using the provided SQL script:
   ```bash
   mysql -u root -p attendance_db < attendance_db.sql
   ```

---

## 🏗️ Maven Build & Packaging

Build the production-ready Web Application Archive (`WAR`):
1. Navigate to the project root directory:
   ```bash
   cd attendance-management-system
   ```
2. Build and package using Maven:
   ```bash
   mvn clean package
   ```
3. Upon compilation success, the packaged archive will be generated at:
   `target/attendance-management-system.war`

---

## 🚢 Apache Tomcat Deployment

### Option 1: Manual Deployment (Tomcat `webapps`)
1. Copy the packaged `attendance-management-system.war` archive from the `target/` directory.
2. Paste it directly into your Tomcat server's deployment subdirectory:
   `/path/to/tomcat/webapps/`
3. Launch/restart the Tomcat server:
   - On Linux/macOS: `./path/to/tomcat/bin/startup.sh`
   - On Windows: `.\path\to\tomcat\bin\startup.bat`
4. Tomcat will automatically extract the war directory and mount the application.

### Option 2: IDE Deployment (IntelliJ IDEA / Eclipse)
1. Open the project root folder as a Maven project.
2. Configure a new run configuration pointing to a local Apache Tomcat Server.
3. In the deployment settings tab, select `attendance-management-system:war exploded` as the deploy artifact.
4. Run/Debug the configuration.

---

## 🌐 Local Access & Credentials

Once Tomcat is started, access the application login page using your browser:
```text
http://localhost:8080/attendance-management-system/
```

### Seed Accounts / Credentials for Testing:
Use the following accounts pre-seeded in the database to test different roles:

| Role | Username | Password |
| :--- | :--- | :--- |
| **System Administrator** | `admin` | `admin123` |
| **Teacher / Faculty** | `teacher1` | `teacher123` |
| **Student** | `student1` | `student123` |
