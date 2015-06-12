# Runs the server 

"use strict" # Enable strict mode.

################################################################################
# Includes 
################################################################################

sqlite3 = require("sqlite3").verbose()
uuid = require "node-uuid"

################################################################################
# Database connection class, with methods specific to our tables. 
################################################################################

class DatabaseConnection
    constructor: () ->
        @_db = new sqlite3.Database(':memory:')
        @_db.serialize(@createTables.bind(@))

    _createTable: (name, members) ->
        @_db.run "CREATE TABLE IF NOT EXISTS #{name}(
            id     INTEGER primary key not null, 
            timestamp DATETIME default current_timestamp,
            #{members})"

    createTables: () ->
        @_createTable "users", "
            name      TEXT not null"

        # user_id is NULL for guests:
        @_createTable "sessions", "
            uuid    TEXT not null,
            user_id INTEGER not null,
              foreign key (user_id) references users(id)"

        # 
        @_createTable "game_rules", "
            name      TEXT not null,
            n_players INTEGER not null
        "

        @_createTable "game_instances", "
            rule_id INTEGER not null,
            is_active BOOLEAN not null default 1,
            foreign key (rule_id) references game_rules(id)"

        @_createTable "game_instance_messages", "
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            message TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        "
        @_createTable "game_instance_users", "
            game_instance_id INTEGER not null,
            user_id INTEGER not null,
            is_host BOOLEAN not null,
            player_kind TEXT not null,
            foreign key (game_instance_id) references game_instances(id),
            foreign key (user_id) references users(id)
        "
    close: () ->
        @_db.close()

    insert: (tableName, data, callback) -> @_db.serialize () =>
        keys = Object.keys(data)
        stmt = @_db.prepare("insert into #{tableName} (#{keys.join ','}) " + 
            "values (#{('?' for key in keys).join ','})")
        vals = (data[key] for key in keys)
        that = @
        stmt.run.call(stmt, vals, 
            # Resolves to 'undefined' if callback is 'undefined':
            callback and (error) -> 
                assert @lastID? # Did an insert happen?
                print "#{tableName} #{JSON.stringify data} #{@lastID}"
                that.get tableName, 'id', @lastID, callback
        )
        stmt.finalize()

    get: (tableName, col, colVal, callback) -> 
        @getGeneric tableName, "#{col} = ?", [colVal], (rows) ->
            callback(rows[0])

    getGeneric: (tableName, whereClause, whereArgs, callback) -> @_db.serialize () =>
        query = "SELECT * from #{tableName} WHERE #{whereClause}"
        @_db.all query, whereArgs..., (error, rows) ->
            assert(not error)
            callback(rows)

    # Temporary
    test1: () -> @_db.serialize () =>
        stmt = @_db.prepare("insert into game_rules (name) values (?)")
        for name in ["Breakthrough", "Checkboard"]
            stmt.run(name)
        stmt.finalize()

    test2: () -> @_db.serialize () =>
        @_db.each "SELECT * from game_rules", (err, row) ->
            console.log(row)

# Sessions are immutable, so we can cache them:
_SESSION_CACHE = {}

################################################################################
# Database utilty functions. Use these.
# TODO: Move to MySQL, and optimize maybe.
################################################################################

# Example usage of raw API: 
#conn.insert 'game_rules', {name: 'Breakthrough'}
#conn.get 'game_rules', 'name', 'Breakthrough', ([game]) ->
#    console.log(game)

DatabaseConnection::newUser = (name, callback) ->
    @insert 'users', {name}, callback

DatabaseConnection::getUser  = (db, id, callback) ->
    @get 'users', 'id', id, callback

# -- Game instance creation, querying, joining: -- #
DatabaseConnection::newGameInstance = (session, rule_id, params, callback) ->
    @insert 'game_instances', {rule_id: params.rule_id}, (gameInst) =>
        @joinGameInstance(session, gameInst.id, true)
        callback?(gameInst)

DatabaseConnection::getGameInstance = (game_instance_id, callback) ->
    @get 'game_instances', 'id', game_instance_id, callback

DatabaseConnection::getActiveGameInstances = (callback) ->
    @getGeneric 'game_instances', 'is_active = 1', [], (data) ->
        print(data)
        callback(data)

DatabaseConnection::getGameInstanceFull = (game_instance_id, callback) ->
    @getGameInstance game_instance_id, (gameInst) =>
        @getGeneric 'game_instance_users', 'game_instance_id = ?', [game_instance_id], (users) =>
            @getGeneric 'game_instance_messages', 'game_instance_id = ?', [game_instance_id], (messages) =>
                gameInst.users = users
                gameInst.messages = messages
                callback(gameInst)

DatabaseConnection::joinGameInstance = (session, game_instance_id, is_host, callback) ->
    @insert 'game_instance_users', {game_instance_id, is_host, user_id: session.user_id}, callback

DatabaseConnection::storeGameInstanceMessage = (session, game_instance_id, message, callback) ->
    @insert 'game_instance_messages', {game_instance_id, message, user_id: session.user_id}, callback

DatabaseConnection::newSession = (user_id, callback) ->
    @insert 'sessions', {user_id, uuid: uuid.v4()}, (data) ->
        _SESSION_CACHE[data.id] = data
        callback(data)

DatabaseConnection::authenticateSession = (session, callback) ->
    @get 'sessions', {id: session.id}, (data) ->
        if not data?
            return callback(goodSession)
        goodSession = (data.timestamp == session.timestamp) and
            (data.uuid == session.uuid) and
            (data.user_id == session.user_id) 
        callback(goodSession)

DatabaseConnection::getSession = (id, callback) ->
    if _SESSION_CACHE[id]
        callback(_SESSION_CACHE[id])
    else
        @get 'sessions', 'id', id, (data) ->
            _SESSION_CACHE[id] = data
            callback(data)

module.exports = {DatabaseConnection}
