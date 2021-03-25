package org.daisy.pipeline.tts.cereproc.impl.util;

import java.net.MalformedURLException;
import java.util.Locale;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CereprocTTSUtilTest {

    CereprocTTSUtilTest(){
    }

    @org.junit.jupiter.api.Test
    void testApplyRegexForSwedish() throws MalformedURLException {
         CereprocTTSUtil ttsutil = new CereprocTTSUtil(new Locale("sv"));

        assertEquals("lorem ipsum Tjugosjunde kapitlet. lorem ipsum", ttsutil.applyRegex("lorem ipsum 27 kap. lorem ipsum"));
        assertEquals("test roman letter  tre", ttsutil.applyRegex("test roman letter III"));

    }

    @org.junit.jupiter.api.Test
    void testApplyRegexForEnglish() throws MalformedURLException {
        CereprocTTSUtil ttsutil = new CereprocTTSUtil(new Locale("en"));

        assertEquals("test roman letter  three", ttsutil.applyRegex("test roman letter III"));
        assertEquals("This apartment is 25  square centimeters big", ttsutil.applyRegex("This apartment is 25 cm2 big"));
    }

    @org.junit.jupiter.api.Test
    void applyCharacterSubstitutionForSwedish() throws MalformedURLException {
        CereprocTTSUtil ttsutil = new CereprocTTSUtil(new Locale("sv"));

        // Swedish rules
        assertEquals("Greek letter  beta  beta", ttsutil.applyCharacterSubstitution("Greek letter β beta"));
        // Common rules
        assertEquals(" \" -  (", ttsutil.applyCharacterSubstitution(" ” —  ₍"));
    }

    @org.junit.jupiter.api.Test
    void applyCharacterSubstitutionForEnglish() throws MalformedURLException {
        CereprocTTSUtil ttsutil = new CereprocTTSUtil(new Locale("en"));

        // English rules
        assertEquals("capital gamma  capital gamma ", ttsutil.applyCharacterSubstitution("capital gamma Γ"));
        // Common rules
        assertEquals(" \" -  (", ttsutil.applyCharacterSubstitution(" ” —  ₍"));
    }
}