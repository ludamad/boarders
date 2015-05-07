sys = require("sys")
fs = require("fs")

assert = require('assert')
sexp = require("./sexp")

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

################################################################################
# The ZRF object model:
################################################################################'

# Convert an s-expression into a list of expressions
s2l = (sexpr) ->
    l = []
    while sexpr && sexpr.head != null
        l.push sexpr.head
        sexpr = sexpr.tail
    return l

# Convert an s-expression into a list of lists of expressions
s2ll = (sexpr) -> [s2l(S) for S in s2l(sexpr)]

# Convert an s-expression into a list of pairs of expressions
s2pairs = (sexpr) ->
    pairs = []
    l = s2l(sexpr)
    i = 0
    while i < l.length
        pairs.push [l[i],l[i+1]]
        i += 2
    return pairs

sUnbox = (sexpr) ->
    assert.equal(sexpr.tail, null)
    return sexpr.head

atomFieldImpl = (field, isAtom) -> (S) ->
    if isAtom
        @[field] = sUnbox(S)
    else
        @[field] = s2l(S)
listFieldImpl = (k, cls) -> (S) ->
    @[k + 's'].push(new cls(S))


class ZrfBase
    constructor: (S, fields, listFields) ->
        for field in fields
            isAtom = true
            if typeof field == 'object'
                [field] = field 
                isAtom = false
            @[field] = null
            @['_' + field] = atomFieldImpl(field, isAtom)
        for k of listFields
            @[k + 's'] = []
            @['_' + k] = listFieldImpl(k, listFields[k])
        @_callHandlers(S)

    _callHandlers: (S) ->
        for {head, tail} in s2l(S)
            if typeof @['_'+head] == 'function'
                @['_'+head](tail)
            else
                print "**NIY: #{@_classname}._#{head}(S)"

class ZrfFile extends ZrfBase
    _classname: 'ZrfFile'
    constructor: (S) -> 
        super S, 
            ['version'], # Simple attributes
            {game: ZrfGame} # Complex attributes
class ZrfDimensions
    _classname: 'ZrfDimensions'
    constructor: (S) -> 
        [rows, cols] = s2l(S)
        [yLabels, yBnds] = s2l(rows)
        [xLabels, xBnds] = s2l(cols)
        [@x1, @x2] = s2l(xBnds)
        [@y1, @y2] = s2l(yBnds)
        @xLabels = xLabels.split("/")
        @yLabels = yLabels.split("/")
class ZrfDirections 
    _classname: 'ZrfDirections'
    constructor: (S) -> 
        @dirs = []
        for dir in s2l(S)
            @dirs.push(s2l(dir))
class ZrfPiece extends ZrfBase
    _classname: 'ZrfPiece'
    constructor: (S) ->
        super(S, ['name', 'help'], {})
    _drops: (S) ->
        print(S)
    _image: (S) ->
        for [kind, img] in s2pairs(S)
            print(kind)
            print(img)
        
class ZrfGrid extends ZrfBase
    _classname: 'ZrfGrid'
    constructor: (S) -> 
        super(S,[
            ['start-rectangle']
        ],{
            dimensions: ZrfDimensions
            directions: ZrfDirections
        })
class ZrfBoard extends ZrfBase
    _classname: 'ZrfBoard'
    constructor: (S) ->
        super S,
            ['image'], {
                grid: ZrfGrid
            }
class ZrfBoardSetup 
    _classname: 'ZrfBoardSetup'
    constructor: (S) ->
        @parts = []
        for [player, pos] in s2ll(S)
            print player
            print pos
class ZrfGame extends ZrfBase
    _classname: 'ZrfGame'
    constructor: (S) ->
        super S, 
            ['title', 'description', 'history', 'strategy',
                ['players'], ['turn-order']], 
            {
                board: ZrfBoard
                piece: ZrfPiece
                "board-setup": ZrfBoardSetup
                option: (S) -> [@label, @value] = s2l(S)
            }

parse = (fileName) ->
    sexps = parseRaw(fileName)
    zrfObjModel = new ZrfFile(sexps)
    return zrfObjModel

module.exports = {parseRaw, parse}
