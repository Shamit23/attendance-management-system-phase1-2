package com.ams.model;

import java.io.Serializable;

/**
 * ClassSection.java
 * Model JavaBean representing the classes table in the database.
 */
public class ClassSection implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private String name;    // Maps to class_name in DB
    private String section; // Maps to semester in DB
    private String academicYear; // Maps to academic_year in DB

    // Constructors
    public ClassSection() {}

    public ClassSection(int id, String name, String section, String academicYear) {
        this.id = id;
        this.name = name;
        this.section = section;
        this.academicYear = academicYear;
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

    public String getSection() {
        return section;
    }

    public void setSection(String section) {
        this.section = section;
    }

    public String getAcademicYear() {
        return academicYear;
    }

    public void setAcademicYear(String academicYear) {
        this.academicYear = academicYear;
    }

    @Override
    public String toString() {
        return "ClassSection{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", section='" + section + '\'' +
                ", academicYear='" + academicYear + '\'' +
                '}';
    }
}
