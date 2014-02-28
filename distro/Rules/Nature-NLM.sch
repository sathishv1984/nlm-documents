<?xml version="1.0" encoding="UTF-8"?>
<!--

* Schematron rules for testing semantic validity of XML files in the JATS DTD submitted to NPG *

Due to the configuration of XSLT templates used in the validation service, attributes cannot be used as the 'context' of a rule.

For example, context="article[@article-type]" will recognise the context as 'article' with an 'article-type' attribute, but context="article/@article-type" will set context as 'article'.
Use the <let> element to define the attribute if necessary.

--><schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding="xslt2">
  <title>Schematron rules for NPG content in JATS v1.0</title>
  <ns uri="http://www.w3.org/1998/Math/MathML" prefix="mml"/>
  <ns uri="http://www.niso.org/standards/z39-96/ns/oasis-exchange/table"
       prefix="oasis"/>
  <ns uri="http://www.w3.org/1999/xlink" prefix="xlink"/>
  <let name="allowed-values"
        value="document( 'allowed-values-nlm.xml' )/allowed-values"/>
   <!--Points at document containing information on journal titles, ids and DOIs-->

  <let name="products" value="document('products.xml')"/>
  <let name="subjects" value="document('subjects.xml')"/>
  <ns prefix="functx" uri="http://www.functx.com"/>
   <!--extended XPath functions from Priscilla Walmsley-->
  <xsl:function xmlns:functx="http://www.functx.com" name="functx:substring-after-last"
                 as="xs:string">
      <xsl:param name="arg" as="xs:string?"/> 
      <xsl:param name="delim" as="xs:string"/> 
      <xsl:sequence select="replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')"/>
  </xsl:function>
  
  <xsl:function xmlns:functx="http://www.functx.com" name="functx:escape-for-regex"
                 as="xs:string">
      <xsl:param name="arg" as="xs:string?"/> 
      <xsl:sequence select="replace($arg,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')"/>
  </xsl:function>
  
  <xsl:function xmlns:functx="http://www.functx.com" name="functx:substring-before-last"
                 as="xs:string">
      <xsl:param name="arg" as="xs:string?"/> 
      <xsl:param name="delim" as="xs:string"/> 
      <xsl:sequence select="if (matches($arg, functx:escape-for-regex($delim)))       then replace($arg,concat('^(.*)', functx:escape-for-regex($delim),'.*'),'$1')       else ''"/>
  </xsl:function>
  
  <!--Regularly used values throughout rules-->
  <let name="journal-title" value="//journal-meta/journal-title-group/journal-title"/>
  <let name="pcode" value="//journal-meta/journal-id[1]"/>
  <let name="article-type" value="article/@article-type"/>
  <let name="article-id"
        value="article/front/article-meta/article-id[@pub-id-type='publisher-id']"/>
    
   <pattern>
      <rule context="article" role="error"><!--Does the article have an article-type attribute-->
      <let name="article-type"
              value="descendant::subj-group[@subj-group-type='category']/subject"/>
      <assert id="article1" test="@article-type">All articles should have an article-type attribute on "article". The value should be the same as the information contained in the "subject" element with attribute subj-group-type="category"<value-of select="if ($article-type ne '') then concat(' (',$article-type,')') else ()"/>.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[@article-type]" role="error"><!--Does the article-type have a value?-->
      <report id="article2" test="$article-type = ''">"article" 'article-type' attribute should have a value and not be empty.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[@xml:lang]" role="error"><!--If @xml:lang exists, does it have an allowed value-->
      <let name="lang" value="@xml:lang"/>
         <assert id="article3" test="$allowed-values/languages/language[.=$lang]">Unexpected language (<value-of select="$lang"/>) declared on root article element. Expected values are "en" (English), "de" (German) and "ja" (Japanese/Kanji).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta" role="error"><!--Correct attribute value included-->
      <report id="jmeta1a"
                 test="count(journal-id) eq 1 and not(journal-id/@journal-id-type='publisher')">The "journal-id" element should have attribute: journal-id-type="publisher".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta" role="error"><!--Only one journal-id included-->
      <assert id="jmeta1b" test="count(journal-id) eq 1">There should only be one "journal-id" element in NPG/Palgrave articles, with attribute: journal-id-type="publisher".</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta" role="error"><!--Journal title exists-->
      <assert id="jmeta2a"
                 test="descendant::journal-title-group/journal-title and not($journal-title='')">Journal title is missing from the journal metadata section. Other rules are based on having a correct journal title and therefore will not be run. Please resubmit this file when the title has been added.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-title-group" role="error"><!--only one journal-title-group-->
      <report id="jmeta2b" test="preceding-sibling::journal-title-group">Only one journal-title-group should be used.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-title-group[not($journal-title='')]" role="error"><!--Is the journal title valid-->
      <assert id="jmeta3a"
                 test="not(descendant::journal-title) or $products[descendant::title=$journal-title]">Journal titles must be from the prescribed list of journal names. "<value-of select="$journal-title"/>" is not on this list - check spelling, spacing of words or use of the ampersand. Other rules are based on having a correct journal title and therefore will not be run. Please resubmit this file when the title has been corrected.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="journal-title-group[not($journal-title='')]" role="error"><!--Is the journal id valid?-->
      <assert id="jmeta3b"
                 test="$products[descendant::product/@pcode=$pcode] or not($products[descendant::title=$journal-title])">Journal id is incorrect (<value-of select="$pcode"/>). For <value-of select="$journal-title"/>, it should be: <value-of select="$products//product[descendant::title=$journal-title]/@pcode"/>. Other rules are based on having a correct journal id and therefore will not be run. Please resubmit this file when the journal id has been corrected.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="journal-title-group[not($journal-title='')]" role="error"><!--Do the journal title and id match each other?-->
      <assert id="jmeta3c"
                 test="$pcode=$products//product[descendant::title=$journal-title]/@pcode or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode])">Journal id (<value-of select="$pcode"/>) does not match journal title: <value-of select="$journal-title"/>. Check which is the correct value.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-subtitle | trans-title-group" role="error"><!--No other children of journal-title-group used-->
      <report id="jmeta4" test="parent::journal-title-group">Unexpected use of "<name/>" in "journal-title-group".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-title-group/journal-title" role="error"><!--Only one journal title present-->
      <report id="jmeta4b" test="preceding-sibling::journal-title">More than one journal title found. Only one journal title should be used.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-title-group/abbrev-journal-title" role="error"><!--Only one journal title present-->
      <report id="jmeta4c" test="preceding-sibling::abbrev-journal-title">More than one abbreviated journal title found. Only one abbreviated journal title should be used.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta/issn" role="error"><!--Correct attribute value inserted; ISSN matches expected syntax-->
      <assert id="jmeta5a"
                 test="@pub-type='ppub' or @pub-type='epub' or @pub-type='supplement'">ISSN should have attribute pub-type="ppub" for print, pub-type="epub" for electronic publication, or pub-type="supplement" where an additional ISSN has been created for a supplement.</assert>
      </rule>
  </pattern>
   <pattern><!--ISSN ppub declared in XML has equivalent print issn in ontology-->
    <rule context="journal-meta/issn[@pub-type='ppub']" role="error">
         <assert id="jmeta5b1a"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or $products/descendant::product[@pcode=$pcode]//issn[@type='print']">Print ISSN given in XML, but <value-of select="$journal-title"/> is online only. Only an electronic ISSN should be given.</assert>
         </rule>
  </pattern>
   <pattern><!--Journal with print issn in ontology has ISSN ppub declared in XML-->
    <rule context="journal-meta[not($pcode='am')]" role="error">
         <assert id="jmeta5b1b"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or not($products/descendant::product[@pcode=$pcode]//issn[@type='print']) or issn[@pub-type='ppub']">
            <value-of select="$journal-title"/> should have print ISSN (<value-of select="$products/descendant::product[@pcode=$pcode]//issn[@type='print']"/>).</assert>
         </rule>
  </pattern>
   <pattern><!--ISSN ppub matches print issn in ontology-->
    <rule context="journal-meta/issn[@pub-type='ppub']" role="error">
         <assert id="jmeta5b2"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or not($products/descendant::product[@pcode=$pcode]//issn[@type='print']) or .=$products/descendant::product[@pcode=$pcode]//issn[@type='print']">Incorrect print ISSN (<value-of select="."/>) for <value-of select="$journal-title"/>. Expected value is: <value-of select="$products/descendant::product[@pcode=$pcode]//issn[@type='print']"/>.</assert>
         </rule>
  </pattern>
   <pattern><!--ISSN epub declared in XML has equivalent eissn in ontology-->
    <rule context="journal-meta/issn[@pub-type='epub']" role="error">
         <assert id="jmeta5c1a"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or $products/descendant::product[@pcode=$pcode]//issn[@type='electronic']">Electronic ISSN given in XML, but <value-of select="$journal-title"/> is print only. Only a print ISSN should be given.</assert>
      </rule>
  </pattern>
   <pattern><!--Journal with eissn in ontology has ISSN epub declared in XML-->
    <rule context="journal-meta" role="error">
         <assert id="jmeta5c1b"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or not($products/descendant::product[@pcode=$pcode]//issn[@type='electronic']) or issn[@pub-type='epub']">
            <value-of select="$journal-title"/> should have eISSN (<value-of select="$products/descendant::product[@pcode=$pcode]//issn[@type='electronic']"/>).</assert>
      </rule>
  </pattern>
   <pattern><!--ISSN ppub matches print issn in ontology-->
    <rule context="journal-meta/issn[@pub-type='epub']" role="error">
         <assert id="jmeta5c2"
                 test="not($journal-title) or not($products[descendant::title=$journal-title]) or not($products[descendant::product/@pcode=$pcode]) or not($products/descendant::product[@pcode=$pcode]//issn[@type='electronic']) or .=$products/descendant::product[@pcode=$pcode]//issn[@type='electronic']">Incorrect electronic ISSN (<value-of select="."/>) for <value-of select="$journal-title"/>. Expected value is: <value-of select="$products/descendant::product[@pcode=$pcode]//issn[@type='electronic']"/>.</assert>
      </rule>
  </pattern>
   <pattern><!--Only one of each issn pub-type used-->
    <rule context="journal-meta/issn" role="error">
         <report id="jmeta5d" test="@pub-type=./preceding-sibling::issn/@pub-type">There should only be one instance of each "issn" element with "pub-type" attribute value of "<value-of select="@pub-type"/>".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta/contrib-group | journal-meta/isbn | journal-meta/notes | journal-meta/self-uri"
            role="error"><!--Unexpected elements in journal-meta-->
      <report id="jmeta6" test=".">Do not use the "<name/>" element in "journal-meta".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-meta" role="error"><!--Other expected and unexpected elements-->
      <assert id="jmeta7a" test="publisher">Journal metadata should include a "publisher" element.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="publisher" role="error">
         <report id="jmeta7b" test="publisher-loc">Do not use "publisher-loc" element in publisher information.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="journal-title-group | journal-title | publisher">
         <report id="jmeta8a" test="@content-type">Unnecessary use of "content-type" attribute on "<name/>" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-meta" role="error"><!--Two article ids, one doi and one publisher-id-->
      <assert id="ameta1a"
                 test="article-id[@pub-id-type='doi'] and article-id[@pub-id-type='publisher-id']">Article metadata should contain at least two "article-id" elements, one with attribute pub-id-type="doi" and one with attribute pub-id-type="publisher-id".</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="article-meta" role="error">
         <assert id="ameta1b" test="article-categories">Article metadata should include an "article-categories" element.</assert>
      </rule>
  </pattern>
   <pattern><!--Does article categories contain "category" information and does it match article/@article-type?-->
    <rule context="article-categories" role="error">
         <assert id="ameta2a" test="subj-group[@subj-group-type='category']">Article categories should contain a "subj-group" element with attribute "subj-group-type='category'". The value of the child "subject" element should be the same as the main article-type attribute: <value-of select="$article-type"/>.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="article-categories/subj-group[@subj-group-type='category']"
            role="error">
         <assert id="ameta2b"
                 test="subject = $article-type or not($article-type) or not(subject)">Subject catgory (<value-of select="subject"/>) does not match root article type (<value-of select="$article-type"/>)</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-categories/subj-group">
         <assert id="ameta2c" test="@subj-group-type">"subj-group" should have attribute 'subj-group-type' declared.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-categories/subj-group[@subj-group-type]">
         <let name="subjGroupType" value="@subj-group-type"/>
         <assert id="ameta2d"
                 test="$allowed-values/subj-group-types/subj-group-type[.=$subjGroupType]">Invalid value for 'subj-group-type' attribute (<value-of select="@subj-group-type"/>). Refer to the Tagging Instructions for allowed values.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-categories/subj-group[@subj-group-type='article-heading']/subject">
         <assert id="ameta2e" test="@content-type">"subject" within "subj-group" (subj-group-type="article-heading") should have a 'content-type' attribute.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group">
         <report id="ameta2f" test="@specific-use">Do not 'specific-use' attribute on "subj-group".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group">
         <report id="ameta2g" test="@xml:lang">Do not 'xml:lang' attribute on "subj-group".</report>
      </rule>
  </pattern>
   <pattern><!--only one of each subj-group-type used-->
    <rule context="subj-group" role="error">
         <report id="ameta2h"
                 test="@subj-group-type=./preceding-sibling::subj-group/@subj-group-type">Only one "subj-group" of subj-group-type "<value-of select="@subj-group-type"/>" should appear in an article - merge these elements.</report>
      </rule>
  </pattern>
   <pattern><!--only one of each subj-group-type used-->
    <rule context="subj-group/subject" role="error">
         <report id="ameta2i" test="@id">Do not use 'id' attribute on "subject".</report>
      </rule>
  </pattern>
   <pattern><!--subject codes should have @content-type="npg.subject" (for transforms to work properly) in new journals-->
    <rule context="article[matches($pcode,'^(mtm|hortres|sdata)$')]//subj-group[@subj-group-type='subject']/subject">
         <assert id="subject1" test="@content-type='npg.subject'">In "subj-group" with attribute 'subj-group="subject"', child "subject" elements should have 'content-type="npg.subject"'.</assert>
      </rule>
  </pattern>
   <pattern><!--subject codes should only contained "named-content"-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/*">
         <assert id="subject2" test="self::named-content">"subject" should only contain "named-content" child elements. Do not use "<name/>".</assert>
      </rule>
  </pattern>
   <pattern><!--subject codes should contain three "named-content" children-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']">
         <report id="subject3" test="count(named-content) ne 3">"subject" contains <value-of select="count(named-content)"/> "named-content" children. It should contain 3, with 'content-type' values of "id", "path" and "version".</report>
      </rule>
  </pattern>
   <pattern><!--"named-content" @content-type should be id, path or version-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject'][count(named-content) eq 3 and count(*) eq 3]/named-content">
         <assert id="subject4" test="matches(@content-type,'^(id|path|version)$')">Unexpected value for 'content-type' in subject codes (<value-of select="@content-type"/>). Allowed values are on each of: "id", "path" and "version".</assert>
      </rule>
  </pattern>
   <pattern><!--"version" included-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject'][count(named-content) eq 3 and count(*) eq 3][not(named-content[not(matches(@content-type,'^(id|path|version)$'))])]">
         <assert id="subject5" test="named-content[@content-type='version']">Missing "named-content" with 'content-type="version"' in subject codes. "subject" should contain three "named-content" children, with one of each 'content-type' attribute value: "id", "path" and "version".</assert>
      </rule>
  </pattern>
   <pattern><!--"id" included-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject'][count(named-content) eq 3 and count(*) eq 3][not(named-content[not(matches(@content-type,'^(id|path|version)$'))])]">
         <assert id="subject6" test="named-content[@content-type='id']">Missing "named-content" with 'content-type="id"' in subject codes. "subject" should contain three "named-content" children, with one of each 'content-type' attribute value: "id", "path" and "version".</assert>
      </rule>
  </pattern>
   <pattern><!--"path" included-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject'][count(named-content) eq 3 and count(*) eq 3][not(named-content[not(matches(@content-type,'^(id|path|version)$'))])]">
         <assert id="subject7" test="named-content[@content-type='path']">Missing "named-content" with 'content-type="path"' in subject codes. "subject" should contain three "named-content" children, with one of each 'content-type' attribute value: "id", "path" and "version".</assert>
      </rule>
  </pattern>
   <pattern><!--named-content should only use @content-type-->
    <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8a" test="@id">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'id'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8b" test="@alt">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'alt'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8c" test="@rid">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'rid'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8d" test="@specific-use">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'specific-use'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8e" test="@xlink:actuate">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:actuate'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8f" test="@xlink:href">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:href'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8g" test="@xlink:role">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:role'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8h" test="@xlink:show">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:show'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8i" test="@xlink:title">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:title'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8j" test="@xlink:type">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xlink:type'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="subj-group[@subj-group-type='subject']/subject[@content-type='npg.subject']/named-content">
         <report id="subject8k" test="@xml:lang">Only 'content-type' should be used as an attribute on "named-content" in "subject". Do not use 'xml:lang'.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="trans-title-group" role="error"><!--No unexpected children of article title-group used-->
      <report id="arttitle1a" test="parent::title-group">Unexpected use of "trans-title-group" in article "title-group". "title-group" should only contain "article-title", "subtitle", "alt-title" or "fn-group".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-title" role="error"><!--No @id on article title-->
      <report id="arttitle2" test="@id">Do not use "id" attribute on "article-title".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="title-group/article-title/styled-content" role="error"><!--correct attributes used on styled-content element-->
      <report id="arttitle3a" test="@specific-use">Unnecessary use of "specific-use" attribute on "styled-content" element in "article-title".</report>
      </rule>
    </pattern>
   <pattern>
      <rule context="title-group/article-title/styled-content" role="error">
         <report id="arttitle3b" test="@style">Unnecessary use of "style" attribute on "styled-content" element in "article-title".</report>
      </rule>
    </pattern>
   <pattern>
      <rule context="title-group/article-title/styled-content" role="error">
         <assert id="arttitle3c" test="@style-type='hide'">The "styled-content" element in "article-title" should have attribute "style-type='hide'". If the correct element has been used here, add the required attribute.</assert>
      </rule>
  </pattern>
   <pattern><!--Rules around expected attribute values of pub-date, and only one of each type-->
    <rule context="pub-date" role="error">
         <assert id="pubdate0a" test="@pub-type">"pub-date" element should have attribute "pub-type" declared. Allowed values are: cover-date, aop, collection, epub, epreprint, fav (final author version or author-ms) and ppub. Please check with NPG.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="pub-date[@pub-type]" role="error">
         <let name="pubType" value="@pub-type"/>
         <assert id="pubdate0b" test="$allowed-values/pub-types/pub-type[.=$pubType]">Unexpected value for "pub-type" attribute on "pub-date" element (<value-of select="$pubType"/>). Allowed values are: cover-date, aop, collection, epub, epreprint, fav (final author version or author-ms) and ppub. Please check with NPG.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="pub-date" role="error">
         <report id="pubdate0c" test="@pub-type=./preceding-sibling::pub-date/@pub-type">There should only be one instance of the "pub-date" element with "pub-type" attribute value of "<value-of select="@pub-type"/>". Please check with NPG.</report>
      </rule>
  </pattern>
   <pattern><!--Valid values for year, month and day-->
    <rule context="pub-date" role="error">
         <assert id="pubdate1a" test="not(year) or matches(year, '^(19|20)[0-9]{2}$')">Invalid year value: <value-of select="year"/>. It should be a 4-digit number starting with 19 or 20.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="pub-date" role="error">
         <assert id="pubdate1b" test="not(month) or matches(month, '^((0[1-9])|(1[0-2]))$')">Invalid month value: <value-of select="month"/>. It should be a 2-digit number between 01 and 12.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="pub-date" role="error">
         <assert id="pubdate1c" test="not(day) or matches(day, '^(0[1-9]|[12][0-9]|3[01])$')">Invalid day value: <value-of select="day"/>. It should be a 2-digit number between 01 and 31.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="pub-date/season" role="error">
         <report id="pubdate1d" test=".">Do not use "season" (<value-of select="."/>). "Day" and "month" are the only other elements which should be used.</report>
      </rule>
  </pattern>
   <pattern><!--Concatenate year/month/day and check valid if those elements have already passed basic validation checks. This regex taken from http://regexlib.com, author Ted Chambron -->
    <rule context="pub-date[matches(year, '^(19|20)[0-9]{2}$') and matches(month, '^((0[1-9])|(1[0-2]))$') and matches(day, '^(0[1-9]|[12][0-9]|3[01])$')]"
            role="error">
         <assert id="pubdate2"
                 test="matches(concat(year,'-',month,'-',day), '^((((19|20)(([02468][048])|([13579][26]))-02-29))|((20[0-9][0-9])|(19[0-9][0-9]))-((((0[1-9])|(1[0-2]))-((0[1-9])|(1[0-9])|(2[0-8])))|((((0[13578])|(1[02]))-31)|(((0[1,3-9])|(1[0-2]))-(29|30)))))$')">Invalid publication date - the day value (<value-of select="day"/>) does not exist for the month (<value-of select="month"/>) in the year (<value-of select="year"/>).</assert>
      </rule>
  </pattern>
   <pattern><!--Year/Day - invalid combination in pub-date-->
    <rule context="pub-date[year and day]" role="error">
         <assert id="pubdate3" test="month">Missing month in pub-date. Currently only contains year and day.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="day[parent::pub-date] | month[parent::pub-date] | year[parent::pub-date]"
            role="error"><!--No content-type attribute on day, month or year-->
      <report id="pubdate4" test="@content-type">Do not use "content-type" attribute on "<name/>" within "pub-date" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="volume[parent::article-meta] | issue[parent::article-meta] | fpage[parent::article-meta] | lpage[parent::article-meta]"
            role="error">
         <assert id="artinfo1a" test="normalize-space(.) or *">Empty "<name/>" element should not be used.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="volume[parent::article-meta] | issue[parent::article-meta] | fpage[parent::article-meta] | lpage[parent::article-meta]"
            role="error">
         <assert id="artinfo1b" test="not(@content-type)">Do not use "content-type" attribute on "<name/>" within article metadata.</assert>
      </rule>
  </pattern>
   <pattern><!--fpage[parent::article-meta] |-->
    <rule context="volume[parent::article-meta] | issue[parent::article-meta] | lpage[parent::article-meta]"
            role="error">
         <let name="value" value="replace(.,'test','')"/>
         <assert id="artinfo2"
                 test="not(normalize-space($value) or *) or matches($value,'^S?[0-9]+$')">Invalid value for "<name/>" (<value-of select="."/>) - this may start with a capital S, but otherwise should only contain numerals.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="counts[page-count]" role="error">
         <assert id="artinfo3b" test="preceding-sibling::fpage">As "page-count" is used, we also expect "fpage" and "lpage" elements to be used in article metadata. Please check if "page-count" should have been used.</assert>
      </rule>
  </pattern>
   <pattern>
      <let name="span"
           value="//article-meta/lpage[normalize-space(.) or *][matches(.,'^[0-9]+$')] - //article-meta/fpage[normalize-space(.) or *][matches(.,'^[0-9]+$')] + 1"/>
      <rule context="counts/page-count[matches(@count,'^[0-9]+$')]">
         <assert id="artinfo4" test="@count = $span or not($span)">Incorrect value given for "page-count" attribute "count" (<value-of select="@count"/>). Expected value is: <value-of select="$span"/>.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="fig-count | table-count | equation-count | ref-count | word-count"
            role="error">
         <report id="artinfo5" test="parent::counts">Unexpected use of "<name/>" element - please delete.</report>
      </rule>
  </pattern>
   <pattern><!--Rules around expected attribute values of date-->
    <rule context="history/date" role="error">
         <assert id="histdate0a" test="@date-type">"date" element should have attribute "date-type" declared. Allowed values are: created, received, rev-recd (revision received), first-decision, accepted and misc. Please check with NPG.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="history/date[@date-type]" role="error">
         <let name="dateType" value="@date-type"/>
         <assert id="histdate0b" test="$allowed-values/date-types/date-type[.=$dateType]">Unexpected value for "date-type" attribute on "date" element (<value-of select="$dateType"/>). Allowed values are: created, received, rev-recd (revision received), first-decision, accepted and misc. Please check with NPG.</assert>
      </rule>
  </pattern>
   <pattern><!--... and only one of each type-->
    <rule context="history/date[not(@date-type='rev-recd')]" role="error">
         <report id="histdate0c" test="@date-type=./preceding-sibling::date/@date-type">There should only be one instance of the "date" element with "date-type" attribute value of "<value-of select="@date-type"/>". Please check with NPG.</report>
      </rule>
  </pattern>
   <pattern><!--Valid values for year, month and day-->
    <rule context="history/date" role="error">
         <assert id="histdate1a" test="not(year) or matches(year, '^(19|20)[0-9]{2}$')">Invalid year value: <value-of select="year"/>. It should be a 4-digit number starting with 19 or 20.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="history/date" role="error">
         <assert id="histdate1b" test="not(month) or matches(month, '^((0[1-9])|(1[0-2]))$')">Invalid month value: <value-of select="month"/>. It should be a 2-digit number between 01 and 12.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="history/date" role="error">
         <assert id="histdate1c" test="not(day) or matches(day, '^(0[1-9]|[12][0-9]|3[01])$')">Invalid day value: <value-of select="day"/>. It should be a 2-digit number between 01 and 31.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="history/date/season" role="error">
         <report id="histdate1d" test=".">Do not use "season" (<value-of select="."/>). "Day" and "month" are the only other elements which should be used.</report>
      </rule>
  </pattern>
   <pattern><!--Concatenate year/month/day and check valid if those elements have already passed basic validation checks. This regex taken from http://regexlib.com, author Ted Cambron-->
    <rule context="history/date[matches(year, '^(19|20)[0-9]{2}$') and matches(month, '^((0[1-9])|(1[0-2]))$') and matches(day, '^(0[1-9]|[12][0-9]|3[01])$')]"
            role="error">
         <assert id="histdate2"
                 test="matches(concat(year,'-',month,'-',day), '^((((19|20)(([02468][048])|([13579][26]))-02-29))|((20[0-9][0-9])|(19[0-9][0-9]))-((((0[1-9])|(1[0-2]))-((0[1-9])|(1[0-9])|(2[0-8])))|((((0[13578])|(1[02]))-31)|(((0[1,3-9])|(1[0-2]))-(29|30)))))$')">Invalid history date - the day value (<value-of select="day"/>) does not exist for the month (<value-of select="month"/>) in the year (<value-of select="year"/>).</assert>
      </rule>
  </pattern>
   <pattern><!--Year/Day - invalid combination in date-->
    <rule context="history/date[year and day]" role="error">
         <assert id="histdate3" test="month">Missing month in "date" element. Currently only contains year and day.</assert>
      </rule>
  </pattern>
   <pattern><!--No content-type attribute on day, month or year-->
    <rule context="day[ancestor::history] | month[ancestor::history] | year[ancestor::history]"
            role="error">
         <report id="histdate4" test="@content-type">Do not use "content-type" attribute on <name/> within "date" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="article-meta"><!--permissions and expected children exist-->
      <assert id="copy1a" test="permissions">Article metadata should include a "permissions" element.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="permissions"><!--permissions and expected children exist-->
      <assert id="copy1b" test="copyright-year">Permissions should include the copyright year.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="permissions">
         <assert id="copy1c" test="copyright-holder">Permissions should include the copyright holder.</assert>
      </rule>
  </pattern>
   <pattern><!--Is the copyright year valid?-->
    <rule context="copyright-year" role="error">
         <assert id="copy2" test="matches(.,'^(19|20)[0-9]{2}$')">Invalid year value for copyright: <value-of select="."/>. It should be a 4-digit number starting with 19 or 20.</assert>
      </rule>
  </pattern>
   <pattern><!--No other elements in copyright-statement-->
    <rule context="copyright-statement/*" role="error">
         <report id="copy4" test=".">Do not use "<name/>" element in "copyright-statement" - it should only contain text.</report>
      </rule>  
  </pattern>
   <pattern><!--Related-article with a link should have @ext-link-type-->
    <rule context="article-meta/related-article[@xlink:href]" role="error">
         <assert id="relart1a" test="@ext-link-type">"related-article" element of type '<value-of select="@related-article-type"/>' should also have 'ext-link-type' attribute.</assert>
      </rule>  
  </pattern>
   <pattern><!--Related-article should have @xlink:href-->
    <rule context="article-meta/related-article[not(@related-article-type='original-article') and @ext-link-type]"
            role="error">
         <assert id="relart1b" test="@xlink:href">"related-article" element of type '<value-of select="@related-article-type"/>' should have 'xlink:href' attribute.</assert>
      </rule>  
  </pattern>
   <pattern><!--Bi directional articles should have @xlink:href and @ext-link-type-->
    <rule context="article-meta/related-article[not(@related-article-type='original-article') and not(@ext-link-type)]"
            role="error">
         <assert id="relart1c" test="@xlink:href">"related-article" element of type '<value-of select="@related-article-type"/>' should have 'xlink:href' and 'ext-link-type' attributes.</assert>
      </rule>  
  </pattern>
   <pattern><!--@related-article-type has allowed value-->
    <rule context="article-meta/related-article" role="error">
         <let name="relatedArticleType" value="@related-article-type"/>
         <assert id="relart2"
                 test="$allowed-values/related-article-types/related-article-type[.=$relatedArticleType]">"related-article" element has incorrect 'related-article-type' value (<value-of select="@related-article-type"/>). Allowed values are: is-addendum-to, is-comment-to, is-correction-to, is-corrigendum-to, is-erratum-to, is-news-and-views-to, is-protocol-to, is-protocol-update-to, is-related-to, is-research-highlight-to, is-response-to, is-retraction-to, is-update-to</assert>
      </rule>  
  </pattern>
   <pattern><!--valid @abstract-type-->
    <rule context="abstract[@abstract-type]" role="error">
         <let name="abstractType" value="@abstract-type"/>
         <assert id="abs1" test="$allowed-values/abstract-types/abstract-type[.=$abstractType]">Unexpected value for "abstract-type" attribute (<value-of select="$abstractType"/>). Allowed values are: editor, editor-standfirst, editorial-summary, editorial-notes, executive-summary, first-paragraph, key-points, research-summary, standfirst, synopsis, toc, toc-note, web-summary.</assert>
      </rule>
  </pattern>
   <pattern><!--only one of each abstract type used-->
    <rule context="abstract[not(@abstract-type='editor' or @abstract-type='editor-standfirst' or @abstract-type='research-summary' or @abstract-type='editorial-summary' or @abstract-type='editorial-notes')]"
            role="error">
         <report id="abs2a" test="@abstract-type=./preceding-sibling::abstract/@abstract-type">Only one abstract of type "<value-of select="@abstract-type"/>" should appear in an article.</report>
      </rule>
  </pattern>
   <pattern><!--"research-summary" not used as @abstract-type value in new journals-->
    <rule context="abstract[@abstract-type='research-summary']" role="error">
         <report id="abs2b" test="matches($pcode,'^(mtm|hortres)$')">Do not use 'abstract-type="research-summary" in <value-of select="$journal-title"/>, use 'abstract-type="editorial-summary" instead.</report>
      </rule>
  </pattern>
   <pattern><!--dateline para in correct place-->
    <rule context="abstract[p[@content-type='dateline']]" role="error">
         <assert id="abs3a" test="@abstract-type='web-summary' or @abstract-type='toc'">Dateline paragraphs should only be used in 'web-summary' or 'toc' abstracts.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="abstract[@abstract-type='web-summary' or @abstract-type='toc']/p[@content-type='dateline']"
            role="error">
         <assert id="abs3b" test="not(preceding-sibling::p)">Dateline paragraphs should only appear as the first element in an abstract.</assert>
      </rule>
  </pattern>
   <pattern><!--editor summaries specific-use attribute equal to 'aop' or 'issue'-->
    <rule context="abstract[@abstract-type='editor' or @abstract-type='editor-standfirst' or @abstract-type='research-summary' or @abstract-type='editorial-notes'][@specific-use]"
            role="error">
         <assert id="abs4a" test="@specific-use='aop' or @specific-use='issue'">Unexpected value (<value-of select="@specific-use"/>) for "specific-use" attribute on editor abstracts. Allowed values are "aop" or "issue".</assert>
      </rule>
  </pattern>
   <pattern><!--only one of each specific-use type used in editor summaries-->
    <rule context="abstract[@abstract-type='editor'][@specific-use]" role="error">
         <report id="abs4b"
                 test="@specific-use=./preceding-sibling::abstract[@abstract-type='editor']/@specific-use">Only one abstract of type "<value-of select="@specific-use"/>" should appear on editor abstract in each article.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="abstract[@abstract-type='editor-standfirst'][@specific-use]"
            role="error">
         <report id="abs4c"
                 test="@specific-use=./preceding-sibling::abstract[@abstract-type='editor-standfirst']/@specific-use">Only one abstract of type "<value-of select="@specific-use"/>" should appear on editor-standfirst in each article.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="abstract[@abstract-type='research-summary'][@specific-use]"
            role="error">
         <report id="abs4d"
                 test="@specific-use=./preceding-sibling::abstract[@abstract-type='research-summary']/@specific-use">Only one abstract of type "<value-of select="@specific-use"/>" should appear on research-summary in each article.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="abstract[@abstract-type='editorial-notes'][@specific-use]"
            role="error">
         <report id="abs4e"
                 test="@specific-use=./preceding-sibling::abstract[@abstract-type='editorial-notes']/@specific-use">Only one abstract of type "<value-of select="@specific-use"/>" should appear on editorial-notes in each article.</report>
      </rule>
  </pattern>
   <pattern><!--update $derived-status with all Frontiers titles if they are converted to JATS-->
    <rule context="article-meta" role="error">
         <let name="derived-status"
              value="if (matches($pcode,'^(am|bcj|boneres|cddis|ctg|cti|emi|emm|hortres|lsa|msb|mtm|mtna|ncomms|nmstr|nutd|oncsis|psp|scibx|sdata|srep|tp)$')) then 'online'         else if (pub-date[@pub-type='epub'] or pub-date[@pub-type='cover-date']) then 'issue'         else if (pub-date[@pub-type='aop']) then 'aop'         else if (pub-date[@pub-type='fav']) then 'fav'         else 'issue'"/>
         <assert id="custom1"
                 test="not($products[descendant::product/@pcode=$pcode]) or custom-meta-group/custom-meta[meta-name='publish-type']">All articles should contain publication status information at the end of "article-metadata". Insert "custom-meta-group/custom-meta" with "meta-name". For this journal and publication status, "meta-value" should be "<value-of select="$derived-status"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--update $derived-status with all Frontiers titles if they are converted to JATS-->
    <rule context="article-meta/custom-meta-group/custom-meta[meta-name='publish-type']"
            role="error">
         <let name="status" value="meta-value"/>
         <let name="derived-status"
              value="if (matches($pcode,'^(am|bcj|boneres|cddis|ctg|cti|emi|emm|hortres|lsa|msb|mtm|mtna|ncomms|nmstr|nutd|oncsis|psp|scibx|sdata|srep|tp)$')) then 'online'         else if (ancestor::article-meta/pub-date[@pub-type='epub'] or ancestor::article-meta/pub-date[@pub-type='cover-date']) then 'issue'         else if (ancestor::article-meta/pub-date[@pub-type='aop']) then 'aop'         else if (ancestor::article-meta/pub-date[@pub-type='fav']) then 'fav'         else 'issue'"/>
         <assert id="custom2"
                 test="not($products[descendant::product/@pcode=$pcode]) or $status=$derived-status">Unexpected value for "publish-type" (<value-of select="$status"/>). Expected value for this journal and publication status is "<value-of select="$derived-status"/>".</assert>
      </rule>
  </pattern>
      <pattern>
      <rule context="article-meta/custom-meta-group/custom-meta[meta-name='publish-type'][1]"
            role="error">
         <report id="custom2b" test="following-sibling::custom-meta[meta-name='publish-type']">'publish-type' should only be used once in "custom-meta".</report>
      </rule>
  </pattern>
   <pattern><!--new OA AJs with restricted article types-->
    <rule context="article[matches($pcode,'^(mtm|hortres)$') or ($pcode='boneres' and not(descendant::volume='1'))]"
            role="error">
         <assert id="oa-aj1"
                 test="matches($article-type,'^(add|af|bc|cg|com|cr|cs|ed|er|mr|nv|prot|ret|rv)$')">Invalid article-type used (<value-of select="$article-type"/>). Article types for "<value-of select="$journal-title"/>" are restricted to: 'add' (Addendum), 'af' (Article), 'bc' (Brief Communication), 'cg' (Corrigendum), 'com' (Comment), 'cr' (Correspondence), 'cs' (Correction), 'ed' (Editorial), 'er' (Erratum), 'mr' (Meeting Report), 'nv' (News and Views), 'prot' (Protocol), 'ret' (Retraction), and 'rv' (Review Article or Mini Review).</assert>
      </rule>
  </pattern>
<pattern><!--SciData restricted article types-->
    <rule context="article[$pcode='sdata']" role="error">
         <assert id="oa-aj1b" test="matches($article-type,'^(add|cg|com|cs|dd|ed|er|ret)$')">Invalid article-type used (<value-of select="$article-type"/>). The only article types allowed in Scientific Data are 'dd' (Data Descriptor), 'com' (Comment) and 'ed' (Editorial). Correction articles are also allowed: 'add' (Addendum), 'cg' (Corrigendum), 'cs' (Correction), 'er' (Erratum), and 'ret' (Retraction).</assert>
      </rule>
  </pattern>   
<pattern><!--volume should be given in all new OA only journals-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata|boneres)$')]/front/article-meta"
            role="error">
         <assert id="oa-aj2a" test="volume">A "volume" element should be used in "<value-of select="$journal-title"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--issue should not be used in new OA only journals-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]/front/article-meta/issue"
            role="error">
         <report id="oa-aj2b" test=".">"issue" should not be used in "<value-of select="$journal-title"/>".</report>
      </rule>
  </pattern>
   <pattern><!--elocation-id should be given in all new OA only journals-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]/front/article-meta"
            role="error">
         <assert id="oa-aj2c" test="elocation-id">An "elocation-id" should be used in "<value-of select="$journal-title"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--elocation-id should be numerical, i.e. does not start with 'e' or leading zeros-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata|boneres)$')]/front/article-meta/elocation-id"
            role="error">
         <assert id="oa-aj2d" test="matches(.,'^[1-9][0-9]*$')">"elocation-id" in "<value-of select="$journal-title"/>" should be a numerical value only (with no leading zeros), not "<value-of select="."/>".</assert>
      </rule>
  </pattern>
   <pattern><!--open access license info should be given in all new OA only journals (except in correction articles)-->
      <rule context="article[(matches($pcode,'^(mtm|hortres|sdata|nutd|boneres)$')) and not(matches($article-type,'^(add|cg|cs|er|ret)$'))]/front/article-meta/permissions"
            role="error">
         <assert id="oa-aj3" test="license">"<value-of select="$journal-title"/>" should contain "license", which gives details of the Open Access license being used. Please contact NPG for this information.</assert>
      </rule>
  </pattern>
   <pattern><!--open access license info should not be given in correction articles in new OA only journals-->
    <rule context="article[(matches($pcode,'^(mtm|hortres|sdata|nutd|boneres)$')) and matches($article-type,'^(add|cg|cs|er|ret)$')]/front/article-meta/permissions"
            role="error">
         <let name="article-type-name"
              value="if ($article-type='add') then 'Addendum'          else if ($article-type='cg') then 'Corrigendum'          else if ($article-type='cs') then 'Correction'          else if ($article-type='er') then 'Erratum'          else if ($article-type='ret') then 'Retraction' else ()"/>
         <report id="oa-aj3b" test="license">"license" should not be used in correction articles, as they are not Open Access. This article is: <value-of select="$article-type-name"/>.</report>
      </rule>
  </pattern>
   <pattern><!--error in pcode, but numerical value ok-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata|boneres)$') or ($pcode='boneres' and not(descendant::volume='1'))]//article-meta/article-id[@pub-id-type='publisher-id']"
            role="error">
         <let name="derivedPcode" value="tokenize(.,'[0-9]')[1]"/>
         <let name="numericValue" value="replace(.,$derivedPcode,'')"/>
      <report id="oa-aj4a2"
                 test="not($pcode=$derivedPcode) and ($derivedPcode ne '' and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Article id (<value-of select="."/>) should start with the pcode/journal-id (<value-of select="$pcode"/>) not "<value-of select="$derivedPcode"/>". Other rules are based on having a correct article id and therefore will not be run. Please resubmit this file when the article id has been corrected.</report>
      </rule>
  </pattern>
   <pattern><!--pcode ok but error in numerical value-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//article-meta/article-id[@pub-id-type='publisher-id']"
            role="error">
         <let name="derivedPcode" value="tokenize(.,'[0-9]')[1]"/>
         <let name="numericValue" value="replace(.,$derivedPcode,'')"/>
         <report id="oa-aj4a3"
                 test="not(matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$')) and ($derivedPcode ne '' and $pcode=$derivedPcode)">Article id after the "<value-of select="$pcode"/>" pcode (<value-of select="$numericValue"/>) should have format year + number of article (without additional letters or leading zeros). Other rules are based on having a correct article id and therefore will not be run. Please resubmit this file when the article id has been corrected.</report>
      </rule>
  </pattern>
   <pattern><!--errors in pcode and numerical value-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//article-meta/article-id[@pub-id-type='publisher-id']"
            role="error">
         <let name="derivedPcode" value="tokenize(.,'[0-9]')[1]"/>
         <let name="numericValue" value="replace(.,$derivedPcode,'')"/>
         <report id="oa-aj4a4"
                 test="$derivedPcode ne '' and not($pcode=$derivedPcode) and not(matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Article id (<value-of select="."/>) should have format pcode + year + number of article (without additional letters or leading zeros). Other rules are based on having a correct article id and therefore will not be run. Please resubmit this file when the article id has been corrected.</report>
      </rule>
  </pattern>
   <pattern><!--Does doi match article-id?-->
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//article-meta/article-id[@pub-id-type='doi']"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="derivedDoi"
              value="concat('10.1038/',$derivedPcode,'.',substring($numericValue,1,4),'.',substring($numericValue,5))"/>
         <assert id="oa-aj5"
                 test=".=$derivedDoi or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Article DOI (<value-of select="."/>) does not match the expected value based on the article id (<value-of select="$derivedDoi"/>).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//fig//graphic[@xlink:href]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="fig-image" value="substring-before(@xlink:href,'.')"/>
         <let name="fig-number" value="replace(replace($fig-image,$article-id,''),'-','')"/>
         <assert id="oa-aj6a"
                 test="starts-with($fig-image,concat($article-id,'-')) and matches($fig-number,'^f[1-9][0-9]*[a-z]?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for figure image (<value-of select="$fig-image"/>). Expected format is "<value-of select="concat($article-id,'-f')"/>"+number (and following letters, if figure has multiple images).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//fig//supplementary-material[@content-type='slide'][@xlink:href]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="fig-image" value="substring-before(@xlink:href,'.')"/>
         <let name="fig-number" value="replace(replace($fig-image,$article-id,''),'-','')"/>
         <assert id="oa-aj6b"
                 test="starts-with($fig-image,concat($article-id,'-')) and matches($fig-number,'^pf[1-9][0-9]*[a-z]?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for figure slide (<value-of select="$fig-image"/>). Expected format is "<value-of select="concat($article-id,'-pf')"/>"+number (and following letters, if figure has multiple slides).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//table-wrap//graphic[@xlink:href]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="tab-image" value="substring-before(@xlink:href,'.')"/>
         <let name="tab-number" value="replace(replace($tab-image,$article-id,''),'-','')"/>
         <assert id="oa-aj7a"
                 test="starts-with($tab-image,concat($article-id,'-')) and matches($tab-number,'^t[1-9][0-9]*?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for table image (<value-of select="$tab-image"/>). Expected format is "<value-of select="concat($article-id,'-t')"/>"+number.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//table-wrap//supplementary-material[@content-type='slide'][@xlink:href]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="tab-image" value="substring-before(@xlink:href,'.')"/>
         <let name="tab-number" value="replace(replace($tab-image,$article-id,''),'-','')"/>
         <assert id="oa-aj7b"
                 test="starts-with($tab-image,concat($article-id,'-')) and matches($tab-number,'^pt[1-9][0-9]*?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for table slide (<value-of select="$tab-image"/>). Expected format is "<value-of select="concat($article-id,'-pt')"/>"+number.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//floats-group/graphic[@content-type='illustration'][@xlink:href]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="ill-image" value="substring-before(@xlink:href,'.')"/>
         <let name="ill-number" value="replace(replace($ill-image,$article-id,''),'-','')"/>
         <assert id="oa-aj8"
                 test="starts-with($ill-image,concat($article-id,'-')) and matches($ill-number,'^i[1-9][0-9]*?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for illustration (<value-of select="$ill-image"/>). Expected format is "<value-of select="concat($article-id,'-i')"/>"+number.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="article[matches($pcode,'^(nmstr|mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]//floats-group/supplementary-material[@xlink:href][not(@content-type='isa-tab')]"
            role="error">
         <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)-->
         <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="supp-image" value="substring-before(@xlink:href,'.')"/>
         <let name="supp-number" value="replace(replace($supp-image,$article-id,''),'-','')"/>
         <let name="supp-id" value="@id"/>
      <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <assert id="oa-aj9"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) or starts-with($supp-image,concat($article-id,'-')) and matches($supp-number,$supp-id) or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for supplementary information (<value-of select="@xlink:href"/>). Expected format is "<value-of select="concat($article-id,'-',$supp-id,'.',$extension)"/>", i.e. XML filename + dash + id of supplementary material.</assert>
      </rule>
  </pattern>
<pattern>
      <rule context="article[$pcode='sdata']//floats-group/supplementary-material[@xlink:href][@content-type='isa-tab']"
            role="error">
      <!--let name="filename" value="functx:substring-after-last(functx:substring-before-last(base-uri(.),'.'),'/')"/--><!--or not($article-id=$filename)--> 
      <let name="derivedPcode" value="tokenize($article-id,'[0-9]')[1]"/>
         <let name="numericValue" value="replace($article-id,$derivedPcode,'')"/>
         <let name="supp-image" value="substring-before(@xlink:href,'.')"/>
         <let name="supp-number" value="replace(replace($supp-image,$article-id,''),'-','')"/>
         <assert id="oa-aj9b"
                 test="starts-with($supp-image,concat($article-id,'-')) and matches($supp-number,'^isa[1-9][0-9]*?$') or not($derivedPcode ne '' and $pcode=$derivedPcode and matches($numericValue,'^20[1-9][0-9][1-9][0-9]*$'))">Unexpected filename for ISA-tab file (<value-of select="$supp-image"/>). Expected format is "<value-of select="concat($article-id,'-isa')"/>"+number.</assert>
      </rule>
  </pattern>
   <pattern><!--subject path found in subject ontology-->
      <rule context="article[matches($pcode,'^(mtm|hortres|sdata|boneres)$')]//subject[@content-type='npg.subject']/named-content[@content-type='path']">
         <let name="derivedUri" value="concat('data:,npg.subject:',.)"/>
         <assert id="oa-aj10a" test="$derivedUri = $subjects//subject/@uri">Subject path (<value-of select="."/>) is not recognized by the subject ontology. Please check the information supplied by NPG.</assert>
      </rule>
  </pattern>
   <pattern><!--subject path valid for the journal-->
      <rule context="article[matches($pcode,'^(mtm|hortres|sdata|boneres)$')]//subject[@content-type='npg.subject']/named-content[@content-type='path']">
         <let name="derivedUri" value="concat('data:,npg.subject:',.)"/>
         <assert id="oa-aj10b"
                 test="$subjects//subject[@uri/.=$derivedUri]/references/reference[@pcode=$pcode] or not($derivedUri = $subjects//subject/@uri)">Subject path (<value-of select="."/> - <value-of select="$subjects//subject[@uri/.=$derivedUri]/@name"/>) is not allowed in "<value-of select="$journal-title"/>". Please check the information supplied by NPG.</assert>
      </rule>
  </pattern>
   <pattern><!--id should be final value in subject path-->
      <rule context="article[matches($pcode,'^(mtm|hortres|sdata|boneres)$')]//subject[@content-type='npg.subject']/named-content[@content-type='id']">
         <let name="path" value="following-sibling::named-content[@content-type='path'][1]"/>
         <let name="derivedUri" value="concat('data:,npg.subject:',$path)"/>
         <let name="derivedId" value="functx:substring-after-last($path,'/')"/>
         <assert id="oa-aj10c"
                 test=".=$derivedId or not($subjects//subject[@uri/.=$derivedUri]/references/reference[@pcode=$pcode]) or not($derivedUri = $subjects//subject/@uri)">Subject 'id' (<value-of select="."/>) does not match the final part of subject 'path' (<value-of select="$derivedId"/>). Please check the information supplied by NPG.</assert>
      </rule>
  </pattern>
   <pattern><!--article-type and article heading should be equivalent (not 'rv')-->
    <rule context="article[(matches($pcode,'^(mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))) and (matches($article-type,'^(add|af|bc|cg|com|cr|cs|dd|ed|er|mr|nv|prot|ret)$'))]/front/article-meta//subject[@content-type='article-heading']"
            role="error">
         <let name="article-heading"
              value="if ($article-type='add') then 'Addendum'          else if ($article-type='cg') then 'Corrigendum'          else if ($article-type='cs') then 'Correction'          else if ($article-type='er') then 'Erratum'          else if ($article-type='ret') then 'Retraction'         else if ($article-type='af') then 'Article'         else if ($article-type='bc') then 'Brief Communication'         else if ($article-type='com') then 'Comment'         else if ($article-type='cr') then 'Correspondence'         else if ($article-type='ed') then 'Editorial'         else if ($article-type='mr') then 'Meeting Report'         else if ($article-type='nv') then 'News and Views'         else if ($article-type='prot') then 'Protocol'         else if ($article-type='dd') then 'Data Descriptor'         else ()"/>
         <assert id="oa-aj11a" test=".=$article-heading">Mismatch between article-heading (<value-of select="."/>) and expected value based on article-type (<value-of select="$article-heading"/>).</assert>
      </rule>
  </pattern>
   <pattern><!--article-type and article heading should be equivalent (for 'rv')-->
    <rule context="article[(matches($pcode,'^(mtm|hortres)$') or ($pcode='boneres' and not(descendant::volume='1'))) and(matches($article-type,'^(rv)$'))]/front/article-meta//subject[@content-type='article-heading']"
            role="error">
         <assert id="oa-aj11b" test="matches(.,'^(Mini Review|Review Article)$')">Mismatch between article-heading (<value-of select="."/>) and expected value based on article-type ("Mini Review" or "Review Article").</assert>
      </rule>
  </pattern>
   <pattern><!--article-heading should be used (not 'rv')-->
    <rule context="article[(matches($pcode,'^(mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))) and(matches($article-type,'^(add|af|bc|cg|com|cr|cs|dd|ed|er|mr|nv|prot|ret)$'))]/front/article-meta/article-categories"
            role="error">
         <let name="article-heading"
              value="if ($article-type='add') then 'Addendum'          else if ($article-type='cg') then 'Corrigendum'          else if ($article-type='cs') then 'Correction'          else if ($article-type='er') then 'Erratum'          else if ($article-type='ret') then 'Retraction'         else if ($article-type='af') then 'Article'         else if ($article-type='bc') then 'Brief Communication'         else if ($article-type='com') then 'Comment'         else if ($article-type='cr') then 'Correspondence'         else if ($article-type='ed') then 'Editorial'         else if ($article-type='mr') then 'Meeting Report'         else if ($article-type='nv') then 'News and Views'         else if ($article-type='prot') then 'Protocol'         else if ($article-type='dd') then 'Data Descriptor'         else ()"/>
         <assert id="oa-aj11c" test="subj-group/@subj-group-type='article-heading'">Article categories should contain a "subj-group" element with attribute "subj-group-type='article-heading'". The value of the child "subject" element (with attribute "content-type='article-heading'") should be: <value-of select="$article-heading"/>.</assert>
      </rule>
  </pattern>
   <pattern><!--article heading should be used (for 'rv')-->
    <rule context="article[(matches($pcode,'^(mtm|hortres)$') or ($pcode='boneres' and not(descendant::volume='1'))) and(matches($article-type,'^(rv)$'))]/front/article-meta/article-categories"
            role="error">
         <assert id="oa-aj11d" test="subj-group/@subj-group-type='article-heading'">Article categories should contain a "subj-group" element with attribute "subj-group-type='article-heading'". The value of the child "subject" element (with attribute "content-type='article-heading'") should be "Mini Review" or "Review Article". Please check instructions from NPG.</assert>
      </rule>
  </pattern>
   <pattern><!--authors should link to their affiliated body, even when there is only one aff-->
    <rule context="article[matches($pcode,'^(mtm|hortres|sdata|boneres)$')]/front/article-meta[aff]/contrib-group/contrib"
            role="error">
         <assert id="oa-aj12" test="xref[@ref-type='aff']">All authors should be linked to an affiliated body. Insert xref with 'ref-type="aff"'.</assert>
      </rule>
  </pattern>
   <pattern><!--pub-date should have @pub-type="epub"-->
    <rule context="article[matches($pcode,'^(mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]/front/article-meta/pub-date"
            role="error">
         <assert id="oa-aj13a" test="@pub-type='epub'">Online-only open access journals should have publication date with the 'pub-type' attribute value "epub", not "<value-of select="@pub-type"/>". </assert>
      </rule>
  </pattern>
   <pattern><!--pub-date should have day element-->
    <rule context="article[matches($pcode,'^(mtm|hortres|sdata)$') or ($pcode='boneres' and not(descendant::volume='1'))]/front/article-meta/pub-date[@pub-type='epub']"
            role="error">
         <assert id="oa-aj13b" test="day">Online-only open access journals should have a full publication date - "day" is missing.</assert>
      </rule>
  </pattern>
   <pattern><!--Only one author email per corresp element-->
    <rule context="corresp[count(email) gt 1][matches($pcode,'^(nmstr|mtm|hortres|sdata|boneres)$')]"
            role="error">
         <report id="maestro1" test=".">Corresponding author information should only contain one email address. Please split "corresp" with id='<value-of select="@id"/>' into separate "corresp" elements - one for each corresponding author. You will also need to update the equivalent "xref" elements with the new 'rid' values.</report>
      </rule>
  </pattern>
   <pattern><!--Do not include the word 'correspondence' in the corresp element-->
    <rule context="corresp[matches($pcode,'^(nmstr|mtm|hortres|sdata|boneres)$')]"
            role="error">
         <report id="aj-corresp1"
                 test="starts-with(.,'correspondence') or starts-with(.,'Correspondence') or starts-with(.,'CORRESPONDENCE')">Do not include the unnecessary text 'Correspondence' in the "corresp" element.</report>
      </rule>
  </pattern>
   <pattern><!--no empty xrefs for ref-types="author-notes"-->
    <rule context="xref[@ref-type='author-notes'][matches($pcode,'^(nmstr|mtm|hortres|boneres)$')]"
            role="error">
         <assert id="aj-aunote1a" test="normalize-space(.) or *">"xref" with ref-type="author-notes" and rid="<value-of select="@rid"/>" should contain text. Please see Tagging Instructions for further examples.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[not(@fn-type)][@id][matches($pcode,'^(nmstr|mtm|hortres|boneres)$')]"
            role="error">
         <let name="id" value="@id"/>
         <let name="symbol" value="(ancestor::article//xref[matches(@rid,$id)])[1]//text()"/>
         <assert id="aj-aunote1b" test="label">Missing "label" element in author footnote - please insert one containing the same text as the corresponding "xref" element<value-of select="if ($symbol ne '') then concat(' (',$symbol,')') else ()"/>.</assert>
      </rule>
  </pattern>
   <pattern><!--correction articles should contain a related-article element-->
    <rule context="article[(matches($pcode,'^(mtm|hortres|sdata|boneres)$')) and matches($article-type,'^(add|cg|cs|er|ret)$')]/front/article-meta"
            role="error">
         <let name="article-type-name"
              value="if ($article-type='add') then 'Addendum'          else if ($article-type='cg') then 'Corrigendum'          else if ($article-type='cs') then 'Correction'          else if ($article-type='er') then 'Erratum'          else if ($article-type='ret') then 'Retraction' else ()"/>
         <let name="related-article-type"
              value="if ($article-type='add') then 'is-addendum-to'          else if ($article-type='cg') then 'is-corrigendum-to'          else if ($article-type='cs') then 'is-correction-to'          else if ($article-type='er') then 'is-erratum-to'          else if ($article-type='ret') then 'is-retraction-to' else ()"/>
         <assert id="correct1a" test="related-article">
            <value-of select="$article-type-name"/> should have a "related-article" element giving information on the article being corrected (following the "permissions" element). It should have 'related-article-type="<value-of select="$related-article-type"/>"', 'ext-link-type="doi"' and an 'xlink:href' giving the full doi of the corrected article.</assert>
      </rule>
  </pattern>
   <pattern><!--check correction articles have matching @related-article-type and @article-type values-->
    <rule context="article[(matches($pcode,'^(mtm|hortres|sdata|boneres)$')) and matches($article-type,'^(add|cg|cs|er|ret)$')]/front/article-meta/related-article"
            role="error">
         <let name="article-type-name"
              value="if ($article-type='add') then 'Addendum'          else if ($article-type='cg') then 'Corrigendum'          else if ($article-type='cs') then 'Correction'          else if ($article-type='er') then 'Erratum'          else if ($article-type='ret') then 'Retraction' else ()"/>
         <let name="related-article-type"
              value="if ($article-type='add') then 'is-addendum-to'          else if ($article-type='cg') then 'is-corrigendum-to'          else if ($article-type='cs') then 'is-correction-to'          else if ($article-type='er') then 'is-erratum-to'          else if ($article-type='ret') then 'is-retraction-to' else ()"/>
         <assert id="correct1b" test="matches(@related-article-type,$related-article-type)">Mismatch between 'related-article-type' attribute (<value-of select="@related-article-type"/>) and expected value based on article-type (<value-of select="$related-article-type"/>).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="contrib-group[not(@content-type='contributor')]/contrib/xref"
            role="error"><!--Contrib xref should have @ref-type-->
      <assert id="contrib1a" test="@ref-type">Contributor "xref" should have a 'ref-type' attribute. The allowed values are "aff" (for links to affilation information), "corresp" (for correspondence information) and "author-notes" for any other notes.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="contrib/xref" role="error"><!--Contrib xref should have @rid-->
      <assert id="contrib1b" test="@rid">Contributor "xref" should have an 'rid' attribute.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="contrib/xref[@ref-type]" role="error"><!--Contrib xref ref-type should have allowed value-->
        <assert id="contrib1c"
                 test="matches(@ref-type,'^(aff|corresp|author-notes|statement)$')">Unexpected value for contributor "xref" 'ref-type' attribute (<value-of select="@ref-type"/>). The allowed values are "aff" (for links to affilation information), "corresp" (for correspondence information) and "author-notes" for any other notes.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="front//aff" role="error"><!--should be a child of article-meta-->
      <assert id="aff1" test="parent::article-meta">"aff" element should be a direct child of "article-meta" after "contrib-group" - not a child of "<value-of select="name(parent::*)"/>".</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="xref[@ref-type='aff'][@rid]" role="error"><!--xref/@ref-type='aff' should be empty-->
      <report id="aff2a" test="matches(.,replace(@rid,'a',''))">Do not use text in "xref" element with ref-type="aff" - these values can be auto-generated from the ids.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="aff/label" role="error"><!--aff should not contain label-->
      <report id="aff2b" test="matches(.,replace(parent::aff/@id,'a',''))">Do not use "label" in "aff" element - these values can be auto-generated from the ids.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="aff" role="error"><!--Affiliation information should have id-->
      <assert id="aff3a" test="@id">Missing 'id' attribute - "aff" should have an 'id' of the form "a"+number (with no leading zeros).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="aff[@id]" role="error"><!--Affiliation id in required format-->
      <assert id="aff3b" test="matches(@id,'^a[1-9][0-9]*$')">Invalid 'id' value ("<value-of select="@id"/>"). "aff" 'id' attribute should be of the form "a"+number (with no leading zeros). Also, update the values in any linking "xref" elements.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="addr-line[not(parent::address)]" role="error">
         <assert id="aff10a" test="@content-type">"addr-line" should have a 'content-type' attribute. Allowed values are: street, city, state, and zip.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="addr-line[@content-type]" role="error">
         <assert id="aff10b" test="matches(@content-type,'^(street|city|state|zip)$')">Unexpected value for "addr-line" 'content-type' attribute (<value-of select="@content-type"/>). Allowed values are: street, city, state, and zip.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="corresp" role="error"><!--Correspondence information should have id-->
        <assert id="corres1a" test="@id">Missing 'id' attribute - "corresp" should have an 'id' of the form "c"+number.</assert>
      </rule>
    </pattern>
   <pattern>
      <rule context="corresp[@id]" role="error"><!--Correspondence id in required format-->
      <assert id="corres1b" test="matches(@id,'^c[0-9]+$')">Invalid 'id' value ("<value-of select="@id"/>"). "corresp" 'id' attribute should be of the form "c"+number.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="corresp[@id][named-content/@content-type='author']" role="error"><!--Correspondence information given, but no corresponding author in contrib list-->
      <let name="id" value="@id"/>
         <assert id="corres1c1" test="ancestor::article//xref[@ref-type='corresp'][@rid=$id]">Corresponding author information has been given for <value-of select="named-content[@content-type='author']"/>, but no link has been added to the contrib information. For the corresponding "contrib" element, change 'corresp' attribute to "yes" and insert an "xref" link with attributes ref-type="corresp" and rid="<value-of select="@id"/>".</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="corresp[@id][not(named-content/@content-type='author')]" role="error"><!--Correspondence information given, but no corresponding author in contrib list-->
      <let name="id" value="@id"/>
         <assert id="corres1c2" test="ancestor::article//xref[@ref-type='corresp'][@rid=$id]">Corresponding author information has been given, but no contributor has been linked. Please add linking information to the relevant "contrib" element - change 'corresp' attribute to "yes" and insert an "xref" link with attributes ref-type="corresp" and rid="<value-of select="@id"/>"</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="xref[@ref-type='corresp'][parent::contrib/@contrib-type='author']"
            role="error"><!--Correspondence information given, but no corresponding author in contrib list-->
      <assert id="corres1d" test="parent::contrib[@corresp='yes']">Contributor has an "xref" link to correspondence information (ref-type="corresp"), but has not been identified as a corresponding author (corresp="yes").</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="contrib[@corresp='yes']" role="error"><!--Correspondence information given, but no corresponding author in contrib list-->
      <assert id="corres1e" test="xref[@ref-type='corresp']">Contributor has been identified as a corresponding author (corresp="yes"), but no "xref" link (ref-type="corresp") has been given.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="corresp[count(email) gt 1]/named-content[@content-type='author'][not(matches($pcode,'^(nmstr|mtm|hortres|sdata)$'))]"
            role="error"><!--Only one author email per corresp element-->
      <report id="corres2" test="contains(.,' or ')">Corresponding author information should only contain one email address. Please split "corresp" with id='<value-of select="parent::corresp/@id"/>' into separate "corresp" elements - one for each corresponding author. You will also need to update the equivalent "xref" elements with the new 'rid' values.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[@fn-type='conflict']/p" role="error"><!--Conflict of interest statement should not be empty - common in NPG titles. I assume XBuilder auto-generates it-->
         <assert id="conflict1" test="normalize-space(.) or *">Empty "conflict of interest" statement used. Please add text of the statement as used in the pdf.</assert>
      </rule>
  </pattern>
  <pattern>
      <rule context="author-notes/fn[@fn-type='conflict']" role="error"><!--Conflict of interest statement should not have an id-->
      <report id="conflict2a" test="@id">'id' is not required on conflict of interest statements - please delete.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[@fn-type='conflict']" role="error"><!--Conflict of interest statement should have @specific-use-->
      <assert id="conflict2b" test="@specific-use">Conflict of interest statements should have 'specific-use' attribute taking the value "conflict" or "no-conflict". "no-conflict" should only be used when none of the authors have a conflict.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[@fn-type='conflict'][@specific-use]" role="error"><!--Conflict of interest statement @specific-use has allowed values-->
      <assert id="conflict2c" test="matches(@specific-use,'^(conflict|no-conflict)$')">Conflict of interest statement 'specific-use' attribute should take the value "conflict" or "no-conflict", not <value-of select="@specific-use"/>. "no-conflict" should only be used when none of the authors have a conflict.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[not(@fn-type)]" role="error"><!--author notes should have an id-->
      <assert id="aunote1a" test="@id">Missing 'id' attribute on author note - "fn" should have an 'id' of the form "n"+number (without leading zeros).</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="author-notes/fn[not(@fn-type)][@id]" role="error"><!--author notes id in required format-->
      <assert id="aunote1b" test="matches(@id,'^n[1-9][0-9]*$')">Invalid 'id' value ("<value-of select="@id"/>"). "author-notes/fn" 'id' attribute should be of the form "n"+number (without leading zeros).</assert>
      </rule>
  </pattern>
   <pattern><!--sec - sec-type or specific-use attribute used-->
    <rule context="sec" role="error">
         <assert id="sec1a" test="@sec-type or @specific-use">"sec" should have "sec-type" or "specific-use" attribute.</assert>
      </rule>
  </pattern>
   <pattern><!--sec - sec-type or specific-use attribute used-->
    <rule context="sec" role="error">
         <report id="sec1b" test="@sec-type and @specific-use">"sec" should only use one "sec-type" or "specific-use" attribute, not both.</report>
      </rule>
  </pattern>
   <pattern><!--sec - id and xml:lang attributes not used-->
    <rule context="sec[not(matches($pcode,'^sdata$'))]" role="error">
         <report id="sec1c" test="@id">Do not use "id" attribute on "sec".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="sec" role="error">
         <report id="sec1d" test="@xml:lang">Do not use "xml:lang" attribute on "sec".</report>
      </rule>
  </pattern>
   <pattern><!--sec - sec-type is valid-->
    <rule context="sec[@sec-type]" role="error">
         <let name="secType" value="@sec-type"/>
         <assert id="sec2a" test="$allowed-values/sec-types/sec-type[.=$secType]">Unexpected value for "sec-type" attribute (<value-of select="$secType"/>). Allowed values are: materials, online-methods, procedure. </assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use - follows expected syntax-->
    <rule context="sec[@specific-use]" role="error">
         <assert id="sec2b" test="matches(@specific-use,'^heading-level-[0-9]+$')">The "specific-use" attribute on "sec" (<value-of select="@specific-use"/>) should be used to show the section heading level. It should be "heading-level-" followed by a number.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-1" is a child of body-->
    <rule context="sec[@specific-use='heading-level-1']" role="error">
         <assert id="sec3a" test="parent::body|parent::abstract|parent::app">Section heading level 1 should only be used in body, abstract or app - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-2" is a child of sec heading level 1-->
    <rule context="sec[@specific-use='heading-level-2']" role="error">
         <assert id="sec3b"
                 test="parent::sec[@specific-use='heading-level-1'] or parent::sec[@sec-type='online-methods'][parent::sec/@specific-use='heading-level-1']">Section heading level 2 should be a child of section heading level 1 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-3" is a child of sec heading level 2-->
    <rule context="sec[@specific-use='heading-level-3']" role="error">
         <assert id="sec3c"
                 test="parent::sec[@specific-use='heading-level-2'] or parent::sec[@sec-type='online-methods'][parent::sec/@specific-use='heading-level-2']">Section heading level 3 should be a child of section heading level 2 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-4" is a child of sec heading level 3-->
    <rule context="sec[@specific-use='heading-level-4']" role="error">
         <assert id="sec3d" test="parent::sec/@specific-use='heading-level-3'">Section heading level 4 should be a child of section heading level 3 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-5" is a child of sec heading level 4-->
    <rule context="sec[@specific-use='heading-level-5']" role="error">
         <assert id="sec3e" test="parent::sec/@specific-use='heading-level-4'">Section heading level 5 should be a child of section heading level 4 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-6" is a child of sec heading level 5-->
    <rule context="sec[@specific-use='heading-level-6']" role="error">
         <assert id="sec3f" test="parent::sec/@specific-use='heading-level-5'">Section heading level 6 should be a child of section heading level 5 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-7" is a child of sec heading level 6-->
    <rule context="sec[@specific-use='heading-level-7']" role="error">
         <assert id="sec3g" test="parent::sec/@specific-use='heading-level-6'">Section heading level 7 should be a child of section heading level 6 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec/@specific-use="heading-level-8" is a child of sec heading level 7-->
    <rule context="sec[@specific-use='heading-level-8']" role="error">
         <assert id="sec3h" test="parent::sec/@specific-use='heading-level-7'">Section heading level 8 should be a child of section heading level 7 - check nesting and "specific-use" attribute values.</assert>
      </rule>
  </pattern>
   <pattern><!--sec - sec-type or specific-use attribute used-->
    <rule context="sec/sec-meta | sec/label | sec/address | sec/alternatives | sec/array | sec/boxed-text | sec/chem-struct-wrap | sec/graphic | sec/media |  sec/supplementary-material | sec/table-wrap | sec/table-wrap-group | sec/disp-formula-group | sec/def-list | sec/tex-math | sec/mml:math | sec/related-article | sec/related-object | sec/disp-quote | sec/speech | sec/statement | sec/verse-group | sec/fn-group | sec/glossary | sec/ref-list"
            role="error">
         <report id="sec4" test=".">Children of "sec" should only be "title", "p", "sec", "disp-formula" or "preformat" - do not use "<name/>".</report>
      </rule>
  </pattern>
   <pattern><!--title - no attributes used-->
    <rule context="title">
         <report id="title1a" test="@id">Unnecessary use of "id" attribute on "title" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="title">
         <report id="title1b" test="@content-type">Unnecessary use of "content-type" attribute on "title" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="title">
         <assert id="title1c" test="normalize-space(.) or *">Do not use empty section "title" for formatting purposes.</assert>
      </rule>
  </pattern>
   <pattern><!--List is not block-level, i.e. is a child of p or list-item [unless used for interview/quiz, materials/procedures]-->
    <rule context="list[not(@list-content or @list-type='materials' or @list-type='procedure-group')]"
            role="error">
         <assert id="list2a" test="parent::p or parent::list-item">Regular lists should be enclosed in paragraphs or other lists.</assert>
      </rule>
  </pattern>
   <pattern><!--List - no unnecessary attributes-->
    <rule context="list" role="error">
         <report id="list2b" test="@continued-from">Do not use "continued-from" attribute on "list" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="list" role="error">
         <report id="list2c" test="@prefix-word">Do not use "prefix-word" attribute on "list" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="list" role="error">
         <report id="list2d" test="@specific-use">Do not use "specific-use" attribute on "list" element.</report>
      </rule>
  </pattern>
   <pattern><!--List-item - no id attribute-->
    <rule context="list-item" role="error">
         <report id="list2e" test="@id">Do not use "id" attribute on "list-item" element.</report>
      </rule>
  </pattern>
   <pattern><!--List - list-type attribute stated (apart from interview/quizzes)-->
    <rule context="list[not(@list-content)]" role="error">
         <assert id="list3a" test="@list-type">Use "list-type" attribute to show type of list used. Allowed values are: none, bullet, number, lcletter, ucletter, lcroman and ucroman for unbracketed labels. Use number-paren, lcletter-paren and roman-paren for labels in parentheses.</assert>
      </rule>
  </pattern>
   <pattern><!--list-type attribute is valid--><!--needs work - excludes lists in body when no sec exists; does it work in abstracts?-->
    <rule context="list[not(ancestor::sec/@sec-type) and (ancestor::sec/@specific-use or ancestor::abstract)][@list-type]"
            role="error">
         <let name="listType" value="@list-type"/>
         <assert id="list3b" test="$allowed-values/list-types/list-type[.=$listType]">Unexpected value for "list-type" attribute (<value-of select="$listType"/>). Allowed values are: none, bullet, number, lcletter, ucletter, lcroman and ucroman for unbracketed labels. Use number-paren, lcletter-paren and roman-paren for labels in parentheses.</assert>
      </rule>
  </pattern>
   <pattern><!--List-item - no labels needed-->
    <rule context="list-item" role="error">
         <report id="list4" test="label">Do not use "label" element in "list-item".</report>
      </rule>
  </pattern>
   <pattern><!--Interview is block-level, i.e. not a child of p or list-item-->
    <rule context="list[@list-content='interview']" role="error">
         <assert id="int1a" test="not(parent::p or parent::list-item)">Interviews should be modelled as block-level lists and should not be enclosed in paragraphs or other lists.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview does not have an id-->
    <rule context="list[@list-content='interview']" role="error">
         <assert id="int1b" test="not(@id)">The "id" attribute is not necessary on interviews.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview does not have @list-type-->
    <rule context="list[@list-content='interview']" role="error">
         <assert id="int1c" test="not(@list-type)">The "list-type" attribute is not necessary on interviews.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview has list-items containing one question and one answer-->
    <rule context="list[@list-content='interview']/list-item" role="error">
         <assert id="int2"
                 test="count(list[@list-content='question'])=1 and count(list[@list-content='answer'])=1">Interview list-items should contain one question and one answer.</assert>
      </rule>
  </pattern>
   <pattern><!--Question and answer lists only used in interview or quiz-->
    <rule context="list[@list-content='question']" role="error">
         <assert id="intquiz1"
                 test="ancestor::list/@list-content='interview' or ancestor::list/@list-content='quiz'">Question lists (list-content="question") should only be used in interviews or quizzes.</assert>
      </rule>
  </pattern>
   <pattern><!--Question and answer lists only used in interview or quiz-->
    <rule context="list[@list-content='answer']" role="error">
         <assert id="intquiz2"
                 test="ancestor::list/@list-content='interview' or ancestor::list/@list-content='quiz'">Answer lists (list-content="answer") should only be used in interviews or quizzes.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview is block-level, i.e. not a child of p or list-item-->
    <rule context="list[@list-content='quiz']" role="error">
         <assert id="quiz1a" test="not(parent::p or parent::list-item)">Quizzes should be modelled as block-level lists and should not be enclosed in paragraphs or other lists.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview does not have an id-->
    <rule context="list[@list-content='quiz']" role="error">
         <assert id="quiz1b" test="not(@id)">The "id" attribute is not necessary on quizzes.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview does not have @list-type-->
    <rule context="list[@list-content='quiz']" role="error">
         <assert id="quiz1c" test="not(@list-type)">The "list-type" attribute is not necessary on quizzes.</assert>
      </rule>
  </pattern>
   <pattern><!--Interview has list-items containing one question and one answer-->
    <rule context="list[@list-content='quiz']/list-item" role="error">
         <assert id="quiz2"
                 test="count(list[@list-content='question'])=1 and count(list[@list-content='answer'])=1">Quiz list-items should contain one question and one answer.</assert>
      </rule>
  </pattern>
   <pattern><!--content-type attribute is valid-->
    <rule context="p[not(ancestor::sec/@sec-type)][not(ancestor::ack or ancestor::app or ancestor::app-group or ancestor::boxed-text)][@content-type]"
            role="error">
         <let name="contentType" value="@content-type"/>
         <assert id="para1a" test="$allowed-values/content-types/content-type[.=$contentType]">Unexpected value for "content-type" attribute (<value-of select="$contentType"/>). Allowed values are: cross-head, dateline and greeting. </assert>
      </rule>
  </pattern>
   <pattern><!--p - no unnecessary attributes-->
    <rule context="p" role="error">
         <report id="para1b" test="@id">Do not use "id" attribute on "p" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="p" role="error">
         <report id="para1c" test="@specific-use">Do not use "specific-use" attribute on "p" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="p" role="error">
         <report id="para1d" test="@xml:lang">Do not use "xml:lang" attribute on "p" element.</report>
      </rule>
  </pattern>
   <pattern><!--dateline para in correct place-->
    <rule context="body//p[@content-type='dateline']" role="error">
         <assert id="para2" test="not(preceding-sibling::p)">Dateline paragraphs should only appear as the first element in "body", or directly following a section "title".</assert>
      </rule>
  </pattern>
   <pattern><!--underline should have @underline-style in order to transform correctly to AJ-->
    <rule context="underline" role="error">
         <assert id="style1a" test="@underline-style">"underline" should have an 'underline-style' attribute with value "single" (for one line) or "double" (for two lines).</assert>
      </rule>
  </pattern>
   <pattern><!--@underline-style should have allowed values-->
    <rule context="underline[@underline-style]" role="error">
         <assert id="style1b" test="@underline-style='single' or @underline-style='double'">"underline" 'underline-style' attribute should have value "single" (for one line) or "double" (for two lines), not "<value-of select="@underline-style"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--no empty xrefs for some ref-types-->
    <rule context="xref[matches(@ref-type,'^(bibr|disp-formula|fig|supplementary-material|table-fn)$')]"
            role="error">
         <let name="ref-type" value="@ref-type"/>
         <assert id="xref1" test="normalize-space(.) or *">"xref" with ref-type="<value-of select="$ref-type"/>" and rid="<value-of select="@rid"/>" should contain text. Please see Tagging Instructions for further examples.</assert>
      </rule>
  </pattern>
   <pattern><!--Multiple rid values only allowed in bibrefs-->
    <rule context="xref[not(@ref-type='bibr')]" role="error">
         <let name="ref-type" value="@ref-type"/>
         <report id="xref2" test="contains(@rid,' ')">"xref" with ref-type="<value-of select="$ref-type"/>" should only contain one 'rid' value (<value-of select="."/>). Please split into separate "xref" elements.</report>
      </rule>
  </pattern>
   <pattern><!--compare single bib rid with text as long as text is numeric (i.e. excludes references which have author names)-->
    <rule context="xref[@ref-type='bibr' and not(contains(@rid,' ')) and not(.='') and matches(.,'^[1-9][0-9]?[0-9]?$')]"
            role="error">
         <assert id="xref3a" test="matches(.,replace(@rid,'b',''))">Mismatch in bibref: rid="<value-of select="@rid"/>" but text is "<value-of select="."/>".</assert>
      </rule>
  </pattern>
   <pattern><!--multiple @rids should not be used where citation is author name-->
    <rule context="xref[@ref-type='bibr' and contains(@rid,' ')]" role="error">
         <report id="xref3b" test="matches(.,'[a-z]')">Multiple bibref rid values should only be used in numeric reference lists, not when author names are used. Please split into separate "xref" elements.</report>
      </rule>
  </pattern>
   <pattern><!--xref/@ref-type="bibr", @rid should not be to two values-->
    <rule context="xref[@ref-type='bibr' and contains(@rid,' ') and not(.='') and not(matches(.,'[a-z]'))]"
            role="error">
         <report id="xref3c" test="count(tokenize(@rid, '\W+')[. != '']) eq 2">Bibrefs should be to a single reference or a range of three or more references. See Tagging Instructions for examples.</report>
      </rule>
  </pattern>
   <pattern><!--compare multiple bib rids with text-->
    <rule context="xref[@ref-type='bibr' and count(tokenize(@rid, '\W+')[. != '']) gt 2][contains(.,'–')]"
            role="error"><!--find multiple bibrefs, text must contain a dash (i.e. is a range)-->
      <let name="first" value="xs:integer(substring-before(.,'–'))"/>
         <!--find start of range-->
      <let name="last" value="xs:integer(substring-after(.,'–'))"/>
         <!--find end of range-->
      <let name="range" value="$last - $first + 1"/>
         <!--find number of refs in the range-->
      <let name="derivedRid" value="for $j in $first to $last return concat('b',$j)"/>
         <!--generate expected sequence of rid values-->
      <let name="normalizedRid" value="tokenize(@rid,'\W+')"/>
         <!--turn rid into a sequence for comparison purposes-->
      <assert id="xref3d"
                 test="every $i in 1 to $range satisfies $derivedRid[$i]=$normalizedRid[$i]">xref with ref-type="bibr" range <value-of select="."/> has non-matching multiple rids (<value-of select="@rid"/>). See Tagging Instructions for examples.</assert>
         <!--if any pair does not match, then test will fail-->
    </rule>
  </pattern>
   <pattern><!--multiple rids not allowed for non-ranges-->
    <rule context="xref[@ref-type='bibr'  and (count(tokenize(@rid, '\W+')[. != '']) gt 2) and not(.='') and not(matches(.,'[a-z]'))]"
            role="error">
         <report id="xref3e" test="contains(.,',')">Multiple rid values should only be used for a range of references - please split into separate "xref" elements. See Tagging Instructions for examples.</report>
      </rule>
  </pattern>
   <pattern><!--range not marked up properly-->
    <rule context="xref[@ref-type='bibr'][following::node()[1]='–'][following-sibling::xref[@ref-type='bibr'][1]]"
            role="error">
         <let name="end" value="following-sibling::xref[@ref-type='bibr'][1]/text()"/>
         <report id="xref3f1" test=".">For a range of references, do not put a separate "xref" on the start and end value. One "xref" should cover the range using multiple 'rid' values - one for each reference in the range. "xref" text should be "<value-of select="."/>&amp;#x2013;<value-of select="$end"/>". See the Tagging Instructions for example markup.</report>
      </rule>
  </pattern>
   <pattern><!--range not marked up properly-->
    <rule context="xref[@ref-type='bibr'][following::node()[1]='—'][following-sibling::xref[@ref-type='bibr'][1]]"
            role="error">
         <let name="end" value="following-sibling::xref[@ref-type='bibr'][1]/text()"/>
         <report id="xref3f2" test=".">For a range of references, do not put a separate "xref" on the start and end value. One "xref" should cover the range using multiple 'rid' values - one for each reference in the range. "xref" text should be "<value-of select="."/>&amp;#x2014;<value-of select="$end"/>". See the Tagging Instructions for example markup.</report>
      </rule>
  </pattern>
   <pattern><!--range not marked up properly-->
    <rule context="xref[@ref-type='bibr'][following::node()[1]='-'][following-sibling::xref[@ref-type='bibr'][1]]"
            role="error">
         <let name="end" value="following-sibling::xref[@ref-type='bibr'][1]/text()"/>
         <report id="xref3f3" test=".">For a range of references, do not put a separate "xref" on the start and end value. One "xref" should cover the range using multiple 'rid' values - one for each reference in the range. "xref" text should be "<value-of select="."/>-<value-of select="$end"/>". See the Tagging Instructions for example markup.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/fig[not(@fig-type='cover-image')][@id]" role="error"><!--All figures should be referenced in the text-->
      <let name="id" value="@id"/>
         <assert id="xref4a"
                 test="ancestor::article//xref[@ref-type='fig' and matches(@rid,$id)]">Figure <value-of select="replace($id,'f','')"/> is not linked to in the XML and therefore will not appear in the online article. Please add an xref link in the required location. If the text itself does not reference Figure <value-of select="replace($id,'f','')"/>, please contact NPG.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/table-wrap[@id]" role="error"><!--All tables should be referenced in the text-->
      <let name="id" value="@id"/>
         <assert id="xref4b"
                 test="ancestor::article//xref[@ref-type='table' and matches(@rid,$id)]">Table <value-of select="replace($id,'t','')"/> is not linked to in the XML and therefore will not appear in the online article. Please add an xref link in the required location. If the text itself does not reference Table <value-of select="replace($id,'t','')"/>, please contact NPG.</assert>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/graphic[@content-type='illustration'][@id]" role="error"><!--All tables should be referenced in the text-->
      <let name="id" value="@id"/>
         <assert id="xref4c"
                 test="ancestor::article//xref[@ref-type='other' and matches(@rid,$id)]">Illustration <value-of select="replace($id,'i','')"/> is not linked to in the XML and therefore will not appear in the online article. Please add an xref link in the required location.</assert>
      </rule>
  </pattern>
   <pattern><!--elements which should have two child elements-->
    <rule context="mml:mfrac|mml:mroot|mml:msub|mml:msup|mml:munder|mml:mover"
            role="error">
         <assert id="form1a" test="count(*)=2">The MathML "<value-of select="local-name()"/>" element should have two children, not <value-of select="count(*)"/>.</assert>
      </rule>
  </pattern>
   <pattern><!--elements which should have three child elements-->
    <rule context="mml:munderover|mml:msubsup" role="error">
         <assert id="form1b" test="count(*)=3">The MathML "<value-of select="local-name()"/>" element should have three children not <value-of select="count(*)"/>.</assert>
      </rule>
  </pattern>
   <pattern><!--equation with @id has used mtable to mark up the formula content-->
    <rule context="disp-formula[@id]/mml:math">
         <assert id="form2a" test="count(*)=1 and mml:mtable">Where an equation is numbered in the pdf, the whole expression should be captured using "mml:mtable". The label should captured as the first cell of "mml:mlabeledtr". If the equation is not numbered in the pdf, delete the 'id' attribute.</assert>
      </rule>
  </pattern>
   <pattern><!--do not use @display on mml:math-->
    <rule context="mml:math[@display]">
         <report id="form3" test=".">Do not use 'display' attribute on "mml:math". If the formula is inline, then use "inline-formula" as the parent element, otherwise use "disp-formula".</report>
      </rule>
  </pattern>
   <pattern><!--back - label or title should not be used-->
    <rule context="back/label | back/title" role="error">
         <report id="back1" test=".">Do not use "<name/>" at start of "back" matter.</report>
      </rule>
  </pattern>
   <pattern><!--ack - zero or one-->
    <rule context="ack" role="error">
         <report id="ack1" test="preceding-sibling::ack">There should only be one acknowledgements section.</report>
      </rule>
  </pattern>
   <pattern><!--ack - only p as child-->
    <rule context="ack/*[not(self::p)]" role="error">
         <report id="ack2" test=".">Acknowledgements should only contain paragraphs - do not use "<name/>".</report>
      </rule>
  </pattern>
   <pattern><!--ack - no attributes used-->
    <rule context="ack">
         <report id="ack3a" test="@id">Unnecessary use of "id" attribute on "ack" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="ack">
         <report id="ack3b" test="@content-type">Unnecessary use of "content-type" attribute on "ack" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="ack">
         <report id="ack3c" test="@specific-use">Unnecessary use of "specific-use" attribute on "ack" element.</report>
      </rule>
  </pattern>
   <pattern><!--ack/p - no attributes used-->
    <rule context="ack/p">
         <report id="ack4" test="@content-type">Unnecessary use of "content-type" attribute on "p" element in acknowledgements.</report>
      </rule>
  </pattern>
   <pattern><!--app-group - zero or one-->
    <rule context="app-group" role="error">
         <report id="app1" test="preceding-sibling::app-group">There should only be one appendix grouping.</report>
      </rule>
  </pattern>
   <pattern><!--app-group - no children apart from p and app used-->
    <rule context="app-group/*">
         <assert id="app2" test="self::p or self::app">Only "p" and "app" should be used in "app-group". Do not use "<name/>".</assert>
      </rule>
  </pattern>
   <pattern><!--app-group - no attributes used-->
    <rule context="app-group">
         <report id="app3a" test="@id">Unnecessary use of "id" attribute on "app-group" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="app-group">
         <report id="app3b" test="@content-type">Unnecessary use of "content-type" attribute on "app-group" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="app-group">
         <report id="app3c" test="@specific-use">Unnecessary use of "specific-use" attribute on "app-group" element.</report>
      </rule>
  </pattern>
   <pattern><!--app-group - no attributes on p used-->
    <rule context="app-group/p">
         <report id="app4" test="@content-type">Unnecessary use of "content-type" attribute on "p" in appendix.</report>
      </rule>
  </pattern>
   <pattern><!--app - no attributes used-->
    <rule context="app">
         <report id="app5b" test="@content-type">Unnecessary use of "content-type" attribute on "app" element.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="app">
         <report id="app5c" test="@specific-use">Unnecessary use of "specific-use" attribute on "app" element.</report>
      </rule>
  </pattern>
   <pattern><!--app - no attributes on p used-->
    <rule context="app//p">
         <report id="app6" test="@content-type">Unnecessary use of "content-type" attribute on "p" in appendix.</report>
      </rule>
  </pattern>
   <pattern><!--bio - zero or one-->
    <rule context="back/bio" role="error">
         <report id="bio1" test="preceding-sibling::bio">There should only be one "bio" (author information section) in "back".</report>
      </rule>
  </pattern>
   <pattern><!--bio - only p as child-->
    <rule context="back/bio/*[not(self::p|self::title)]" role="error">
         <report id="bio2" test=".">"bio" (author information section) in "back" should only contain paragraphs or title - do not use "<name/>".</report>
      </rule>
  </pattern>
   <pattern><!--bio - no attributes used-->
    <rule context="back/bio">
         <report id="bio3" test="attribute::*">Do not use attributes on "bio" element.</report>
      </rule>
  </pattern>
   <pattern><!--p in bio - no attributes used-->
    <rule context="back/bio/p">
         <report id="bio4" test="@content-type">Do not use "content-type" attribute on paragraphs in "bio" section.</report>
      </rule>
  </pattern>
   <pattern><!--fn-group - label or title should not be used-->
    <rule context="back/fn-group/label | back/fn-group/title" role="error">
         <report id="back-fn1" test=".">Do not use "<name/>" at start of footnote group in "back" matter.</report>
      </rule>
  </pattern>
   <pattern><!--fn-group - @content-type stated-->
    <rule context="back/fn-group" role="error">
         <assert id="back-fn2a" test="@content-type">Footnote groups in back matter should have 'content-type' attribute stated. Allowed values are "article-notes", "closenotes", "endnotes" or "footnotes".</assert>
      </rule>
  </pattern>
   <pattern><!--fn-group - @content-type allowed-->
    <rule context="back/fn-group[@content-type]" role="error">
         <assert id="back-fn2b"
                 test="@content-type='endnotes' or @content-type='footnotes' or @content-type='closenotes' or @content-type='article-notes'">Allowed values for 'content-type' attribute on "fn-group" are "article-notes", "closenotes", "endnotes" or "footnotes".</assert>
      </rule>
  </pattern>
   <pattern><!--fn-group - no id or specific-use attribute-->
    <rule context="back/fn-group" role="error">
         <report id="back-fn2c" test="@id">Do not use "id" attribute on "fn-group" in back matter.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="back/fn-group" role="error">
         <report id="back-fn2d" test="@specific-use">Do not use "specific-use" attribute on "fn-group" in back matter.</report>
      </rule>
  </pattern>
   <pattern><!--endnotes - fn-type="other"-->
    <rule context="back/fn-group[@content-type='endnotes']/fn" role="error">
         <assert id="back-fn4a" test="@fn-type='other'">"fn" within endnotes should have attribute fn-type="other".</assert>
      </rule>
  </pattern>
   <pattern><!--endnotes - id attribute not necessary-->
    <rule context="back/fn-group[@content-type='endnotes']/fn" role="error">
         <report id="back-fn4b" test="@id">'id' attribute is not necessary on endnotes.</report>
      </rule>
  </pattern>
   <pattern><!--endnotes - symbol attribute not necessary-->
    <rule context="back/fn-group[@content-type='endnotes']/fn" role="error">
         <report id="back-fn4c" test="@symbol">'symbol' attribute is not necessary on endnotes.</report>
      </rule>
  </pattern>
   <pattern><!--footnotes - @id used-->
    <rule context="back/fn-group[@content-type='footnotes']/fn" role="error">
         <assert id="back5a" test="@id">"fn" within footnotes section should have attribute 'id' declared. Expected syntax is "fn" followed by a number.</assert>
      </rule>
  </pattern>
   <pattern><!--footnotes - @id has required syntax-->
    <rule context="back/fn-group[@content-type='footnotes']/fn[@id]" role="error">
         <assert id="back5b" test="matches(@id,'^fn[0-9]+$')">Unexpected 'id' syntax found (<value-of select="@id"/>). Footnote ids should be "fn" followed by a number.</assert>
      </rule>
  </pattern>
   <pattern><!--footnotes - fn-type attribute not necessary-->
    <rule context="back/fn-group[@content-type='footnotes']/fn" role="error">
         <report id="back-fn5c" test="@fn-type">'fn-type' attribute is not necessary on footnotes.</report>
      </rule>
  </pattern>
   <pattern><!--footnotes - symbol attribute not necessary-->
    <rule context="back/fn-group[@content-type='footnotes']/fn" role="error">
         <report id="back-fn5d" test="@symbol">'symbol' attribute is not necessary on footnotes.</report>
      </rule>
  </pattern>
   <pattern><!--notes - zero or one-->
    <rule context="back/notes" role="error">
         <report id="notes1" test="preceding-sibling::notes">There should only be one "notes" (accession group) in "back".</report>
      </rule>
  </pattern>
   <pattern><!--notes - @notes-type="database-links"-->
    <rule context="back/notes" role="error">
         <assert id="notes2a" test="@notes-type='database-links' or @notes-type='note-in-proof'">Unexpected value for "notes" attribute 'notes-type' ("<value-of select="@notes-type"/>"). It should be either "database-links" or "note-in-proof".</assert>
      </rule>
  </pattern>
   <pattern><!--notes - no id or specific-use attribute-->
    <rule context="back/notes" role="error">
         <report id="notes2b" test="@id">Do not use "id" attribute on "notes" in back matter.</report>
      </rule>
  </pattern>
   <pattern><!--notes - no id or specific-use attribute-->
    <rule context="back/notes" role="error">
         <report id="notes2c" test="@specific-use">Do not use "specific-use" attribute on "notes" in back matter.</report>
      </rule>
  </pattern>
   <pattern><!--para in notes - only one ext-link per para-->
    <rule context="back/notes/p">
         <report id="notes3a" test="count(ext-link) gt 1">Take a new paragraph for each "ext-link" in the database link (notes) section.</report>
      </rule>
  </pattern>
   <pattern><!--para in notes - no attributes used-->
    <rule context="back/notes/p">
         <report id="notes3b" test="attribute::*">Do not use attributes on paragraphs in the database link (notes) section.</report>
      </rule>
  </pattern>
   <pattern><!--notes ext-link - @ext-link-type used-->
    <rule context="back/notes/p/ext-link">
         <assert id="notes4a" test="@ext-link-type">External links to databases should have 'ext-link-type' attribute stated. Allowed values are "genbank" or "pdb".</assert>
      </rule>
  </pattern>
   <pattern><!--notes ext-link - @ext-link-type allowed-->
    <rule context="back/notes/p/ext-link[@ext-link-type]" role="error">
         <assert id="notes4b" test="@ext-link-type='genbank' or @ext-link-type='pdb'">Allowed values for 'ext-link-type' attribute on "ext-link" in notes section are "genbank" or "pdb".</assert>
      </rule>
  </pattern>
   <pattern><!--notes ext-link - @ext-link-type allowed-->
    <rule context="back/notes/p/ext-link" role="error">
         <assert id="notes4c" test="@xlink:href">External database links should have attribute 'xlink:href' declared.</assert>
      </rule>
  </pattern>
   <pattern><!--notes ext-link - @ext-link-type allowed-->
    <rule context="back/notes/p/ext-link[@xlink:href]" role="error">
         <assert id="notes4d" test="@xlink:href=.">'xlink:href' should be equal to the link text (<value-of select="."/>).</assert>
      </rule>
  </pattern>
   <pattern><!--elements not allowed as children of mixed-citation-->
    <rule context="ref/mixed-citation/alternatives|ref/mixed-citation/chem-struct|ref/mixed-citation/conf-date|ref/mixed-citation/conf-loc|ref/mixed-citation/conf-name|ref/mixed-citation/conf-sponsor|ref/mixed-citation/date|ref/mixed-citation/date-in-citation|ref/mixed-citation/inline-graphic|ref/mixed-citation/institution|ref/mixed-citation/label|ref/mixed-citation/name|ref/mixed-citation/name-alternatives|ref/mixed-citation/private-char|ref/mixed-citation/role|ref/mixed-citation/series|ref/mixed-citation/size|ref/mixed-citation/supplement"
            role="error">
         <report id="disallowed2" test=".">Do not use "<name/>" element in "mixed-citation" in NPG/Palgrave articles.</report>
      </rule>
  </pattern>
   <pattern><!--elements not allowed as children of ref-list-->
    <rule context="ref-list/label|ref-list/address|ref-list/alternatives|ref-list/array|ref-list/boxed-text|ref-list/chem-struct-wrap|ref-list/fig|ref-list/fig-group|ref-list/graphic|ref-list/media|ref-list/preformat|ref-list/supplementary-material|ref-list/table-wrap|ref-list/table-wrap-group|ref-list/disp-formula|ref-list/disp-formula-group|ref-list/def-list|ref-list/list|ref-list/tex-math|ref-list/mml:math|ref-list/related-article|ref-list/related-object|ref-list/disp-quote|ref-list/speech|ref-list/statement|ref-list/verse-group"
            role="error">
         <report id="disallowed3" test=".">Do not use "<name/>" element in "ref-list" in NPG/Palgrave articles.</report>
      </rule>
  </pattern>
   <pattern><!--no brackets in year-->
    <rule context="ref/mixed-citation/year" role="error">
         <report id="punct1a" test="starts-with(.,'(') or ends-with(.,')')">Do not include parentheses in the "year" element in citations in NPG/Palgrave articles.</report>
      </rule>
  </pattern>
   <pattern><!--no brackets in publisher-name-->
    <rule context="ref/mixed-citation/publisher-name" role="error">
         <report id="punct1b" test="starts-with(.,'(') or ends-with(.,')')">Do not include parentheses in the "publisher-name" element in citations in NPG/Palgrave articles.</report>
      </rule>
  </pattern>
   <pattern><!--elocation-id should have @content-type in citations-->
    <rule context="ref/mixed-citation/elocation-id" role="error">
         <assert id="eloc1a" test="@content-type">"elocation-id" should have a 'content-type' attribute when used in citations. Allowed values are "doi" and "article-number". If the reference is to an ISBN or ISSN, then use "isbn" or "issn" elements instead.</assert>
      </rule>
  </pattern>
   <pattern><!--elocation-id should only be used for doi and article number, not issn or isbn-->
    <rule context="ref/mixed-citation/elocation-id[@content-type]" role="error">
         <assert id="eloc1b" test="@content-type='doi' or @content-type='article-number'">"elocation-id" 'content-type' attribute in citations only has allowed values of "doi" or "article-number". If the reference is to an ISBN or ISSN, then use "isbn" or "issn" elements instead on the number only (the text 'ISBN' or 'ISSN' should remain outside the element).</assert>
      </rule>
  </pattern>
   <pattern><!--elocation-id should not contain text 'doi'-->
    <rule context="ref/mixed-citation/elocation-id[@content-type='doi']" role="error">
         <report id="eloc1c" test="starts-with(.,'doi')">"elocation-id" should contain the DOI value only - move the text 'doi' and any punctuation to be outside the "doi" element.</report>
      </rule>
  </pattern>
   <pattern><!--isbn should not contain text 'ISBN'-->
    <rule context="ref/mixed-citation/isbn" role="error">
         <report id="isbn1" test="starts-with(.,'ISBN')">"isbn" should contain the ISBN value only - move the text 'ISBN' and any punctuation to be outside the "isbn" element.</report>
      </rule>
  </pattern>
   <pattern><!--Reference lists should have specific-use attribute to give style info-->
  <rule context="back/ref-list[not(@content-type='link-group')]" role="error">
         <assert id="reflist1a" test="@specific-use">Ref-list should have a 'specific-use' attribute with value "alpha" (for alphabetical references) or "numero" (for numbered references).</assert>
      </rule>
  </pattern>
   <pattern><!--ref-list specific-use attribute should be 'alpha' or 'numero'-->
    <rule context="back/ref-list[not(@content-type='link-group')][@specific-use]"
            role="error">
         <assert id="reflist1b" test="@specific-use='alpha' or @specific-use='numero'">Ref-list 'specific-use' attribute should have value "alpha" (for alphabetical references) or "numero" (for numbered references), not "<value-of select="@specific-use"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--ref-list - do not use 'id' attribute-->
    <rule context="ref-list" role="error">
         <report id="reflist1c" test="@id">Do not use 'id' attribute on "ref-list".</report>
      </rule>
  </pattern>
   <pattern><!--ref-list - do not use 'content-type' attribute (except for link groups)-->
    <rule context="ref-list[@content-type]" role="error">
         <assert id="reflist1d"
                 test="@content-type='link-group' or @content-type='data-citations'">Do not use 'content-type' attribute on "ref-list", except for link groups or data citations.</assert>
      </rule>
  </pattern>
   <pattern><!--ref-list does not need title "References"-->
    <rule context="back/ref-list[not(@content-type='link-group')]/title" role="error">
         <report id="reflist2a" test=".='references' or .='References' or .='REFERENCES'">A "title" element with text 'References' is not necessary at the start of the References section - please delete.</report>
      </rule>
  </pattern>
   <pattern><!--citations in ref-list do not need labels, values can be generated from id-->
    <rule context="back/ref-list[not(@content-type='link-group')]//ref/label"
            role="error">
         <report id="reflist3a" test=".">Delete unnecessary "label" element in reference.</report>
      </rule>
  </pattern>
   <pattern><!--ref - must have an @id-->
    <rule context="back/ref-list[not(@content-type)]/ref" role="error">
         <assert id="reflist4a" test="@id">Missing 'id' attribute - "ref" should have an 'id' of the form "b"+number (with no leading zeros).</assert>
      </rule>
  </pattern>
   <pattern><!--ref - @id must be correct format-->
    <rule context="back/ref-list[not(@content-type)]/ref[@id]" role="error">
         <assert id="reflist4b" test="matches(@id,'^b[1-9][0-9]*$')">Invalid 'id' value ("<value-of select="@id"/>"). "ref" 'id' attribute should be of the form "b"+number (with no leading zeros).</assert>
      </rule>
  </pattern>
   <pattern><!--data citation - must have an @id-->
    <rule context="back/ref-list[@content-type='data-citations']/ref" role="error">
         <assert id="reflist4c" test="@id">Missing 'id' attribute - "ref" should have an 'id' of the form "d"+number (with no leading zeros).</assert>
      </rule>
  </pattern>
   <pattern><!--data citation - @id must be correct format-->
    <rule context="back/ref-list[@content-type='data-citations']/ref[@id]" role="error">
         <assert id="reflist4d" test="matches(@id,'^d[1-9][0-9]*$')">Invalid 'id' value ("<value-of select="@id"/>"). "ref" 'id' attribute should be of the form "d"+number (with no leading zeros).</assert>
      </rule>
  </pattern>
   <pattern><!--surname and given-names should be separated by whitespace, otherwise do not get rendered properly-->
    <rule context="back/ref-list[not(@content-type)]//ref/mixed-citation/string-name/surname"
            role="error">
         <report id="reflist5a" test="following::node()[1]/self::given-names">Insert a space between "surname" and "given-names" in references.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="etal" role="error"><!--etal not followed by full stop-->
      <report id="reflist5b" test="starts-with(following::node()[1],'.')">"etal" should not be followed by a full stop - in NPG/Palgrave articles, it is the equivalent of 'et al.' in italics.</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="etal" role="error"><!--etal should be empty-->
      <report id="reflist5c" test="normalize-space(.) or *">"etal" should be an empty element in NPG/Palgrave articles - please delete content.</report>
      </rule>
  </pattern>
   <pattern><!--collab should have @collab-type-->
    <rule context="back/ref-list[not(@content-type)]//ref/mixed-citation/collab"
            role="error">
         <assert id="reflist5d" test="@collab-type">"collab" should have a 'collab-type' attribute with value "corporate-author" (for a committee, consortium or other collaborative group) or "on-behalf-of" (where this text is used in the reference).</assert>
      </rule>
  </pattern>
   <pattern><!--@collab-type should have allowed values-->
    <rule context="back/ref-list[not(@content-type)]//ref/mixed-citation/collab[@collab-type]"
            role="error">
         <assert id="reflist5e"
                 test="@collab-type='corporate-author' or @collab-type='on-behalf-of'">"collab" 'collab-type' attribute should have value "corporate-author" (for a committee, consortium or other collaborative group) or "on-behalf-of" (where this text is used in the reference), not "<value-of select="@collab-type"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--book citations should not have "article-title"-->
    <rule context="back/ref-list[not(@content-type)]//ref/mixed-citation[@publication-type='book']/article-title"
            role="error">
         <report id="reflist6a" test=".">"article-title" should not be used in book citations. Use "chapter-title" instead.</report>
      </rule>
  </pattern>
   <pattern><!--second set of authors in book citation should be contained in person-group-->
    <rule context="back//mixed-citation[@publication-type='book']/chapter-title"
            role="error">
         <report id="reflist7a" test="following-sibling::string-name">The second set of author/editor names in a book citation should be enclosed in "person-group" with a 'person-group-type' attribute to identify authors/editors etc.</report>
      </rule>
  </pattern>
   <pattern><!--person-group should have @person-group-type-->
    <rule context="back//mixed-citation[@publication-type='book']/person-group"
            role="error">
         <assert id="reflist7b" test="@person-group-type">"person-group" should have a 'person-group-type' attribute to identify authors/editors etc.</assert>
      </rule>
  </pattern>
   <pattern><!--person-group should not have @id-->
    <rule context="back//mixed-citation[@publication-type='book']/person-group"
            role="error">
         <report id="reflist7c" test="@id">Do not use 'id' attribute on "person-group".</report>
      </rule>
  </pattern>
   <pattern><!--person-group should not have @specific-use-->
    <rule context="back//mixed-citation[@publication-type='book']/person-group"
            role="error">
         <report id="reflist7d" test="@specific-use">Do not use 'specific-use' attribute on "person-group".</report>
      </rule>
  </pattern>
   <pattern><!--person-group should not have @xml:lang-->
    <rule context="back//mixed-citation[@publication-type='book']/person-group"
            role="error">
         <report id="reflist7e" test="@xml:lang">Do not use 'xml:lang' attribute on "person-group".</report>
      </rule>
  </pattern>
   <pattern><!--person-group should only be used in book citations for the second group of authors-->
    <rule context="person-group" role="error">
         <assert id="reflist7f"
                 test="parent::mixed-citation[@publication-type='book'] and preceding-sibling::chapter-title">"person-group" should only be used to capture the second group of editors/authors in a book citation. Do not use it here.</assert>
      </rule>
  </pattern>
   <pattern><!--caption must contain a title-->
        <rule context="table-wrap/caption" role="error">
            <report id="tab5a" test="not(child::title) and child::p" role="error">Table-wrap "caption" should contain a "title" element - change "p" to "title".</report>
        </rule>
    </pattern>
   <pattern><!--caption should not be empty (strip out unicode spaces as well - &#x2003; &#x2009;)-->
        <rule context="table-wrap/caption" role="error">
            <let name="text" value="replace(.,'( )|( )','')"/>
            <assert id="tab5b" test="normalize-space($text) or *" role="error">Table-wrap "caption" should not be empty - it should contain a "title" or not be used at all.</assert>
        </rule>
    </pattern>
   <pattern><!--caption children should not be empty (strip out unicode spaces as well - &#x2003; &#x2009;)-->
        <rule context="table-wrap/caption/p | table-wrap/caption/title" role="error">
            <let name="text" value="replace(.,'( )|( )','')"/>
            <assert id="tab5c" test="normalize-space($text) or *" role="error">Do not use empty "<name/>" element in table-wrap "caption".</assert>
        </rule>
    </pattern>
   <pattern><!--caption should not have attributes-->
        <rule context="table-wrap/caption" role="error">
            <report id="tab5d" test="attribute::*" role="error">Do not use attributes on table-wrap "caption".</report>
        </rule>
    </pattern>
   <pattern><!--caption title or p should not have attributes-->
        <rule context="table-wrap/caption/title|table-wrap/caption/p" role="error">
            <report id="tab5e" test="attribute::*" role="error">Do not use attributes on "<name/>" within table-wrap "caption".</report>
        </rule>
    </pattern>
   <pattern>
      <rule context="table-wrap-foot/fn" role="error">
        <let name="id" value="@id"/>
        <assert id="tab10a" test="ancestor::article//xref[@ref-type='table-fn'][@rid=$id]">Table footnote is not linked to. Either insert a correctly numbered link, or just mark up as a table footer paragraph.</assert>
      </rule>
   </pattern>
   <pattern>
        <rule context="table-wrap-foot/fn" role="error">
            <let name="id" value="@id"/>
            <assert id="tab10b"
                 test="not(ancestor::article//xref[@ref-type='table-fn'][@rid=$id]) or label">Table footnote should contain "label" element - check if it is a footnote or should just be a table footer paragraph.</assert>
        </rule>
    </pattern>
   <pattern>
        <rule context="xref[@ref-type='table-fn']" role="error"><!--Does symbol in link match symbol on footnote?-->
            <let name="id" value="@rid"/>
            <let name="sup-link" value="descendant::text()"/>
            <let name="sup-fn"
              value="ancestor::article//table-wrap-foot/fn[@id=$id]/label//text()"/>
            <assert id="tab10c" test="not($sup-fn) or not($sup-link) or $sup-link=$sup-fn">Mismatch on linking text: "<value-of select="$sup-link"/>" in table, but "<value-of select="$sup-fn"/>" in footnote. Please check that correct footnote has been linked to.</assert>
        </rule>
    </pattern>
   <pattern>
      <rule context="oasis:entry[@namest and @nameend]">
        <assert id="tab11a" test="@align">Spanning table entries should also have an 'align' attribute.</assert>
      </rule>
   </pattern>
   <pattern>
        <rule context="oasis:entry[@nameend]">
            <assert id="tab11b" test="@namest">Table entry has 'nameend' attribute (<value-of select="@nameend"/>), but there is no 'namest' attribute. Spanning entries should have both these attributes; non-spanning entries should have neither.</assert>
        </rule>
    </pattern>
   <pattern>
        <rule context="oasis:entry[@namest]">
            <assert id="tab11c" test="@nameend">Table entry has 'namest' attribute (<value-of select="@namest"/>), but there is no 'nameend' attribute. Spanning entries should have both these attributes; non-spanning entries should have neither.</assert>
        </rule>
    </pattern>
   <pattern>
      <rule context="fig//graphic" role="error">
        <report id="fig1a" test="@xlink:href='' or @mimetype='' or @mime-subtype=''">Graphic attribute values 'xlink:href', 'mimetype' and 'mime-subtype' should be used and not be empty - please check that entity declarations have been converted correctly before transformation.</report>
      </rule>
   </pattern>
   <pattern>
        <rule context="fig-group" role="error">
            <report id="fig1b" test=".">Do not use "fig-group" in NPG/Palgrave articles. Figures should be captured as direct children of "floats-group".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig" role="error">
            <assert id="fig1c" test="parent::floats-group or parent::fig-group">"fig" should be only be a child of "floats-group" in NPG/Palgrave articles - not "<value-of select="local-name(parent::*)"/>".</assert>
        </rule>
    </pattern>
   <pattern><!--fig - allowed children only: add other possibilities!!!!!!!!!!!!!!-->
        <rule context="fig/alt-text | fig/long-desc | fig/email | fig/ext-link | fig/uri | fig/disp-formula | fig/disp-formula-group | fig/chem-struct-wrap | fig/disp-quote | fig/speech | fig/statement | fig/verse-group | fig/table-wrap | fig/p | fig/def-list | fig/list | fig/array | fig/media | fig/preformat | fig/permissions"
            role="error">
            <report id="fig2a" test=".">Do not use "<name/>" as a child of "fig". Refer to Tagging Instructions for sample markup.</report>
        </rule>
    </pattern>
   <pattern><!--fig - caption must not be empty-->
        <rule context="fig/caption" role="error">
            <assert id="fig2b" test="normalize-space(.) or *">Figure "caption" should not be empty.</assert>
        </rule>
    </pattern>
   <pattern><!--fig - caption must not have attributes-->
        <rule context="fig/caption" role="error">
            <report id="fig2c" test="@content-type or @id or @specific-use or @style or @xml:lang">Do not use attributes on figure "caption".</report>
        </rule>
    </pattern>
   <pattern><!--fig - label must not have attributes-->
        <rule context="fig/label" role="error">
            <report id="fig2d" test="@alt or @xml:lang">Do not use attributes on figure "label".</report>
        </rule>
    </pattern>
   <pattern><!--fig - label not necessary if text is of form "Figure 1" etc-->
        <rule context="fig[matches(@id,'^f[A-Z]?[1-9][0-9]*$')]/label" role="error">
            <let name="derivedLabel" value="concat('Figure ',translate(parent::fig/@id,'f',''))"/>
            <report id="fig2e" test=".=$derivedLabel">Figure "label" is not necessary when text is of the standard format "<value-of select="$derivedLabel"/>" - please delete.</report>
        </rule>
    </pattern>
   <pattern><!--fig - must have an @id-->
        <rule context="fig[not(@fig-type='cover-image')]" role="error">
            <assert id="fig3a" test="@id">Missing 'id' attribute - "fig" should have an 'id' of the form "f"+number (with no leading zeros).</assert>
        </rule>
    </pattern>
   <pattern><!--fig - @id must be correct format-->
        <rule context="fig[@id]" role="error">
            <assert id="fig3b" test="matches(@id,'^f[A-Z]?[1-9][0-9]*$')">Invalid 'id' value ("<value-of select="@id"/>"). "fig" 'id' attribute should be of the form "f"+number (with no leading zeros).</assert>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig" role="error">
            <report id="fig3c" test="@specific-use" role="error">Do not use "specific-use" attribute on "fig".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig" role="error">
            <report id="fig3d" test="@xml:lang" role="error">Do not use "xml:lang" attribute on "fig".</report>
        </rule>
    </pattern>
   <pattern><!--fig - must have an @xlink:href-->
        <rule context="fig//graphic" role="error">
            <assert id="fig4a" test="@xlink:href">Missing 'xlink:href' attribute on figure "graphic". The 'xlink:href' should contain the filename (including extension) of the item of graphic. Do not include any path information.</assert>
        </rule>
    </pattern>
   <pattern><!--@xlink:href does not contain filepath info-->
        <rule context="fig//graphic[@xlink:href]" role="error">
            <report id="fig4b" test="contains(@xlink:href,'/')">Do not include filepath information for figure graphic files "<value-of select="@xlink:href"/>".</report>
        </rule>
    </pattern>
   <pattern><!--@xlink:href contains a '.' and therefore may have an extension-->
        <rule context="fig//graphic[@xlink:href]" role="error">
            <assert id="fig4c" test="contains(@xlink:href,'.')">Figure graphic 'xlink:href' value ("<value-of select="@xlink:href"/>") should contain the file extension (e.g. jpg, gif, etc).</assert>
        </rule>
    </pattern>
   <pattern><!--@xlink:href has valid file extension - check allowed image extensions-->
        <rule context="fig//graphic[@xlink:href]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <assert id="fig4d"
                 test="matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')">Unexpected file extension value ("<value-of select="$extension"/>") in figure "graphic" '@xlink:href' attribute - please check.</assert>
        </rule>
    </pattern>
   <pattern><!--fig graphic - must have a @mimetype; when @xlink:href does not exist, point to Tagging instructions-->
        <rule context="fig//graphic[not(@xlink:href or contains(@xlink:href,'.'))]"
            role="error">
            <assert id="fig5a" test="@mimetype">Missing 'mimetype' attribute on figure "graphic". Refer to Tagging Instructions for correct value.</assert>
        </rule>
    </pattern>
   <pattern><!--fig graphic - must have a @mimetype; when @xlink:href is invalid, point to Tagging instructions-->
        <rule context="fig//graphic[contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <report id="fig5b"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) and not(@mimetype)">Missing 'mimetype' attribute on figure "graphic". Refer to Tagging Instructions for correct value.</report>
        </rule>
    </pattern>
   <pattern><!--fig graphic - must have a @mimetype; when @xlink:href exists (and is valid) gives value that should be used-->
        <rule context="fig//graphic[contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <let name="mimetype"
              value="if (matches($extension,'^(doc|docx|eps|exe|noa|pdf|pps|ppt|pptx|ps|rtf|swf|tar|tgz|wmf|xls|xlsx|xml|zip)$')) then 'application'                 else if (matches($extension,'^(mp2|mp3|ra|wav)$')) then 'audio'                 else if (matches($extension,'^(cif|pdb|sdf)$')) then 'chemical'                 else if (matches($extension,'^(bmp|gif|jpeg|jpg|pict|png|tiff)$')) then 'image'                 else if (matches($extension,'^(c|csv|htm|html|sif|txt)$')) then 'text'                 else if (matches($extension,'^(avi|mov|mp4|mpg|qt|rv|wmv)$')) then 'video'                 else ()"/>
            <assert id="fig5c"
                 test="@mimetype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">Missing 'mimetype' attribute on figure "graphic". For files with extension "<value-of select="$extension"/>", this should have the value "<value-of select="$mimetype"/>".</assert>
        </rule>
    </pattern>
   <pattern><!--value used for @mimetype is correct based on file extension (includes test for valid extension)-->
        <rule context="fig//graphic[@mimetype][contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <let name="mimetype"
              value="if (matches($extension,'^(doc|docx|eps|exe|noa|pdf|pps|ppt|pptx|ps|rtf|swf|tar|tgz|wmf|xls|xlsx|xml|zip)$')) then 'application'                 else if (matches($extension,'^(mp2|mp3|ra|wav)$')) then 'audio'                 else if (matches($extension,'^(cif|pdb|sdf)$')) then 'chemical'                 else if (matches($extension,'^(bmp|gif|jpeg|jpg|pict|png|tiff)$')) then 'image'                 else if (matches($extension,'^(c|csv|htm|html|sif|txt)$')) then 'text'                 else if (matches($extension,'^(avi|mov|mp4|mpg|qt|rv|wmv)$')) then 'video'                 else ()"/>
            <assert id="fig5d"
                 test="@mimetype=$mimetype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">For figure graphics with extension "<value-of select="$extension"/>", the mimetype attribute should have the value "<value-of select="$mimetype"/>" (not "<value-of select="@mimetype"/>").</assert>
        </rule>
    </pattern>
   <pattern><!--fig graphic - must have a @mime-subtype; when @xlink:href does not exist or is invalid, point to Tagging instructions-->
        <rule context="fig//graphic[not(@xlink:href or contains(@xlink:href,'.'))]"
            role="error">
            <assert id="fig6a" test="@mime-subtype">Missing 'mime-subtype' attribute on figure "graphic". Refer to Tagging Instructions for correct value.</assert>
        </rule>
    </pattern>
   <pattern><!--fig graphic - must have a @mime-subtype; when @xlink:href exists (and is invalid) points to Tagging instructions-->
        <rule context="fig//graphic[contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <report id="fig6b"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) and not(@mime-subtype)">Missing 'mime-subtype' attribute on figure "graphic". Refer to Tagging Instructions for correct value based.</report>
        </rule>
    </pattern>
   <pattern><!--fig - must have a @mime-subtype; when @xlink:href exists (and is valid) gives value that should be used-->
        <rule context="fig//graphic[contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <let name="mime-subtype"
              value="if ($extension='tgz') then 'application/gzip'                 else if ($extension='bmp') then 'bmp'                 else if ($extension='csv') then 'csv'                 else if ($extension='gif') then 'gif'                 else if ($extension='htm' or $extension='html') then 'html'                 else if ($extension='jpeg' or $extension='jpg') then 'jpeg'                 else if ($extension='mp4' or $extension='mp2' or $extension='mp3' or $extension='mpg') then 'mpeg'                 else if ($extension='doc' or $extension='dot') then 'msword'                 else if ($extension='exe' or $extension='noa' or $extension='ole' or $extension='wp') then 'octet-stream'                 else if ($extension='pdf') then 'pdf'                 else if ($extension='c' or $extension='sif' or $extension='txt') then 'plain'                 else if ($extension='png') then 'png'                 else if ($extension='eps' or $extension='ps') then 'postscript'                 else if ($extension='mov' or $extension='qt') then 'quicktime'                 else if ($extension='rtf') then 'rtf'                 else if ($extension='sbml') then 'sbml+xml'                 else if ($extension='tiff') then 'tiff'                 else if ($extension='xls') then 'vnd.ms-excel'                 else if ($extension='xlsm') then 'vnd.ms-excel.sheet.macroEnabled.12'                 else if ($extension='pps' or $extension='ppt') then 'vnd.ms-powerpoint'                 else if ($extension='pptm') then 'vnd.ms-powerpoint.presentation.macroEnabled.12'                 else if ($extension='docm') then 'vnd.ms-word.document.macroEnabled.12'                 else if ($extension='pptx') then 'vnd.openxmlformats-officedocument.presentationml.presentation'                 else if ($extension='xlsx') then 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'                 else if ($extension='docx') then 'vnd.openxmlformats-officedocument.wordprocessingml.document'                 else if ($extension='ra') then 'vnd.rn-realaudio'                 else if ($extension='rv') then 'vnd.rn-realvideo'                 else if ($extension='cdx') then 'x-cdx'                 else if ($extension='cif') then 'x-cif'                 else if ($extension='jdx') then 'x-jcamp-dx'                 else if ($extension='tex') then 'x-latex'                 else if ($extension='mol') then 'x-mdl-molfile'                 else if ($extension='sdf') then 'x-mdl-sdfile'                 else if ($extension='xml') then 'xml'                 else if ($extension='wmf') then 'x-msmetafile'                 else if ($extension='avi') then 'x-msvideo'                 else if ($extension='wmv') then 'x-ms-wmv'                 else if ($extension='pdb') then 'x-pdb'                 else if ($extension='pict') then 'x-pict'                 else if ($extension='swf') then 'x-shockwave-flash'                 else if ($extension='tar') then 'x-tar'                 else if ($extension='wav') then 'x-wav'                 else if ($extension='zip') then 'x-zip-compressed'                 else ()"/>
            <assert id="fig6c"
                 test="@mime-subtype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">Missing 'mime-subtype' attribute on figure "graphic". For files with extension "<value-of select="$extension"/>", this should have the value "<value-of select="$mime-subtype"/>".</assert>
        </rule>
    </pattern>
   <pattern><!--value used for @mimetype is correct based on file extension (includes test for valid extension)-->
        <rule context="fig//graphic[@mime-subtype][contains(@xlink:href,'.')]" role="error">
            <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
            <let name="mime-subtype"
              value="if ($extension='tgz') then 'application/gzip'                 else if ($extension='bmp') then 'bmp'                 else if ($extension='csv') then 'csv'                 else if ($extension='gif') then 'gif'                 else if ($extension='htm' or $extension='html') then 'html'                 else if ($extension='jpeg' or $extension='jpg') then 'jpeg'                 else if ($extension='mp4' or $extension='mp2' or $extension='mp3' or $extension='mpg') then 'mpeg'                 else if ($extension='doc' or $extension='dot') then 'msword'                 else if ($extension='exe' or $extension='noa' or $extension='ole' or $extension='wp') then 'octet-stream'                 else if ($extension='pdf') then 'pdf'                 else if ($extension='c' or $extension='sif' or $extension='txt') then 'plain'                 else if ($extension='png') then 'png'                 else if ($extension='eps' or $extension='ps') then 'postscript'                 else if ($extension='mov' or $extension='qt') then 'quicktime'                 else if ($extension='rtf') then 'rtf'                 else if ($extension='sbml') then 'sbml+xml'                 else if ($extension='tiff') then 'tiff'                 else if ($extension='xls') then 'vnd.ms-excel'                 else if ($extension='xlsm') then 'vnd.ms-excel.sheet.macroEnabled.12'                 else if ($extension='pps' or $extension='ppt') then 'vnd.ms-powerpoint'                 else if ($extension='pptm') then 'vnd.ms-powerpoint.presentation.macroEnabled.12'                 else if ($extension='docm') then 'vnd.ms-word.document.macroEnabled.12'                 else if ($extension='pptx') then 'vnd.openxmlformats-officedocument.presentationml.presentation'                 else if ($extension='xlsx') then 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'                 else if ($extension='docx') then 'vnd.openxmlformats-officedocument.wordprocessingml.document'                 else if ($extension='ra') then 'vnd.rn-realaudio'                 else if ($extension='rv') then 'vnd.rn-realvideo'                 else if ($extension='cdx') then 'x-cdx'                 else if ($extension='cif') then 'x-cif'                 else if ($extension='jdx') then 'x-jcamp-dx'                 else if ($extension='tex') then 'x-latex'                 else if ($extension='mol') then 'x-mdl-molfile'                 else if ($extension='sdf') then 'x-mdl-sdfile'                 else if ($extension='xml') then 'xml'                 else if ($extension='wmf') then 'x-msmetafile'                 else if ($extension='avi') then 'x-msvideo'                 else if ($extension='wmv') then 'x-ms-wmv'                 else if ($extension='pdb') then 'x-pdb'                 else if ($extension='pict') then 'x-pict'                 else if ($extension='swf') then 'x-shockwave-flash'                 else if ($extension='tar') then 'x-tar'                 else if ($extension='wav') then 'x-wav'                 else if ($extension='zip') then 'x-zip-compressed'                 else ()"/>
            <assert id="fig6d"
                 test="@mime-subtype=$mime-subtype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">For figure graphics with extension "<value-of select="$extension"/>", the 'mime-subtype' attribute should have the value "<value-of select="$mime-subtype"/>" (not "<value-of select="@mime-subtype"/>").</assert>
        </rule>
    </pattern>
   <pattern><!--no other attributes used on supplementary-material - check what's allowed for fig graphics!!!!!!!!!!!!!!!!!!!-->
        <rule context="fig//graphic" role="error">
            <report id="fig7a" test="@specific-use" role="error">Do not use "specific-use" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic" role="error">
            <report id="fig7b" test="@xlink:actuate" role="error">Do not use "xlink:actuate" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic[not(@content-type='external-media')]" role="error">
            <report id="fig7c" test="@xlink:role" role="error">Do not use "xlink:role" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic" role="error">
            <report id="fig7d" test="@xlink:show" role="error">Do not use "xlink:show" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic" role="error">
            <report id="fig7e" test="@xlink:title" role="error">Do not use "xlink:title" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic" role="error">
            <report id="fig7f" test="@xlink:type" role="error">Do not use "xlink:type" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern>
        <rule context="fig//graphic" role="error">
            <report id="fig7g" test="@xml:lang" role="error">Do not use "xml:lang" attribute on figure "graphic".</report>
        </rule>
    </pattern>
   <pattern><!--supplementary-material - only caption allowed as a child-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')]"
            role="error">
         <report id="supp1a" test="*[not(self::caption)]">Only "caption" should be used as a child of "supplementary-material" - do not use "<value-of select="local-name(*)"/>".</report>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - caption must contain title-->
    <rule context="floats-group/supplementary-material/caption" role="error">
         <assert id="supp1b" test="title">Supplementary-material "caption" must contain "title".</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have an @id-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')]"
            role="error">
         <assert id="supp2a" test="@id">Missing 'id' attribute - "supplementary-material" should have an 'id' of the form "s"+number.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - @id must be correct format-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][@id]"
            role="error">
         <assert id="supp2b" test="matches(@id,'^s[0-9]+$')">Invalid 'id' value ("<value-of select="@id"/>"). "supplementary-material" 'id' attribute should be of the form "s"+number.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have an @content-type-->
    <rule context="floats-group/supplementary-material[not(@xlink:href or contains(@xlink:href,'.'))]"
            role="error">
         <assert id="supp3a" test="@content-type">Missing 'content-type' attribute on "supplementary-material". Refer to Tagging Instructions for correct value.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @content-type; when @xlink:href is invalid, point to Tagging instructions-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <report id="supp3b"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) and not(@content-type)">Missing 'content-type' attribute on "supplementary-material". Refer to Tagging Instructions for correct value.</report>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @content-type; when @xlink:href exists (and is valid) gives value that should be used-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="content-type"
              value="if (matches($extension,'^(doc|docx|pdf|pps|ppt|pptx|xls|xlsx)$')) then 'document'         else if (matches($extension,'^(eps|gif|jpg|bmp|png|pict|ps|tiff|wmf)$')) then 'image'         else if (matches($extension,'^(tar|tgz|zip)$')) then 'archive'         else if (matches($extension,'^(c|csv|htm|html|rtf|txt|xml)$')) then 'text'         else if (matches($extension,'^(aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv)$')) then 'movie'         else if (matches($extension,'^(cif|exe|pdb|sdf|sif)$')) then 'other'         else ()"/>
         <assert id="supp3c"
                 test="@content-type or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">Missing 'content-type' attribute on "supplementary-material". For files with extension "<value-of select="$extension"/>", this should have the value "<value-of select="$content-type"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--value used for @content-type is correct based on file extension (includes test for valid extension)-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media' or @content-type='isa-tab')][@content-type][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="content-type"
              value="if (matches($extension,'^(doc|docx|pdf|pps|ppt|pptx|xls|xlsx)$')) then 'document'         else if (matches($extension,'^(eps|gif|jpg|bmp|png|pict|ps|tiff|wmf)$')) then 'image'         else if (matches($extension,'^(tar|tgz|zip)$')) then 'archive'         else if (matches($extension,'^(c|csv|htm|html|rtf|txt|xml)$')) then 'text'         else if (matches($extension,'^(aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv)$')) then 'movie'         else if (matches($extension,'^(cif|exe|pdb|sdf|sif)$')) then 'other'         else ()"/>
         <assert id="supp3d"
                 test="@content-type=$content-type or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">For supplementary material files with extension "<value-of select="$extension"/>", the content-type attribute should have the value "<value-of select="$content-type"/>" (not "<value-of select="@content-type"/>").</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have an @xlink:href-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')]"
            role="error">
         <assert id="supp4a" test="@xlink:href">Missing 'xlink:href' attribute on "supplementary-material". The 'xlink:href' should contain the filename (including extension) of the item of supplementary information. Do not include any path information.</assert>
      </rule>
  </pattern>
   <pattern><!--@xlink:href does not contain filepath info-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][@xlink:href and not(contains(@xlink:href,'.doi.'))]"
            role="error">
         <report id="supp4b" test="contains(@xlink:href,'/')">Do not include filepath information for supplementary material files "<value-of select="@xlink:href"/>".</report>
      </rule>
  </pattern>
   <pattern><!--@xlink:href contains a '.' and therefore may have an extension-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][@xlink:href]"
            role="error">
         <assert id="supp4c" test="contains(@xlink:href,'.')">Supplementary-material 'xlink:href' value ("<value-of select="@xlink:href"/>") should contain the file extension (e.g. jpg, doc, etc).</assert>
      </rule>
  </pattern>
   <pattern><!--@xlink:href has valid file extension-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.') and not(contains(@xlink:href,'.doi.'))]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <assert id="supp4d"
                 test="matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')">Unexpected file extension value ("<value-of select="$extension"/>") in supplementary material '@xlink:href' attribute - please check.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mimetype; when @xlink:href does not exist, point to Tagging instructions-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][not(@xlink:href or contains(@xlink:href,'.'))]"
            role="error">
         <assert id="supp5a" test="@mimetype">Missing 'mimetype' attribute on "supplementary-material". Refer to Tagging Instructions for correct value.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mimetype; when @xlink:href is invalid, point to Tagging instructions-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <report id="supp5b"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) and not(@mimetype)">Missing 'mimetype' attribute on "supplementary-material". Refer to Tagging Instructions for correct value.</report>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mimetype; when @xlink:href exists (and is valid) gives value that should be used-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="mimetype"
              value="if (matches($extension,'^(doc|docx|eps|exe|noa|pdf|pps|ppt|pptx|ps|rtf|swf|tar|tgz|wmf|xls|xlsx|xml|zip)$')) then 'application'         else if (matches($extension,'^(mp2|mp3|ra|wav)$')) then 'audio'         else if (matches($extension,'^(cif|pdb|sdf)$')) then 'chemical'         else if (matches($extension,'^(bmp|gif|jpeg|jpg|pict|png|tiff)$')) then 'image'         else if (matches($extension,'^(c|csv|htm|html|sif|txt)$')) then 'text'         else if (matches($extension,'^(avi|mov|mp4|mpg|qt|rv|wmv)$')) then 'video'         else ()"/>
         <assert id="supp5c"
                 test="@mimetype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">Missing 'mimetype' attribute on "supplementary-material". For files with extension "<value-of select="$extension"/>", this should have the value "<value-of select="$mimetype"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--value used for @mimetype is correct based on file extension (includes test for valid extension)-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][@mimetype][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="mimetype"
              value="if (matches($extension,'^(doc|docx|eps|exe|noa|pdf|pps|ppt|pptx|ps|rtf|swf|tar|tgz|wmf|xls|xlsx|xml|zip)$')) then 'application'         else if (matches($extension,'^(mp2|mp3|ra|wav)$')) then 'audio'         else if (matches($extension,'^(cif|pdb|sdf)$')) then 'chemical'         else if (matches($extension,'^(bmp|gif|jpeg|jpg|pict|png|tiff)$')) then 'image'         else if (matches($extension,'^(c|csv|htm|html|sif|txt)$')) then 'text'         else if (matches($extension,'^(avi|mov|mp4|mpg|qt|rv|wmv)$')) then 'video'         else ()"/>
         <assert id="supp5d"
                 test="@mimetype=$mimetype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">For supplementary material files with extension "<value-of select="$extension"/>", the mimetype attribute should have the value "<value-of select="$mimetype"/>" (not "<value-of select="@mimetype"/>").</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mime-subtype; when @xlink:href does not exist or is invalid, point to Tagging instructions-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][not(@xlink:href or contains(@xlink:href,'.'))]"
            role="error">
         <assert id="supp6a" test="@mime-subtype">Missing 'mime-subtype' attribute on "supplementary-material". Refer to Tagging Instructions for correct value.</assert>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mime-subtype; when @xlink:href exists (and is invalid) points to Tagging instructions-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <report id="supp6b"
                 test="not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$')) and not(@mime-subtype)">Missing 'mime-subtype' attribute on "supplementary-material". Refer to Tagging Instructions for correct value based.</report>
      </rule>
  </pattern>
   <pattern><!--supplementary-material - must have a @mime-subtype; when @xlink:href exists (and is valid) gives value that should be used-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="mime-subtype"
              value="if ($extension='tgz') then 'application/gzip'         else if ($extension='bmp') then 'bmp'         else if ($extension='csv') then 'csv'         else if ($extension='gif') then 'gif'         else if ($extension='htm' or $extension='html') then 'html'         else if ($extension='jpeg' or $extension='jpg') then 'jpeg'         else if ($extension='mp4' or $extension='mp2' or $extension='mp3' or $extension='mpg') then 'mpeg'         else if ($extension='doc' or $extension='dot') then 'msword'         else if ($extension='exe' or $extension='noa' or $extension='ole' or $extension='wp') then 'octet-stream'         else if ($extension='pdf') then 'pdf'         else if ($extension='c' or $extension='sif' or $extension='txt') then 'plain'         else if ($extension='png') then 'png'         else if ($extension='eps' or $extension='ps') then 'postscript'         else if ($extension='mov' or $extension='qt') then 'quicktime'         else if ($extension='rtf') then 'rtf'         else if ($extension='sbml') then 'sbml+xml'         else if ($extension='tiff') then 'tiff'         else if ($extension='xls') then 'vnd.ms-excel'         else if ($extension='xlsm') then 'vnd.ms-excel.sheet.macroEnabled.12'         else if ($extension='pps' or $extension='ppt') then 'vnd.ms-powerpoint'         else if ($extension='pptm') then 'vnd.ms-powerpoint.presentation.macroEnabled.12'         else if ($extension='docm') then 'vnd.ms-word.document.macroEnabled.12'         else if ($extension='pptx') then 'vnd.openxmlformats-officedocument.presentationml.presentation'         else if ($extension='xlsx') then 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'         else if ($extension='docx') then 'vnd.openxmlformats-officedocument.wordprocessingml.document'         else if ($extension='ra') then 'vnd.rn-realaudio'         else if ($extension='rv') then 'vnd.rn-realvideo'         else if ($extension='cdx') then 'x-cdx'         else if ($extension='cif') then 'x-cif'         else if ($extension='jdx') then 'x-jcamp-dx'         else if ($extension='tex') then 'x-latex'         else if ($extension='mol') then 'x-mdl-molfile'         else if ($extension='sdf') then 'x-mdl-sdfile'         else if ($extension='xml') then 'xml'         else if ($extension='wmf') then 'x-msmetafile'         else if ($extension='avi') then 'x-msvideo'         else if ($extension='wmv') then 'x-ms-wmv'         else if ($extension='pdb') then 'x-pdb'         else if ($extension='pict') then 'x-pict'         else if ($extension='swf') then 'x-shockwave-flash'         else if ($extension='tar') then 'x-tar'         else if ($extension='wav') then 'x-wav'         else if ($extension='zip') then 'x-zip-compressed'         else ()"/>
         <assert id="supp6c"
                 test="@mime-subtype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">Missing 'mime-subtype' attribute on "supplementary-material". For files with extension "<value-of select="$extension"/>", this should have the value "<value-of select="$mime-subtype"/>".</assert>
      </rule>
  </pattern>
   <pattern><!--value used for @mimetype is correct based on file extension (includes test for valid extension)-->
    <rule context="floats-group/supplementary-material[not(@content-type='external-media')][@mime-subtype][contains(@xlink:href,'.')]"
            role="error">
         <let name="extension" value="functx:substring-after-last(@xlink:href,'.')"/>
         <let name="mime-subtype"
              value="if ($extension='tgz') then 'application/gzip'         else if ($extension='bmp') then 'bmp'         else if ($extension='csv') then 'csv'         else if ($extension='gif') then 'gif'         else if ($extension='htm' or $extension='html') then 'html'         else if ($extension='jpeg' or $extension='jpg') then 'jpeg'         else if ($extension='mp4' or $extension='mp2' or $extension='mp3' or $extension='mpg') then 'mpeg'         else if ($extension='doc' or $extension='dot') then 'msword'         else if ($extension='exe' or $extension='noa' or $extension='ole' or $extension='wp') then 'octet-stream'         else if ($extension='pdf') then 'pdf'         else if ($extension='c' or $extension='sif' or $extension='txt') then 'plain'         else if ($extension='png') then 'png'         else if ($extension='eps' or $extension='ps') then 'postscript'         else if ($extension='mov' or $extension='qt') then 'quicktime'         else if ($extension='rtf') then 'rtf'         else if ($extension='sbml') then 'sbml+xml'         else if ($extension='tiff') then 'tiff'         else if ($extension='xls') then 'vnd.ms-excel'         else if ($extension='xlsm') then 'vnd.ms-excel.sheet.macroEnabled.12'         else if ($extension='pps' or $extension='ppt') then 'vnd.ms-powerpoint'         else if ($extension='pptm') then 'vnd.ms-powerpoint.presentation.macroEnabled.12'         else if ($extension='docm') then 'vnd.ms-word.document.macroEnabled.12'         else if ($extension='pptx') then 'vnd.openxmlformats-officedocument.presentationml.presentation'         else if ($extension='xlsx') then 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'         else if ($extension='docx') then 'vnd.openxmlformats-officedocument.wordprocessingml.document'         else if ($extension='ra') then 'vnd.rn-realaudio'         else if ($extension='rv') then 'vnd.rn-realvideo'         else if ($extension='cdx') then 'x-cdx'         else if ($extension='cif') then 'x-cif'         else if ($extension='jdx') then 'x-jcamp-dx'         else if ($extension='tex') then 'x-latex'         else if ($extension='mol') then 'x-mdl-molfile'         else if ($extension='sdf') then 'x-mdl-sdfile'         else if ($extension='xml') then 'xml'         else if ($extension='wmf') then 'x-msmetafile'         else if ($extension='avi') then 'x-msvideo'         else if ($extension='wmv') then 'x-ms-wmv'         else if ($extension='pdb') then 'x-pdb'         else if ($extension='pict') then 'x-pict'         else if ($extension='swf') then 'x-shockwave-flash'         else if ($extension='tar') then 'x-tar'         else if ($extension='wav') then 'x-wav'         else if ($extension='zip') then 'x-zip-compressed'         else ()"/>
         <assert id="supp6d"
                 test="@mime-subtype=$mime-subtype or not(matches($extension,'^(eps|gif|jpg|jpeg|bmp|png|pict|ps|tiff|wmf|doc|docx|pdf|pps|ppt|pptx|xls|xlsx|tar|tgz|zip|c|csv|htm|html|rtf|txt|xml|aiff|au|avi|midi|mov|mp2|mp3|mp4|mpa|mpg|noa|qt|ra|ram|rv|swf|wav|wmv|cif|exe|pdb|sdf|sif)$'))">For supplementary material files with extension "<value-of select="$extension"/>", the mime-subtype attribute should have the value "<value-of select="$mime-subtype"/>" (not "<value-of select="@mime-subtype"/>").</assert>
      </rule>
  </pattern>
   <pattern><!--no other attributes used on supplementary-material-->
    <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7a" test="@specific-use" role="error">Do not use "specific-use" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7b" test="@xlink:actuate" role="error">Do not use "xlink:actuate" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material[not(@content-type='external-media')]"
            role="error">
         <report id="supp7c" test="@xlink:role" role="error">Do not use "xlink:role" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7d" test="@xlink:show" role="error">Do not use "xlink:show" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7e" test="@xlink:title" role="error">Do not use "xlink:title" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7f" test="@xlink:type" role="error">Do not use "xlink:type" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
   <pattern>
      <rule context="floats-group/supplementary-material" role="error">
         <report id="supp7g" test="@xml:lang" role="error">Do not use "xml:lang" attribute on "supplementary-material".</report>
      </rule>
  </pattern>
<pattern><!--elements not allowed in NPG JATS content-->
    <rule context="abbrev | annotation | collab-alternatives | comment | gov | issn-l | issue-id | issue-part | issue-title | milestone-end | milestone-start | object-id |  page-range | part-title | patent | pub-id | roman | std | trans-abstract | trans-source | volume-id | volume-series"
            role="error">
         <report id="disallowed1" test=".">Do not use "<name/>" element in NPG/Palgrave articles.</report>
         </rule>
  </pattern>
   </schema>