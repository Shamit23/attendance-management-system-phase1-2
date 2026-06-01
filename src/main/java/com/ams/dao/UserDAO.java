package com.ams.dao;

import com.ams.model.User;
import com.ams.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * UserDAO.java
 * Purpose: Handles all CRUD and database queries for the 'users' table.
 */
public class UserDAO {

    /**
     * Authenticates a user based on username and password.
     * 
     * SQL Query: SELECT * FROM users WHERE username = ? AND password = ?
     * Explanation: Checks the users table for a matching username and password combination.
     * 
     * @param username The login username.
     * @param password The login password.
     * @return The authenticated User object, or null if authentication fails.
     */
    public User authenticate(String username, String password) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        User user = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM users WHERE username = ? AND password = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                user = extractUserFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS UserDAO] Error authenticating user: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return user;
    }

    /**
     * Retrieves a user by their unique username.
     * 
     * SQL Query: SELECT * FROM users WHERE username = ?
     * Explanation: Queries the users table by username. Useful for registration checks or username verification.
     * 
     * @param username The username to search.
     * @return The User object if found, or null otherwise.
     */
    public User getUserByUsername(String username) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        User user = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM users WHERE username = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            rs = ps.executeQuery();

            if (rs.next()) {
                user = extractUserFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS UserDAO] Error fetching user by username: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return user;
    }

    /**
     * Retrieves a user by their unique primary key ID.
     * 
     * SQL Query: SELECT * FROM users WHERE user_id = ?
     * Explanation: Queries the users table by primary key user_id to extract user details.
     * 
     * @param userId The unique user ID.
     * @return The User object if found, or null otherwise.
     */
    public User getUserById(int userId) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        User user = null;

        try {
            conn = DBConnection.getInstance().getConnection();
            String sql = "SELECT * FROM users WHERE user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();

            if (rs.next()) {
                user = extractUserFromResultSet(rs);
            }
        } catch (SQLException e) {
            System.err.println("[AMS UserDAO] Error fetching user by ID: " + e.getMessage());
            e.printStackTrace();
        } finally {
            DBConnection.closeResultSet(rs);
            DBConnection.closeStatement(ps);
            DBConnection.closeConnection(conn);
        }
        return user;
    }

    /**
     * Standard helper method to translate a ResultSet row into a User JavaBean.
     */
    private User extractUserFromResultSet(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("user_id"));
        user.setUsername(rs.getString("username"));
        user.setPassword(rs.getString("password"));
        user.setRole(rs.getString("role"));
        user.setEmail(rs.getString("email"));
        user.setCreatedAt(rs.getTimestamp("created_at"));
        return user;
    }
}
