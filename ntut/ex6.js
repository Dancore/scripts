var crypto = require('crypto')
//var path = require('path')
//var express = require('express')
var app = require('express')()

app.listen(process.argv[2])

app.put('/message/:id', function(req, res) {
  var h = crypto.createHash('sha1')
    .update(new Date().toDateString() + req.params.id)
    .digest('hex')
  res.send(h)
});

app.get('/', function(req, res) {
  res.send("<a href='/form'>form</a>")
});


/*

Create an Express.js server that processes PUT '/message/:id' requests, e.g., PUT '/message/526aa677a8ceb64569c9d4fb'

As the response of this request return id SHA1 hashed with a date:

  require('crypto')
    .createHash('sha1')
    .update(new Date().toDateString() + id)
    .digest('hex')


-----------------------------

HINTS

To handle PUT requests use:

  app.put('/path/:NAME', function(req, res){...});

To extract parameters from within the request handlers, use:

  req.params.NAME

*/
