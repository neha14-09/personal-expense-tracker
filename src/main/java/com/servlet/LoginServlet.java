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

@WebServlet({"/userLogin", "/login"})
public class LoginServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		resp.sendRedirect(req.getContextPath() + "/login.jsp");
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");
		resp.setContentType("text/html;charset=UTF-8");
		resp.setCharacterEncoding("UTF-8");

		String email = req.getParameter("email");
		String password = req.getParameter("password");

		HttpSession session = req.getSession();

		if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
			session.setAttribute("msg", "Please enter both email and password.");
			resp.sendRedirect(req.getContextPath() + "/login.jsp");
			return;
		}

		UserDao dao = new UserDao(HibernateUtil.getSessionFactory());
		User u = dao.login(email.trim(), password);

		if (u == null) {
			session.setAttribute("msg", "Invalid email or password.");
			resp.sendRedirect(req.getContextPath() + "/login.jsp");
		} else {
			session.setAttribute("loginUser", u);
			resp.sendRedirect(req.getContextPath() + "/user/home.jsp");
		}
	}
}
