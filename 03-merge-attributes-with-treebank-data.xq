import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: The third script to run in the toolchain. :)
(: This script combines linguistic annotation with textual information ('expan', 'damage', and 'seg'). :)

<treebank xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:treebank="http://nlp.perseus.tufts.edu/syntax/treebank/1.5" version="1.5" xsi:schemaLocation="http://nlp.perseus.tufts.edu/syntax/treebank/1.5 treebank-1.5.xsd" xml:lang="lat">
	<date>date</date>
	<annotator>
		<short>short_name</short>
		<name>name</name>
		<address>address</address>
	</annotator> {
  (: Let's open the XPointer file, in which the textual information ('expan', 'damage', and 'seg') was included as XML attributes. :)
  (: These input files were created in the previous step and saved to the database. :)
  for $text in db:open("database_name","XPointer_file_name.xml")/texts/text
    (: Process the text paragraph by paragraph. :)
    for $p in $text/paragraph
      return
        (: We select all the words in the paragraph. :)
        let $words_with_segmentation:=$p/*:w
        (: We have to construct the treebank sentence by sentence. :)
        (: To do this, we have to separate the sentence parts from the XPointers. :)
        let $sentence_pointers:=
          for $xpointer in $words_with_segmentation/@ana
            (: Each word may have multiple XPointers, but they point all to the same sentence, so we use the first one. :)
            let $individual_xpointers:=tokenize($xpointer, '\s+')
            (: We split the full XPointer by 'word', so we get the sentence part of the XPointer. :)
            let $sentence_selector:=(substring-before(substring-after(data($individual_xpointers[1]), '#xpointer('), '/word'))
            return $sentence_selector

        (: Let's include only one sentence pointer per sentence, as the $sentence_pointers contain the sentence part of all words in the sentence repeatedly. :)
        let $clean_sentence_pointers:=distinct-values($sentence_pointers)

        (: Now, we use the sentence pointers to query the document identification information (e.g. 'text=172') to be included in the treebank. :)
        for $sentence_pointer in $clean_sentence_pointers
         (: We query the document information by executing the sentence pointer. The original linguistic treebank annotation includes the document information in each sentence. :)
          let $sentence:=xquery:eval($sentence_pointer)
          return
            <sentence id="{data($sentence/@id)}" document_id="{data($sentence/@document_id)}" subdoc="{data($sentence/@subdoc)}">{
              (: Let's process the words with textual information ('expan', 'damage', and 'seg') one by one. :)
              for $word in $words_with_segmentation
                (: Include only words which belong to this sentence. :)
                where contains($word/@ana, data($sentence/@id))
                let $xpointer:=$word/@ana
                (: Each word may have multiple XPointers. :)
                let $individual_xpointers:=tokenize($xpointer[1], '\s+')
                
                for $word_pointer in $individual_xpointers
                    (: The $words_to_analyze includes all the words with linguistic annotation that the Xpointer(s) in the original text file pointed to. :)
                    let $words_to_analyze:= xquery:eval(substring-before(substring-after(data($word_pointer), '#xpointer('), ')'))
                     (: Include 'expan', 'damage', and 'seg' information to the words to be outputted. :)
                    
                    let $seg:= if(string-length($word/@seg)>1) then
                      $word/@seg
                      else('none')
        
                     (: Finally, let's include the status and segmentation information. :)
                    for $word_to_analyze in $words_to_analyze
                      (: First, status information. :)
                      let $with_status:=functx:add-attributes(
                        $word_to_analyze,
                        xs:QName('status'),data($word/@status))
                      (: Then, segmentation. :)
                      let $word_to_return:=functx:add-attributes(
                        $with_status,
                        xs:QName('seg'),$seg)
   
                      (: Output the word with full information, i.e. with linguistic annotation combined with 'expan', 'damage', and 'seg' information. :)
                      return $word_to_return
             }</sentence>
           }
</treebank>