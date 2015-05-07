assert = require('assert')

################################################################################
# ZRF S-expression helpers:
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

################################################################################
# The ZRF object model:
################################################################################'

Z = {}

_parseField = (obj, field, type, value) ->
    member = field

    addData = (v) ->
        obj[field] = v
    if typeof type == 'object'
        field = field.substring(0, field.length - 1)
        print "Truncating #{member} -> #{field} for #{type[0]}"
        type = type[0]
        addData = (v) ->
            if not obj[field]?
                obj[field] = []
            obj[field].push(v)

    ###################################################
    # Dispatch based on type field, whether it is an object, and whether it ends in '*'
    ###################################################

    if value == null
        print "**NOT FOUND: #{obj._classname} #{field}"

    # Handler function:
    else if typeof type == 'function'
        addData type(value)

    # Simple atom (string):
    else if type == 'string'
        assert.equal(value.length, 1)
        assert.equal(typeof value[0], 'string')
        addData value[0]

    # List of simple atoms (strings):
    else if type == 'string*'
        for str in value
            assert.equal(typeof str, 'string')
        addData value

    # ZRF object:
    else if type.substring(type.length-1,type.length) != '*'
        addData new Z[type](value)
    
    # List of ZRF objects:
    else
        type = type.substring(0, type.length - 1)
        addData [new Z[type](s2l(S)) for S in value]

# Helper for succintly describing the shape of ZRF object model nodes:
def = (name) -> (fields) ->
    Z[name] = class Base 
        constructor: (list) ->
            fields._init?.call(@, list)
            for {head, tail} in list
                value = s2l(tail)
                parsed = false
                for field of fields 
                    if field.indexOf(head) == 0
                        _parseField(@, field, fields[field], value)
                        parsed = true
                        break
                if not parsed
                    print "**NYI: #{name} #{head}"

def('File') {
    version: 'string'
    games: ['Game']
}

def('Dimensions') {
    _init: (list) ->
        [rows, cols] = list
        [yLabels, yBnds] = s2l(rows)
        [xLabels, xBnds] = s2l(cols)
        [@x1, @x2] = s2l(xBnds)
        [@y1, @y2] = s2l(yBnds)
        @xLabels = xLabels.split("/")
        @yLabels = yLabels.split("/")
}

def('Directions') {
    dirs: s2ll
}

def('Piece') {
    name: 'string', help: 'string'
    image: s2pairs
    drops: (S) ->
        print('drops ' + JSON.stringify S)
}

def('Grid') {
    'start-rectangle': s2l
    dimensions: 'Dimensions'
    directions: 'Directions'
}

def('Board') {
    image: s2l
    grid: 'Grid'
}

def('BoardSetup') {
    parts: s2l
}

def('Game') {
    title: 'string', description: 'string'
    history: 'string', strategy: 'string'
    players: 'string*'
    'turn-order': 'string*'
    'board-setup': 'BoardSetup'
    boards: ['Board']
    pieces: ['Piece']
    option: (S) ->
        [label, value] = S
        return {label, value}
}

module.exports = {
    sexpToZrfObjModel: (S) -> new Z.File(s2l(S))
}
