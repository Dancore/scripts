var http = require('http')
var fs = require('fs')
var map = require('through2-map')
var url = require('url')
var argv = process.argv;	// shortcut
if( !argv[2] ) process.exit()

var server = http.createServer(function (req, res) {
  console.log('STATUS: ' + res.statusCode);
  console.log(req.method + 'URL: ' +req.url)
//  console.log('HEADERS: ' + JSON.stringify(req.headers));
//  console.log(req)

  if( argv[3] )  // debug test
  	var urlObj = url.parse(argv[3], true)
  else
  	var urlObj = url.parse(req.url, true)

  switch(urlObj.pathname) {
  case "/api/parsetime":
	console.log(urlObj.pathname)
//	console.log(urlObj.query.iso)
	var T = new Date(urlObj.query.iso)
	var hour = T.getHours()
	var min = T.getMinutes()
	var sec = T.getSeconds()
	var timeObj = {hour:T.getHours(), minute:T.getMinutes(), second:T.getSeconds()}
	var jstr = JSON.stringify(timeObj)
	console.log(timeObj)
//	console.log(jstr)
	res.writeHead(200, { 'Content-Type': 'application/json' })
	res.end(jstr)
  	break;
  case "/api/unixtime":
	console.log(urlObj.pathname)
	var T = new Date(urlObj.query.iso)
	var timestamp = T.getTime()
	var timeObj = {"unixtime":timestamp}
	var jstr = JSON.stringify(timeObj)
	console.log(timeObj)
	res.writeHead(200, { 'Content-Type': 'application/json' })
	res.end(jstr)	
  	break;
  default:
	res.writeHead(404)
	res.end()
	console.log("404: Unknown URL path "+ urlObj.pathname)
  }

//  console.log(urlObj)

  req.on('data', function (chunk) {
	if(req.method == "POST") buffer += chunk
//	console.log('chunk: ' + chunk);
  });
  req.on('end', function () {
	if(req.method == "POST")
	  console.log('POSTed: ' + buffer);
  });

  res.on('data', function(chunk) {
	console.log("BODY: "+chunk.toString())
  });

});
server.listen(argv[2])
server.on('error', function(e) {
 	console.log('problem with request: ' + e.message);
});
server.on('connection', function() {
	console.log("connected")
});
