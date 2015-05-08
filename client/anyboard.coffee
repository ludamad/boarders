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

class HtmlBoard
    constructor: (@boardId, zrfBoard, @orientation = 'white') ->
        {grid: {dimensions: {width, height}}} = zrfBoard
        [@width, @height] = [width, height]
        @elem = $('#' + @boardId)
        @squareSize = (parseInt(@elem.width(), 10) - 4) / @width
        @gridIds = []
        @gridImages = [[null]]

    render: () ->
        html = ''
        squareColor = 'white'
        row = (if @orientation == 'black' then 1 else 8)

        for y in [1..@height]
            rowIds = []
            # Start the row:
            html += '<div class="' + CSS.row + '">'
            startColor = squareColor
            for x in [1..@width]
                html += '<div class="' + CSS.square + ' ' + CSS[squareColor]
                html += ' id="' + @boardId + "-" + x + "-" + y + '"'
                html += ' style="width: ' + @squareSize + 'px; height: ' + @squareSize + 'px">'
                html += '</div>'
                squareColor = if squareColor == 'white' then 'black' else 'white'

            # Finish the row:
            html += '<div class="' + CSS.clearfix + '"></div></div>';
            squareColor = if startColor == 'white' then 'black' else 'white'
            if @orientation == 'white' then row-- else row++
            @gridIds.push(rowIds)
        @elem.html html
     _getElem: (x, y) -> $("##{@boardId}-#{x+1}-#{y + 1}")
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
    render: () ->
        for board in @boards
            board.render()

SQUARE_SIZE = 32
COLUMNS = 'abcdefgh'.split('')
deepCopy = (obj) -> JSON.parse JSON.stringify(obj)

buildBoard = (orientation = 'white') ->
    html = ''

    alpha = deepCopy(COLUMNS)
    row = 8
    if orientation == 'black'
        alpha.reverse()
        row = 1

    squareColor = 'white'
    for i in [0..7]
        # Start the row:
        html += '<div class="' + CSS.row + '">'
        for j in [0..7]
            square = alpha[j] + row;
            html += '<div class="' + CSS.square + ' ' + CSS[squareColor] + ' ' + 'square-' + square + '" ' + 'style="width: ' + SQUARE_SIZE + 'px; height: ' + SQUARE_SIZE + 'px" data-square="' + square + '">'
            html += '</div>'
            squareColor = if squareColor == 'white' then 'black' else 'white'

        # Finish the row:
        html += '<div class="' + CSS.clearfix + '"></div></div>';
        squareColor = if squareColor == 'white' then 'black' else 'white'
        if orientation == 'white' then row-- else row++
    return html

buildBoardContainer = (o = 'white') ->
    html = '<div class="' + CSS.chessboard + '">'

    html += '</div>'
    return html

$.get 'tictactoe.zrf', (content) ->
    P = require("./zrfparser")
    zrfFile = P.parse(content)
    [zrfGame] = zrfFile.games
    board = new HtmlPlayArea('board-container', zrfGame)
    board.render()

module.exports = {HtmlPlayArea, HtmlBoard}
