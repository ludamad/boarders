declare var describe, require, before, it;

var {assert} = require('chai');
require('chai').config.includeStack = true;
var jsdom = require('mocha-jsdom');

import * as boarders from "../client/boarders";
import * as Breakthrough from "../client/Breakthrough";

function assertSeenOnce(obj:any, trait="__VISITED"):void {
    assert.ok(obj);
    assert.equal(obj[trait], undefined, "Cell should not be visited twice!");
    obj[trait] = true;
}

describe('mocha tests', function () {
    jsdom();
    before(() => {
        (<any>global).$ = jsdom.rerequire('jquery');
    });
    // JSDom setup:
    it('tests boarders.Rules setup for Breakthrough', () => {
        let rules = Breakthrough.createRules();
        let game = new boarders.GameState(rules);
        assert.equal(rules.cellList().length, 64);
        assert.equal(rules._initialEnumPieces.length, 64)
        let board = game.setupHtml($("<div>"));
        
        let nCells = 0;
        for (let cell of rules.cellList()) {
            assert.equal(rules.getCell(cell.id), cell);
            assertSeenOnce(cell);
            assert.equal(cell.enumId, nCells++);
        }

        // Check that the rule representation has the correct number of pieces.
        let numPieces = 0;
        for (let piece of rules._initialEnumPieces) {
            if (piece > -1) {
                numPieces++;
            }
        }
        assert.equal(numPieces, 32);

        numPieces = 0;
        for (let cell of rules.cellList()) {
            if (game._enumPieces[cell.enumId] == -1) {
                assert.notOk(cell.uiCell.piece());
            } else {
                numPieces++;
                assertSeenOnce(cell.uiCell.piece());
            }
            assert.equal(cell.uiCell.gridCell, cell);
        }
        assert.equal(numPieces, 32);
    });
});
