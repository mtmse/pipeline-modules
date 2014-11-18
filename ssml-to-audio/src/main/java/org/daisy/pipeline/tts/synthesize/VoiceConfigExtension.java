package org.daisy.pipeline.tts.synthesize;

import java.net.URI;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Map;

import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.XdmNode;

import org.daisy.pipeline.tts.VoiceInfo;
import org.daisy.pipeline.tts.VoiceInfo.Gender;
import org.daisy.pipeline.tts.config.ConfigReader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VoiceConfigExtension implements ConfigReader.Extension {

	private Logger Logger = LoggerFactory.getLogger(VoiceConfigExtension.class);

	@Override
	public boolean parseNode(XdmNode node, URI documentURI) {
		String name = node.getNodeName().getLocalName();
		if ("voice".equalsIgnoreCase(name)) {
			String lang = node.getAttributeValue(new QName(null, "lang"));
			if (lang == null)
				node.getAttributeValue(new QName("http://www.w3.org/XML/1998/namespace",
				        "lang"));
			String vengine = node.getAttributeValue(new QName(null, "engine"));
			String vname = node.getAttributeValue(new QName(null, "name"));
			String priority = node.getAttributeValue(new QName(null, "priority"));
			Gender gender = Gender.of(node.getAttributeValue(new QName(null, "gender")));
			if (priority == null)
				priority = "5";
			if (lang == null || vengine == null || vname == null || gender == null) {
				Logger.warn("Config file invalid near " + node.toString());
			} else {
				try {
					mVoices.add(new VoiceInfo(vengine, vname, lang, gender, Float
					        .valueOf(priority)));
				} catch (NumberFormatException e) {
					Logger.warn("Error while converting config file's priority " + priority
					        + " to float.");
				}
			}
			return true;
		}
		return false;
	}

	@Override
	public void setParentReader(ConfigReader cr) {
		mConfigReader = cr;
	}

	public Collection<VoiceInfo> getVoiceDeclarations() {
		return mVoices;
	}

	public Map<String, String> getProperties() {
		return mConfigReader.getProperties();
	}

	private ConfigReader mConfigReader;
	private Collection<VoiceInfo> mVoices = new ArrayList<VoiceInfo>();
}
