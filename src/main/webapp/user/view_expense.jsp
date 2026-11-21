<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.entity.User" %>
<%@ page import="com.entity.Expense" %>
<%@ page import="com.dao.ExpenseDao" %>
<%@ page import="com.db.HibernateUtil" %>
<%@ page import="java.util.List" %>
<%
    // Prevent browser caching after logout so back-button does not show expenses
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User loginUser = (User) session.getAttribute("loginUser");
    if (loginUser == null) {
        session.setAttribute("msg", "Please login to access your account.");
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String keyword = request.getParameter("keyword");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    String paymentMode = request.getParameter("paymentMode");

    boolean isFiltered = (keyword != null && !keyword.trim().isEmpty())
            || (startDate != null && !startDate.trim().isEmpty())
            || (endDate != null && !endDate.trim().isEmpty())
            || (paymentMode != null && !paymentMode.trim().isEmpty());

    ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());
    List<Expense> list;
    if (isFiltered) {
        list = dao.searchExpenses(loginUser, keyword, startDate, endDate, paymentMode);
    } else {
        list = dao.getAllExpenseByUser(loginUser);
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>View & Search Expenses - Expense Tracker</title>
<%@include file="../component/all_css.jsp" %>
<style type="text/css">
.card-sh {
    box-shadow: 0 0 8px 0 rgba(0, 0, 0, 0.15);
    border-radius: 12px;
}
.filter-card {
    background-color: #f8fafc;
    border: 1px solid #e2e8f0;
}
</style>
</head>
<body class="bg-light">
<%@include file="../component/navbar.jsp" %>

<div class="container p-4">

    <!-- Search & Filter Bar -->
    <div class="card card-sh filter-card mb-4">
        <div class="card-body">
            <form action="<%= request.getContextPath() %>/user/view_expense.jsp" method="get" class="row g-3 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold"><i class="fa-solid fa-magnifying-glass text-success"></i> Search Keyword</label>
                    <input type="text" name="keyword" class="form-control" placeholder="Title or description..." value="<%= (keyword != null) ? keyword : "" %>">
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold"><i class="fa-solid fa-wallet text-warning"></i> Payment Mode</label>
                    <select name="paymentMode" class="form-select">
                        <option value="">All Modes</option>
                        <option value="Cash" <%= "Cash".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Cash</option>
                        <option value="Google Pay (UPI)" <%= "Google Pay (UPI)".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Google Pay (UPI)</option>
                        <option value="PhonePe (UPI)" <%= "PhonePe (UPI)".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>PhonePe (UPI)</option>
                        <option value="Paytm (UPI)" <%= "Paytm (UPI)".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Paytm (UPI)</option>
                        <option value="Other UPI" <%= "Other UPI".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Other UPI</option>
                        <option value="Credit Card" <%= "Credit Card".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Credit Card</option>
                        <option value="Debit Card" <%= "Debit Card".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Debit Card</option>
                        <option value="Net Banking" <%= "Net Banking".equalsIgnoreCase(paymentMode) ? "selected" : "" %>>Net Banking</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold"><i class="fa-solid fa-calendar-day text-primary"></i> From Date</label>
                    <input type="date" name="startDate" class="form-control" value="<%= (startDate != null) ? startDate : "" %>">
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold"><i class="fa-solid fa-calendar-check text-primary"></i> To Date</label>
                    <input type="date" name="endDate" class="form-control" value="<%= (endDate != null) ? endDate : "" %>">
                </div>
                <div class="col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-success flex-fill"><i class="fa-solid fa-filter"></i> Filter</button>
                    <% if (isFiltered) { %>
                        <a href="<%= request.getContextPath() %>/user/view_expense.jsp" class="btn btn-outline-secondary" title="Clear Filters"><i class="fa-solid fa-rotate-left"></i> Reset</a>
                    <% } %>
                </div>
            </form>
        </div>
    </div>

    <!-- Expense Table Card -->
    <div class="card card-sh">
        <div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
            <div>
                <h4 class="mb-0 text-success"><i class="fa-solid fa-receipt"></i> Expenses List</h4>
                <% if (isFiltered) { %>
                    <small class="text-muted">Showing filtered search results</small>
                <% } else { %>
                    <small class="text-muted">Showing all your recorded expenses</small>
                <% } %>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/user/home.jsp" class="btn btn-sm btn-outline-primary me-2">
                    <i class="fa-solid fa-chart-line"></i> Dashboard
                </a>
                <a href="<%= request.getContextPath() %>/user/add_expense.jsp" class="btn btn-sm btn-success">
                    <i class="fa-solid fa-plus"></i> Add Expense
                </a>
            </div>
        </div>
        <div class="card-body">
            <%
                String msg = (String) session.getAttribute("msg");
                if (msg != null) {
                    String alertClass = msg.toLowerCase().contains("success") ? "alert-success" : "alert-danger";
            %>
                <div class="alert <%= alertClass %> alert-dismissible fade show text-center" role="alert">
                    <%= msg %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <%
                    session.removeAttribute("msg");
                }
            %>

            <%
                if (list == null || list.isEmpty()) {
            %>
                <div class="text-center py-5">
                    <i class="fa-solid fa-receipt fa-4x text-muted mb-3"></i>
                    <% if (isFiltered) { %>
                        <h5 class="text-secondary">No matching expenses found!</h5>
                        <p class="text-muted">No expenses match your search query or filters.</p>
                        <a href="<%= request.getContextPath() %>/user/view_expense.jsp" class="btn btn-outline-secondary">
                            <i class="fa-solid fa-rotate-left"></i> Clear Filters
                        </a>
                    <% } else { %>
                        <h5 class="text-secondary">No expenses found!</h5>
                        <p class="text-muted">You haven't recorded any expenses yet.</p>
                        <a href="<%= request.getContextPath() %>/user/add_expense.jsp" class="btn btn-outline-success">
                            <i class="fa-solid fa-plus"></i> Add Your First Expense
                        </a>
                    <% } %>
                </div>
            <%
                } else {
                    double total = 0.0;
            %>
                <div class="table-responsive">
                    <table class="table table-striped table-hover align-middle">
                        <thead class="table-success">
                            <tr>
                                <th scope="col" style="width: 50px;">#</th>
                                <th scope="col">Title</th>
                                <th scope="col">Date</th>
                                <th scope="col">Payment Mode</th>
                                <th scope="col">Description</th>
                                <th scope="col" class="text-end">Price (&#8377;)</th>
                                <th scope="col" class="text-center" style="width: 180px;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                int count = 1;
                                for (Expense ex : list) {
                                    try {
                                        total += Double.parseDouble(ex.getPrice());
                                    } catch (Exception ignored) {}

                                    String pMode = (ex.getPaymentMode() != null && !ex.getPaymentMode().trim().isEmpty())
                                            ? ex.getPaymentMode().trim()
                                            : "Cash";

                                    String badgeClass = "bg-secondary";
                                    String icon = "fa-money-bill";
                                    if (pMode.toLowerCase().contains("upi") || pMode.toLowerCase().contains("pay")) {
                                        badgeClass = "bg-info text-dark";
                                        icon = "fa-mobile-screen-button";
                                    } else if (pMode.equalsIgnoreCase("cash")) {
                                        badgeClass = "bg-success";
                                        icon = "fa-money-bill-wave";
                                    } else if (pMode.toLowerCase().contains("card")) {
                                        badgeClass = "bg-warning text-dark";
                                        icon = "fa-credit-card";
                                    } else if (pMode.toLowerCase().contains("bank")) {
                                        badgeClass = "bg-primary";
                                        icon = "fa-building-columns";
                                    }
                            %>
                            <tr>
                                <th scope="row"><%= count++ %></th>
                                <td class="fw-semibold"><%= ex.getTitle() %></td>
                                <td>
                                    <i class="fa-regular fa-calendar text-primary me-1"></i><%= ex.getDate() %>
                                    <% if (ex.getTime() != null && !ex.getTime().trim().isEmpty()) { %>
                                        <small class="text-muted d-block ps-3"><i class="fa-regular fa-clock me-1"></i><%= ex.getTime() %></small>
                                    <% } %>
                                </td>
                                <td>
                                    <span class="badge <%= badgeClass %> px-2 py-1">
                                        <i class="fa-solid <%= icon %> me-1"></i> <%= pMode %>
                                    </span>
                                </td>
                                <td><%= (ex.getDescription() != null && !ex.getDescription().trim().isEmpty()) ? ex.getDescription() : "<span class='text-muted'>-</span>" %></td>
                                <td class="text-end fw-bold text-success">&#8377; <%= ex.getPrice() %></td>
                                <td class="text-center">
                                    <a href="<%= request.getContextPath() %>/user/edit_expense.jsp?id=<%= ex.getId() %>" class="btn btn-sm btn-primary me-1">
                                        <i class="fa-solid fa-pen-to-square"></i> Edit
                                    </a>
                                    <a href="<%= request.getContextPath() %>/deleteExpense?id=<%= ex.getId() %>" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure you want to delete this expense?');">
                                        <i class="fa-solid fa-trash"></i> Delete
                                    </a>
                                </td>
                            </tr>
                            <%
                                }
                            %>
                        </tbody>
                        <tfoot class="table-light">
                            <tr>
                                <td colspan="5" class="text-end fw-bold fs-6">
                                    <% if (isFiltered) { %>
                                        Filtered Total (<%= list.size() %> items):
                                    <% } else { %>
                                        Total Amount (<%= list.size() %> items):
                                    <% } %>
                                </td>
                                <td class="text-end fw-bold fs-6 text-danger">&#8377; <%= String.format("%.2f", total) %></td>
                                <td></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            <%
                }
            %>
        </div>
    </div>
</div>

</body>
</html>
