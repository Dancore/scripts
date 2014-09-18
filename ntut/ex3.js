var path = require('path')
var app = require('express')()
var bodyparser = require('body-parser')

var postHTML = '<html><head><title>Post Example</title></head><body><form method="post">Input 1: <input name="str"><br><input type="submit"></form></body></html>';

app.use(bodyparser.urlencoded({extended: false}))
app.set('view engine', 'jade')
app.set('views', path.join(__dirname, 'templates'))
//app.set('views', process.argv[3])
app.listen(process.argv[2])

app.get('/', function(req, res) {
//  res.render('index', {date: new Date().toLocaleString()})
  res.send("<a href='/form'>form</a>")
});
app.get('/form', function(req, res) {
  res.end(postHTML)
});
app.post('/form', function(req, res) {
  res.end(req.body.str.split('').reverse().join(''))
});

/*
To handle POST request use the post() method which is used the same way as get():

  app.post('/path', function(req, res){...})

Express.js uses middleware to provide extra functionality to your web server.
Simply put, a middleware is a function invoked by Express.js before your own request handler.
Middlewares provide a large variety of functionalities such as logging, serving static files and error handling.
A middleware is added by calling use() on the application and passing the middleware as a parameter.

To parse x-www-form-urlencoded request bodies Express.js can use urlencoded() middleware
from the body-parser module.

  var bodyparser = require('body-parser')
  app.use(bodyparser.urlencoded({extended: false}))

Read more about Connect middleware here:
  https://github.com/senchalabs/connect#middleware
The documentation of the body-parser module can be found here:
  https://github.com/expressjs/body-parser

var postHTML =
  '<html><head><title>Post Example</title></head>' +
  '<body>' +
  '<form method="post">' +
  'Input 1: <input name="str"><br>' +
  '<input type="submit">' +
  '</form>' +
  '</body></html>';

*/
