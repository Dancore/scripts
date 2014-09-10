var dir = process.argv[2]
var ext = process.argv[3]

//if( !dir ) process.exit()
//if( !ext ) process.exit()

var mymod = require("./6-mymod.js");

mymod(dir, ext, function(err, filtlist){
if(err) throw err;

// testing some different output options:
//console.log(filtlist.length)
//console.log(filtlist)
//console.log(filtlist.toString())
console.log(filtlist.join("\n"))

});

