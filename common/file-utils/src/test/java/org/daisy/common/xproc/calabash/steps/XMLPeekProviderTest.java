package org.daisy.common.xproc.calabash.steps;

import java.io.UnsupportedEncodingException;

import org.daisy.common.xproc.calabash.steps.XMLPeekProvider.XMLPeek;
import org.junit.Assert;
import org.junit.Test;

public class XMLPeekProviderTest {

	@Test
	public void test() {
		try {
			Assert.assertEquals("Test that spliceBytes works", "es", new String(XMLPeek.spliceBytes("test".getBytes(), 1, 2), "UTF-8"));
		} catch (UnsupportedEncodingException e) {
			Assert.fail("Unable to test spliceBytes because UTF-8 encoding is not supported");
			e.printStackTrace();
		}
	}

}
