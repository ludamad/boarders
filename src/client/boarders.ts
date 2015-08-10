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

import {arrayWithValueNTimes, mapUntilN, mapNByM, unionToArray} from "../common/common";
import * as anyboard from "./anyboard";

// Helpers:
// 
// function stringListCast(players:string[]|string):string[] {
//     if (typeof players === "string") {
//         return [players];
//     } else return players;
// }

export abstract class RuleComponent {
    enumId:number;
    constructor(public rules:Rules) {
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
        rules.enums.graphNodes.add(this)
    }

    public next(dir, val : GraphNode = this._directions[dir]) {
        this._directions[dir] = val;
        return this._directions[dir];
    }
}

// This is user facing code, use getters and underscored members:
export abstract class Graph extends RuleComponent {
    _directions = {};

    // Enumeration refers to turning data about cells into 
    // a bunch of indices:

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

    constructor(rules:Rules, public width, public height, cellIds) {
        super(rules);
        this._cells = mapNByM(width, height, (x, y) => 
            new GraphNode(rules, cellIds(x, y), this, x, y)
        );
    }

    public direction(name, dx, dy) {
        for (var cell of this.rules.cellList()) {
            cell.next(name, null);
        }
        mapNByM(this.width, this.height, (x, y) => {
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

    public setImage(players:Player|Player[], img?): void{
        for (var p of unionToArray(players)) {
            this.images[p.id] = img;
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
        this._enumOwners = _rules._initialState._enumOwners.map((copy) => copy);
        this._enumPieces = _rules._initialState._enumPieces.map((copy) => copy);
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
            grid._board = this._playArea.board(grid.enumId, grid.width, grid.height);
        }
        this._playArea.setup();

        // Link the representations for easy end-user manipulation:
        for (var grid of this._rules.grids()) {
            grid._board.grid = grid;
            for (var y = 0; y < grid.height; y++) {
                for (var x = 0; x < grid.width; x++) {
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

export class Enumerators {
    graphs = new Enumerator<Graph>();
    graphNodes = new Enumerator<GraphNode>();
    players = new Enumerator<Player>();
    pieces = new Enumerator<Piece>();
}

export class Options {
    canPassOnTurn = false;
}

export class InitialState {
    _currentPlayerNum:number = 0;
    _enumOwners:number[] = [];
    _enumPieces:number[] = [];
}

// Game rules object.
// This is user facing code, use getters and underscored members:
export class Rules {
    enums = new Enumerators();
    private _playerAis = [];
    _players:Player[] = [];
    private _grids:Grid[] = [];
    private _turnsCanPass:boolean = false;
    private _stacks = [];
    _pieces:Piece[] = [];
    _initialState = new InitialState();
    private _finalized = false;

    public direction(grid, dx, dy) {
        return grid.direction(dx, dy);
    }

    public _ensureNotFinalized() {
        if (this._finalized) {
            throw new Error("Cannot call after calling rules.finalizeBoardShape()!");
        }
    }

    public _ensureFinalized(finalize = false) {
        if (!this._finalized) {
            if (!finalize) {
                throw new Error("Must call rules.finalizeBoardShape() before proceeding!");
            }
            this.finalizeBoardShape();
        }
    }

    public finalizeBoardShape() {
        this._ensureNotFinalized();
        this._finalized = true;
        this._initialState._enumPieces = arrayWithValueNTimes(-1, this.enums.graphNodes.total());
        this._initialState._enumOwners = arrayWithValueNTimes(-1, this.enums.graphNodes.total());
    }

    public cellList() {
        return this.enums.graphNodes.list;
    }
    
    //TODO
    public moveGenerator(throwaway) {
    }

    public boardSetup(piece:Piece, player:Player, cellIds:string[]):void {
        this._ensureFinalized(/* Finalize if necessary: */true);
        for (var cellId of unionToArray(cellIds)) {
            var cell = this.getCell(cellId);
            this._initialState._enumPieces[cell.enumId] = piece.enumId;
            this._initialState._enumOwners[cell.enumId] = player.enumId;
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

    public grid(w:number, h:number, cellNameCallback: (x:number, y:number)=>string) {
        this._ensureNotFinalized();
        var grid = new Grid(this, w, h, cellNameCallback);
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
        throw new Error("boarders.ts: Graph node was not found. Is your graph node naming convention consistent?");
    }
}
