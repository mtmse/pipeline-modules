<p:declare-step type="px:text-to-ssml" version="1.0"
		xmlns:p="http://www.w3.org/ns/xproc"
		xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
		xmlns:cx="http://xmlcalabash.com/ns/extensions"
		xmlns:xml="http://www.w3.org/XML/1998/namespace"
		xmlns:ssml="http://www.w3.org/2001/10/synthesis"
		name="main"
		exclude-inline-prefixes="#all">

  <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
  <p:import href="http://www.daisy.org/pipeline/modules/css-speech/inline-css.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

  <p:documentation>
    Generate the TTS input, as SSML snippets.
  </p:documentation>

  <p:input port="fileset.in" sequence="false"/>
  <p:input port="content.in"  sequence="false" primary="true">
    <p:documentation>The content document (e.g. a Zedai document, a DTBook)</p:documentation>
  </p:input>
  <p:input port="sentence-ids" sequence="false" >
    <p:documentation>The list of the sentence ids, generated by the lexers.</p:documentation>
  </p:input>

  <p:output port="result" sequence="true" primary="true">
    <p:pipe port="result" step="docs-extract"/>
  </p:output>

  <p:option name="aural-sheet-uri" required="false" select="''">
      <p:documentation>An additional CSS Speech stylesheet that is not
      already referred by the content documents. If such a stylesheet
      is provided, the other stylesheets must not contain any
      'cue-before', 'cue-after', or 'cue' properties with relative
      paths.
      </p:documentation>
  </p:option>

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

  <p:option name="skippable-elements" required="false" select="''">
    <p:documentation>The list of elements that will be synthesized in
    separate sections when the corresponding option is enable.
    </p:documentation>
  </p:option>
  <p:option name="separate-skippable" required="false" select="'false'">
    <p:documentation>Whether or not the skippable elements must be all
    synthesized in separate sections.
    </p:documentation>
  </p:option>

  <p:option name="xhtml-link" required="false" select="'true'">
    <p:documentation>Whether or not the XHTML element 'link' exists,
    such as in EPUB3 and DTBook. Used for retrieving the CSS
    stylesheets.</p:documentation>
  </p:option>

  <!-- <p:option name="call-uid" required="false" select="'0'"> -->
  <!--   <p:documentation>Unique identifier for the call that allow to -->
  <!--   generate true pipeline-wide unique IDs.</p:documentation> -->
  <!-- </p:option> -->

  <!-- The skippable elements are separated before the CSS inlining so that -->
  <!-- the CSS will properly be applied on the new sentences that group -->
  <!-- together the skippable elements. -->
  <!-- As a result, the context-dependent CSS properties won't have any -->
  <!-- effect on the skippable elements. -->

  <p:choose name="separate">
    <p:when test="$separate-skippable = 'true'">
      <p:output port="result"/>
      <p:xslt>
	<p:with-param name="skippable-elements" select="$skippable-elements"/>
	<p:input port="stylesheet">
	  <p:document href="skippable-to-ssml.xsl"/>
	</p:input>
	<p:input port="source">
	  <p:pipe port="content.in" step="main"/>
	</p:input>
      </p:xslt>
      <cx:message message="Skippable elements separated"/>
    </p:when>
    <p:otherwise>
      <p:output port="result"/>
      <p:identity/>
    </p:otherwise>
  </p:choose>

  <!-- Get the CSS stylesheets -->
  <p:try>
    <p:group>
      <p:output port="result"/>
      <p:variable name="fileset-base" select="base-uri(/*)">
	<p:pipe port="fileset.in" step="main"/>
      </p:variable>
      <p:xslt name="get-css">
	<p:with-param name="xhtml-link" select="$xhtml-link"/>
	<p:input port="source">
	  <p:pipe port="content.in" step="main"/>
	</p:input>
	<p:input port="stylesheet">
	  <p:document href="get-css-uris.xsl"/>
	</p:input>
      </p:xslt>
      <p:viewport match="//*[@href]">
	<p:add-attribute attribute-name="original-href" match="/*">
	  <p:with-option name="attribute-value" select="resolve-uri(/*/@href, $fileset-base)"/>
	</p:add-attribute>
      </p:viewport>
    </p:group>
    <p:catch>
      <p:output port="result"/>
      <cx:message message="CSS stylesheet URI(s) are malformed."/>
      <p:identity>
	<p:input port="source">
	  <p:empty/>
	</p:input>
      </p:identity>
    </p:catch>
  </p:try>

  <p:group name="group.inlining">
    <p:output port="result"/>

    <!-- inline the CSS speech -->
    <p:variable name="sheet-uri-list" select="string-join(//*[@original-href]/@original-href, ',')"/>
    <p:variable name="all-sheet-uris"
		select="if ($aural-sheet-uri) then concat($sheet-uri-list, ',', $aural-sheet-uri) else $sheet-uri-list">
      <p:empty/>
    </p:variable>
    <p:variable name="first-sheet-uri"
		select="if ($aural-sheet-uri) then $aural-sheet-uri else //*[@original-href][1]/@original-href"/>
    <p:choose name="inlining">
      <p:when test="$all-sheet-uris != '' and $all-sheet-uris != ','">
	<p:output port="result"/>
	<p:identity>
	  <p:input port="source">
	    <p:pipe port="result" step="separate"/>
	  </p:input>
	</p:identity>
	<px:inline-css>
	  <p:with-option name="stylesheet-uri" select="$all-sheet-uris"/>
	  <p:with-option name="style-ns" select="'http://www.daisy.org/ns/pipeline/tmp'"/>
	</px:inline-css>
	<cx:message message="CSS speech inlined"/>
      </p:when>
      <p:otherwise>
	<p:output port="result"/>
	<p:identity>
	  <p:input port="source">
	    <p:pipe port="result" step="separate"/>
	  </p:input>
	</p:identity>
	<cx:message message="No CSS sheet found"/>
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

    <!-- Map the content to undispatchable objets (i.e. the content can be split -->
    <!-- within these objects but not transfered to other objects. Each object -->
    <!-- subdivision will be processed by a single thread. -->
    <p:xslt name="set-thread">
      <p:with-param name="future-docid" select="''"/>
      <p:input port="stylesheet">
	<p:document href="assign-thread-id.xsl"/>
      </p:input>
    </p:xslt>
    <cx:message message="ssml assigned to threads"/>

    <!-- TODO: conversion of elements such as span role="address" -->
    <!-- better use a XSLT URI as an option, because this example is Zedai specific -->

    <!-- Generate the rough skeleton of the SSML document. -->
    <!-- Everything is converted but the content of the sentences.-->
    <p:xslt name="gen-input">
      <p:with-param  name="css-sheet-uri" select="$first-sheet-uri"/>
      <p:input port="stylesheet">
	<p:document href="generate-tts-input.xsl"/>
      </p:input>
    </p:xslt>
    <cx:message message="TTS document input skeletons generated"/>
  </p:group>

  <!-- Convert the sentences' content with the help of the CSS properties. -->
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
    <p:iteration-source select="//*[@media-type = 'application/pls+xml']">
      <p:pipe port="fileset.in" step="main"/>
    </p:iteration-source>
    <p:output port="result" sequence="true"/>
    <p:load>
      <p:with-option name="href" select="/*/@original-href"/>
    </p:load>
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
