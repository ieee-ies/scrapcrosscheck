#!/usr/bin/env perl

# Extracts document name, similarity index, and report URL from an HTML report pagenum
# Antonio Luque <aluque@ieee.org> 2019-04-12

while (<>) {
    if(/<td class="docName"><font size="3" >(.*)<\/td>/) {
        $docname=$1;
    }
    if(/<td><font size="3" color="red"><b>(.*)<\/b><\/td>/) {
        $similarity=$1;
    }
    if(/gotoReport\('(.*)' , '(.*)' , '(.*)' , '(.*)' \);" ><font size="3" color="red"><b>Review Report<\/b>/) {
        print "$docname https://crosscheck.ieee.org/crosscheck/GetScore?id=$2&pages=$3&docid=$1&pagenum=$4 $similarity\n";
    }
}
