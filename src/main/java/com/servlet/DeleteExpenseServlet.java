package com.servlet;

import java.io.IOException;

import com.dao.ExpenseDao;
import com.db.HibernateUtil;
import com.entity.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet({"/deleteExpense", "/user/deleteExpense"})
public class DeleteExpenseServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("loginUser") : null;

		if (user == null) {
			HttpSession newSession = req.getSession(true);
			newSession.setAttribute("msg", "Please login to access your account.");
			resp.sendRedirect(req.getContextPath() + "/login.jsp");
			return;
		}

		String idStr = req.getParameter("id");
		if (idStr != null && !idStr.trim().isEmpty()) {
			try {
				int id = Integer.parseInt(idStr.trim());
				ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());
				boolean f = dao.deleteExpense(id, user.getId());

				if (f) {
					session.setAttribute("msg", "Expense deleted successfully!");
				} else {
					session.setAttribute("msg", "Action failed: unauthorized or expense not found.");
				}
			} catch (Exception e) {
				e.printStackTrace();
				session.setAttribute("msg", "Invalid expense ID!");
			}
		}

		resp.sendRedirect(req.getContextPath() + "/user/view_expense.jsp");
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		doGet(req, resp);
	}
}
