var fs = require('fs')
var app = require('express')()
var file = process.argv[3]
process.stderr.write("start")
console.error("Books file path: "+file)

app.listen(process.argv[2])

app.get('/books', function(req, res) {
  fs.readFile(file, function (err, data) {
	if(err) return res.send(500);
	try {
	  var books = JSON.parse(data)
	} catch (err) {
	  res.send(500)
	}      
	res.json(books)
  });
});

app.get('/', function(req, res) {
  res.send("<a href='/books'>books</a>")
});


/*

Write a server that reads a file (file name is passed in process.argv[3]), parses it to JSON and outputs the content to the user with res.json(object). Everything should match to the 'books' resource.

For reading, there's an fs module, e.g.,

  fs.readFile(filename, callback)

While the parsing can be done with JSON.parse:

  object = JSON.parse(string)

*/
