express = require('express')
app = express()
app.use(express.static(__dirname + '/public'));
server = require('http').createServer(app)
io = require('socket.io')(server)
port = process.env.PORT || 8081

C = require 'cli-color'
sexp = require("./sexp")

sys = require("sys")
fs = require("fs");
#console.log(JSON.stringify(SExp.parse("(1 2 3 4)")));

M = {}
global.Boarders = M
global.print = console.log

SITE_NAME = "Boarders"
VERSION_MAJOR = '0'
VERSION_MINOR = '0'
VERSION_COUNTER = '0'

content = fs.readFileSync("crazyhouse.zrf", "utf8")
print(content)


M.serverStart = () ->
    print "#{C.white 'Welcome to'} #{C.green SITE_NAME} #{C.white 'server'} #{C.green "V#{VERSION_MAJOR}.#{VERSION_MINOR}.#{VERSION_COUNTER}"}"

    server.listen port, () ->
      print("Server listening at port #{C.green port}")


