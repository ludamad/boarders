import {zrfNodes as zrf} from "./zrfFromSexp";
import * as boarders from "../boarders";

function visitAll(node:zrf.Node, visitor:zrf.ZrfCompilerPass<void>) {
    function recurse(obj:zrf.Node) {
        // TODO: can iterate obj._subevents, technically.
        for (var key of Object.keys(obj)) {
            if (obj[key] instanceof zrf.Node) {
                var handler = visitor[obj[key]._classname];
                if (handler) {
                    handler(obj);
                }
                recurse(obj);
            }
        }
    }
}

export function compile(node:zrf.Node):boarders.Rules {
    var rules = new boarders.Rules();
    
    visitAll(node, {
        Directions(obj:zrf.Directions) {
            obj.dirs; // <function>
        },
        Dimensions(obj:zrf.Dimensions) {
        },
        Piece(obj:zrf.Piece) {
            obj.name; // string
            obj.help; // string
            obj.images; // <function>
            obj.drops; // <function>
        },
        Grid(obj:zrf.Grid) {
            obj["start-rectangle"]; // <function>
            obj.dimensions; // Dimensions
            obj.directions; // Directions
        },
        Board(obj:zrf.Board) {
            obj.image; // string
            obj.grid; // Grid
        },
        BoardSetup(obj:zrf.BoardSetup) {
        },
        EndCondition(obj:zrf.EndCondition) {
            // obj.players
        },
        Game(obj:zrf.Game) {
            obj.title; // string
            obj.description; // string
            obj.history; // string
            obj.strategy; // string
            obj.players; // string*
            obj["turn-order"]; // string*
            obj["board-setup"]; // string*
            obj.boards; // Board[]
            obj.pieces; // Piece[]
            obj["draw-conditions"]; // EndCondition[]
            obj["win-conditions"]; // EndCondition[]
            obj.option; // <function>
        }
    });

    return rules;
}

// 
// visitAll(node, {
//     Directions(obj:zrf.Directions) {
//         obj.dirs; // <function>
//     },
//     Dimensions(obj:zrf.Dimensions) {
//     },
//     Piece(obj:zrf.Piece) {
//         obj.name; // string
//         obj.help; // string
//         obj.images; // <function>
//         obj.drops; // <function>
//     },
//     Grid(obj:zrf.Grid) {
//         obj["start-rectangle"]; // <function>
//         obj.dimensions; // Dimensions
//         obj.directions; // Directions
//     },
//     Board(obj:zrf.Board) {
//         obj.image; // string
//         obj.grid; // Grid
//     },
//     BoardSetup(obj:zrf.BoardSetup) {
//     },
//     EndCondition(obj:zrf.EndCondition) {
//         // obj.players
//     },
//     Game(obj:zrf.Game) {
//         obj.title; // string
//         obj.description; // string
//         obj.history; // string
//         obj.strategy; // string
//         obj.players; // string*
//         obj["turn-order"]; // string*
//         obj["board-setup"]; // string*
//         obj.boards; // Board[]
//         obj.pieces; // Piece[]
//         obj["draw-conditions"]; // EndCondition[]
//         obj["win-conditions"]; // EndCondition[]
//         obj.option; // <function>
//     }
// });
