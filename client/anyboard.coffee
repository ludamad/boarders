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
    constructor: (@boardId, @width, @height) ->
        @orientation = 'white'
        @elem = $('#' + @boardId)
        @sqrWidth = (parseInt(@elem.width(), 10)) / @width
        @sqrHeight = @sqrWidth # Square squares for now. Makes sense.
        @pieces = ((null for _ in [0..@width-1]) for _ in [0..@height-1])
        @draggedPiece = null
        @selectedSquare = null

    _getId: (x, y) ->
        return "#{@boardId}-#{x + 1}-#{y + 1}"
    piece: (img, x, y) ->
        piece = new HtmlPiece(img, @sqrWidth, @sqrHeight)
        @pieces[y][x] = piece
        @_getElem(x, y).empty()
        @_getElem(x, y).append(piece.elem)
        return piece

    movePiece: (x1, y1, x2, y2) ->
        piece = @pieces[y1][x1]
        @pieces[y1][x1] = null
        @pieces[y2][x2] = piece
        @_getElem(x1, y1).empty()
        @_getElem(x2, y2).empty()
        @_getElem(x2, y2).append(piece.elem)

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
         self = @
         startHover = () -> 
             x = parseInt($(@).attr 'data-x')
             y = parseInt($(@).attr 'data-y')
             if self.selectedSquare != @
                if (self.pieces[y][x]?) == (self.selectedSquare?)
                    $(@).css 'border', '2px solid #aa0000'
                else
                    $(@).css 'border', '2px solid #00ff00'
         endHover = () ->
             if self.selectedSquare != @
                $(@).css 'border', '2px solid transparent'
         onClick = () ->
             x = parseInt($(@).attr 'data-x')
             y = parseInt($(@).attr 'data-y')

             if self.selectedSquare?
                 xFrom = parseInt($(self.selectedSquare).attr 'data-x')
                 yFrom = parseInt($(self.selectedSquare).attr 'data-y')
                 $(self.selectedSquare).css 'border', '2px solid transparent'
                 self.movePiece(xFrom, yFrom, x, y)
                 self.selectedSquare = null
                 $(@).css 'border', '2px solid transparent'
             else if self.pieces[y][x]?
                 if self.selectedSquare?
                     $(self.selectedSquare).css 'border', '2px solid transparent'
                 self.selectedSquare = @
                 $(@).css 'border', '2px solid #00ff00'
         $('.' + CSS.square).hover(startHover, endHover)
         $('.' + CSS.square).click(onClick)
 
     _getElem: (x, y) -> $('#' + @_getId(x, y))
     set: (x, y, image) ->

# Composed of some number of boards and stacks, for now
class HtmlPlayArea
    constructor: (elem) ->
        @elem = $('#' + elem) 
        @boards = []
        @pieceStacks = {}
    board: (id, w, h) -> 
        board = new HtmlBoard(id, w, h)
        @boards.push(board)
        return board
    setup: () ->
        for board in @boards
            board.setup()

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
