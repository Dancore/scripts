var through = require('through');
//var tr = through(write, end);
var tr = through(write);
//tr.write('beep\n');
//tr.write('boop\n');
//tr.end();

function write (buf) {
  this.queue(buf.toString().toUpperCase())
//  console.dir(buf) 
}
//function end () { console.log('__END__') }

/*
Instead of calling `console.dir(buf)`, your code should use `this.queue()` in
your `write()` function to output upper-cased data.

Don't forget to feed data into your stream from stdin and output data from
stdout, which should look something like:
*/

process.stdin.pipe(tr).pipe(process.stdout);

