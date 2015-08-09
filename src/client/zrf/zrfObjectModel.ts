"use strict";

import {SExp} from "./sexp"
import {
    sexprCopy, sexpToList, sexpToSexps, sexpToStrings, sexprVisitNamed, sexpToPairs, 
    sexpToLabeledPair, sexpStringCast, sexpToStringPair, sexpBoxIfString,
    sexpFoldStringPairs, sexpToInts, sexpCheckLabeled
} from "./sexpUtils";

function subevent(type:any, name?:string) : PropertyDecorator {
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
// TODO: See if Typescript bug is creating the need for this:
var Option = "hackForMetadataPurposes";

function hasOwnProperty(obj:Object, key:string) {
    return Object.prototype.hasOwnProperty.call(obj, key);
}

// Classes for the ZRF object model. Define parsing events with metadata.
// The names of the classes themselves are used for matching events triggered.
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
                    _parseField(this, head, this._subevents[head], tail);
                    parsed = true;
                }
                if (!parsed) {
                    console.log(`**NYI: ${this._classname} ${head}`);
                }
            }
        }
        print() {
            console.log(pprint(this));
        }
    }

    export class File extends Node {
        @subevent("string")
            version:string;
        @subevent("Game", "game" /* Subevent name */)
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

    // Move logic forms its own crude language within Zillions:
    export class MoveLogic extends Node {
        moveLogic: SExp[];
        processSubnodes(moveLogic) {
            this.moveLogic = moveLogic;
        }
    }

    export class Piece extends Node {
        @subevent("string")
            name:string;
        @subevent("string")
            help:string;
        @subevent((sexp:SExp, obj) => {
            obj.images = obj.images || {};
            for (var [player, file] of sexpFoldStringPairs(sexp)) {
                obj.images[player] = file;
            }
        }, "image" /*Event name*/)
            images:StrMap<string>;
        @subevent("MoveLogic")
            drops:MoveLogic;
    }

    export class Grid extends Node {
        @subevent((sexp:SExp) => {
            var [x1,y1,x2,y2] = sexpToInts(sexp);
            return {x1,y1,x2,y2};
        })
            "start-rectangle": {x1:number, y1:number, x2:number, y2:number};
        @subevent("Dimensions")
            dimensions:Dimensions;
        @subevent("Directions")
            directions:Directions;
    }

    export class Board extends Node {
        @subevent("string")
            image:string;
        @subevent("Grid")
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
        @subevent("string")   title:        string;
        @subevent("string")   description:  string;
        @subevent("string")   history:      string;
        @subevent("string")   strategy:     string;
        @subevent("string*")  players:      string[];
        @subevent("string*") "turn-order":  string;
        @subevent("BoardSetup") "board-setup": BoardSetup;
        @subevent("Board[]", "board") 
            boards: Board[];
        @subevent("Piece[]", "piece")
            pieces: Piece[];
        @subevent("EndCondition[]", "draw-condition") 
            "draw-conditions": EndCondition[];
        @subevent("EndCondition[]", "win-condition") 
            "win-conditions": EndCondition[];
        @subevent((sexp:SExp) => {
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
}

export function _emitCompilerPassInterface() {
    console.log("interface ZrfCompilerPass<T> {");
    for (var event of Object.keys(zrfNodes)) {
        if (event === "Node") continue;
        console.log(`    ${event}(obj:${event}): T;`)
    }
    console.log("}");
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

type ParseInfo = {propertyKey: string, type:any}
function _parseField(obj:zrfNodes.Node, field:string, {propertyKey, type}:ParseInfo, value:SExp) {
    // console.log({func: "_parseField", obj, field, type, value});

    var addData = (v:any) => {
        return obj[propertyKey] = v;
    };
    if (typeof type === "string" && type.substring(type.length - 2, type.length) === "[]") {
        type = type.substring(0, type.length - 2);
        addData = (v:any) => {
            obj[propertyKey] = obj[propertyKey] || [];
            return obj[propertyKey].push(v);
        };
    }

    if (value === null) {
        return console.log("**NOT FOUND: " + obj._classname + " " + field);
    } // Handler function:
    else if (typeof type === 'function') {
        addData(type(value, obj));
    } else if (type === 'string') {
        // Simple atom (string):
        //assert.equal(value.length, 1)
        //assert.equal(typeof value[0], 'string')
        addData(sexpStringCast(value.head));
    } else if (type == 'string*') {
        // List of simple atoms (strings):
        //    assert.equal(typeof str, 'string')
        addData(sexpToStrings(value));
    } else if (type.substring(type.length-1,type.length) != '*') {
        var newNode = new zrfNodes[type]();
        newNode.processSubnodes(value);
        addData(newNode);
    } else {
        // List of ZRF nodes:
        type = type.substring(0, type.length - 1);
        addData(sexpToSexps(value).map(subNode => {
            var newNode = new zrfNodes[type]();
            newNode.processSubnodes(subNode);
            return newNode;
        }));
    }
}

for (var key of Object.keys(zrfNodes)) {
    zrfNodes[key].prototype._classname = key;
}

///////////////////////////////////////////////////////////////////////////////
// ZRF utils
///////////////////////////////////////////////////////////////////////////////

// Pretty print a ZRF node:
function pprint(V, indent = 0) {
    var clc = require("cli-color"), s = "", t = "";
    for (var i = 0; i < indent + 1; i++) {
        t += " ";
    }
    if (typeof V !== "object") {
        return (V != null ? V.toString() : clc.yellow("null")) + "\n";
    } else if (Array.isArray(V)) {
        s += "\n";
        V.forEach((v) => s += t + "- " + (pprint(v, indent + 2)));
    } else {
        if (V._classname != null) {
            s += (clc.blue(V._classname)) + "\n";
        } else {
            s += "\n";
        }
        for (var k of Object.keys(V)) {
            if (V[k] != null) {
                s += t + " " + (clc.green(k)) + " " + (pprint(V[k], indent + 1));
            }
        }
    }
    return s;
}

///////////////////////////////////////////////////////////////////////////////
// ZRF macro substitution
///////////////////////////////////////////////////////////////////////////////

//Macro substitution for arguments eg $1, $2:

function replaceArguments(S, replacements) {
    return sexprVisitNamed(S, (child) => {
        if (replacements[child.head] != null) {
            var r = sexprCopy(replacements[child.head]);
            return child.head = r;
        }
    });
}

function replaceDefines(S, defines) {
    if ((S == null) || typeof S !== "object") {
        return;
    }
    if (typeof S.head !== "object") {
        for (var {head, tail} of defines) {
            if (S.head === head) {
                var args = sexpToList(S.tail);
                var replacements = {};
                for (var i = 0; i < args.length; i++) {
                    replacements["$" + (i+1)] = args[i];
                }
                var newObj = sexprCopy(tail);
                replaceArguments(newObj, replacements);
                S.head = newObj.head;
                S.tail = newObj.tail;
            }
        }
    } else {
        replaceDefines(S.head, defines);
    }
    return replaceDefines(S.tail, defines);
}

function findAndReplaceDefines(S:SExp):SExp {
    // Defines should be top level:
    var defines:SExp[] = [], newNode:SExp = {head: S.head};
    var iter = newNode;
    for (var node of sexpToList(S)) {
        if (typeof node !== "string" && node.head === "define") {
            defines.push(node.tail);
        } else {
            // Relink nodes, removing the defines:
            iter.tail = {head: node};
            iter = iter.tail;
        }
    }
    // Inline globally the result of the defines:
    replaceDefines(newNode, defines);
    return newNode;
}

export function sexpToZrfObjModel(S) {
    var nodes = findAndReplaceDefines(S);
    var model = new zrfNodes.File();
    model.processSubnodes(nodes);
    console.log("<model>");
    model.print();
    console.log("</model>");
    return model;
};