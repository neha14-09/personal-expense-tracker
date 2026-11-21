<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.entity.User" %>
<%@ page import="com.entity.Expense" %>
<%@ page import="com.dao.ExpenseDao" %>
<%@ page import="com.db.HibernateUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.TreeMap" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // 1. Session security & no-cache headers
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User loginUser = (User) session.getAttribute("loginUser");
    if (loginUser == null) {
        session.setAttribute("msg", "Please login to access your account.");
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // 2. Compute analytics in Java/JSP using ExpenseDao and loginUser
    ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());
    List<Expense> allExpenses = dao.getAllExpenseByUser(loginUser);
    if (allExpenses == null) {
        allExpenses = new ArrayList<>();
    }

    SimpleDateFormat yyyyMmFormat = new SimpleDateFormat("yyyy-MM");
    SimpleDateFormat displayMonthFormat = new SimpleDateFormat("MMMM yyyy");
    String currentYearMonth = yyyyMmFormat.format(new java.util.Date());
    String currentMonthName = displayMonthFormat.format(new java.util.Date());

    double totalLifetimeExpense = 0.0;
    int totalCount = allExpenses.size();
    double currentMonthExpense = 0.0;
    double highestExpense = 0.0;

    // Monthly aggregation for Bar Chart (sorted chronologically)
    Map<String, Double> monthlyTotals = new TreeMap<>();
    Map<String, Integer> monthlyCounts = new TreeMap<>();

    // Title / category aggregation
    Map<String, Double> rawTitleTotals = new HashMap<>();

    for (Expense ex : allExpenses) {
        double price = 0.0;
        try {
            if (ex.getPrice() != null && !ex.getPrice().trim().isEmpty()) {
                price = Double.parseDouble(ex.getPrice().trim());
            }
        } catch (Exception ignored) {
            price = 0.0;
        }

        totalLifetimeExpense += price;
        if (price > highestExpense) {
            highestExpense = price;
        }

        String dateStr = ex.getDate();
        if (dateStr != null && dateStr.trim().startsWith(currentYearMonth)) {
            currentMonthExpense += price;
        }

        if (dateStr != null && dateStr.trim().length() >= 7) {
            String monthKey = dateStr.trim().substring(0, 7);
            monthlyTotals.put(monthKey, monthlyTotals.getOrDefault(monthKey, 0.0) + price);
            monthlyCounts.put(monthKey, monthlyCounts.getOrDefault(monthKey, 0) + 1);
        }

        String title = (ex.getTitle() != null && !ex.getTitle().trim().isEmpty())
                ? ex.getTitle().trim()
                : "Uncategorized";
        rawTitleTotals.put(title, rawTitleTotals.getOrDefault(title, 0.0) + price);
    }

    // Top 5 titles, group remainder as "Other"
    List<Map.Entry<String, Double>> sortedTitleEntries = new ArrayList<>(rawTitleTotals.entrySet());
    sortedTitleEntries.sort((a, b) -> Double.compare(b.getValue(), a.getValue()));

    Map<String, Double> titleTotals = new LinkedHashMap<>();
    double otherTotal = 0.0;
    int titleIndex = 0;
    for (Map.Entry<String, Double> entry : sortedTitleEntries) {
        if (titleIndex < 5) {
            titleTotals.put(entry.getKey(), entry.getValue());
        } else {
            otherTotal += entry.getValue();
        }
        titleIndex++;
    }
    if (otherTotal > 0.0) {
        titleTotals.put("Other", otherTotal);
    }

    // Monthly Budget & Target Calculations
    double monthlyTarget = (loginUser.getMonthlyTarget() > 0) ? loginUser.getMonthlyTarget() : 5000.0;
    double percentSpent = (monthlyTarget > 0) ? (currentMonthExpense / monthlyTarget) * 100.0 : 0.0;
    double remainingBudget = monthlyTarget - currentMonthExpense;
    boolean isOverBudget = currentMonthExpense > monthlyTarget;
    boolean isNearBudget = (!isOverBudget && currentMonthExpense >= (0.80 * monthlyTarget));

    // Recent 5 expenses (dao orders by id desc, so first 5 are latest)
    List<Expense> recentExpenses = allExpenses.subList(0, Math.min(5, allExpenses.size()));

    // Reverse chronological months for the Report Table (latest first)
    List<String> sortedMonthsDesc = new ArrayList<>(monthlyTotals.keySet());
    Collections.reverse(sortedMonthsDesc);

    // Prepare JSON arrays for Chart.js
    StringBuilder barLabelsJson = new StringBuilder();
    StringBuilder barDataJson = new StringBuilder();
    StringBuilder barCountsJson = new StringBuilder();
    boolean firstBar = true;
    for (Map.Entry<String, Double> entry : monthlyTotals.entrySet()) {
        if (!firstBar) {
            barLabelsJson.append(",");
            barDataJson.append(",");
            barCountsJson.append(",");
        }
        String mKey = entry.getKey();
        String formattedMonth = mKey;
        try {
            formattedMonth = new SimpleDateFormat("MMM yyyy").format(yyyyMmFormat.parse(mKey));
        } catch (Exception ignored) {}

        barLabelsJson.append("\"").append(formattedMonth).append("\"");
        barDataJson.append(String.format(Locale.US, "%.2f", entry.getValue()));
        barCountsJson.append(monthlyCounts.getOrDefault(entry.getKey(), 0));
        firstBar = false;
    }

    StringBuilder pieLabelsJson = new StringBuilder();
    StringBuilder pieDataJson = new StringBuilder();
    boolean firstPie = true;
    for (Map.Entry<String, Double> entry : titleTotals.entrySet()) {
        if (!firstPie) {
            pieLabelsJson.append(",");
            pieDataJson.append(",");
        }
        String safeTitle = entry.getKey().replace("\\", "\\\\").replace("\"", "\\\"");
        pieLabelsJson.append("\"").append(safeTitle).append("\"");
        pieDataJson.append(String.format(Locale.US, "%.2f", entry.getValue()));
        firstPie = false;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Financial Dashboard - Expense Tracker</title>
<%@include file="../component/all_css.jsp" %>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style type="text/css">
    body {
        background-color: #f4f7f6;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    }

    .card-sh {
        border: none;
        border-radius: 12px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.06);
        background-color: #ffffff;
    }

    .stat-card {
        border-radius: 12px;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        border: 1px solid rgba(0, 0, 0, 0.05);
    }

    .stat-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.09);
    }

    .border-left-green {
        border-left: 5px solid #198754 !important;
    }

    .border-left-blue {
        border-left: 5px solid #0d6efd !important;
    }

    .border-left-purple {
        border-left: 5px solid #6f42c1 !important;
    }

    .border-left-orange {
        border-left: 5px solid #fd7e14 !important;
    }

    .icon-shape {
        width: 52px;
        height: 52px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }

    .icon-green {
        background-color: rgba(25, 135, 84, 0.12);
        color: #198754;
    }

    .icon-blue {
        background-color: rgba(13, 110, 253, 0.12);
        color: #0d6efd;
    }

    .icon-purple {
        background-color: rgba(111, 66, 193, 0.12);
        color: #6f42c1;
    }

    .icon-orange {
        background-color: rgba(253, 126, 20, 0.12);
        color: #fd7e14;
    }

    .chart-container {
        position: relative;
        min-height: 290px;
    }

    .table thead th {
        font-weight: 600;
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    @media print {
        .navbar, .quick-actions, .no-print, .btn-action {
            display: none !important;
        }
        body {
            background-color: #ffffff;
        }
        .card-sh, .stat-card {
            box-shadow: none !important;
            border: 1px solid #ddd !important;
        }
    }
</style>
</head>
<body>

<%@include file="../component/navbar.jsp" %>

<div class="container-fluid px-4 py-4">

    <!-- Flash message -->
    <%
        String msg = (String) session.getAttribute("msg");
        if (msg != null) {
            String alertClass = msg.toLowerCase().contains("success") ? "alert-success" : "alert-danger";
    %>
        <div class="alert <%= alertClass %> alert-dismissible fade show text-center mb-4 no-print shadow-sm" role="alert">
            <i class="fa-solid <%= msg.toLowerCase().contains("success") ? "fa-circle-check" : "fa-circle-exclamation" %> me-2"></i>
            <%= msg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    <%
            session.removeAttribute("msg");
        }
    %>

    <!-- Header Section with Greeting and Quick Actions -->
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center pb-3 mb-4 border-bottom">
        <div class="mb-3 mb-md-0">
            <h2 class="h3 fw-bold text-dark mb-1">
                Financial Dashboard - Welcome back, <%= loginUser.getName() %>
            </h2>
            <p class="text-muted mb-0 small">
                <i class="fa-regular fa-clock me-1"></i> Snapshot for <%= currentMonthName %> &bull; Track spending, manage your monthly target, and stay on budget.
            </p>
        </div>
        <div class="quick-actions d-flex flex-wrap gap-2">
            <button type="button" class="btn btn-outline-primary shadow-sm" data-bs-toggle="modal" data-bs-target="#targetModal">
                <i class="fa-solid fa-bullseye me-1"></i> Set Monthly Target
            </button>
            <a href="<%= request.getContextPath() %>/user/add_expense.jsp" class="btn btn-success shadow-sm">
                <i class="fa-solid fa-plus-circle me-1"></i> Add Expense
            </a>
            <a href="<%= request.getContextPath() %>/user/view_expense.jsp" class="btn btn-outline-success shadow-sm">
                <i class="fa-solid fa-magnifying-glass me-1"></i> View & Search
            </a>
            <button type="button" onclick="window.print()" class="btn btn-outline-secondary shadow-sm">
                <i class="fa-solid fa-print me-1"></i> Print / Save PDF
            </button>
        </div>
    </div>

    <!-- Monthly Target & Overspending Reminder Banner -->
    <% if (isOverBudget) { %>
        <div class="alert alert-danger shadow-sm border-2 border-danger d-flex flex-column flex-md-row align-items-md-center justify-content-between p-3 mb-4 no-print" role="alert">
            <div class="d-flex align-items-center mb-2 mb-md-0">
                <i class="fa-solid fa-triangle-exclamation fa-2x text-danger me-3"></i>
                <div>
                    <h5 class="alert-heading fw-bold mb-1 text-danger">
                        <i class="fa-solid fa-bell me-1"></i> Overspending Reminder: Expenses are High this Month!
                    </h5>
                    <p class="mb-0 text-dark">
                        Your expenses for <strong><%= currentMonthName %></strong> have reached 
                        <strong class="text-danger">&#8377; <%= String.format(Locale.US, "%,.2f", currentMonthExpense) %></strong>, 
                        which crosses your monthly target of <strong>&#8377; <%= String.format(Locale.US, "%,.2f", monthlyTarget) %></strong> by 
                        <span class="badge bg-danger">&#8377; <%= String.format(Locale.US, "%,.2f", Math.abs(remainingBudget)) %> extra</span> 
                        (<%= String.format(Locale.US, "%.1f", percentSpent) %>% spent). 
                        <strong>You have to save some money and control your spending!</strong>
                    </p>
                </div>
            </div>
            <button type="button" class="btn btn-danger btn-sm text-nowrap ms-md-3" data-bs-toggle="modal" data-bs-target="#targetModal">
                <i class="fa-solid fa-sliders me-1"></i> Adjust Target
            </button>
        </div>
    <% } else if (isNearBudget) { %>
        <div class="alert alert-warning shadow-sm border-2 border-warning d-flex flex-column flex-md-row align-items-md-center justify-content-between p-3 mb-4 no-print" role="alert">
            <div class="d-flex align-items-center mb-2 mb-md-0">
                <i class="fa-solid fa-triangle-exclamation fa-2x text-warning me-3"></i>
                <div>
                    <h5 class="alert-heading fw-bold mb-1 text-dark">
                        <i class="fa-solid fa-bell me-1"></i> Caution: Approaching Your Monthly Target Limit!
                    </h5>
                    <p class="mb-0 text-dark">
                        You have already spent <strong><%= String.format(Locale.US, "%.1f", percentSpent) %>%</strong> of your monthly target (&#8377; <%= String.format(Locale.US, "%,.2f", currentMonthExpense) %> of &#8377; <%= String.format(Locale.US, "%,.2f", monthlyTarget) %>). 
                        Only <strong>&#8377; <%= String.format(Locale.US, "%,.2f", remainingBudget) %></strong> remains for <%= currentMonthName %>. Please keep an eye on upcoming expenses.
                    </p>
                </div>
            </div>
            <button type="button" class="btn btn-warning btn-sm text-nowrap ms-md-3" data-bs-toggle="modal" data-bs-target="#targetModal">
                <i class="fa-solid fa-sliders me-1"></i> Adjust Target
            </button>
        </div>
    <% } else { %>
        <div class="alert alert-success bg-white shadow-sm border-1 border-success d-flex flex-column flex-md-row align-items-md-center justify-content-between p-3 mb-4 no-print" role="alert">
            <div class="d-flex align-items-center mb-2 mb-md-0">
                <i class="fa-solid fa-circle-check fa-2x text-success me-3"></i>
                <div>
                    <h6 class="fw-bold text-success mb-1">
                        <i class="fa-solid fa-shield-heart me-1"></i> Monthly Budget on Track
                    </h6>
                    <p class="mb-0 small text-muted">
                        You have spent <strong>&#8377; <%= String.format(Locale.US, "%,.2f", currentMonthExpense) %></strong> out of your <strong>&#8377; <%= String.format(Locale.US, "%,.2f", monthlyTarget) %></strong> target (<%= String.format(Locale.US, "%.1f", percentSpent) %>% used). 
                        Safe balance remaining: <strong class="text-success">&#8377; <%= String.format(Locale.US, "%,.2f", remainingBudget) %></strong> for <%= currentMonthName %>. Good job saving money!
                    </p>
                </div>
            </div>
            <button type="button" class="btn btn-outline-success btn-sm text-nowrap ms-md-3" data-bs-toggle="modal" data-bs-target="#targetModal">
                <i class="fa-solid fa-sliders me-1"></i> Set Target
            </button>
        </div>
    <% } %>

    <!-- Monthly Target Progress Card -->
    <div class="card card-sh mb-4 p-3 border-0">
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-2">
            <div>
                <span class="text-uppercase fw-bold small text-muted"><i class="fa-solid fa-bullseye text-primary me-1"></i> Monthly Target Progress</span>
                <span class="ms-2 badge <%= isOverBudget ? "bg-danger" : (isNearBudget ? "bg-warning text-dark" : "bg-success") %>">
                    <%= isOverBudget ? "Exceeded" : (isNearBudget ? "Caution" : "On Track") %>
                </span>
            </div>
            <div class="small fw-semibold mt-1 mt-md-0">
                Target: &#8377; <%= String.format(Locale.US, "%,.2f", monthlyTarget) %> &bull; 
                Spent: &#8377; <%= String.format(Locale.US, "%,.2f", currentMonthExpense) %> &bull; 
                <span class="<%= isOverBudget ? "text-danger" : "text-success" %>">
                    <%= isOverBudget ? "Over by: &#8377; " + String.format(Locale.US, "%,.2f", Math.abs(remainingBudget)) : "Remaining: &#8377; " + String.format(Locale.US, "%,.2f", remainingBudget) %>
                </span>
            </div>
        </div>
        <div class="progress" style="height: 14px;">
            <div class="progress-bar <%= isOverBudget ? "bg-danger progress-bar-striped progress-bar-animated" : (isNearBudget ? "bg-warning" : "bg-success") %>" 
                 role="progressbar" 
                 style="width: <%= Math.min(100.0, percentSpent) %>%;" 
                 aria-valuenow="<%= percentSpent %>" 
                 aria-valuemin="0" 
                 aria-valuemax="100">
                <%= String.format(Locale.US, "%.1f", percentSpent) %>%
            </div>
        </div>
    </div>

    <!-- 4 Stat Cards in a row -->
    <div class="row g-3 mb-4">
        <!-- 1. Total Lifetime Expense (Green Theme) -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="card card-sh stat-card border-left-green h-100 p-3">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-muted text-uppercase fw-bold small">Total Lifetime</span>
                        <h3 class="fw-bold text-dark my-1">&#8377; <%= String.format(Locale.US, "%,.2f", totalLifetimeExpense) %></h3>
                        <div class="small text-muted"><i class="fa-solid fa-chart-line text-success me-1"></i> Cumulative spending</div>
                    </div>
                    <div class="icon-shape icon-green shadow-sm">
                        <i class="fa-solid fa-wallet"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- 2. This Month's Expenses (Blue Theme) -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="card card-sh stat-card border-left-blue h-100 p-3">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-muted text-uppercase fw-bold small">This Month</span>
                        <h3 class="fw-bold text-dark my-1">&#8377; <%= String.format(Locale.US, "%,.2f", currentMonthExpense) %></h3>
                        <div class="small text-muted"><i class="fa-regular fa-calendar me-1 text-primary"></i> <%= currentMonthName %></div>
                    </div>
                    <div class="icon-shape icon-blue shadow-sm">
                        <i class="fa-solid fa-calendar-check"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- 3. Total Transactions (Purple Theme) -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="card card-sh stat-card border-left-purple h-100 p-3">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-muted text-uppercase fw-bold small">Transactions</span>
                        <h3 class="fw-bold text-dark my-1"><%= totalCount %></h3>
                        <div class="small text-muted"><i class="fa-solid fa-receipt text-purple me-1"></i> Total logged items</div>
                    </div>
                    <div class="icon-shape icon-purple shadow-sm">
                        <i class="fa-solid fa-file-invoice-dollar"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- 4. Monthly Target (Orange Theme) -->
        <div class="col-12 col-sm-6 col-xl-3">
            <div class="card card-sh stat-card border-left-orange h-100 p-3">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <span class="text-muted text-uppercase fw-bold small">Monthly Target</span>
                        <h3 class="fw-bold text-dark my-1">&#8377; <%= String.format(Locale.US, "%,.2f", monthlyTarget) %></h3>
                        <div class="small <%= isOverBudget ? "text-danger fw-semibold" : "text-muted" %>">
                            <i class="fa-solid fa-bullseye text-warning me-1"></i> <%= isOverBudget ? "Exceeded by ₹" + String.format(Locale.US, "%,.2f", Math.abs(remainingBudget)) : "Safe Limit" %>
                        </div>
                    </div>
                    <div class="icon-shape icon-orange shadow-sm">
                        <i class="fa-solid fa-bullseye"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Graphical Representation Row -->
    <div class="row g-4 mb-4">
        <!-- Left (col-md-7): Bar Chart canvas showing Monthly Expense Trend -->
        <div class="col-lg-7">
            <div class="card card-sh h-100">
                <div class="card-header bg-white py-3 border-0 d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title fw-bold text-dark mb-0">
                            <i class="fa-solid fa-chart-column text-primary me-2"></i> Monthly Expense Trend
                        </h5>
                        <small class="text-muted">Month-by-month spending analysis</small>
                    </div>
                    <span class="badge bg-primary bg-opacity-10 text-primary px-3 py-2 rounded-pill">
                        <%= monthlyTotals.size() %> <%= monthlyTotals.size() == 1 ? "Month" : "Months" %>
                    </span>
                </div>
                <div class="card-body">
                    <% if (monthlyTotals.isEmpty()) { %>
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-chart-column fa-3x mb-3 text-secondary opacity-50"></i>
                            <h6 class="fw-semibold">No Monthly Data Available</h6>
                            <p class="small mb-0">Add expenses to visualize your monthly trends over time.</p>
                        </div>
                        <canvas id="monthlyBarChart" class="d-none"></canvas>
                    <% } else { %>
                        <div class="chart-container">
                            <canvas id="monthlyBarChart" style="max-height: 290px; width: 100%;"></canvas>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Right (col-md-5): Doughnut / Pie Chart canvas showing Expense Distribution by Title -->
        <div class="col-lg-5">
            <div class="card card-sh h-100">
                <div class="card-header bg-white py-3 border-0 d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title fw-bold text-dark mb-0">
                            <i class="fa-solid fa-chart-pie text-success me-2"></i> Expense Distribution
                        </h5>
                        <small class="text-muted">Top 5 categories & remaining grouped</small>
                    </div>
                    <span class="badge bg-success bg-opacity-10 text-success px-3 py-2 rounded-pill">
                        <%= titleTotals.size() %> Categories
                    </span>
                </div>
                <div class="card-body">
                    <% if (titleTotals.isEmpty()) { %>
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-chart-pie fa-3x mb-3 text-secondary opacity-50"></i>
                            <h6 class="fw-semibold">No Category Data Available</h6>
                            <p class="small mb-0">Add expenses to visualize category spending distribution.</p>
                        </div>
                        <canvas id="expensePieChart" class="d-none"></canvas>
                    <% } else { %>
                        <div class="chart-container">
                            <canvas id="expensePieChart" style="max-height: 290px; width: 100%;"></canvas>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <!-- Reports Row -->
    <div class="row g-4">
        <!-- Left (col-md-7): Monthly Expense Report Table -->
        <div class="col-lg-7">
            <div class="card card-sh h-100">
                <div class="card-header bg-white py-3 border-0 d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title fw-bold text-dark mb-0">
                            <i class="fa-solid fa-table-list text-info me-2"></i> Monthly Expense Report
                        </h5>
                        <small class="text-muted">Aggregated summary per billing period</small>
                    </div>
                </div>
                <div class="card-body p-0">
                    <% if (sortedMonthsDesc.isEmpty()) { %>
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-receipt fa-3x mb-3 text-secondary opacity-50"></i>
                            <h6 class="fw-semibold">No Monthly Records</h6>
                            <p class="small mb-0">Transactions will appear aggregated here once added.</p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th scope="col" class="ps-3">Month</th>
                                        <th scope="col" class="text-center">Transactions</th>
                                        <th scope="col" class="text-end">Total Spent (&#8377;)</th>
                                        <th scope="col" class="text-end pe-3">Avg / Txn (&#8377;)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        for (String mKey : sortedMonthsDesc) {
                                            double mTotal = monthlyTotals.getOrDefault(mKey, 0.0);
                                            int mCount = monthlyCounts.getOrDefault(mKey, 0);
                                            double mAvg = (mCount > 0) ? (mTotal / mCount) : 0.0;

                                            String prettyMonth = mKey;
                                            try {
                                                prettyMonth = new SimpleDateFormat("MMMM yyyy").format(yyyyMmFormat.parse(mKey));
                                            } catch (Exception ignored) {}
                                    %>
                                    <tr>
                                        <td class="ps-3 fw-semibold text-dark">
                                            <i class="fa-regular fa-calendar-days text-primary me-2"></i><%= prettyMonth %>
                                            <small class="text-muted d-block ps-4"><%= mKey %></small>
                                        </td>
                                        <td class="text-center">
                                            <span class="badge bg-secondary bg-opacity-10 text-dark px-2 py-1">
                                                <%= mCount %> items
                                            </span>
                                        </td>
                                        <td class="text-end fw-bold text-dark">
                                            &#8377; <%= String.format(Locale.US, "%,.2f", mTotal) %>
                                        </td>
                                        <td class="text-end pe-3 text-muted">
                                            &#8377; <%= String.format(Locale.US, "%,.2f", mAvg) %>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Right (col-md-5): Recent 5 Expenses Table with Payment Mode Badge -->
        <div class="col-lg-5">
            <div class="card card-sh h-100">
                <div class="card-header bg-white py-3 border-0 d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title fw-bold text-dark mb-0">
                            <i class="fa-solid fa-clock-rotate-left text-warning me-2"></i> Recent Expenses
                        </h5>
                        <small class="text-muted">Last 5 logged transactions</small>
                    </div>
                    <a href="<%= request.getContextPath() %>/user/view_expense.jsp" class="btn btn-sm btn-link text-decoration-none fw-semibold">
                        View All <i class="fa-solid fa-arrow-right ms-1"></i>
                    </a>
                </div>
                <div class="card-body p-0">
                    <% if (recentExpenses.isEmpty()) { %>
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-basket-shopping fa-3x mb-3 text-secondary opacity-50"></i>
                            <h6 class="fw-semibold">No Recent Expenses</h6>
                            <p class="small mb-3">You haven't recorded any expenses yet.</p>
                            <a href="<%= request.getContextPath() %>/user/add_expense.jsp" class="btn btn-sm btn-success">
                                <i class="fa-solid fa-plus me-1"></i> Add First Expense
                            </a>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th scope="col" class="ps-3">Expense</th>
                                        <th scope="col">Mode</th>
                                        <th scope="col" class="text-end">Amount (&#8377;)</th>
                                        <th scope="col" class="text-center pe-3" style="width: 90px;">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        for (Expense ex : recentExpenses) {
                                            double priceVal = 0.0;
                                            try {
                                                if (ex.getPrice() != null && !ex.getPrice().trim().isEmpty()) {
                                                    priceVal = Double.parseDouble(ex.getPrice().trim());
                                                }
                                            } catch (Exception ignored) {}

                                            String pMode = (ex.getPaymentMode() != null && !ex.getPaymentMode().trim().isEmpty())
                                                    ? ex.getPaymentMode().trim()
                                                    : "Cash";
                                            String badgeClass = "bg-secondary";
                                            if (pMode.toLowerCase().contains("upi") || pMode.toLowerCase().contains("pay")) {
                                                badgeClass = "bg-info text-dark";
                                            } else if (pMode.equalsIgnoreCase("cash")) {
                                                badgeClass = "bg-success";
                                            } else if (pMode.toLowerCase().contains("card")) {
                                                badgeClass = "bg-warning text-dark";
                                            }
                                    %>
                                    <tr>
                                        <td class="ps-3">
                                            <div class="fw-semibold text-dark text-truncate" style="max-width: 150px;" title="<%= ex.getTitle() %>">
                                                <%= ex.getTitle() %>
                                            </div>
                                            <div class="small text-muted">
                                                <i class="fa-regular fa-clock me-1"></i><%= ex.getDate() %>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge <%= badgeClass %>" style="font-size: 0.75rem;">
                                                <%= pMode %>
                                            </span>
                                        </td>
                                        <td class="text-end fw-bold text-danger text-nowrap">
                                            &#8377; <%= String.format(Locale.US, "%,.2f", priceVal) %>
                                        </td>
                                        <td class="text-center pe-3 text-nowrap">
                                            <a href="<%= request.getContextPath() %>/user/edit_expense.jsp?id=<%= ex.getId() %>" 
                                               class="btn btn-sm btn-outline-primary py-0 px-2 btn-action" 
                                               title="Edit">
                                                <i class="fa-solid fa-pen-to-square"></i>
                                            </a>
                                            <a href="<%= request.getContextPath() %>/deleteExpense?id=<%= ex.getId() %>" 
                                               class="btn btn-sm btn-outline-danger py-0 px-2 ms-1 btn-action" 
                                               onclick="return confirm('Are you sure you want to delete this expense?');" 
                                               title="Delete">
                                                <i class="fa-solid fa-trash"></i>
                                            </a>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

</div>

<!-- Modal to Set / Update Monthly Target -->
<div class="modal fade" id="targetModal" tabindex="-1" aria-labelledby="targetModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content shadow border-0 rounded-3">
      <form action="<%= request.getContextPath() %>/setMonthlyTarget" method="post">
        <div class="modal-header bg-light">
          <h5 class="modal-title fw-bold text-dark" id="targetModalLabel">
            <i class="fa-solid fa-bullseye text-primary me-2"></i> Set Monthly Target Budget
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body p-4">
          <p class="text-muted small">
            Set your target spending budget per month (e.g., <strong>₹5,000</strong> to <strong>₹6,000</strong>). 
            If your expenses in the current month cross this target, your dashboard will alert you to save money.
          </p>
          <div class="mb-3">
            <label class="form-label fw-semibold">Monthly Target Amount (&#8377;)</label>
            <div class="input-group">
                <span class="input-group-text">&#8377;</span>
                <input type="number" step="100" min="500" name="target" class="form-control" value="<%= (long) monthlyTarget %>" placeholder="e.g. 5000 or 6000" required>
            </div>
            <div class="form-text">Common targets: &#8377;5,000, &#8377;6,000, or &#8377;10,000.</div>
          </div>
        </div>
        <div class="modal-footer bg-light">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary fw-semibold"><i class="fa-solid fa-check me-1"></i> Save Target</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- Chart.js Initialization Script -->
<script>
document.addEventListener("DOMContentLoaded", function() {
    // 1. Monthly Expense Trend Bar Chart
    const barLabels = [<%= barLabelsJson.toString() %>];
    const barData = [<%= barDataJson.toString() %>];
    const barCounts = [<%= barCountsJson.toString() %>];

    const barCanvas = document.getElementById('monthlyBarChart');
    if (barCanvas && barLabels.length > 0) {
        const ctxBar = barCanvas.getContext('2d');
        new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: barLabels,
                datasets: [{
                    label: 'Monthly Spending (₹)',
                    data: barData,
                    backgroundColor: 'rgba(13, 110, 253, 0.75)',
                    hoverBackgroundColor: 'rgba(13, 110, 253, 0.95)',
                    borderColor: 'rgba(13, 110, 253, 1)',
                    borderWidth: 1.5,
                    borderRadius: 6,
                    maxBarThickness: 45
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: 'rgba(33, 37, 41, 0.9)',
                        padding: 10,
                        titleFont: { size: 13, weight: 'bold' },
                        bodyFont: { size: 12 },
                        callbacks: {
                            label: function(context) {
                                const val = Number(context.raw || 0).toLocaleString('en-IN', {
                                    minimumFractionDigits: 2,
                                    maximumFractionDigits: 2
                                });
                                const count = barCounts[context.dataIndex] || 0;
                                return ' Total: ₹ ' + val + ' (' + count + ' txns)';
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(value) {
                                return '₹ ' + Number(value).toLocaleString('en-IN');
                            }
                        },
                        grid: {
                            color: 'rgba(0, 0, 0, 0.05)'
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                }
            }
        });
    }

    // 2. Title / Category Expense Distribution Doughnut Chart
    const pieLabels = [<%= pieLabelsJson.toString() %>];
    const pieData = [<%= pieDataJson.toString() %>];

    const pieCanvas = document.getElementById('expensePieChart');
    if (pieCanvas && pieLabels.length > 0) {
        const ctxPie = pieCanvas.getContext('2d');
        const palette = [
            '#198754', '#0d6efd', '#6f42c1', '#fd7e14', '#20c997',
            '#dc3545', '#0dcaf0', '#ffc107', '#6c757d'
        ];

        new Chart(ctxPie, {
            type: 'doughnut',
            data: {
                labels: pieLabels,
                datasets: [{
                    data: pieData,
                    backgroundColor: palette.slice(0, pieLabels.length),
                    hoverOffset: 8,
                    borderWidth: 2,
                    borderColor: '#ffffff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            boxWidth: 12,
                            padding: 12,
                            font: { size: 11 }
                        }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(33, 37, 41, 0.9)',
                        padding: 10,
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const val = Number(context.raw || 0).toLocaleString('en-IN', {
                                    minimumFractionDigits: 2,
                                    maximumFractionDigits: 2
                                });
                                const total = context.chart._metasets[context.datasetIndex].total || 1;
                                const pct = ((context.raw / total) * 100).toFixed(1);
                                return ' ' + label + ': ₹ ' + val + ' (' + pct + '%)';
                            }
                        }
                    }
                },
                cutout: '62%'
            }
        });
    }
});
</script>

</body>
</html>
