var http = require('http')
var fs = require('fs')
var map = require('through2-map')
var argv = process.argv;	// shortcut
if( !argv[2] ) process.exit()

var postHTML = 
  '<html><head><title>Post Example</title></head>' +
  '<body>' +
  '<form method="post">' +
  'Input 1: <input name="input1"><br>' +
  'Input 2: <input name="input2"><br>' +
  '<input type="submit">' +
  '</form>' +
  '</body></html>';

function readstr (out) {
  var readstream = fs.createReadStream(argv[3])
  readstream.on('open', function() {
	console.log("stream open")
  });
  readstream.on('error', function(err) {
	console.log(err)
	out.end(err)
  });
  return readstream;
}

function manipstream (instream, out) {
//  instream = readstr(out);
  instream.pipe(map(function (chunk) {
	return chunk.toString().toUpperCase();
//	return chunk.toString().split('').reverse().join('')
  })).pipe(out)
}

var server = http.createServer(function (req, res) {
  var buffer = '';
  console.log('STATUS: ' + res.statusCode);
  console.log(req.method + 'URL: ' +req.url)
//  console.log('HEADERS: ' + JSON.stringify(req.headers));
//  console.log(req)

  if(req.method == "GET")
	res.end(postHTML);
  else if(req.method == "POST") {
	manipstream(req, res);
  }

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
