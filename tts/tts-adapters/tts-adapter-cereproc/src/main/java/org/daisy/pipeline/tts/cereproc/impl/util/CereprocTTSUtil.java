package org.daisy.pipeline.tts.cereproc.impl.util;

import java.io.IOException;
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

        String lang  = getCurrentLanguage();
        if (lang.equals("sv")) {
            url = CereprocTTSUtil.class.getResource("/regex/cereproc_sv.xml");
        } else if (lang.equals("en")) {
            url = CereprocTTSUtil.class.getResource("/regex/cereproc_en.xml");
        } else {
            return;
        }

        this.regexReplace = new RegexReplace(url);
    }

    private void initCharSubstitutionRules() {
        this.charReplacer = new UCharReplacer();
        URL commonSubstRulesFileUrl = CereprocTTSUtil.class.getResource("/charsubst/character-translation-table.xml");
        try {
            this.charReplacer.addSubstitutionTable(commonSubstRulesFileUrl);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        String lang  = getCurrentLanguage();

        URL languageSubstRulesFileUrl;
        if (lang.equals("sv")) {
            languageSubstRulesFileUrl = CereprocTTSUtil.class.getResource("/charsubst/character-translation-table_sv.xml");
        } else if (lang.equals("en")) {
            languageSubstRulesFileUrl = CereprocTTSUtil.class.getResource("/charsubst/character-translation-table_en.xml");
        } else {
            return;
        }

        try {
            this.charReplacer.addSubstitutionTable(languageSubstRulesFileUrl);
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

    public String applyAll(String text) {
        String tmp;
        tmp = this.applyRegex(text);
        return this.applyCharacterSubstitution(tmp);
    }

    private String getCurrentLanguage() {
        if (this.locale.isPresent()){
            return this.locale.get().getLanguage();
        } else {
            return "";
        }
    }
}
