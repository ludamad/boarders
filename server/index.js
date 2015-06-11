#!/bin/node
require("coffee-script/register");

global.print = console.log;

require("./main").serverStart();

