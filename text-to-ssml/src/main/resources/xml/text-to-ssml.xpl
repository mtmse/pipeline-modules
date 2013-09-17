<p:declare-step type="px:text-to-ssml" version="1.0"
		xmlns:p="http://www.w3.org/ns/xproc"
		xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
		xmlns:cx="http://xmlcalabash.com/ns/extensions"
		xmlns:xml="http://www.w3.org/XML/1998/namespace"
		xmlns:ssml="http://www.w3.org/2001/10/synthesis"
		name="main"
		exclude-inline-prefixes="#all">

  <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/xproc/fileset-library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/css-speech/inline-css.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

  <p:documentation>
    Generate the TTS input, as SSML snippets.
  </p:documentation>

  <p:input port="fileset.in" sequence="false"/>
  <p:input port="content.in" sequence="false" primary="true">
    <p:documentation>The content document (e.g. a Zedai document)</p:documentation>
  </p:input>
  <p:input port="sentence-ids" sequence="false" >
    <p:documentation>The list of the sentence ids, generated the lexing.</p:documentation>
  </p:input>

  <p:output port="result" sequence="true" primary="true">
    <p:pipe port="result" step="docs-extract"/>
  </p:output>

  <p:option name="css-sheet-uri" required="false" select="''"/>

  <p:option name="section-element" required="true">
    <p:documentation>Element used to identify threadable groups,
    together with its attribute 'section-attr'.</p:documentation>
  </p:option>
  <p:option name="section-attr" required="false" select="''"/>
  <p:option name="section-attr-val" required="false" select="''"/>

  <p:option name="word-element" required="true">
    <p:documentation>Element used to identify words within sentences,
    together with its attribute 'word-attr'.</p:documentation>
  </p:option>
  <p:option name="word-attr" required="false" select="''"/>
  <p:option name="word-attr-val" required="false" select="''"/>

  <!-- <p:option name="call-uid" required="false" select="'0'"> -->
  <!--   <p:documentation>Unique identifier for the call that allow to -->
  <!--   generate true pipeline-wide unique IDs.</p:documentation> -->
  <!-- </p:option> -->

  <!-- inline the CSS speech -->
  <p:choose name="inlining">
    <p:when test="$css-sheet-uri != ''">
      <p:output port="result"/>
      <px:inline-css>
	<p:input port="source">
	  <p:pipe port="content.in" step="main"/>
	</p:input>
	<p:with-option name="medium" select="'speech'"/>
	<p:with-option name="inherit" select="'true'"/>
	<p:with-option name="stylesheet-uri" select="$css-sheet-uri"/>
	<p:with-option name="style-ns" select="'http://www.daisy.org/ns/pipeline/tmp'"/>
      </px:inline-css>
      <cx:message message="CSS speech inlined"/>
    </p:when>
    <p:otherwise>
      <p:output port="result"/>
      <p:identity>
	<p:input port="source">
	  <p:pipe port="content.in" step="main"/>
	</p:input>
      </p:identity>
      <cx:message message="No CSS sheet given"/>
    </p:otherwise>
  </p:choose>

 <!-- replace sentences and words with their SSML counterpart so that it -->
 <!-- will be much simpler and faster to apply transformations after. -->
  <p:xslt name="normalize">
    <p:with-param name="word-element" select="$word-element"/>
    <p:with-param name="word-attr" select="$word-attr"/>
    <p:with-param name="word-attr-val" select="$word-attr-val"/>
    <p:with-param name="section-element" select="$section-element"/>
    <p:with-param name="section-attr" select="$section-attr"/>
    <p:with-param name="section-attr-val" select="$section-attr-val"/>
    <p:input port="source">
      <p:pipe port="result" step="inlining"/>
      <p:pipe port="sentence-ids" step="main"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="normalize.xsl"/>
    </p:input>
  </p:xslt>
  <cx:message message="Lexing information normalized"/>

  <p:xslt name="set-thread">
    <p:with-param name="future-docid" select="''"/>
    <p:input port="stylesheet">
      <p:document href="assign-thread-id.xsl"/>
    </p:input>
  </p:xslt>
  <cx:message message="ssml assigned to threads"/>

  <!-- TODO: conversion of elements such as span role="address" -->
  <!-- better use a XSLT URI as an option, because this example is Zedai specific -->
  <p:xslt name="gen-input">
    <p:with-param  name="css-sheet-uri" select="$css-sheet-uri"/>
    <p:input port="stylesheet">
      <p:document href="generate-tts-input.xsl"/>
    </p:input>
  </p:xslt>
  <cx:message message="TTS document input skeletons generated"/>

  <p:xslt name="css-convert">
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="css-to-ssml.xsl"/>
    </p:input>
  </p:xslt>
  <cx:message message="CSS properties converted to SSML"/><p:sink/>

  <!-- ============================================================== -->
  <!-- DO SOME TEXT-TO-SSML CONVERSIONS USING THE LEXICONS -->
  <!-- ============================================================== -->

  <p:variable name="provided-lexicons" select="'provided'"/>
  <p:variable name="builtin-lexicons" select="'builtins'"/>

  <!-- iterate over the fileset to extract the lexicons URI, then load them -->
  <!-- from the disk -->
  <p:for-each>
    <p:iteration-source select="/*/*">
      <p:pipe port="fileset.in" step="main"/>
    </p:iteration-source>
    <p:output port="result" sequence="true"/>
    <p:choose>
      <p:when test="/*/@media-type = 'application/pls+xml'">
	<p:load>
	  <p:with-option name="href" select="/*/@original-href"/>
	</p:load>
      </p:when>
      <p:otherwise>
	<p:identity>
	  <p:input port="source">
	    <p:empty/>
	    </p:input>
	</p:identity>
      </p:otherwise>
    </p:choose>
  </p:for-each>
  <p:wrap-sequence name="wrap-provided-lexicons">
    <p:with-option name="wrapper" select="$provided-lexicons"/>
  </p:wrap-sequence>
  <cx:message message="got the lexicons URI"/><p:sink/>

  <!-- find all the languages actually used -->
  <p:xslt name="list-lang">
    <p:input port="source">
      <p:pipe port="content.in" step="main"/>
    </p:input>
    <p:input port="parameters">
	<p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
	<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	  <xsl:output method="xml" encoding="UTF-8" />
	  <xsl:template match="/">
	    <root>
	      <xsl:for-each-group select="//node()[@xml:lang]" group-by="@xml:lang">
		<lang><xsl:attribute name="lang">
		  <xsl:value-of select="@xml:lang"/>
		</xsl:attribute></lang>
	      </xsl:for-each-group>
	    </root>
	  </xsl:template>
	</xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>

  <!-- read the corresponding lexicons from the disk -->
  <p:for-each name="for-each">
    <p:iteration-source select="//*[@lang]">
      <p:pipe port="result" step="list-lang"/>
    </p:iteration-source>
    <p:variable name="l" select="/*/@lang">
	<p:pipe port="current" step="for-each"/>
    </p:variable>
    <p:try>
      <p:group>
	<p:load>
	  <p:with-option name="href" select="concat('../lexicons/lexicon_', $l,'.pls')"/>
	</p:load>
	<cx:message>
	  <p:with-option name="message" select="concat('loaded lexicon for language: ', $l)"/>
	</cx:message>
      </p:group>
      <p:catch>
	<p:identity>
	  <p:input port="source">
	    <p:empty/>
	    </p:input>
	</p:identity>
	<cx:message>
	  <p:with-option name="message" select="concat('could not find the builtin lexicon for language: ', $l)"/>
	</cx:message>
      </p:catch>
    </p:try>
  </p:for-each>
  <p:wrap-sequence name="wrap-builtin-lexicons">
    <p:with-option name="wrapper" select="$builtin-lexicons"/>
  </p:wrap-sequence>
  <cx:message message="lexicons read from the disk"/><p:sink/>

  <p:xslt name="pls">
    <p:input port="source">
      <p:pipe port="result" step="css-convert"/>
      <p:pipe port="result" step="wrap-provided-lexicons"/>
      <p:pipe port="result" step="wrap-builtin-lexicons"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="pls-to-ssml.xsl"/>
    </p:input>
    <p:with-param name="builtin-lexicons" select="$builtin-lexicons"/>
    <p:with-param name="provided-lexicons" select="$provided-lexicons"/>
  </p:xslt>

  <cx:message message="PLS info converted to SSML"/>

  <!-- split the result to extract the wrapped SSML files -->
  <p:filter name="docs-extract">
    <p:with-option name="select" select="'//ssml:speak'"/>
  </p:filter>

</p:declare-step>
