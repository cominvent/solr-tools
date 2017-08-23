/*
 * Copyright 2017 Cominvent AS
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.cominvent.solr;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Random;

import org.apache.commons.codec.binary.Base64;

public class SolrPasswordHash {
    public static void main(String[] args) {
        String pass;
        String salt;

        if (args.length == 0) {
            System.out.println("Usage: java SolrPasswordHash <password> [<salt>]");
            System.exit(1);
        }

        pass = args[0];
        salt = args.length > 1 ? args[1] : generateRandomSalt();

        System.out.println("Generating password hash for password "+pass+" and salt "+salt+":");
        String val = createPasswordHash(args[0], Base64.encodeBase64String(salt.getBytes()));
        System.out.println(val);
        System.out.println("Example usage:\n"+"\"credentials\":{\"myUser\":\""+val+"\"}");
    }

    public static String createPasswordHash(String password, String saltBase64) {
        return sha256(password, saltBase64) + " " + saltBase64;
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

    /**
     * Copied from org.apache.solr.security.Sha256AuthenticationProvider
     */
    public static String sha256(String password, String saltKey) {
      MessageDigest digest;
      try {
        digest = MessageDigest.getInstance("SHA-256");
      } catch (NoSuchAlgorithmException e) {
        return null;//should not happen
      }
      if (saltKey != null) {
        digest.reset();
        digest.update(Base64.decodeBase64(saltKey));
      }

      byte[] btPass = digest.digest(password.getBytes(StandardCharsets.UTF_8));
      digest.reset();
      btPass = digest.digest(btPass);
      return Base64.encodeBase64String(btPass);
    }
}
