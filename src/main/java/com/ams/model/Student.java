package com.ams.model;

import java.io.Serializable;
import java.sql.Date;

/**
 * Student.java
 * Model JavaBean representing the student profile in the database.
 */
public class Student implements Serializable {
    private static final long serialVersionUID = 1L;

    private int id;
    private int userId;
    private int classId;
    private String firstName;
    private String lastName;
    private String rollNo;
    private String email; // Joined/mapped from User account
    private String phone;
    private Date dateOfBirth; // Persisted from schema
    private String address;   // Optional model helper
    private String photo;     // Optional model helper

    // Constructors
    public Student() {}

    public Student(int id, int userId, int classId, String firstName, String lastName, String rollNo, String email, String phone, Date dateOfBirth, String address, String photo) {
        this.id = id;
        this.userId = userId;
        this.classId = classId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.rollNo = rollNo;
        this.email = email;
        this.phone = phone;
        this.dateOfBirth = dateOfBirth;
        this.address = address;
        this.photo = photo;
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

    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
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

    public String getRollNo() {
        return rollNo;
    }

    public void setRollNo(String rollNo) {
        this.rollNo = rollNo;
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

    public Date getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(Date dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPhoto() {
        return photo;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    @Override
    public String toString() {
        return "Student{" +
                "id=" + id +
                ", userId=" + userId +
                ", classId=" + classId +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", rollNo='" + rollNo + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", dateOfBirth=" + dateOfBirth +
                '}';
    }
}
