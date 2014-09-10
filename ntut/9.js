var http = require('http')
var argv = process.argv;	// shortcut
if( !argv[2] | !argv[3] | !argv[4] ) process.exit()

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
	callback(null, buffer)
  });
}
function final() { console.log('Done', results); }

for(i = 0; i < 3; i++)
{
 http.get(argv[i+2], function(res){handleresult(res, function(err, data) {
	result_count++;
	console.log(result_count + " got data: " + data) 
	results[i]=data
	if(result_count >= 3)
		final();
 });
 }).on('error', function(e) {
 	console.log('problem with request: ' + e.message);
 });
}
