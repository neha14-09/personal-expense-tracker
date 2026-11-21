package com.servlet;

import java.io.IOException;

import com.dao.UserDao;
import com.db.HibernateUtil;
import com.entity.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet({"/setMonthlyTarget", "/user/setMonthlyTarget"})
public class SetMonthlyTargetServlet extends HttpServlet {
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

		String targetStr = req.getParameter("target");
		if (targetStr == null || targetStr.trim().isEmpty()) {
			targetStr = req.getParameter("monthlyTarget");
		}

		if (targetStr != null && !targetStr.trim().isEmpty()) {
			try {
				double target = Double.parseDouble(targetStr.trim());
				if (target <= 0) {
					session.setAttribute("msg", "Please enter a valid positive target amount.");
				} else {
					UserDao dao = new UserDao(HibernateUtil.getSessionFactory());
					boolean updated = dao.updateMonthlyTarget(user.getId(), target);
					if (updated) {
						user.setMonthlyTarget(target);
						session.setAttribute("loginUser", user);
						session.setAttribute("msg", "Monthly budget target set to ₹" + String.format("%.2f", target) + " successfully!");
					} else {
						session.setAttribute("msg", "Failed to update monthly target on server.");
					}
				}
			} catch (NumberFormatException e) {
				session.setAttribute("msg", "Invalid number format for budget target.");
			}
		} else {
			session.setAttribute("msg", "Target amount cannot be empty.");
		}

		resp.sendRedirect(req.getContextPath() + "/user/home.jsp");
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		resp.sendRedirect(req.getContextPath() + "/user/home.jsp");
	}
}
