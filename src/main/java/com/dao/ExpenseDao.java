package com.dao;

import java.util.ArrayList;
import java.util.List;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.Query;

import com.entity.Expense;
import com.entity.User;

public class ExpenseDao {
	private SessionFactory factory;

	public ExpenseDao(SessionFactory factory) {
		super();
		this.factory = factory;
	}

	public boolean saveExpense(Expense ex) {
		boolean f = false;
		Session session = null;
		Transaction tx = null;
		try {
			if (factory == null) return false;
			session = factory.openSession();
			tx = session.beginTransaction();

			if (ex.getUser() != null && ex.getUser().getId() > 0) {
				User managedUser = session.get(User.class, ex.getUser().getId());
				if (managedUser != null) {
					ex.setUser(managedUser);
				}
			}

			session.persist(ex);
			tx.commit();
			f = true;
		} catch (Exception e) {
			if (tx != null && tx.isActive()) {
				try {
					tx.rollback();
				} catch (Exception rbEx) {
					rbEx.printStackTrace();
				}
			}
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return f;
	}

	public List<Expense> getAllExpenseByUser(User user) {
		List<Expense> list = new ArrayList<>();
		Session session = null;
		try {
			if (factory == null || user == null) {
				return list;
			}
			session = factory.openSession();
			Query<Expense> q = session.createQuery("from Expense where user = :us order by id desc", Expense.class);
			q.setParameter("us", user);
			list = q.list();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return list;
	}

	public List<Expense> searchExpenses(User user, String keyword, String startDate, String endDate) {
		return searchExpenses(user, keyword, startDate, endDate, null);
	}

	public List<Expense> searchExpenses(User user, String keyword, String startDate, String endDate, String paymentMode) {
		List<Expense> list = new ArrayList<>();
		Session session = null;
		try {
			if (factory == null || user == null) {
				return list;
			}
			session = factory.openSession();

			StringBuilder hql = new StringBuilder("from Expense where user = :us");
			boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
			boolean hasStartDate = startDate != null && !startDate.trim().isEmpty();
			boolean hasEndDate = endDate != null && !endDate.trim().isEmpty();
			boolean hasPaymentMode = paymentMode != null && !paymentMode.trim().isEmpty();

			if (hasKeyword) {
				hql.append(" and (lower(title) like :kw or lower(description) like :kw)");
			}
			if (hasStartDate) {
				hql.append(" and date >= :startDate");
			}
			if (hasEndDate) {
				hql.append(" and date <= :endDate");
			}
			if (hasPaymentMode) {
				hql.append(" and paymentMode = :pm");
			}

			hql.append(" order by date desc, id desc");

			Query<Expense> q = session.createQuery(hql.toString(), Expense.class);
			q.setParameter("us", user);

			if (hasKeyword) {
				q.setParameter("kw", "%" + keyword.trim().toLowerCase() + "%");
			}
			if (hasStartDate) {
				q.setParameter("startDate", startDate.trim());
			}
			if (hasEndDate) {
				q.setParameter("endDate", endDate.trim());
			}
			if (hasPaymentMode) {
				q.setParameter("pm", paymentMode.trim());
			}

			list = q.list();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return list;
	}

	public double getTotalExpenseByUser(User user) {
		List<Expense> list = getAllExpenseByUser(user);
		double total = 0.0;
		if (list != null) {
			for (Expense ex : list) {
				try {
					if (ex.getPrice() != null && !ex.getPrice().trim().isEmpty()) {
						total += Double.parseDouble(ex.getPrice().trim());
					}
				} catch (Exception ignored) {
				}
			}
		}
		return total;
	}

	public Expense getExpenseById(int id) {
		Expense ex = null;
		Session session = null;
		try {
			if (factory == null) return null;
			session = factory.openSession();
			Query<Expense> q = session.createQuery("from Expense where id = :id", Expense.class);
			q.setParameter("id", id);
			ex = q.uniqueResult();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return ex;
	}

	public Expense getExpenseById(int id, int userId) {
		Expense ex = null;
		Session session = null;
		try {
			if (factory == null) return null;
			session = factory.openSession();
			Query<Expense> q = session.createQuery("from Expense where id = :id and user.id = :uid", Expense.class);
			q.setParameter("id", id);
			q.setParameter("uid", userId);
			ex = q.uniqueResult();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return ex;
	}

	public boolean updateExpense(Expense ex) {
		boolean f = false;
		Session session = null;
		Transaction tx = null;
		try {
			if (factory == null) return false;
			session = factory.openSession();
			tx = session.beginTransaction();

			if (ex.getUser() != null && ex.getUser().getId() > 0) {
				User managedUser = session.get(User.class, ex.getUser().getId());
				if (managedUser != null) {
					ex.setUser(managedUser);
				}
			}

			session.merge(ex);
			tx.commit();
			f = true;
		} catch (Exception e) {
			if (tx != null && tx.isActive()) {
				try {
					tx.rollback();
				} catch (Exception rbEx) {
					rbEx.printStackTrace();
				}
			}
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return f;
	}

	public boolean deleteExpense(int id) {
		boolean f = false;
		Session session = null;
		Transaction tx = null;
		try {
			if (factory == null) return false;
			session = factory.openSession();
			tx = session.beginTransaction();
			Expense ex = session.get(Expense.class, id);
			if (ex != null) {
				session.remove(ex);
				tx.commit();
				f = true;
			}
		} catch (Exception e) {
			if (tx != null && tx.isActive()) {
				try {
					tx.rollback();
				} catch (Exception rbEx) {
					rbEx.printStackTrace();
				}
			}
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return f;
	}

	public boolean deleteExpense(int id, int userId) {
		boolean f = false;
		Session session = null;
		Transaction tx = null;
		try {
			if (factory == null) return false;
			session = factory.openSession();
			tx = session.beginTransaction();
			Expense ex = session.get(Expense.class, id);
			if (ex != null && ex.getUser() != null && ex.getUser().getId() == userId) {
				session.remove(ex);
				tx.commit();
				f = true;
			} else {
				if (tx != null && tx.isActive()) {
					tx.rollback();
				}
			}
		} catch (Exception e) {
			if (tx != null && tx.isActive()) {
				try {
					tx.rollback();
				} catch (Exception rbEx) {
					rbEx.printStackTrace();
				}
			}
			e.printStackTrace();
		} finally {
			if (session != null && session.isOpen()) {
				session.close();
			}
		}
		return f;
	}
}
