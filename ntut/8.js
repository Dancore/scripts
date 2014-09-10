var http = require('http')
var fs = require('fs')
var path = require('path')

var url = process.argv[2]
if( !url ) process.exit()

var req = http.get(url, function(res) {
	var buffer = '';
	var chunks = 0;
//  console.log('STATUS: ' + res.statusCode);
//  console.log('HEADERS: ' + JSON.stringify(res.headers));
  res.setEncoding('utf8');
  res.on('data', function (chunk) {
	chunks++;
	buffer += chunk;
  });
  res.on('end', function() {
//	console.log('Got END after ' + chunks + ' nr of chunks');
	console.log(buffer.length)
//	console.log(buffer.length +' nr of chars in the data: ' + buffer)
	console.log(buffer)
  });
});

req.on('error', function(e) {
  console.log('problem with request: ' + e.message);
});
