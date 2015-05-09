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

# Pieces that can be played, outside of the board
class HtmlStack
    constructor: (@player, @piece, @amount = 0) ->

class HtmlPiece
    constructor: (imgFile, w, h) ->
        @elem = $("<img>")
        @elem.attr 'src',   imgFile
        @elem.attr 'class', CSS.piece
        @elem.attr 'style', "width: #{w}px; height: #{h}px;"

class HtmlBoard
    constructor: (@boardId, zrfBoard, @orientation = 'white') ->
        {grid: {dimensions: {width, height}}} = zrfBoard
        [@width, @height] = [width, height]
        @elem = $('#' + @boardId)
        @sqrWidth = (parseInt(@elem.width(), 10)) / @width
        @sqrHeight = @sqrWidth # Square squares for now. Makes sense.

    _getId: (x, y) ->
        return "#{@boardId}-#{x + 1}-#{y + 1}"
    render: () ->
        html = ''
        squareColor = 'white'
        row = (if @orientation == 'black' then 1 else 8)

        for y in [0..@height-1]
            rowIds = []
            # Start the row:
            rowEl = $("<div>")
            rowEl.attr "class", CSS.row
            startColor = squareColor
            for x in [0..@width-1]
                # Create initial div:
                squareEl = $("<div>")
                squareEl.attr 'class', "#{CSS.square} #{CSS[squareColor]}" 
                squareEl.css 'width', "#{@sqrWidth - 4}px"
                squareEl.css 'height', "#{@sqrHeight - 4}px"
                squareEl.attr 'id', @_getId(x, y)
                squareEl.attr 'data-x', x.toString()
                squareEl.attr 'data-y', y.toString()
                rowEl.append(squareEl)

                squareColor = if squareColor == 'white' then 'black' else 'white'

            # Finish the row:
            rowEl.append $("<div class=#{CSS.clearfix}>")
            squareColor = if startColor == 'white' then 'black' else 'white'
            if @orientation == 'white' then row-- else row++
            html += rowEl.html()
        @elem.html(html)

    setup: () ->
         @render()
         startHover = () -> 
             $(@).css 'border', '2px solid black'
         endHover = () ->
             $(@).css 'border', '2px solid transparent'
         onClick = () ->
             piece = new HtmlPiece('images/TicTacToe/TTTX.png', @squareSize, @squareSize)
             $(@).append(piece.elem)
             x = parseInt($(@).attr 'data-x')
             y = parseInt($(@).attr 'data-y')

         $('.' + CSS.square).hover(startHover, endHover)
         $('.' + CSS.square).click(onClick)
 
     _getElem: (x, y) -> $('#' + @_getId(x, y))
     set: (x, y, image) ->
 
fixImgUrl = (url) ->
    url = url.replace("\\", "/")
    url = url.replace("\.bmp", ".png")
    url = url.replace("\.BMP", ".png")

# Composed of some number of boards and stacks, for now
class HtmlPlayArea
    constructor: (elem, zrfGame) ->
        @elem = $('#' + elem) 
        @boards = []
        for board in zrfGame.boards
            @boards.push(new HtmlBoard('board-1', board))
        @pieceStacks = {}
    setup: () ->
        for board in @boards
            board.setup()

$.get 'tictactoe.zrf', (content) ->
    P = require("./zrfparser")
    zrfFile = P.parse(content)
    [zrfGame] = zrfFile.games
    board = new HtmlPlayArea('board-container', zrfGame)
    board.setup()

module.exports = {HtmlPlayArea, HtmlBoard}
