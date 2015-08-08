// Much async ahead. Not for the faint of heart.
declare var describe, require, before, it;

var {assert} = require('chai');
require('chai').config.includeStack = true;

import * as persist from "../server/persistApiPromised";

// Fill in with mock data:
// - a game rule object 'breakthrough'
// - users 'ludamad', 'notludamad'
// - create two sessions
async function mockDbPre(db:persist.DatabaseConnection) {
    await db.insert("game_rules", {
        name: "Breakthrough",
        n_players: 2
    });
    var user1 = await db.newUser("ludamad");
    var user2 = await db.newUser("not.ludamad");
    var session1 = await db.newSession(user1.id);
    var session2 = await db.newSession(user2.id);
    (<any>db).session1 = session1;  // hack
    (<any>db).session2 = session2;  // hack
    await validateMockDbPre(db);
}

// Validate above mock data.
async function validateMockDbPre(db:persist.DatabaseConnection) {
    var breakthrough = await get1(db, "game_rules", "name = \"Breakthrough\""); 
    assert.equal(breakthrough.n_players, 2);
    var user1 = await get1(db, "users", "name = \"ludamad\"");
    var user2 = await get1(db, "users", "name = \"not.ludamad\"");
    assert.ok(user1);
    assert.ok(user2);
}

// Fill in with mock data:
// - a game instance with the two above users, and a message.
async function mockDb(db:persist.DatabaseConnection) {
    await mockDbPre(db);
    // var breakthrough = await get1(db, "game_rules", "name = \"Breakthrough\"");
    // var instance = await db.newGameInstance((<any>db).session1, breakthrough.id);
    // var instanceOther = await db.newGameInstance((<any>db).session2, breakthrough.id);
    // await db.joinGameInstance((<any>db).session2, instance.id, false);
    // await db.storeGameInstanceMessage((<any>db).session2, instance.id, "This is a sample message from not.ludamad.");
    // await validateMockDb(db);
}

// Validate above mock data.
async function validateMockDb(db:persist.DatabaseConnection) {
    var games = await db.getActiveGameInstances();
    assert.equal(games.length, 2);

    var entry = await db.getGameInstanceFull(games[0].id);
    assert.equal(entry.users.length, 2);
    assert.equal(entry.messages.length, 1);
}

async function get1(db:persist.DatabaseConnection, tableName:string, whereClause:string):Promise<any> {
    var rows = await db.getGeneric(tableName, whereClause, []);
    assert.equal(rows.length, 1);
    return rows[0];
}

describe("persist.DatabaseConnection, sqlite3 in memory", () => {
    var db = new persist.DatabaseConnection();
    return it("should validate sample data insertion", () => mockDb(db));
});
