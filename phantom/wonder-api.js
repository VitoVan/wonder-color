#!/usr/bin/phantomjs --web-security=false
var serverBase = "http://wc.vitovan.vito/"
var system = require('system');
if (system.args.length === 1) {
    console.log('Usage: wonder-api.js <query text>');
    phantom.exit();
}
queryText = system.args[1];//.replace(/ /g,"+");
var page = require('webpage').create();
page.onConsoleMessage = function(msg) {
    if(msg === 'PHANTOM:EXIT'){
        phantom.exit();
    }else{
        console.log(msg);
    }
};
page.open(serverBase + 'wonder-api-html', 'post', 'text=' + encodeURI(queryText), function(status) {
    if (status !== 'success') {
        console.log('Unable to post!');
        console.log('PHANTOM:EXIT');
    }
});
setTimeout(function(){
    phantom.exit();
},10000);
