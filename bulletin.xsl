<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:x="internal"
                xpath-default-namespace="https://questionary.iris-psy.org.ua/schema2">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:function name="x:sanitised-text">
    <xsl:param name="node"/>
    <xsl:sequence select="normalize-space(string-join($node//text()[not(parent::image or parent::video or parent::audio)], ' '))"/>
  </xsl:function>

  <xsl:template name="question-template">
    <xsl:param name="element-name"/>
    <question>
      <xsl:attribute name="id" select="$element-name"/>
      <xsl:attribute name="type" select="ancestor-or-self::*[self::question or self::subquestion]/@type"/>
      <xsl:variable name="text">
        <xsl:if test="x:sanitised-text(ancestor-or-self::stickytext/text)">
          <xsl:value-of select="x:sanitised-text(ancestor-or-self::stickytext/text)"/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:if test="x:sanitised-text(ancestor-or-self::question/text)">
          <xsl:value-of select="x:sanitised-text(ancestor-or-self::question/text)"/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:if test="x:sanitised-text(ancestor-or-self::subquestion/text)">
          <xsl:value-of select="x:sanitised-text(ancestor-or-self::subquestion/text)"/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:if test="@placeholder">
          <xsl:value-of select="normalize-space(@placeholder)"/>
        </xsl:if>
      </xsl:variable>
      <xsl:attribute name="text" select="normalize-space($text)" />
      <xsl:attribute name="from" select="ancestor-or-self::*[self::question or self::subquestion]/@from"/>
      <xsl:attribute name="to" select="ancestor-or-self::*[self::question or self::subquestion]/@to"/>
      <xsl:for-each select="answer">
        <answer>
          <xsl:attribute name="id" select="@id"/>
          <xsl:attribute name="text" select="x:sanitised-text(.)"/>
        </answer>
      </xsl:for-each>
    </question>
  </xsl:template>

  <xsl:template match="/">
      <xsl:apply-templates select="//question[answer or subquestion/answer or @type='scale' or @type='number']"/>
  </xsl:template>

  <xsl:template match="question">
    <xsl:variable name="question-number" select="count(ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
    <xsl:variable name="element-name">
      <xsl:text>quest</xsl:text>
      <xsl:value-of select="$question-number"/>
    </xsl:variable>

    <xsl:if test="answer or @type='scale'">
      <xsl:call-template name="question-template">
        <xsl:with-param name="element-name" select="$element-name"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="@type='number'">
      <xsl:apply-templates select="input">
        <xsl:with-param name="element-name" select="$element-name"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:apply-templates select="subquestion[answer or @type='scale' or @type='number']">
      <xsl:with-param name="element-name" select="$element-name"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="subquestion">
    <xsl:param name="element-name"/>
    <xsl:variable name="subquestion-number" select="count(preceding-sibling::subquestion)+1"/>
    <xsl:variable name="element-name">
      <xsl:value-of select="$element-name"/>
      <xsl:text>_sub</xsl:text>
      <xsl:value-of select="$subquestion-number"/>
    </xsl:variable>
    <xsl:if test="answer or @type='scale'">
      <xsl:call-template name="question-template">
        <xsl:with-param name="element-name" select="$element-name"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="@type='number'">
      <xsl:apply-templates select="input">
        <xsl:with-param name="element-name" select="$element-name"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="input">
    <xsl:param name="element-name"/>
    <xsl:variable name="input-number" select="count(preceding-sibling::input)+1"/>

    <xsl:call-template name="question-template">
      <xsl:with-param name="element-name">
        <xsl:value-of select="$element-name"/>
        <xsl:text>_input</xsl:text>
        <xsl:value-of select="$input-number"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>