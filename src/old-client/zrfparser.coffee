sexp = require("./sexp.js")

{sexpToZrfObjModel} = require './zrf'

################################################################################
# Raw s-expression parsing:
################################################################################'

parseRaw =(content) ->
    # Keep our parser simple by sanitizing parts of the file, for now (TODO integrate into parser maybe.)

    # Remove comments:
    content = content.replace(/;[^\n]*/g, "")
    # Replace \ with /:
    content = content.replace(/\\/g, '/')
    # Parse a list:
    content = "(" + content + ")"
    parsed = sexp.parse(content)
    return parsed

parse = (content) ->
    sexps = parseRaw(content)
    #zrfObjModel = new ZrfFile(sexps)
    zrfObjModel = sexpToZrfObjModel(sexps)
    return zrfObjModel

module.exports = {parseRaw, parse}
