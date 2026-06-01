package com.ams.dao;

import com.ams.model.Student;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * StudentDAO.java
 * Purpose: Manages all database operations for students profiles and maps
 * data updates across 'students' and joined 'users' tables.
 */
public class StudentDAO {

    /**
     * Retrieves all students enrolled in the system.
     * 
     * SQL Query: SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id
     * Explanation: Performs an INNER JOIN between students and users on user_id 
     * to extract student details along with their central account email.
     * 
     * @return A List of Student objects.
     */
    public List<Student> getAllStudents() {
        List<Student> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractStudentFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Error in getAllStudents: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves a single student by their unique student ID.
     * 
     * SQL Query: SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id WHERE s.student_id = ?
     * Explanation: Queries the students-users joined result set by the student_id primary key.
     * 
     * @param studentId The unique student ID.
     * @return The Student object if found, or null otherwise.
     */
    public Student getStudentById(int studentId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Student student = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id WHERE s.student_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            rs = ps.executeQuery();

            if (rs.next()) {
                student = extractStudentFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Error in getStudentById: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return student;
    }

    /**
     * Retrieves all students belonging to a specific class cohort.
     * 
     * SQL Query: SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id WHERE s.class_id = ?
     * Explanation: Performs an inner join and filters student rows by class_id parameter.
     * 
     * @param classId The unique class ID.
     * @return A List of Student objects matching the class selection.
     */
    public List<Student> getStudentsByClass(int classId) {
        List<Student> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id WHERE s.class_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, classId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractStudentFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Error in getStudentsByClass: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Adds a new student to the system. Handles database transactions to insert
     * corresponding records into both 'users' and 'students' tables.
     * 
     * SQL Query 1: INSERT INTO users (username, password, role, email) VALUES (?, ?, 'STUDENT', ?)
     * SQL Query 2: INSERT INTO students (user_id, class_id, first_name, last_name, roll_number, phone, date_of_birth) VALUES (?, ?, ?, ?, ?, ?, ?)
     * 
     * Explanation: First creates the user authentication row. Retrieves the newly created 
     * primary auto-incremented key (user_id), then inserts the student profile utilizing that user_id.
     * 
     * @param student The Student JavaBean profile to insert.
     * @return True if insertion succeeds in both tables, false otherwise.
     */
    public boolean addStudent(Student student) {
        Connection conn = null;
        PreparedStatement psUser = null;
        PreparedStatement psStudent = null;
        ResultSet rsKey = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false); // Enable manual transaction controls

            // 1. Insert into users table
            String sqlUser = "INSERT INTO users (username, password, role, email) VALUES (?, ?, 'STUDENT', ?)";
            psUser = conn.prepareStatement(sqlUser, Statement.RETURN_GENERATED_KEYS);
            // Default username is set to lowercased roll number
            psUser.setString(1, student.getRollNo().toLowerCase());
            // Default password is set to a standard default
            psUser.setString(2, "student123");
            psUser.setString(3, student.getEmail());
            psUser.executeUpdate();

            rsKey = psUser.getGeneratedKeys();
            int userId = -1;
            if (rsKey.next()) {
                userId = rsKey.getInt(1);
            } else {
                throw new SQLException("Failed to retrieve generated user_id for student.");
            }

            // 2. Insert into students table using generated user_id
            String sqlStudent = "INSERT INTO students (user_id, class_id, first_name, last_name, roll_number, phone, date_of_birth) VALUES (?, ?, ?, ?, ?, ?, ?)";
            psStudent = conn.prepareStatement(sqlStudent);
            psStudent.setInt(1, userId);
            
            if (student.getClassId() > 0) {
                psStudent.setInt(2, student.getClassId());
            } else {
                psStudent.setNull(2, java.sql.Types.INTEGER);
            }
            
            psStudent.setString(3, student.getFirstName());
            psStudent.setString(4, student.getLastName());
            psStudent.setString(5, student.getRollNo());
            psStudent.setString(6, student.getPhone());
            psStudent.setDate(7, student.getDateOfBirth());
            psStudent.executeUpdate();

            conn.commit(); // Commit transaction
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Transaction error in addStudent: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback(); // Rollback transaction on failure
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rsKey);
            DBConnection.closeStatement(psUser);
            DBConnection.closeStatement(psStudent);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Updates an existing student profile. Updates both 'students' and joined 'users' tables.
     * 
     * SQL Query 1: UPDATE students SET first_name = ?, last_name = ?, class_id = ?, roll_number = ?, phone = ?, date_of_birth = ? WHERE student_id = ?
     * SQL Query 2: UPDATE users SET email = ? WHERE user_id = ?
     * 
     * Explanation: Modifies core student details in 'students' and uses the student's 
     * user_id key to update the centralized 'users' table contact email.
     * 
     * @param student The Student JavaBean profile containing modified fields.
     * @return True if update succeeds on both tables, false otherwise.
     */
    public boolean updateStudent(Student student) {
        Connection conn = null;
        PreparedStatement psStudent = null;
        PreparedStatement psUser = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false); // Enable manual transaction controls

            // 1. Update students table details
            String sqlStudent = "UPDATE students SET first_name = ?, last_name = ?, class_id = ?, roll_number = ?, phone = ?, date_of_birth = ? WHERE student_id = ?";
            psStudent = conn.prepareStatement(sqlStudent);
            psStudent.setString(1, student.getFirstName());
            psStudent.setString(2, student.getLastName());
            
            if (student.getClassId() > 0) {
                psStudent.setInt(3, student.getClassId());
            } else {
                psStudent.setNull(3, java.sql.Types.INTEGER);
            }
            
            psStudent.setString(4, student.getRollNo());
            psStudent.setString(5, student.getPhone());
            psStudent.setDate(6, student.getDateOfBirth());
            psStudent.setInt(7, student.getId());
            psStudent.executeUpdate();

            // 2. Update email in users table
            String sqlUser = "UPDATE users SET email = ? WHERE user_id = ?";
            psUser = conn.prepareStatement(sqlUser);
            psUser.setString(1, student.getEmail());
            psUser.setInt(2, student.getUserId());
            psUser.executeUpdate();

            conn.commit(); // Commit transaction
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Transaction error in updateStudent: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback(); // Rollback transaction on failure
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(psStudent);
            DBConnection.closeStatement(psUser);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Deletes a student from the database by deleting their parent User row.
     * 
     * SQL Query 1: SELECT user_id FROM students WHERE student_id = ?
     * SQL Query 2: DELETE FROM users WHERE user_id = ?
     * 
     * Explanation: Cascading foreign keys are configured in Phase 1 database schema:
     * "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE"
     * Therefore, deleting the parent User account automatically cascade-removes 
     * the matching row from 'students'.
     * 
     * @param studentId The unique student ID to delete.
     * @return True if deletion succeeds, false otherwise.
     */
    public boolean deleteStudent(int studentId) {
        Connection conn = null;
        PreparedStatement psGetUserId = null;
        PreparedStatement psDeleteUser = null;
        ResultSet rs = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false);

            // 1. Fetch user_id for cascade target
            String sqlGetUserId = "SELECT user_id FROM students WHERE student_id = ?";
            psGetUserId = conn.prepareStatement(sqlGetUserId);
            psGetUserId.setInt(1, studentId);
            rs = psGetUserId.executeQuery();

            int userId = -1;
            if (rs.next()) {
                userId = rs.getInt("user_id");
            }

            // 2. Delete parent user row (initiating cascade deletion)
            if (userId != -1) {
                String sqlDeleteUser = "DELETE FROM users WHERE user_id = ?";
                psDeleteUser = conn.prepareStatement(sqlDeleteUser);
                psDeleteUser.setInt(1, userId);
                psDeleteUser.executeUpdate();
                conn.commit();
                success = true;
            }
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Transaction error in deleteStudent: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(psGetUserId);
            DBConnection.closeStatement(psDeleteUser);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Searches students based on a name or roll number keyword.
     * 
     * SQL Query: SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id WHERE s.first_name LIKE ? OR s.last_name LIKE ? OR s.roll_number LIKE ?
     * Explanation: Joins students-users and matches first_name, last_name, or roll_number using wildcard matching.
     * 
     * @param keyword The search pattern.
     * @return A List of Student objects matching the criteria.
     */
    public List<Student> searchStudents(String keyword) {
        List<Student> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT s.*, u.email FROM students s JOIN users u ON s.user_id = u.user_id " +
                         "WHERE s.first_name LIKE ? OR s.last_name LIKE ? OR s.roll_number LIKE ?";
            ps = conn.prepareStatement(sql);
            String searchPattern = "%" + keyword + "%";
            ps.setString(1, searchPattern);
            ps.setString(2, searchPattern);
            ps.setString(3, searchPattern);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractStudentFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS StudentDAO] Error in searchStudents: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Standard helper method to translate a ResultSet row into a Student JavaBean.
     */
    private Student extractStudentFromResultSet(ResultSet rs) throws SQLException {
        Student student = new Student();
        student.setId(rs.getInt("student_id"));
        student.setUserId(rs.getInt("user_id"));
        student.setClassId(rs.getInt("class_id"));
        student.setFirstName(rs.getString("first_name"));
        student.setLastName(rs.getString("last_name"));
        student.setRollNo(rs.getString("roll_number"));
        student.setPhone(rs.getString("phone"));
        student.setDateOfBirth(rs.getDate("date_of_birth"));
        student.setEmail(rs.getString("email")); // Populated from joined user row
        student.setAddress(null); // Optional field, defaults to null
        student.setPhoto(null);   // Optional field, defaults to null
        return student;
    }
}
