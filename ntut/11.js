var http = require('http')
var fs = require('fs')
var argv = process.argv;	// shortcut
if( !argv[2] | !argv[3] ) process.exit()

var results = [];
var result_count = 0;

function handleresult(res, callback) {
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
//	console.log(buffer.length)
//	console.log(buffer.length +' nr of chars in the data: ' + buffer)
//	console.log(buffer)
	callback(buffer)
  });
}
function final() { console.log(results.join('\n')); }

function httpGet(ind) {
 http.get(argv[ind+2], function(res){ handleresult(res, function(data) {
//	console.log(result_count + " ind "+ind+" got data: " + data) 
	results[ind]=data
	result_count++;
	if(result_count >= 3)
		final();
 });
 }).on('error', function(e) {
 	console.log('problem with request: ' + e.message);
 });
}

//for(i = 0; i < 3; i++) httpGet(i)

var server = http.createServer(function (req, res) {
  // request handling logic...
  console.log('STATUS: ' + res.statusCode);
  console.log('Request URL: ' +req.url)
//  console.log('HEADERS: ' + JSON.stringify(req.headers));
//  console.log(req)

  var readstream = fs.createReadStream(argv[3])
  readstream.on('open', function() {
	console.log("stream open")
	readstream.pipe(res);
  });

  readstream.on('error', function(err) {
	console.log(err)
	res.end(err)
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

