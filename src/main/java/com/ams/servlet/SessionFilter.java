package com.ams.servlet;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * SessionFilter.java
 * Reusable HTTP Filter protecting roles resources from unauthenticated access.
 * 
 * Declared mappings are registered in web.xml or via annotations.
 */
@WebFilter(filterName = "SessionFilter")
public class SessionFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization lifecycle hook
    }

    /**
     * Inspects incoming request URI patterns, checking authentications and roles.
     */
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) 
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        // Prevent browser caching of protected portal pages
        httpResponse.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
        httpResponse.setHeader("Pragma", "no-cache"); // HTTP 1.0
        httpResponse.setDateHeader("Expires", 0); // Proxies

        HttpSession session = httpRequest.getSession(false);
        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();

        boolean loggedIn = (session != null && session.getAttribute("role") != null);
        
        if (!loggedIn) {
            // Unauthenticated user trying to access protected dashboards
            httpResponse.sendRedirect(contextPath + "/login.jsp?error=unauthorized");
            return;
        }

        String role = ((String) session.getAttribute("role")).toUpperCase();

        // 2. Validate role authorization boundaries
        if (requestURI.contains(contextPath + "/admin/") && !"ADMIN".equals(role)) {
            // Non-admin trying to access admin folder
            httpResponse.sendRedirect(contextPath + "/login.jsp?error=forbidden");
            return;
        }
        
        if (requestURI.contains(contextPath + "/teacher/") && !"TEACHER".equals(role)) {
            // Non-teacher trying to access teacher folder
            httpResponse.sendRedirect(contextPath + "/login.jsp?error=forbidden");
            return;
        }
        
        if (requestURI.contains(contextPath + "/student/") && !"STUDENT".equals(role)) {
            // Non-student trying to access student folder
            httpResponse.sendRedirect(contextPath + "/login.jsp?error=forbidden");
            return;
        }

        // Passed checks, proceed to the requested resource
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        // Cleanup lifecycle hook
    }
}
