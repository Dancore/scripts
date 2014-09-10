var fs = require('fs')
var file= process.argv[2]
var data = fs.readFileSync(file)
//console.log(data);
var datastr=data.toString()
//console.log(datastr);
var lines = datastr.split('\n')
//console.log(lines)
//console.log(lines.length -1)

//console.log("alt")

var alt = fs.readFileSync(process.argv[2], 'utf8').split('\n').length - 1
console.log(alt)

