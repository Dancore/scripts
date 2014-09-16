var concat = require('concat-stream');

var cc = concat(function (data) {
  // called when all data is collected and concatinated
  // if(!data) return;  // needed if using write to stdout below
  // process.stdout.write( data.toString().split('').reverse().join('') )
  console.log( data.toString().split('').reverse().join('') )
});
process.stdin.pipe(cc)
