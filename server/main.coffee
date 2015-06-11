# Main entry point. Runs the server.

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
persist = require "./persistApi"

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

class ClientConnection
    constructor: (@socket, @db) ->
        print "New socket."
    emit: (event, data) -> 
        @socket.emit event, data
    newSession: (data) ->
        print "New session."
        @db.createUser data.name, (user) =>
            @db.newSession user.id, (session) =>
                @emit('newSessionResp', session)

setupApp = (app) ->
    app.use(express.static(__dirname + '/build'))
    # Handle HTTP requests as JSON:
    # parse application/x-www-form-urlencoded 
    app.use(bodyParser.urlencoded({ extended: false }))

    # parse application/json 
    app.use(bodyParser.json())

createApp = () ->
    app = express()
    setupApp(app)
    server = require('http').createServer(app)
    io = require('socket.io')(server)
    # The persist module is used for all our data access:
    db = new persist.DatabaseConnection()

    server.listen config.PORT, () ->
        serverPrintInfo()
    io.on 'connection', (socket) -> 
        # Create client objects for each connection socket:
        connection = new ClientConnection(socket, db)
        for method in ['newSession']
            socket.on method, connection[method].bind(connection)

createApp()