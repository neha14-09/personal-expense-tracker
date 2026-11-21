<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.entity.User" %>
<%@ page import="com.entity.Expense" %>
<%@ page import="com.dao.ExpenseDao" %>
<%@ page import="com.db.HibernateUtil" %>
<%
    // Prevent browser caching after logout
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User loginUser = (User) session.getAttribute("loginUser");
    if (loginUser == null) {
        session.setAttribute("msg", "Please login to access your account.");
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String idStr = request.getParameter("id");
    Expense ex = null;
    if (idStr != null && !idStr.trim().isEmpty()) {
        try {
            int id = Integer.parseInt(idStr.trim());
            ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());
            ex = dao.getExpenseById(id, loginUser.getId());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    if (ex == null) {
        session.setAttribute("msg", "Expense not found or unauthorized access!");
        response.sendRedirect(request.getContextPath() + "/user/view_expense.jsp");
        return;
    }

    String currentMode = ex.getPaymentMode() != null ? ex.getPaymentMode() : "Cash";
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Edit Expense - Expense Tracker</title>
<%@include file="../component/all_css.jsp" %>
<style type="text/css">
.card-sh {
    box-shadow: 0 0 8px 0 rgba(0, 0, 0, 0.15);
    border-radius: 12px;
}
</style>
</head>
<body class="bg-light">
<%@include file="../component/navbar.jsp" %>

<div class="container p-5">
    <div class="row">
        <div class="col-md-6 offset-md-3">
            <div class="card card-sh">
                <div class="card-header bg-white text-center py-3">
                    <p class="fs-3 mb-0 fw-bold text-primary"><i class="fa-solid fa-pen-to-square"></i> Edit Expense</p>
                </div>
                <div class="card-body p-4">
                    <form action="<%= request.getContextPath() %>/updateExpense" method="post">
                        <input type="hidden" name="id" value="<%= ex.getId() %>">

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-tag text-primary"></i> Title</label> 
                            <input type="text" name="title" class="form-control" value="<%= ex.getTitle() %>" placeholder="e.g. Grocery, Electricity Bill" required>
                        </div>

                        <input type="hidden" name="time" value="<%= (ex.getTime() != null) ? ex.getTime() : "" %>">

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-regular fa-calendar text-primary"></i> Expense Date</label> 
                            <input type="date" name="date" class="form-control" value="<%= ex.getDate() %>" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-wallet text-warning"></i> Payment Mode</label> 
                            <select name="paymentMode" class="form-select" required>
                                <option value="Cash" <%= "Cash".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128181; Cash</option>
                                <option value="Google Pay (UPI)" <%= "Google Pay (UPI)".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128241; Google Pay (UPI)</option>
                                <option value="PhonePe (UPI)" <%= "PhonePe (UPI)".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128241; PhonePe (UPI)</option>
                                <option value="Paytm (UPI)" <%= "Paytm (UPI)".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128241; Paytm (UPI)</option>
                                <option value="Other UPI" <%= "Other UPI".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128241; BHIM / Other UPI</option>
                                <option value="Credit Card" <%= "Credit Card".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128147; Credit Card</option>
                                <option value="Debit Card" <%= "Debit Card".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#128179; Debit Card</option>
                                <option value="Net Banking" <%= "Net Banking".equalsIgnoreCase(currentMode) ? "selected" : "" %>>&#127966; Net Banking</option>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-indian-rupee-sign text-danger"></i> Price (&#8377;)</label> 
                            <input type="number" step="0.01" name="price" class="form-control" value="<%= ex.getPrice() %>" placeholder="0.00" required>
                        </div>

                        <div class="mb-4">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-file-lines text-secondary"></i> Description</label> 
                            <input type="text" name="description" class="form-control" value="<%= (ex.getDescription() != null) ? ex.getDescription() : "" %>" placeholder="Short description (optional)">
                        </div>

                        <button type="submit" class="btn btn-primary col-md-12 mb-2 py-2 fw-semibold shadow-sm"><i class="fa-solid fa-floppy-disk"></i> Update Expense</button>
                        <a href="<%= request.getContextPath() %>/user/view_expense.jsp" class="btn btn-outline-secondary col-md-12 py-2"><i class="fa-solid fa-arrow-left"></i> Cancel</a>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

</body>
</html>
