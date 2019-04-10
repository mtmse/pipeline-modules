<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:odt="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
                xmlns:math="http://www.w3.org/1998/Math/MathML"
                xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                exclude-inline-prefixes="#all"
                type="odt:separate-mathml"
                name="separate-mathml">
	
	<p:documentation xmlns="http://www.w3.org/1999/xhtml">
		<p>Extract MathML formula's from the main content document and put each one in its
		own sub document inside the package. We rely on LibreOffice or MS Word to generate
		the settings files of the sub documents.</p>
	</p:documentation>
	
	<p:input port="fileset.in" primary="true"/>
	<p:input port="in-memory.in" sequence="true"/>
	<p:output port="fileset.out" primary="true">
		<p:pipe step="update" port="result.fileset"/>
	</p:output>
	<p:output port="in-memory.out" sequence="true">
		<p:pipe step="update" port="result.in-memory"/>
	</p:output>
	
	<p:import href="get-file.xpl"/>
	<p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
	<p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
	
	<p:variable name="base" select="//d:file[starts-with(@media-type,'application/vnd.oasis.opendocument')]/resolve-uri(@href, base-uri(.))">
		<p:pipe step="separate-mathml" port="fileset.in"/>
	</p:variable>
	<p:variable name="numbering-offset"
	            select="max((0, for $x in (//d:file[@media-type='application/mathml+xml']/substring-after(resolve-uri(@href, base-uri(.)), $base))
	                                      [matches(., '^Math/mathml_([0-9]+)/content\.xml$')]
	                              return number(replace($x, '^Math/mathml_([0-9]+)/content\.xml$', '$1'))))">
		<p:pipe step="separate-mathml" port="fileset.in"/>
	</p:variable>
	
	<odt:get-file href="content.xml" name="content">
		<p:input port="fileset.in">
			<p:pipe step="separate-mathml" port="fileset.in"/>
		</p:input>
		<p:input port="in-memory.in">
			<p:pipe step="separate-mathml" port="in-memory.in"/>
		</p:input>
	</odt:get-file>
	
	<px:message severity="DEBUG" message="[odt-utils] separating mathml"/>
	
	<p:viewport match="draw:object[math:math]" name="content.temp">
		<p:variable name="href" select="concat('Math/mathml_', number($numbering-offset) + p:iteration-position())"/>
		<p:add-attribute match="/*" attribute-name="xlink:href">
			<p:with-option name="attribute-value" select="$href"/>
		</p:add-attribute>
		<p:add-attribute match="/*" attribute-name="xlink:type" attribute-value="simple"/>
		<p:add-attribute match="/*" attribute-name="xlink:show" attribute-value="embed"/>
		<p:add-attribute match="/*" attribute-name="xlink:actuate" attribute-value="onLoad"/>
		<p:add-attribute match="/*/math:math" attribute-name="xml:base">
			<p:with-option name="attribute-value" select="resolve-uri(concat($href, '/content.xml'), $base)"/>
		</p:add-attribute>
	</p:viewport>
	
	<p:filter select="//draw:object/math:math" name="mathml"/>
	
	<p:delete match="draw:object/math:math" name="content.new">
		<p:input port="source">
			<p:pipe step="content.temp" port="result"/>
		</p:input>
	</p:delete>
	
	<px:fileset-create name="base">
		<p:with-option name="base" select="$base"/>
	</px:fileset-create>
	<p:sink/>
	
	<p:for-each>
		<p:iteration-source>
			<p:pipe step="mathml" port="result"/>
		</p:iteration-source>
		<px:fileset-add-entry media-type="application/mathml+xml">
			<p:input port="source">
				<p:pipe step="base" port="result"/>
			</p:input>
			<p:with-option name="href" select="base-uri(/*)"/>
		</px:fileset-add-entry>
	</p:for-each>
	
	<px:fileset-join name="fileset.mathml"/>
	
	<px:fileset-join name="fileset.with-mathml">
		<p:input port="source">
			<p:pipe step="separate-mathml" port="fileset.in"/>
			<p:pipe step="fileset.mathml" port="result"/>
		</p:input>
	</px:fileset-join>
	<p:sink/>
	
	<px:fileset-update name="update">
		<p:input port="update">
			<p:pipe step="content.new" port="result"/>
		</p:input>
		<p:input port="source.fileset">
			<p:pipe step="fileset.with-mathml" port="result"/>
		</p:input>
		<p:input port="source.in-memory">
			<p:pipe step="separate-mathml" port="in-memory.in"/>
			<p:pipe step="mathml" port="result"/>
		</p:input>
	</px:fileset-update>
	<p:sink/>
	
</p:declare-step>
