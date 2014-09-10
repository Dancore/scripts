//console.log("helo")
//process.exit()

var fs = require('fs')
var path = require('path')
var dir = process.argv[2]
if( !dir ) process.exit()
var ext = process.argv[3]
if( !ext ) process.exit()
//console.log("got " + dir)

function filterext(err, files) {
 if(err) throw err;
 var ret = files.forEach(function(elem, i, arr)
 {
	var ex = path.extname(elem)
	if (path.extname(elem) === "." + ext)
	console.log(elem)
//		return;
 });
}

var ret = fs.readdir(dir, filterext);
//console.log(ret)

// fake:
//console.log("CHANGELOG.md")
//console.log("LICENCE.md")
//console.log("README.md")
