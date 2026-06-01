package com.ams.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * DBConnection.java
 * Purpose: Singleton utility class providing secure, centralized access to database
 * connections for the College Attendance Management System.
 * 
 * DESIGN PATTERN: Thread-Safe Singleton Pattern
 */
public class DBConnection {

    // =========================================================================
    // DATABASE CONNECTION CONFIGURATIONS
    // =========================================================================
    /**
     * Fully Qualified Name of the MySQL JDBC Driver Class.
     */
    private static final String DB_DRIVER = "com.mysql.cj.jdbc.Driver";

    /**
     * MySQL Connection String URL.
     * Adjust the hostname, port, and query configurations if your local instance operates on a different socket.
     */
    private static final String DB_URL = "jdbc:mysql://localhost:3306/attendance_db?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";

    /**
     * Database Username Constant.
     * EDIT THIS to match the credential configured in your MySQL server.
     */
    private static final String DB_USER = "root";

    /**
     * Database Password Constant.
     * EDIT THIS to match the actual credential required by your MySQL instance.
     */
    private static final String DB_PASSWORD = "password";

    /**
     * Singleton instance placeholder.
     */
    private static DBConnection instance = null;

    /**
     * Private constructor enforces singleton usage and ensures driver class is registered with DriverManager.
     */
    private DBConnection() {
        try {
            // Explicitly load and register the driver to initialize connection manager pipelines
            Class.forName(DB_DRIVER);
        } catch (ClassNotFoundException e) {
            System.err.println("[AMS DBConnection] CRITICAL: MySQL Driver class '" + DB_DRIVER + "' not found.");
            e.printStackTrace();
        }
    }

    /**
     * Returns the singleton instance of DBConnection.
     * Uses synchronized double-checked locking behavior or standard synchronization for thread safety.
     *
     * @return The active DBConnection management instance.
     */
    public static synchronized DBConnection getInstance() {
        if (instance == null) {
            instance = new DBConnection();
        }
        return instance;
    }

    /**
     * Generates a new raw Connection against the configured MySQL server.
     * Caller is responsible for explicitly managing transaction loops and closing this connection.
     *
     * @return A live SQL Connection.
     * @throws SQLException If database access fails.
     */
    public Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }

    /**
     * Standard cleanup helper to release connection instances safely back to database buffers.
     * 
     * @param connection The SQL Connection instance to close.
     */
    public static void closeConnection(Connection connection) {
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {
                System.err.println("[AMS DBConnection] Error releasing SQL Connection: " + e.getMessage());
            }
        }
    }

    /**
     * Standard cleanup helper to release prepared statement or statement caches safely.
     * 
     * @param statement The SQL Statement instance to close.
     */
    public static void closeStatement(Statement statement) {
        if (statement != null) {
            try {
                statement.close();
            } catch (SQLException e) {
                System.err.println("[AMS DBConnection] Error releasing SQL Statement: " + e.getMessage());
            }
        }
    }

    /**
     * Standard cleanup helper to release data stream cursors safely.
     * 
     * @param resultSet The SQL ResultSet instance to close.
     */
    public static void closeResultSet(ResultSet resultSet) {
        if (resultSet != null) {
            try {
                resultSet.close();
            } catch (SQLException e) {
                System.err.println("[AMS DBConnection] Error releasing SQL ResultSet: " + e.getMessage());
            }
        }
    }
}
