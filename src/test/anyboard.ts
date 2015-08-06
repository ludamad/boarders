declare var describe, require, before, it;

var assert = require('chai').assert;

import * as anyboard from "../client/anyboard";
import * as boarders from "../client/boarders";
import {setupBreakthrough} from "../client/Breakthrough";

describe('mocha tests', function () {
    // JSDom setup:
    it('tests Breakthrough rule creation', () => {
        var rules = new boarders.Rules();
        rules.player("white");
        rules.player("black");
        rules.grid("board-1", 8, 8);

        var pawn = rules.piece("pawn");
        pawn.image("white", "images/Chess/wpawn_45x45.svg");
        pawn.image("black", "images/Chess/bpawn_45x45.svg");

        rules.finalizeBoardShape();

        rules.boardSetup("pawn", "white", "a1 b1 c1 d1 e1 f1 g1 h1".split(" "));
        rules.boardSetup("pawn", "white", "a2 b2 c2 d2 e2 f2 g2 h2".split(" "));
        rules.boardSetup("pawn", "black", "a7 b7 c7 d7 e7 f7 g7 h7".split(" "));
        rules.boardSetup("pawn", "black", "a8 b8 c8 d8 e8 f8 g8 h8".split(" "));

        rules.direction("board-1", "forward-left", -1, 1);
        rules.direction("board-1", "forward", 0, 1);
        rules.direction("board-1", "forward-right", 1, 1);

        rules.direction("board-1", "backward-left", -1, -1);
        rules.direction("board-1", "backward", 0, -1);
        rules.direction("board-1", "backward-right", 1, -1);        
    });
});
