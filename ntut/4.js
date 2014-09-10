//console.log("helo")
//process.exit()

var fs = require('fs')
var file= process.argv[2]
if( !file ) process.exit()

var alt = fs.readFile(file, 'utf8', function (err, data) {
 if(err) throw err;
 var ret = data.split('\n').length - 1
 console.log(ret)
});
// console.log(alt)
