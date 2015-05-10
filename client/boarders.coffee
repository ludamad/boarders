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

# Helpers:
stringListCast = (players) ->
    if typeof players == "string"
        return [players]
    return players

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
    constructor: (@id, @_x = null, @_y = null) ->
        @_directions = {}
    enumId: (@_enumId = @_enumId) -> @_enumId
    x: (@_x = @_x) -> @_x
    y: (@_y = @_y) -> @_y
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
        @_directions[dir] = (-1 for _ in [0..enumerator.total()-1])
        for cell in @cellList()
            @_directions[dir][cell.enumId()] = cell.next(dir).enumId()

    cellList: () -> throw new Error("Abstract method called!")

# This is user facing code, use getters and underscored members:
class Grid extends Graph
    constructor: (@id, @_width, @_height, cellIds) ->
       mkRow = (y, w) -> 
           return (new Cell(cellIds(x, y), x, y) for x in [0 .. w - 1])
       @_cells = (mkRow(y, @width()) for y in [0 .. @height() - 1])

    defineDirection: (name, mapping) ->
        for cell in @cellList()
            mapping(cell)
    cellList: () ->
        list = []
        for row in @_cells
            for cell in row
                list.push(cell)
        return list

    getCell: (id) ->
        for row in @_cells
            for cell in row
                if cell.id == id
                    return cell
        return null

    # At least coffee makes writing getter-setters bearable.
    width:  (@_width  = @_width)  -> @_width
    height: (@_height = @_height) -> @_height

# This is user facing code, use getters and underscored members:
class Player
    constructor: (@id) ->
    enumId: (@_enumId = @_enumId) -> @_enumId

# This is user facing code, use getters and underscored members:
class Piece
    constructor: (@id) ->
        @_images = {}
    enumId: (@_enumId = @_enumId) -> @_enumId
    image: (players, img) ->
        if not img?
            return @_images[players]
        for p in stringListCast(players)
            @_images[p] = img

# This is user facing code, use getters and underscored members:
class GameState
    constructor: (rules) ->
        @_rules = rules
        @_enumOwners = (copy for copy in rules._initialEnumOwners)
        @_enumPieces = (copy for copy in rules._initialEnumPieces)
    setupHtml: (container) ->
        playArea = new anyboard.HtmlPlayArea(container)
        for grid in @_rules.grids()
            board = playArea.board grid.id, grid.width(), grid.height()
        playArea.setup()
        for grid in @_rules.grids()
            for cell in grid.cellList()
                enumPiece = @_enumPieces[cell.enumId()]
                if enumPiece == -1
                    continue
                enumOwner = @_enumOwners[cell.enumId()]
                owner = @_rules._players[enumOwner].id
                piece = @_rules._pieces[enumPiece]
                img = piece.image(owner)
                board.piece img, cell.x(), cell.y()
        return playArea

algebraic = (x, y) ->
    return "#{String.fromCharCode 97 + x}#{1 + y}"

# Game rules object.
# This is user facing code, use getters and underscored members:
class Rules 
    constructor: () ->
        @_cellEnumerator = new Enumerator()
        @_players = []
        @_grids = []
        @_turnsCanPass = false
        @_stacks = []
        @_pieces = []
        @_initialEnumPieces = []
        @_initialEnumOwners = []
        @_finalized = false

    _ensureNotFinalized: () ->
        if @_finalized
            throw new Error("Cannot call after calling rules.finalizeBoardShape()!")
    _ensureFinalized: () ->
        if not @_finalized
            throw new Error("Must call rules.finalizeBoardShape() before proceeding!")
    finalizeBoardShape: () ->
        @_ensureNotFinalized()
        @_finalized = true
        for grid in @_grids
            grid._enumerateCells(@_cellEnumerator)
        @_initialEnumPieces = (-1 for _ in [0..@_cellEnumerator.total()-1])
        @_initialEnumOwners = (-1 for _ in [0..@_cellEnumerator.total()-1])

    boardSetup: (pieceId, playerId, cellIds) ->
        @_ensureFinalized()
        cellIds = stringListCast(cellIds) # Ensure list
        for cellId in cellIds
            cell = @getCell(cellId)
            @_initialEnumPieces[cell.enumId()] = @getPiece(pieceId).enumId()
            @_initialEnumOwners[cell.enumId()] = @getPlayer(playerId).enumId()

    piece: (id) -> 
        @_ensureNotFinalized()
        piece = new Piece(id)
        piece.enumId(@_pieces.length)
        @_pieces.push(piece)
        return piece
    player: (id) -> 
        @_ensureNotFinalized()
        player = new Player(id)
        player.enumId(@_players.length)
        @_players.push(player)
        return player
    grid: (name, w, h, cellNames = algebraic) ->
        @_ensureNotFinalized()
        grid = new Grid(name, w, h, cellNames)
        @_grids.push(grid)
        return grid
    grids: () -> @_grids

    # Mmm boilerplate.
    getCell: (id) ->
        for grid in @_grids 
            cell = grid.getCell(id)
            if cell? then return cell
        return null
    getGrid: (id) ->
        for grid in @_grids 
            if grid.id == id then return grid
    getPlayer: (id) ->
        for player in @_players 
            if player.id == id then return player
    getStack: (id) ->
        for stack in @_stacks 
            if stack.id == id then return stack
    getPiece: (id) ->
        for piece in @_pieces 
            if piece.id == id then return piece

module.exports = {Cell, Grid, Rules, GameState}
