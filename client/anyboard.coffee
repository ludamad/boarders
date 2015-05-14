# Imports:
CSS = {
    alpha: 'alpha-d2270'
    black: 'black-3c85d'
    board: 'board-b72b1'
    chessboard: 'chessboard-63f37'
    clearfix: 'clearfix-7da63'
    highlight1: 'highlight1-32417'
    highlight2: 'highlight2-9c5d2'
    notation: 'notation-322f9'
    numeric: 'numeric-fc462'
    piece: 'piece-417db'
    row: 'row-5277c'
    sparePieces: 'spare-pieces-7492f'
    sparePiecesBottom: 'spare-pieces-bottom-ae20f'
    sparePiecesTop: 'spare-pieces-top-4028b'
    square: 'square-55d63'
    white: 'white-1e1d7'
}

window.print = () ->
cfg = {
    showNotation: true
}

# All the game information required for display:
class HtmlPlayerInfoBlock
    _formatTime: (remaining) ->
        hours = Math.floor(remaining / 3600)
        remaining = remaining % 3600
        mins = Math.floor(remaining / 60)
        secs = remaining % 60
        return "#{hours}:#{mins}:#{secs}"

    constructor: (userName, playerName, timeLeft) ->
        @elem = $("<div>")
        @elem.addClass('btn player disabled btn-success')
        @elem.css 'float', 'right'
        @_nameElem = $("<p>")
        @elem.append(@_nameElem)
        @_playerElem = $("<p>")
        @elem.append(@_playerElem)
        @_timeElem = $("<p>")
        @_timeElem.addClass("time")
        @elem.append(@_timeElem)
        @userName(userName)
        @playerName(playerName)
        @timeLeft(timeLeft)
        @_isCurrentPlayer = false

    timeLeft: (@_timeLeft = @_timeLeft) ->
        @_timeElem.text(@_formatTime @_timeLeft) 
        return @_timeLeft
    playerName: (@_playerName = @_playerName) ->
        @_playerElem.text(@_playerName) 
        return @_playerName
    userName: (@_userName = @_userName) ->
        @_nameElem.text(@_userName) 
        return @_userName
    isCurrentPlayer: (isCurrentPlayer) ->
        if isCurrentPlayer? 
            @_isCurrentPlayer = isCurrentPlayer
            if isCurrentPlayer
                @elem.addClass('disabled')
            else
                @elem.removeClass('disabled')
        return @_isCurrentPlayer

# Pieces that can be played, outside of the board
class HtmlStack
    constructor: (@player, @piece, @amount = 0) ->

class HtmlPiece
    constructor: (@_imageFile, @_w, @_h) ->
        @elem = $("<img>")
        @elem.attr 'src',   @_imageFile
        @elem.attr 'class', CSS.piece
        @elem.attr 'style', "width: #{@_w}px; height: #{@_h}px;"
    imageFile: (file) -> 
        if file?
            @elem.attr 'src', file
            @_imageFile = file
        return @_imageFile

class HtmlCell
    constructor: (@x, @y, @width, @height, @squareColor) ->
        # Create initial div:
        @elem = $("<div>")
        @elem.attr 'class', "#{CSS.square} #{CSS[@squareColor]}" 
        @elem.css 'width', "#{@width}px"
        @elem.css 'height', "#{@height}px"
        @elem.attr 'data-x', @x.toString()
        @elem.attr 'data-y', @y.toString()
        @gridCell = null # Set by boarders.coffee
        @_piece = null

    movePiece: (destCell) ->
        destCell.piece @piece()
        @piece(null)

    piece: (piece) ->
        if typeof piece == 'undefined'
            return @_piece
        if typeof piece == 'string'
            piece = new HtmlPiece(piece, @width, @height)
        @_piece = piece
        @elem.empty()
        if piece?
            @elem.append(piece.elem)
        return @_piece

    highlightReset: () ->
        @elem.css 'box-shadow', ''
    highlightHover: () ->
        @elem.css 'box-shadow', 'inset 0 0 3px 3px green'
    highlightSelected: () ->
        @elem.css 'box-shadow', 'inset 0 0 3px 3px green'

class HtmlBoard
    constructor: (@boardId, @width, @height) ->
        @orientation = 'black'
        @elem = $('#' + @boardId)
        @sqrWidth = (parseInt(@elem.width(), 10)) / @width
        @sqrHeight = @sqrWidth # Square squares for now. Makes sense.
        @cells = ((null for _ in [0..@width-1]) for _ in [0..@height-1])
        @draggedPiece = null

    getCellFromCell: (cell) ->
        return @getCell(cell.x, cell.y)
    getPiece: (x, y) ->
        return @getCell(x, y).piece()
    setPiece: (x, y, piece) ->
        @getCell(x, y).piece(piece)
    movePiece: (x1, y1, x2, y2) ->
        @getCell(x1, y1).movePiece(@getCell x2, y2)

    setup: () ->
        @elem.empty()
        squareColor = 'white'
        for y in [0..@height-1]
            rowIds = []
            # Start the row:
            rowEl = $("<div>")
            rowEl.attr "class", CSS.row
            startColor = squareColor
            for x in [0..@width-1]
                cell = new HtmlCell(x, y, @sqrWidth, @sqrHeight, squareColor)
                @cells[y][x] = cell
                if @orientation == 'white' 
                    rowEl.append(cell.elem)
                else
                    rowEl.prepend(cell.elem)

                squareColor = if squareColor == 'white' then 'black' else 'white'

            # Finish the row:
            rowEl.append $("<div class=#{CSS.clearfix}>")
            squareColor = if startColor == 'white' then 'black' else 'white'
            if @orientation == 'white' 
                @elem.append rowEl
            else
                @elem.prepend rowEl

    _createDomCallbackFromCellFunc: (f) ->
         self = @
         return () ->
             x = parseInt($(@).attr 'data-x')
             y = parseInt($(@).attr 'data-y')
             cell = self.getCell(x,y)
             f(self, cell)

    onCellClick: (f) ->
         @elem.find('.' + CSS.square).click(@_createDomCallbackFromCellFunc(f))
    onCellHover: (startHoverF, endHoverF) ->
         startHoverDom = @_createDomCallbackFromCellFunc(startHoverF)
         endHoverDom = @_createDomCallbackFromCellFunc(endHoverF)
         @elem.find('.' + CSS.square).hover(startHoverDom, endHoverDom)
 
    getCell: (x, y) -> @cells[y][x]

# This is all stuff that could be part of the HtmlPlayArea object
# but since we can confine its usage here, we do
#playAreaUiStateMachine = (playArea) ->

    #return {onClick, onHover, addUiTrigger}


# Composed of some number of boards and stacks, for now
class HtmlPlayArea
    constructor: (elem) ->
        @elem = $('#' + elem) 
        @boards = []
        @pieceStacks = []
        @pInfoBlocks = []
        @pInfoBlocks.push new HtmlPlayerInfoBlock('ludamad', 'white', 50)
        @pInfoBlocks.push new HtmlPlayerInfoBlock('not ludamad', 'black', 50)
        #uiStateMachine = playAreaUiStateMachine(@)
        #uiStateMachine.addUiTrigger
        for info in @pInfoBlocks
            @elem.find('#timers').append(info.elem)
    board: (id, w, h) -> 
        board = new HtmlBoard(id, w, h)
        @boards.push(board)
        return board
    onCellClick: (f) ->
        for board in @boards
            board.onCellClick(f)
    onCellHover: (startHoverF, endHoverF) ->
        for board in @boards
            board.onCellHover(startHoverF, endHoverF)
    setup: () ->
        for board in @boards
            board.setup()

    addUiTrigger: ({triggerCells, triggerOnDrag, triggerOnClick}) ->


#$.get 'tictactoe.zrf', (content) ->
#    P = require("./zrfparser")
#    zrfFile = P.parse(content)
#    [zrfGame] = zrfFile.games
#    board = new HtmlPlayArea('board-container', zrfGame)
#    board.setup()

# TODO to be part of zrf module:
fixImgUrl = (url) ->
    url = url.replace("\\", "/")
    url = url.replace("\.bmp", ".png")
    url = url.replace("\.BMP", ".png")

module.exports = {HtmlPlayArea, HtmlBoard}
