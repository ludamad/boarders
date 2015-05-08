M = {}
global.Boarders = M
global.print = console.log

express = require('express')
app = express()
app.use(express.static(__dirname + '/public'));
server = require('http').createServer(app)
io = require('socket.io')(server)
port = process.env.PORT || 8081

fs = require "fs"

C = require 'cli-color'
P = require("./client/zrfparser")

SITE_NAME = "Boarders"
VERSION_MAJOR = '0'
VERSION_MINOR = '0'
VERSION_COUNTER = '0'

M.serverStart = () ->
    print "#{C.white 'Welcome to'} #{C.green SITE_NAME} #{C.white 'server'} #{C.green "V#{VERSION_MAJOR}.#{VERSION_MINOR}.#{VERSION_COUNTER}"}"

    server.listen port, () ->
        print("Server listening at port #{C.green port}")

    content = fs.readFileSync("tictactoe.zrf", "utf8")
    P.parse(content).print()

