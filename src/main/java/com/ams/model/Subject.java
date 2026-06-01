package com.ams.model;

import java.io.Serializable;

/**
 * Subject.java
 * Model JavaBean representing the subjects table in the database.
 */
public class Subject implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private String name;  // Maps to subject_name in DB
    private String code;  // Maps to subject_code in DB
    private int teacherId;
    private int classId;
    private int totalClasses; // Optional model helper (e.g. calculated for statistics)

    // Constructors
    public Subject() {}

    public Subject(int id, String name, String code, int teacherId, int classId, int totalClasses) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.teacherId = teacherId;
        this.classId = classId;
        this.totalClasses = totalClasses;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
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

    public int getTotalClasses() {
        return totalClasses;
    }

    public void setTotalClasses(int totalClasses) {
        this.totalClasses = totalClasses;
    }

    @Override
    public String toString() {
        return "Subject{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", code='" + code + '\'' +
                ", teacherId=" + teacherId +
                ", classId=" + classId +
                ", totalClasses=" + totalClasses +
                '}';
    }
}
