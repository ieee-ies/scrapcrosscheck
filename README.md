# scrapCrosscheck
Scripts to scrap Crosscheck reports for a conference and download the reports for offline use.

# Usage
Run the the script `./scrapCrosscheck.sh`.
You will be asked for the Crosscheck URL, your IEEE login and password.

The scripts will download only the flagged papers (indicated with a red color in the Crosscheck report and similarity index above the threshold).
The downloaded Crosscheck reports can be found in the same directory as report_similarityIndex_TFxxx.pdf

# Requirements

Several utils are needed for these scripts to work. Most of them should already exist for non-windows based machines.
The utils needed are: Bash, perl, [curl](https://curl.haxx.se/), [phantom.js](http://www.phantomjs.org), sed, awk, [jq](https://stedolan.github.io/jq/)


In Linux/Unix-based systems
```bash
sudo apt-get install curl phantomjs perl jq
```


In MacOS via brew:
```
brew install curl jq && \
brew install phantomjs
```

# Limitations
There are very few error checks. It will probably fail miserably in cases which are not completely standard. Nevertheless, much information is displayed on screen, which makes finding the failure cause easy.
