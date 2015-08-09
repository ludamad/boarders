"use strict";

import {SExp} from "./sexpParser"
import {sexpToList, sexpToSexps, sexpToStrings, sexpToPairs, 
    sexpToLabeledPair, sexpStringCast, sexpToStringPair, sexpBoxIfString,
    sexpFoldStringPairs, sexpToInts, sexpCheckLabeled} from "./sexpUtils";

////////////////////////////////////////////////////////////////////////////////
// Main exported function.
////////////////////////////////////////////////////////////////////////////////

export function zrfFromSexpWithNoMacros(sexp:SExp) {
    var model = new zrfNodes.File();
    model.processSubnodes(sexp);
    return model;
};

function parseAs(type:any, name?:string) : PropertyDecorator {
    return function(target, propertyKey: string) {
        target._subevents = target._subevents || {};
        // console.log(target, propertyKey)
        target._subevents[name || propertyKey] = {propertyKey, type};
    }
}

interface StrMap<T> {
    [s: string]: T;
}

type Option = {label: string, value:any};

function hasOwnProperty(obj:Object, key:string) {
    return Object.prototype.hasOwnProperty.call(obj, key);
}

////////////////////////////////////////////////////////////////////////////////
// Classes for the ZRF object model. Define parsing events with metadata.
// The names of the classes themselves are used for matching events triggered.
////////////////////////////////////////////////////////////////////////////////
export module zrfNodes {
    export abstract class Node {
        /* Not actually set on class, used to declare the setting above: */
        _subevents:StrMap<{propertyKey:string, type:any}>;
        _classname:string;
        processSubnodes(sexp:SExp) {
            for (var {head, tail} of sexpToSexps(sexp)) {
                var parsed = false;
                console.log({head, tail});
                if (typeof head === "string" && hasOwnProperty(this._subevents, head)) {
                    zrfChildParse(this, head, tail, this._subevents[head]);
                    parsed = true;
                }
                if (!parsed) {
                    console.log(`**NYI: ${this._classname} ${head}`);
                }
            }
        }
    }

    export class File extends Node {
        @parseAs("string")
            version:string;
        @parseAs("Game", "game" /* Subevent name */)
            games:Game;
    }

    export class Directions extends Node {
        dirs:{name:string, dx:number, dy:number}[] = [];
        processSubnodes(dirs:SExp) {
            for (var dir of sexpToSexps(dirs)) {
                var [name, dx, dy] = sexpToStrings(dir);
                this.dirs.push({name, dx: parseInt(dx), dy: parseInt(dy)});

            }
        }
    }

    export class Dimensions extends Node {
        xLabels:string[];
        yLabels:string[];
        x1:number; 
        x2:number;
        y1:number; 
        y2:number;
        width:number;
        height:number;
        processSubnodes(dirs:SExp) {
            var [rows, cols] = sexpToSexps(dirs);
            var [yLabels, yBnds] = sexpToLabeledPair(rows);
            var [xLabels, xBnds] = sexpToLabeledPair(cols);
            var [x1, x2] = sexpToStringPair(xBnds);
            var [y1, y2] = sexpToStringPair(yBnds);
            this.x1 = parseInt(x1), this.x2 = parseInt(x2);
            this.x1 = parseInt(y1), this.x2 = parseInt(y2);
            this.xLabels = xLabels.split("/");
            this.yLabels = yLabels.split("/");
            this.width = this.xLabels.length;
            this.height = this.yLabels.length;
        }
    }

    // A simple language is used to generate moves:
    export class Drops extends Node {
        @parseAs("")
            moveLogic: SExp[];
    }

    export class Piece extends Node {
        @parseAs("string")
            name:string;
        @parseAs("string")
            help:string;
        @parseAs((sexp:SExp, obj) => {
            obj.images = obj.images || {};
            for (var [player, file] of sexpFoldStringPairs(sexp)) {
                obj.images[player] = file;
            }
        }, "image")
            images:StrMap<string>;
        @parseAs("Drops")
            drops:Drops;
    }

    export class Grid extends Node {
        @parseAs((sexp:SExp) => {
            var [x1,y1,x2,y2] = sexpToInts(sexp);
            return {x1,y1,x2,y2};
        })
            "start-rectangle": {x1:number, y1:number, x2:number, y2:number};
        @parseAs("Dimensions")
            dimensions:Dimensions;
        @parseAs("Directions")
            directions:Directions;
    }

    export class Board extends Node {
        @parseAs("string")
            image:string;
        @parseAs("Grid")
            grid:Grid;
    }

    type PiecePlacements = {piece:string, squares:string[]}[];
    type BoardSetupComponent = {player: string, pieces: PiecePlacements};

    export class BoardSetup extends Node {
        components : BoardSetupComponent[] = [];

        processSubnodes(sexp:SExp) {
            for (var [player, pieceSetups] of sexpToSexps(sexp).map(sexpCheckLabeled)) {
                var pieces:PiecePlacements = [];
                for (var [piece, squares] of sexpToSexps(sexp).map(sexpCheckLabeled)) {
                    pieces.push({piece, squares: sexpToStrings(squares)});
                }
                this.components.push({player, pieces});
            }
        }
    }

    export class EndCondition extends Node {
        players:string[];
        condition:string|SExp;
        processSubnodes(components:SExp) {
            // Parse conditions in separate file, same as directionality stuff.
            var [playersSexp, condition] = sexpToList(components).map(sexpBoxIfString);
            this.players = sexpToStrings(playersSexp);
            this.condition = condition;
        }
    }

    export class Game extends Node {
        // Metadata for parser, field name, field type.
        @parseAs("string")    title:        string;
        @parseAs("string")    description:  string;
        @parseAs("string")    history:      string;
        @parseAs("string")    strategy:     string;
        @parseAs("string*")   players:      string[];
        @parseAs("string*")  "turn-order":  string;
        @parseAs("BoardSetup") 
            "board-setup": BoardSetup;
        @parseAs("Board[]", "board") 
            boards: Board[];
        @parseAs("Piece[]", "piece")
            pieces: Piece[];
        @parseAs("EndCondition[]", "draw-condition") 
            "draw-conditions": EndCondition[];
        @parseAs("EndCondition[]", "win-condition") 
            "win-conditions": EndCondition[];
        @parseAs((sexp:SExp) => {
            var [label, value] = sexpToStringPair(sexp);
            return {label, value};
        }) 
            option: Option;
    }

    export interface ZrfCompilerPass<T> {
        File?(obj:File): T;
        Directions?(obj:Directions): T;
        Dimensions?(obj:Dimensions): T;
        Piece?(obj:Piece): T;
        Grid?(obj:Grid): T;
        Board?(obj:Board): T;
        BoardSetup?(obj:BoardSetup): T;
        EndCondition?(obj:EndCondition): T;
        Game?(obj:Game): T;
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    // Statement/condition nodes:
    //   - Once we enter a statement or condition node, everything within it is 
    //   a statement or condition node. Thus, we implement a separate parser scheme 
    //  from above.
    ///////////////////////////////////////////////////////////////////////////////

    export class Statement extends Node {
        
    }

    export class Condition extends Node {
    }
    
}

// Install class names into classes:
for (var key of Object.keys(zrfNodes)) {
    zrfNodes[key].prototype._classname = key;
}

// function zrfExpressionParse():zrfNodes.Expr {
//     
// }

type ParseInfo = {propertyKey: string, type:any}
function zrfChildParse(parent:zrfNodes.Node, childField:string, childValue:SExp, {propertyKey, type}:ParseInfo):void {
    // console.log({func: "_parseField", obj, field, type, value});

    var addData = (v:any) => {
        return parent[propertyKey] = v;
    };
    if (typeof type === "string" && type.substring(type.length - 2, type.length) === "[]") {
        type = type.substring(0, type.length - 2);
        addData = (v:any) => {
            parent[propertyKey] = parent[propertyKey] || [];
            return parent[propertyKey].push(v);
        };
    }

    if (childValue === null) {
        return console.log("**NOT FOUND: " + parent._classname + " " + childField);
    } // Handler function:
    else if (typeof type === 'function') {
        addData(type(childValue, parent));
    } else if (type === 'string') {
        // Simple atom (string):
        //assert.equal(value.length, 1)
        //assert.equal(typeof value[0], 'string')
        addData(sexpStringCast(childValue.head));
    } else if (type == 'string*') {
        // List of simple atoms (strings):
        //    assert.equal(typeof str, 'string')
        addData(sexpToStrings(childValue));
    } else if (type.substring(type.length-1,type.length) != '*') {
        var newNode = new zrfNodes[type]();
        newNode.processSubnodes(childValue);
        addData(newNode);
    } else {
        // List of ZRF nodes:
        type = type.substring(0, type.length - 1);
        addData(sexpToSexps(childValue).map(subNode => {
            var newNode = new zrfNodes[type]();
            newNode.processSubnodes(subNode);
            return newNode;
        }));
    }
}


export function _emitSampleCompilerPass() {
    console.log("var samplePass:zrf.ZrfCompilerPass<void> = {");
    for (var event of Object.keys(zrfNodes)) {
        if (event === "Node") continue;
        var _class = zrfNodes[event];
        console.log(`    ${event}(obj:zrf.${event}) {`);
        for (var subevent of Object.keys(_class.prototype._subevents || {})) {
            var {propertyKey, type} = _class.prototype._subevents[subevent];
            if (propertyKey.indexOf("-") > -1) {
                propertyKey = `["${propertyKey}"]`;
            } else {
                propertyKey = `.${propertyKey}`;
            }
            var tStr = typeof type == "string" ? type : "<function>";
            console.log(`        obj${propertyKey}; // ${tStr}`)
        }
        console.log(`    },`);
    }
    console.log("}");
}

export function _emitCompilerPassInterface() {
    console.log("interface ZrfCompilerPass<T> {");
    for (var event of Object.keys(zrfNodes)) {
        if (event === "Node") continue;
        console.log(`    ${event}(obj:${event}): T;`)
    }
    console.log("}");
}
