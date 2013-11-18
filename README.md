Linguistic annotation merger
============================

This repository contains scripts for combining annotations created in Perseus and Alpheios editors.

Description of the workflow:

1. Run alignannotations-latin XQuery transformation scenario to merge the two annotation layers through XPointers (01-run-xpointer-transformation-scenario.md). 
2. Convert the segmentation and status annotation into XML attributes for each word element inside the XPointer file (02-convert-elements-to-attributes.xq).
3. Merge the segmentation and status attributes of the XPointer file with each word element of the treebank file (03-merge-attributes-with-treebank-data.xq).
4. Transform the merged treebank file into PML format by using the Ancient Language Dependency Treebank XSL transformation stylesheet (aldt2pml-unicode-with-custom-attributes.xsl in the 04-run-aldt-to-pml-transformation folder).
5. To query the PML file in the TrEd Tree Editor, use the modified XML schema with the custom attributes defined (./schema-for-tred/aldt_schema.xml).

Copyright (2013) by Timo Korkiakangas (University of Helsinki) & Matti Lassila (University of Tampere).

aldt2pml transformation stylesheets copyrighed by Francesco Mambrini.

Licenced under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.



