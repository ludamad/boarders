import {Rules, Piece, GameState}  from "./boarders";
import {runEnginePlayer, stopEnginePlayer} from "./jmarine/ai-spawn";

// More or less takes control of the game and UI logic.
export var rules = new Rules();

var whitePlayer = rules.player("white");
var blackPlayer = rules.player("black");

// Chess-like naming scheme:
var board = rules.grid(8, 8, (x, y) => `${String.fromCharCode(97 + x)}${1 + y}`);

var pawn:Piece = rules.piece("pawn");
pawn.setImage(whitePlayer, "images/Chess/wpawn_45x45.svg");
pawn.setImage(blackPlayer, "images/Chess/bpawn_45x45.svg");

rules.boardSetup(pawn, whitePlayer, "a1 b1 c1 d1 e1 f1 g1 h1".split(" "));
rules.boardSetup(pawn, whitePlayer, "a2 b2 c2 d2 e2 f2 g2 h2".split(" "));
rules.boardSetup(pawn, blackPlayer, "a7 b7 c7 d7 e7 f7 g7 h7".split(" "));
rules.boardSetup(pawn, blackPlayer, "a8 b8 c8 d8 e8 f8 g8 h8".split(" "));

var forwardLeft  = rules.direction(board, -1, 1);
var forward      = rules.direction(board, 0, 1);
var forwardRight = rules.direction(board, 1, 1);

var backwardLeft  = rules.direction(board, -1, -1);
var backward      = rules.direction(board, 0, -1);
var backwardRight = rules.direction(board, 1, -1);

var MOVE_DIRECTIONS = [
    {
        white: forwardLeft,
        black: backwardLeft,
        canCapture: true
    }, {
        white: forward,
        black: backward,
        canCapture: false
    }, {
        white: forwardRight,
        black: backwardRight,
        canCapture: true
    }
];

function validCells(game, cell) {
    var player = game.currentPlayer();
    var cells = [];
    if (game.hasPiece(cell) != null && game.getPieceOwner(cell) === player) {
        for (var dir of MOVE_DIRECTIONS) {
            var next = cell.next(dir[player]);
            if (next == null) {
                // Invalid: Direction not defined here
                continue;
            }
            if (!game.hasPiece(next)) {
                // Valid: Direction defined and empty
                cells.push(next);
                continue;
            }
            if (game.getPieceOwner(next) === player) {
                // Invalid: Direction defined and friendly
                continue;
            }

            if (dir.canCapture) {
                // Valid: Direction defined and enemy and diagonal
                cells.push(next);
                continue;
            }
            // Invalid: Direction defined and enemy and forward
        }
    }
    return cells;
}

var ai = rules.playerAi("Easy");
ai.thinkFunction((game:GameState, onFinishThinking) => {
    // Interface with jmarine's AI:
    let contents = ["Breakthrough:"];
    if (game.currentPlayer() === "white") {
        contents.push("1");
    } else {
        contents.push("2");
    }
    for (let piece of game.pieces()) {
        if (piece != null) {
            let owner = piece.owner;
            contents.push(owner.id === "white" ? "P" : "p");
        } else {
            contents.push(" ");
        }
    }
    let gameString = contents.join("");
    return runEnginePlayer(5, gameString, onFinishThinking);
});

export function setupUiAndGame(elem:JQuery) {
    var game = new GameState(rules);
    setupUi(game, elem);
    return game;
}

export function setupUi(game:GameState, elem:JQuery) {

    function queueAI() {
        return ai.think(game, (move) => {
            if (move == null) {
                return;
            }
            var from = move.substring(0, 2), to = move.substring(2, 4);
            var fromCell = game.rules().getCell(from);
            var toCell = game.rules().getCell(to);
            game.movePiece(fromCell, toCell);
            game.endTurn();
        });
    }

    // Used for move generation logic:

    var selectedCell = null;

    // Set up the breakthrough board for the current element:
    var playArea = game.setupHtml(elem);
    playArea.onCellClick((board, cell) => {
        if ((selectedCell != null) && selectedCell !== cell) {
            var cells = validCells(game, selectedCell.gridCell);
            // Is the move valid?
            if (cells.indexOf(cell.gridCell) >= 0) {
                game.movePiece(selectedCell.gridCell, cell.gridCell);
                game.endTurn();
                queueAI();
            }
            selectedCell.highlightReset();
            selectedCell = null;
        } else if (cell.piece() != null) {
            selectedCell = cell;
            selectedCell.highlightSelected();
        }
    });

    playArea.onCellHover(
        (board, cell) => {
            cell.highlightHover();
        }, 
        (board, cell) => {
            if (cell !== selectedCell) {
                return cell.highlightReset();
            }
        }
    );
}

