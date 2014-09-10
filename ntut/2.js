// console.log( process.argv )
//process.argv.forEach(function(val, index, array) {

//[0, 1, 2, 3, 4]
var out = process.argv.reduce(function(previousValue, currentValue, index, array) {
// console.log(previousValue + ': ' + currentValue);
if(index<2) return 0
	return (previousValue*1 + currentValue*1)
});
console.log(out)

console.log("alt")
var result = 0
    for (var i = 2; i < process.argv.length; i++)
      result += Number(process.argv[i])
    console.log(result)

