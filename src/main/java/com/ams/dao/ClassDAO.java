package com.ams.dao;

import com.ams.model.ClassSection;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * ClassDAO.java
 * Purpose: Handles all CRUD operations for class cohorts/sections in the 'classes' table.
 */
public class ClassDAO {

    /**
     * Retrieves all classes stored in the system.
     * 
     * SQL Query: SELECT * FROM classes
     * Explanation: Queries all available rows from the classes cohort tables.
     * 
     * @return A List of ClassSection objects.
     */
    public List<ClassSection> getAllClasses() {
        List<ClassSection> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM classes";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractClassFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS ClassDAO] Error in getAllClasses: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves a single class cohort by its unique class ID.
     * 
     * SQL Query: SELECT * FROM classes WHERE class_id = ?
     * Explanation: Filters classes records by class_id primary key parameter.
     * 
     * @param classId The unique class ID.
     * @return The ClassSection object if found, or null otherwise.
     */
    public ClassSection getClassById(int classId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        ClassSection classSection = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM classes WHERE class_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, classId);
            rs = ps.executeQuery();

            if (rs.next()) {
                classSection = extractClassFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS ClassDAO] Error in getClassById: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return classSection;
    }

    /**
     * Inserts a new class section.
     * 
     * SQL Query: INSERT INTO classes (class_name, semester, academic_year) VALUES (?, ?, ?)
     * Explanation: Creates a class cohort mapping class name, semester (section), and academic year.
     * 
     * @param classSection The ClassSection JavaBean containing properties to save.
     * @return True if insertion succeeds, false otherwise.
     */
    public boolean addClass(ClassSection classSection) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "INSERT INTO classes (class_name, semester, academic_year) VALUES (?, ?, ?)";
            ps = conn.prepareStatement(sql);
            ps.setString(1, classSection.getName());
            ps.setString(2, classSection.getSection()); // section maps to semester
            ps.setString(3, classSection.getAcademicYear()); // academicYear maps to academic_year
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS ClassDAO] Error in addClass: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Updates an existing class section.
     * 
     * SQL Query: UPDATE classes SET class_name = ?, semester = ?, academic_year = ? WHERE class_id = ?
     * Explanation: Modifies class parameters based on the matched class primary key identifier.
     * 
     * @param classSection The ClassSection JavaBean containing modified fields.
     * @return True if update succeeds, false otherwise.
     */
    public boolean updateClass(ClassSection classSection) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "UPDATE classes SET class_name = ?, semester = ?, academic_year = ? WHERE class_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, classSection.getName());
            ps.setString(2, classSection.getSection()); // section maps to semester
            ps.setString(3, classSection.getAcademicYear()); // academicYear maps to academic_year
            ps.setInt(4, classSection.getId());
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS ClassDAO] Error in updateClass: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Deletes a class section from the system database.
     * 
     * SQL Query: DELETE FROM classes WHERE class_id = ?
     * Explanation: Deletes target class row matching class_id. Relational cascades clean up
     * dependent student allocations and subject associations automatically.
     * 
     * @param classId The unique class ID.
     * @return True if deletion succeeds, false otherwise.
     */
    public boolean deleteClass(int classId) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "DELETE FROM classes WHERE class_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, classId);
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS ClassDAO] Error in deleteClass: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Checks if a class name already exists.
     */
    public boolean isClassNameExists(String className) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        boolean exists = false;
        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT COUNT(*) FROM classes WHERE class_name = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, className);
            rs = ps.executeQuery();
            if (rs.next()) {
                exists = rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return exists;
    }

    /**
     * Checks if a class name exists for another class cohort.
     */
    public boolean isClassNameExistsForOther(String className, int classId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        boolean exists = false;
        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT COUNT(*) FROM classes WHERE class_name = ? AND class_id != ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, className);
            ps.setInt(2, classId);
            rs = ps.executeQuery();
            if (rs.next()) {
                exists = rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return exists;
    }

    /**
     * Checks if a class has active students or registered subjects.
     */
    public boolean hasDependentStudentsOrSubjects(int classId) {
        Connection conn = null;
        PreparedStatement psStudents = null;
        PreparedStatement psSubjects = null;
        ResultSet rsStudents = null;
        ResultSet rsSubjects = null;
        boolean hasDependents = false;
        try {
            conn = DBConnection.getInstance().getConnection();
            
            // Check students
            String sqlStudents = "SELECT COUNT(*) FROM students WHERE class_id = ?";
            psStudents = conn.prepareStatement(sqlStudents);
            psStudents.setInt(1, classId);
            rsStudents = psStudents.executeQuery();
            if (rsStudents.next() && rsStudents.getInt(1) > 0) {
                hasDependents = true;
            }
            
            // Check subjects
            if (!hasDependents) {
                String sqlSubjects = "SELECT COUNT(*) FROM subjects WHERE class_id = ?";
                psSubjects = conn.prepareStatement(sqlSubjects);
                psSubjects.setInt(1, classId);
                rsSubjects = psSubjects.executeQuery();
                if (rsSubjects.next() && rsSubjects.getInt(1) > 0) {
                    hasDependents = true;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rsStudents);
            DBConnection.closeResultSet(rsSubjects);
            DBConnection.closeStatement(psStudents);
            DBConnection.closeStatement(psSubjects);
            DBConnection.closeConnection(conn);
        }
        return hasDependents;
    }

    /**
     * Standard helper method to translate a ResultSet row into a ClassSection JavaBean.
     */
    private ClassSection extractClassFromResultSet(ResultSet rs) throws SQLException {
        ClassSection classSection = new ClassSection();
        classSection.setId(rs.getInt("class_id"));
        classSection.setName(rs.getString("class_name"));
        classSection.setSection(rs.getString("semester")); // semester maps to section
        classSection.setAcademicYear(rs.getString("academic_year")); // academic_year maps to academicYear
        return classSection;
    }
}
