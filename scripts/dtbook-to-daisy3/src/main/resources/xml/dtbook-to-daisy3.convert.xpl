<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:m="http://www.w3.org/1998/Math/MathML"
                type="px:dtbook-to-daisy3" name="main"
                exclude-inline-prefixes="#all">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h1 px:role="name">DTBook to DAISY 3</h1>
    <p px:role="desc">Converts a single dtbook to DAISY 3 format</p>
  </p:documentation>

  <p:input port="in-memory.in" primary="true" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">2005 DTBook file</h2>
      <p px:role="desc">It contains the DTBook file to be
      transformed. Any other document will be ignored.</p>
    </p:documentation>
  </p:input>

  <p:input port="tts-config">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Text-To-Speech configuration file</h2>
      <p px:role="desc">Configuration file that contains Text-To-Speech
      properties, links to aural CSS stylesheets and links to PLS
      lexicons.</p>
    </p:documentation>
    <p:inline><d:config/></p:inline>
  </p:input>

  <p:output port="in-memory.out" primary="true" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Output documents</h2>
      <p px:role="desc">The SMIL files, the NCX file, the resource
      file, the OPF file and the input DTBook file updated in order to
      be linked with the SMIL files.</p>
    </p:documentation>
    <p:pipe step="convert" port="in-memory"/>
  </p:output>

  <p:output port="temp-audio-files" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">List of audio files</h2>
      <p px:role="desc">List of audio files generated by the TTS step. May be deleted when the
      result fileset is stored.</p>
    </p:documentation>
    <p:pipe step="audio" port="mapping"/>
  </p:output>

  <p:output port="validation-status" px:media-type="application/vnd.pipeline.status+xml">
    <p:pipe step="validation-status" port="result"/>
  </p:output>

  <p:output port="tts-log" sequence="true">
    <p:pipe step="tts" port="log"/>
  </p:output>

  <p:input port="fileset.in">
    <p:documentation>
      A fileset containing references to all the DTBook files and any
      resources they reference (images etc.).  The xml:base is also
      set with an absolute URI for each file, and is intended to
      represent the "original file", while the href can change during
      conversions to reflect the path and filename of the resource in
      the output fileset.
    </p:documentation>
  </p:input>

  <p:output port="fileset.out">
    <p:documentation>
      A fileset containing references to the DTBook files and any
      resources it references (images etc.). For each file that is not
      stored in memory, the xml:base is set with an absolute URI
      pointing to the location on disk where it is stored. This lets
      the href reflect the path and filename of the resulting resource
      without having to store it. This is useful for chaining
      conversions.
    </p:documentation>
    <p:pipe step="convert" port="fileset"/>
  </p:output>

  <p:option name="publisher" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Publisher</h2>
      <p px:role="desc">The agency responsible for making the Digital
      Talking Book available. If left blank, it will be retrieved from
      the DTBook meta-data.</p>
    </p:documentation>
  </p:option>

  <p:option name="output-fileset-base" required="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Ouput fileset's base</h2>
      <p px:role="desc">fileset.out's base directory, which is the
      directory where the DAISY 3 publication will be stored if the
      user intends to store it with no further transformation.</p>
    </p:documentation>
  </p:option>

  <p:option name="audio" required="false" px:type="boolean" select="'true'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">Enable Text-To-Speech</h2>
      <p px:role="desc">Whether to use a speech synthesizer to produce audio files.</p>
    </p:documentation>
  </p:option>

  <p:option name="audio-only" required="false" px:type="boolean" select="'true'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h2 px:role="name">audio only</h2>
      <p px:role="desc">SMIL files are not attached to any DTBook</p>
    </p:documentation>
  </p:option>

  <p:option name="date" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Date of publication of the DTB</p>
      <p>Format must be YYYY[-MM[-DD]]</p>
      <p>Defaults to the current date.</p>
    </p:documentation>
  </p:option>

  <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
    <p:documentation>
      px:assert
    </p:documentation>
  </p:import>
  <p:import href="http://www.daisy.org/pipeline/modules/daisy3-utils/library.xpl">
    <p:documentation>
      px:daisy3-prepare-dtbook
      px:daisy3-create-ncx
      px:daisy3-create-opf
      px:daisy3-create-res-file
      px:daisy3-create-smils
    </p:documentation>
  </p:import>
  <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
    <p:documentation>
      px:fileset-rebase
      px:fileset-load
      px:fileset-copy
      px:fileset-move
      px:fileset-create
      px:fileset-add-entry
      px:fileset-join
      px:fileset-filter
    </p:documentation>
  </p:import>
  <p:import href="http://www.daisy.org/pipeline/modules/dtbook-tts/library.xpl">
    <p:documentation>
      px:tts-for-dtbook
    </p:documentation>
  </p:import>
  <p:import href="http://www.daisy.org/pipeline/modules/smil-utils/library.xpl">
    <p:documentation>
      px:audio-clips-to-fileset
      px:audio-clips-update-files
    </p:documentation>
  </p:import>
  <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl">
    <p:documentation>
      px:set-base-uri
    </p:documentation>
  </p:import>


  <!-- Find the first and only DTBook file within the input fileset. -->
  <p:identity>
    <p:input port="source">
      <p:pipe step="main" port="fileset.in"/>
    </p:input>
  </p:identity>
  <px:assert message="No DTBook document found." error-code="PEZE00">
    <p:with-option name="test" select="exists(/*/d:file[@media-type='application/x-dtbook+xml'])"/>
  </px:assert>
  <px:assert message="More than one DTBook found in fileset." error-code="PEZE00">
    <p:with-option name="test" select="count(/*/d:file[@media-type='application/x-dtbook+xml'])=1"/>
  </px:assert>

  <!-- ===== PERFORM TTS ==== -->
  <px:tts-for-dtbook process-css="true" name="tts" px:progress="1">
    <p:input port="source.in-memory">
      <p:pipe step="main" port="in-memory.in"/>
    </p:input>
    <p:input port="config">
      <p:pipe step="main" port="tts-config"/>
    </p:input>
    <p:with-option name="audio" select="$audio"/>
  </px:tts-for-dtbook>
  <px:fileset-load media-types="application/x-dtbook+xml" name="tts-enriched-dtbook">
    <p:input port="in-memory">
      <p:pipe step="tts" port="result.in-memory"/>
    </p:input>
  </px:fileset-load>
  <p:sink/>

  <!-- ===== CREATE MP3/OGG FILESET ENTRIES ==== -->
  <px:audio-clips-to-fileset>
    <p:input port="source">
      <p:pipe step="tts" port="audio-map"/>
    </p:input>
  </px:audio-clips-to-fileset>
  <px:fileset-move flatten="true" name="audio">
    <p:with-option name="target" select="$output-fileset-base"/>
    <!-- <p:with-option name="target" select="concat($output-fileset-base, 'audio/')"/> -->
  </px:fileset-move>
  <p:sink/>
  <px:audio-clips-update-files name="audio-map">
    <p:input port="source">
      <p:pipe step="tts" port="audio-map"/>
    </p:input>
    <p:input port="mapping">
      <p:pipe step="audio" port="mapping"/>
    </p:input>
  </px:audio-clips-update-files>
  <p:sink/>

  <p:identity>
    <p:input port="source">
      <p:pipe step="tts-enriched-dtbook" port="result"/>
    </p:input>
  </p:identity>
  <p:group name="convert">
    <p:output port="fileset" primary="true"/>
    <p:output port="in-memory" sequence="true">
      <p:pipe step="daisy3.in-memory" port="result"/>
    </p:output>

    <!-- Those variables could be used for structuring the output
         package but some DAISY players can only read flat
         package. -->
    <p:variable name="uid" select="concat((//dtbook:meta[@name='dtb:uid'])[1]/@content, '-packaged')"/>
    <p:variable name="title" select="normalize-space((//dtbook:meta[@name='dc:Title'])[1]/@content)"/>
    <p:variable name="dclang" select="(//dtbook:meta[@name='dc:Language'])[1]/@content"/>
    <p:variable name="lang" select="if ($dclang) then $dclang else //@*[name()='xml:lang'][1]"/>
    <p:variable name="dcpublisher" select="(//dtbook:meta[@name='dc:Publisher'])[1]/@content"/>
    <p:variable name="publisher" select="if ($publisher) then $publisher
					 else (if ($dcpublisher) then $dcpublisher else 'unknown')"/>

    <!--
        FIXME: automatic upgrade?
        FIXME: correct error code
    -->
    <px:assert message="Other versions than DTBook-2005 are not supported." error-code="C0051">
      <p:with-option name="test" select="(//dtbook:dtbook)[1]/@version/starts-with(., '2005')"/>
    </px:assert>

    <!-- ===== ADD WHAT IS MAYBE MISSING IN THE DTBOOK ===== -->
    <!--
        FIXME: perform this before the TTS so that the extra text will be synthesized
    -->
    <px:daisy3-prepare-dtbook name="prepare-dtbook">
      <p:with-option name="uid" select="$uid"/>
      <p:with-option name="output-base-uri" select="concat($output-fileset-base, replace(base-uri(/),'^.*/([^/]+)$','$1'))"/>
      <p:input port="mathml-altimg-fallback">
        <p:pipe step="mathml-altimg-fallback" port="result"/>
      </p:input>
    </px:daisy3-prepare-dtbook>

    <!-- ===== SMIL FILES ===== -->
    <px:daisy3-create-smils name="mo" px:message="Generating SMIL files...">
      <p:input port="source.in-memory">
        <p:pipe step="prepare-dtbook" port="result.in-memory"/>
      </p:input>
      <p:input port="audio-map">
        <p:pipe step="audio-map" port="result"/>
      </p:input>
      <p:with-option name="smil-dir" select="$output-fileset-base"/>
      <!-- <p:with-option name="smil-dir" select="concat($output-fileset-base, 'mo/')"/> -->
      <p:with-option name="uid" select="$uid"/>
      <p:with-option name="audio-only" select="$audio-only"/>
    </px:daisy3-create-smils>
    <p:sink/>

    <!-- ===== NCX FILE ===== -->
    <px:daisy3-create-ncx name="ncx">
      <p:input port="content">
        <p:pipe step="mo" port="dtbook.in-memory"/>
      </p:input>
      <p:input port="audio-map">
        <p:pipe step="audio-map" port="result"/>
      </p:input>
      <p:with-option name="ncx-dir" select="$output-fileset-base"/>
      <p:with-option name="uid" select="$uid"/>
    </px:daisy3-create-ncx>
    <p:sink/>

    <!-- ===== RESOURCE FILE ===== -->
    <px:daisy3-create-res-file name="res-file">
      <p:with-option name="output-dir" select="$output-fileset-base"/>
      <p:with-option name="lang" select="$lang"/>
    </px:daisy3-create-res-file>
    <p:sink/>

    <!-- ===== MATHML XSLT AND ALTIMG FALLBACKS ===== -->
    <!-- xslt fallback -->
    <p:choose name="mathml-xslt-fallback">
      <p:xpath-context>
        <p:pipe step="tts-enriched-dtbook" port="result"/>
      </p:xpath-context>
      <p:when test="$audio-only='true' or not(exists(//m:math))">
        <p:output port="fileset" sequence="true"/>
        <p:identity>
          <p:input port="source">
            <p:empty/>
          </p:input>
        </p:identity>
      </p:when>
      <p:otherwise>
        <p:output port="fileset" sequence="true"/>
        <px:fileset-create>
          <p:with-option name="base" select="$output-fileset-base"/>
        </px:fileset-create>
        <px:fileset-add-entry media-type="application/xslt+xml">
          <p:with-option name="href" select="'mathml-fallback.xsl'"/>
          <p:with-option name="original-href" select="resolve-uri('mathml-fallback.xsl', static-base-uri())"/>
          <p:with-param port="file-attributes" name="role" select="'mathml-xslt-fallback'"/>
        </px:fileset-add-entry>
      </p:otherwise>
    </p:choose>
    <p:sink/>

    <!-- altimg fallback -->
    <px:fileset-create>
      <p:with-option name="base" select="$output-fileset-base"/>
    </px:fileset-create>
    <px:fileset-add-entry media-type="image/png" name="mathml-altimg-fallback">
      <p:with-option name="href" select="'math-formulae.png'"/>
      <p:with-option name="original-href" select="resolve-uri('../images/math_formulae.png', static-base-uri())"/>
    </px:fileset-add-entry>
    <p:sink/>

    <!-- ===== OPF FILE AND DAISY 3 FILESET ==== -->
    <px:fileset-join>
      <p:input port="source">
        <p:pipe step="mo" port="result.fileset"/>
        <p:pipe step="audio" port="result.fileset"/>
        <p:pipe step="mathml-xslt-fallback" port="fileset"/>
        <p:pipe step="ncx" port="result.fileset"/>
        <p:pipe step="res-file" port="result.fileset"/>
      </p:input>
    </px:fileset-join>
    <p:choose>
      <p:when test="$audio-only='true'">
        <!-- remove DTBook -->
        <px:fileset-filter not-media-types="application/x-dtbook+xml"/>
      </p:when>
      <p:otherwise>
        <p:identity name="fileset"/>
        <p:sink/>
        <!-- copy resource files -->
        <px:fileset-rebase>
          <!-- to make sure relative paths from DTBook to resource files remain the same -->
          <p:input port="source">
            <p:pipe step="main" port="fileset.in"/>
          </p:input>
          <p:with-option name="new-base" select="base-uri(/*)">
            <p:pipe step="tts-enriched-dtbook" port="result"/>
          </p:with-option>
        </px:fileset-rebase>
        <px:fileset-filter media-types="image/gif
                                        image/jpeg
                                        image/png
                                        image/svg+xml
                                        application/pls+xml
                                        audio/mpeg
                                        audio/mp4
                                        text/css"/>
        <px:fileset-copy name="resources-fileset">
          <p:with-option name="target" select="$output-fileset-base"/>
        </px:fileset-copy>
        <p:sink/>
        <px:fileset-join>
          <p:input port="source">
            <p:pipe step="fileset" port="result"/>
            <p:pipe step="resources-fileset" port="result.fileset"/>
          </p:input>
        </px:fileset-join>
      </p:otherwise>
    </p:choose>
    <p:identity name="daisy3.fileset-without-opf"/>
    <px:daisy3-create-opf name="opf">
      <p:with-option name="opf-uri" select="concat($output-fileset-base, 'book.opf')"/>
      <p:with-option name="uid" select="$uid"/>
      <p:with-option name="title" select="$title"/>
      <p:with-option name="lang" select="$lang"/>
      <p:with-option name="date" select="$date"/>
      <p:with-option name="publisher" select="$publisher"/>
      <p:with-option name="audio-only" select="$audio-only"/>
      <p:with-option name="total-time" select="//*[@duration]/@duration">
      	<p:pipe step="mo" port="duration"/>
      </p:with-option>
    </px:daisy3-create-opf>
    <p:sink/>
    <p:identity name="daisy3.in-memory">
      <p:input port="source">
        <p:pipe step="mo" port="result.in-memory"/>
        <p:pipe step="ncx" port="result"/>
        <p:pipe step="res-file" port="result"/>
        <p:pipe step="opf" port="result"/>
      </p:input>
    </p:identity>
    <p:sink/>
    <px:fileset-join>
      <p:input port="source">
        <p:pipe step="daisy3.fileset-without-opf" port="result"/>
        <p:pipe step="opf" port="result.fileset"/>
      </p:input>
    </px:fileset-join>
  </p:group>
  <p:sink/>

  <p:rename match="/*" new-name="d:validation-status" name="validation-status">
    <p:input port="source">
      <p:pipe step="tts" port="status"/>
    </p:input>
  </p:rename>

</p:declare-step>
