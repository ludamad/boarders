/// <reference path="../DefinitelyTyped/sqlite3/sqlite3.d.ts"/>
/// <reference path="../DefinitelyTyped/node-uuid/node-uuid.d.ts"/>

import * as sqlite3 from "sqlite3";
import * as uuid from "node-uuid";
import * as jsutil from "../common/common";

"use strict"; // Enable strict mode.

// Sessions are immutable, so we can cache them:
var _SESSION_CACHE = {};

////////////////////////////////////////////////////////////////////////////////
// Base database connection class. Extending classes define methods specific to 
// our tables. 
// Example usage of raw API: 
//     conn.insert('game_rules', {name: 'Breakthrough'});
//     conn.get 'game_rules', 'name', 'Breakthrough', ([game]) ->
//        console.log(game)
// TODO: Support MySQL, and optimize maybe.
////////////////////////////////////////////////////////////////////////////////

abstract class BaseDatabaseConnection {
    _db: sqlite3.Database = new sqlite3.Database(':memory:');

    _createTable(name : string, members: string): void {
        this._db.run(`CREATE TABLE IF NOT EXISTS ${name}(
            id     INTEGER primary key not null, 
            timestamp DATETIME default current_timestamp,
            ${members}
        )`);
    }

    close(): void {
        this._db.close();
    }

    insert(tableName, data, callback): void {
        var self = this;
        function insertCallback() {
            // assert(this.lastID != null); // Did an insert happen?
            console.log(`${tableName} ${JSON.stringify(data)} ${this.lastID}`);
            self.get(tableName, 'id', this.lastID, callback);
        }
        this._db.serialize( () => {
            var keys = Object.keys(data);
            var vals = keys.map((key) => data[key]);
            var keyString = keys.join(',');
            var questionMarkString = jsutil.arrayWithValueNTimes('?', keys.length).join(",");
            var stmt = this._db.prepare(`insert into ${tableName} (${keyString}) values (${questionMarkString})`);
            stmt.run(vals, callback && insertCallback);
            // )
            stmt.finalize();
        });
    } 
    get(tableName, col, colVal, callback) {
        this.getGeneric(tableName, `${col} = ?`, [colVal], (rows) => {
            callback(rows[0]);
        });
    }

    getGeneric(tableName, whereClause, whereArgs, callback) {
        this._db.serialize( () => {
            var query = `SELECT * from ${tableName} WHERE ${whereClause}`;
            this._db.all(query, ...whereArgs, (error, rows) => {
                // assert(!error);
                callback(rows);
            });
        });
    }
    
    test1() {
        this._db.serialize( () => {
            var stmt = this._db.prepare(`insert into game_rules (name) values (?)`)
            for (name of [`Breakthrough`, `Checkboard`]) {
                stmt.run(name);
            }
            stmt.finalize();
        });
    }
    
    test2() {
        this._db.serialize( () => {
            this._db.each(`SELECT * from game_rules`, (err, row) => {
                console.log(row)
            });
        });
    }
}

////////////////////////////////////////////////////////////////////////////////
// Database utilty functions on top of BaseDatabaseConnection.
////////////////////////////////////////////////////////////////////////////////
export class DatabaseConnection extends BaseDatabaseConnection {
    constructor() {
        super();
        this._db.serialize(this.createTables.bind(this));
    }
    
    newUser(name, callback) {
        this.insert( 'users', {name}, callback);
    }
    
    getUser (db, id, callback) {
        this.get( 'users', 'id', id, callback);
    }
    
    // -- Game instance( creation, querying, joining: -- //);
    newGameInstance(session, rule_id:number, callback) {
        this.insert('game_instances', {rule_id}, (gameInst) => {
            this.joinGameInstance(session, gameInst.id, true);
            if (callback) callback(gameInst);
        });
    }
     
    getGameInstance(game_instance_id, callback) {
        this.get('game_instances', 'id', game_instance_id, callback);
    }
    
    getActiveGameInstances(callback) {
        this.getGeneric('game_instances', 'is_active = 1', [], (data) => {
            console.log(data);
            callback(data);
        });
    }

    getGameInstanceFull(game_instance_id, callback) {
        this.getGameInstance(game_instance_id, (gameInst) => {
            this.getGeneric('game_instance_users', 'game_instance_id = ?', [game_instance_id], (users) => {
                this.getGeneric('game_instance_messages', 'game_instance_id = ?', [game_instance_id], (messages) => {
                    gameInst.users = users;
                    gameInst.messages = messages;
                    callback(gameInst);
                })
            })
        });
    }

    joinGameInstance(session, game_instance_id, is_host, callback?) {
        this.insert('game_instance_users', {game_instance_id, is_host, user_id: session.user_id, player_kind: "bot"}, callback);
    }
    
    storeGameInstanceMessage(session, game_instance_id, message, callback?) {
        this.insert('game_instance_messages', {game_instance_id, message, user_id: session.user_id}, callback);
    }
    
    newSession(user_id, callback) {
        this.insert('sessions', {user_id, uuid: uuid.v4()}, (data) => {
            _SESSION_CACHE[data.id] = data;
            callback(data);
        });
    }
    
    authenticateSession(session, callback) {
        this.get('sessions', "id", session.id, (data) => {
            if (data == null) {
                return callback(false);
            }
            var goodSession = (data.timestamp === session.timestamp) && 
                (data.uuid === session.uuid) && 
                (data.user_id === session.user_id);
            return callback(goodSession);
        })
    }

    getSession(id, callback) {
        if (_SESSION_CACHE[id]) {
            return callback(_SESSION_CACHE[id]);
        } else {
            return this.get('sessions', 'id', id, function(data) {
                _SESSION_CACHE[id] = data;
                return callback(data);
            });
        }
    }

    createTables(): void {
        this._createTable(`users`, `
            name        TEXT not null`);
    
        // user_id is NULL for guests:
        this._createTable(`sessions`, `
            uuid    TEXT not null,
            user_id INTEGER not null,
                foreign key (user_id) references users(id)`
            );
    
        this._createTable(`game_rules`, `
            name        TEXT not null,
            n_players INTEGER not null
        `);
    
        this._createTable(`game_instances`, `
            rule_id INTEGER not null,
            is_active BOOLEAN not null default 1,
            foreign key (rule_id) references game_rules(id)`);
    
        this._createTable(`game_instance_messages`, `
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            message TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        `);
        this._createTable(`game_instance_users`, `
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            is_host BOOLEAN not null,
            player_kind TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        `);
    }    
}
