fs = require("fs")

assert = require('assert')
sexp = require("./sexp")

{sexpToZrfObjModel} = require './zrf'

################################################################################
# Raw s-expression parsing:
################################################################################'

parseRaw =(fileName) ->
    content = fs.readFileSync(fileName, "utf8")

    # Keep our parser simple by sanitizing parts of the file, for now (TODO integrate into parser maybe.)

    # Remove comments:
    content = content.replace(/;[^\n]*/g, "")
    # Replace \ with /:
    content = content.replace(/\\/g, '/')
    # Parse a list:
    content = "(" + content + ")"
    parsed = sexp.parse(content)
    return parsed

parse = (fileName) ->
    sexps = parseRaw(fileName)
    #zrfObjModel = new ZrfFile(sexps)
    zrfObjModel = sexpToZrfObjModel(sexps)
    return zrfObjModel

module.exports = {parseRaw, parse}
