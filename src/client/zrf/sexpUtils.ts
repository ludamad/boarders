
export function sexprCopy(sexpr) {
    if (sexpr == null || typeof sexpr !== "object") {
        return sexpr;
    }
    return {
        head: sexprCopy(sexpr.head),
        tail: sexprCopy(sexpr.tail)
    };
}

export function sexprVisitNamed(sexpr, f) {
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
export function s2l(sexpr) {
    var l;
    l = [];
    while (sexpr && sexpr.head !== null) {
        l.push(sexpr.head);
        sexpr = sexpr.tail;
    }
    return l;
}

// Convert an s-expression into a list of lists of expressions
export function s2ll(sexpr) {
    return [s2l(sexpr).map((S) => s2l(S))];
}

// Fold an s-expression list into a list of pairs of s-expressions
export function sexpToPairs(l) {
    var pairs = [];
    var i = 0;
    while (i < l.length) {
        pairs.push([l[i], l[i + 1]]);
        i += 2;
    }
    return pairs;
}