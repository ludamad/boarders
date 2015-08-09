// ZRF S-expression helpers:

// The ZRF object model:
export var zrfEvents:any = {};

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
                var args = s2l(S.tail);
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

function findAndReplaceDefines(S) {
    // Defines should be top level:
    var defines, newNodes;
    defines = [];
    newNodes = [];
    s2l(S).forEach((node) => {
        if (node.head === "define") {
            return defines.push(node.tail);
        } else {
            return newNodes.push(node);
        }
    });
    newNodes.forEach((v) => replaceDefines(v, defines));
    return newNodes;
}

function zrfEvent(name, fields) {
    function event(list) {
        if (fields._init) fields._init.call(this, list);
        for (var {head, tail} of list) {
            var value = s2l(tail);
            var parsed = false;
            for (var field of Object.keys(fields)) {
                if (field === head || field === head + 's') {
                    console.log(field);
                    console.log(head);
                    _parseField(this, field, fields[field], value);
                    parsed = true;
                    break;
                }
            }
            if (!parsed) {
                console.log(`**NYI: ${name} ${head}`);
            }
        }
    };
    event.prototype._classname = name;
    event.prototype.print = function() {
        return console.log(pprint(this));
    }
    event.prototype.fields = fields;
    zrfEvents[name] = event;
}

class Dimensions {
    xLabels:string[];
    yLabels:string[];
    width:number;
    height:number;
    constructor([rows, cols]) {
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

zrfEvents.Dimensions = Dimensions;

zrfEvent("File", {
    version: "string",
    games: ["Game"]
});

zrfEvent("Directions", {
    dirs: (S) => [S.map((s) => s2l(s))]
});

zrfEvent("Piece", {
    name: "string",
    help: "string",
    image: function(S) {
        this.images = this.images || {};
        for (var [player, file] of toPairs(S)) {
            this.images[player] = file;
        }
    },
    drops: (S) => S
});

zrfEvent("Grid", {
    "start-rectangle": ([x1,x2,y1,y2]) => {
        return {
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2
        };
    },
    dimensions: "Dimensions",
    directions: "Directions"
});

zrfEvent("Board", {
    image: "string",
    grid: "Grid"
});

zrfEvents.BoardSetup = function (players) {
    this.players = players;
};

zrfEvents.EndCondition = function ([players, condition]) {
    // Parse conditions in separate file, same as directionality stuff.
    this.players = players;
    this.condition = condition;
};

zrfEvent("Game", {
    title: "string",
    description: "string",
    history: "string",
    strategy: "string",
    players: "string*",
    "turn-order": "string*",
    "board-setup": "BoardSetup",
    boards: ["Board"],
    pieces: ["Piece"],
    option: ([label, value]) => {
        return {label, value}
    },
    "draw-conditions": ["EndCondition"],
    "win-conditions": ["EndCondition"]
});

export function migrateToTypescript() {
    console.log("<BEGIN>")
    for (var className of Object.keys(zrfEvents)) {
        var fields = zrfEvents[className].prototype.fields;
        if (!fields) continue;
        console.log(`@event("${className}")`);
        console.log(`class ${className} {`);
        for (var field of Object.keys(fields)) {
            if (typeof field == "object") {
                field = `${field[0]}[]`
            }
            field.replace("*", "[]");
            console.log(`    @subevent("${fields[field]}")`);
            console.log(`        ${field}:${fields[field]};`);
        }
        console.log(`}`);
        console.log("");
    }
    console.log("<END>")
}
export function sexpToZrfObjModel(S) {
    var nodes = findAndReplaceDefines(S);
    var model = new zrfEvents.File(nodes);
    console.log(pprint(model));
    return model;
};