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


import {arrayWithValueNTimes, mapUntilN} from "./common";
import * as anyboard from "./anyboard";


// Helpers:
function stringListCast(players) {
    if (typeof players === "string") {
        return [players];
    }
    return players;
}

// Tentatively the following is the 'BRF object model', 
// which the ZRF object model is compiled to,
// and which the Boarders API emits. (Architecture is hard)

class Enumerator {
    list = [];

    public push(obj) {
        obj.enumId(this.list.length);
        return this.list.push(obj);
    }

    public total() {
        return this.list.length;
    }
}

// This is user facing code, use getters and underscored members:
export class Cell {
    _directions = {};
    _enumId = null;
    constructor(public id, public _parent, public _x : any = null, public _y : any = null) {
    }

    public enumId(_enumId : any = this._enumId) {
        this._enumId = _enumId != null ? _enumId : this._enumId;
        return this._enumId;
    }

    public x(_x : any = this._x) {
        this._x = _x != null ? _x : this._x;
        return this._x;
    }

    public y(_y : any = this._y) {
        this._y = _y != null ? _y : this._y;
        return this._y;
    }

    public parent() {
        return this._parent;
    }

    public next(dir, val : any = this._directions[dir]) {
        this._directions[dir] = val;
        return this._directions[dir];
    }
}

// This is user facing code, use getters and underscored members:
export class Graph {
    _directions = {};

    // Enumeration refers to turning data about cells into 
    // a bunch of indices:

    public _enumerateCells(enumerator) {
        return this.cellList().map((cell) => enumerator.push(cell));
    }

    public _enumerateDir(enumerator, dir) {
        this._directions[dir] = arrayWithValue enumerator.total() - 1 + 1).map((_) => -1);
        return this.cellList().map((cell) => this._directions[dir][cell.enumId()] = cell.next(dir).enumId());
    }

    public cellList(): Cell[] {
        throw new Error("Abstract method called!");
    }  // Base class
}

// This is user facing code, use getters and underscored members:
export class Grid extends Graph {
    // The cells of the graph, mirrored by HtmlCell's in the UI
    _cells : Cell[][];
    constructor(public id, public _width, public _height, cellIds) {
        this._cells = mapNByM(width, height, (x, y) => new Cell(cellIds(x, y), this, x, y));
    }

    public direction(name, dx, dy) {
        mapNByM(this.width, this.height, (x, y) => {
            // Set the cell's linked cell for this name
            if (this.getCell(x + dx, y + dy) != null) {
                // Set the cell's linked cell for this name
                this.getCell(x, y).next(name, this.getCell(x + dx, y + dy));
            }
        });
    }

    public cellList() {
        var list = [];
        for (var row of this._cells) {
            for (var cell of row) {
                list.push(cell);
            }
        }
        return list;
    }

    public getCell(id, yIfIdIsX) {
        // Case 1: getCell(x, y)
        if (typeof id === "number") {
            if (this._cells[yIfIdIsX]) == null) {
                return null;
            }
            return this._cells[yIfIdIsX][id];
        }
        // Case 2: getCell(id)
        for (var row of @_cells) {
            for (var cell of row) {
                return cell;
            }
        }
        return null;
    }

    // At least coffee makes writing getter-setters bearable.

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
    constructor(public _fromCell, public _toCell, public _dragTrigger = false) {}
}

// This is user facing code, use getters and underscored members:
export class Player {
    constructor(public id) {}

    public enumId(_enumId : any = this._enumId) {
        this._enumId = _enumId != null ? _enumId : this._enumId;
        return this._enumId;
    }
}

// This is user facing code, use getters and underscored members:
class Piece {
    constructor(public id) {
        this._images = {};
    }

    public enumId(_enumId : any = this._enumId) {
        this._enumId = _enumId != null ? _enumId : this._enumId;
        return this._enumId;
    }

    public image(players, img) {
        if (img == null) {
            return this._images[players];
        }
        return stringListCast(players).map((p) => this._images[p] = img);
    }
}

// This is user facing code, use getters and underscored members:
export class GameState {
    _currentPlayerNum:number = 0;
    _enumOwners:any;
    _enumPieces:any;

    constructor(public _rules) {
        this._enumOwners = _rules._initialEnumOwners.map((copy) => copy);
        this._enumPieces = _rules._initialEnumPieces.map((copy) => copy);
    }

    public currentPlayerNum(_currentPlayerNum : any = this._currentPlayerNum) {
        this._currentPlayerNum = _currentPlayerNum != null ? _currentPlayerNum : this._currentPlayerNum;
        return this._currentPlayerNum;
    }

    public currentPlayer() {
        return this._rules._players[this._currentPlayerNum].id;
    }

    public rules() {
        return this._rules;
    }

    public setPiece(cell, player, piece) {
        this._enumOwners[cell.enumId()] = player.enumId();
        return this._enumPieces[cell.enumId()] = piece.enumId();
    }

    public getPieceOwner(cell) {
        return this._rules._players[this._enumOwners[cell.enumId()]].id;
    }

    public hasPiece(cell) {
        return this.getPieceType(cell) != null;
    }

    public getPieceType(cell) {
        var eId;
        eId = this._enumPieces[cell.enumId()];
        if (eId === -1) {
            return null;
        }
        return this._rules._players[eId];
    }

    public movePiece(cell1, cell2) {
        this._enumOwners[cell2.enumId()] = this._enumOwners[cell1.enumId()];
        this._enumPieces[cell2.enumId()] = this._enumPieces[cell1.enumId()];
        this._enumOwners[cell1.enumId()] = -1;
        this._enumPieces[cell1.enumId()] = -1;
        if (cell1.uiCell != null) {
            return cell1.uiCell.movePiece(cell2.uiCell);
        }
    }

    public pieces() {
        var pieces = []
        for (var i = 0; i < @_enumOwners.length; i++) {
            owner = @_rules._players[@_enumOwners[i]]
            typeEnum = @_enumPieces[i]
            if (typeEnum == -1) {
                pieces.push(null);
            } else {
                cell = @_rules.cellList()[i]
                pieces.push({owner, {type: @_rules._pieces[typeEnum], x: cell.x(), y: cell.y()}});
            }
        }
        return pieces
    }

    public setupHtml(container) {
        var playArea = new anyboard.HtmlPlayArea(container);
        for (var grid of @_rules.grids()) {
            grid._board = playArea.board(grid.id, grid.width(), grid.height());
        }
        playArea.setup();

        // Link the representations for easy end-user manipulation:
        for (var grid of @_rules.grids()) {
            grid._board.grid = grid;
            for (var y = 0; y < grid.height(); y++) {
                for (var x = 0; x < grid.width(); x++) {
                    grid._board.getCell(x,y).gridCell = grid.getCell(x,y)
                    grid.getCell(x,y).uiCell = grid._board.getCell(x,y)
                }
            }
        }
        this.syncPieces();
        return playArea;
    }

    public endTurn() {
        this._currentPlayerNum++;
        if (this._currentPlayerNum >= this._rules._players.length) {
            this._currentPlayerNum -= this._rules._players.length;
        }
        return this.syncPieces();
    }

    public syncPieces() {
        for (var cell of this._rules.cellList()) {
            var enumPiece = this._enumPieces[cell.enumId()];
            var enumOwner = this._enumOwners[cell.enumId()];
            if (enumPiece === -1) {
                cell.uiCell.piece(null);
                continue;
            }
            var owner = this._rules._players[enumOwner].id;
            var piece = this._rules._pieces[enumPiece];
            var img = piece.image(owner);
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
    constructor(public playerId, public game) {
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
    return (String.fromCharCode(97 + x)) + (1 + y);
}

// Game rules object.
// This is user facing code, use getters and underscored members:
export class Rules {
    _cellEnumerator:any = new Enumerator();
    _playerAis = [];
    _players = [];
    _grids = [];
    _turnsCanPass = false;
    _stacks = [];
    _pieces = [];
    _initialEnumPieces = [];
    _initialEnumOwners = [];
    _finalized = false;

    public direction(grid, name, dx, dy) {
        if (typeof grid === "string") {
            grid = this.getGrid(grid);
        }
        this.cellList().forEach((cell) => cell.next(name, null));
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
        this._grids.forEach((grid) => grid._enumerateCells(this._cellEnumerator));
        this._initialEnumPieces = arrayWithValueNTimes(-1, this._cellEnumerator.total());
        this._initialEnumOwners = arrayWithValueNTimes(-1, this._cellEnumerator.total());
    }

    public cellList() {
        return this._cellEnumerator.list;
    }

    public boardSetup(pieceId, playerId, cellIds) {
        var cell;
        this._ensureFinalized();
        cellIds = stringListCast(cellIds);  // Ensure list
        return cellIds.map((cellId) => {
            cell = this.getCell(cellId);
            this._initialEnumPieces[cell.enumId()] = this.getPiece(pieceId).enumId();
            return this._initialEnumOwners[cell.enumId()] = this.getPlayer(playerId).enumId();
        });
    }

    public playerAi(id) {
        var ai;
        ai = new PlayerAi(id);
        this._playerAis.push(ai);
        return ai;
    }

    public piece(id) {
        var piece;
        this._ensureNotFinalized();
        piece = new Piece(id);
        piece.enumId(this._pieces.length);
        this._pieces.push(piece);
        return piece;
    }

    public player(id) {
        var player;
        this._ensureNotFinalized();
        player = new Player(id);
        player.enumId(this._players.length);
        this._players.push(player);
        return player;
    }

    public grid(name, w, h, cellNames : any = algebraicCellNamingScheme) {
        var grid;
        this._ensureNotFinalized();
        grid = new Grid(name, w, h, cellNames);
        this._grids.push(grid);
        return grid;
    }

    public grids() {
        return this._grids;
    }

    // Mmm boilerplate.

    public getCell(id) {
        var cell, grid, _i, _len, _ref;
        _ref = this._grids;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            grid = _ref[_i];
            cell = grid.getCell(id);
            if (cell != null) {
                return cell;
            }
        }
        return null;
    }

    public getGrid(id) {
        var grid, _i, _len, _ref;
        _ref = this._grids;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            grid = _ref[_i];
            if (grid.id === id) {
                return grid;
            }
        }
    }

    public getPlayer(id) {
        var player, _i, _len, _ref;
        _ref = this._players;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            player = _ref[_i];
            if (player.id === id) {
                return player;
            }
        }
    }

    public getStack(id) {
        var stack, _i, _len, _ref;
        _ref = this._stacks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            stack = _ref[_i];
            if (stack.id === id) {
                return stack;
            }
        }
    }

    public getPiece(id) {
        var piece, _i, _len, _ref;
        _ref = this._pieces;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            piece = _ref[_i];
            if (piece.id === id) {
                return piece;
            }
        }
    }
}
