global.print = console.log;

global.assert = function(cond, error) {
	if (!cond) {
		throw new Error(error || "Assertion failed.");
	}
}