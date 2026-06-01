package com.ams.model;

import java.io.Serializable;
import java.sql.Date;

/**
 * Attendance.java
 * Model JavaBean representing the attendance master table in the database.
 */
public class Attendance implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private int subjectId;
    private int teacherId;
    private int classId;
    private Date attendanceDate;
    private String slot; // e.g. "09:00 - 10:00 AM" (Persisted in DB)
    private int totalStudents; // Optional calculated model helper

    // Constructors
    public Attendance() {}

    public Attendance(int id, int subjectId, int teacherId, int classId, Date attendanceDate, String slot, int totalStudents) {
        this.id = id;
        this.subjectId = subjectId;
        this.teacherId = teacherId;
        this.classId = classId;
        this.attendanceDate = attendanceDate;
        this.slot = slot;
        this.totalStudents = totalStudents;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getSubjectId() {
        return subjectId;
    }

    public void setSubjectId(int subjectId) {
        this.subjectId = subjectId;
    }

    public int getTeacherId() {
        return teacherId;
    }

    public void setTeacherId(int teacherId) {
        this.teacherId = teacherId;
    }

    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
    }

    public Date getAttendanceDate() {
        return attendanceDate;
    }

    public void setAttendanceDate(Date attendanceDate) {
        this.attendanceDate = attendanceDate;
    }

    public String getSlot() {
        return slot;
    }

    public void setSlot(String slot) {
        this.slot = slot;
    }

    public int getTotalStudents() {
        return totalStudents;
    }

    public void setTotalStudents(int totalStudents) {
        this.totalStudents = totalStudents;
    }

    @Override
    public String toString() {
        return "Attendance{" +
                "id=" + id +
                ", subjectId=" + subjectId +
                ", teacherId=" + teacherId +
                ", classId=" + classId +
                ", attendanceDate=" + attendanceDate +
                ", slot='" + slot + '\'' +
                ", totalStudents=" + totalStudents +
                '}';
    }
}
