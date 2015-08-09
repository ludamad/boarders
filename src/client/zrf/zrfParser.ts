import {SExp, sexpParse} from "./sexpParser";
// We must replace defines before passing to zrfFromSexp:
import {zrfNodes, zrfFromSexpWithNoMacros} from "./zrfFromSexp";
import {zrfPrettyPrint} from "./zrfUtils";

import {sexpToList, sexprCopy, sexprVisitNamed} from "./sexpUtils";

////////////////////////////////////////////////////////////////////////////////
// Public interface
////////////////////////////////////////////////////////////////////////////////

// Main export:
export function zrfParse(content:string):zrfNodes.Node {
    var sexp = sanitizeAndSexpParse(content);
    // Resolve all macros:
    sexp = findAndReplaceDefines(sexp);
    return zrfFromSexpWithNoMacros(sexp);
}

////////////////////////////////////////////////////////////////////////////////
// Testing interface
////////////////////////////////////////////////////////////////////////////////

// Raw s-expression parsing:
export function sanitizeAndSexpParse(content):SExp {
    // Keep our parser simple by sanitizing parts of the file, for now (TODO integrate into parser maybe.)
    // Remove comments:
    content = content.replace(/;[^\n]*/g, "");
    // Replace \ with /:
    content = content.replace(/\\/g, "/");
    // Parse a list:
    content = "(" + content + ")";
    return sexpParse(content);
}

////////////////////////////////////////////////////////////////////////////////
// Macro subsitution logic:
////////////////////////////////////////////////////////////////////////////////

function replaceArguments(sexp:SExp, replacements):SExp {
    return sexprVisitNamed(sexp, (child) => {
        if (replacements[child.head] != null) {
            var r = sexprCopy(replacements[child.head]);
            return child.head = r;
        }
    });
}

function replaceDefines(sexp:SExp, defines):SExp {
    if ((sexp == null) || typeof sexp !== "object") {
        return;
    }
    if (typeof sexp.head !== "object") {
        for (var {head, tail} of defines) {
            if (sexp.head === head) {
                var args = sexpToList(sexp.tail);
                var replacements = {};
                for (var i = 0; i < args.length; i++) {
                    replacements["$" + (i+1)] = args[i];
                }
                var newObj = sexprCopy(tail);
                replaceArguments(newObj, replacements);
                sexp.head = newObj.head;
                sexp.tail = newObj.tail;
            }
        }
    } else {
        replaceDefines(<SExp>sexp.head, defines);
    }
    return replaceDefines(sexp.tail, defines);
}

// Resolve macros:
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

