assert = require('assert')
clc = require('cli-color')

################################################################################
# ZRF S-expression helpers:
################################################################################'

sexprCopy = (sexpr) ->
    if sexpr.

# Convert an s-expression into a list of expressions
s2l = (sexpr) ->
    l = []
    while sexpr && sexpr.head != null
        l.push sexpr.head
        sexpr = sexpr.tail
    return l

isArray = (obj) ->
    return Object::toString.call(obj) == '[object Array]'

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
        obj[member] = v
    if typeof type == 'object'
        field = field.substring(0, field.length - 1)
        print "Truncating #{member} -> #{field} for #{type[0]}"
        type = type[0]
        addData = (v) ->
            if not obj[member]?
                obj[member] = []
            obj[member].push(v)

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

pprint = (V, indent = 0) ->

    t = ''
    s = ''
    for k in [0..indent]
        t += '  '

    if typeof V != 'object'
        return (if V? then V.toString() else clc.yellow 'null') + '\n'
    else if isArray(V)
        s += "\n"
        for v in V
            s += "#{t}- #{pprint(v, indent + 2)}"
    else 
        if V._classname?
            s += "#{clc.blue V._classname}\n"
        else
            s += "\n"
        for k in Object.keys(V)
            if V[k]?
                s += "#{t} #{clc.green k} #{pprint(V[k], indent + 1)}"
    return s

# Helper for succintly describing the shape of ZRF object model nodes:
def = (name) -> (fields) ->
    Z[name] = class Base 
        _classname: name
        constructor: (list) ->
            fields._init?.call(@, list)
            for {head, tail} in list
                value = s2l(tail)
                parsed = false
                for field in Object.keys(fields)
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

Z.Dimensions = ([rows, cols]) ->
    [yLabels, yBnds] = s2l(rows)
    [xLabels, xBnds] = s2l(cols)
    [@x1, @x2] = s2l(xBnds)
    [@y1, @y2] = s2l(yBnds)
    @xLabels = xLabels.split("/")
    @yLabels = yLabels.split("/")

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

Z.BoardSetup = (players) ->
    @players = players

Z.EndCondition = ([@players, @condition]) ->
    # Parse conditions in separate file, same as directionality stuff.

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
    'draw-conditions': ['EndCondition']
    'win-conditions': ['EndCondition']
}

# Macro substitution:
replaceArguments = (S, replacements) -> 
    if not S? or typeof S != 'object'
        return
    if typeof S.head != 'object'
        for {head, tail} in defines
            if S.head == head
                args = s2l(S.tail)
                replacements = {}
                for i in [1..args.length]
                    replacements["$#{i}"] = args[i-1]
                newObj = copyAndReplaceArguments(S, replacements)
                S.head = newObj.head
                S.tail = newObj.tail
                return
    else
        replaceDefines(S.head, defines)
    replaceDefines(S.tail, defines)

replaceDefines = (S, defines) -> 
    if not S? or typeof S != 'object'
        return
    if typeof S.head != 'object'
        for {head, tail} in defines
            if S.head == head
                args = s2l(S.tail)
                replacements = {}
                for i in [1..args.length]
                    replacements["$#{i}"] = args[i-1]
                newObj = copyAndReplaceArguments(S, replacements)
                S.head = newObj.head
                S.tail = newObj.tail
                return
    else
        replaceDefines(S.head, defines)
    replaceDefines(S.tail, defines)

findAndReplaceDefines = (S) -> 
    print "BEFORE REPLACEMENT"
    # Defines should be top level:
    defines = []
    for {head,tail} in s2l(S)
        if head == 'define'
            defines.push(tail)
    for v in s2l(S)
        if v.head != 'define'
            replaceDefines(v, defines)
    print "AFTER REPLACEMENT"
    print(S)

module.exports = {

    sexpToZrfObjModel: (S) -> 
        findAndReplaceDefines(S)
        model = new Z.File(s2l(S))
        #print pprint(model)
        return model
}
