package com.ams.model;

import java.io.Serializable;

/**
 * Teacher.java
 * Model JavaBean representing the teacher profile in the database.
 */
public class Teacher implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private int userId;
    private String firstName;
    private String lastName;
    private String employeeId; // Maps to specialized string identifier or id
    private String email;      // Joined/mapped from User account
    private String phone;
    private String specialization; // Maps to department column in database schema

    // Constructors
    public Teacher() {}

    public Teacher(int id, int userId, String firstName, String lastName, String employeeId, String email, String phone, String specialization) {
        this.id = id;
        this.userId = userId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.employeeId = employeeId;
        this.email = email;
        this.phone = phone;
        this.specialization = specialization;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(String employeeId) {
        this.employeeId = employeeId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getSpecialization() {
        return specialization;
    }

    public void setSpecialization(String specialization) {
        this.specialization = specialization;
    }

    @Override
    public String toString() {
        return "Teacher{" +
                "id=" + id +
                ", userId=" + userId +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", employeeId='" + employeeId + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", specialization='" + specialization + '\'' +
                '}';
    }
}
