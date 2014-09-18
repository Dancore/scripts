var express = require('express')
var app = express()
app.get('/', function(req, res) {
  res.end('root')
})
app.get('/home', function(req, res) {
  res.end('Hello World!')
})
app.listen(process.argv[2])
