# Much async ahead. Not for the faint of heart.

require "../globals"

assert = require("assert")
persist = require("../persistApi")


# Fill in with mock data:
# - a game rule object 'breakthrough'
# - users 'ludamad', 'notludamad'
# - create two sessions
mockDbPre = (db, callback) ->
    db.insert 'game_rules', {name: 'Breakthrough', n_players: 2}, () ->
        db.newUser 'ludamad', (user1) ->
            db.newUser 'not.ludamad', (user2) ->
                db.newSession user1.id, (session1) ->
                    db.newSession user2.id, (session2) ->
                        db.session1 = session1 # hack
                        db.session2 = session2 # hack
                        validateMockDbPre(db, callback)

# Validate above mock data.
validateMockDbPre = (db, callback) ->
    get1 db, 'game_rules', 'name = "Breakthrough"', (breakthrough) ->
        assert.equal breakthrough.n_players, 2
        get1 db, 'users', 'name = "ludamad"', () ->
            get1 db, 'users', 'name = "not.ludamad"', () ->
                callback()

# Fill in with mock data:
# - a game instance with the two above users, and a message. 
mockDb = (db, callback) ->
    mockDbPre db, () ->
        get1 db, 'game_rules', 'name = "Breakthrough"', (breakthrough) ->
            db.newGameInstance db.session1, breakthrough.id, (instance) ->
                db.newGameInstance db.session2, breakthrough.id, (instanceOther) ->
                    db.joinGameInstance db.session2, instance.id, false, () ->
                        db.storeGameInstanceMessage db.session2, instance.id, 'This is a sample message from not.ludamad.', () ->
                            validateMockDb db, callback

# Validate above mock data.
validateMockDb = (db, callback) ->
    db.getActiveGameInstances (games) ->
        assert.equal games.length, 2
        db.getGameInstanceFull games[0].id, (entry) ->
            assert.equal entry.users.length, 2
            assert.equal entry.messages.length, 1
            callback()

get1 = (db, tableName, whereClause, callback) ->
    db.getGeneric tableName, whereClause, [], (rows) ->
        assert.equal(rows.length, 1)
        callback(rows[0])

describe 'persist.DatabaseConnection, sqlite3 in memory', () ->
    db = new persist.DatabaseConnection()
    it 'should validate sample data insertion', (doneCallback) ->
        mockDb db, doneCallback