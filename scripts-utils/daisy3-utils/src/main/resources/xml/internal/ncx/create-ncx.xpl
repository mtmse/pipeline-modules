<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                type="px:daisy3-create-ncx" name="main">

    <p:input port="content" primary="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>DTBook document with the smilref attributes.</p>
      </p:documentation>
    </p:input>

    <p:input port="audio-map">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>List of audio clips (see ssml-to-audio documentation)</p>
      </p:documentation>
    </p:input>

    <p:option name="audio-dir">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>Parent directory URI of the audio files.</p>
      </p:documentation>
    </p:option>

    <p:option name="smil-dir">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>Parent directory URI of the smil files.</p>
      </p:documentation>
    </p:option>

    <p:option name="ncx-dir">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>Output directory URI if the NCX file were to be stored or refered by a fileset.</p>
      </p:documentation>
    </p:option>

    <p:option name="uid">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<p>UID of the DTBook (in the meta elements)</p>
      </p:documentation>
    </p:option>

    <p:output port="result" primary="true">
      <p:pipe step="ncx" port="result"/>
    </p:output>
    <p:output port="result.fileset">
      <p:pipe step="fileset" port="result"/>
    </p:output>

    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl">
        <p:documentation>
            px:set-base-uri
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
      <p:documentation>
        px:fileset-create
        px:fileset-add-entry
      </p:documentation>
    </p:import>

    <p:xslt>
      <p:input port="source">
	<p:pipe port="content" step="main"/>
	<p:pipe port="audio-map" step="main"/>
      </p:input>
      <p:input port="stylesheet">
	<p:document href="create-ncx.xsl"/>
      </p:input>
      <p:with-param name="mo-dir" select="$smil-dir"/>
      <p:with-param name="audio-dir" select="$audio-dir"/>
      <p:with-param name="ncx-dir" select="$ncx-dir"/>
      <p:with-param name="uid" select="$uid"/>
    </p:xslt>

    <px:set-base-uri>
      <p:with-option name="base-uri" select="concat($ncx-dir, 'navigation.ncx')"/>
    </px:set-base-uri>
    <p:identity name="ncx"/>
    <p:sink/>

    <px:fileset-create>
      <p:with-option name="base" select="$ncx-dir"/>
    </px:fileset-create>
    <px:fileset-add-entry media-type="application/x-dtbncx+xml" name="fileset">
      <p:input port="entry">
        <p:pipe step="ncx" port="result"/>
      </p:input>
      <p:with-param port="file-attributes" name="indent" select="'true'"/>
      <p:with-param port="file-attributes" name="doctype-public" select="'-//NISO//DTD ncx 2005-1//EN'"/>
      <p:with-param port="file-attributes" name="doctype-system" select="'http://www.daisy.org/z3986/2005/ncx-2005-1.dtd'"/>
    </px:fileset-add-entry>
    <p:sink/>

</p:declare-step>
