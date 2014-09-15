var argv = process.argv
var fs = require('fs');
if(!argv[2]) process.exit()

fs.createReadStream(argv[2]).pipe(process.stdout);
