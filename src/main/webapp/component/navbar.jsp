<%@ page pageEncoding="UTF-8"%>
<%@ page import="com.entity.User"%>
<%
    String uri = request.getRequestURI();
    String contextPath = request.getContextPath();
    User navUser = (User) session.getAttribute("loginUser");
%>
<nav class="navbar navbar-expand-lg navbar-dark bg-success">
  <div class="container-fluid">
    <a class="navbar-brand" href="<%= contextPath %>/index.jsp"><i class="fa-solid fa-money-check"></i> Expense Tracker</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <% if (navUser == null) { %>
        <li class="nav-item">
          <a class="nav-link <%= (uri != null && (uri.endsWith("index.jsp") || uri.endsWith("/Expense_Tracker/"))) ? "active" : "" %>" href="<%= contextPath %>/index.jsp"><i class="fa-solid fa-house"></i> Home</a>
        </li>
        <% } else { %>
        <li class="nav-item">
          <a class="nav-link <%= (uri != null && uri.endsWith("home.jsp")) ? "active" : "" %>" href="<%= contextPath %>/user/home.jsp"><i class="fa-solid fa-chart-line"></i> Dashboard</a>
        </li>
        <li class="nav-item">
          <a class="nav-link <%= (uri != null && uri.endsWith("add_expense.jsp")) ? "active" : "" %>" href="<%= contextPath %>/user/add_expense.jsp"><i class="fa-solid fa-plus"></i> Add Expense</a>
        </li>
        <li class="nav-item">
          <a class="nav-link <%= (uri != null && uri.endsWith("view_expense.jsp")) ? "active" : "" %>" href="<%= contextPath %>/user/view_expense.jsp"><i class="fa-solid fa-magnifying-glass"></i> View & Search</a>
        </li>
        <% } %>
      </ul>
      
      <ul class="navbar-nav ms-auto mb-2 mb-lg-0">
        <% if (navUser == null) { %>
            <li class="nav-item">
              <a class="nav-link <%= (uri != null && uri.endsWith("login.jsp")) ? "active" : "" %>" href="<%= contextPath %>/login.jsp"><i class="fa-solid fa-right-to-bracket"></i> Login</a>
            </li>
            <li class="nav-item">
              <a class="nav-link <%= (uri != null && uri.endsWith("register.jsp")) ? "active" : "" %>" href="<%= contextPath %>/register.jsp"><i class="fa-solid fa-user-plus"></i> Register</a>
            </li>
        <% } else { %>
            <li class="nav-item">
              <a class="nav-link <%= (uri != null && uri.endsWith("home.jsp")) ? "active" : "" %>" href="<%= contextPath %>/user/home.jsp"><i class="fa-solid fa-user"></i> <%= navUser.getName() %></a>
            </li>
            <li class="nav-item">
              <a class="nav-link text-white" href="<%= contextPath %>/userLogout"><i class="fa-solid fa-right-from-bracket"></i> Logout</a>
            </li>
        <% } %>
      </ul>
    </div>
  </div>
</nav>
