<?xml version="1.0" encoding="UTF-8"?>
<!--

Part of Teinte https://github.com/oeuvres/teinte
BSD-3-Clause https://opensource.org/licenses/BSD-3-Clause
Copyright (c) 2020 frederic.glorieux@fictif.org
Copyright (c) 2013 Frederic.Glorieux@fictif.org et LABEX OBVIL
Copyright (c) 2012 Frederic.Glorieux@fictif.org 
Copyright (c) 2010 Frederic.Glorieux@fictif.org et École nationale des chartes


Split a single TEI book in different html chapters

-->
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  exclude-result-prefixes="tei html"
  
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"

  >
  <!--
  <xsl:include href="../vendor/oeuvres/xsl/tei_html/tei_header_html.xsl"/>
  <xsl:include href="../vendor/oeuvres/xsl/tei_html/tei_flow_html.xsl"/>
  <xsl:include href="../vendor/oeuvres/xsl/tei_html/tei_notes_html.xsl"/>
  <xsl:include href="../vendor/oeuvres/xsl/tei_html/tei_toc_html.xsl"/>
  -->
  <xsl:include href="../../teinte-xsl/tei_html/tei_header_html.xsl"/>
  <xsl:include href="../../teinte-xsl/tei_html/tei_flow_html.xsl"/>
  <xsl:include href="../../teinte-xsl/tei_html/tei_notes_html.xsl"/>
  <xsl:include href="../../teinte-xsl/tei_html/tei_toc_html.xsl"/>
  <xsl:output indent="yes" encoding="UTF-8" method="xml"/>
  <!-- Split chapters when we have -->
  <xsl:variable name="split" select="true()"/>
  <!-- Where to find images -->
  <xsl:param name="images"/>
  <!-- Transmit edition status -->
  <xsl:param name="status"/>
  <!-- Where to find static assets like CSS or JS -->
  <xsl:param name="theme">https://oeuvres.github.io/teinte_theme/</xsl:param>
  <!-- extension for links (not the generated files) -->
  <xsl:param name="_ext" select="''"/>
  <!-- Prefix for canonical url -->
  <xsl:param name="urlprefix">https://www.unige.ch/rougemont/</xsl:param>  
  <xsl:key name="split" match="
tei:*[self::tei:div or self::tei:div1 or self::tei:div2][normalize-space(.) != ''][@type][
  contains(@type, 'article') 
    or contains(@type, 'chapter') 
    or contains(@subtype, 'split') 
    or contains(@type, 'act')  
    or contains(@type, 'poem')
    or contains(@type, 'letter')
] 
| tei:group/tei:text 
" use="generate-id(.)"/>
  <!-- Rights protection -->
  <xsl:param name="closed-access"
    select="/tei:TEI/tei:teiHeader/tei:profileDesc/tei:textClass/tei:keywords/tei:term[. = '#sous-droits']"/>
  <!-- id of the document -->
  <xsl:param name="docid"/>
  <!-- Required, folder where to project the generated files -->
  <xsl:param name="dstDir">html/</xsl:param>
  <xsl:variable name="issued">
    <xsl:variable name="date" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:imprint/tei:date"/>
    <xsl:choose>
      <xsl:when test="$date/@when">
        <xsl:value-of select="$date/@when"/>
      </xsl:when>
      <xsl:when test="$date != ''">
        <xsl:value-of select="$date"/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="booktitle">
  <xsl:choose>
      <xsl:when test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title">
        <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$doctitle"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="byline">
    <xsl:choose>
      <xsl:when test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct">
        <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct" mode="byline"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt" mode="byline"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Process root -->
  <xsl:template match="/*" name="split">
    <!--There are chapters -->
    <xsl:choose>
      <xsl:when test=".//tei:div[key('split', generate-id())]">
      <xsl:variable name="href">
        <xsl:value-of select="$dstDir"/>
        <xsl:value-of select="$docid"/>
        <xsl:text>.html</xsl:text>
      </xsl:variable>
      <exsl:document href="{$href}" omit-xml-declaration="yes" encoding="UTF-8" indent="yes">
        <xsl:call-template name="toc"/>
      </exsl:document>
        <!-- No book cover for now
        <xsl:call-template name="book"/>
        -->
        <xsl:apply-templates select="." mode="split"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="article"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Default, go through -->
  <xsl:template match="*" mode="split">
    <xsl:apply-templates mode="split"/>
  </xsl:template>
  <!-- Do not output text -->
  <xsl:template match="text()" mode="split"/>

  <!-- Redirect images -->
  <xsl:template match="tei:graphic">
    <xsl:variable name="id">
      <xsl:call-template name="id"/>
    </xsl:variable>
    <img alt="{normalize-space(.)}" id="{$id}" src="{$images}{substring-after(@url, '/')}"> </img>
  </xsl:template>


  <!-- Sections, candidates for split -->
  <xsl:template match="
    tei:text| tei:group/tei:text | tei:group | tei:back | tei:body | tei:front
  | tei:div | tei:div0 | tei:div1 | tei:div2 | tei:div3 | tei:div4 | tei:div5 | tei:div6 | tei:div7 
    " mode="split">
    <xsl:param name="type"/>
    <xsl:choose>
      <!-- there are children to split, so we should do something special with what is before (and also after)
          Is it a great idea to open a file/page for such division which could contain no more than a title ?      
      -->
      <xsl:when test="descendant::*[key('split', generate-id())]">
        <!-- Get last pb ? -->
        <xsl:variable name="lastpb">
          <xsl:if test="preceding-sibling::*[1][self::tei:pb]">
            <xsl:apply-templates select="preceding-sibling::*[1]"/>
          </xsl:if>
        </xsl:variable>
        <!-- take content before sections -->
        <xsl:variable name="before" select="generate-id(
          tei:back | tei:body | tei:front
        | tei:group|tei:div|tei:div0|tei:div1|tei:div2|tei:div3|tei:div4|tei:div5|tei:div6)"/>
        <xsl:variable name="blocks" select="tei:*[following-sibling::*[generate-id(.)=$before]]"/>
        <!-- Some short parts with just an epigraph are not splitted -->
        <xsl:if test="@xml:id and $blocks[local-name()!='head' and local-name()!='pb' and local-name()!='index']">
          <xsl:call-template name="chapter"/>
        </xsl:if>
        <xsl:apply-templates select="
          tei:back | tei:body | tei:front
        | tei:div | tei:div0 | tei:div1 | tei:div2 | tei:div3 | tei:div4 | tei:div5 | tei:div6 | tei:div7
        " mode="split"/>
        <!-- What about content after last section ? -->
      </xsl:when>
      <!-- Should be a leave with no children to split -->
      <xsl:otherwise>
        <xsl:if test="not(key('split', generate-id()))">
          <xsl:variable name="title">
            <xsl:call-template name="title"/>
          </xsl:variable>
          <xsl:message>Split problem for: <xsl:call-template name="id"/>, <xsl:value-of
              select="normalize-space($title)"/></xsl:message>
        </xsl:if>
        <xsl:call-template name="chapter"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="prev">
    <xsl:for-each select="preceding::*[key('split', generate-id())][not(self::tei:titlePage)][1]">
      <xsl:call-template name="rel">
        <xsl:with-param name="rel">prev</xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="next">
    <xsl:variable name="child"
      select="descendant::*[not(self::tei:titlePage)][key('split', generate-id())][1]"/>
    <xsl:choose>
      <xsl:when test="$child">
        <xsl:for-each select="$child">
          <xsl:call-template name="rel">
            <xsl:with-param name="rel">next</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each
          select="following::*[not(self::tei:titlePage)][key('split', generate-id())][1]">
          <xsl:call-template name="rel">
            <xsl:with-param name="rel">next</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Metadata is controlled by doctype (chapter, book, article…) -->
  <xsl:template match="tei:teiHeader" mode="split"/>

  <!-- Short summary -->
  <xsl:template name="argument">
    <nav class="argument">
      <xsl:for-each select="tei:div | tei:group | tei:body/tei:div">
        <xsl:if test="position() != 1"> — </xsl:if>
        <xsl:call-template name="a"/>
      </xsl:for-each>
    </nav>
  </xsl:template>

  <!--  -->
  <xsl:template name="breadcrumb">
    <xsl:param name="base" select="$base"/>
    <nav class="breadcrumb">
      <xsl:for-each select="ancestor::*">
        <xsl:choose>
          <!-- stop before title doc, better formatted upper -->
          <xsl:when test="self::tei:TEI"/>
          <xsl:when test="self::tei:group[parent::tei:text]"/>
          <xsl:when test="self::tei:body"/>
          <xsl:when test="self::tei:front"/>
          <xsl:when test="self::tei:back"/>
          <xsl:otherwise>
            <xsl:call-template name="rel">
              <xsl:with-param name="base" select="$base"/>
            </xsl:call-template>
            <xsl:if test="position() != last()">
              <xsl:text> » </xsl:text>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <!--
      <xsl:call-template name="a-label">
        <xsl:with-param name="base" select="$base"/>
      </xsl:call-template>
      -->
    </nav>
  </xsl:template>



  <!-- a prev/next navigation -->
  <xsl:template name="prevnext">
    <nav class="prevnext">
      <div class="prev">
        <xsl:call-template name="prev"/>
      </div>
      <div class="next">
        <xsl:call-template name="next"/>
      </div>
    </nav>
  </xsl:template>

  <!-- link to a section, shortening too big title -->
  <xsl:template name="rel">
    <!-- rel attribute -->
    <xsl:param name="rel"/>
    <!-- class attribute -->
    <xsl:param name="class"/>
    <!-- base href prefix foir link -->
    <xsl:param name="base"/>
    <!-- html to put before in the link -->
    <xsl:param name="prefix"/>
    <!-- html to put after in the link -->
    <xsl:param name="suffix"/>
    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="href"/>
      </xsl:attribute>
      <xsl:if test="$rel">
        <xsl:attribute name="rel">
          <xsl:value-of select="$rel"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:variable name="classnorm" select="normalize-space(concat($class, ' ', $rel))"/>
      <xsl:if test="$classnorm != ''">
        <xsl:attribute name="class">
          <xsl:value-of select="$classnorm"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:variable name="t">
        <xsl:choose>
          <xsl:when test="concat($prefix , $suffix)!=''">
            <span>
              <xsl:apply-templates select="." mode="title"/>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="title"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="title" select="normalize-space($t)"/>
      <span>
        <xsl:choose>
          <xsl:when test="$title=''">
            <xsl:copy-of select="$prefix"/>
            <xsl:call-template name="message">
              <xsl:with-param name="id">notitle</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <!-- Titre trop complet ?
      <xsl:when test="self::tei:text">
        <xsl:copy-of select="$prefix"/>
        <xsl:copy-of select="$t"/>
      </xsl:when>
      -->
          <xsl:when test="string-length($title) &gt; 50">
            <xsl:attribute name="title">
              <xsl:value-of select="$title"/>
            </xsl:attribute>
            <xsl:copy-of select="$prefix"/>
            <xsl:value-of select="substring($title, 1, 30)"/>
            <xsl:value-of select="substring-before(concat(substring($title, 31), ' '), ' ')"/>
            <!-- Quelque chose a été coupé -->
            <xsl:if test="substring-after(substring($title, 30), ' ') != ''">…</xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="$prefix"/>
            <xsl:copy-of select="$t"/>
          </xsl:otherwise>
        </xsl:choose>
      </span>
      <xsl:copy-of select="$suffix"/>
    </a>
  </xsl:template>

  <xsl:template match="tei:div/tei:note[@type = 'bibl']">
    <!-- metadata, no output -->
  </xsl:template>
  


  <xsl:template name="book">
    <xsl:variable name="biblStruct"
      select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct"/>

    <xsl:variable name="html">
      <html lang="fr">
        <head>
          <xsl:call-template name="head-common">
            <xsl:with-param name="type">book</xsl:with-param>
          </xsl:call-template>
          <xsl:apply-templates select="$biblStruct" mode="citation"/>
        </head>
        <body>
          <xsl:variable name="class" select="normalize-space(concat('book ', $status))"/>
          <article class="{$class}" data-slug="{$docid}">
            <xsl:if test="string(number(substring($docdate, 1, 4))) != 'NaN'">
              <xsl:attribute name="data-year">
                <xsl:value-of select="substring($docdate, 1, 4)"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="normalize-space($byline) != ''">
              <xsl:attribute name="data-byline">
                <xsl:value-of select="normalize-space($byline)"/>
              </xsl:attribute>
            </xsl:if>
            <aside class="book-toc" aria-label="Sommaire">
              <nav class="toc" aria-label="Sommaire" role="doc-toc">
                <xsl:call-template name="toc"/>
              </nav>
            </aside>
            <figure class="book-cover">
              <!-- Specific Piaget
              <xsl:apply-templates select="$cover/html:a"/>
              -->
            </figure>
            <xsl:variable name="class2" select="normalize-space(concat('book-abstract ', $status))"/>
            <section class="{$class2}">
              <div>
                <xsl:choose>
                  <xsl:when test="$closed-access">
                    <p>Ouvrage sous droits.</p>
                    <xsl:apply-templates
                      select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability"
                    />
                  </xsl:when>
                </xsl:choose>
                <h2>Notice de l’éditeur</h2>
                <xsl:variable name="abstract"
                  select="/tei:TEI/tei:teiHeader/tei:profileDesc/tei:abstract[1]"/>
                <xsl:choose>
                  <xsl:when test="normalize-space($abstract) != ''">
                    <xsl:apply-templates select="$abstract/*"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <p>[À venir…]</p>
                  </xsl:otherwise>
                </xsl:choose>
                <!--
                <xsl:call-template name="footnotes">
                  <xsl:with-param name="tei"
                    select="/tei:TEI/tei:text/tei:body/tei:*[not(self::tei:div)]"/>
                </xsl:call-template>
                -->
              </div>
            </section>
          </article>
        </body>
      </html>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:value-of select="$dstDir"/>
      <xsl:value-of select="$docid"/>
      <xsl:text>.html</xsl:text>
    </xsl:variable>
    <exsl:document href="{$href}" omit-xml-declaration="yes" encoding="UTF-8" indent="yes">
      <xsl:copy-of select="$html"/>
    </exsl:document>
  </xsl:template>


  <xsl:template name="chapter">
    <xsl:variable name="id">
      <xsl:choose>
        <xsl:when test="@xml:id">
          <xsl:value-of select="@xml:id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>No @xml:id <xsl:call-template name="idpath"/>
            <xsl:apply-templates select="tei:head" mode="title"/>
          </xsl:message>
          <xsl:value-of select="/*/@xml:id"/>
          <xsl:text>-</xsl:text>
          <xsl:call-template name="id"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="url" select="concat($urlprefix, $id)"/>
    <xsl:variable name="pages">
      <xsl:variable name="pages" select=".//tei:pb[@n]"/>
      <xsl:choose>
        <xsl:when test="not(tei:pb[not(preceding-sibling::tei:p)]) and .//tei:pb">
          <xsl:value-of select="preceding::tei:pb[@n][1]/@n"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$pages[1]/@n"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="count($pages) &gt; 1">
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$pages[last()]/@n"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="year">
      <xsl:choose>
        <xsl:when test="@when">
          <xsl:value-of select="substring(@when, 1, 4)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring($docdate, 1, 4)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="html">
      <html lang="fr">
        <head>
          <xsl:call-template name="head-common">
            <xsl:with-param name="type">chapter</xsl:with-param>
          </xsl:call-template>
          <xsl:choose>
            <xsl:when test="tei:note[@type = 'bibl']/tei:biblStruct">
              <xsl:apply-templates select="(tei:note[@type = 'bibl']/tei:biblStruct)[1]" mode="citation"/>
            </xsl:when>
            <xsl:when test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct">
                <xsl:choose>
                  <xsl:when test="@type = 'chapter'">
                    <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1]" mode="citation">
                      <xsl:with-param name="type">chapter</xsl:with-param>
                      <xsl:with-param name="title">
                        <xsl:choose>
                          <xsl:when test="tei:head/tei:note[@type='bibl']//tei:ref">
                            <xsl:apply-templates select="(tei:head/tei:note[@type='bibl']//tei:ref)[1]/node()"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:call-template name="title"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:with-param>
                      <xsl:with-param name="pages" select="$pages"/>
                      <xsl:with-param name="url" select="concat($urlprefix, $id)"/>
                    </xsl:apply-templates>
                  </xsl:when>
                </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </head>
        <body>
          <xsl:variable name="class" select="normalize-space(concat('chapter ', $status))"/>
          <article class="{$class}" data-slug="{$id}" data-year="{$year}" data-byline="{$byline}">
            <!-- Get last pb ? -->
            <xsl:variable name="lastpb">
              <xsl:if test="preceding-sibling::*[1][self::tei:pb]">
                <xsl:apply-templates select="preceding-sibling::*[1]"/>
              </xsl:if>
            </xsl:variable>
            <xsl:variable name="first-non-header" select="
              (tei:*[not(self::tei:argument)]
              [not(self::tei:byline)]
              [not(self::tei:cb)]
              [not(self::tei:dateline)]
              [not(self::tei:docAuthor)]
              [not(self::tei:docDate)]
              [not(self::tei:epigraph)]
              [not(self::tei:head)]
              [not(self::tei:index)]
              [not(self::tei:opener)]
              [not(self::tei:pb)]
              [not(self::tei:salute)]
              [not(self::tei:signed)])[1]
              "/>
            <header class="chapter-header">
              <xsl:for-each select="tei:note[@type = 'bibl']/tei:bibl[@type = 'title']">
                <div class="running-title print-only">
                  <xsl:apply-templates/>
                </div>
              </xsl:for-each>
              <!-- for print, url -->
               <div class="url print-only"><a href="{$url}"><xsl:value-of select="$url"/></a></div>
              <div class="booktitle">
                <xsl:apply-templates select="tei:note[@type = 'bibl']/tei:biblStruct" mode="byline"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="tei:note[@type = 'bibl']/tei:biblStruct" mode="year"/>
                <xsl:text> </xsl:text>
                <em class="title">
                  <xsl:copy-of select="$booktitle"/>
                </em>
              </div>
              <xsl:apply-templates select="$first-non-header/preceding-sibling::node()">
                <xsl:with-param name="level" select="1"/>
              </xsl:apply-templates>
            </header>

            <xsl:choose>
              <!-- part with chapters -->
              <xsl:when test="descendant::*[key('split', generate-id())]">
                <!-- take content before sections -->
                <xsl:variable name="first-div" select="(
                    tei:back
                  | tei:body
                  | tei:front
                  | tei:group
                  | tei:div
                  | tei:div0
                  | tei:div1
                  | tei:div2
                  | tei:div3
                  | tei:div4
                  | tei:div5
                  | tei:div6
                  )[1]"/>
                <div>
                  <xsl:attribute name="class">
                    <xsl:text>col2</xsl:text>
                    <xsl:if test="$closed-access"> rights</xsl:if>
                  </xsl:attribute>
                  <xsl:variable name="before" select="$first-div/preceding-sibling::node()"/>
                  <div class="body">
                    <xsl:value-of select="$lf"/>
                    <xsl:apply-templates select="$first-non-header | $first-non-header/following-sibling::node()[count(. | $before) = count($before)]">
                      <xsl:with-param name="level" select="1"/>
                    </xsl:apply-templates>
                  </div>
                  <xsl:call-template name="footnotes">
                    <xsl:with-param name="tei" select="$first-div/preceding-sibling::node()"/>
                  </xsl:call-template>
                </div>
                <!-- Chapters -->
                <nav class="toc-sub chapters">
                  <ol class="tree">
                    <xsl:for-each select="tei:div">
                      <li class="toc-item">
                        <xsl:call-template name="a"/>
                      </li>
                    </xsl:for-each>
                  </ol>
                </nav>
              </xsl:when>
              <xsl:otherwise>
                <div>
                  <xsl:attribute name="class">
                    <xsl:text>col2</xsl:text>
                    <xsl:if test="$closed-access"> rights</xsl:if>
                  </xsl:attribute>
                  
                  <!-- For print, local toc -->
                  <xsl:variable name="html">
                    <xsl:apply-templates select="tei:div" mode="li"/>
                  </xsl:variable>
                  <xsl:if test="$html != ''">
                    <nav class="toc-sub sections print-only">
                      <ol class="tree">
                        <xsl:copy-of select="$html"/>
                      </ol>
                    </nav>
                  </xsl:if>
                  <div class="body">
                    <xsl:apply-templates
                      select="$first-non-header | $first-non-header/following-sibling::node()">
                      <xsl:with-param name="level" select="1"/>
                    </xsl:apply-templates>
                  </div>
                  <xsl:call-template name="footnotes"/>
                </div>
              </xsl:otherwise>
            </xsl:choose>
            
            <!-- No more local toc
            <aside class="chapter-toc" aria-label="Sommaire">
              <xsl:comment>teinte:toc-start</xsl:comment>
              <xsl:variable name="toc">
                <xsl:call-template name="toclocal"/>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$toc!=''">
                  <nav class="toc">
                    <xsl:copy-of select="$toc"/>
                  </nav>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text> </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:comment>teinte:toc-end</xsl:comment>
            </aside>
            -->
          </article>
        </body>
      </html>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:value-of select="$dstDir"/>
      <xsl:value-of select="$id"/>
      <xsl:text>.html</xsl:text>
    </xsl:variable>
    <exsl:document href="{$href}" omit-xml-declaration="yes" encoding="UTF-8" indent="yes">
      <xsl:copy-of select="$html"/>
    </exsl:document>
  </xsl:template>

  <xsl:template name="article">
    <xsl:variable name="biblStruct"
      select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct"/>
    <xsl:variable name="html">
      <html lang="fr">
        <head>
          <xsl:call-template name="head-common">
            <xsl:with-param name="type">article</xsl:with-param>
          </xsl:call-template>
          <xsl:apply-templates select="$biblStruct" mode="citation"/>
        </head>
        <body>
          <xsl:variable name="head" select="/tei:TEI/tei:text/tei:body/tei:head"/>
              <xsl:variable name="first-non-header" select="
                (/tei:TEI/tei:text/tei:body/tei:*[not(self::tei:argument)]
                [not(self::tei:byline)]
                [not(self::tei:cb)]
                [not(self::tei:dateline)]
                [not(self::tei:docAuthor)]
                [not(self::tei:docDate)]
                [not(self::tei:epigraph)]
                [not(self::tei:head)]
                [not(self::tei:index)]
                [not(self::tei:opener)]
                [not(self::tei:pb)]
                [not(self::tei:salute)]
                [not(self::tei:signed)])[1]
                "/>
          <xsl:variable name="class" select="normalize-space(concat('article ', $status))"/>
          <article class="{$class}">
            <xsl:variable name="class2" select="normalize-space(concat('article-flow ', $status))"/>
            <xsl:comment>teinte:flow-start</xsl:comment>
            <div class="{$class2}" data-slug="{$docid}">
            <xsl:if test="string(number(substring($docdate, 1, 4))) != 'NaN'">
              <xsl:attribute name="data-year">
                <xsl:value-of select="substring($docdate, 1, 4)"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="normalize-space($byline) != ''">
              <xsl:attribute name="data-byline">
                <xsl:value-of select="normalize-space($byline)"/>
              </xsl:attribute>
            </xsl:if>
              <header class="article-header">
                <xsl:for-each select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:notesStmt/tei:note[@type = 'bibl']/tei:bibl[@type='title']">
                  <div class="running-title print-only">
                    <xsl:apply-templates/>
                  </div>
                </xsl:for-each>
                <!-- for print, url -->
                <xsl:for-each select="($biblStruct/tei:analytic/tei:*[@target])[1]">
                   <div class="url print-only"><a href="{@target}"><xsl:value-of select="@target"/></a></div>
                </xsl:for-each>
                <div class="byline">
                  <xsl:apply-templates select="$biblStruct" mode="byline"/>
                  <xsl:text> </xsl:text>
                  <xsl:apply-templates select="$biblStruct" mode="year"/>
                </div>
                <xsl:apply-templates select="$first-non-header/preceding-sibling::node()">
                  <xsl:with-param name="level" select="1"/>
                </xsl:apply-templates>
              </header>
              <div>
                <xsl:attribute name="class">
                  <xsl:text>col2</xsl:text>
                  <xsl:if test="$closed-access"> rights</xsl:if>
                </xsl:attribute>
                <!-- For print, local toc -->
                <xsl:variable name="toc">
                  <xsl:call-template name="toc"/>
                </xsl:variable>
                <xsl:if test="$toc != ''">
                  <nav class="toc-sub sections print-only">
                    <xsl:copy-of select="$toc"/>
                  </nav>
                </xsl:if>
                <div class="body">
                  <xsl:apply-templates
                    select="$first-non-header | $first-non-header/following-sibling::node()">
                    <xsl:with-param name="level" select="1"/>
                  </xsl:apply-templates>
                </div>
                <xsl:call-template name="footnotes">
                  <xsl:with-param name="tei" select="/tei:TEI/tei:text"/>
                </xsl:call-template>
              </div>
            </div>
            <xsl:comment>teinte:flow-end</xsl:comment>
            <aside class="article-toc" aria-label="Sommaire">
              <xsl:comment>teinte:toc-start</xsl:comment>
              <xsl:variable name="toc">
                <xsl:call-template name="toc"/>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$toc != ''">
                  <nav class="toc">
                    <xsl:copy-of select="$toc"/>
                  </nav>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text> </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:comment>teinte:toc-end</xsl:comment>
            </aside>
          </article>
        </body>
      </html>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:value-of select="$dstDir"/>
      <xsl:value-of select="$docid"/>
      <xsl:text>.html</xsl:text>
    </xsl:variable>
    <exsl:document href="{$href}" omit-xml-declaration="yes" encoding="UTF-8" indent="yes">
      <xsl:copy-of select="$html"/>
    </exsl:document>
  </xsl:template>

  <xsl:template name="head-common">
    <xsl:param name="type"/>
    <xsl:param name="year">
      <xsl:choose>
        <xsl:when test="@when">
          <xsl:value-of select="substring(@when, 1, 4)"/>
        </xsl:when>
        <xsl:otherwise>          
          <xsl:value-of select="substring($issued, 1, 4)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width"/>
    <link rel="stylesheet" type="text/css" href="{$theme}teinte.css"/>
    <link rel="stylesheet" type="text/css" href="{$theme}teinte.layout.css"/>
    <link rel="stylesheet" type="text/css" href="{$theme}teinte.tree.css"/>



    <title>
      <xsl:choose>
        <xsl:when test="tei:note[@type = 'bibl']/tei:bibl[@type='title']">
          <xsl:apply-templates select="tei:note[@type = 'bibl']/tei:bibl[@type='title']" mode="text"/>
        </xsl:when>
        <xsl:when
          test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:notesStmt/tei:note[@type = 'bibl']/tei:bibl[@type='title']">
          <xsl:apply-templates 
            select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:notesStmt/tei:note[@type = 'bibl']/tei:bibl[@type='title']"
            mode="text"
            />
        </xsl:when>
        <xsl:when test="$type = 'chapter'">
          <xsl:value-of select="$byline"/>
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$year"/>
          <xsl:text>) </xsl:text>
          <xsl:call-template name="title"/>
          <xsl:text> — </xsl:text>
          <xsl:value-of select="normalize-space($booktitle)"/>
        </xsl:when>
        <xsl:when test="$type = 'article'">
          <xsl:value-of select="$byline"/>
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$year"/>
          <xsl:text>) </xsl:text>
          <xsl:choose>
            <xsl:when test="tei:head/tei:note[@type='bibl']//tei:ref">
              <xsl:apply-templates select="(tei:head/tei:note[@type='bibl']//tei:ref)[1]/node()"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="title"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- book -->
        <xsl:otherwise>
          <xsl:value-of select="$byline"/>
          <xsl:text> (</xsl:text>
          <xsl:value-of select="substring($issued, 1, 4)"/>
          <xsl:text>) </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </title>
    <xsl:choose>
      <xsl:when test="tei:note[@type = 'bibl']/processing-instruction('JSON-LD')">
        <script type="application/ld+json">
          <xsl:value-of select="$lf"/>
          <xsl:value-of select="tei:note[@type = 'bibl']/processing-instruction('JSON-LD')"/>
        </script>
      </xsl:when>
      <xsl:when
        test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:notesStmt/tei:note[@type = 'bibl']/processing-instruction('JSON-LD')">
        <script type="application/ld+json">
          <xsl:value-of select="$lf"/>
          <xsl:value-of
            select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:notesStmt/tei:note[@type = 'bibl']/processing-instruction('JSON-LD')"
          />
        </script>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="text">
    <xsl:apply-templates mode="text"/>
  </xsl:template>
  
  <xsl:template match="tei:hi[not(@*)]" mode="text">
    <xsl:text>“</xsl:text>
    <xsl:apply-templates mode="text"/>
    <xsl:text>”</xsl:text>
  </xsl:template>

  <xsl:template match="tei:bibl[@type='source']">
    <p class="bibl source"><xsl:apply-templates/></p>
  </xsl:template>

  <xsl:template match="html:*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>
