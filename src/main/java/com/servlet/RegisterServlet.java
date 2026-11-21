package com.servlet;

import java.io.IOException;

import com.dao.UserDao;
import com.db.HibernateUtil;
import com.entity.User;
import com.util.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/userRegister")
public class RegisterServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		resp.sendRedirect("register.jsp");
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");
		resp.setContentType("text/html;charset=UTF-8");
		resp.setCharacterEncoding("UTF-8");

		String fullname = req.getParameter("fullname");
		String email = req.getParameter("email");
		String password = req.getParameter("password");
		String about = req.getParameter("about");

		HttpSession session = req.getSession();

		if (fullname == null || fullname.trim().isEmpty() ||
			email == null || email.trim().isEmpty() ||
			password == null || password.trim().isEmpty()) {
			session.setAttribute("msg", "Please fill in all required fields.");
			resp.sendRedirect("register.jsp");
			return;
		}

		UserDao dao = new UserDao(HibernateUtil.getSessionFactory());

		if (dao.checkEmail(email.trim())) {
			session.setAttribute("msg", "Email is already registered! Please login.");
			resp.sendRedirect("login.jsp");
			return;
		}

		// Securely hash the plain-text password using BCrypt before storing
		String hashedPassword = PasswordUtil.hashPassword(password.trim());
		User u = new User(fullname.trim(), email.trim(), hashedPassword, about != null ? about.trim() : "");
		boolean f = dao.saveuser(u);

		if (f) {
			session.setAttribute("msg", "User registered successfully! Please login.");
			resp.sendRedirect("login.jsp");
		} else {
			session.setAttribute("msg", "Something went wrong on server!");
			resp.sendRedirect("register.jsp");
		}
	}
}
