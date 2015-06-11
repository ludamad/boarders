# The headless client is used to test the REST api separately from the GUI.

"use strict" # Enable strict mode.

################################################################################
# Includes 
################################################################################

C = require 'cli-color'
io = require('socket.io-client')

################################################################################
# Configuration
################################################################################

config = {
    HOST: "http://localhost"
}

################################################################################
# Connection abstraction.
################################################################################

class Connection 
    constructor: (@socket) ->
        print 'New command line user connection.'
    emitOnce: (eventName, data, callback) ->
        @socket.on "#{eventName}Resp", callback.bind(@)
        @socket.emit eventName, data

connect = (host, callback) -> 
    socket = io(host)
    socket.on 'connect', () ->
        con = new Connection(socket)
        callback?(con)

################################################################################
# Ad-hoc tests.
################################################################################

connect "http://localhost:8081", (con) ->
    con.emitOnce 'newSession', {name: 'ludamad'}, (info) ->
        print 'Got new session (and user ID).'
        print info
        @session = session

    print "Connected."
