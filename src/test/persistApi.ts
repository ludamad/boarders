// Much async ahead. Not for the faint of heart.
declare var describe, require, before, it;

var {assert} = require('chai');
require('chai').config.includeStack = true;

import * as persist from "../server/persistApi";

// Fill in with mock data:
// - a game rule object 'breakthrough'
// - users 'ludamad', 'notludamad'
// - create two sessions
function mockDbPre(db:persist.DatabaseConnection, callback) {
    return db.insert("game_rules", {
        name: "Breakthrough",
        n_players: 2
    }, () => db.newUser("ludamad", (user1) => db.newUser("not.ludamad", (user2) => db.newSession(user1.id, (session1) => db.newSession(user2.id, (session2) => {
        (<any>db).session1 = session1;  // hack
        (<any>db).session2 = session2;  // hack
        return validateMockDbPre(db, callback);
    })))));
}

// Validate above mock data.
function validateMockDbPre(db:persist.DatabaseConnection, callback) {
    return get1(db, "game_rules", "name = \"Breakthrough\"", (breakthrough) => {
        assert.equal(breakthrough.n_players, 2);
        return get1(db, "users", "name = \"ludamad\"", () => get1(db, "users", "name = \"not.ludamad\"", () => callback()));
    });
}

// Fill in with mock data:
// - a game instance with the two above users, and a message.
function mockDb(db:persist.DatabaseConnection, callback) {
    return mockDbPre(db, () => 
        get1(db, "game_rules", "name = \"Breakthrough\"", (breakthrough) => 
            db.newGameInstance((<any>db).session1, breakthrough.id, (instance) => 
                db.newGameInstance((<any>db).session2, breakthrough.id, (instanceOther) => 
                    db.joinGameInstance((<any>db).session2, instance.id, false, () => 
                        db.storeGameInstanceMessage((<any>db).session2, instance.id, "This is a sample message from not.ludamad.", () => 
                            validateMockDb(db, callback)))))));
}

// Validate above mock data.
function validateMockDb(db:persist.DatabaseConnection, callback) {
    return db.getActiveGameInstances((games) => {
        assert.equal(games.length, 2);
        return db.getGameInstanceFull(games[0].id, (entry) => {
            assert.equal(entry.users.length, 2);
            assert.equal(entry.messages.length, 1);
            return callback();
        });
    });
}

function get1(db:persist.DatabaseConnection, tableName, whereClause, callback) {
    return db.getGeneric(tableName, whereClause, [], (rows) => {
        assert.equal(rows.length, 1);
        return callback(rows[0]);
    });
}

describe("persist.DatabaseConnection, sqlite3 in memory", () => {
    var db;
    db = new persist.DatabaseConnection();
    return it("should validate sample data insertion", (doneCallback) => mockDb(db, doneCallback));
});
