<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.entity.User" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User loginUser = (User) session.getAttribute("loginUser");
    if (loginUser == null) {
        session.setAttribute("msg", "Please login to access your account.");
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Add Expense - Expense Tracker</title>
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
                    <p class="fs-3 mb-0 fw-bold text-success"><i class="fa-solid fa-circle-plus"></i> Add Expense</p>
                </div>
                <div class="card-body p-4">
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

                    <form action="<%= request.getContextPath() %>/saveExpense" method="post">
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-tag text-success"></i> Title</label> 
                            <input type="text" name="title" class="form-control" placeholder="e.g. Grocery, Electricity Bill, Movie" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-regular fa-calendar text-primary"></i> Expense Date</label> 
                            <input type="date" name="date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-wallet text-warning"></i> Payment Mode</label> 
                            <select name="paymentMode" class="form-select" required>
                                <option value="" disabled selected>-- Select Payment Mode --</option>
                                <option value="Cash">&#128181; Cash</option>
                                <option value="Google Pay (UPI)">&#128241; Google Pay (UPI)</option>
                                <option value="PhonePe (UPI)">&#128241; PhonePe (UPI)</option>
                                <option value="Paytm (UPI)">&#128241; Paytm (UPI)</option>
                                <option value="Other UPI">&#128241; BHIM / Other UPI</option>
                                <option value="Credit Card">&#128147; Credit Card</option>
                                <option value="Debit Card">&#128179; Debit Card</option>
                                <option value="Net Banking">&#127966; Net Banking</option>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-indian-rupee-sign text-danger"></i> Price (&#8377;)</label> 
                            <input type="number" step="0.01" name="price" class="form-control" placeholder="0.00" required>
                        </div>

                        <div class="mb-4">
                            <label class="form-label fw-semibold"><i class="fa-solid fa-file-lines text-secondary"></i> Description</label> 
                            <input type="text" name="description" class="form-control" placeholder="Short description or notes (optional)">
                        </div>

                        <button type="submit" class="btn btn-success col-md-12 py-2 fw-semibold shadow-sm">
                            <i class="fa-solid fa-check"></i> Save Expense
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

</body>
</html>
