<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                type="px:epub3-to-daisy202" name="main">

    <p:input port="source.fileset" primary="true"/>
    <p:input port="source.in-memory" sequence="true"/>

    <p:output port="result.fileset" primary="true">
        <p:pipe step="move" port="result.fileset"/>
    </p:output>
    <p:output port="result.in-memory" sequence="true">
        <p:pipe step="move" port="result.in-memory"/>
    </p:output>

    <p:option name="bundle-dtds" select="'false'"/>
    <p:option name="output-dir" required="true"/>

    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:assert
            px:error
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-filter
            px:fileset-load
            px:fileset-rebase
            px:fileset-copy
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/epub-utils/library.xpl">
        <p:documentation>
            px:opf-spine-to-fileset
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/html-utils/library.xpl">
        <p:documentation>
            px:html-upgrade
            px:html-downgrade
            px:html-outline
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/daisy202-utils/library.xpl">
        <p:documentation>
            px:daisy202-rename-files
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/smil-utils/library.xpl">
        <p:documentation>
            px:smil-downgrade
        </p:documentation>
    </p:import>
    <p:import href="create-ncc.xpl">
        <p:documentation>
            pxi:create-ncc
        </p:documentation>
    </p:import>
    
    <p:documentation>
        Extract and verify the OPF.
    </p:documentation>
    <px:fileset-load media-types="application/oebps-package+xml">
        <p:input port="in-memory">
            <p:pipe step="main" port="source.in-memory"/>
        </p:input>
    </px:fileset-load>
    <px:assert test-count-min="1" test-count-max="1" error-code="PED01" message="The EPUB must contain exactly one OPF document"/>
    <px:assert error-code="PED02" message="There must be at least one dc:identifier meta element in the OPF document">
        <p:with-option name="test" select="exists(/opf:package/opf:metadata/dc:identifier)"/>
    </px:assert>
    <p:identity name="opf"/>
    <p:sink/>

    <p:documentation>
        Convert from EPUB 3 SMIL to DAISY 2.02 SMIL.
    </p:documentation>
    <px:fileset-load media-types="application/smil+xml" name="epub3.smil.in-memory">
        <p:documentation>
            Load SMIL files.
        </p:documentation>
        <p:input port="fileset">
            <p:pipe step="main" port="source.fileset"/>
        </p:input>
        <p:input port="in-memory">
            <p:pipe step="main" port="source.in-memory"/>
        </p:input>
    </px:fileset-load>
    <p:for-each px:message="Converting SMIL 3.0 to SMIL 1.0" px:progress="1/5">
        <p:variable name="smil-base" select="base-uri(/*)"/>
        <p:variable name="smil-href" select="//d:file[resolve-uri(@href,base-uri(.))=$smil-base]/@href">
            <p:pipe step="epub3.smil.in-memory" port="result.fileset"/>
        </p:variable>
        <px:smil-downgrade version="1.0" px:message="Processing {$smil-href}"/>
    </p:for-each>
    <p:identity name="daisy202.smil.in-memory"/>
    <p:sink/>

    <p:documentation>
        Convert from EPUB 3 HTML to DAISY 2.02 HTML.
    </p:documentation>
    <px:opf-spine-to-fileset>
        <p:documentation>
            Get spine.
        </p:documentation>
        <p:input port="source.fileset">
            <p:pipe step="main" port="source.fileset"/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="opf" port="result"/>
        </p:input>
    </px:opf-spine-to-fileset>
    <px:fileset-load name="epub3.xhtml">
        <p:documentation>
            Load content documents.
        </p:documentation>
        <p:input port="in-memory">
            <p:pipe step="main" port="source.in-memory"/>
        </p:input>
    </px:fileset-load>
    <p:for-each px:message="Converting HTML5 to HTML4" px:progress="1/5">
        <p:variable name="base" select="base-uri()"/>
        <p:variable name="href" select="//d:file[resolve-uri(@href,base-uri(.))=$base]/@href">
            <p:pipe step="epub3.xhtml" port="result.fileset"/>
        </p:variable>
        <p:identity px:message="Processing {$href}"/>
        <px:html-upgrade>
            <p:documentation>Normalize HTML5.</p:documentation>
            <!-- hopefully this preserves all IDs -->
        </px:html-upgrade>
        <px:html-downgrade>
            <p:documentation>Downgrade to HTML4. This preserves all ID.</p:documentation>
        </px:html-downgrade>
        <px:html-outline name="fix-heading-ranks" fix-heading-ranks="outline-depth" output-base-uri="file:/irrelevant">
            <p:documentation>Make sure heading hierarchy is correct in output</p:documentation>
            <!-- Note that this is already done once in px:html-downgrade but we do it a second time
                 after the sectioning elements have been converted, so that if the first heading is
                 a h2 everything shifts up one level. -->
        </px:html-outline>
        <p:sink/>
        <p:identity>
            <p:input port="source">
                <p:pipe step="fix-heading-ranks" port="content-doc"/>
            </p:input>
        </p:identity>
    </p:for-each>
    <p:identity name="daisy202.xhtml.in-memory"/>
    <p:sink/>

    <p:documentation>
        Create DAISY 2.02 fileset manifest.
    </p:documentation>
    <p:identity>
        <p:input port="source">
            <p:pipe step="main" port="source.fileset"/>
        </p:input>
    </p:identity>
    <p:choose>
        <p:when test="//d:file[matches(@href,'^(.+/)?mimetype$')]">
            <p:documentation>
                Make the base URI the directory containing the mimetype file.
            </p:documentation>
            <px:fileset-rebase>
                <p:with-option name="new-base"
                               select="//d:file[matches(@href,'^(.+/)?mimetype$')][1]
                                       /replace(resolve-uri(@href,base-uri(.)),'mimetype$','')"/>
            </px:fileset-rebase>
        </p:when>
        <p:otherwise>
            <px:error code="XXXXX" message="Fileset must contain a 'mimetype' file"/>
        </p:otherwise>
    </p:choose>
    <p:group>
        <p:documentation>
            - Delete package document (OPF).
            - Delete table of contents (NCX).
            - Delete original navigation document. It will be replaced with the generated NCC.
            - Delete mimetype and META-INF/.
            - Delete files outside of the directory that contains the mimetype.
        </p:documentation>
        <p:variable name="nav" select="(//opf:item[tokenize(@properties,'\s+')='nav']/resolve-uri(@href,base-uri()))[1]">
            <p:pipe step="opf" port="result"/>
        </p:variable>
        <p:delete>
            <p:with-option name="match"
                           select="concat('
                                     //d:file[@media-type=(&quot;application/oebps-package+xml&quot;,
                                                           &quot;application/x-dtbncx+xml&quot;)
                                              or (&quot;',$nav,'&quot;!=&quot;&quot;
                                                  and @media-type=&quot;application/xhtml+xml&quot;
                                                  and &quot;',$nav,'&quot;=resolve-uri(@href,base-uri()))
                                              or starts-with(@href,&quot;..&quot;)
                                              or starts-with(@href,&quot;META-INF/&quot;)
                                              or @href=&quot;mimetype&quot;]
                                   ')"/>
        </p:delete>
    </p:group>

    <p:documentation>
        Create NCC file.
    </p:documentation>
    <pxi:create-ncc name="create-ncc" px:message="Creating NCC" px:progress="2/5">
        <p:input port="source.in-memory">
            <p:pipe port="result" step="daisy202.xhtml.in-memory"/>
            <p:pipe port="result" step="daisy202.smil.in-memory"/>
        </p:input>
        <p:input port="opf">
            <p:pipe step="opf" port="result"/>
        </p:input>
    </pxi:create-ncc>

    <p:documentation>
        Rename content documents to .html.
    </p:documentation>
    <p:group name="rename-xhtml" px:message="Renaming content documents to .html" px:progress="1/5">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="rename" port="result.in-memory"/>
        </p:output>
        <px:fileset-filter media-types="application/xhtml+xml"/>
        <p:label-elements match="d:file" attribute="original-href" replace="true"
                          label="resolve-uri(@href,base-uri(.))"/>
        <p:label-elements match="d:file" attribute="href" replace="true"
                          label="replace(@href,'^(.*)\.([^/\.]*)$','$1.html')"/>
        <p:delete match="/*/*[not(self::d:file)]"/>
        <p:delete match="d:file/@*[not(name()=('href','original-href'))]" name="rename-xhtml-mapping"/>
        <p:sink/>
        <px:daisy202-rename-files name="rename">
            <p:input port="source.fileset">
                <p:pipe step="create-ncc" port="result.fileset"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="create-ncc" port="result.in-memory"/>
            </p:input>
            <p:input port="mapping">
                <p:pipe step="rename-xhtml-mapping" port="result"/>
            </p:input>
        </px:daisy202-rename-files>
    </p:group>

    <p:documentation>
        Flatten DAISY 2.02 directory structure.
        Don't rename CSS, images and font files because that could break links in CSS.
    </p:documentation>
    <p:group name="flatten-daisy202">
        <p:output port="fileset" primary="true"/>
        <p:output port="in-memory" sequence="true">
            <p:pipe step="rename" port="result.in-memory"/>
        </p:output>
        <px:fileset-filter media-types="application/xhtml+xml
                                        application/smil+xml
                                        audio/mpeg
                                        audio/mp4"/>
        <px:fileset-copy flatten="true" dry-run="true" name="flatten">
            <p:with-option name="target" select="base-uri(/*)"/>
        </px:fileset-copy>
        <p:sink/>
        <px:daisy202-rename-files name="rename">
            <p:input port="source.fileset">
                <p:pipe step="rename-xhtml" port="fileset"/>
            </p:input>
            <p:input port="source.in-memory">
                <p:pipe step="rename-xhtml" port="in-memory"/>
            </p:input>
            <p:input port="mapping">
                <p:pipe step="flatten" port="mapping"/>
            </p:input>
        </px:daisy202-rename-files>
    </p:group>

    <p:documentation>
        Finalize DAISY 2.02 fileset manifest: set DOCTYPE on XHTML and SMIL files
    </p:documentation>
    <p:add-attribute match="d:file[@media-type='application/xhtml+xml']"
                     attribute-name="doctype-public"
                     attribute-value="-//W3C//DTD XHTML 1.0 Transitional//EN"/>
    <p:add-attribute match="d:file[@media-type='application/xhtml+xml']"
                     attribute-name="doctype-system"
                     attribute-value="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
    <p:add-attribute match="d:file[@media-type='application/smil+xml']"
                     attribute-name="doctype-public"
                     attribute-value="-//W3C//DTD SMIL 1.0//EN"/>
    <p:add-attribute match="d:file[@media-type='application/smil+xml']"
                     attribute-name="doctype-system"
                     attribute-value="http://www.w3.org/TR/REC-SMIL/SMIL10.dtd"/>

    <p:documentation>
        Move to final location
    </p:documentation>
    <px:fileset-copy name="move">
        <p:with-option name="target" select="concat($output-dir,replace(/*/@content,'[^a-zA-Z0-9]','_'),'/')">
            <p:pipe step="identifier" port="result"/>
        </p:with-option>
        <p:input port="source.in-memory">
            <p:pipe step="flatten-daisy202" port="in-memory"/>
        </p:input>
    </px:fileset-copy>
    <p:sink/>

    <p:group name="identifier">
        <p:output port="result"/>
        <p:identity>
            <p:input port="source">
                <p:pipe step="create-ncc" port="ncc"/>
            </p:input>
        </p:identity>
        <!--
            these assertions should normally never fail
        -->
        <px:assert test-count-min="1" test-count-max="1" error-code="PED01"
                   message="There must be exactly one ncc.html in the resulting DAISY 2.02 fileset"/>
        <p:filter select="/*/*/*[@name='dc:identifier']"/>
        <px:assert test-count-min="1" error-code="PED02"
                   message="There must be at least one dc:identifier meta element in the resulting ncc.html"/>
        <p:split-sequence test="position()=1"/>
    </p:group>
    <p:sink/>

</p:declare-step>
