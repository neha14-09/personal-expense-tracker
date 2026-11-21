package com.util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * PasswordUtil provides secure password hashing and verification using BCrypt.
 * 
 * Why BCrypt?
 * 1. BCrypt includes an automatic random salt (preventing Rainbow Table attacks).
 * 2. It has an adjustable work factor (cost) to remain resilient against brute-force attacks.
 * 3. It is a one-way mathematical function; passwords can never be decrypted.
 */
public class PasswordUtil {

    // Cost factor 12 provides strong protection while keeping auth fast (<200ms)
    private static final int BCRYPT_WORK_FACTOR = 12;

    /**
     * Hashes a plain-text password using BCrypt with a secure random salt.
     *
     * @param plainPassword The raw user-supplied password
     * @return The 60-character secure BCrypt hash string
     */
    public static String hashPassword(String plainPassword) {
        if (plainPassword == null || plainPassword.isEmpty()) {
            throw new IllegalArgumentException("Password cannot be null or empty.");
        }
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_WORK_FACTOR));
    }

    /**
     * Verifies an entered plain-text password against a stored BCrypt hash.
     *
     * @param plainPassword The raw user-supplied password at login
     * @param hashedPassword The stored hash from the database
     * @return true if password matches, false otherwise
     */
    public static boolean checkPassword(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null || hashedPassword.isEmpty()) {
            return false;
        }
        try {
            return BCrypt.checkpw(plainPassword, hashedPassword);
        } catch (Exception e) {
            System.err.println("PasswordUtil: Error verifying BCrypt hash: " + e.getMessage());
            return false;
        }
    }

    /**
     * Checks whether a stored password string is already in valid BCrypt format.
     * Standard BCrypt hashes start with $2a$, $2b$, or $2y$, followed by a 2-digit cost,
     * a $, and a 53-character base64 salt and hash (total length 60).
     *
     * @param password The password string stored in database
     * @return true if the string matches the BCrypt format, false if plain-text/legacy
     */
    public static boolean isBCryptHash(String password) {
        if (password == null || password.length() != 60) {
            return false;
        }
        return password.startsWith("$2a$") || password.startsWith("$2b$") || password.startsWith("$2y$");
    }
}
