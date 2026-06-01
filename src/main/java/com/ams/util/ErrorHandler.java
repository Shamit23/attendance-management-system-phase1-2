package com.ams.util;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ErrorHandler.java
 * Purpose: Centrally handles operations, logs exceptions to java.util.logging.Logger, 
 * and returns unified Result wrappers for caller servlets.
 */
public class ErrorHandler {
    private static final Logger LOGGER = Logger.getLogger(ErrorHandler.class.getName());

    /**
     * Functional interface representing a database action or service invocation.
     */
    @FunctionalInterface
    public interface ServiceAction<T> {
        T execute() throws Exception;
    }

    /**
     * Executes a database/service action securely, wrapping exceptions with detailed log outputs.
     * 
     * @param action The ServiceAction lambda block to run.
     * @param successMsg The message to return on successful execution.
     * @param errorMsg The default message to return if execution fails.
     * @param <T> The return type.
     * @return A Result object indicating success or failure status.
     */
    public static <T> Result<T> executeSafely(ServiceAction<T> action, String successMsg, String errorMsg) {
        try {
            T payload = action.execute();
            if (payload instanceof Boolean && !((Boolean) payload)) {
                return new Result<>(false, errorMsg, payload);
            }
            return new Result<>(true, successMsg, payload);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Application exception intercepted: " + e.getMessage(), e);
            return new Result<>(false, errorMsg + ": " + e.getMessage(), null);
        }
    }
}
