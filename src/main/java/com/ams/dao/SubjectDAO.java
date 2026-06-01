package com.ams.dao;

import com.ams.model.Subject;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * SubjectDAO.java
 * Purpose: Manages all database queries and updates for academic 'subjects'.
 */
public class SubjectDAO {

    /**
     * Retrieves all subjects registered in the system.
     * 
     * SQL Query: SELECT * FROM subjects
     * Explanation: Queries the subjects table to fetch catalog listings.
     * 
     * @return A List of Subject objects.
     */
    public List<Subject> getAllSubjects() {
        List<Subject> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM subjects";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractSubjectFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in getAllSubjects: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves subjects allocated to a specific teacher.
     * 
     * SQL Query: SELECT * FROM subjects WHERE teacher_id = ?
     * Explanation: Queries subjects where the assigned professor matches teacherId parameter.
     * 
     * @param teacherId The unique teacher ID.
     * @return A List of Subject objects.
     */
    public List<Subject> getSubjectsByTeacher(int teacherId) {
        List<Subject> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM subjects WHERE teacher_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, teacherId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractSubjectFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in getSubjectsByTeacher: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves subjects allocated to a specific class cohort.
     * 
     * SQL Query: SELECT * FROM subjects WHERE class_id = ?
     * Explanation: Queries subjects taught inside a designated class batch section.
     * 
     * @param classId The unique class ID.
     * @return A List of Subject objects.
     */
    public List<Subject> getSubjectsByClass(int classId) {
        List<Subject> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM subjects WHERE class_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, classId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractSubjectFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in getSubjectsByClass: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Inserts a new subject catalog entry.
     * 
     * SQL Query: INSERT INTO subjects (subject_code, subject_name, teacher_id, class_id) VALUES (?, ?, ?, ?)
     * Explanation: Writes standard subject codes and identifiers to the database subjects table.
     * 
     * @param subject The Subject JavaBean containing properties to save.
     * @return True if insertion succeeds, false otherwise.
     */
    public boolean addSubject(Subject subject) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "INSERT INTO subjects (subject_code, subject_name, teacher_id, class_id) VALUES (?, ?, ?, ?)";
            ps = conn.prepareStatement(sql);
            ps.setString(1, subject.getCode());
            ps.setString(2, subject.getName());
            
            if (subject.getTeacherId() > 0) {
                ps.setInt(3, subject.getTeacherId());
            } else {
                ps.setNull(3, java.sql.Types.INTEGER);
            }
            
            ps.setInt(4, subject.getClassId());
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in addSubject: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Updates an existing subject entry.
     * 
     * SQL Query: UPDATE subjects SET subject_code = ?, subject_name = ?, teacher_id = ?, class_id = ? WHERE subject_id = ?
     * Explanation: Modifies subject metadata attributes based on matching subject primary key identifier.
     * 
     * @param subject The Subject JavaBean containing updated fields.
     * @return True if update succeeds, false otherwise.
     */
    public boolean updateSubject(Subject subject) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "UPDATE subjects SET subject_code = ?, subject_name = ?, teacher_id = ?, class_id = ? WHERE subject_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, subject.getCode());
            ps.setString(2, subject.getName());
            
            if (subject.getTeacherId() > 0) {
                ps.setInt(3, subject.getTeacherId());
            } else {
                ps.setNull(3, java.sql.Types.INTEGER);
            }
            
            ps.setInt(4, subject.getClassId());
            ps.setInt(5, subject.getId());
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in updateSubject: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Deletes a subject from the system catalog.
     * 
     * SQL Query: DELETE FROM subjects WHERE subject_id = ?
     * Explanation: Deletes target subject row matching subject_id. Due to cascade rules:
     * "FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE"
     * deleting a subject automatically cleans up any linked attendance records!
     * 
     * @param subjectId The unique subject ID.
     * @return True if deletion succeeds, false otherwise.
     */
    public boolean deleteSubject(int subjectId) {
        Connection conn = null;
        PreparedStatement ps = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "DELETE FROM subjects WHERE subject_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, subjectId);
            ps.executeUpdate();
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS SubjectDAO] Error in deleteSubject: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Standard helper method to translate a ResultSet row into a Subject JavaBean.
     */
    private Subject extractSubjectFromResultSet(ResultSet rs) throws SQLException {
        Subject subject = new Subject();
        subject.setId(rs.getInt("subject_id"));
        subject.setCode(rs.getString("subject_code"));
        subject.setName(rs.getString("subject_name"));
        subject.setTeacherId(rs.getInt("teacher_id"));
        subject.setClassId(rs.getInt("class_id"));
        subject.setTotalClasses(0); // Optional default helper
        return subject;
    }
}
