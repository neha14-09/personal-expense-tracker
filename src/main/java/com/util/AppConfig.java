package com.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * AppConfig reads configuration values and sensitive credentials securely.
 * 
 * Order of precedence:
 * 1. OS Environment Variables (System.getenv)
 * 2. JVM System Properties (System.getProperty)
 * 3. Local '.env' file (project root, working directory, or classpath)
 * 
 * Important: Fallback passwords or secrets are never hardcoded here.
 * If a required secret is missing, an explicit IllegalStateException is thrown.
 */
public class AppConfig {

    private static final Map<String, String> ENV_VARS = new HashMap<>();

    static {
        loadDotEnv();
    }

    private static void loadDotEnv() {
        // Try locating .env in several common locations
        InputStream is = null;
        try {
            // 1. Current working directory .env
            File file = new File(".env");
            if (file.exists() && file.isFile()) {
                is = new FileInputStream(file);
            }

            // 2. user.dir .env
            if (is == null) {
                String userDir = System.getProperty("user.dir");
                if (userDir != null) {
                    File userDirFile = new File(userDir, ".env");
                    if (userDirFile.exists() && userDirFile.isFile()) {
                        is = new FileInputStream(userDirFile);
                    }
                }
            }

            // 3. Classpath .env (e.g., packaged in WEB-INF/classes or src/main/resources)
            if (is == null) {
                is = AppConfig.class.getResourceAsStream("/.env");
                if (is == null) {
                    ClassLoader cl = Thread.currentThread().getContextClassLoader();
                    if (cl != null) {
                        is = cl.getResourceAsStream(".env");
                    }
                }
            }

            if (is != null) {
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        line = line.trim();
                        // Skip empty lines and comments
                        if (line.isEmpty() || line.startsWith("#")) {
                            continue;
                        }
                        int eqIdx = line.indexOf('=');
                        if (eqIdx > 0) {
                            String key = line.substring(0, eqIdx).trim();
                            String value = line.substring(eqIdx + 1).trim();

                            // Strip surrounding single or double quotes if present
                            if ((value.startsWith("\"") && value.endsWith("\"")) ||
                                (value.startsWith("'") && value.endsWith("'"))) {
                                if (value.length() >= 2) {
                                    value = value.substring(1, value.length() - 1);
                                }
                            }
                            ENV_VARS.put(key, value);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("AppConfig: Notice - Could not load .env file: " + e.getMessage());
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (Exception ignored) {
                }
            }
        }
    }

    /**
     * Retrieves a configuration value by key.
     * Checks OS environment variables, JVM properties, then .env entries.
     *
     * @param key The environment variable key (e.g., "DB_PASSWORD")
     * @return The configured value, or null if not found.
     */
    public static String get(String key) {
        if (key == null || key.trim().isEmpty()) {
            return null;
        }

        // 1. OS Environment variable
        String envVal = System.getenv(key);
        if (envVal != null && !envVal.trim().isEmpty()) {
            return envVal.trim();
        }

        // 2. JVM System Property
        String propVal = System.getProperty(key);
        if (propVal != null && !propVal.trim().isEmpty()) {
            return propVal.trim();
        }

        // 3. .env map
        String dotEnvVal = ENV_VARS.get(key);
        if (dotEnvVal != null && !dotEnvVal.trim().isEmpty()) {
            return dotEnvVal.trim();
        }

        return null;
    }

    /**
     * Retrieves a configuration value with a default fallback (for non-sensitive settings).
     *
     * @param key The environment variable key
     * @param defaultValue The fallback to use if not configured
     * @return The configured value or the defaultValue
     */
    public static String get(String key, String defaultValue) {
        String val = get(key);
        return (val != null && !val.trim().isEmpty()) ? val : defaultValue;
    }

    /**
     * Retrieves a REQUIRED configuration value (like passwords and database credentials).
     * Throws IllegalStateException if the value is missing.
     *
     * @param key The environment variable key
     * @return The non-empty configuration value
     * @throws IllegalStateException If the key is not defined anywhere
     */
    public static String getRequired(String key) {
        String val = get(key);
        if (val == null || val.trim().isEmpty()) {
            throw new IllegalStateException(
                "CRITICAL CONFIGURATION ERROR: Required configuration key '" + key + 
                "' is missing! Please configure it as an environment variable or define it in your '.env' file."
            );
        }
        return val;
    }
}
