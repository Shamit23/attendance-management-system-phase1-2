package com.ams.dao;

import com.ams.model.Teacher;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * TeacherDAO.java
 * Purpose: Manages database CRUD actions for teachers profiles, joining email and 
 * authorization credentials across the central 'users' and 'teachers' tables.
 */
public class TeacherDAO {

    /**
     * Retrieves all teachers stored in the system.
     * 
     * SQL Query: SELECT t.*, u.email FROM teachers t JOIN users u ON t.user_id = u.user_id
     * Explanation: Joins teachers and users tables on user_id to select all teachers 
     * along with their corresponding profile contact email.
     * 
     * @return A List of Teacher objects.
     */
    public List<Teacher> getAllTeachers() {
        List<Teacher> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT t.*, u.email FROM teachers t JOIN users u ON t.user_id = u.user_id";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractTeacherFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS TeacherDAO] Error in getAllTeachers: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves a teacher profile by their unique teacher ID.
     * 
     * SQL Query: SELECT t.*, u.email FROM teachers t JOIN users u ON t.user_id = u.user_id WHERE t.teacher_id = ?
     * Explanation: Filters the teachers-users inner joined result set by the teacher_id primary key.
     * 
     * @param teacherId The unique teacher ID.
     * @return The Teacher object if found, or null otherwise.
     */
    public Teacher getTeacherById(int teacherId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Teacher teacher = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT t.*, u.email FROM teachers t JOIN users u ON t.user_id = u.user_id WHERE t.teacher_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, teacherId);
            rs = ps.executeQuery();

            if (rs.next()) {
                teacher = extractTeacherFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS TeacherDAO] Error in getTeacherById: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return teacher;
    }

    /**
     * Adds a new teacher to the system. Handles database transactions to insert
     * corresponding records into both 'users' and 'teachers' tables.
     * 
     * SQL Query 1: INSERT INTO users (username, password, role, email) VALUES (?, ?, 'TEACHER', ?)
     * SQL Query 2: INSERT INTO teachers (user_id, first_name, last_name, phone, department) VALUES (?, ?, ?, ?, ?)
     * 
     * Explanation: Creates the security credential record in users first, fetches the newly 
     * generated user_id, and then writes the profile record using model properties.
     * 
     * @param teacher The Teacher JavaBean profile to insert.
     * @return True if insertion succeeds in both tables, false otherwise.
     */
    public boolean addTeacher(Teacher teacher) {
        Connection conn = null;
        PreparedStatement psUser = null;
        PreparedStatement psTeacher = null;
        ResultSet rsKey = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false); // Enable manual transaction controls

            // 1. Insert into users table
            String sqlUser = "INSERT INTO users (username, password, role, email) VALUES (?, ?, 'TEACHER', ?)";
            psUser = conn.prepareStatement(sqlUser, Statement.RETURN_GENERATED_KEYS);
            // Default username generated based on first initial + last name
            String baseUsername = (teacher.getFirstName().charAt(0) + teacher.getLastName()).toLowerCase().replaceAll("\\s+", "");
            psUser.setString(1, baseUsername);
            psUser.setString(2, "teacher123"); // Default password
            psUser.setString(3, teacher.getEmail());
            psUser.executeUpdate();

            rsKey = psUser.getGeneratedKeys();
            int userId = -1;
            if (rsKey.next()) {
                userId = rsKey.getInt(1);
            } else {
                throw new SQLException("Failed to retrieve generated user_id for teacher.");
            }

            // 2. Insert into teachers table using generated user_id
            String sqlTeacher = "INSERT INTO teachers (user_id, first_name, last_name, phone, department) VALUES (?, ?, ?, ?, ?)";
            psTeacher = conn.prepareStatement(sqlTeacher);
            psTeacher.setInt(1, userId);
            psTeacher.setString(2, teacher.getFirstName());
            psTeacher.setString(3, teacher.getLastName());
            psTeacher.setString(4, teacher.getPhone());
            psTeacher.setString(5, teacher.getSpecialization()); // specialization maps to department
            psTeacher.executeUpdate();

            conn.commit(); // Commit transaction
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS TeacherDAO] Transaction error in addTeacher: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rsKey);
            DBConnection.closeStatement(psUser);
            DBConnection.closeStatement(psTeacher);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Updates an existing teacher profile. Updates both 'teachers' and joined 'users' tables.
     * 
     * SQL Query 1: UPDATE teachers SET first_name = ?, last_name = ?, phone = ?, department = ? WHERE teacher_id = ?
     * SQL Query 2: UPDATE users SET email = ? WHERE user_id = ?
     * 
     * Explanation: Modifies teacher name, phone, and department (specialization) in 'teachers' table,
     * and updates the associated contact email in the central 'users' table.
     * 
     * @param teacher The Teacher JavaBean profile containing modified fields.
     * @return True if update succeeds on both tables, false otherwise.
     */
    public boolean updateTeacher(Teacher teacher) {
        Connection conn = null;
        PreparedStatement psTeacher = null;
        PreparedStatement psUser = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false); // Enable manual transaction controls

            // 1. Update teachers table
            String sqlTeacher = "UPDATE teachers SET first_name = ?, last_name = ?, phone = ?, department = ? WHERE teacher_id = ?";
            psTeacher = conn.prepareStatement(sqlTeacher);
            psTeacher.setString(1, teacher.getFirstName());
            psTeacher.setString(2, teacher.getLastName());
            psTeacher.setString(3, teacher.getPhone());
            psTeacher.setString(4, teacher.getSpecialization()); // specialization maps to department
            psTeacher.setInt(5, teacher.getId());
            psTeacher.executeUpdate();

            // 2. Update users table email
            String sqlUser = "UPDATE users SET email = ? WHERE user_id = ?";
            psUser = conn.prepareStatement(sqlUser);
            psUser.setString(1, teacher.getEmail());
            psUser.setInt(2, teacher.getUserId());
            psUser.executeUpdate();

            conn.commit(); // Commit transaction
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS TeacherDAO] Transaction error in updateTeacher: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(psTeacher);
            DBConnection.closeStatement(psUser);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Deletes a teacher from the database by deleting their parent User row.
     * 
     * SQL Query 1: SELECT user_id FROM teachers WHERE teacher_id = ?
     * SQL Query 2: DELETE FROM users WHERE user_id = ?
     * 
     * Explanation: Similar to deleteStudent, deleting the parent user row will trigger
     * a cascade delete removing the corresponding row in 'teachers' due to the database configuration:
     * "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE"
     * 
     * @param teacherId The unique teacher ID.
     * @return True if deletion succeeds, false otherwise.
     */
    public boolean deleteTeacher(int teacherId) {
        Connection conn = null;
        PreparedStatement psGetUserId = null;
        PreparedStatement psDeleteUser = null;
        ResultSet rs = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false);

            // 1. Fetch user_id matching the teacher row
            String sqlGetUserId = "SELECT user_id FROM teachers WHERE teacher_id = ?";
            psGetUserId = conn.prepareStatement(sqlGetUserId);
            psGetUserId.setInt(1, teacherId);
            rs = psGetUserId.executeQuery();

            int userId = -1;
            if (rs.next()) {
                userId = rs.getInt("user_id");
            }

            // 2. Cascade delete by removing user parent entry
            if (userId != -1) {
                String sqlDeleteUser = "DELETE FROM users WHERE user_id = ?";
                psDeleteUser = conn.prepareStatement(sqlDeleteUser);
                psDeleteUser.setInt(1, userId);
                psDeleteUser.executeUpdate();
                conn.commit();
                success = true;
            }
        } catch (SQLException e) {
            System.err.println("[AMS TeacherDAO] Transaction error in deleteTeacher: " + e.getMessage());
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
     * Standard helper method to translate a ResultSet row into a Teacher JavaBean.
     */
    private Teacher extractTeacherFromResultSet(ResultSet rs) throws SQLException {
        Teacher teacher = new Teacher();
        teacher.setId(rs.getInt("teacher_id"));
        teacher.setUserId(rs.getInt("user_id"));
        teacher.setFirstName(rs.getString("first_name"));
        teacher.setLastName(rs.getString("last_name"));
        teacher.setPhone(rs.getString("phone"));
        teacher.setSpecialization(rs.getString("department")); // department maps to specialization
        teacher.setEmail(rs.getString("email")); // Populated from joined user row
        
        // Formulate employeeId using prefix + teacher_id
        teacher.setEmployeeId("EMP" + String.format("%04d", rs.getInt("teacher_id")));
        return teacher;
    }
}
