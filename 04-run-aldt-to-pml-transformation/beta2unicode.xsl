<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
 xmlns:aldt="http://treebank.alpheios.net/namespaces/aldt">

 <xsl:import href="beta-uni-util.xsl"/>

 <xsl:variable name="beta2uni-table"
   select="document('beta-uni-tables.xml')/*/aldt:beta-uni-table"/>

 <!--
     Convert Greek betacode to Unicode
     Parameters:
       $input        betacode input string to be converted
       $pending      character waiting to be output
       $state        diacritics associated with pending character
       $precomposed  whether to put out precomposed or decomposed Unicode

     Output:
       $input transformed to equivalent Unicode

     The characters in the state string are maintained in a canonical order,
     which allows the lookup table to contain a single entry for each
     combination of base character and diacritics.  The diacritics may appear
     in any order in the input.

     Diacritics associated with (either preceding or following) a base
     character are accumulated until either a non-diacritic character or end
     of input are encountered, at which point the pending character is output.
 -->
 <xsl:template name="beta-to-uni">
   <xsl:param name="input"/>
   <xsl:param name="pending" select="''"/>
   <xsl:param name="state" select="''"/>
   <xsl:param name="precomposed" select="true()"/>

   <xsl:variable name="head" select="substring($input, 1, 1)"/>

   <xsl:choose>
     <!-- if no more input -->
     <xsl:when test="string-length($input) = 0">
       <!-- output last pending char -->
       <xsl:call-template name="output-uni-char">
         <xsl:with-param name="char" select="$pending"/>
         <xsl:with-param name="state" select="$state"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>
     </xsl:when>

     <!-- if input starts with "*" -->
     <xsl:when test="$head = '*'">
       <!-- output pending char -->
       <xsl:call-template name="output-uni-char">
         <xsl:with-param name="char" select="$pending"/>
         <xsl:with-param name="state" select="$state"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>

       <!-- recurse, capitalizing next char, erasing any saved state -->
       <xsl:call-template name="beta-to-uni">
         <xsl:with-param name="input" select="substring($input, 2)"/>
         <xsl:with-param name="state" select="'*'"/>
         <xsl:with-param name="pending" select="''"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>
     </xsl:when>

     <!-- if input starts with diacritic -->
     <xsl:when test="contains($beta-diacritics, $head)">
       <!-- update state with new character -->
       <xsl:variable name="newstate">
         <xsl:call-template name="insert-diacritic">
           <xsl:with-param name="string" select="$state"/>
           <xsl:with-param name="char" select="$head"/>
         </xsl:call-template>
       </xsl:variable>

       <!-- recurse with updated state -->
       <xsl:call-template name="beta-to-uni">
         <xsl:with-param name="input" select="substring($input, 2)"/>
         <xsl:with-param name="state" select="$newstate"/>
         <xsl:with-param name="pending" select="$pending"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>
     </xsl:when>

     <!-- if not special char -->
     <xsl:otherwise>
       <!-- output pending char -->
       <xsl:call-template name="output-uni-char">
         <xsl:with-param name="char" select="$pending"/>
         <xsl:with-param name="state" select="$state"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>

       <!-- reset state if there was a pending character -->
       <xsl:variable name="newstate">
         <xsl:choose>
           <xsl:when test="$pending"/>
           <xsl:otherwise>
             <xsl:value-of select="$state"/>
           </xsl:otherwise>
         </xsl:choose>
       </xsl:variable>

       <!-- recurse with head as pending char -->
       <xsl:call-template name="beta-to-uni">
         <xsl:with-param name="input" select="substring($input, 2)"/>
         <xsl:with-param name="state" select="$newstate"/>
         <xsl:with-param name="pending" select="$head"/>
         <xsl:with-param name="precomposed" select="$precomposed"/>
       </xsl:call-template>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!--
     Output a single character with diacritics
     Parameters:
       $char         character to be output
       $state        diacritics associated with character
       $precomposed  whether to put out precomposed or decomposed Unicode
 -->
 <xsl:template name="output-uni-char">
   <xsl:param name="char"/>
   <xsl:param name="state"/>
   <xsl:param name="precomposed"/>

   <xsl:choose>
     <!-- if no character pending -->
     <xsl:when test="string-length($char) = 0">
       <!-- if we have state and we're not processing a capital -->
       <xsl:if
         test="(string-length($state) > 0) and
                     (substring($state, 1, 1) != '*')">
         <!-- output just the state -->
         <!-- here precomposed=true means don't make it combining -->
         <xsl:apply-templates select="$beta2uni-table" mode="b2u">
           <xsl:with-param name="key" select="$state"/>
           <xsl:with-param name="precomposed" select="true()"/>
         </xsl:apply-templates>
       </xsl:if>
     </xsl:when>

     <!-- if character is pending -->
     <xsl:otherwise>
       <!-- translate to lower and back -->
       <xsl:variable name="lowerchar"
         select="translate($char, $beta-uppers, $beta-lowers)"/>
       <xsl:variable name="upperchar"
         select="translate($char, $beta-lowers, $beta-uppers)"/>
       <xsl:choose>
         <!-- if upper != lower, we have a letter -->
         <xsl:when test="$lowerchar != $upperchar">
           <!-- use letter+state as key into table -->
           <xsl:apply-templates select="$beta2uni-table" mode="b2u">
             <xsl:with-param name="key" select="concat($lowerchar, $state)"/>
             <xsl:with-param name="precomposed" select="$precomposed"/>
           </xsl:apply-templates>
         </xsl:when>

         <!-- if upper = lower, we have a non-letter -->
         <xsl:otherwise>
           <!-- output character, if any, then use state as key into table -->
           <!-- this handles the case of isolated diacritics -->
           <xsl:value-of select="$char"/>
           <xsl:if test="string-length($state) > 0">
             <xsl:apply-templates select="$beta2uni-table" mode="b2u">
               <xsl:with-param name="key" select="$state"/>
               <xsl:with-param name="precomposed" select="$precomposed"/>
             </xsl:apply-templates>
           </xsl:if>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!--
     Convert betacode to unicode
     Parameters:
       $key          combined character plus diacritics
       $precomposed  whether to put out precomposed or decomposed Unicode
 -->
 <xsl:key name="beta-uni-lookup" match="aldt:beta-uni-table/aldt:entry"
   use="aldt:beta"/>
 <xsl:template match="aldt:beta-uni-table" mode="b2u">
   <xsl:param name="key"/>
   <xsl:param name="precomposed"/>

   <xsl:variable name="keylen" select="string-length($key)"/>

   <!-- if key exists -->
   <xsl:if test="$keylen > 0">
     <!-- try to find key in table -->
     <xsl:variable name="value">
       <xsl:choose>
         <xsl:when test="$precomposed">
           <xsl:value-of
             select="key('beta-uni-lookup', $key)/aldt:unic/text()"/>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of
             select="key('beta-uni-lookup', $key)/aldt:unid/text()"/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>

     <xsl:choose>
       <!-- if key found, use value -->
       <xsl:when test="string-length($value) > 0">
         <xsl:value-of select="$value"/>
       </xsl:when>

       <!-- if key not found and contains multiple chars -->
       <xsl:when test="$keylen > 1">
         <!-- lookup key with last char removed -->
         <xsl:apply-templates select="$beta2uni-table" mode="b2u">
           <xsl:with-param name="key" select="substring($key, 1, $keylen - 1)"/>
           <xsl:with-param name="precomposed" select="$precomposed"/>
         </xsl:apply-templates>
         <!-- convert last char -->
         <!-- precomposed=false means make sure it's a combining form -->
         <xsl:apply-templates select="$beta2uni-table" mode="b2u">
           <xsl:with-param name="key" select="substring($key, $keylen)"/>
           <xsl:with-param name="precomposed" select="false()"/>
         </xsl:apply-templates>
       </xsl:when>
     </xsl:choose>

     <!-- otherwise, ignore it (probably an errant *) -->
   </xsl:if>
 </xsl:template>

</xsl:stylesheet>
