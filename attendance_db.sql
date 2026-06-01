-- ============================================================================
-- COLLEGE ATTENDANCE MANAGEMENT SYSTEM DATABASE
-- Phase 1 - Complete Database Script
-- File: attendance_db.sql
-- ============================================================================

CREATE DATABASE IF NOT EXISTS attendance_db;
USE attendance_db;

-- ----------------------------------------------------------------------------
-- 1. Table: users
-- Purpose: Holds central credential and profile metadata for all system users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each user account',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique alphanumeric username used for system login',
    password VARCHAR(255) NOT NULL COMMENT 'Securely hashed password string',
    role ENUM('ADMIN', 'TEACHER', 'STUDENT') NOT NULL COMMENT 'System authorization role determining portal access',
    email VARCHAR(100) NOT NULL UNIQUE COMMENT 'Primary contact email address for communication',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Audit trail record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Audit trail last modification timestamp',
    INDEX idx_username (username),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores user login credentials, authentication info, and roles';

-- ----------------------------------------------------------------------------
-- 2. Table: teachers
-- Purpose: Holds professor profile metrics and department assignments
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each teacher',
    user_id INT NOT NULL UNIQUE COMMENT 'Foreign key link to core users table account details',
    first_name VARCHAR(50) NOT NULL COMMENT 'First name of the teacher',
    last_name VARCHAR(50) NOT NULL COMMENT 'Last name of the teacher',
    phone VARCHAR(20) DEFAULT NULL COMMENT 'Contact phone number of the teacher',
    department VARCHAR(100) NOT NULL COMMENT 'Department division associated with the teacher (e.g. Computer Science)',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_teacher_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores details of teaching staff mapped to their user credentials';

-- ----------------------------------------------------------------------------
-- 3. Table: classes
-- Purpose: Declares specific cohort bands and sections
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each class cohort',
    class_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Readable name of the class section (e.g. CS - Year 1, Semester 1)',
    semester VARCHAR(20) NOT NULL COMMENT 'Current active semester description (e.g. Semester 1, Semester 3)',
    academic_year VARCHAR(20) NOT NULL COMMENT 'Academic calendar year representation (e.g. 2026-2027)',
    INDEX idx_class_name (class_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores different class sections or student batches';

-- ----------------------------------------------------------------------------
-- 4. Table: students
-- Purpose: Captures student details, linking them to users and specific classes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    student_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each student',
    user_id INT NOT NULL UNIQUE COMMENT 'Foreign key link to core users table account details',
    class_id INT DEFAULT NULL COMMENT 'Foreign key link to class section currently enrolled in',
    first_name VARCHAR(50) NOT NULL COMMENT 'First name of the student',
    last_name VARCHAR(50) NOT NULL COMMENT 'Last name of the student',
    roll_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'University-issued unique roll number for student identity verification',
    phone VARCHAR(20) DEFAULT NULL COMMENT 'Contact phone number of the student',
    date_of_birth DATE DEFAULT NULL COMMENT 'Birth date of the student for verification',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE SET NULL,
    INDEX idx_student_name (first_name, last_name),
    INDEX idx_roll_number (roll_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores details of students, their class section, and user accounts';

-- ----------------------------------------------------------------------------
-- 5. Table: subjects
-- Purpose: Declares college subjects and links them to classes and lecturers
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each subject',
    subject_code VARCHAR(20) NOT NULL UNIQUE COMMENT 'Official course catalog code (e.g. CS101, IT301)',
    subject_name VARCHAR(100) NOT NULL COMMENT 'Descriptive title of the subject (e.g. Introduction to Programming)',
    teacher_id INT DEFAULT NULL COMMENT 'Foreign key referencing teacher assigned to teach this subject',
    class_id INT NOT NULL COMMENT 'Foreign key referencing target class cohort for this subject',
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE SET NULL,
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE,
    INDEX idx_subject_code (subject_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores subject details, mapping them to class and assigned teacher';

-- ----------------------------------------------------------------------------
-- 6. Table: attendance
-- Purpose: Captures details of recorded class sessions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each recorded attendance session',
    class_id INT NOT NULL COMMENT 'Foreign key referencing class section session was recorded for',
    subject_id INT NOT NULL COMMENT 'Foreign key referencing subject being taught during session',
    teacher_id INT NOT NULL COMMENT 'Foreign key referencing teacher who took the attendance',
    attendance_date DATE NOT NULL COMMENT 'Calendar date the session took place',
    slot VARCHAR(50) NOT NULL COMMENT 'Time window of lecture session (e.g. 09:00 - 10:00 AM)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Log entry recording time',
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    INDEX idx_attendance_date (attendance_date),
    INDEX idx_attendance_lookup (class_id, subject_id, attendance_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores session master info for recorded attendance lectures';

-- ----------------------------------------------------------------------------
-- 7. Table: attendance_details
-- Purpose: Holds daily attendance statuses of individual students per session
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance_details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each student entry in a session',
    attendance_id INT NOT NULL COMMENT 'Foreign key reference to master session attendance log',
    student_id INT NOT NULL COMMENT 'Foreign key reference to student being graded',
    status ENUM('PRESENT', 'ABSENT', 'LATE', 'EXCUSED') NOT NULL COMMENT 'Individual attendance status selection',
    remarks VARCHAR(255) DEFAULT NULL COMMENT 'Optional notes regarding absence or excuse reasons',
    FOREIGN KEY (attendance_id) REFERENCES attendance(attendance_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    UNIQUE KEY uq_attendance_student (attendance_id, student_id),
    INDEX idx_student_attendance (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores status of individual students for each attendance session';


-- ============================================================================
-- SAMPLE DATA INSERTIONS
-- Includes: 1 Admin, 3 Teachers, 10 Students, 3 Classes, 5 Subjects, 2 Weeks Logs
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Insert Users
-- Roles: ADMIN, TEACHER, STUDENT
-- Password is set to a placeholder string (e.g. "password" in a production system these would be hashed)
-- ----------------------------------------------------------------------------
INSERT INTO users (user_id, username, password, role, email) VALUES
(1, 'admin', 'admin123', 'ADMIN', 'admin@ams.edu'),
(2, 'aturing', 'teacher123', 'TEACHER', 'a.turing@ams.edu'),
(3, 'ghopper', 'teacher123', 'TEACHER', 'g.hopper@ams.edu'),
(4, 'rfeynman', 'teacher123', 'TEACHER', 'r.feynman@ams.edu'),
(5, 'asmith', 'student123', 'STUDENT', 'alice.smith@ams.edu'),
(6, 'bjones', 'student123', 'STUDENT', 'bob.jones@ams.edu'),
(7, 'cbrown', 'student123', 'STUDENT', 'charlie.brown@ams.edu'),
(8, 'dmiller', 'student123', 'STUDENT', 'david.miller@ams.edu'),
(9, 'egreen', 'student123', 'STUDENT', 'eva.green@ams.edu'),
(10, 'fharris', 'student123', 'STUDENT', 'frank.harris@ams.edu'),
(11, 'gdavis', 'student123', 'STUDENT', 'grace.davis@ams.edu'),
(12, 'hwilson', 'student123', 'STUDENT', 'henry.wilson@ams.edu'),
(13, 'ithomas', 'student123', 'STUDENT', 'ivy.thomas@ams.edu'),
(14, 'jwhite', 'student123', 'STUDENT', 'jack.white@ams.edu');

-- ----------------------------------------------------------------------------
-- Insert Teacher Profiles
-- ----------------------------------------------------------------------------
INSERT INTO teachers (teacher_id, user_id, first_name, last_name, phone, department) VALUES
(1, 2, 'Alan', 'Turing', '+15550101', 'Computer Science'),
(2, 3, 'Grace', 'Hopper', '+15550102', 'Information Technology'),
(3, 4, 'Richard', 'Feynman', '+15550103', 'Electronics & Comm');

-- ----------------------------------------------------------------------------
-- Insert Class Cohorts
-- ----------------------------------------------------------------------------
INSERT INTO classes (class_id, class_name, semester, academic_year) VALUES
(1, 'Computer Science - Year 1', 'Semester 1', '2026-2027'),
(2, 'Information Technology - Year 2', 'Semester 3', '2026-2027'),
(3, 'Electronics & Comm - Year 3', 'Semester 5', '2026-2027');

-- ----------------------------------------------------------------------------
-- Insert Student Profiles
-- ----------------------------------------------------------------------------
INSERT INTO students (student_id, user_id, class_id, first_name, last_name, roll_number, phone, date_of_birth) VALUES
-- CS - Year 1 Students
(1, 5, 1, 'Alice', 'Smith', 'CS2601', '+15550201', '2008-05-15'),
(2, 6, 1, 'Bob', 'Jones', 'CS2602', '+15550202', '2008-09-22'),
(3, 7, 1, 'Charlie', 'Brown', 'CS2603', '+15550203', '2008-11-05'),
(4, 8, 1, 'David', 'Miller', 'CS2604', '+15550204', '2008-01-30'),
(5, 9, 1, 'Eva', 'Green', 'CS2605', '+15550205', '2008-04-12'),
-- IT - Year 2 Students
(6, 10, 2, 'Frank', 'Harris', 'IT2501', '+15550301', '2007-06-18'),
(7, 11, 2, 'Grace', 'Davis', 'IT2502', '+15550302', '2007-02-25'),
(8, 12, 2, 'Henry', 'Wilson', 'IT2503', '+15550303', '2007-10-14'),
-- Electronics - Year 3 Students
(9, 13, 3, 'Ivy', 'Thomas', 'ECE2401', '+15550401', '2006-03-08'),
(10, 14, 3, 'Jack', 'White', 'ECE2402', '+15550402', '2006-07-19');

-- ----------------------------------------------------------------------------
-- Insert Course Subjects
-- ----------------------------------------------------------------------------
INSERT INTO subjects (subject_id, subject_code, subject_name, teacher_id, class_id) VALUES
(1, 'CS101', 'Introduction to Programming', 1, 1),
(2, 'CS102', 'Data Structures & Algorithms', 1, 1),
(3, 'IT301', 'Database Management Systems', 2, 2),
(4, 'IT302', 'Computer Networks', 2, 2),
(5, 'ECE501', 'Digital Electronics', 3, 3);

-- ----------------------------------------------------------------------------
-- Insert 2 Weeks of Attendance Session Masters
-- Week 1: 2026-05-18 to 2026-05-22
-- Week 2: 2026-05-25 to 2026-05-29
-- ----------------------------------------------------------------------------
INSERT INTO attendance (attendance_id, class_id, subject_id, teacher_id, attendance_date, slot) VALUES
-- Week 1
(1, 1, 1, 1, '2026-05-18', '09:00 - 10:00 AM'),  -- CS Year 1 (Prog)
(2, 2, 3, 2, '2026-05-18', '10:30 - 11:30 AM'),  -- IT Year 2 (DB)
(3, 3, 5, 3, '2026-05-18', '01:30 - 02:30 PM'),  -- ECE Year 3 (Digital)
(4, 1, 2, 1, '2026-05-20', '09:00 - 10:00 AM'),  -- CS Year 1 (DataStr)
(5, 2, 4, 2, '2026-05-20', '10:30 - 11:30 AM'),  -- IT Year 2 (Net)
(6, 1, 1, 1, '2026-05-22', '09:00 - 10:00 AM'),  -- CS Year 1 (Prog)
(7, 3, 5, 3, '2026-05-22', '01:30 - 02:30 PM'),  -- ECE Year 3 (Digital)
-- Week 2
(8, 1, 1, 1, '2026-05-25', '09:00 - 10:00 AM'),  -- CS Year 1 (Prog)
(9, 2, 3, 2, '2026-05-25', '10:30 - 11:30 AM'),  -- IT Year 2 (DB)
(10, 3, 5, 3, '2026-05-25', '01:30 - 02:30 PM'), -- ECE Year 3 (Digital)
(11, 1, 2, 1, '2026-05-27', '09:00 - 10:00 AM'), -- CS Year 1 (DataStr)
(12, 2, 4, 2, '2026-05-27', '10:30 - 11:30 AM'), -- IT Year 2 (Net)
(13, 1, 1, 1, '2026-05-29', '09:00 - 10:00 AM'), -- CS Year 1 (Prog)
(14, 3, 5, 3, '2026-05-29', '01:30 - 02:30 PM'); -- ECE Year 3 (Digital)

-- ----------------------------------------------------------------------------
-- Insert Attendance Details (Grades)
-- Mapping all enrolled students to each class attendance session
-- ----------------------------------------------------------------------------
INSERT INTO attendance_details (attendance_id, student_id, status, remarks) VALUES
-- ==================== WEEK 1 ====================
-- Session 1 (CS Year 1 - CS101 - 2026-05-18)
(1, 1, 'PRESENT', NULL),
(1, 2, 'PRESENT', NULL),
(1, 3, 'ABSENT', 'Unexcused'),
(1, 4, 'PRESENT', NULL),
(1, 5, 'LATE', 'Traffic delay'),

-- Session 2 (IT Year 2 - IT301 - 2026-05-18)
(2, 6, 'PRESENT', NULL),
(2, 7, 'PRESENT', NULL),
(2, 8, 'ABSENT', 'Sick leave'),

-- Session 3 (ECE Year 3 - ECE501 - 2026-05-18)
(3, 9, 'PRESENT', NULL),
(3, 10, 'PRESENT', NULL),

-- Session 4 (CS Year 1 - CS102 - 2026-05-20)
(4, 1, 'PRESENT', NULL),
(4, 2, 'PRESENT', NULL),
(4, 3, 'PRESENT', NULL),
(4, 4, 'ABSENT', 'No show'),
(4, 5, 'PRESENT', NULL),

-- Session 5 (IT Year 2 - IT302 - 2026-05-20)
(5, 6, 'PRESENT', NULL),
(5, 7, 'LATE', NULL),
(5, 8, 'PRESENT', NULL),

-- Session 6 (CS Year 1 - CS101 - 2026-05-22)
(6, 1, 'PRESENT', NULL),
(6, 2, 'ABSENT', 'Family event'),
(6, 3, 'PRESENT', NULL),
(6, 4, 'PRESENT', NULL),
(6, 5, 'PRESENT', NULL),

-- Session 7 (ECE Year 3 - ECE501 - 2026-05-22)
(7, 9, 'PRESENT', NULL),
(7, 10, 'EXCUSED', 'Representing college in sports tournament'),

-- ==================== WEEK 2 ====================
-- Session 8 (CS Year 1 - CS101 - 2026-05-25)
(8, 1, 'PRESENT', NULL),
(8, 2, 'PRESENT', NULL),
(8, 3, 'PRESENT', NULL),
(8, 4, 'PRESENT', NULL),
(8, 5, 'PRESENT', NULL),

-- Session 9 (IT Year 2 - IT301 - 2026-05-25)
(9, 6, 'PRESENT', NULL),
(9, 7, 'PRESENT', NULL),
(9, 8, 'PRESENT', NULL),

-- Session 10 (ECE Year 3 - ECE501 - 2026-05-25)
(10, 9, 'PRESENT', NULL),
(10, 10, 'PRESENT', NULL),

-- Session 11 (CS Year 1 - CS102 - 2026-05-27)
(11, 1, 'PRESENT', NULL),
(11, 2, 'LATE', NULL),
(11, 3, 'PRESENT', NULL),
(11, 4, 'PRESENT', NULL),
(11, 5, 'ABSENT', 'Medical appointment'),

-- Session 12 (IT Year 2 - IT302 - 2026-05-27)
(12, 6, 'PRESENT', NULL),
(12, 7, 'ABSENT', 'Overslept'),
(12, 8, 'PRESENT', NULL),

-- Session 13 (CS Year 1 - CS101 - 2026-05-29)
(13, 1, 'PRESENT', NULL),
(13, 2, 'PRESENT', NULL),
(13, 3, 'PRESENT', NULL),
(13, 4, 'PRESENT', NULL),
(13, 5, 'PRESENT', NULL),

-- Session 14 (ECE Year 3 - ECE501 - 2026-05-29)
(14, 9, 'PRESENT', NULL),
(14, 10, 'PRESENT', NULL);
