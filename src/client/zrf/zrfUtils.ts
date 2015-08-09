// Pretty print a ZRF node:
export function zrfPrettyPrint(V, indent = 0) {
    var clc = require("cli-color"), s = "", t = "";
    for (var i = 0; i < indent + 1; i++) {
        t += " ";
    }
    if (typeof V !== "object") {
        return (V != null ? V.toString() : clc.yellow("null")) + "\n";
    } else if (Array.isArray(V)) {
        s += "\n";
        V.forEach((v) => s += t + "- " + (zrfPrettyPrint(v, indent + 2)));
    } else {
        if (V._classname != null) {
            s += (clc.blue(V._classname)) + "\n";
        } else {
            s += "\n";
        }
        for (var k of Object.keys(V)) {
            if (V[k] != null) {
                s += t + " " + (clc.green(k)) + " " + (zrfPrettyPrint(V[k], indent + 1));
            }
        }
    }
    return s;
}