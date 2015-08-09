// Boarders public API for hosted Javascript games.
//
// API Version: 0.0.?
//
// This code should be usable anywhere, but only games hosted on the server can be played through the Boarders server.
// Networking primitives are decidedly not to ever be exposed. The fact that the code is so tied to the Boarders server 
// should not be evident during local testing.
//
// Current goals are to provide a convenient framework for Chesslikes. 
//
// Playing areas should be represented as graphs, but so far the plan is onlyto 
// provide rendering support for square grids. 
//
// Similarly, logic can be anything, but current display support is limited to 
// one image per square.
//
// Stretch goals:
// Maybe provide JSFiddle-like environment eventually.

"use strict";

import {arrayWithValueNTimes, mapUntilN, mapNByM} from "./common";
import * as anyboard from "./anyboard";

// Helpers:

function stringListCast(players:string[]|string):string[] {
    if (typeof players === "string") {
        return [players];
    } else return players;
}

export abstract class RuleComponent {
    enumId: number;
    constructor(public rule:Rules) {
    }
}

// Tentatively the following is the 'BRF object model', 
// which the ZRF object model is compiled to,
// and which the Boarders API emits. (Architecture is hard)

class Enumerator<T extends RuleComponent> {
    list:T[] = [];
    public add(obj:T) {
        obj.enumId = this.list.length;
        this.list.push(obj);
    }
    public total():number {
        return this.list.length;
    }
}

// This is user facing code, use getters and underscored members:
export class GraphNode extends RuleComponent {
    _directions = {};
    uiCell:anyboard.HtmlCell = null;
    constructor(rules:Rules, public id, public parent, public x:number, public y:number) {
        super(rules);
    }

    public next(dir, val : any = this._directions[dir]) {
        this._directions[dir] = val;
        return this._directions[dir];
    }
}

// This is user facing code, use getters and underscored members:
export abstract class Graph extends RuleComponent {
    _directions = {};

    // Enumeration refers to turning data about cells into 
    // a bunch of indices:

    public _enumerateCells(enumerator:Enumerator<GraphNode>) {
        for (var cell of this.cellList()) {
            enumerator.add(cell);
        }
    }

    public _enumerateDir(enumerator, dir) {
        this._directions[dir] = arrayWithValueNTimes(-1, enumerator.total());
        for (var cell of this.cellList()) {
            this._directions[dir][cell.enumId] = cell.next(dir).enumId;
        }
    }

    public cellList(): GraphNode[] {
        throw new Error("Abstract method called!");
    }  
}

// This is user facing code, use getters and underscored members:
export class Grid extends Graph {
    // The cells of the graph, mirrored by HtmlCell's in the UI
    _cells : GraphNode[][];
    _board : anyboard.HtmlBoard = null;

    constructor(rules:Rules, public id, public _width, public _height, cellIds) {
        super(rules);
        this._cells = mapNByM(_width, _height, (x, y) => 
            new GraphNode(rules, cellIds(x, y), this, x, y)
        );
    }

    public direction(name, dx, dy) {
        mapNByM(this._width, this._height, (x, y) => {
            // Set the cell's linked cell for this name
            if (this.getCell(x + dx, y + dy) != null) {
                // Set the cell's linked cell for this name
                this.getCell(x, y).next(name, this.getCell(x + dx, y + dy));
            }
        });
    }

    public cellList():GraphNode[] {
        var list = [];
        for (var row of this._cells) {
            for (var cell of row) {
                list.push(cell);
            }
        }
        return list;
    }

    public getCell(id:number|string, yIfIdIsX?:number):GraphNode {
        // Case 1: getCell(x, y)
        if (typeof id === "number") {
            if (this._cells[yIfIdIsX] == null) {
                return null;
            }
            return this._cells[yIfIdIsX][id];
        }
        // Case 2: getCell(id)
        for (var row of this._cells) {
            for (var cell of row) {
                if (cell.id === id) {
                    return cell;
                }
            }
        }
        return null;
    }

    public width(_width : any = this._width) {
        this._width = _width != null ? _width : this._width;
        return this._width;
    }

    public height(_height : any = this._height) {
        this._height = _height != null ? _height : this._height;
        return this._height;
    }
}

// This is user facing code, use getters and underscored members:
export class SlideMove {
    constructor(public _fromCell   :GraphNode, 
                public _toCell     :GraphNode, 
                public _dragTrigger:boolean = false) {}
}

// This is user facing code, use getters and underscored members:
export class Player extends RuleComponent {
    constructor(rules:Rules, public id:string) {
        super(rules);
    }
}

// This is user facing code, use getters and underscored members:
export class Piece extends RuleComponent {
    images = {};
    constructor(rules:Rules, public id:string) {
        super(rules);
    }

    public setImage(players:string|string[], img?): void{
        for (var p of stringListCast(players)) {
            this.images[p] = img;
        }
    }
}

interface PieceInfo {
    owner: Player;
    type: Piece;
    x: number; 
    y: number;    
}

// This is user facing code, use getters and underscored members:
export class GameState {
    _currentPlayerNum:number = 0;
    _enumOwners:number[];
    _enumPieces:number[];
    _playArea:anyboard.HtmlPlayArea = null;

    constructor(public _rules:Rules) {
        this._enumOwners = _rules._initialEnumOwners.map((copy) => copy);
        this._enumPieces = _rules._initialEnumPieces.map((copy) => copy);
    }

    public currentPlayerNum(_currentPlayerNum : any = this._currentPlayerNum) {
        this._currentPlayerNum = _currentPlayerNum != null ? _currentPlayerNum : this._currentPlayerNum;
        return this._currentPlayerNum;
    }

    public currentPlayer():string {
        return this._rules._players[this._currentPlayerNum].id;
    }

    public rules():Rules{
        return this._rules;
    }

    public setPiece(cell, player, piece):void {
        this._enumOwners[cell.enumId] = player.enumId;
        this._enumPieces[cell.enumId] = piece.enumId;
    }

    public getPieceOwner(cell) {
        return this._rules._players[this._enumOwners[cell.enumId]].id;
    }

    public hasPiece(cell) {
        return this.getPieceType(cell) != null;
    }

    public getPieceType(cell) {
        var eId = this._enumPieces[cell.enumId];
        if (eId === -1) {
            return null;
        }
        return this._rules._players[eId];
    }

    public movePiece(cell1, cell2) {
        this._enumOwners[cell2.enumId] = this._enumOwners[cell1.enumId];
        this._enumPieces[cell2.enumId] = this._enumPieces[cell1.enumId];
        this._enumOwners[cell1.enumId] = -1;
        this._enumPieces[cell1.enumId] = -1;
        if (cell1.uiCell != null) {
            return cell1.uiCell.movePiece(cell2.uiCell);
        }
    }

    public pieces():PieceInfo[] {
        var pieces:PieceInfo[] = [];
        for (var i = 0; i < this._enumOwners.length; i++) {
            var owner = this._rules._players[this._enumOwners[i]];
            var typeEnum = this._enumPieces[i];
            if (typeEnum == -1) {
                pieces.push(null);
            } else {
                var cell = this._rules.cellList()[i];
                pieces.push({
                    owner,
                    type: this._rules._pieces[typeEnum], 
                    x: cell.x, 
                    y: cell.y
                });
            }
        }
        return pieces;
    }

    public setupHtml(container:JQuery):anyboard.HtmlPlayArea {
        this._playArea = new anyboard.HtmlPlayArea(container);
        for (var grid of this._rules.grids()) {
            grid._board = this._playArea.board(grid.id, grid.width(), grid.height());
        }
        this._playArea.setup();

        // Link the representations for easy end-user manipulation:
        for (var grid of this._rules.grids()) {
            grid._board.grid = grid;
            for (var y = 0; y < grid.height(); y++) {
                for (var x = 0; x < grid.width(); x++) {
                    grid._board.getCell(x,y).gridCell = grid.getCell(x,y);
                    grid.getCell(x,y).uiCell = grid._board.getCell(x,y);
                }
            }
        }
        this.syncPieces();
        return this._playArea;
    }

    public endTurn():void {
        this._currentPlayerNum++;
        if (this._currentPlayerNum >= this._rules._players.length) {
            this._currentPlayerNum -= this._rules._players.length;
        }
        this.syncPieces();
    }

    public syncPieces():void {
        for (var cell of this._rules.cellList()) {
            var enumPiece = this._enumPieces[cell.enumId];
            var enumOwner = this._enumOwners[cell.enumId];
            if (enumPiece === -1) {
                cell.uiCell.piece(null);
                continue;
            }
            var owner = this._rules._players[enumOwner].id;
            var piece = this._rules._pieces[enumPiece];
            var img = piece.images[owner];
            var htmlPiece = cell.uiCell.piece();
            // Avoid creating a new image element if necessary, slight gain:
            if (htmlPiece != null) {
                htmlPiece.imageFile(img);
            } else {
                cell.uiCell.piece(img);
            }
        }
    }
}

export class LocalPlayer {
    constructor(public playerId:number, public game) {
    }

    public isLocalPlayer() {
        return true;
    }

    public onTurnStart(onMove) {}
}

export class EnginePlayer {
    constructor(public playerId, public game, public ai) {
    }

    public isLocalPlayer() {
        return false;
    }

    public onTurnStart(onMove) {
        return this.ai.think(this.game, onMove);
    }
}

class NetworkPlayer {
    undoConfirmed = false;
    constructor(public playerId) {
    }

    public onTurnStart(onMove) {}
}

class PlayerAi {
    _thinkFunc:any;
    constructor(public id) {}

    public thinkFunction(_thinkFunc = this._thinkFunc) {
        this._thinkFunc = _thinkFunc != null ? _thinkFunc : this._thinkFunc;
        return this._thinkFunc;
    }

    public think(game, onFinishThinking) {
        return this._thinkFunc(game, onFinishThinking);
    }
}

// Default naming scheme, because chess:
function algebraicCellNamingScheme(x, y) {
    return String.fromCharCode(97 + x) + (1 + y).toString();
}

export class Enumerators {
    graphNodes = new Enumerator<GraphNode>();
    cells = new Enumerator<GraphNode>();
}

// Game rules object.
// This is user facing code, use getters and underscored members:
export class Rules {
    private _cellEnumerator = new Enumerator<GraphNode>();
    private _playerAis = [];
    _players:Player[] = [];
    private _grids:Grid[] = [];
    private _turnsCanPass:boolean = false;
    private _stacks = [];
    _pieces:Piece[] = [];
    _initialEnumPieces:number[] = [];
    _initialEnumOwners:number[] = [];
    private _finalized = false;

    public direction(grid, name, dx, dy) {
        if (typeof grid === "string") {
            grid = this.getGrid(grid);
        }
        for (var cell of this.cellList()) {
            cell.next(name, null);
        }
        return grid.direction(name, dx, dy);
    }

    public _ensureNotFinalized() {
        if (this._finalized) {
            throw new Error("Cannot call after calling rules.finalizeBoardShape()!");
        }
    }

    public _ensureFinalized() {
        if (!this._finalized) {
            throw new Error("Must call rules.finalizeBoardShape() before proceeding!");
        }
    }

    public finalizeBoardShape() {
        this._ensureNotFinalized();
        this._finalized = true;
        for (var grid of this._grids) {
            grid._enumerateCells(this._cellEnumerator);
        }
        this._initialEnumPieces = arrayWithValueNTimes(-1, this._cellEnumerator.total());
        this._initialEnumOwners = arrayWithValueNTimes(-1, this._cellEnumerator.total());
    }

    public cellList() {
        return this._cellEnumerator.list;
    }

    public boardSetup(pieceId:string, playerId:string, cellIds:string[]):void {
        this._ensureFinalized();
        cellIds = stringListCast(cellIds);  // Ensure list
        for (var cellId of cellIds) {
            var cell = this.getCell(cellId);
            this._initialEnumPieces[cell.enumId] = this.getPiece(pieceId).enumId;
            this._initialEnumOwners[cell.enumId] = this.getPlayer(playerId).enumId;
        }
    }

    public playerAi(id) {
        var ai = new PlayerAi(id);
        this._playerAis.push(ai);
        return ai;
    }

    public piece(id) {
        this._ensureNotFinalized();
        var piece = new Piece(this, id);
        piece.enumId = this._pieces.length;
        this._pieces.push(piece);
        return piece;
    }

    public player(id:string) {
        this._ensureNotFinalized();
        var player = new Player(this, id);
        player.enumId = this._players.length;
        this._players.push(player);
        return player;
    }

    public grid(name, w, h, cellNames = algebraicCellNamingScheme) {
        this._ensureNotFinalized();
        var grid = new Grid(this, name, w, h, cellNames);
        this._grids.push(grid);
        return grid;
    }

    public grids():Grid[] {
        return this._grids;
    }

    // Mmm boilerplate.

    public getCell(id):GraphNode {
        for (var grid of this._grids) {
            var cell = grid.getCell(id);
            if (cell != null) {
                return cell;
            }
        }
        return null;
    }

    public getGrid(id):Grid {
        for (var grid of this._grids) {
            if (grid.id === id) {
                return grid;
            }
        }
    }

    public getPlayer(id):Player {
        for (var player of this._players) {
            if (player.id === id) {
                return player;
            }
        }
    }

    public getStack(id:string):Piece {
        for (var stack of this._stacks) {
            if (stack.id === id) {
                return stack;
            }
        }
    }
    
    public getPiece(id:string):Piece {
        for (var piece of this._pieces) {
            if (piece.id === id) {
                return piece;
            }
        }
    }
}
