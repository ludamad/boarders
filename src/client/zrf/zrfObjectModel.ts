export module zrfEvents {
    function subevent(type:any, name?:string) {
        // Property decorator:
        return function(target: any, propertyKey: string) {
            target.prototype._subevents = target.prototype._subevents || {};
            target.prototype._subevents[name || propertyKey] = type;
        }
    }

    interface StrMap<T> {
        [s: string]: T;
    }
    type Option = {label: string, value:any};

    export class File {
        @subevent("string")
            version:string;
        @subevent("Game")
            games:Game;
    }

    export class Directions {
        @subevent((S) => [S.map(s => s2l(s))])
            dirs:string[];
    }
    

    class Dimensions {
        xLabels:string[];
        yLabels:string[];
        width:number;
        height:number;
        processSubnodes([rows, cols]) {
            var [yLabels, yBnds] = s2l(rows);
            var [xLabels, xBnds] = s2l(cols);
            var [x1, x2] = s2l(xBnds);
            var [y1, y2] = s2l(yBnds);
            this.xLabels = xLabels.split("/");
            this.yLabels = yLabels.split("/");
            this.width = this.xLabels.length;
            this.height = this.yLabels.length;
        }
    }

    export class Piece {
        @subevent("string")
            name:string;
        @subevent("string")
            help:string;
        @subevent((S, obj) => {
            obj.images = obj.images || {};
            for (var [player, file] of toPairs(S)) {
                obj.images[player] = file;
            }
        }, "image" /*Event name*/)
            images:StrMap<string>;
        @subevent((S) => S)
            drops;
    }

    export class Grid {
        @subevent(([x1,y1,x2,y2]) => {x1,y1,x2,y2})
            "start-rectangle": {x1:number, y1:number, x2:number, y2:number};
        @subevent("Dimensions")
            dimensions:Dimensions;
        @subevent("Directions")
            directions:Directions;
    }

    export class Board {
        @subevent("string")
            image:string;
        @subevent("Grid")
            grid:Grid;
    }

    
    class BoardSetup {
        players:string[];
        processSubnodes(players) {
            this.players = players;
        }
    }

    class EndCondition {
        players:string[];
        condition:string[];
        processSubnodes([players, condition]) {
            // Parse conditions in separate file, same as directionality stuff.
            this.players = players;
            this.condition = condition;
        }
    }

    export class Game {
        // Metadata for parser, field name, field type.
        @subevent("string")   title:        string;
        @subevent("string")   description:  string;
        @subevent("string")   history:      string;
        @subevent("string")   strategy:     string;
        @subevent("string*")  players:      string[];
        @subevent("string*") "turn-order":  string;
        @subevent("string*") "board-setup": BoardSetup;
        @subevent("Board[]")  boards: Board[];
        @subevent("Piece[]")  pieces: Piece[];
        @subevent("EndCondition[]") 
            "draw-conditions": EndCondition[];
        @subevent("EndCondition[]") 
            "win-conditions": EndCondition[];
        @subevent(([label, value]) => {label, value})
            option: Option;
    }
}

function sexprCopy(sexpr) {
    if (sexpr == null || typeof sexpr !== "object") {
        return sexpr;
    }
    return {
        head: sexprCopy(sexpr.head),
        tail: sexprCopy(sexpr.tail)
    };
}

function sexprVisitNamed(sexpr, f) {
    if (sexpr == null) {
        return;
    }
    if (typeof sexpr.head === "string") {
        f(sexpr);
    }
    // Purposefully allow head to be turned into an object which we further investigate:
    if ((sexpr.head != null) && typeof sexpr.head === "object") {
        sexprVisitNamed(sexpr.head, f);
    }
    return sexprVisitNamed(sexpr.tail, f);
}

// Convert an s-expression into a list of expressions
function s2l(sexpr) {
    var l;
    l = [];
    while (sexpr && sexpr.head !== null) {
        l.push(sexpr.head);
        sexpr = sexpr.tail;
    }
    return l;
}

function isArray(obj) {
    return (obj != null) && (obj.constructor === Array);
}

// Convert an s-expression into a list of lists of expressions
function s2ll(sexpr) {
    return [s2l(sexpr).map((S) => s2l(S))];
}

// Fold an s-expression list into a list of pairs of s-expressions
function toPairs(l) {
    var pairs = [];
    var i = 0;
    while (i < l.length) {
        pairs.push([l[i], l[i + 1]]);
        i += 2;
    }
    return pairs;
}

function _parseField(obj, field, type, value) {
    var member = field;

    var addData = (v) => {
        return obj[member] = v;
    };
    if (typeof type === "object") {
        field = field.substring(0, field.length - 1);
        type = type[0];
        addData = (v) => {
            console.log(member);
            console.log(v);
            if (obj[member] == null) {
                obj[member] = [];
            }
            return obj[member].push(v);
        };
    }

    if (value === null) {
        return console.log("**NOT FOUND: " + obj._classname + " " + field);
    }

    // Handler function:
    else if (typeof type === 'function') {
        addData(type.bind(obj)(value));
    } else if (type === 'string') {
        // Simple atom (string):
        //assert.equal(value.length, 1)
        //assert.equal(typeof value[0], 'string')
        addData(value[0]);
    } else if (type == 'string*') {
        // List of simple atoms (strings):
        //    assert.equal(typeof str, 'string')
        addData(value);
    } else if (type.substring(type.length-1,type.length) != '*') {
        addData(new zrfEvents[type](value));
    } else {
        // List of ZRF objects:
        type = type.substring(0, type.length - 1);
        addData(value.map(S => new zrfEvents[type](s2l(S))));
    }
}

// Pretty print a ZRF node:
function pprint(V, indent = 0) {
    var clc = require("cli-color"), s = "", t = "";
    for (var i = 0; i < indent + 1; i++) {
        t += " ";
    }
    if (typeof V !== "object") {
        return (V != null ? V.toString() : clc.yellow("null")) + "\n";
    } else if (isArray(V)) {
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
                return s += t + " " + (clc.green(k)) + " " + (pprint(V[k], indent + 1));
            }
        }
    }
    return s;
}
