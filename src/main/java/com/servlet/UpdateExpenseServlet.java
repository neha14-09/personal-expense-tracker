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

@WebServlet({"/updateExpense", "/user/updateExpense"})
public class UpdateExpenseServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("loginUser") : null;

		if (user == null) {
			HttpSession newSession = req.getSession(true);
			newSession.setAttribute("msg", "Please login to access your account.");
			resp.sendRedirect(req.getContextPath() + "/login.jsp");
			return;
		}

		String idStr = req.getParameter("id");
		String title = req.getParameter("title");
		String date = req.getParameter("date");
		String time = req.getParameter("time");
		String description = req.getParameter("description");
		String price = req.getParameter("price");
		String paymentMode = req.getParameter("paymentMode");

		if (idStr == null || idStr.trim().isEmpty()) {
			session.setAttribute("msg", "Invalid expense ID.");
			resp.sendRedirect(req.getContextPath() + "/user/view_expense.jsp");
			return;
		}

		try {
			int id = Integer.parseInt(idStr.trim());
			ExpenseDao dao = new ExpenseDao(HibernateUtil.getSessionFactory());

			// Security ownership check: verify expense belongs to logged-in user
			Expense existing = dao.getExpenseById(id, user.getId());
			if (existing == null) {
				session.setAttribute("msg", "Unauthorized attempt or expense not found.");
				resp.sendRedirect(req.getContextPath() + "/user/view_expense.jsp");
				return;
			}

			existing.setTitle(title != null ? title.trim() : "");
			existing.setDate(date != null ? date.trim() : existing.getDate());
			// Time is optional: retain existing value if no new time is provided
			if (time != null && !time.trim().isEmpty()) {
				existing.setTime(time.trim());
			} else if (existing.getTime() == null) {
				existing.setTime("");
			}
			existing.setDescription(description != null ? description.trim() : "");
			existing.setPrice(price != null ? price.trim() : "");
			existing.setPaymentMode(paymentMode != null && !paymentMode.trim().isEmpty() ? paymentMode.trim() : "Cash");
			existing.setUser(user);

			boolean f = dao.updateExpense(existing);

			if (f) {
				session.setAttribute("msg", "Expense updated successfully!");
			} else {
				session.setAttribute("msg", "Failed to update expense!");
			}
		} catch (Exception e) {
			e.printStackTrace();
			session.setAttribute("msg", "Error processing update.");
		}

		resp.sendRedirect(req.getContextPath() + "/user/view_expense.jsp");
	}
}
