<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal" xmlns:html="http://www.w3.org/1999/xhtml" type="px:epub3-validator" version="1.0" xmlns:d="http://www.daisy.org/ns/pipeline/data">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">EPUB3 Validator</h1>
        <p px:role="desc">Validates a EPUB.</p>
        <address px:role="author maintainer">
            <p>Script wrapper for epubcheck maintained by <span px:role="name">Jostein Austvik Jacobsen</span>
                (organization: <span px:role="organization">NLB</span>,
                e-mail: <a px:role="contact" href="mailto:josteinaj@gmail.com">josteinaj@gmail.com</a>).</p>
        </address>
        <p><a px:role="homepage" href="http://code.google.com/p/daisy-pipeline/wiki/EpubCheckDoc">Online Documentation</a></p>
    </p:documentation>

    <p:option name="epub" required="true" px:type="anyFileURI" px:media-type="application/epub+zip application/oebps-package+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">EPUB</h2>
            <p px:role="desc">EPUB to be validated.</p>
        </p:documentation>
    </p:option>

    <p:option name="mode" required="false" px:type="string" select="'epub'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">What to validate</h2>
            <p px:role="desc">One of: "epub" (the entire epub), "opf" (the package file), "xhtml" (the content files), "svg" (vector graphics), "mo" (media overlays), "nav" (the navigation document)
                or "expanded" (like "epub" but unzipped).</p>
        </p:documentation>
    </p:option>

    <p:option name="version" required="false" px:type="string" select="'3'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">EPUB version</h2>
            <p px:role="desc">The EPUB version to validate against. Default is "3". Values allowed are: "2" and "3".</p>
        </p:documentation>
    </p:option>

    <p:output port="html-report" px:media-type="application/vnd.pipeline.report+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">HTML Report</h1>
            <p px:role="desc">An HTML-formatted version of the validation report.</p>
        </p:documentation>
        <p:pipe port="result" step="html-report"/>
    </p:output>

    <p:output port="validation-status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h1 px:role="name">Validation status</h1>
            <p px:role="desc">Validation status (http://code.google.com/p/daisy-pipeline/wiki/ValidationStatusXML).</p>
        </p:documentation>
        <p:pipe port="result" step="status"/>
    </p:output>

    <p:import href="step/validate.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/epubcheck-adapter/library.xpl"/>

    <px:epub3-validator.validate name="validate">
        <p:with-option name="epub" select="$epub"/>
        <p:with-option name="mode" select="$mode"/>
        <p:with-option name="version" select="$version"/>
    </px:epub3-validator.validate>

    <p:xslt name="html-report">
        <p:input port="source">
            <p:pipe port="report.out" step="validate"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/epubcheck-pipeline-report-to-html-report.xsl"/>
        </p:input>
    </p:xslt>
    <p:sink/>

    <p:group name="status">
        <p:output port="result"/>
        <p:for-each>
            <p:iteration-source select="/d:document-validation-report/d:document-info/d:error-count">
                <p:pipe port="report.out" step="validate"/>
            </p:iteration-source>
            <p:identity/>
        </p:for-each>
        <p:wrap-sequence wrapper="d:validation-status"/>
        <p:add-attribute attribute-name="result" match="/*">
            <p:with-option name="attribute-value" select="if (sum(/*/*/number(.))&gt;0) then 'error' else 'ok'"/>
        </p:add-attribute>
        <p:delete match="/*/node()"/>
    </p:group>
    <p:sink/>

</p:declare-step>
