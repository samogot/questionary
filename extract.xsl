<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:x="internal"
                xpath-default-namespace="https://questionary.iris-psy.org.ua/schema2">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:function name="x:sanitised-text">
    <xsl:param name="node"/>
    <xsl:sequence
        select="normalize-space(string-join($node//text()[not(parent::image or parent::video or parent::audio)], ' '))"/>
  </xsl:function>

  <xsl:template name="field">
    <xsl:param name="id"/>
    <xsl:param name="text" required="no"/>
    <field>
      <xsl:attribute name="id" select="$id"></xsl:attribute>
      <xsl:attribute name="text" select="$text"/>
      <xsl:call-template name="parent-text"/>
    </field>
  </xsl:template>

  <xsl:template name="parent-text">
    <xsl:if test="x:sanitised-text(ancestor-or-self::stickytext/text)">
      <xsl:attribute name="sticky-text"
                     select="x:sanitised-text(ancestor-or-self::stickytext/text)"/>
    </xsl:if>

    <xsl:if test="x:sanitised-text(ancestor-or-self::question/text)">
      <xsl:attribute name="question-text"
                     select="x:sanitised-text(ancestor-or-self::question/text)"/>
    </xsl:if>

    <xsl:if test="x:sanitised-text(ancestor-or-self::subquestion/text)">
      <xsl:attribute name="subquestion-text"
                     select="x:sanitised-text(ancestor-or-self::subquestion/text)"/>
    </xsl:if>

    <xsl:if test="x:sanitised-text(ancestor-or-self::answer)">
      <xsl:attribute name="answer-text"
                     select="x:sanitised-text(ancestor-or-self::answer)"/>
    </xsl:if>

    <xsl:if test="@placeholder">
      <xsl:attribute name="input-text" select="normalize-space(@placeholder)"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates select="//question"/>
  </xsl:template>

  <xsl:template match="question">
    <xsl:variable name="question-number"
                  select="count(ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
    <xsl:variable name="element-name">
      <xsl:text>quest</xsl:text>
      <xsl:value-of select="$question-number"/>
    </xsl:variable>

    <xsl:for-each select="(script|scripts)/declare">
      <xsl:call-template name="field">
        <xsl:with-param name="id">
          <xsl:text>var_</xsl:text><xsl:value-of select="@id"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:if test=".[@type='scale' or (./answer and not(@type='multiselect')) or (./answer and @max=1)]">
      <xsl:call-template name="field">
        <xsl:with-param name="id" select="$element-name"/>
        <xsl:with-param name="text" select="x:sanitised-text(./text)"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:apply-templates>
      <xsl:with-param name="question-number" select="$question-number"/>
      <xsl:with-param name="element-name" select="$element-name"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="subquestion">
    <xsl:param name="element-name"/>
    <xsl:param name="question-number"/>
    <xsl:variable name="subquestion-number" select="count(preceding-sibling::subquestion)+1"/>
    <xsl:variable name="element-name">
      <xsl:value-of select="$element-name"/>
      <xsl:text>_sub</xsl:text>
      <xsl:value-of select="$subquestion-number"/>
    </xsl:variable>

    <xsl:if test=".[@type='scale' or (./answer and (not(@type='multiselect') or @max=1))]">
      <xsl:call-template name="field">
        <xsl:with-param name="id" select="$element-name"/>
        <xsl:with-param name="text" select="x:sanitised-text(./text)"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:apply-templates>
      <xsl:with-param name="question-number" select="$question-number"/>
      <xsl:with-param name="element-name" select="$element-name"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="answer">
    <xsl:param name="question-number"/>
    <xsl:param name="element-name"/>
    <xsl:variable name="answer-number" select="count(preceding-sibling::answer)+1"/>

    <xsl:if test="..[@type='multiselect' and @max &gt; 1]">
      <xsl:call-template name="field">
        <xsl:with-param name="id">
          <xsl:value-of select="$element-name"/>
          <xsl:text>_answ</xsl:text>
          <xsl:value-of select="$answer-number"/>
        </xsl:with-param>
        <xsl:with-param name="text" select="x:sanitised-text(.)"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:apply-templates>
      <xsl:with-param name="question-number" select="$question-number"/>
      <xsl:with-param name="element-name">
        <xsl:value-of select="$element-name"/>
        <xsl:text>_answ</xsl:text>
        <xsl:value-of select="$answer-number"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="input">
    <xsl:param name="element-name"/>
    <xsl:variable name="input-number" select="count(preceding-sibling::input)+1"/>

    <xsl:call-template name="field">
      <xsl:with-param name="id">
        <xsl:value-of select="$element-name"/>
        <xsl:text>_input</xsl:text>
        <xsl:value-of select="$input-number"/>
      </xsl:with-param>
      <xsl:with-param name="text" select="@placeholder"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="node()">
  </xsl:template>

</xsl:stylesheet>