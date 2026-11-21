package com.dao;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.hibernate.query.Query;

import com.entity.User;
import com.util.PasswordUtil;

public class UserDao {

    private SessionFactory factory;

    public UserDao(SessionFactory factory) {
        this.factory = factory;
    }

    public boolean saveuser(User user) {
        boolean f = false;
        Transaction tx = null;
        Session session = null;

        try {
            if (factory == null) {
                System.err.println("UserDao: SessionFactory is null. Check database connection/configuration.");
                return false;
            }

            session = factory.openSession();
            tx = session.beginTransaction();

            session.persist(user);

            tx.commit();
            f = true;

        } catch (Exception e) {
            if (tx != null && tx.isActive()) {
                tx.rollback();
            }
            e.printStackTrace();
        } finally {
            if (session != null && session.isOpen()) {
                session.close();
            }
        }

        return f;
    }

    public boolean checkEmail(String email) {
        boolean exists = false;
        Session session = null;

        try {
            if (factory == null) return false;
            session = factory.openSession();
            Query<Long> q = session.createQuery("SELECT COUNT(u) FROM User u WHERE u.email = :em", Long.class);
            q.setParameter("em", email);
            Long count = q.uniqueResult();
            if (count != null && count > 0) {
                exists = true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (session != null && session.isOpen()) {
                session.close();
            }
        }

        return exists;
    }

    public User login(String email, String password) {
        User u = null;
        Session session = null;

        try {
            if (factory == null) {
                System.err.println("UserDao: SessionFactory is null. Check database connection/configuration.");
                return null;
            }

            session = factory.openSession();
            Query<User> q = session.createQuery("from User where email = :em", User.class);
            q.setParameter("em", email);
            q.setMaxResults(1);

            User candidate = q.uniqueResult();
            if (candidate != null && candidate.getPassword() != null) {
                String storedPassword = candidate.getPassword();

                if (PasswordUtil.isBCryptHash(storedPassword)) {
                    // Password is already a secure BCrypt hash: verify securely
                    if (PasswordUtil.checkPassword(password, storedPassword)) {
                        u = candidate;
                    }
                } else {
                    // Legacy user: plain-text password in database
                    // Verify plain-text match first
                    if (storedPassword.equals(password)) {
                        // Match found! Automatically migrate legacy plain-text password to BCrypt
                        Transaction tx = null;
                        try {
                            tx = session.beginTransaction();
                            String upgradedHash = PasswordUtil.hashPassword(password);
                            candidate.setPassword(upgradedHash);
                            session.merge(candidate);
                            tx.commit();
                            System.out.println("UserDao: Seamlessly migrated legacy password to BCrypt for user: " + email);
                        } catch (Exception migEx) {
                            if (tx != null && tx.isActive()) {
                                tx.rollback();
                            }
                            System.err.println("UserDao: Failed to save migrated BCrypt password for user: " + email);
                            migEx.printStackTrace();
                        }
                        u = candidate;
                    }
                }
            }

        } catch (Exception e) {
            System.err.println("UserDao: Error during user login for email: " + email);
            e.printStackTrace();
        } finally {
            if (session != null && session.isOpen()) {
                session.close();
            }
        }

        return u;
    }

    public User getUserById(int userId) {
        User u = null;
        Session session = null;
        try {
            if (factory == null) return null;
            session = factory.openSession();
            u = session.get(User.class, userId);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (session != null && session.isOpen()) {
                session.close();
            }
        }
        return u;
    }

    public boolean updateMonthlyTarget(int userId, double target) {
        boolean f = false;
        Transaction tx = null;
        Session session = null;
        try {
            if (factory == null) return false;
            session = factory.openSession();
            tx = session.beginTransaction();
            User u = session.get(User.class, userId);
            if (u != null) {
                u.setMonthlyTarget(target);
                session.merge(u);
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
}
