package org.daisy.pipeline.tts.cereproc.impl;

import net.sf.saxon.Configuration;
import net.sf.saxon.s9api.XdmItem;
import net.sf.saxon.s9api.XdmNode;
import org.daisy.common.saxon.SaxonOutputValue;
import org.daisy.pipeline.junit.AbstractTest;
import org.daisy.pipeline.tts.Voice;
import org.junit.Assert;
import org.junit.Test;

import javax.xml.stream.XMLStreamWriter;
import java.io.File;
import java.util.*;


public class CereProcEngineTest extends AbstractTest {


	private static final Map<String,String> params = new HashMap<>();

	static {
		params.put("org.daisy.pipeline.tts.cereproc.server", System.getProperty("org.daisy.pipeline.tts.cereproc.server"));
		params.put("org.daisy.pipeline.tts.cereproc.port", System.getProperty("org.daisy.pipeline.tts.cereproc.port"));
		params.put("org.daisy.pipeline.tts.cereproc.dnn.port", System.getProperty("org.daisy.pipeline.tts.cereproc.dnn.port"));
	}


	@Test
	public void TestSSMLFormatter() throws Throwable {
		CereProcService service = new CereProcService() {
			@Override
			protected CereProcEngine newEngine(String server, File client, int priority, Map<String, String> params) throws Throwable {
				return null;
			}
		};

		File client = new File(CereProcEngineTest.class.getResource("/ClientMock").toURI());
		CereProcEngine engine = new CereProcEngine(CereProcEngine.Variant.STANDARD,
				service,
				"Server",
				9999,
				client,
				1
		);

//		File tempDir = new File(System.getProperty("java.io.tmpdir"));
//		File tempFile = File.createTempFile("xmlfile", ".tmp", tempDir);
//		FileWriter fileWriter = new FileWriter(tempFile, true);
//
//		XMLOutputFactory outputFactory = XMLOutputFactory.newInstance();
////		XMLStreamWriter writer = outputFactory.createXMLStreamWriter(fileWriter);
		List<XdmItem> ssmlProcessed = new ArrayList<>();
		XMLStreamWriter writer = new SaxonOutputValue(
				item -> {
					if (item instanceof XdmNode) {
						ssmlProcessed.add(item);
					} else {
						throw new RuntimeException(); // should not happen
					}
				}, new Configuration()).asXMLStreamWriter();

		writer.writeStartDocument("1.0");
//		writer.writeStartElement("x", "p", "www.google.");
//		writer.writeNamespace("pipetest", "www.google.com");
//		writer.writeAttribute("SomeAttrib", "true");
		writer.writeStartElement("ssml", "speak", "x");
		writer.writeStartElement("ssml", "s", "x");
		writer.writeStartElement("ssml", "token", "x");
		writer.writeAttribute("xml:lang", "sv");
		writer.writeCharacters("This is a Γ\n");
		writer.writeCharacters("test roman letter III, lorem ipsum 27 kap. lorem ipsum\n");
		writer.writeEndElement();
		writer.writeEndElement();
		writer.writeEndElement();
//		writer.writeEndElement();
//		writer.writeEndElement();
		writer.writeEndDocument();
		writer.flush();
		writer.close();

		if ( ssmlProcessed.size() != 1) {
			throw new RuntimeException("Something went wrong");
		}
		if (!(ssmlProcessed.get(0) instanceof XdmNode)) {
			throw new RuntimeException("Incorrect type");
		}
		XdmNode node = (XdmNode) ssmlProcessed.get(0);
		Voice  v = new Voice("cereproc", "Ylva", new Locale("sv"), null, null);
		Assert.assertEquals("test roman letter  tre, lorem ipsum Tjugosjunde kapitlet.  lorem ipsum<break time=\"250ms\"></break>", engine.transformSSML(node, v));
//		Assert.assertEquals(1,1);
	}

	/**
	 * <speak version="1.1" xmlns="http://www.w3.org/2001/10/synthesis">
	 * 						<s id="A" xml:lang="sv">
	 * 							<token role="word">Det</token>
	 * 							<token role="word">var</token>
	 * 							<token role="word">en</token>
	 * 							<token role="word">gång</token>
	 * 							<token role="word">och</token>
	 * 							<token role="word">den</token>
	 * 							<token role="word">var</token>
	 * 							<token role="word">sandad</token>.
	 * 						</s>
	 * 						<s id="B" xml:lang="fr">
	 * 							<token role="word">Bonjour</token>
	 * 							<token role="word">monsieur</token>,
	 * 							<token role="word">ça</token>
	 * 							<token role="word">va</token>?
	 * 						</s>
	 * 						<s id="C" xml:lang="en">
	 * 							<token role="word">End</token>
	 * 							<token role="word">of</token>
	 * 							<token role="word">test</token>
	 * 							<token role="word">book</token>.
	 * 						</s>
	 * 					</speak>
	 */
}
