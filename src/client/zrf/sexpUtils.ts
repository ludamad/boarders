import {SExp} from "./sexp"

// These could be represented by a smaller number of more dynamic operations.
// However, I favoured the more verbose approach that gave fairly good type information.

export function sexprCopy(sexpr:SExp):SExp {
    if (sexpr == null) {
        return sexpr;
    } else {
        return {
            head: (typeof sexpr.head === "string" ? sexpr.head : sexprCopy(<SExp>sexpr.head)),
            tail: sexprCopy(sexpr.tail)
        };
    }
}

export function sexprVisitNamed(sexpr:SExp, f:(SExp)=>void) {
    if (sexpr == null) {
        return;
    }
    if (typeof sexpr.head === "string") {
        f(sexpr);
    }
    // Purposefully allow head to be turned into an object which we further investigate:
    if ((sexpr.head != null) && typeof sexpr.head === "object") {
        sexprVisitNamed(<SExp>sexpr.head, f);
    }
    return sexprVisitNamed(sexpr.tail, f);
}

// Convert an s-expression into a list of expressions
export function sexpToList(sexpr:SExp): (string|SExp)[] {
    var l:(string|SExp)[] = [];
    while (sexpr && sexpr.head !== null) {
        l.push(sexpr.head);
        sexpr = sexpr.tail;
    }
    return l;
}

function checkString(val, wanted) {
    if ((typeof val === "string") !== wanted) {
        if (wanted) throw new Error(`Expecting string for "${val}"!`);
        else throw new Error(`Not expecting string "${val}"!`);
    }
}

export function sexpToStrings(sexpr:SExp): string[] {
    var list = sexpToList(sexpr);
    for (var val of list) checkString(val, true);
    return <string[]>list;
}

export function sexpToSexps(sexpr:SExp): SExp[] {
    var list = sexpToList(sexpr);
    for (var val of list) checkString(val, false);
    return <SExp[]>list;
}

// Fold an s-expression list into a list of pairs of s-expressions
export function sexpToPairs(l:SExp[]):(string|SExp)[][] {
    var pairs:(string|SExp)[][] = [];
    var i = 0;
    while (i < l.length) {
        pairs.push([l[i], l[i + 1]]);
        i += 2;
    }
    return pairs;
}

export function sexpIntCast(s:string|SExp):number {
    if (typeof s === "string") {
        return parseInt(s);
    }
    throw new Error("SExp should resolve to an integer-bearing string!");
}

export function sexpStringCast(s:string|SExp):string {
    if (typeof s === "string") {
        return s;
    }
    throw new Error("SExp should resolve to string!");
}

export function sexpToLabeledPair(sexpr:SExp):[string, SExp] {
    var pair = sexpToList(sexpr);
    if (typeof pair[0] !== "string" || !pair[1] || typeof pair[1] === "string") {
        throw new Error("Expected string+SExp pair!");
    }
    return <[string, SExp]>pair;
}

export function sexpCheckLabeled(sexpr:SExp):{head:string, tail?:SExp} {
    checkString(sexpr.head, true);
    return <any>sexpr;
}

// export function sexpToLabeledPairs(sexpr:SExp):[string, SExp][] {
//     return sexpToSexps(sexpr).map(sexpToLabeledPair);
// }

// Forgive the duplication.
export function sexpToStringPair(sexpr:SExp):[string, string] {
    var pair = sexpToList(sexpr);
    if (pair.length !== 2) {
        throw new Error("Expected pair!");
    }
    if (typeof pair[0] !== "string" || typeof pair[1] !== "string") {
        throw new Error("Expected string+string pair!");
    }
    return <[string, string]>pair;
}

// Fold an s-expression into a list of pairs of s-expressions
export function sexpFoldStringPairs(sexp:SExp):[string, string][] {
    var pairs:[string, string][] = [];
    var i = 0;
    var l = sexpToList(sexp);
    while (i < l.length) {
        if (typeof l[i] !== "string" || typeof l[i + 1] !== "string") {
            throw new Error("Expected string+string pair!");
        }
        pairs.push(<[string, string]>[l[i], l[i + 1]]);
        i += 2;
    }
    return pairs;
}

export function sexpBoxIfString(sexpr:string|SExp): SExp {
    return (typeof sexpr === "string") ? {head: sexpr} : sexpr;
}

export function sexpToInts(sexpr:SExp): number[] {
    return sexpToList(sexpr).map(sexpIntCast);
}