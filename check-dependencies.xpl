<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xpath-version="2.0" xmlns:d="http://www.daisy.org/ns/pipeline/data"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:catalog="urn:oasis:names:tc:entity:xmlns:xml:catalog">
    
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:type="name">XProc+XSLT Dependency Checker</h1>
    </p:documentation>
    
    <p:option name="report-base" select="'..'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:type="name">The parent directory to all your pipeline module repositories.</h1>
            <p px:type="desc">For instance <code>file:/home/user/daisy-pipeline.modules/</code>. The scripts/scripts-utils/common-utils repositories are expected to be subdirectories of this directory.</p>
        </p:documentation>
    </p:option>

    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/xproc/fileset-library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/xproc/file-library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/mediatype-utils/mediatype.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/validation-utils/validation-utils-library.xpl"/>

    <p:variable name="reportBase" select="resolve-uri($report-base,replace(base-uri(/),'[^/]+$',''))">
        <p:inline>
            <this/>
        </p:inline>
    </p:variable>

    <p:directory-list>
        <p:with-option name="path" select="$reportBase"/>
    </p:directory-list>
    <p:add-xml-base all="true" relative="false"/>
    <p:for-each name="repo">
        <p:iteration-source select="/*/c:directory[not(starts-with(@name,'.'))]"/>
        <p:directory-list>
            <p:with-option name="path" select="concat(/*/@xml:base,/*/@name)"/>
        </p:directory-list>
        <p:add-xml-base all="true" relative="false"/>
        <p:for-each name="module">
            <p:iteration-source select="/*/c:directory[not(starts-with(@name,'.'))]"/>
            <p:identity name="module.current"/>
            <px:directory-list>
                <p:with-option name="path" select="concat(/*/@xml:base,/*/@name,'/src/main/resources/')"/>
            </px:directory-list>
            <p:delete match="/*/c:directory[@name='META-INF']"/>
            <px:fileset-from-dir-list/>
            <px:mediatype-detect name="module.fileset">
                <p:input port="in-memory">
                    <p:empty/>
                </p:input>
            </px:mediatype-detect>

            <px:fileset-filter media-types="application/xproc+xml application/xslt+xml"/>

            <p:viewport match="/*/d:file[@media-type='application/xproc+xml']" name="iterate-xproc">
                <p:load>
                    <p:with-option name="href" select="resolve-uri(/*/@href,base-uri(/*))"/>
                </p:load>
                <p:for-each>
                    <p:iteration-source select="//p:import | //p:document | //p:load[@href]"/>
                    <p:add-attribute match="/*" attribute-name="href">
                        <p:with-option name="attribute-value" select="/*/@href"/>
                        <p:input port="source">
                            <p:inline exclude-inline-prefixes="#all">
                                <d:ref/>
                            </p:inline>
                        </p:input>
                    </p:add-attribute>
                </p:for-each>
                <p:insert match="/*" position="first-child">
                    <p:input port="source">
                        <p:pipe port="current" step="iterate-xproc"/>
                    </p:input>
                </p:insert>
                <p:delete match="/*/d:ref[not(matches(@href,'^[^/]+:'))]"/>
            </p:viewport>

            <p:viewport match="/*/d:file[@media-type='application/xslt+xml']" name="iterate-xslt">
                <p:load>
                    <p:with-option name="href" select="resolve-uri(/*/@href,base-uri(/*))"/>
                </p:load>
                <p:for-each>
                    <p:iteration-source select="(//xsl:import | //xsl:include)[@href]"/>
                    <p:add-attribute match="/*" attribute-name="href">
                        <p:with-option name="attribute-value" select="/*/@href"/>
                        <p:input port="source">
                            <p:inline exclude-inline-prefixes="#all">
                                <d:ref/>
                            </p:inline>
                        </p:input>
                    </p:add-attribute>
                </p:for-each>
                <p:insert match="/*" position="first-child">
                    <p:input port="source">
                        <p:pipe port="current" step="iterate-xslt"/>
                    </p:input>
                </p:insert>
                <p:delete match="/*/d:ref[not(matches(@href,'^[^/]+:'))]"/>
            </p:viewport>

            <p:viewport match="//d:ref">
                <p:choose>
                    <p:when test="starts-with(/*/@href,'http://www.daisy.org/pipeline/')">
                        <p:add-attribute match="/*" attribute-name="catalog">
                            <p:with-option name="attribute-value" select="replace(/*/@href,'http://www.daisy.org/pipeline/+([^/]+)/+([^/]+)/.*','org:daisy:pipeline:$1:$2')"/>
                        </p:add-attribute>
                    </p:when>
                    <p:when test="/*/@href='http://xmlcalabash.com/extension/steps/library-1.0.xpl'">
                        <p:add-attribute match="/*" attribute-name="catalog">
                            <p:with-option name="attribute-value" select="'com:xmlcalabash'"/>
                        </p:add-attribute>
                    </p:when>
                    <p:otherwise>
                        <p:identity/>
                    </p:otherwise>
                </p:choose>
            </p:viewport>
            <p:delete match="//d:ref[preceding::d:ref/@catalog=@catalog]"/>
            <p:add-xml-base all="true" relative="false"/>
            <p:identity name="module.refs"/>
            <p:sink/>

            <p:load name="module.catalog">
                <p:with-option name="href" select="concat(/*/@xml:base,/*/@name,'/src/main/resources/META-INF/catalog.xml')">
                    <p:pipe port="current" step="module"/>
                </p:with-option>
            </p:load>
            <p:sink/>

            <p:group name="unavailable">
                <p:output port="result"/>
                <p:identity>
                    <p:input port="source">
                        <p:pipe port="result" step="module.refs"/>
                    </p:input>
                </p:identity>
                <p:for-each name="unavailable.file">
                    <p:iteration-source select="//d:file"/>
                    <p:variable name="file-href" select="/*/@href"/>
                    <p:variable name="file-href-full" select="resolve-uri(/*/@href,/*/@xml:base)"/>
                    <p:for-each name="ref">
                        <p:output port="result" sequence="true"/>
                        <p:iteration-source select="//d:ref"/>
                        <p:variable name="catalog" select="/*/@catalog"/>
                        <p:variable name="ref" select="/*/@href"/>
                        <p:identity>
                            <p:input port="source">
                                <p:pipe step="module.catalog" port="result"/>
                            </p:input>
                        </p:identity>
                        <p:choose>
                            <p:when test="$catalog=//catalog:nextCatalog/@catalog">
                                <p:sink/>
                                <p:identity>
                                    <p:input port="source">
                                        <p:empty/>
                                    </p:input>
                                </p:identity>
                            </p:when>
                            <p:otherwise>
                                <p:in-scope-names name="module.ref.vars"/>
                                <p:template>
                                    <p:input port="template">
                                        <p:inline>
                                            <d:error type="file-not-found">
                                                <d:desc>Dependency is not declared in catalog.xml: {$catalog}</d:desc>
                                                <d:file>{$ref}</d:file>
                                                <d:location href="{$file-href-full}"/>
                                            </d:error>
                                        </p:inline>
                                    </p:input>
                                    <p:input port="source">
                                        <p:inline>
                                            <doc/>
                                        </p:inline>
                                    </p:input>
                                    <p:input port="parameters">
                                        <p:pipe step="module.ref.vars" port="result"/>
                                    </p:input>
                                </p:template>
                            </p:otherwise>
                        </p:choose>
                    </p:for-each>
                </p:for-each>
                <p:wrap-sequence wrapper="d:errors"/>
                <p:wrap-sequence wrapper="d:report"/>
                <p:add-attribute match="/*" attribute-name="type" attribute-value="filecheck"/>
            </p:group>

            <p:group name="unused">
                <p:output port="result"/>
                <p:identity>
                    <p:input port="source">
                        <p:pipe port="result" step="module.catalog"/>
                    </p:input>
                </p:identity>
                <p:for-each name="nextCatalog">
                    <p:output port="result" sequence="true"/>
                    <p:iteration-source select="//catalog:nextCatalog"/>
                    <p:variable name="catalog" select="/*/@catalog"/>
                    <p:identity>
                        <p:input port="source">
                            <p:pipe step="module.refs" port="result"/>
                        </p:input>
                    </p:identity>
                    <p:choose>
                        <p:when test="$catalog=//d:ref/@catalog">
                            <p:sink/>
                            <p:identity>
                                <p:input port="source">
                                    <p:empty/>
                                </p:input>
                            </p:identity>
                        </p:when>
                        <p:otherwise>
                            <p:variable name="catalog-uri" select="concat(/*/@xml:base,/*/@name,'/src/main/resources/META-INF/catalog.xml')">
                                <p:pipe port="current" step="module"/>
                            </p:variable>
                            <p:in-scope-names name="module.nextCatalog.vars"/>
                            <p:template>
                                <p:input port="template">
                                    <p:inline>
                                        <d:error type="file-not-found">
                                            <d:desc>Unused dependency</d:desc>
                                            <d:file>{normalize-space(/*/@catalog)}</d:file>
                                            <d:location href="{$catalog-uri}"/>
                                        </d:error>
                                    </p:inline>
                                </p:input>
                                <p:input port="source">
                                    <p:pipe port="current" step="nextCatalog"/>
                                </p:input>
                                <p:input port="parameters">
                                    <p:pipe step="module.nextCatalog.vars" port="result"/>
                                </p:input>
                            </p:template>
                        </p:otherwise>
                    </p:choose>
                </p:for-each>
                <p:wrap-sequence wrapper="d:errors"/>
                <p:wrap-sequence wrapper="d:report"/>
                <p:add-attribute match="/*" attribute-name="type" attribute-value="filecheck"/>
            </p:group>

            <p:wrap-sequence wrapper="d:reports">
                <p:input port="source">
                    <p:pipe port="result" step="unavailable"/>
                    <p:pipe port="result" step="unused"/>
                </p:input>
            </p:wrap-sequence>
            <p:wrap-sequence wrapper="d:document-validation-report" name="report-without-info"/>
            <p:in-scope-names name="module.vars"/>
            <p:template name="report-info">
                <p:input port="template">
                    <p:inline>
                        <d:document-info>
                            <d:document-name>{normalize-space(/*/@name)}</d:document-name>
                            <d:document-type>XProc+XSLT Dependency Check</d:document-type>
                            <d:document-path>{concat(/*/@xml:base,/*/@name)}</d:document-path>
                        </d:document-info>
                    </p:inline>
                </p:input>
                <p:input port="source">
                    <p:pipe port="current" step="module"/>
                </p:input>
                <p:input port="parameters">
                    <p:pipe step="module.vars" port="result"/>
                </p:input>
            </p:template>
            <p:insert match="/*" position="first-child">
                <p:input port="source">
                    <p:pipe port="result" step="report-without-info"/>
                </p:input>
                <p:input port="insertion">
                    <p:pipe port="result" step="report-info"/>
                </p:input>
            </p:insert>
        </p:for-each>
    </p:for-each>

    <px:validation-report-to-html/>
    <p:store href="file:/tmp/report.html"/>

</p:declare-step>
