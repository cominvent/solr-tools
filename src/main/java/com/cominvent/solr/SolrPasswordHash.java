package com.cominvent.solr;

import java.security.SecureRandom;
import java.util.Random;

import org.apache.commons.codec.binary.Base64;
import org.apache.solr.security.Sha256AuthenticationProvider;

public class SolrPasswordHash {
    public static void main(String[] args) {
        String pass;
        String salt;

        if (args.length == 0) {
            System.out.println("Usage: java SolrPasswordHash <password>");
            System.exit(1);
        }

        pass = args[0];
        salt = args.length > 1 ? args[1] : generateRandomSalt();

        System.out.println("Generating password hash for "+pass+" and salt "+salt+":");
        String val = createPasswordHash(args[0], Base64.encodeBase64String(salt.getBytes()));
        System.out.println(val);
        System.out.println("Example usage:\n"+"\"credentials\":{\"myUser\":\""+val+"\"}");
    }

    public static String createPasswordHash(String password, String saltBase64) {
        return Sha256AuthenticationProvider.sha256(password, saltBase64) + " " + saltBase64;
    }

    public static String generateRandomSalt() {
        final Random r = new SecureRandom();
        byte[] salt = new byte[32];
        r.nextBytes(salt);
        return Base64.encodeBase64String(salt);
    }

    public static String base64(String s) {
        return Base64.encodeBase64String(s.getBytes());
    }
}
