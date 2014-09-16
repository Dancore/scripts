var duplex = require('duplexer');
var through = require('through')

module.exports = function (counter) {
  // return a duplex stream to capture countries on the writable side
  // and pass through `counter` on the readable side
  var counts = {}
  var tru = through(count, end)  
  return duplex(tru, counter)

  function count(obj) {
	counts[obj.country] = (counts[obj.country] || 0) + 1
  }
  function end() {
	counter.setCounts(counts)
  }

};
