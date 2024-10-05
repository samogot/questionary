<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xpath-default-namespace="http://questionary.iris-psy.org.ua/schema" >
  <xsl:output omit-xml-declaration="no" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <xsl:apply-templates select="questionary/*"/>
  </xsl:template>
  <xsl:template match="stickytext">
    <xsl:apply-templates select="question"/>
  </xsl:template>
  <xsl:template match="script|scripts" name="script">
    <xsl:for-each select="load">
      <xsl:variable name="key" select="text()"/>
      <xsl:variable name="keyelem" select="//node()[@id = $key]"/>
      <div class="load-key" name="{$key}">
        <xsl:choose>
          <xsl:when test="$keyelem[name()='question']">
            <xsl:text>quest</xsl:text>
            <xsl:value-of
                select="count($keyelem/ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
          </xsl:when>
          <xsl:when test="$keyelem[name()='declare']">
            <xsl:text>var_</xsl:text>
            <xsl:value-of select="$key"/>
          </xsl:when>
        </xsl:choose>
      </div>
    </xsl:for-each>
    <script type="text/javascript">
      <xsl:value-of disable-output-escaping="yes" select="body"/>
      $('[data-role="page"]:not(.ui-page)').one('pagebeforecreate', function(){
      <xsl:value-of disable-output-escaping="yes" select="beforecreate"/>
      });
    </script>
  </xsl:template>
  <xsl:template match="question" name="question">
    <xsl:variable name="question-number"
        select="count(ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
    <xsl:variable name="element-name">
      <xsl:text>quest</xsl:text>
      <xsl:value-of select="$question-number"/>
    </xsl:variable>
    <xsl:text>!@#$%^*SEPARATOR*^%$#@!</xsl:text>
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <xsl:comment>
        <xsl:value-of select="$question-number"/>
      </xsl:comment>
      <head>
        <title>Опитувальник</title>
        <meta name="author" content="Samogot"/>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link href="/android_asset/css/jquery.mobile.css" rel="stylesheet"/>
        <link href="/android_asset/css/style.css" rel="stylesheet"/>
        <link href="/android_asset/css/iat.css" rel="stylesheet"/>
        <link href="//cdn.syncfusion.com/20.1.0.55/js/web/flat-azure/ej.web.all.min.css" rel="stylesheet"/>
        <script src="/android_asset/js/jquery.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="/android_asset/js/config.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="/android_asset/js/jquery.mobile.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="/android_asset/js/api.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="/android_asset/js/iat.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="/android_asset/js/script.js">
          <xsl:text> </xsl:text>
        </script>
        <script src="//cdn.syncfusion.com/20.1.0.55/js/web/ej.web.all.min.js">
          <xsl:text> </xsl:text>
        </script>
      </head>
      <body>
        <div data-role="page" lang="{/questionary/@lang}">
          <xsl:choose>
            <xsl:when test=".[@type='iat']">
              <xsl:attribute name="id">iat</xsl:attribute>
              <div id="preload">
                <xsl:text> </xsl:text>
              </div>
              <div id="frame">
                <div id="left">
                  <div class="attr">
                    <xsl:text> </xsl:text>
                  </div>
                  <div class="or">
                    <xsl:text> </xsl:text>
                  </div>
                  <div class="targ">
                    <xsl:text> </xsl:text>
                  </div>
                </div>
                <div id="right">
                  <div class="attr">
                    <xsl:text> </xsl:text>
                  </div>
                  <div class="or">
                    <xsl:text> </xsl:text>
                  </div>
                  <div class="targ">
                    <xsl:text> </xsl:text>
                  </div>
                </div>
                <table id="stimul">
                  <tr>
                    <td>
                      <xsl:text> </xsl:text>
                    </td>
                  </tr>
                </table>
                <div id="error">X</div>
                <table id="instructions">
                  <tr>
                    <td>
                      <xsl:text> </xsl:text>
                    </td>
                  </tr>
                </table>
              </div>
              <p id="bottom_instr">
                <xsl:text> </xsl:text>
              </p>
              <xsl:call-template name="script"/>
            </xsl:when>
            <xsl:otherwise>
              <div data-role="header" data-position="fixed">
                <xsl:if test=".[@type='multiselect' and @max]">
                  <a data-icon="check" id="checkcounter">
                    <xsl:value-of select="@max"/>
                    <xsl:text> з </xsl:text>
                    <xsl:value-of select="@max"/>
                  </a>
                </xsl:if>
                <h1>Опитувальник</h1>
                <a data-icon="grid" class="ui-btn-right" id="pages">
                  <xsl:value-of select="$question-number"/>
                  <xsl:text> з </xsl:text>
                  <xsl:value-of select="count(//question)"/>
                </a>
              </div>
              <form data-role="content" class="questions">
                <xsl:apply-templates select="..[name()='stickytext']/text"/>
                <xsl:apply-templates
                    select="child::*[not(name()='answer' or name()='script' or name()='scripts' or name()='from-text' or name()='to-text')]">
                  <xsl:with-param name="question-number" select="$question-number"/>
                  <xsl:with-param name="element-name" select="$element-name"/>
                </xsl:apply-templates>
                <xsl:if test=".[@type='treeselect']">
                  <input type="text" name="{$element-name}"/>
                  <script type="text/javascript">
                    <xsl:text>var localData = [</xsl:text>
                    <xsl:apply-templates select="answer"></xsl:apply-templates>
                    <xsl:text>];</xsl:text>
                    <xsl:text>
                                            $(function () {
                                                $('input[name="</xsl:text><xsl:value-of select="$element-name"/><xsl:text>"]').ejDropDownTree({
                                                    enableFilterSearch: true,
                                                    treeViewSettings: {
                                                        fields: { id: "id", parentId: "pid", value: "id", text: "name", dataSource: localData }
                                                    },
                                                    popupSettings: { height: "500px" },
                                                    watermarkText: "Виберіть...",
                                                    width: "100%",
                                                    select: function () { this.hidePopup() }
                                                });
                                            });
                                        </xsl:text>
                  </script>
                </xsl:if>
                <fieldset data-role="controlgroup">
                  <xsl:if test=".[answer/image or @type='scale']">
                    <xsl:attribute name="data-type">horizontal</xsl:attribute>
                  </xsl:if>
                  <xsl:if test=".[not(@type='treeselect')]">
                    <xsl:apply-templates select="answer">
                      <xsl:with-param name="question-number" select="$question-number"/>
                      <xsl:with-param name="element-name" select="$element-name"/>
                    </xsl:apply-templates>
                  </xsl:if>
                  <xsl:if test=".[@type='scale']">
                    <xsl:if test=".[from-text]">
                      <button type="button" disabled="disabled">
                        <xsl:value-of select="from-text"/>
                      </button>
                    </xsl:if>
                    <xsl:call-template name="scale">
                      <xsl:with-param name="question-number" select="$question-number"/>
                      <xsl:with-param name="from" select="@from"/>
                      <xsl:with-param name="to" select="@to"/>
                      <xsl:with-param name="cur" select="1"/>
                    </xsl:call-template>
                    <xsl:if test=".[to-text]">
                      <button type="button" disabled="disabled">
                        <xsl:value-of select="to-text"/>
                      </button>
                    </xsl:if>
                  </xsl:if>
                </fieldset>
                <xsl:if
                    test=".[not(@type='select' or @type='scale') or descendant::input or answer/image or subquestion]">
                  <p>
                    <button type="button" class="apply"
                        href="quest{$question-number+1}.html">
                      <xsl:if test=".[not(@type='context') or descendant::video]">
                        <xsl:attribute name="disabled">true</xsl:attribute>
                      </xsl:if>
                      <xsl:text>OK</xsl:text>
                    </button>
                  </p>
                </xsl:if>
                <xsl:if
                    test=".[(@type='select' or @type='scale') and not(descendant::input or answer/image)]">
                  <input type="hidden" name="{$element-name}"/>
                </xsl:if>
                <xsl:for-each select="(script|scripts)/declare">
                  <input type="hidden" name="var_{@id}"/>
                </xsl:for-each>
              </form>
              <xsl:apply-templates select="script|scripts"/>
            </xsl:otherwise>
          </xsl:choose>
          <script type="text/javascript"
              src="/android_asset/js/lang_{/questionary/@lang}.js">
            <xsl:text> </xsl:text>
          </script>
          <xsl:if test=".[@mp]">
            <script type="text/javascript">
                            <xsl:text>
                                if(window.android)
                                    android.mp();
                            </xsl:text>
            </script>
          </xsl:if>
          <xsl:if test=".[@ma]">
            <script type="text/javascript">
                            <xsl:text>
                                if(window.android)
                                    android.ma(</xsl:text><xsl:value-of select="@ma"/><xsl:text>);
                            </xsl:text>
            </script>
          </xsl:if>
        </div>
      </body>
    </html>

  </xsl:template>
  <xsl:template name="scale">
    <xsl:param name="question-number"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="cur"/>
    <button type="button" class="answer" value="{$cur}"
        href="quest{$question-number+1}.html">
      <xsl:value-of select="$from + $cur - 1"/>
    </button>
    <xsl:if test="$from + $cur - 1 &lt; $to">
      <xsl:call-template name="scale">
        <xsl:with-param name="question-number" select="$question-number"/>
        <xsl:with-param name="from" select="$from"/>
        <xsl:with-param name="to" select="$to"/>
        <xsl:with-param name="cur" select="$cur + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="subquestion">
    <xsl:param name="element-name"/>
    <xsl:param name="question-number"/>
    <xsl:variable name="subquestion-number"
        select="count(preceding-sibling::subquestion)+1"/>
    <xsl:variable name="element-name">
      <xsl:value-of select="$element-name"/>
      <xsl:text>_sub</xsl:text>
      <xsl:value-of select="$subquestion-number"/>
    </xsl:variable>
    <div class="subquestion">
      <xsl:apply-templates select="child::node()[not(name()='answer')]">
        <xsl:with-param name="question-number" select="$question-number"/>
        <xsl:with-param name="element-name" select="$element-name"/>
      </xsl:apply-templates>
      <fieldset data-role="controlgroup">
        <xsl:if test=".[answer/image or @type='scale']">
          <xsl:attribute name="data-type">horizontal</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="answer">
          <xsl:with-param name="question-number" select="$question-number"/>
          <xsl:with-param name="element-name" select="$element-name"/>
        </xsl:apply-templates>
        <xsl:if test=".[@type='scale']">
          <xsl:call-template name="scale">
            <xsl:with-param name="question-number" select="$question-number"/>
            <xsl:with-param name="from" select="@from"/>
            <xsl:with-param name="to" select="@to"/>
            <xsl:with-param name="cur" select="1"/>
          </xsl:call-template>
        </xsl:if>
      </fieldset>
    </div>
  </xsl:template>
  <xsl:template match="text[descendant::p]|cardtext[descendant::p]">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="text[not(descendant::p)]|cardtext[not(descendant::p)]">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="answer">
    <xsl:param name="question-number"/>
    <xsl:variable name="answer-number" select="count(preceding-sibling::answer)+1"/>
    <button type="button" class="answer" value="{$answer-number}"
        href="quest{$question-number + 1}.html">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test=".[@goto]">
            <xsl:variable name="goto" select="@goto"/>
            <xsl:text>quest</xsl:text>
            <xsl:value-of
                select="count(//question[@id = $goto]/ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
            <xsl:text>.html</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>quest</xsl:text>
            <xsl:value-of select="$question-number + 1"/>
            <xsl:text>.html</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <xsl:apply-templates/>
    </button>
  </xsl:template>
  <xsl:template match="answer[../@type='treeselect']">
    <xsl:text>{ id: "</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:if test=".[@parent]">
      <xsl:text>", pid: "</xsl:text>
      <xsl:value-of select="@parent"/>
    </xsl:if>
    <xsl:text>", name: "</xsl:text>
    <xsl:value-of select="replace(text(), '&quot;', '\\&quot;')"/>
    <xsl:text>"},
        </xsl:text>
  </xsl:template>
  <xsl:template
      match="answer[../@type='multiselect' or ../descendant::input or ../answer/image or parent::subquestion]">
    <xsl:param name="question-number"/>
    <xsl:param name="element-name"/>
    <xsl:variable name="answer-number" select="count(preceding-sibling::answer)+1"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="..[@type='select' or @max = 1]">
          <xsl:text>radio</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>checkbox</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="answer-input">
      <xsl:with-param name="element-name" select="$element-name"/>
      <xsl:with-param name="question-number" select="$question-number"/>
      <xsl:with-param name="answer-number" select="$answer-number"/>
      <xsl:with-param name="type" select="$type"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="answer-input">
    <xsl:param name="element-name"/>
    <xsl:param name="question-number"/>
    <xsl:param name="answer-number"/>
    <xsl:param name="type"/>
    <label>
      <input type="{$type}">
        <xsl:attribute name="value">
          <xsl:if test="$type='radio'">
            <xsl:value-of select="$answer-number"/>
          </xsl:if>
          <xsl:if test="$type='checkbox'">1</xsl:if>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:if test="$type='checkbox'"><xsl:value-of select="$element-name"/>_answ<xsl:value-of
              select="$answer-number"/>
          </xsl:if>
          <xsl:if test="$type='radio'">
            <xsl:value-of select="$element-name"/>
          </xsl:if>
        </xsl:attribute>
        <xsl:if test=".[@goto]">
          <xsl:variable name="goto" select="@goto"/>
          <xsl:attribute name="href">
            <xsl:text>quest</xsl:text>
            <xsl:value-of
                select="count(//question[@id = $goto]/ancestor-or-self::node()/preceding-sibling::node()/descendant-or-self::question) + 1"/>
            <xsl:text>.html</xsl:text>
          </xsl:attribute>
        </xsl:if>
      </input>
      <xsl:apply-templates>
        <xsl:with-param name="question-number" select="$question-number"/>
        <xsl:with-param name="element-name">
          <xsl:value-of select="$element-name"/>
          <xsl:text>_answ</xsl:text>
          <xsl:value-of select="$answer-number"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </label>
  </xsl:template>
  <xsl:template match="video">
    <button type="button" class="video" data-inline="true" value="video/{.}">Подивитись
      відео
    </button>
  </xsl:template>
  <xsl:template match="audio">
    <button type="button" class="audio" data-inline="true" value="audio/{.}">Прослухати
      запис
    </button>
  </xsl:template>
  <xsl:template match="image">
    <img src="image/{.}">
      <xsl:copy-of select="@width"/>
      <xsl:copy-of select="@height"/>
    </img>
  </xsl:template>
  <xsl:template match="input">
    <xsl:param name="element-name"/>
    <xsl:variable name="input-number" select="count(preceding-sibling::input)+1"/>
    <input type="text" name="{$element-name}_input{$input-number}">
      <xsl:copy-of select="@placeholder"/>
      <xsl:copy-of select="@type"/>
      <xsl:if test=".[not(@type)]">
        <xsl:copy-of select="../@type"/>
      </xsl:if>
      <xsl:if test="..[name()='answer']">
        <xsl:attribute name="data-mini">true</xsl:attribute>
        <xsl:attribute name="style">width: 200px;</xsl:attribute>
      </xsl:if>
    </input>
  </xsl:template>

  <xsl:template match="*">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*|text()|comment()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>