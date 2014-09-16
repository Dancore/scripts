var http = require('http');
var through = require('through');
var buffer = '';

var tr = through(function (buf) {
  var sbuf = buf.toString()
  var nbuf = sbuf.toUpperCase()
  buffer += sbuf
  this.queue(nbuf)
});

var server = http.createServer(function (req, res) {
  console.log('STATUS: ' + res.statusCode);
  console.log(req.method + 'URL: ' +req.url)

  if (req.method === 'POST') {
	req.pipe(tr).pipe(res)
//	console.log('POSTed: '+req.pipe(tr).pipe(process.stdout))
  }
  res.end('send me a POST\n');

  req.on('end', function () {
	console.log('POSTed: ' + buffer);
  });
});
server.listen(parseInt(process.argv[2]));
