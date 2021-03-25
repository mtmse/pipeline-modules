package org.daisy.pipeline.tts.cereproc.impl.util;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Locale;
import java.util.Optional;

public class CereprocTTSUtil {

    private Optional<Locale> locale;
    RegexReplace regexReplace;
    UCharReplacer charReplacer;

    public CereprocTTSUtil(Optional<Locale> locale) {
        this.locale = locale;
        initRegexRules();
        initCharSubstitutionRules();
    }

    private void initRegexRules() {
        URL url;
        File t;

        String lang  = getCurrentLangauge();

        if (lang == "sv") {
            String swedish_cereproc_rulesets = "src/main/java/regex/cereproc_sv.xml";
            t = new File(swedish_cereproc_rulesets);
        } else if (lang == "en") {
            String english_cereproc_rulesets = "src/main/java/regex/cereproc_en.xml";
            t = new File(english_cereproc_rulesets);
        } else {
            return;
        }

        try {
            url = t.toURI().toURL();
        } catch (MalformedURLException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }

        this.regexReplace = new RegexReplace(url);
    }

    private void initCharSubstitutionRules() {
        this.charReplacer =  charReplacer = new UCharReplacer();
        File commonSubstRulesFile = new File("src/main/java/charsubst/character-translation-table.xml");
        try {
            this.charReplacer.addSubstitutionTable(commonSubstRulesFile.toURI().toURL());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        String lang  = getCurrentLangauge();

        File languageSubstRulesFile;
        if (lang == "sv") {
            languageSubstRulesFile = new File("src/main/java/charsubst/character-translation-table_sv.xml");
        } else if (lang == "en") {
            languageSubstRulesFile = new File("src/main/java/charsubst/character-translation-table_en.xml");
        } else {
            return;
        }

        try {
            this.charReplacer.addSubstitutionTable(languageSubstRulesFile.toURI().toURL());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public String applyRegex(String text) {
        return this.regexReplace.filter(text);
    }

    public String applyCharacterSubstitution(String text){
        return this.charReplacer.replace(text).toString();
    }

    private String getCurrentLangauge() {

        if (this.locale.isEmpty()){
            return "";
        } else {
            return this.locale.get().getLanguage();
        }
    }
}
