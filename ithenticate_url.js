// Get URL of iThenticate report from the URL created by Crosscheck
// Antonio Luque <aluque@ieee.org> 2019-04-12
// This is a phantom.js script. Use as
// $phantomjs ithenticate_url.js us
// arguments
//    url: Crosscheck url created by the function gotoReport() in the Crosscheck conference listing
// output
//    url sessionid
//    where url us the iThenticate equivalent URL and sessionid is an authentication session id to be used in further calls to API

var system = require('system');
if (system.args.length === 1) {
    console.log('This script needs one argument.');
} else {
    var ccurl=system.args[1];
}

var page = require('webpage').create();

page.open(ccurl, function(status) {
    var convurl = page.evaluate(function() {
            return document.URL;
    });
    var cookies = page.cookies;
  
    for(var i in cookies) {
        if(cookies[i].name=="ithenticate_session") { console.log(convurl+" "+cookies[i].value); }
        //console.log(cookies[i].name+" = "+cookies[i].value);
    }    
    // We need to access the second page in order for iThenticate to believe we are authenticated
    var page2 = require('webpage').create();
        page2.open(convurl, function(status2) {
            page.render('doc.png');
            phantom.exit();
    });
    
});

