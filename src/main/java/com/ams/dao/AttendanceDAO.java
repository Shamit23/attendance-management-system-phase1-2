package com.ams.dao;

import com.ams.model.Attendance;
import com.ams.model.AttendanceDetail;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AttendanceDAO.java
 * Purpose: Central control layer managing all master attendance logs, individual
 * grading records, real-time report summaries, and analytics percentage queries.
 */
public class AttendanceDAO {

    // Status translation helper: Model status abbreviation -> DB ENUM
    private String mapModelStatusToDB(String modelStatus) {
        if (modelStatus == null) return "PRESENT";
        switch (modelStatus.toUpperCase()) {
            case "P": return "PRESENT";
            case "A": return "ABSENT";
            case "L": return "LATE";
            case "E": return "EXCUSED";
            default: return "PRESENT";
        }
    }

    // Status translation helper: DB ENUM -> Model status abbreviation
    private String mapDBStatusToModel(String dbStatus) {
        if (dbStatus == null) return "P";
        switch (dbStatus.toUpperCase()) {
            case "PRESENT": return "P";
            case "ABSENT": return "A";
            case "LATE": return "L";
            case "EXCUSED": return "E";
            default: return "P";
        }
    }

    /**
     * Records a new attendance session and logs grades for all students in a transaction.
     * 
     * SQL Query 1: INSERT INTO attendance (class_id, subject_id, teacher_id, attendance_date, slot) VALUES (?, ?, ?, ?, ?)
     * SQL Query 2: INSERT INTO attendance_details (attendance_id, student_id, status, remarks) VALUES (?, ?, ?, ?)
     * 
     * Explanation: Utilizes JDBC transactions. Inserts the master session entry, retrieves 
     * the auto-generated attendance_id, loops through details to record student marks, 
     * then commits the transaction together to ensure data integrity.
     * 
     * @param attendance The master Attendance record.
     * @param details List of student AttendanceDetail records.
     * @return True if recorded successfully, false if transaction rolled back.
     */
    public boolean markAttendance(Attendance attendance, List<AttendanceDetail> details) {
        Connection conn = null;
        PreparedStatement psMaster = null;
        PreparedStatement psDetail = null;
        ResultSet rsKey = null;
        boolean success = false;

        try {
            conn = DBConnection.getInstance().getConnection();
            conn.setAutoCommit(false); // Begin transaction

            // 1. Insert into attendance (Master record)
            String sqlMaster = "INSERT INTO attendance (class_id, subject_id, teacher_id, attendance_date, slot) VALUES (?, ?, ?, ?, ?)";
            psMaster = conn.prepareStatement(sqlMaster, Statement.RETURN_GENERATED_KEYS);
            psMaster.setInt(1, attendance.getClassId());
            psMaster.setInt(2, attendance.getSubjectId());
            psMaster.setInt(3, attendance.getTeacherId());
            psMaster.setDate(4, attendance.getAttendanceDate());
            psMaster.setString(5, attendance.getSlot() != null ? attendance.getSlot() : "09:00 - 10:00 AM");
            psMaster.executeUpdate();

            rsKey = psMaster.getGeneratedKeys();
            int attendanceId = -1;
            if (rsKey.next()) {
                attendanceId = rsKey.getInt(1);
            } else {
                throw new SQLException("Failed to retrieve generated attendance_id.");
            }

            // 2. Loop and insert attendance details
            String sqlDetail = "INSERT INTO attendance_details (attendance_id, student_id, status, remarks) VALUES (?, ?, ?, ?)";
            psDetail = conn.prepareStatement(sqlDetail);

            for (AttendanceDetail detail : details) {
                psDetail.setInt(1, attendanceId);
                psDetail.setInt(2, detail.getStudentId());
                psDetail.setString(3, mapModelStatusToDB(detail.getStatus()));
                psDetail.setString(4, detail.getRemarks());
                psDetail.addBatch(); // Batch processing for fast execution
            }

            psDetail.executeBatch();
            conn.commit(); // Commit transaction
            success = true;
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Transaction error in markAttendance: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback(); // Roll back on failure
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rsKey);
            DBConnection.closeStatement(psMaster);
            DBConnection.closeStatement(psDetail);
            DBConnection.closeConnection(conn);
        }
        return success;
    }

    /**
     * Fetches a master attendance session by subject and date.
     * 
     * SQL Query: SELECT * FROM attendance WHERE subject_id = ? AND attendance_date = ? LIMIT 1
     * Explanation: Locates the single master recorded session for a specific course subject and date.
     * 
     * @param subjectId The unique subject ID.
     * @param date The calendar date.
     * @return The Attendance object if found, or null otherwise.
     */
    public Attendance getAttendanceByDate(int subjectId, Date date) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Attendance att = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM attendance WHERE subject_id = ? AND attendance_date = ? LIMIT 1";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, subjectId);
            ps.setDate(2, date);
            rs = ps.executeQuery();

            if (rs.next()) {
                att = extractAttendanceFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getAttendanceByDate: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return att;
    }

    /**
     * Retrieves all recorded sessions for a specific subject (History).
     * 
     * SQL Query: SELECT * FROM attendance WHERE subject_id = ? ORDER BY attendance_date DESC
     * Explanation: Fetches session records matching the subject ID, sorted chronologically.
     * 
     * @param subjectId The unique subject ID.
     * @return A List of Attendance objects.
     */
    public List<Attendance> getAttendanceHistory(int subjectId) {
        List<Attendance> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM attendance WHERE subject_id = ? ORDER BY attendance_date DESC";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, subjectId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractAttendanceFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getAttendanceHistory: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Retrieves individual attendance logs recorded for a student.
     * 
     * SQL Query: SELECT * FROM attendance_details WHERE student_id = ?
     * Explanation: Pulls individual student status rows from attendance_details table.
     * 
     * @param studentId The unique student ID.
     * @return A List of AttendanceDetail records.
     */
    public List<AttendanceDetail> getStudentAttendance(int studentId) {
        List<AttendanceDetail> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM attendance_details WHERE student_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            rs = ps.executeQuery();

            while (rs.next()) {
                list.add(extractDetailFromResultSet(rs));
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getStudentAttendance: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return list;
    }

    /**
     * Calculates the attendance percentage of a student in a specific subject.
     * 
     * SQL Query: 
     * SELECT 
     *     SUM(CASE WHEN ad.status = 'PRESENT' OR ad.status = 'LATE' OR ad.status = 'EXCUSED' THEN 1 ELSE 0 END) as attended,
     *     COUNT(ad.detail_id) as total 
     * FROM attendance_details ad 
     * JOIN attendance a ON ad.attendance_id = a.attendance_id 
     * WHERE ad.student_id = ? AND a.subject_id = ?
     * 
     * Explanation: Joins session master and details, counts classes matching Present, Late, or Excused,
     * then divides by total sessions taken to calculate the percentage.
     * 
     * @param studentId The unique student ID.
     * @param subjectId The unique subject ID.
     * @return The percentage value (0.0 to 100.0). Returns 100.0 if no sessions exist.
     */
    public double getAttendancePercentage(int studentId, int subjectId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        double percentage = 100.0;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT " +
                         "  SUM(CASE WHEN ad.status = 'PRESENT' OR ad.status = 'LATE' OR ad.status = 'EXCUSED' THEN 1 ELSE 0 END) as attended, " +
                         "  COUNT(ad.detail_id) as total " +
                         "FROM attendance_details ad " +
                         "JOIN attendance a ON ad.attendance_id = a.attendance_id " +
                         "WHERE ad.student_id = ? AND a.subject_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, studentId);
            ps.setInt(2, subjectId);
            rs = ps.executeQuery();

            if (rs.next()) {
                int total = rs.getInt("total");
                int attended = rs.getInt("attended");
                if (total > 0) {
                    percentage = (double) attended / total * 100.0;
                }
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getAttendancePercentage: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return percentage;
    }

    /**
     * Generates a detailed daily report aggregating all student attendances logged for a date.
     * 
     * SQL Query: 
     * SELECT ad.detail_id, ad.status, ad.remarks, s.first_name, s.last_name, s.roll_number, 
     *        c.class_name, subj.subject_name, subj.subject_code 
     * FROM attendance_details ad 
     * JOIN attendance a ON ad.attendance_id = a.attendance_id 
     * JOIN students s ON ad.student_id = s.student_id 
     * JOIN classes c ON a.class_id = c.class_id 
     * JOIN subjects subj ON a.subject_id = subj.subject_id 
     * WHERE a.attendance_date = ?
     * 
     * Explanation: Joins multiple tables (details, master session, student metrics, classes, and subjects)
     * to extract real-time daily metrics for the dashboard.
     * 
     * @param date The calendar date target.
     * @return A List of Map structures holding detailed column metrics.
     */
    public List<Map<String, Object>> getDailyReport(Date date) {
        List<Map<String, Object>> report = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT ad.detail_id, ad.status, ad.remarks, s.first_name, s.last_name, s.roll_number, " +
                         "       c.class_name, subj.subject_name, subj.subject_code " +
                         "FROM attendance_details ad " +
                         "JOIN attendance a ON ad.attendance_id = a.attendance_id " +
                         "JOIN students s ON ad.student_id = s.student_id " +
                         "JOIN classes c ON a.class_id = c.class_id " +
                         "JOIN subjects subj ON a.subject_id = subj.subject_id " +
                         "WHERE a.attendance_date = ? " +
                         "ORDER BY c.class_name ASC, s.roll_number ASC";
            ps = conn.prepareStatement(sql);
            ps.setDate(1, date);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("detailId", rs.getInt("detail_id"));
                row.put("studentName", rs.getString("first_name") + " " + rs.getString("last_name"));
                row.put("rollNo", rs.getString("roll_number"));
                row.put("className", rs.getString("class_name"));
                row.put("subjectName", rs.getString("subject_name"));
                row.put("subjectCode", rs.getString("subject_code"));
                row.put("status", mapDBStatusToModel(rs.getString("status")));
                row.put("remarks", rs.getString("remarks"));
                report.add(row);
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getDailyReport: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return report;
    }

    /**
     * Generates a monthly aggregate report of recorded class sessions for a calendar month.
     * 
     * SQL Query: 
     * SELECT c.class_name, subj.subject_name, subj.subject_code, a.attendance_date, 
     *        SUM(CASE WHEN ad.status = 'PRESENT' THEN 1 ELSE 0 END) as present_count, 
     *        SUM(CASE WHEN ad.status = 'ABSENT' THEN 1 ELSE 0 END) as absent_count, 
     *        SUM(CASE WHEN ad.status = 'LATE' THEN 1 ELSE 0 END) as late_count, 
     *        COUNT(ad.student_id) as total_students 
     * FROM attendance_details ad 
     * JOIN attendance a ON ad.attendance_id = a.attendance_id 
     * JOIN classes c ON a.class_id = c.class_id 
     * JOIN subjects subj ON a.subject_id = subj.subject_id 
     * WHERE MONTH(a.attendance_date) = ? AND YEAR(a.attendance_date) = ? 
     * GROUP BY a.attendance_id, c.class_name, subj.subject_name, subj.subject_code, a.attendance_date 
     * ORDER BY a.attendance_date ASC
     * 
     * Explanation: Uses SQL grouping aggregates to summarize stats for all sessions taken in the month.
     * 
     * @param month Calendar month index (1-12).
     * @param year Calendar academic year (e.g. 2026).
     * @return A List of Map structures showing aggregated monthly summary metrics.
     */
    public List<Map<String, Object>> getMonthlyReport(int month, int year) {
        List<Map<String, Object>> report = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT c.class_name, subj.subject_name, subj.subject_code, a.attendance_date, " +
                         "       SUM(CASE WHEN ad.status = 'PRESENT' THEN 1 ELSE 0 END) as present_count, " +
                         "       SUM(CASE WHEN ad.status = 'ABSENT' THEN 1 ELSE 0 END) as absent_count, " +
                         "       SUM(CASE WHEN ad.status = 'LATE' THEN 1 ELSE 0 END) as late_count, " +
                         "       COUNT(ad.student_id) as total_students " +
                         "FROM attendance_details ad " +
                         "JOIN attendance a ON ad.attendance_id = a.attendance_id " +
                         "JOIN classes c ON a.class_id = c.class_id " +
                         "JOIN subjects subj ON a.subject_id = subj.subject_id " +
                         "WHERE MONTH(a.attendance_date) = ? AND YEAR(a.attendance_date) = ? " +
                         "GROUP BY a.attendance_id, c.class_name, subj.subject_name, subj.subject_code, a.attendance_date " +
                         "ORDER BY a.attendance_date ASC";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, month);
            ps.setInt(2, year);
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("className", rs.getString("class_name"));
                row.put("subjectName", rs.getString("subject_name"));
                row.put("subjectCode", rs.getString("subject_code"));
                row.put("date", rs.getDate("attendance_date"));
                row.put("presentCount", rs.getInt("present_count"));
                row.put("absentCount", rs.getInt("absent_count"));
                row.put("lateCount", rs.getInt("late_count"));
                row.put("totalCount", rs.getInt("total_students"));
                report.add(row);
            }
        } catch (SQLException e) {
            System.err.println("[AMS AttendanceDAO] Error in getMonthlyReport: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return report;
    }

    /**
     * Helper to translate a ResultSet row into an Attendance JavaBean.
     */
    private Attendance extractAttendanceFromResultSet(ResultSet rs) throws SQLException {
        Attendance att = new Attendance();
        att.setId(rs.getInt("attendance_id"));
        att.setClassId(rs.getInt("class_id"));
        att.setSubjectId(rs.getInt("subject_id"));
        att.setTeacherId(rs.getInt("teacher_id"));
        att.setAttendanceDate(rs.getDate("attendance_date"));
        att.setSlot(rs.getString("slot"));
        att.setTotalStudents(0); // Default placeholder
        return att;
    }

    /**
     * Helper to translate a ResultSet row into an AttendanceDetail JavaBean.
     */
    private AttendanceDetail extractDetailFromResultSet(ResultSet rs) throws SQLException {
        AttendanceDetail detail = new AttendanceDetail();
        detail.setId(rs.getInt("detail_id"));
        detail.setAttendanceId(rs.getInt("attendance_id"));
        detail.setStudentId(rs.getInt("student_id"));
        detail.setStatus(mapDBStatusToModel(rs.getString("status"))); // Translate DB to Model
        detail.setRemarks(rs.getString("remarks"));
        return detail;
    }
}
