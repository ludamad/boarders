# Imports:
{getElementById} = document

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

class HtmlBoard
    constructor: (@id, @orientation = "up") ->
        @elem = getElementById(@id)
    _render: (text) -> 
        @elem.innerHTML = text

table = document.createElement('table')
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
document.body.appendChild(table)
