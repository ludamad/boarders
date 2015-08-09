import * as sexp from "./sexp"
import {sexpToZrfObjModel} from "./zrfObjectModel";

// Raw s-expression parsing:
export function parseRaw(content) {
    // Keep our parser simple by sanitizing parts of the file, for now (TODO integrate into parser maybe.)
    // Remove comments:
    content = content.replace(/;[^\n]*/g, "");
    // Replace \ with /:
    content = content.replace(/\\/g, "/");
    // Parse a list:
    content = "(" + content + ")";
    var parsed = sexp.parse(content);
    return parsed;
}

export function parse(content:string) {
    var sexps = parseRaw(content);
    //var zrfObjModel = new ZrfFile(sexps)
    var zrfObjModel = sexpToZrfObjModel(sexps);
    return zrfObjModel;
}
