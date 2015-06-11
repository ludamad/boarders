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
            user_id INTEGER,
              foreign key (user_id) references users(id)"

        # 
        @_createTable "game_rules", "
            name      TEXT not null
        "

        @_createTable "active_games", "
            rule_id INTEGER,
            foreign key (rule_id) references game_rules(id)"

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

    get: (tableName, col, colVal, callback) -> @_db.serialize () =>
        query = "SELECT * from #{tableName} WHERE #{col} = ?"
        @_db.all query, colVal, (err, rows) ->
            callback(rows[0])

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

DatabaseConnection::createUser = (name, callback) ->
    @insert 'users', {name}, callback

DatabaseConnection::getUser  = (db, id, callback) ->
    @get 'users', 'id', id, callback

DatabaseConnection::newSession = (user_id, callback) ->
    @insert 'sessions', {user_id, uuid: uuid.v4()}, callback

DatabaseConnection::authenticateSession = (session, callback) ->
    @get 'sessions', {id: session.id}, (data) ->
        goodSession = (data.timestamp == session.timestamp) and
            (data.uuid == session.uuid) and
            (data.user_id == session.user_id) 
        callback(goodSession)

DatabaseConnection::getSession = (id, callback) ->
    @get 'sessions', 'id', id, (data) ->
        _SESSION_CACHE[id] = data
        callback(data)

module.exports = {DatabaseConnection}
