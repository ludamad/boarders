var jsdom = require('mocha-jsdom')
var {assert, expect, fail} = require('chai')

import * as anyboard from "../client/anyboard";

declare var describe, require, before, it;

describe('mocha tests', function () {
    // JSDom setup:
    var $; jsdom();
    before(() => {$ = require('jquery');});
    it('tests HtmlPiece.imageFile()', () => {
        var piece = new anyboard.HtmlPiece("myimage", 32, 32);
        assert(piece.imageFile() == "myimage");
    })
});
