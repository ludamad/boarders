/// <reference path="../DefinitelyTyped/sqlite3/sqlite3.d.ts"/>
/// <reference path="../DefinitelyTyped/node-uuid/node-uuid.d.ts"/>

import * as sqlite3 from "sqlite3";
import * as uuid from "node-uuid";
import {arrayWithValueNTimes, promisify} from "../common/common";

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

    _createTable(name : string, members: string): Promise<void> {
        // Promisifications (compatibility with callback APIs):
        var doRun = promisify(this._db.run.bind(this._db))
        return doRun(`CREATE TABLE IF NOT EXISTS ${name}(
            id     INTEGER primary key not null, 
            timestamp DATETIME default current_timestamp,
            ${members}
        )`);
    }

    close(): void {
        this._db.close();
    }

    async _serializeRest() {
        await promisify(this._db.serialize.bind(this._db));
    }

    async insert(tableName:string, data:any): Promise<any> {
        console.log(":insert:")
        console.log(tableName, data);
        // Promisifications (compatibility with callback APIs):
        var doInsert = promisify<string>((vals, callback) => {
            stmt.run(vals, function(error) {
                console.log(`${tableName} ${JSON.stringify(data)} ${this.lastID}`);
                callback(error, this.lastID);
            });
        });
        // Serialize rest of the commands:
        await this._serializeRest();
        // Insert the data:
        var keys:string[] = Object.keys(data);
        var vals:any[] = keys.map((key) => data[key]);
        var keyString = keys.join(',');
        var questionMarkString = arrayWithValueNTimes('?', keys.length).join(",");
        var stmt = this._db.prepare(`insert into ${tableName} (${keyString}) values (${questionMarkString})`);
        // stmt.finalize();
        var newId:string = await doInsert(vals);
        console.log(`newId ${newId}`);
        return this.get(tableName, 'id', newId);
    }

    async get(tableName:string, col:string, colVal:string): Promise<any> {
        var rows = await this.getGeneric(tableName, `${col} = ?`, [colVal]);
        console.log(":get:");
        console.log(rows);
        return rows[0];
    }

    async getGeneric(tableName, whereClause, whereArgs) {
        // Promisifications (compatibility with callback APIs):
        var doAll = promisify(this._db.all.bind(this._db));
        // Serialize rest of the commands:
        await this._serializeRest();
        var query = `SELECT * from ${tableName} WHERE ${whereClause}`;
        return await doAll(query, ...whereArgs);
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
    
    newUser(name):Promise<any> {
        return this.insert( 'users', {name});
    }

    getUser(db, id):Promise<any> {
        return this.get( 'users', 'id', id);
    }

    // -- Game instance( creation, querying, joining: -- //);
    async newGameInstance(session, rule_id:number):Promise<any> {
        var gameInst = await this.insert('game_instances', {rule_id});
        this.joinGameInstance(session, gameInst.id, true);
        return gameInst;
    }

    getGameInstance(game_instance_id):Promise<any> {
        return this.get('game_instances', 'id', game_instance_id);
    }

    async getActiveGameInstances(): Promise<any> {
        var data = await this.getGeneric('game_instances', 'is_active = 1', []);
        console.log(data);
        return data;
    }

    async getGameInstanceFull(game_instance_id): Promise<any> {
        var gameInst = await this.getGameInstance(game_instance_id);
        var users = await this.getGeneric('game_instance_users', 'game_instance_id = ?', [game_instance_id]);
        var messages = await this.getGeneric('game_instance_messages', 'game_instance_id = ?', [game_instance_id]);
        gameInst.users = users;
        gameInst.messages = messages;
        return gameInst;
    }

    joinGameInstance(session, game_instance_id, is_host):Promise<void> {
        return this.insert('game_instance_users', {game_instance_id, is_host, user_id: session.user_id, player_kind: "bot"});
    }

    storeGameInstanceMessage(session, game_instance_id, message):Promise<any> {
        return this.insert('game_instance_messages', {game_instance_id, message, user_id: session.user_id});
    }

    async newSession(user_id):Promise<any> {
        var session = await this.insert('sessions', {user_id, uuid: uuid.v4()});
        _SESSION_CACHE[session.id] = session;
        return session;
    }

    async authenticateSession(session) {
        var data = await this.get('sessions', "id", session.id);
        if (data === null) {
            return false;
        }
        var goodSession = (data.timestamp === session.timestamp) && 
            (data.uuid === session.uuid) && 
            (data.user_id === session.user_id);
        return goodSession;
    }

    async getSession(id) {
        if (_SESSION_CACHE[id]) {
            return _SESSION_CACHE[id];
        } else {
            var session = await this.get('sessions', 'id', id);
            _SESSION_CACHE[id] = session;
            return session;
        }
    }

    async createTables(): Promise<void> {
        await this._createTable(`users`, `
            name        TEXT not null`);
    
        // user_id is NULL for guests:
        await this._createTable(`sessions`, `
            uuid    TEXT not null,
            user_id INTEGER not null,
                foreign key (user_id) references users(id)`
            );
    
        await this._createTable(`game_rules`, `
            name        TEXT not null,
            n_players INTEGER not null
        `);
    
        await this._createTable(`game_instances`, `
            rule_id INTEGER not null,
            is_active BOOLEAN not null default 1,
            foreign key (rule_id) references game_rules(id)`);
    
        await this._createTable(`game_instance_messages`, `
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            message TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        `);
        await this._createTable(`game_instance_users`, `
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            is_host BOOLEAN not null,
            player_kind TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        `);
    }    
}
