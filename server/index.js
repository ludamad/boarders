#!/bin/node
require("coffee-script/register");

global.print = console.log;

global.assert = function(cond, error) {
	if (!cond) {
		throw new Error(error || "Assertion failed.");
	}
}

if (process.env.TEST === "1") {
	require("./tests/test_persistApi.coffee")
} else {
	require("./main");
}

