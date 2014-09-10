//console.log("helo")
//process.exit()

var fs = require('fs')
var path = require('path')
//console.log("got " + dir)

module.exports = function(dir, ext, callback)
{
if( !dir ) 
	return callback("no dir") // early return
if( !ext ) 
	return callback("no ext")

var flist = [];


 fs.readdir(dir, function(err, files) 
 {
  if(err) return callback(err);
//  var filtlist = [];
  files.forEach(function(elem, i, arr)
  {
	var ex = path.extname(elem)
	if (path.extname(elem) === "." + ext){
		flist[flist.length] = elem
//		console.log(elem)
	}
  });
  callback(null, flist)
  
 });



};


// example
//    function bar (callback) {
//      foo(function (err, data) {
//        if (err)
//          return callback(err) // early return

        // ... no error, continue doing cool things with `data`

        // all went well, call callback with `null` for the error argument

//        callback(null, data)
//      })
//    }

