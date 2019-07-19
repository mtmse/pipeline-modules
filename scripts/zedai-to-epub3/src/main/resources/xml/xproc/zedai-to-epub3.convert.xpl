<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                type="px:zedai-to-epub3" name="main"
                exclude-inline-prefixes="#all">

    <p:documentation> Transforms a ZedAI (DAISY 4 XML) document into an EPUB 3 publication. </p:documentation>

    <p:input port="fileset.in" primary="true"/>
    <p:input port="in-memory.in" sequence="true"/>

    <p:input port="tts-config">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Text-To-Speech configuration file</h2>
            <p px:role="desc">Configuration file that contains Text-To-Speech properties, links to
            aural CSS stylesheets and links to PLS lexicons.</p>
        </p:documentation>
    </p:input>

    <p:output port="fileset.out" primary="true">
        <p:pipe step="ocf" port="fileset"/>
    </p:output>
    <p:output port="in-memory.out" sequence="true">
        <p:pipe step="ocf" port="in-memory"/>
    </p:output>

    <p:output port="validation-status" px:media-type="application/vnd.pipeline.status+xml">
        <p:pipe step="validation-status" port="result"/>
    </p:output>

    <p:output port="temp-audio-files">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">List of audio files</h2>
            <p px:role="desc">List of audio files generated by the TTS step. May be deleted when the
            result fileset is stored.</p>
        </p:documentation>
        <p:pipe step="add-mediaoverlays" port="temp-audio.fileset"/>
    </p:output>
  
    <p:option name="output-dir" required="true">
        <p:documentation>Empty directory dedicated to this conversion.</p:documentation>
    </p:option>
    <p:option name="temp-dir" select="''">
        <p:documentation>Empty directory dedicated to this conversion. May be left empty in which
        case a temporary directory will be automaticall created.</p:documentation>
    </p:option>
    <p:option name="chunk-size" required="false" select="'-1'"/>
    <p:option name="audio" required="false" select="'false'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Enable Text-To-Speech</h2>
            <p px:role="desc">Whether to use a speech synthesizer to produce audio files.</p>
        </p:documentation>
    </p:option>
    <p:option name="process-css" required="false" select="'true'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Set to false to bypass aural CSS processing.</p>
        </p:documentation>
    </p:option>

    <p:import href="zedai-to-opf-metadata.xpl">
        <p:documentation>
            px:zedai-to-opf-metadata
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/zedai-to-html/library.xpl">
        <p:documentation>
            px:zedai-to-html
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/html-utils/library.xpl">
        <p:documentation>
            px:html-id-fixer
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/epub3-utils/library.xpl">
        <p:documentation>
            px:epub3-nav-create-navigation-doc
            px:epub3-create-mediaoverlays
            px:epub3-pub-create-package-doc
            px:epub3-ocf-finalize
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-load
            px:fileset-add-entry
            px:fileset-join
            px:fileset-rebase
            px:fileset-update
            px:fileset-filter
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:assert
            px:message
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/epub3-tts/library.xpl">
        <p:documentation>
            px:epub3-for-tts
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/css-speech/library.xpl">
        <p:documentation>
            px:inline-css-speech
        </p:documentation>
    </p:import>

    <p:variable name="epub-dir" select="concat($output-dir,'epub/')"/>
    <p:variable name="content-dir" select="concat($epub-dir,'EPUB/')"/>

    <!--=========================================================================-->
    <!-- GET ZEDAI FROM FILESET                                                  -->
    <!--=========================================================================-->

    <p:documentation>Retreive the ZedAI document from the input fileset.</p:documentation>
    <p:group>
        <px:fileset-load media-types="application/z3998-auth+xml">
            <p:input port="in-memory">
                <p:pipe step="main" port="in-memory.in"/>
            </p:input>
        </px:fileset-load>
        <!-- TODO: describe the error on the wiki and insert correct error code -->
        <px:assert message="No XML documents with the ZedAI media type ('application/z3998-auth+xml') found in the fileset."
                   test-count-min="1" error-code="PEZE00"/>
        <px:assert message="More than one XML document with the ZedAI media type ('application/z3998-auth+xml') found in the fileset; there can only be one ZedAI document."
                   test-count-max="1" error-code="PEZE00"/>
    </p:group>

    <!--=========================================================================-->
    <!-- CSS INLINING                                                            -->
    <!--=========================================================================-->
    <p:choose>
        <p:xpath-context>
            <p:empty/>
        </p:xpath-context>
        <p:when test="$audio='true' and $process-css='true'">
            <px:inline-css-speech content-type="application/z3998-auth+xml">
                <p:input port="fileset.in">
                    <p:pipe step="main" port="fileset.in"/>
                </p:input>
                <p:input port="config">
                    <p:pipe step="main" port="tts-config"/>
                </p:input>
            </px:inline-css-speech>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    <p:identity name="zedai-with-css"/>

    <!--=========================================================================-->
    <!-- METADATA                                                                -->
    <!--=========================================================================-->

    <p:documentation>Extract metadata from ZedAI</p:documentation>
    <px:zedai-to-opf-metadata name="metadata"/>
    <p:sink/>

    <!--=========================================================================-->
    <!-- CONVERT TO XHTML                                                        -->
    <!--=========================================================================-->

    <px:fileset-update name="fileset-with-css">
        <p:input port="source.fileset">
            <p:pipe step="main" port="fileset.in"/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="main" port="in-memory.in"/>
        </p:input>
        <p:input port="update">
            <p:pipe step="zedai-with-css" port="result"/>
        </p:input>
    </px:fileset-update>

    <px:zedai-to-html chunk="true" name="zedai-to-html">
        <p:input port="in-memory.in">
            <p:pipe step="fileset-with-css" port="result.in-memory"/>
        </p:input>
        <p:with-option name="output-dir" select="$content-dir"/>
        <p:with-option name="chunk-size" select="$chunk-size"/>
    </px:zedai-to-html>

    <!--=========================================================================-->
    <!-- GENERATE THE NAVIGATION DOCUMENT                                        -->
    <!--=========================================================================-->

    <p:documentation>Generate the EPUB 3 navigation document</p:documentation>
    <p:group name="add-navigation-doc">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="add-entry" port="result.in-memory"/>
        </p:output>
        <p:output port="doc">
            <p:pipe step="navigation-doc" port="result"/>
        </p:output>
        <px:fileset-load media-types="application/xhtml+xml">
            <p:input port="in-memory">
                <p:pipe step="zedai-to-html" port="in-memory.out"/>
            </p:input>
        </px:fileset-load>
        <p:for-each name="fix-ids">
            <p:documentation>Add missing IDs</p:documentation>
            <p:output port="result" sequence="true"/>
            <px:html-id-fixer/>
        </p:for-each>
        <!--TODO create other nav types (configurable ?)-->
        <px:epub3-nav-create-navigation-doc>
            <p:with-option name="output-base-uri" select="concat($content-dir,'toc.xhtml')">
                <p:empty/>
            </p:with-option>
        </px:epub3-nav-create-navigation-doc>
        <px:message message="Navigation Document Created." name="navigation-doc"/>
        <p:sink/>
        <px:fileset-update name="update">
            <p:input port="source.fileset">
                <p:pipe step="zedai-to-html" port="fileset.out"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="zedai-to-html" port="in-memory.out"/>
            </p:input>
            <p:input port="update">
                <p:pipe step="fix-ids" port="result"/>
            </p:input>
        </px:fileset-update>
        <px:fileset-add-entry media-type="application/xhtml+xml" name="add-entry">
            <p:input port="source.in-memory">
                <p:pipe step="update" port="result.in-memory"/>
            </p:input>
            <p:input port="entry">
                <p:pipe step="navigation-doc" port="result"/>
            </p:input>
        </px:fileset-add-entry>
    </p:group>

    <!--=========================================================================-->
    <!-- Call the TTS                                                            -->
    <!--=========================================================================-->

    <px:tts-for-epub3 name="tts">
      <p:input port="in-memory.in">
          <p:pipe step="add-navigation-doc" port="in-memory"/>
      </p:input>
      <p:input port="fileset.in">
          <!-- TODO: include resources such as lexicons -->
          <p:pipe step="add-navigation-doc" port="fileset"/>
      </p:input>
      <p:input port="config">
          <p:pipe step="main" port="tts-config"/>
      </p:input>
      <p:with-option name="audio" select="$audio"/>
      <p:with-option name="output-dir" select="$output-dir"/>
      <p:with-option name="temp-dir" select="$temp-dir"/>
    </px:tts-for-epub3>

    <p:documentation>Update the fileset with the enriched HTML files.</p:documentation>
    <px:fileset-update name="add-enriched-html">
        <p:input port="source.fileset">
            <p:pipe step="add-navigation-doc" port="fileset"/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="add-navigation-doc" port="in-memory"/>
        </p:input>
        <p:input port="update">
            <p:pipe step="tts" port="content.out"/>
        </p:input>
    </px:fileset-update>

    <!--=========================================================================-->
    <!-- GENERATE THE MEDIA-OVERLAYS                                             -->
    <!--=========================================================================-->

    <p:documentation>Add SMIL and audio files</p:documentation>
    <p:choose name="add-mediaoverlays">
        <p:xpath-context>
            <p:pipe step="tts" port="audio-map"/>
        </p:xpath-context>
        <p:when test="count(/d:audio-clips/*) = 0">
            <p:output port="fileset" primary="true"/>
            <p:output port="in-memory" sequence="true">
                <p:pipe step="add-enriched-html" port="result.in-memory"/>
            </p:output>
            <p:output port="temp-audio.fileset">
                <p:inline><d:fileset/></p:inline>
            </p:output>
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:output port="fileset" primary="true"/>
            <p:output port="in-memory" sequence="true">
                <p:pipe step="add-enriched-html" port="result.in-memory"/>
                <p:pipe step="mo" port="in-memory.out"/>
            </p:output>
            <p:output port="temp-audio.fileset">
                <p:pipe step="mo" port="original-audio.fileset"/>
            </p:output>
            <p:documentation>Generate SMIL files and copy audio files</p:documentation>
            <px:epub3-create-mediaoverlays flatten="true" name="mo">
                <p:input port="content-docs">
                    <p:pipe step="tts" port="content.out"/>
                </p:input>
                <p:input port="audio-map">
                    <p:pipe step="tts" port="audio-map"/>
                </p:input>
                <p:with-option name="mediaoverlay-dir" select="concat($content-dir,'mo/')">
                    <p:empty/>
                </p:with-option>
                <p:with-option name="audio-dir" select="concat($content-dir,'audio/')">
                    <p:empty/>
                </p:with-option>
            </px:epub3-create-mediaoverlays>
            <p:sink/>
            <px:fileset-join>
                <p:input port="source">
                    <p:pipe step="add-enriched-html" port="result.fileset"/>
                    <p:pipe step="mo" port="fileset.out"/>
                </p:input>
            </px:fileset-join>
        </p:otherwise>
    </p:choose>

    <!--=========================================================================-->
    <!-- GENERATE THE PACKAGE DOCUMENT                                           -->
    <!--=========================================================================-->

    <p:documentation>Generate the EPUB 3 package document</p:documentation>
    <p:group name="add-package-doc">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="add-entry" port="result.in-memory"/>
        </p:output>
        <p:output port="opf">
            <p:pipe port="result" step="package-doc"/>
        </p:output>

        <p:group name="content-docs">
            <p:output port="fileset" primary="true">
                <p:pipe step="fileset" port="result"/>
            </p:output>
            <p:output port="in-memory" sequence="true">
                <p:pipe step="in-memory" port="result"/>
            </p:output>
            <px:fileset-filter media-types="application/xhtml+xml" name="fileset"/>
            <px:fileset-load name="in-memory">
                <p:input port="in-memory">
                    <p:pipe step="add-mediaoverlays" port="in-memory"/>
                </p:input>
            </px:fileset-load>
        </p:group>
        <p:sink/>
        <p:group name="publication-resources">
            <p:output port="fileset"/>
            <px:fileset-filter not-media-types="application/xhtml+xml application/smil+xml">
                <p:input port="source">
                    <p:pipe step="add-mediaoverlays" port="fileset"/>
                </p:input>
            </px:fileset-filter>
        </p:group>
        <p:sink/>

        <px:epub3-pub-create-package-doc compatibility-mode="false">
            <p:input port="spine-filesets">
                <p:pipe step="content-docs" port="fileset"/>
            </p:input>
            <p:input port="publication-resources">
                <p:pipe step="publication-resources" port="fileset"/>
            </p:input>
            <p:input port="mediaoverlays">
                <p:pipe step="add-mediaoverlays" port="in-memory"/>
            </p:input>
            <p:input port="metadata">
                <p:pipe step="metadata" port="result"/>
            </p:input>
            <p:input port="content-docs">
                <p:pipe step="content-docs" port="in-memory"/>
            </p:input>
            <p:with-option name="result-uri" select="concat($content-dir,'package.opf')"/>
            <p:with-option name="nav-uri" select="base-uri(/*)">
                <p:pipe step="add-navigation-doc" port="doc"/>
            </p:with-option>
        </px:epub3-pub-create-package-doc>
        <px:message message="Package Document Created."/>
        <p:identity name="package-doc"/>
        <p:sink/>

        <px:fileset-add-entry media-type="application/oebps-package+xml" name="add-entry">
            <p:input port="source">
                <p:pipe step="add-mediaoverlays" port="fileset"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="add-mediaoverlays" port="in-memory"/>
            </p:input>
            <p:input port="entry">
                <p:pipe step="package-doc" port="result"/>
            </p:input>
        </px:fileset-add-entry>
    </p:group>

    <!--=========================================================================-->
    <!-- GENERATE THE OCF DOCUMENTS                                              -->
    <!-- (container.xml, manifest.xml, metadata.xml, rights.xml, signature.xml)  -->
    <!--=========================================================================-->

    <!--
        change fileset base from EPUB/ directory to top directory because this is what
        px:epub3-ocf-finalize expects
    -->
    <px:fileset-rebase>
        <p:with-option name="new-base" select="$epub-dir"/>
    </px:fileset-rebase>
    
    <p:group name="ocf">
        <p:output port="fileset" primary="true">
            <p:pipe step="ocf-finalize" port="result"/>
        </p:output>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="in-memory" port="result.in-memory"/>
        </p:output>
        <px:epub3-ocf-finalize name="ocf-finalize"/>
        <!--
            Remove files from memory that are not in fileset
        -->
        <px:fileset-update name="in-memory">
            <p:input port="source.in-memory">
                <p:pipe step="ocf-finalize" port="in-memory.out"/>
                <p:pipe step="add-package-doc" port="in-memory"/>
            </p:input>
             <p:input port="update">
                 <!-- update empty because only calling px:fileset-update for purging in-memory port -->
                <p:empty/>
            </p:input>
        </px:fileset-update>
        <p:sink/>
    </p:group>
    <p:sink/>

    <!--=========================================================================-->
    <!-- Status                                                                  -->
    <!--=========================================================================-->

    <p:rename match="/*" new-name="d:validation-status" name="validation-status">
        <p:input port="source">
            <p:pipe step="tts" port="status"/>
        </p:input>
    </p:rename>

</p:declare-step>
