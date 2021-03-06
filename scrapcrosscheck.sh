#!/usr/bin/env bash
#
# Scraps the reports produced by IEEE Crosscheck for a conference
# Antonio Luque <aluque@ieee.org> 2019-04-12
#
# Requirements: bash, curl, perl, sed, awk, jq, phantom.js
#
# INSTRUCTIONS:
#
# Using a web browser, login into Crosscheck (https://crosscheck.ieee.org), create a publication (conference), upload papers (either one
# by one or in batches), and wait until all processing is done.
#
# When processing is done, enter the conference report, copy the URL from the browser bar at the conference initial page (where the
# first page of results is displayed). This URL has the form https://crosscheck.ieee.org/crosscheck/Report?id=...
#
# Paste this URL at the confreport line below. Paste your IEEE account username as well
# Run the script, enter your password when prompted, and it will download all the offline reports. It will take some time
#
# TODO: save the file using the similarity index for easier inspection

#only flagged reports will be downloaded
echo "Only flagged reports (where similarity index is above the threshold) will be downloaded from Crosscheck."

# Getting the initial page of the conference report here
echo "Enter the initial page of Crosscheck report e.g. https://crosscheck.ieee.org/crosscheck/Report?id=..."
read -p "Crosscheck initial page: " confreport

shopt -s expand_aliases
alias goto="cat >/dev/null <<"

# Getting IEEE username and password
echo "Enter your IEEE username e.g. aluque@ieee.org"
read -p "IEEE username: " USERNAME

echo "Enter the password for the IEEE account '$USERNAME' (will not be echoed)"
read -s PASSWD

echo -n "Logging in to Crosscheck..."
curl -s -X POST -c cookiejar.txt "https://crosscheck.ieee.org/crosscheck/LoginServlet?username=$USERNAME&password=$PASSWD" >/dev/null
echo "done."

# sed parameters to accomodate unix and macos sed implementations
sed  -Ei'_' -e 's/\#HttpOnly_crosscheck.ieee.org/crosscheck.ieee.org/' cookiejar.txt
\rm -f cookiejar.txt_

sleep 2


numpages=$(echo $confreport | perl -ne '/&pages=(.*)&pagenum/ && print $1')
echo "There are $numpages pages of reports"

sleep 2

echo "" > allreports.txt
for p in $(seq 1 $numpages); do
    if [ -f allreports-${p}.txt ]; then rm allreports-${p}.txt; fi
    thispage=$(echo $confreport |perl -p -e 's/&pagenum=.*&sortcol/&pagenum='${p}'&sortcol/g')
    echo -n "Getting page $p of $numpages ($thispage)..."
    curl -s -X GET -b cookiejar.txt "$thispage" -o confreport.html
    echo "done."
    cat confreport.html | ./getreporturls.pl >> allreports-${p}.txt
    sleep 1
    # Now all Crosscheck URLs are in allreports.txt
    # We need to convert them to iThenticate URLs

    if [ -f allithenticate-${p}.txt ]; then rm allithenticate-${p}.txt; fi
    cat allreports-${p}.txt| while read u; do
        docpdf=$(echo $u |awk '{print "report_"$3"_"$1}')
        u1=$(echo $u |awk '{print $2}')
        #echo "Document $docpdf has its report at $u1"
        echo -n $docpdf >> allithenticate-${p}.txt
        echo -n " " >> allithenticate-${p}.txt
        echo -n "Converting to the equivalent entry iThenticate URL from $u1..."
        curl -s -X GET -b cookiejar.txt "$u1" >> allithenticate-${p}.txt
        echo "done."
        sleep 1
    done
    echo >> allithenticate-${p}.txt


    # With phantom.js, obtain the equivalent URLs
    cat allithenticate-${p}.txt| while read u; do
        if [[ "$u" == '' ]]; then continue; fi
        docpdf=$(echo $u |awk '{print $1}')
        if [[ -f "$docpdf" ]]
        then
          echo "File $docpdf exists already locally and wont be re-downloaded. Delete the local copy to fetch it again."
          continue
        fi
        u1=$(echo $u |awk '{print $2}')
        echo -n "Now getting iThenticate real URL for $docpdf ($u1)..."
        ithresp=$(phantomjs ithenticate_url.js $u1|head -1)
        ithurl=$(echo $ithresp |awk '{print $1}')
        ithcookie=$(echo $ithresp |awk '{print $2}')
        echo "which is $ithurl"
        echo -e "api.ithenticate.com\tFALSE\t/\tTRUE\t0\tithenticate_session\t$ithcookie" > ithenticatecookie.txt
        echo -e "api.ithenticate.com\tFALSE\t/\tTRUE\t0\tuse_text\t0" >> ithenticatecookie.txt
        echo -e "api.ithenticate.com\tFALSE\t/\tTRUE\t0\tdefaultSideBar\t1" >> ithenticatecookie.txt

        sleep 1

        docid=$(echo $ithurl| perl -ne '/o=([0123456789]*)/ && print $1')
        echo "The iThenticate document id for $docpdf is $docid"
        queueurl="https://api.ithenticate.com/paper/${docid}/queue_pdf?&lang=en_us&output=json"
        echo -n "Adding $docpdf to the queue ($queueurl)..."
        readyurl=$(curl -s -X POST -H "Content-Type: application/json" --data '{"as": 1, "or_type": "similarity"}' -b ithenticatecookie.txt "$queueurl" | jq '.url' |sed 's/"//g')
        if [ "$readyurl" = "" ]; then echo "Cannot add. Moving to next one."; continue; fi
        if [ "$readyurl" = "null" ]; then echo "Cannot add. Moving to next one."; continue; fi
        echo "done."
        pdfready="no"
        echo -n "Waiting for the report to be ready (at $readyurl)..."
        while [ "$pdfready" = "no" ] ; do
            sleep 1
            echo -n "."
            readyreply=$(curl -s -X GET -b ithenticatecookie.txt "$readyurl")
            isready=$(echo $readyreply |jq '.ready')
            if [ "$isready" = "1" ]; then
                pdfurl=$(echo $readyreply |jq '.url' |sed 's/"//g')
                echo -n "Ready! Downloading '$pdfurl' into $docpdf..."
                pdfready=yes
                curl -s -X GET -b ithenticatecookie.txt "$pdfurl" -o $docpdf
                echo "Done! Report for $docpdf is now available offline."
            fi
        done

    done

    # Relogging in after each page to avoid timeout
    echo -n "Relogging into Crosscheck..."
    curl -s -X POST -c cookiejar.txt "https://crosscheck.ieee.org/crosscheck/LoginServlet?username=$USERNAME&password=$PASSWD" >/dev/null
    echo "done."

done


# cleanup
\rm -f allithenticate*.txt
\rm -f allreports*.txt
\rm -f doc.png
\rm -f ithenticatecookie.txt
\rm -f cookiejar.txt
\rm -f confreport.html
