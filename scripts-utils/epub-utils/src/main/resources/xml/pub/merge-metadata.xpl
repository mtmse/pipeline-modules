<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                exclude-inline-prefixes="#all"
                type="pxi:merge-metadata" name="main">

	<p:documentation xmlns="http://www.w3.org/1999/xhtml">
		<p>Merge and augment EPUB Publications metadata</p>
	</p:documentation>

	<p:input port="source" sequence="true" primary="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<p>A set of <code>metadata</code> documents in the OPF namespace</p>
		</p:documentation>
	</p:input>

	<p:input port="manifest">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<p>The <code>manifest</code> document</p>
		</p:documentation>
	</p:input>

	<p:option name="reserved-prefixes" required="false" select="'#default'"/>

	<p:option name="log-conflicts" required="false" select="'true'">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<p>Whether to create log messages when there are fields with the same property in
			different documents.</p>
		</p:documentation>
	</p:option>

	<p:output port="result">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<p>A single <code>metadata</code> document in the OPF namespace, containing the merged
			metadata. When the same metadata (the same property) exists in multiple input documents,
			the first occurences win. Elements that are not valid OPF 3 metadata elements are
			removed.</p>
		</p:documentation>
	</p:output>

	<p:import href="merge-prefix.xpl">
		<p:documentation>
			px:epub3-merge-prefix
		</p:documentation>
	</p:import>

	<p:wrap-sequence wrapper="_">
		<!-- wrap input documents in a common root element (the name of the wrapper is insignificant) -->
	</p:wrap-sequence>

	<px:epub3-merge-prefix name="metadata-with-single-prefix-attribute">
		<p:with-option name="implicit-output-prefixes" select="$reserved-prefixes">
			<p:empty/>
		</p:with-option>
	</px:epub3-merge-prefix>

	<p:xslt>
		<p:input port="source">
			<p:pipe step="metadata-with-single-prefix-attribute" port="result"/>
			<p:pipe step="main" port="manifest"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="create-metadata.merge.xsl"/>
		</p:input>
		<p:with-param name="reserved-prefixes" select="$reserved-prefixes">
			<p:empty/>
		</p:with-param>
		<p:with-param name="log-conflicts" select="$log-conflicts">
			<p:empty/>
		</p:with-param>
	</p:xslt>

</p:declare-step>
