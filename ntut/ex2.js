var path = require('path')
var express = require('express')
var app = express()
app.get('/', function(req, res) {
  res.end("<a href='/home'>home</a>")
});
app.get('/home', function(req, res) {
//  res.render('index', {date: new Date().toDateString()})
  res.render('index', {date: new Date().toLocaleString()})
  // res.end('Hello World!')
});
app.listen(process.argv[2])

app.set('view engine', 'jade')
app.set('views', path.join(__dirname, 'templates'))
//app.set('views', process.argv[3])

/*
Jade template file index.jade is already provided:

  h1 Hello World
  p Today is #{date}.

This is how to specify path in a typical Express.js app considering that the folder is 'templates':

  app.set('views', path.join(__dirname, 'templates'))

However, to use our index.jade, the path to index.jade will be provided in the process.argv[3] value. You are welcome to use your own jade file!

To tell Express.js app what template engine to use, apply this line to Express.js configuration:

  app.set('view engine', 'jade')

Instead of Hello World's res.end, the res.render function accepts filename and data:

  res.render('index', {date: new Date().toDateString()})
*/
