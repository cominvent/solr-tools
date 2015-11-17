package com.cominvent.solr;

import org.junit.Test;

import static org.junit.Assert.*;

/**
 * Testing basic behavior
 */
public class SolrPasswordHashTest {
    @Test
    public void testCreatePasswordHash() {
        assertEquals("HZtl83vopLyZfOpGedEQveAwvVdAQ1Ukr6dDJPEfs/w= MTIz", SolrPasswordHash.createPasswordHash("admin", "MTIz"));
    }

    @Test
    public void testGenerateRandomSalt() throws Exception {
        assertTrue(SolrPasswordHash.generateRandomSalt().length() > 0);
    }

    @Test
    public void testBase64() throws Exception {
        assertEquals("MTIz", SolrPasswordHash.base64("123"));
    }
}