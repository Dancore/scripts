var fs = require('fs')
var net = require('net')
var argv = process.argv;	// shortcut
if( !argv[2] ) process.exit()
console.log("trying to listen to port "+argv[2])
var T = new Date()
var year = T.getFullYear()
var mon = T.getMonth()+1
mon = "0"+mon	// ugly hack
var day = T.getDate()
var hour = T.getHours()
var min = T.getMinutes()
if(min < 10) min = "0"+min;
var sec = T.getSeconds()
var date = year+"-"+mon+"-"+day
var time = hour+":"+min
var datetime = date+" "+time

function handlesocket (socket) {
  // socket handling logic
  console.log('server connected');
//  console.log('sending: '+datetime);
//  console.log(date.toString());
//  console.log(date.toISOString());
//  console.log(date.toDateString());
  socket.on('end', function() {
    console.log('server disconnected');
    server.close();
  });
//  socket.write('hello\r\n');
//  socket.pipe(socket);
    socket.end(datetime+'\n');
}
function listener () {
  console.log('server bound');
}

var server = net.createServer(handlesocket);
server.listen(argv[2], listener);
server.on('error', function (e) {
  console.log(e + " code: "+e.code)
  if (e.code == 'EADDRINUSE') {
    console.log('Address in use, retrying...');
	net.connect(argv[2]).on('error', function (e) {
	  console.log(e + " code: "+e.code)
	  fs.unlinkSync(argv[2]);
	  server.listen(argv[2]); //, listener);
	});
	
//    setTimeout(function () {
//      server.close();
//      server.listen(PORT, HOST);
//    }, 1000);
  }
});
