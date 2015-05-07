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

COLUMNS = 'abcdefgh'.split('')
deepCopy = (obj) -> JSON.parse JSON.stringify(obj)

buildBoardContainer = () ->
  html = '<div class="' + CSS.chessboard + '">'
  html += '<div class="' + CSS.board + '"></div>'
  html += '</div>'
  return html

buildBoard (orientation = 'white') ->
    html = ''

    alpha = deepCopy(COLUMNS)
    row = 8
    if orientation == 'black'
      alpha.reverse()
      row = 1

    squareColor = 'white'
    for i in [0..7]
      html += '<div class="' + CSS.row + '">'
      for j in [0..7]
            square = alpha[j] + row;
            html += '<div class="' + CSS.square + ' ' + CSS[squareColor] + ' ' + 'square-' + square + '" ' + 'style="width: ' + SQUARE_SIZE + 'px; height: ' + SQUARE_SIZE + 'px" data-square="' + square + '">'
            if cfg.showNotation == true
                # alpha notation
                if orientation == 'white' and row == 1 or orientation == 'black' and row == 8
                    html += '<div class="' + CSS.notation + ' ' + CSS.alpha + '">' + alpha[j] + '</div>'
                # numeric notation
                if j == 0
                    html += '<div class="' + CSS.notation + ' ' + CSS.numeric + '">' + row + '</div>'
            html += '</div>'
    end .sque
            squareColor = if squareColor == 'white' then 'black' else 'white'
            if orientation == 'white' then 
               row--
            else 
               row++
    return html


class HtmlBoard
    constructor: (@id, @orientation = "up") ->
        @elem = $(@id)
    create: () -> 
        @elem.html()
        table = document.createElement('table')
        @elem.appendChild(table)
        for i in [1..8]
            tr = document.createElement('tr')
            for j in [1..8]
                td = document.createElement('td')
                if i % 2 == j % 2
                    td.className = 'whitesquare'
                else
                    td.className = 'blacksquare'
                tr.appendChild(td)
            table.appendChild(tr)

board = new HtmlBoard('#board-container')
board.create()
