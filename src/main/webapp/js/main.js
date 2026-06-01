/* ============================================================================
   ATTENDANCE MANAGEMENT SYSTEM - FRONTEND CORE UTILITIES
   Phase 1 - JavaScript Core Helpers
   File: main.js
   ============================================================================ */

document.addEventListener("DOMContentLoaded", () => {
    // Automatically boot essential layout listeners
    initSidebarToggle();
    startSessionTimer();
    initKeyboardShortcuts();
    
    // Apply page transition class
    document.body.classList.add("page-enter");
});

/**
 * 1. Collapsible Sidebar Layout Module
 * Toggles expanded/collapsed layouts on desktop and absolute drawer placement on mobile.
 */
function initSidebarToggle() {
    const sidebarToggle = document.querySelector(".sidebar-toggle-btn");
    const appWrapper = document.querySelector(".app-wrapper");
    const sidebar = document.querySelector(".sidebar");

    if (sidebarToggle && appWrapper) {
        sidebarToggle.addEventListener("click", (e) => {
            e.stopPropagation();
            if (window.innerWidth <= 768) {
                // Mobile layout drawer toggle
                if (sidebar) {
                    sidebar.classList.toggle("mobile-open");
                }
            } else {
                // Desktop layout collapse toggle
                appWrapper.classList.toggle("collapsed");
            }
        });
    }

    // Close mobile sidebar drawer when clicking outside it
    document.addEventListener("click", (e) => {
        if (window.innerWidth <= 768 && sidebar && sidebar.classList.contains("mobile-open")) {
            if (!sidebar.contains(e.target) && !sidebarToggle.contains(e.target)) {
                sidebar.classList.remove("mobile-open");
            }
        }
    });
}

/**
 * 2. Schema-Driven Reusable Form Validation Helper
 * Validates fields dynamically based on rule schemas and appends visual feedback.
 * 
 * @param {HTMLFormElement} formElement - The form element to validate.
 * @param {Object} schema - Validation schema (e.g. { username: { required: true, minLength: 3 } })
 * @returns {boolean} - True if all fields pass constraints, false otherwise.
 */
function validateForm(formElement, schema) {
    let isValid = true;

    // Reset previous error indicators
    formElement.querySelectorAll(".form-control").forEach(input => {
        input.classList.remove("error");
    });
    formElement.querySelectorAll(".form-error-msg").forEach(msg => {
        msg.remove();
    });

    // Run field level checking
    for (const fieldName in schema) {
        const input = formElement.querySelector(`[name="${fieldName}"]`);
        if (!input) continue;

        const rules = schema[fieldName];
        const val = input.value.trim();
        let fieldError = null;

        // Required check
        if (rules.required && val === "") {
            fieldError = rules.message || `${fieldName.replace("_", " ")} is required.`;
        }
        // Email format check
        else if (rules.email && val !== "") {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(val)) {
                fieldError = rules.message || "Please enter a valid email address.";
            }
        }
        // Min Length check
        else if (rules.minLength && val.length < rules.minLength) {
            fieldError = rules.message || `Must be at least ${rules.minLength} characters.`;
        }
        // Custom regex checking
        else if (rules.pattern && val !== "") {
            if (!rules.pattern.test(val)) {
                fieldError = rules.message || "Invalid format.";
            }
        }

        // If error found, render the message and flag form as invalid
        if (fieldError) {
            isValid = false;
            input.classList.add("error");
            
            const errorLabel = document.createElement("span");
            errorLabel.className = "form-error-msg animate-fade";
            errorLabel.innerText = fieldError;
            
            // Append error element after input container
            input.parentNode.appendChild(errorLabel);
        }
    }

    return isValid;
}

/**
 * 3. Client-Side Real-Time Table Searching & Filtering
 * 
 * @param {string} tableId - ID of the target table element.
 * @param {string} inputId - ID of the search text input.
 * @param {Array<number>} colIndexes - Specific column indexes to search (0-indexed). Search all if empty.
 */
function initTableSearch(tableId, inputId, colIndexes = []) {
    const table = document.getElementById(tableId);
    const searchInput = document.getElementById(inputId);

    if (!table || !searchInput) return;

    searchInput.addEventListener("input", () => {
        const query = searchInput.value.toLowerCase().trim();
        const rows = table.querySelectorAll("tbody tr");

        rows.forEach(row => {
            const cells = row.getElementsByTagName("td");
            let rowMatches = false;

            if (query === "") {
                rowMatches = true;
            } else {
                const targetCells = colIndexes.length > 0 
                    ? colIndexes.map(idx => cells[idx]).filter(Boolean)
                    : Array.from(cells);

                rowMatches = targetCells.some(cell => {
                    return cell.textContent.toLowerCase().includes(query);
                });
            }

            // Adjust display parameter
            row.style.display = rowMatches ? "" : "none";
        });
    });
}

/**
 * 4. Micro Toast Notification System
 * Spawns elegant auto-dismissible visual notifications.
 * 
 * @param {string} message - Notification text content.
 * @param {string} type - Display flavor ('success', 'danger', 'warning', 'info').
 * @param {number} duration - Time visible in milliseconds before fadeout. Defaults to 4000.
 */
function showToast(message, type = "info", duration = 4000) {
    // Find or create toast container
    let container = document.querySelector(".toast-container");
    if (!container) {
        container = document.createElement("div");
        container.className = "toast-container";
        document.body.appendChild(container);
    }

    // Construct toast element
    const toast = document.createElement("div");
    toast.className = `toast toast-${type}`;
    
    // Choose appropriate SVG icon representing types
    let iconSvg = "";
    if (type === "success") {
        iconSvg = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>`;
    } else if (type === "danger") {
        iconSvg = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>`;
    } else if (type === "warning") {
        iconSvg = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>`;
    } else {
        iconSvg = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>`;
    }

    toast.innerHTML = `
        ${iconSvg}
        <span class="toast-message">${message}</span>
        <button class="toast-close">&times;</button>
    `;

    // Append toast node
    container.appendChild(toast);

    // Setup close button action
    const closeBtn = toast.querySelector(".toast-close");
    closeBtn.addEventListener("click", () => {
        dismissToast(toast);
    });

    // Auto-dismiss timeout
    const autoDismissTimer = setTimeout(() => {
        dismissToast(toast);
    }, duration);

    function dismissToast(toastNode) {
        clearTimeout(autoDismissTimer);
        toastNode.style.transform = "translateX(120%)";
        toastNode.style.opacity = "0";
        setTimeout(() => {
            toastNode.remove();
            // Clean container if empty to free up DOM nodes
            if (container.children.length === 0) {
                container.remove();
            }
        }, 300);
    }
}

/**
 * 5. Event-Intercepting Delete Confirmation Dialog
 * Hooks onto links or buttons to double check destructive operations.
 * 
 * @param {Event} event - The triggered DOM event.
 * @param {string} entityName - Description of resource being deleted (e.g. 'Student Alice').
 * @returns {boolean} - True if confirmed, false otherwise.
 */
function confirmDelete(event, entityName = "this item") {
    const confirmation = confirm(`Are you absolutely sure you want to permanently delete ${entityName}?\nThis action cannot be undone.`);
    
    if (!confirmation) {
        event.preventDefault();
        return false;
    }
    return true;
}

/**
 * 6. Phase 6 Additions: Complete form validation library, AJAX helper, session timer & modal
 */
function validateRequired(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return true;
    const val = input.value.trim();
    if (val === "") {
        showFieldError(fieldId, "This field is required.");
        return false;
    }
    clearFieldError(fieldId);
    return true;
}

function validateEmail(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return true;
    const val = input.value.trim();
    if (val === "") return true;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(val)) {
        showFieldError(fieldId, "Please enter a valid email address.");
        return false;
    }
    clearFieldError(fieldId);
    return true;
}

function validatePhone(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return true;
    const val = input.value.trim();
    if (val === "") return true;
    const phoneRegex = /^\+?[0-9\s\-()]{7,15}$/;
    if (!phoneRegex.test(val)) {
        showFieldError(fieldId, "Please enter a valid phone number.");
        return false;
    }
    clearFieldError(fieldId);
    return true;
}

function validateRollNo(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return true;
    const val = input.value.trim();
    if (val === "") return true;
    const rollRegex = /^[a-zA-Z0-9]{1,10}$/;
    if (!rollRegex.test(val)) {
        showFieldError(fieldId, "Roll number must be alphanumeric and max 10 characters.");
        return false;
    }
    clearFieldError(fieldId);
    return true;
}

function validateDate(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return true;
    const val = input.value.trim();
    if (val === "") return true;
    const selectedDate = new Date(val);
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    if (selectedDate > today) {
        showFieldError(fieldId, "Date cannot be in the future.");
        return false;
    }
    clearFieldError(fieldId);
    return true;
}

function showFieldError(fieldId, message) {
    const input = document.getElementById(fieldId);
    if (!input) return;
    input.classList.add("error");
    let errSpan = input.parentNode.querySelector(`.error-${fieldId}`);
    if (!errSpan) {
        errSpan = document.createElement("span");
        errSpan.className = `form-error-msg animate-fade error-${fieldId}`;
        input.parentNode.appendChild(errSpan);
    }
    errSpan.innerText = message;
}

function clearFieldError(fieldId) {
    const input = document.getElementById(fieldId);
    if (!input) return;
    input.classList.remove("error");
    const errSpan = input.parentNode.querySelector(`.error-${fieldId}`);
    if (errSpan) {
        errSpan.remove();
    }
}

function ajaxPost(url, data, onSuccess, onError) {
    const xhr = new XMLHttpRequest();
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    if (onSuccess) onSuccess(response);
                } catch (e) {
                    if (onSuccess) onSuccess(xhr.responseText);
                }
            } else {
                if (onError) onError(xhr.status, xhr.statusText);
            }
        }
    };
    let body = "";
    if (typeof data === "string") {
        body = data;
    } else if (typeof data === "object") {
        body = Object.keys(data)
            .map(key => encodeURIComponent(key) + "=" + encodeURIComponent(data[key]))
            .join("&");
    }
    xhr.send(body);
}

let sessionTimeoutTimer;
function startSessionTimer() {
    clearTimeout(sessionTimeoutTimer);
    sessionTimeoutTimer = setTimeout(showSessionWarningModal, 28 * 60 * 1000); // 28 minutes
}

function showSessionWarningModal() {
    let modal = document.getElementById("session-warning-modal");
    if (!modal) {
        modal = document.createElement("div");
        modal.id = "session-warning-modal";
        modal.className = "modal active";
        modal.style.position = "fixed";
        modal.style.top = "0";
        modal.style.left = "0";
        modal.style.width = "100%";
        modal.style.height = "100%";
        modal.style.backgroundColor = "rgba(0, 0, 0, 0.5)";
        modal.style.display = "flex";
        modal.style.alignItems = "center";
        modal.style.justifyContent = "center";
        modal.style.zIndex = "9999";
        
        const contextPath = window.location.pathname.split('/')[1] || "attendance-management-system";
        
        modal.innerHTML = `
            <div class="card page-enter" style="max-width: 400px; width: 90%; background: var(--bg-card); border-radius: var(--border-radius-md); box-shadow: var(--shadow-lg); padding: 24px;">
                <div class="card-header" style="margin-bottom: 12px;">
                    <h3 class="card-title" style="color: var(--danger); display: flex; align-items: center; gap: 8px;">
                        Session Expiring Soon
                    </h3>
                </div>
                <div class="card-body" style="margin-bottom: 20px;">
                    <p>Your session will expire in 2 minutes due to inactivity. Would you like to remain logged in?</p>
                </div>
                <div class="action-buttons-group" style="display: flex; gap: 12px; justify-content: flex-end;">
                    <button class="btn btn-secondary" onclick="extendSession()">Keep Logged In</button>
                    <a href="/${contextPath}/logout" class="btn btn-danger">Log Out</a>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
    }
}

function extendSession() {
    const contextPath = window.location.pathname.split('/')[1] || "attendance-management-system";
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "/" + contextPath + "/login.jsp", true);
    xhr.send();
    
    const modal = document.getElementById("session-warning-modal");
    if (modal) {
        modal.remove();
    }
    startSessionTimer();
    if (typeof showToast === "function") {
        showToast("Session extended successfully", "success");
    }
}
window.extendSession = extendSession;

function initKeyboardShortcuts() {
    document.addEventListener("keydown", (e) => {
        if (e.ctrlKey && e.key === "f") {
            const searchInput = document.getElementById("searchInput") || document.querySelector(".search-input");
            if (searchInput) {
                e.preventDefault();
                searchInput.focus();
            }
        }
        if (e.key === "Escape") {
            const modal = document.getElementById("session-warning-modal");
            if (modal) {
                modal.remove();
            }
        }
    });
}

