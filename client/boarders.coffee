################################################################################
# Boarders public API for hosted Javascript games.
#
# API Version: 0.0.?
#
# This code should be usable anywhere, but only games hosted on the server can be played through the Boarders server.
# Networking primitives are decidedly not to ever be exposed. The fact that the code is so tied to the Boarders server 
# should not be evident during local testing.
#
# Current goals are to provide a convenient framework for Chesslikes. 
#
# Playing areas should be represented as graphs, but so far the plan is onlyto 
# provide rendering support for square grids. 
#
# Similarly, logic can be anything, but current display support is limited to 
# one image per square.
#
# Stretch goals:
# Maybe provide JSFiddle-like environment eventually.
################################################################################

anyboard = require "./anyboard"

# Tentatively the following is the 'BRF object model', 
# which the ZRF object model is compiled to,
# and which the Boarders API emits. (Architecture is hard)

# This is user facing code, use getters and underscored members:
class Enumerator
    constructor: (@_next = 0) ->
    next: () -> return (@_next++)
    total: () -> @_next

# This is user facing code, use getters and underscored members:
class Cell
    constructor: () ->
        @_directions = {}
    enumId: (@_enumId = @_enumId) -> @_enumId
    next: (dir, val = @_directions[dir]) -> 
        @_directions[dir] = val;
        return @_directions[dir]

# This is user facing code, use getters and underscored members:
class Graph # Base class
    constructor: () ->
        @_directions = {}
    # Enumeration refers to turning data about cells into 
    # a bunch of indices:
    _enumerateCells: (enumerator) ->
        for cell in @cellList()
            cell.enumId(enumerator.next())
    _enumerateDir: (enumerator, dir) ->
        @_directions[dir] = [-1 for _ in [0..enumerator.total()-1]]
        for cell in @cellList()
            @_directions[dir][cell.enumId()] = cell.next(dir).enumId()

    cellList: () -> throw new Error("Abstract method called!")

# This is user facing code, use getters and underscored members:
class Grid extends Graph
    constructor: (@id, @_width, @_height, cellIds) ->
       mkRow = (y, w) -> 
           return [ {id: cellIds(x, y), x, y} for x in [0 .. w - 1] ]
       @_cells = [mkRow(y, @width()) for y in [0 .. @height() - 1]]

    defineDirection: (name, mapping) ->
        for cell in @cellList()
            mapping(cell)
    cellList: () ->
        accum = []
        for row in @_cells 
            accum.concat(row)
        return accum
    setupHtml: () ->
        anyboard.HtmlBoard()

    # At least coffee makes writing getter-setters bearable.
    width:  (@_width  = @_width)  -> @_width
    height: (@_height = @_height) -> @_height

class Player
    constructor: (@id) ->

class Piece
    constructor: (@id) ->

class GameState
    constructor: () ->
        @cellContents = []

algebraic = (x, y) ->
    return "#{String.fromCharCode 97 + y}{1 + x}"

# Game rules object.
class Rules 
    constructor: () ->
        @_cellEnumerator = new Enumerator()
        @_pieceEnumerator = new Enumerator()
        @_players = []
        @_grids = []
        @_turnsCanPass = false
        @_stacks = []
        @_pieces = []
    grid: (name, w, h, cellNames = algebraic) ->
        @_grids.push new Grid(name, w, h, cellNames)

    getGrid: (id) ->
        for grid in @_grids 
            if grid.id == id then return grid
    getStack: (id) ->
        for stack in @_stacks 
            if stack.id == id then return stack
    getPiece: (id) ->
        for piece in @_pieces 
            if piece.id == id then return piece
    getHtmlComponent: (container) ->
        playArea = new anyboard.HtmlPlayArea(container)
        for grid in @_grids
            playArea.board grid.id, grid.width(), grid.height()
        return playArea

################################################################################
# BRF expressions
################################################################################

# Due to symmetry making directions more complex
# we store direction expressions as a set of actual 
# directions for each player
class ExprDirection
    constructor: (@playerDirs) ->

class ExprStep
    constructor: (@direction) ->

class ExprVerify
    constructor: () ->

module.exports = {Cell, Grid, Rules}
