/// <reference path="../DefinitelyTyped/node/node.d.ts"/>
/// <reference path="../DefinitelyTyped/express/express.d.ts"/>
/// <reference path="../DefinitelyTyped/cli-color/cli-color.d.ts"/>
/// <reference path="../DefinitelyTyped/body-parser/body-parser.d.ts"/>

"use strict";

import * as common from "./common";

import * as http from 'http';
import * as fs from "fs";
import * as C from 'cli-color';
import * as bodyParser from 'body-parser';

// We sacrifice typing for 'express' because it does not work with ES6-style import.
var express = require('express');

// Handles sessions and database access
import * as persist from "./persistApi";

////////////////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////////////////

var config = {
    SITE_NAME: "Boarders",
    VERSION_MAJOR: '0',
    VERSION_MINOR: '0',
    VERSION_COUNTER: '0',
    PORT: process.env.PORT || 8081
};

////////////////////////////////////////////////////////////////////////////////
// Misc helpers 
////////////////////////////////////////////////////////////////////////////////

function serverPrintInfo() {
    return console.log(C.white('Welcome to') + " " + 
        C.green(config.SITE_NAME) + " " + C.white('server') + " " + 
        "" + C.green("V" + config.VERSION_MAJOR + "." + config.VERSION_MINOR + "." + config.VERSION_COUNTER)
    );
};

////////////////////////////////////////////////////////////////////////////////
// Client connection to the server
////////////////////////////////////////////////////////////////////////////////
class ClientConnection {
    constructor(public socket, public db) {
        console.log("New socket.");
    }

    emit(event, data) {
        return this.socket.emit(event, data);
    }

    newSession(data) {
        console.log("New session.");
        return this.db.newUser(data.name, () => {
            return (user) => {
                return this.db.newSession(user.id, (session) => {
                    return this.emit('newSessionResp', session);
                });
            };
        });
    }
}

function setupApp(app) {
    // // Handle HTTP requests as JSON:
    // // parse application/x-www-form-urlencoded 
    // app.use(bodyParser.urlencoded({ extended: false }));

    // // parse application/json 
    // app.use(bodyParser.json());
    return app.use(express["static"](__dirname + '/build'));
}

function createApp() {
    var app, db, io, server;
    app = express();
    setupApp(app);
    server = require('http').createServer(app);
    io = require('socket.io')(server);
    // The persist module is used for all our data access:
    db = new persist.DatabaseConnection();
    db.insert('game_rules', {
        name: 'Breakthrough',
        n_players: 2
    });
    server.listen(config.PORT, () => {
        return serverPrintInfo();
    });
    return io.on('connection', (socket) => {
        // Create client objects for each connection socket:
        var connection = new ClientConnection(socket, db);
        for (var method of ['newSession']) {
            socket.on(method, connection[method].bind(connection));
        }
        return connection.emit('mock_data', ["One", "three", "blue"]);
    });
}

createApp();
