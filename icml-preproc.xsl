<?xml version="1.0" encoding="UTF-8"?>
<!--
Adobe ICML preprocessor stylesheet
==================================

Copyright (c) 2014 Lorenz Schori <lo@znerol.ch>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

This stylesheet produces a simplified structure from Adobe InCopy 4 ICML file
format. Due to its structure ICML is somewhat hard to transform into Markup for
the Web, especially because ParagraphStyleRanges do not necessarely correspond
exactly to paragraph boundaries.

The format produced by this template is a variation of the one from the
original icml-preproc.xsl. It additionally groups successive p-elements having
the same paragraph style into a section. This especially helps when it is
necessary to wrap a container around elements of the same class (e.g. lists).
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:func="http://exslt.org/functions"
    xmlns:short-story="https://github.com/znerol/Short-Story"
    extension-element-prefixes="func"
    exclude-result-prefixes="short-story"
>

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:template match="Document">
    <body>
        <xsl:for-each select="//Story">
            <xsl:call-template name="article"/>
        </xsl:for-each>
    </body>
</xsl:template>

<xsl:template match="Content">
    <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="HyperlinkTextSource//Content">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="short-story:get-link-href(.)"/>
        </xsl:attribute>
        <xsl:value-of select="."/>
    </a>
</xsl:template>

<!-- Default template to extract XMP-metadata. If you have an XSLT processor
     which has a parsing extension like saxon:parse, override this template
     in the calling stylesheet -->
<xsl:template name="xmp-extract">
    <xsl:value-of select="." disable-output-escaping="yes"/>
</xsl:template>

<!-- Context: Story node. Extract XMP metadata and regroup all Content nodes
     into section, p and span elements. -->
<xsl:template name="article">
    <article>
        <!-- parse metadata by trying to call external defined xml parsing method
             on embedded RDF/XML XMP stuff -->
        <xsl:for-each select="MetadataPacketPreference/Properties/Contents/text()">
            <xsl:call-template name="xmp-extract"/>
        </xsl:for-each>

        <xsl:for-each select=".//Content[short-story:section-head(.)]">
            <xsl:call-template name="section"/>
        </xsl:for-each>
    </article>
</xsl:template>

<!-- Context: First Content node of a section -->
<xsl:template name="section">
    <section>
        <xsl:attribute name="class">
            <xsl:value-of select="short-story:get-section-class(.)"/>
        </xsl:attribute>

        <xsl:for-each select="short-story:section-elements(.)[short-story:paragraph-head(.)]">
            <xsl:call-template name="paragraph"/>
        </xsl:for-each>
    </section>
</xsl:template>

<!-- Context: First Content node of a paragraph -->
<xsl:template name="paragraph">
    <p>
        <xsl:attribute name="class">
            <xsl:value-of select="short-story:get-paragraph-class(.)"/>
        </xsl:attribute>

        <xsl:for-each select="short-story:paragraph-elements(.)[short-story:fragment-head(.)]">
            <xsl:call-template name="fragment"/>
        </xsl:for-each>
    </p>
</xsl:template>

<!-- Context: Content node -->
<xsl:template name="fragment">
    <span>
        <xsl:attribute name="class">
            <xsl:value-of select="short-story:get-fragment-class(.)"/>
        </xsl:attribute>

        <xsl:for-each select="short-story:fragment-elements(.)">
            <xsl:apply-templates select="."/>
        </xsl:for-each>
    </span>
</xsl:template>



<func:function name="short-story:get-section-class">
    <xsl:param name="n" />
    <func:result select="$n/ancestor-or-self::ParagraphStyleRange[1]/@AppliedParagraphStyle"/>
</func:function>

<func:function name="short-story:get-paragraph-class">
    <xsl:param name="n" />
    <func:result select="short-story:get-section-class($n)"/>
</func:function>

<func:function name="short-story:get-fragment-class">
    <xsl:param name="n" />
    <func:result>
        <xsl:value-of select="$n/ancestor-or-self::CharacterStyleRange[1]/@AppliedCharacterStyle"/>
        <xsl:if test="$n/ancestor-or-self::CharacterStyleRange[1]/@Position">
            <xsl:text> Position-</xsl:text>
            <xsl:value-of select="$n/ancestor-or-self::CharacterStyleRange[1]/@Position"/>
        </xsl:if>
    </func:result>
</func:function>



<func:function name="short-story:section-anchor">
    <xsl:param name="n" />
    <func:result select="($n/ancestor::Story | preceding::Content[short-story:get-section-class(.) != short-story:get-section-class($n)])[position()=last()]"/>
</func:function>

<func:function name="short-story:section-key">
    <xsl:param name="n" />
    <func:result select="generate-id(short-story:section-anchor($n))"/>
</func:function>

<func:function name="short-story:section-elements">
    <xsl:param name="n" />
    <func:result select="key('sections', short-story:section-key($n))"/>
</func:function>

<func:function name="short-story:section-head">
    <xsl:param name="n" />
    <func:result select="$n[count(. | short-story:section-elements(.)[1]) = 1]"/>
</func:function>

<xsl:key name='sections' match='Content' use='short-story:section-key(.)'/>



<func:function name="short-story:paragraph-anchor">
    <xsl:param name="n" />
    <func:result select="(short-story:section-anchor($n) | $n/preceding::Br)[position()=last()]"/>
</func:function>

<func:function name="short-story:paragraph-key">
    <xsl:param name="n" />
    <func:result select="generate-id(short-story:paragraph-anchor($n))"/>
</func:function>

<func:function name="short-story:paragraph-elements">
    <xsl:param name="n" />
    <func:result select="key('paragraphs', short-story:paragraph-key($n))"/>
</func:function>

<func:function name="short-story:paragraph-head">
    <xsl:param name="n" />
    <func:result select="$n[count(. | short-story:paragraph-elements(.)[1]) = 1]"/>
</func:function>

<xsl:key name='paragraphs' match='Content' use='short-story:paragraph-key(.)'/>



<func:function name="short-story:fragment-anchor">
    <xsl:param name="n" />
    <func:result select="(short-story:paragraph-anchor($n) | $n/preceding::Content[short-story:get-fragment-class(.) != short-story:get-fragment-class($n)])[position()=last()]"/>
</func:function>

<func:function name="short-story:fragment-key">
    <xsl:param name="n" />
    <func:result select="generate-id(short-story:fragment-anchor($n))"/>
</func:function>

<func:function name="short-story:fragment-elements">
    <xsl:param name="n" />
    <func:result select="key('fragments', short-story:fragment-key($n))"/>
</func:function>

<func:function name="short-story:fragment-head">
    <xsl:param name="n" />
    <func:result select="$n[count(. | short-story:fragment-elements(.)[1]) = 1]"/>
</func:function>

<xsl:key name='fragments' match='Content' use='short-story:fragment-key(.)'/>



<func:function name="short-story:get-link-href">
    <xsl:param name="n" />
    <func:result select="key('hyperlink_url_destinations', key('hyperlinks', $n/ancestor-or-self::HyperlinkTextSource[1]/@Self)//Destination)/@DestinationURL"/>
</func:function>

<xsl:key name='hyperlinks' match='Hyperlink' use='@Source'/>
<xsl:key name='hyperlink_url_destinations' match='HyperlinkURLDestination' use='@Self'/>

</xsl:stylesheet>
