<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Login - Expense Tracker</title>
<%@include file="component/all_css.jsp" %>
<style type="text/css">
.card-sh {
    box-shadow: 0 0 6px 0 rgba(0, 0, 0, 0.3);
}
</style>
</head>
<body class="bg-light">
<%@include file="component/navbar.jsp" %>
<div class="container p-5">
    <div class="row">
        <div class="col-md-6 offset-md-3">
            <div class="card card-sh">
                <div class="card-header text-center">
                    <p class="fs-3 mb-0">Login Page</p>
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

                    <form action="userLogin" method="post">
                        <div class="mb-3">
                            <label class="form-label">Email</label> 
                            <input type="email" name="email" class="form-control" placeholder="Enter email" autocomplete="email" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Password</label> 
                            <input type="password" name="password" class="form-control" placeholder="Enter password" autocomplete="current-password" required>
                        </div>

                        <button type="submit" class="btn btn-success col-md-12">Login</button>
                        
                        <div class="text-center mt-3">
                            Don't have an account? <a href="register.jsp" class="text-decoration-none">Create one</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

</body>
</html>
