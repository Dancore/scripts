var trumpet = require('trumpet');
//var fs = require('fs');
var tr = trumpet();
var through = require('through');
var buffer = '';

var tru = through(function (buf) {
  var sbuf = buf.toString()
  var nbuf = sbuf.toUpperCase()
  buffer += sbuf
  this.queue(nbuf)
});

process.stdin.pipe(tr).pipe(process.stdout);

var loud = tr.select('.loud').createStream();
loud.pipe(tru).pipe(loud)

process.stdin.on('end', function () { 
//  console.log("EOL from stdin"); 
//  console.log(buffer)
})
