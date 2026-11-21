package com.servlet;

import java.io.IOException;

import com.dao.ExpenseDao;
import com.db.HibernateUtil;
import com.entity.Expense;
import com.entity.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet({"/saveExpense", "/user/saveExpense"})
public class SaveExpenseServlet extends HttpServlet {

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		HttpSession session = req.getSession();
		User user = (User) session.getAttribute("loginUser");

		if (user == null) {
			session.setAttribute("msg", "Please login first to add expenses!");
			resp.sendRedirect(req.getContextPath() + "/login.jsp");
			return;
		}

		String title = req.getParameter("title");
		if (title == null || title.trim().isEmpty()) {
			title = req.getParameter("tittle");
		}
		String date = req.getParameter("date");
		String time = req.getParameter("time");
		if (time == null) {
			time = ""; // Time is no longer required from frontend form
		}
		String description = req.getParameter("description");
		String price = req.getParameter("price");
		String paymentMode = req.getParameter("paymentMode");
		if (paymentMode == null || paymentMode.trim().isEmpty()) {
			paymentMode = "Cash";
		}

		if (date == null || date.trim().isEmpty()) {
			session.setAttribute("msg", "Please provide a valid expense date.");
			resp.sendRedirect(req.getContextPath() + "/user/add_expense.jsp");
			return;
		}

		Expense ex = new Expense(
			title != null ? title.trim() : "",
			date != null ? date.trim() : "",
			time != null ? time.trim() : "",
			description != null ? description.trim() : "",
			price != null ? price.trim() : "",
			paymentMode != null ? paymentMode.trim() : "Cash",
			user
		);

		ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());
		boolean f = dao.saveExpense(ex);

		if (f) {
			session.setAttribute("msg", "Expense added successfully!");
		} else {
			session.setAttribute("msg", "Something went wrong on server!");
		}
		resp.sendRedirect(req.getContextPath() + "/user/add_expense.jsp");
	}
}
