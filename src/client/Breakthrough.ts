import * as boarders from "./boarders";
import {runEnginePlayer, stopEnginePlayer} from "./jmarine/ai-spawn";

// More or less takes control of the game and UI logic.
export function setupBreakthrough(elem) {
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

    var ai = rules.playerAi("Easy");
    ai.thinkFunction((game, onFinishThinking) => {
        // Interface with jmarine's AI:
        var contents, gameString, owner;
        contents = ["Breakthrough:"];
        if (game.currentPlayer() === "white") {
            contents.push(1);
        } else {
            contents.push(2);
        }
        for (var piece of game.pieces) {
            if (piece != null) {
                owner = piece.owner;
                contents.push(owner.id === "white" ? "P" : "p");
            } else {
                contents.push(" ");
            }
        }
        gameString = contents.join("");
        return runEnginePlayer(5, gameString, onFinishThinking);
    });

    var game = new boarders.GameState(rules);

    function queueAI() {
        return ai.think(game, (move) => {
            var from, fromCell, to, toCell, _ref1;
            if (move == null) {
                return;
            }
            _ref1 = [move.substring(0, 2), move.substring(2, 4)], from = _ref1[0], to = _ref1[1];
            fromCell = game.rules().getCell(from);
            toCell = game.rules().getCell(to);
            game.movePiece(fromCell, toCell);
            game.endTurn();
        });
    }

    // Used for move generation logic:
    var MOVE_DIRECTIONS = [
        {
            white: "forward-left",
            black: "backward-left",
            canCapture: true
        }, {
            white: "forward",
            black: "backward",
            canCapture: false
        }, {
            white: "forward-right",
            black: "backward-right",
            canCapture: true
        }
    ];

    function validCells(cell) {
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

    var selectedCell = null;

    // Set up the breakthrough board for the current element:
    var playArea = game.setupHtml(elem);
    playArea.onCellClick((board, cell) => {
        if ((selectedCell != null) && selectedCell !== cell) {
            var cells = validCells(selectedCell.gridCell);
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
            cell.highlightHover()
        }, 
        (board, cell) => {
            if (cell !== selectedCell) {
                return cell.highlightReset();
            }
        }
    );
}