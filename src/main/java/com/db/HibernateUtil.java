package com.db;

import java.util.Properties;

import org.hibernate.SessionFactory;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.cfg.AvailableSettings;
import org.hibernate.cfg.Configuration;
import org.hibernate.service.ServiceRegistry;

import com.entity.Expense;
import com.entity.User;
import com.util.AppConfig;

public class HibernateUtil {

    private static SessionFactory sessionFactory;

    public static SessionFactory getSessionFactory() {
        if (sessionFactory == null) {
            try {
                Configuration configuration = new Configuration();

                Properties properties = new Properties();

                // Load database credentials and settings securely from environment variables / .env
                String driver = AppConfig.get("DB_DRIVER", "com.mysql.cj.jdbc.Driver");
                String url = AppConfig.getRequired("DB_URL");
                String user = AppConfig.getRequired("DB_USER");
                String password = AppConfig.getRequired("DB_PASSWORD");
                String dialect = AppConfig.get("HIBERNATE_DIALECT", "org.hibernate.dialect.MySQLDialect");
                String hbm2ddl = AppConfig.get("HIBERNATE_HBM2DDL_AUTO", "update");
                String showSql = AppConfig.get("HIBERNATE_SHOW_SQL", "true");

                properties.put(AvailableSettings.JAKARTA_JDBC_DRIVER, driver);
                properties.put(AvailableSettings.JAKARTA_JDBC_URL, url);
                properties.put(AvailableSettings.JAKARTA_JDBC_USER, user);
                properties.put(AvailableSettings.JAKARTA_JDBC_PASSWORD, password);
                properties.put(AvailableSettings.DIALECT, dialect);
                properties.put(AvailableSettings.HBM2DDL_AUTO, hbm2ddl);
                properties.put(AvailableSettings.SHOW_SQL, showSql);

                configuration.setProperties(properties);
                configuration.addAnnotatedClass(User.class);
                configuration.addAnnotatedClass(Expense.class);
                

                ServiceRegistry serviceRegistry = new StandardServiceRegistryBuilder()
                        .applySettings(configuration.getProperties())
                        .build();

                sessionFactory = configuration.buildSessionFactory(serviceRegistry);
            } catch (Exception e) {
                System.err.println("HibernateUtil: Failed to initialize SessionFactory!");
                e.printStackTrace();
            }
        }
        return sessionFactory;
    }
}
