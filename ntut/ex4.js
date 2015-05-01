var path = require('path')
var express = require('express')
var app = require('express')()

app.use(express.static(process.argv[3] || path.join(__dirname, 'public')));
app.listen(process.argv[2])

/*

./public/index.html:
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="/main.css"/>
  </head>
  <body>
    <p>I am red!</p>
  </body>
</html>

./public/main.css:
p { color: red }

*/
