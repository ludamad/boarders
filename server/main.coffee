"use strict" # Enable strict mode.

################################################################################
# Includes 
################################################################################

http = require('http')
express = require('express')
fs = require "fs"
C = require 'cli-color'
bodyParser = require 'body-parser'

# Handles sessions and database access
persist = require "./Persistence"

################################################################################
# Configuration
################################################################################

config = {
    SITE_NAME: "Boarders"
    VERSION_MAJOR: '0'
    VERSION_MINOR: '0'
    VERSION_COUNTER: '0'
    PORT: (process.env.PORT or 8081)
}

################################################################################
# Misc helpers 
################################################################################

serverPrintInfo = () ->
    print "#{C.white 'Welcome to'} #{C.green config.SITE_NAME} #{C.white 'server'} " + 
        "#{C.green "V#{config.VERSION_MAJOR}.#{config.VERSION_MINOR}.#{config.VERSION_COUNTER}"}"

################################################################################
# Server class
################################################################################

class SocketIoConnection
    constructor: (@socket) ->
        print "New socket."

    newSession: () ->
        print "New session."

setupApp = (app) ->
    app.use(express.static(__dirname + '/build'))
    # Handle HTTP requests as JSON:
    # parse application/x-www-form-urlencoded 
    app.use(bodyParser.urlencoded({ extended: false }))

    # parse application/json 
    app.use(bodyParser.json())
    #require("GameRequestApi").setup(app)
    #require("").setupGameRestApi(app)

createApp = () ->
    app = express()
    setupApp(app)
    server = require('http').createServer(app)
    io = require('socket.io')(server)
    # The persist module is used for all our data access:
    conn = new persist.DatabaseConnection()
    conn.insert 'game_rules', {name: 'Breakthrough'}
    conn.get 'game_rules', 'name', 'Breakthrough', ([game]) ->
        console.log(game)

    server.listen config.PORT, () ->
        serverPrintInfo()
    io.on 'connection', (socket) -> 
        # Create socket objects for each connection:
        connection = new SocketIoConnection(socket)
        for method in ['newSession']
            socket.on method, connection[method]

################################################################################
# Exported module.
#   serverStart: Server entry point.
################################################################################

module.exports = {
    serverStart: () ->
        createApp()
}
