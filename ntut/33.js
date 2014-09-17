var combine = require('stream-combiner')
//var duplex = require('duplexer')
var through = require('through')
var zlib = require('zlib')
var split = require('split');

// to test if an object is empty, i.e. "{}"
function isEmpty(obj) {
  return Object.keys(obj).length === 0;
}

module.exports = function () {
  var genres = 0
  var genre = {}
  var jsonstr = ''
  var tr = through(dostuff, end)  
     // read newline-separated json,
     // group books into genres,
     // then gzip the output
  return combine( split(), tr, zlib.createGzip() );

  function dostuff(row) {
	console.log(row)
	if( row ){
	  var obj = JSON.parse(row)
//	  console.log(obj.type)
	  if(obj.type === "genre") {
		genres++;
		if(!isEmpty(genre)){
		  jsonstr += JSON.stringify(genre)
		  if(genres > 1) jsonstr += '\n'
		}
		genre = {}
		genre["name"] = obj.name
		genre["books"] = []
	  }
	  else if(obj.type === "book") {
		genre.books[genre.books.length] = obj.name
	  }
//	  console.log(genre)
	}
  }
  function end() {
	jsonstr += JSON.stringify(genre)
	console.log("END")
	console.log(jsonstr)
	this.queue(jsonstr)
	this.queue('\n')
	this.queue(null)
  }
};

/*
Your stream will be written a newline-separated JSON list of science fiction
genres and books. All the books after a `"type":"genre"` row belong in that
genre until the next `"type":"genre"` comes along in the output.

    {"type":"genre","name":"cyberpunk"}
    {"type":"book","name":"Neuromancer"}
    {"type":"book","name":"Snow Crash"}
    {"type":"genre","name":"space opera"}
    {"type":"book","name":"A Deepness in the Sky"}
    {"type":"book","name":"Void"}

Your program should generate a newline-separated list of JSON lines of genres,
each with a `"books"` array containing all the books in that genre. The input
above would yield the output:

    {"name":"cyberpunk","books":["Neuromancer","Snow Crash"]}
    {"name":"space opera","books":["A Deepness in the SKy","Void"]}

Your stream should take this list of JSON lines and gzip it with
`zlib.createGzip()`.
*/
