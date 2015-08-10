/// <reference path="../DefinitelyTyped/jquery/jquery.d.ts"/>

import {gridWithValueNByMTimes} from "../common/common";
import * as boarders from "./boarders";

// Imports:

var _CSS = {
    alpha: "alpha-d2270",
    black: "black-3c85d",
    board: "board-b72b1",
    chessboard: "chessboard-63f37",
    clearfix: "clearfix-7da63",
    highlight1: "highlight1-32417",
    highlight2: "highlight2-9c5d2",
    notation: "notation-322f9",
    numeric: "numeric-fc462",
    piece: "piece-417db",
    row: "row-5277c",
    sparePieces: "spare-pieces-7492f",
    sparePiecesBottom: "spare-pieces-bottom-ae20f",
    sparePiecesTop: "spare-pieces-top-4028b",
    square: "square-55d63",
    white: "white-1e1d7"
};

var cfg = {
    showNotation: true
};

// All the game information required for display:
export class HtmlPlayerInfoBlock {
    elem = $("<div>").addClass("btn player disabled btn-success");
    _timeElem = $("<p>").addClass("time");
    _nameElem = $("<p>");
    _playerElem = $("<p>");
    _isCurrentPlayer = false;

    constructor(public _userName, public _playerName, public _timeLeft) {
        this.elem.append(this._nameElem);
        this.elem.append(this._playerElem);
        this.elem.append(this._timeElem);
    }

    public _formatTime(remaining) {
        var hours, mins, secs;
        hours = Math.floor(remaining / 3600);
        remaining = remaining % 3600;
        mins = Math.floor(remaining / 60);
        secs = remaining % 60;
        return hours + ":" + mins + ":" + secs;
    }

    public timeLeft(_timeLeft : any = this._timeLeft) {
        this._timeLeft = _timeLeft != null ? _timeLeft : this._timeLeft;
        this._timeElem.text(this._formatTime(this._timeLeft));
        return this._timeLeft;
    }

    public playerName(_playerName : any = this._playerName) {
        this._playerName = _playerName != null ? _playerName : this._playerName;
        this._playerElem.text(this._playerName);
        return this._playerName;
    }

    public userName(_userName : any = this._userName) {
        this._userName = _userName != null ? _userName : this._userName;
        this._nameElem.text(this._userName);
        return this._userName;
    }

    public isCurrentPlayer(isCurrentPlayer) {
        if (isCurrentPlayer != null) {
            this._isCurrentPlayer = isCurrentPlayer;
            if (isCurrentPlayer) {
                this.elem.addClass("disabled");
            } else {
                this.elem.removeClass("disabled");
            }
        }
        return this._isCurrentPlayer;
    }
}

// Pieces that can be played, outside of the board
export class HtmlStack {
    constructor(public player, public piece, public amount : any = 0) {}
}

export class HtmlPiece {
    elem:JQuery;
    constructor(public _imageFile:string, public _w, public _h) {
        this.elem = $("<img>")
           .attr("src", this._imageFile)
           .attr("class", _CSS.piece)
           .attr("style", "width: " + this._w + "px; height: " + this._h + "px;");
    }

    public imageFile(file?:string):string {
        if (file != null) {
            this.elem.attr("src", file);
            this._imageFile = file;
        }
        return this._imageFile;
    }
}

export class HtmlCell {
    elem:JQuery;
    gridCell = null;
    _piece = null;
    constructor(public x, public y, public width, public height, public squareColor) {
        // Create initial div:
        this.elem = $("<div>")
            .attr("class", _CSS.square + " " + _CSS[this.squareColor])
            .css("width", this.width + "px")
            .css("height", this.height + "px")
            .attr("data-x", this.x.toString())
            .attr("data-y", this.y.toString());
    }

    public movePiece(destCell) {
        destCell.piece(this.piece());
        return this.piece(null);
    }

    public piece(piece = this._piece): HtmlPiece {
        if (typeof piece === "string") {
            piece = new HtmlPiece(piece, this.width, this.height);
        }
        this._piece = piece;
        this.elem.empty();
        if (piece != null) {
            this.elem.append(piece.elem);
        }
        return this._piece;
    }

    public highlightReset() {
        return this.elem.css("box-shadow", "");
    }

    public highlightHover() {
        return this.elem.css("box-shadow", "inset 0 0 3px 3px green");
    }

    public highlightSelected() {
        return this.elem.css("box-shadow", "inset 0 0 3px 3px green");
    }
}

export type BoardCallback = (self:HtmlBoard, cell:HtmlCell) => void;
export type DomCallback = () => void;

export class HtmlBoard {
    public draggedPiece = null;
    public cells:HtmlCell[][];
    public sqrHeight:any;
    public sqrWidth:number;
    public elem:JQuery;
    public orientation:string;
    public grid:boarders.Grid;
    
    constructor(public boardId:number, public width:number, public height:number) {
        this.orientation = "black";
        this.elem = $("#" + this.boardId);  //' + @boardId)
        this.sqrWidth = this.elem.width() / this.width;
        this.sqrHeight = this.sqrWidth;  // Square squares for now. Makes sense.
        this.cells = gridWithValueNByMTimes(null, width, height);
        this.draggedPiece = null;
    }   

    public getCellFromCell(cell:boarders.GraphNode):HtmlCell {
        return this.getCell(cell.x, cell.y);
    }

    public getPiece(x, y):HtmlPiece {
        return this.getCell(x, y).piece();
    }

    public setPiece(x, y, piece):void {
        this.getCell(x, y).piece(piece);
    }

    public movePiece(x1:number, y1:number, x2:number, y2:number):void {
        this.getCell(x1, y1).movePiece(this.getCell(x2, y2));
    }

    public setup():void {
        this.elem.empty();
        var squareColor = "white";
        for (var y = 0; y < this.height; y++) {
            var rowIds = [];
            // Start the row:
            var rowEl = $("<div>").attr("class", _CSS.row);
            var startColor = squareColor;
            for (var x = 0; x < this.width; x++) {
                var cell = new HtmlCell(x, y, this.sqrWidth, this.sqrHeight, squareColor);
                this.cells[y][x] = cell;
                if (this.orientation === "white") {
                    rowEl.append(cell.elem);
                } else {
                    rowEl.prepend(cell.elem);
                }

                squareColor = squareColor === "white" ? "black" : "white";
            }

            // Finish the row:
            rowEl.append($("<div class=" + _CSS.clearfix + ">"));
            squareColor = startColor === "white" ? "black" : "white";
            if (this.orientation === "white") {
                this.elem.append(rowEl);
            } else {
                this.elem.prepend(rowEl);
            }
        }
    }

    public _createDomCallbackFromCellFunc<T>(f:BoardCallback): DomCallback {
        var self = this;
        return function() {
            var x = parseInt($(this).attr("data-x"));
            var y = parseInt($(this).attr("data-y"));
            var cell = self.getCell(x, y);
            f(self, cell);
        };
    }

    public onCellClick<T>(f:BoardCallback):void {
        this.elem.find("." + _CSS.square).click(this._createDomCallbackFromCellFunc(f));
    }

    public onCellHover(startHoverF:BoardCallback, endHoverF:BoardCallback) {
        var endHoverDom, startHoverDom;
        startHoverDom = this._createDomCallbackFromCellFunc(startHoverF);
        endHoverDom = this._createDomCallbackFromCellFunc(endHoverF);
        this.elem.find("." + _CSS.square).hover(startHoverDom, endHoverDom);
    }

    public getCell(x:number, y:number) : HtmlCell {
        return this.cells[y][x];
    }
}

// This is all stuff that could be part of the HtmlPlayArea object
// but since we can confine its usage here, we do
//playAreaUiStateMachine = (playArea) ->

//return {onClick, onHover, addUiTrigger}

// Composed of some number of boards and stacks, for now
export class HtmlPlayArea {
    public pieceStacks:HtmlPiece[];
    public boards:HtmlBoard[];
    public pInfoBlocks:HtmlPlayerInfoBlock[];

    constructor(public elem:JQuery) {
        this.boards = [];
        this.pieceStacks = [];
        this.pInfoBlocks = [];
        this.pInfoBlocks.push(new HtmlPlayerInfoBlock("ludamad", "white", 50));
        this.pInfoBlocks.push(new HtmlPlayerInfoBlock("not ludamad", "black", 50));
        for (var info of this.pInfoBlocks) {
            this.elem.find("#timers").append(info.elem);
        }
    }

    public board(id:number, w:number, h:number): HtmlBoard {
        var board = new HtmlBoard(id, w, h);
        this.boards.push(board);
        return board;
    }

    public onCellClick(f:BoardCallback):void {
        for (var board of this.boards) {
            board.onCellClick(f);
        }
    }

    public onCellHover(startHoverF:BoardCallback, endHoverF:BoardCallback):void {
        for (var board of this.boards) {
            board.onCellHover(startHoverF, endHoverF);
        }
    }

    public setup():void {
        for (var board of this.boards) {
            board.setup();
        }
    }

    public addUiTrigger(_arg) {
        // var triggerCells, triggerOnClick, triggerOnDrag, _arg;
        // triggerCells = _arg.triggerCells, triggerOnDrag = _arg.triggerOnDrag, triggerOnClick = _arg.triggerOnClick;
    }
}

//$.get 'tictactoe.zrf', (content) ->
//    P = require("./zrfparser")
//    zrfFile = P.parse(content)
//    [zrfGame] = zrfFile.games
//    board = new HtmlPlayArea('board-container', zrfGame)
//    board.setup()

// TODO to be part of zrf module:
function fixImgUrl(url) {
    url = url.replace("\\", "/");
    url = url.replace("\.bmp", ".png");
    return url = url.replace("\.BMP", ".png");
}
