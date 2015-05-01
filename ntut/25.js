var through = require('through');
var split = require('split');

var lines = 0;

var tr = through( function (buf) {
  lines++;
  if(lines %2 === 0)
	  this.queue(buf.toString().toUpperCase()+'\n')
  else
	  this.queue(buf.toString().toLowerCase()+'\n')
});

process.stdin.pipe(split()).pipe(tr).pipe(process.stdout);
