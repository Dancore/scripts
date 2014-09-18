var crypto = require('crypto')
//var path = require('path')
//var express = require('express')
var app = require('express')()

app.listen(process.argv[2])

app.get('/search', function(req, res) {
  res.send(req.query)
});

app.get('/', function(req, res) {
  res.send("<a href='/form'>form</a>")
});


/*

Write a route that extracts data from query string in the GET '/search' URL route, e.g.,
?results=recent&include_tabs=true, and then outputs it back to the user in JSON format.

-----------------------------

HINTS

In Express.js to extract query string parameters, we can use:

  req.query.NAME

To output json we can use, res.send(object).


*/
