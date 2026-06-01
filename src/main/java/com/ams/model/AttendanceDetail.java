package com.ams.model;

import java.io.Serializable;

/**
 * AttendanceDetail.java
 * Model JavaBean representing individual student attendance details.
 */
public class AttendanceDetail implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private int attendanceId;
    private int studentId;
    private String status; // P, A, L (Model status abbreviations)
    private String remarks; // Optional remarks for absence excuses

    // Constructors
    public AttendanceDetail() {}

    public AttendanceDetail(int id, int attendanceId, int studentId, String status, String remarks) {
        this.id = id;
        this.attendanceId = attendanceId;
        this.studentId = studentId;
        this.status = status;
        this.remarks = remarks;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getAttendanceId() {
        return attendanceId;
    }

    public void setAttendanceId(int attendanceId) {
        this.attendanceId = attendanceId;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
    }

    @Override
    public String toString() {
        return "AttendanceDetail{" +
                "id=" + id +
                ", attendanceId=" + attendanceId +
                ", studentId=" + studentId +
                ", status='" + status + '\'' +
                ", remarks='" + remarks + '\'' +
                '}';
    }
}
