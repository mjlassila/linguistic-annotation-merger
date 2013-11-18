<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

 <!-- Upper/lower tables.  Note: J is not a valid betacode base character. -->
 <xsl:variable name="beta-uppers">ABCDEFGHIKLMNOPQRSTUVWXYZ</xsl:variable>
 <xsl:variable name="beta-lowers">abcdefghiklmnopqrstuvwxyz</xsl:variable>

 <!-- diacritics in betacode and combining unicode -->
 <xsl:variable name="beta-diacritics">()+/\=|_^</xsl:variable>
 <xsl:variable name="uni-diacritics">
&#x0314;&#x0313;&#x0308;&#x0301;&#x0300;&#x0342;&#x0345;&#x0304;&#x0306;</xsl:variable>

 <!--
   Insert betacode diacritic character in sorted order in string
   Parameters:
     $string       existing string
     $char         character to be inserted

   Output:
     updated string with character inserted in canonical order
 -->
 <xsl:template name="insert-diacritic">
   <xsl:param name="string"/>
   <xsl:param name="char"/>

   <xsl:choose>
     <!-- if empty string, use char -->
     <xsl:when test="string-length($string) = 0">
       <xsl:value-of select="$char"/>
     </xsl:when>

     <xsl:otherwise>
       <!-- find order of char and head of string -->
       <xsl:variable name="head" select="substring($string, 1, 1)"/>
       <xsl:variable name="charOrder">
         <xsl:call-template name="beta-order">
           <xsl:with-param name="beta" select="$char"/>
         </xsl:call-template>
       </xsl:variable>
       <xsl:variable name="headOrder">
         <xsl:call-template name="beta-order">
           <xsl:with-param name="beta" select="$head"/>
         </xsl:call-template>
       </xsl:variable>

       <xsl:choose>
         <!-- if new char is greater than head, insert it in remainder -->
         <xsl:when test="number($charOrder) > number($headOrder)">
           <xsl:variable name="tail">
             <xsl:call-template name="insert-diacritic">
               <xsl:with-param name="string" select="substring($string, 2)"/>
               <xsl:with-param name="char" select="$char"/>
             </xsl:call-template>
           </xsl:variable>
           <xsl:value-of select="concat($head, $tail)"/>
         </xsl:when>

         <!-- if same as head, discard it (don't want duplicates) -->
         <xsl:when test="number($charOrder) = number($headOrder)">
           <xsl:value-of select="$string"/>
         </xsl:when>

         <!-- if new char comes before head -->
         <xsl:otherwise>
           <xsl:value-of select="concat($char, $string)"/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!--
   Define canonical order of betacode diacritics
   Parameter:
     $beta        betacode diacritic character

   Output:
     numerical order of character in canonical ordering
 -->
 <xsl:template name="beta-order">
   <xsl:param name="beta"/>
   <xsl:choose>
     <!-- capitalization -->
     <xsl:when test="$beta = '*'">0</xsl:when>
     <!-- dasia -->
     <xsl:when test="$beta = '('">1</xsl:when>
     <!-- psili -->
     <xsl:when test="$beta = ')'">2</xsl:when>
     <!-- diaeresis -->
     <xsl:when test="$beta = '+'">3</xsl:when>
     <!-- acute -->
     <xsl:when test="$beta = '/'">4</xsl:when>
     <!-- grave -->
     <xsl:when test="$beta = '\'">5</xsl:when>
     <!-- perispomeni -->
     <xsl:when test="$beta = '='">6</xsl:when>
     <!-- ypogegrammeni -->
     <xsl:when test="$beta = '|'">7</xsl:when>
     <!-- macron -->
     <xsl:when test="$beta = '_'">8</xsl:when>
     <!-- breve -->
     <xsl:when test="$beta = '^'">9</xsl:when>
   </xsl:choose>
 </xsl:template>

</xsl:stylesheet>
