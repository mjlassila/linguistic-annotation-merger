import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Copyright (2013) by Timo Korkiakangas (University of Helsinki) & Matti Lassila (University of Tampere). Licensed under GNU GPL v3 (or later) :)

(: The second script to run in the toolchain. :)

(: This script converts 'expan', 'damage', and 'seg' tags to XML attributes within an XPointer file where the XPointers point to the treebank annotation. :)
(: Originally, they are expressed as nested XML elements, i.e. 'expan', 'damage', and 'seg' are parents to word (w) elements. :)
(: The script outputs a file, which is used as input for creating a PML format treebank with 'expan', 'damage', and 'seg' annotation as attributes. :)
<texts>{

(: Let's open an XPointer file with 'expan', 'damage', and 'seg' tags from the XML database. :)
for $text in db:open("database_name","XPointer_file_name")//tei:group/tei:text
  return
    <text n="{data($text/@n)}">{
      for $p in $text/tei:body/tei:p
       return
        <paragraph>{
          for $word in $p//tei:w

            (: If the word has a 'seg' element as an ancestor, let's include that. :)
            (: If there is no 'seg' information, let's write 'formulaic' as a placeholder value. :)
            let $seg:= if(string-length($word/ancestor::tei:seg/@type)>1) then
              $word/ancestor::tei:seg/@type
              else('formulaic')

            (: If a word has an 'expan' or 'damage' element as a parent, let's include that. :)
            (: A word cannot have 'expan' and 'damage' tags at the same time. :)
            (: If there is no status information (i.e. 'expan' or 'damage'), let's write 'normal' as a placeholder value. :)
            (: I.e., we do the same as with the 'seg' tags. :)
            let $expan_or_damage:=
              if($word/parent::tei:expan) then
                'expan'
                 else if($word/parent::tei:damage) then
                'damage'
              else 'normal'

            (: Now, we have to include our newly created 'damage', 'expan', and 'seg' values as XML attributes. :)
            (: First, 'expan' and 'damage' :)
            let $with_expan_or_damage:=functx:add-attributes(
                 $word,
                 xs:QName('status'),$expan_or_damage)
            (: Next, 'seg' :)
            let $with_seg:=functx:add-attributes(
                 $with_expan_or_damage,
                 xs:QName('seg'),$seg)
          (: Finally, let's output the word elements. :)
          return $with_seg
        }</paragraph>
    }</text>
}</texts>