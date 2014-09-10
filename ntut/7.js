var http = require('http')
var fs = require('fs')
var path = require('path')

var url = process.argv[2]
if( !url ) process.exit()

var req = http.get(url, function(res) {
//  console.log('STATUS: ' + res.statusCode);
//  console.log('HEADERS: ' + JSON.stringify(res.headers));
  res.setEncoding('utf8');
  res.on('data', function (chunk) {
    console.log(chunk);
//    console.log('BODY: ' + chunk);
  });
});

req.on('error', function(e) {
  console.log('problem with request: ' + e.message);
});

//console.log(ret)
