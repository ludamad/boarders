validMove = (move) ->
    # move should be a string
    if typeof move != 'string'
        return false
    # move should be in the form of "e2-e4", "f6-d5"
    tmp = move.split('-')
    if tmp.length != 2
        return false
    validSquare(tmp[0]) == true and validSquare(tmp[1]) == true

validSquare = (square) ->
    if typeof square != 'string'
        return false
    square.search(/^[a-h][1-8]$/) != -1

validPieceCode = (code) ->
    if typeof code != 'string'
        return false
    code.search(/^[bw][KQRNBP]$/) != -1

# TODO: this whole function could probably be replaced with a single regex

validFen = (fen) ->
    if typeof fen != 'string'
        return false
    # cut off any move, castling, etc info from the end
    # we're only interested in position information
    fen = fen.replace(RegExp(' .+$'), '')
    # FEN should be 8 sections separated by slashes
    chunks = fen.split('/')
    if chunks.length != 8
        return false
    # check the piece sections
    i = 0
    while i < 8
        if chunks[i] == '' or chunks[i].length > 8 or chunks[i].search(/[^kqrbnpKQRNBP1-8]/) != -1
            return false
        i++
    true

validPositionObject = (pos) ->
    if typeof pos != 'object'
        return false
    for i of pos
        if pos.hasOwnProperty(i) != true
            i++
            continue
        if validSquare(i) != true or validPieceCode(pos[i]) != true
            return false
    true

# convert FEN piece code to bP, wK, etc

fenToPieceCode = (piece) ->
    # black piece
    if piece.toLowerCase() == piece
        return 'b' + piece.toUpperCase()
    # white piece
    'w' + piece.toUpperCase()

# convert bP, wK, etc code to FEN structure

pieceCodeToFen = (piece) ->
    tmp = piece.split('')
    # white piece
    if tmp[0] == 'w'
        return tmp[1].toUpperCase()
    # black piece
    tmp[1].toLowerCase()

# convert FEN string to position object
# returns false if the FEN string is invalid

fenToObj = (fen) ->
    if validFen(fen) != true
        return false
    # cut off any move, castling, etc info from the end
    # we're only interested in position information
    fen = fen.replace(RegExp(' .+$'), '')
    rows = fen.split('/')
    position = {}
    currentRow = 8
    i = 0
    while i < 8
        row = rows[i].split('')
        colIndex = 0
        # loop through each character in the FEN section
        j = 0
        while j < row.length
            # number / empty squares
            if row[j].search(/[1-8]/) != -1
                emptySquares = parseInt(row[j], 10)
                colIndex += emptySquares
            else
                square = COLUMNS[colIndex] + currentRow
                position[square] = fenToPieceCode(row[j])
                colIndex++
            j++
        currentRow--
        i++
    position

# position object to FEN string
# returns false if the obj is not a valid position object

objToFen = (obj) ->
    if validPositionObject(obj) != true
        return false
    fen = ''
    currentRow = 8
    i = 0
    while i < 8
        j = 0
        while j < 8
            square = COLUMNS[j] + currentRow
            # piece exists
            if obj.hasOwnProperty(square) == true
                fen += pieceCodeToFen(obj[square])
            else
                fen += '1'
            j++
        if i != 7
            fen += '/'
        currentRow--
        i++
    # squeeze the numbers together
    # haha, I love this solution...
    fen = fen.replace(/11111111/g, '8')
    fen = fen.replace(/1111111/g, '7')
    fen = fen.replace(/111111/g, '6')
    fen = fen.replace(/11111/g, '5')
    fen = fen.replace(/1111/g, '4')
    fen = fen.replace(/111/g, '3')
    fen = fen.replace(/11/g, '2')
    fen

'use strict'
#------------------------------------------------------------------------------
# Chess Util Functions
#------------------------------------------------------------------------------
COLUMNS = 'abcdefgh'.split('')
ChessBoard = (containerElOrId, cfg) ->
    #------------------------------------------------------------------------------
    # JS Util Functions
    #------------------------------------------------------------------------------
    # http://tinyurl.com/3ttloxj

    uuid = ->
        'xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx'.replace /x/g, (c) ->
            r = Math.random() * 16 | 0
            r.toString 16

    deepCopy = (thing) ->
        JSON.parse JSON.stringify(thing)

    parseSemVer = (version) ->
        tmp = version.split('.')
        {
            major: parseInt(tmp[0], 10)
            minor: parseInt(tmp[1], 10)
            patch: parseInt(tmp[2], 10)
        }

    # returns true if version is >= minimum

    compareSemVer = (version, minimum) ->
        version = parseSemVer(version)
        minimum = parseSemVer(minimum)
        versionNum = version.major * 10000 * 10000 + version.minor * 10000 + version.patch
        minimumNum = minimum.major * 10000 * 10000 + minimum.minor * 10000 + minimum.patch
        versionNum >= minimumNum

    #------------------------------------------------------------------------------
    # Validation / Errors
    #------------------------------------------------------------------------------

    error = (code, msg, obj) ->
        # do nothing if showErrors is not set
        if cfg.hasOwnProperty('showErrors') != true or cfg.showErrors == false
            return
        errorText = 'ChessBoard Error ' + code + ': ' + msg
        # print to console
        if cfg.showErrors == 'console' and typeof console == 'object' and typeof console.log == 'function'
            console.log errorText
            if arguments.length >= 2
                console.log obj
            return
        # alert errors
        if cfg.showErrors == 'alert'
            if obj
                errorText += '\n\n' + JSON.stringify(obj)
            window.alert errorText
            return
        # custom function
        if typeof cfg.showErrors == 'function'
            cfg.showErrors code, msg, obj
        return

    # check dependencies

    checkDeps = ->
        # if containerId is a string, it must be the ID of a DOM node
        if typeof containerElOrId == 'string'
            # cannot be empty
            if containerElOrId == ''
                window.alert 'ChessBoard Error 1001: ' + 'The first argument to ChessBoard() cannot be an empty string.' + '\n\nExiting...'
                return false
            # make sure the container element exists in the DOM
            el = document.getElementById(containerElOrId)
            if !el
                window.alert 'ChessBoard Error 1002: Element with id "' + containerElOrId + '" does not exist in the DOM.' + '\n\nExiting...'
                return false
            # set the containerEl
            containerEl = $(el)
        else
            containerEl = $(containerElOrId)
            if containerEl.length != 1
                window.alert 'ChessBoard Error 1003: The first argument to ' + 'ChessBoard() must be an ID or a single DOM node.' + '\n\nExiting...'
                return false
        # JSON must exist
        if !window.JSON or typeof JSON.stringify != 'function' or typeof JSON.parse != 'function'
            window.alert 'ChessBoard Error 1004: JSON does not exist. ' + 'Please include a JSON polyfill.\n\nExiting...'
            return false
        # check for a compatible version of jQuery
        if !(typeof window.$ and $.fn and $.fn.jquery and compareSemVer($.fn.jquery, MINIMUM_JQUERY_VERSION) == true)
            window.alert 'ChessBoard Error 1005: Unable to find a valid version ' + 'of jQuery. Please include jQuery ' + MINIMUM_JQUERY_VERSION + ' or ' + 'higher on the page.\n\nExiting...'
            return false
        true

    validAnimationSpeed = (speed) ->
        if speed == 'fast' or speed == 'slow'
            return true
        if parseInt(speed, 10) + '' != speed + ''
            return false
        speed >= 0

    # validate config / set default options

    expandConfig = ->
        if typeof cfg == 'string' or validPositionObject(cfg) == true
            cfg = position: cfg
        # default for orientation is white
        if cfg.orientation != 'black'
            cfg.orientation = 'white'
        CURRENT_ORIENTATION = cfg.orientation
        # default for showNotation is true
        if cfg.showNotation != false
            cfg.showNotation = true
        # default for draggable is false
        if cfg.draggable != true
            cfg.draggable = false
        # default for dropOffBoard is 'snapback'
        if cfg.dropOffBoard != 'trash'
            cfg.dropOffBoard = 'snapback'
        # default for sparePieces is false
        if cfg.sparePieces != true
            cfg.sparePieces = false
        # draggable must be true if sparePieces is enabled
        if cfg.sparePieces == true
            cfg.draggable = true
        # default piece theme is wikipedia
        # animation speeds
        if cfg.hasOwnProperty('appearSpeed') != true or validAnimationSpeed(cfg.appearSpeed) != true
            cfg.appearSpeed = 200
        if cfg.hasOwnProperty('moveSpeed') != true or validAnimationSpeed(cfg.moveSpeed) != true
            cfg.moveSpeed = 200
        if cfg.hasOwnProperty('snapbackSpeed') != true or validAnimationSpeed(cfg.snapbackSpeed) != true
            cfg.snapbackSpeed = 50
        if cfg.hasOwnProperty('snapSpeed') != true or validAnimationSpeed(cfg.snapSpeed) != true
            cfg.snapSpeed = 25
        if cfg.hasOwnProperty('trashSpeed') != true or validAnimationSpeed(cfg.trashSpeed) != true
            cfg.trashSpeed = 100
        # make sure position is valid
        if cfg.hasOwnProperty('position') == true
            if cfg.position == 'start'
                CURRENT_POSITION = deepCopy(START_POSITION)
            else if validFen(cfg.position) == true
                CURRENT_POSITION = fenToObj(cfg.position)
            else if validPositionObject(cfg.position) == true
                CURRENT_POSITION = deepCopy(cfg.position)
            else
                error 7263, 'Invalid value passed to config.position.', cfg.position
        true

    #------------------------------------------------------------------------------
    # DOM Misc
    #------------------------------------------------------------------------------
    # calculates square size based on the width of the container
    # got a little CSS black magic here, so let me explain:
    # get the width of the container element (could be anything), reduce by 1 for
    # fudge factor, and then keep reducing until we find an exact mod 8 for
    # our square size

    calculateSquareSize = ->
        containerWidth = parseInt(containerEl.width(), 10)
        # defensive, prevent infinite loop
        if !containerWidth or containerWidth <= 0
            return 0
        # pad one pixel
        boardWidth = containerWidth - 1
        while boardWidth % 8 != 0 and boardWidth > 0
            boardWidth--
        boardWidth / 8

    # create random IDs for elements

    createElIds = ->
        `var i`
        # squares on the board
        i = 0
        while i < COLUMNS.length
            j = 1
            while j <= 8
                square = COLUMNS[i] + j
                SQUARE_ELS_IDS[square] = square + '-' + uuid()
                j++
            i++
        # spare pieces
        pieces = 'KQRBNP'.split('')
        i = 0
        while i < pieces.length
            whitePiece = 'w' + pieces[i]
            blackPiece = 'b' + pieces[i]
            SPARE_PIECE_ELS_IDS[whitePiece] = whitePiece + '-' + uuid()
            SPARE_PIECE_ELS_IDS[blackPiece] = blackPiece + '-' + uuid()
            i++
        return

    #------------------------------------------------------------------------------
    # Markup Building
    #------------------------------------------------------------------------------

    buildBoardContainer = ->
        html = '<div class="' + CSS.chessboard + '">'
        if cfg.sparePieces == true
            html += '<div class="' + CSS.sparePieces + ' ' + CSS.sparePiecesTop + '"></div>'
        html += '<div class="' + CSS.board + '"></div>'
        if cfg.sparePieces == true
            html += '<div class="' + CSS.sparePieces + ' ' + CSS.sparePiecesBottom + '"></div>'
        html += '</div>'
        html

    ###
    var buildSquare = function(color, size, id) {
      var html = '<div class="' + CSS.square + ' ' + CSS[color] + '" ' +
      'style="width: ' + size + 'px; height: ' + size + 'px" ' +
      'id="' + id + '">';
    
      if (cfg.showNotation === true) {
    
      }
    
      html += '</div>';
    
      return html;
    };
    ###

    buildBoard = (orientation) ->
        if orientation != 'black'
            orientation = 'white'
        html = ''
        # algebraic notation / orientation
        alpha = deepCopy(COLUMNS)
        row = 8
        if orientation == 'black'
            alpha.reverse()
            row = 1
        squareColor = 'white'
        i = 0
        while i < 8
            html += '<div class="' + CSS.row + '">'
            j = 0
            while j < 8
                square = alpha[j] + row
                html += '<div class="' + CSS.square + ' ' + CSS[squareColor] + ' ' + 'square-' + square + '" ' + 'style="width: ' + SQUARE_SIZE + 'px; height: ' + SQUARE_SIZE + 'px" ' + 'id="' + SQUARE_ELS_IDS[square] + '" ' + 'data-square="' + square + '">'
                if cfg.showNotation == true
                    # alpha notation
                    if orientation == 'white' and row == 1 or orientation == 'black' and row == 8
                        html += '<div class="' + CSS.notation + ' ' + CSS.alpha + '">' + alpha[j] + '</div>'
                    # numeric notation
                    if j == 0
                        html += '<div class="' + CSS.notation + ' ' + CSS.numeric + '">' + row + '</div>'
                html += '</div>'
                # end .square
                squareColor = if squareColor == 'white' then 'black' else 'white'
                j++
            html += '<div class="' + CSS.clearfix + '"></div></div>'
            squareColor = if squareColor == 'white' then 'black' else 'white'
            if orientation == 'white'
                row--
            else
                row++
            i++
        html

    buildPieceImgSrc = (piece) ->
        if typeof cfg.pieceTheme == 'function'
            return cfg.pieceTheme(piece)
        if typeof cfg.pieceTheme == 'string'
            return cfg.pieceTheme.replace(/{piece}/g, piece)
        # NOTE: this should never happen
        error 8272, 'Unable to build image source for cfg.pieceTheme.'
        ''

    buildPiece = (piece, hidden, id) ->
        html = '<img src="' + buildPieceImgSrc(piece) + '" '
        if id and typeof id == 'string'
            html += 'id="' + id + '" '
        html += 'alt="" ' + 'class="' + CSS.piece + '" ' + 'data-piece="' + piece + '" ' + 'style="width: ' + SQUARE_SIZE + 'px;' + 'height: ' + SQUARE_SIZE + 'px;'
        if hidden == true
            html += 'display:none;'
        html += '" />'
        html

    buildSparePieces = (color) ->
        pieces = [
            'wK'
            'wQ'
            'wR'
            'wB'
            'wN'
            'wP'
        ]
        if color == 'black'
            pieces = [
                'bK'
                'bQ'
                'bR'
                'bB'
                'bN'
                'bP'
            ]
        html = ''
        i = 0
        while i < pieces.length
            html += buildPiece(pieces[i], false, SPARE_PIECE_ELS_IDS[pieces[i]])
            i++
        html

    #------------------------------------------------------------------------------
    # Animations
    #------------------------------------------------------------------------------

    animateSquareToSquare = (src, dest, piece, completeFn) ->
        # get information about the source and destination squares
        srcSquareEl = $('#' + SQUARE_ELS_IDS[src])
        srcSquarePosition = srcSquareEl.offset()
        destSquareEl = $('#' + SQUARE_ELS_IDS[dest])
        destSquarePosition = destSquareEl.offset()
        # create the animated piece and absolutely position it
        # over the source square
        animatedPieceId = uuid()
        $('body').append buildPiece(piece, true, animatedPieceId)
        animatedPieceEl = $('#' + animatedPieceId)
        animatedPieceEl.css
            display: ''
            position: 'absolute'
            top: srcSquarePosition.top
            left: srcSquarePosition.left
        # remove original piece from source square
        srcSquareEl.find('.' + CSS.piece).remove()
        # on complete

        complete = ->
            # add the "real" piece to the destination square
            destSquareEl.append buildPiece(piece)
            # remove the animated piece
            animatedPieceEl.remove()
            # run complete function
            if typeof completeFn == 'function'
                completeFn()
            return

        # animate the piece to the destination square
        opts = 
            duration: cfg.moveSpeed
            complete: complete
        animatedPieceEl.animate destSquarePosition, opts
        return

    animateSparePieceToSquare = (piece, dest, completeFn) ->
        srcOffset = $('#' + SPARE_PIECE_ELS_IDS[piece]).offset()
        destSquareEl = $('#' + SQUARE_ELS_IDS[dest])
        destOffset = destSquareEl.offset()
        # create the animate piece
        pieceId = uuid()
        $('body').append buildPiece(piece, true, pieceId)
        animatedPieceEl = $('#' + pieceId)
        animatedPieceEl.css
            display: ''
            position: 'absolute'
            left: srcOffset.left
            top: srcOffset.top
        # on complete

        complete = ->
            # add the "real" piece to the destination square
            destSquareEl.find('.' + CSS.piece).remove()
            destSquareEl.append buildPiece(piece)
            # remove the animated piece
            animatedPieceEl.remove()
            # run complete function
            if typeof completeFn == 'function'
                completeFn()
            return

        # animate the piece to the destination square
        opts = 
            duration: cfg.moveSpeed
            complete: complete
        animatedPieceEl.animate destOffset, opts
        return

    # execute an array of animations

    doAnimations = (a, oldPos, newPos) ->

        onFinish = ->
            numFinished++
            # exit if all the animations aren't finished
            if numFinished != a.length
                return
            drawPositionInstant()
            ANIMATION_HAPPENING = false
            # run their onMoveEnd function
            if cfg.hasOwnProperty('onMoveEnd') == true and typeof cfg.onMoveEnd == 'function'
                cfg.onMoveEnd deepCopy(oldPos), deepCopy(newPos)
            return

        if a.length == 0
            return
        ANIMATION_HAPPENING = true
        numFinished = 0
        i = 0
        while i < a.length
            # clear a piece
            if a[i].type == 'clear'
                $('#' + SQUARE_ELS_IDS[a[i].square] + ' .' + CSS.piece).fadeOut cfg.trashSpeed, onFinish
            # add a piece (no spare pieces)
            if a[i].type == 'add' and cfg.sparePieces != true
                $('#' + SQUARE_ELS_IDS[a[i].square]).append(buildPiece(a[i].piece, true)).find('.' + CSS.piece).fadeIn cfg.appearSpeed, onFinish
            # add a piece from a spare piece
            if a[i].type == 'add' and cfg.sparePieces == true
                animateSparePieceToSquare a[i].piece, a[i].square, onFinish
            # move a piece
            if a[i].type == 'move'
                animateSquareToSquare a[i].source, a[i].destination, a[i].piece, onFinish
            i++
        return

    # returns the distance between two squares

    squareDistance = (s1, s2) ->
        s1 = s1.split('')
        s1x = COLUMNS.indexOf(s1[0]) + 1
        s1y = parseInt(s1[1], 10)
        s2 = s2.split('')
        s2x = COLUMNS.indexOf(s2[0]) + 1
        s2y = parseInt(s2[1], 10)
        xDelta = Math.abs(s1x - s2x)
        yDelta = Math.abs(s1y - s2y)
        if xDelta >= yDelta
            return xDelta
        yDelta

    # returns an array of closest squares from square

    createRadius = (square) ->
        squares = []
        # calculate distance of all squares
        i = 0
        while i < 8
            j = 0
            while j < 8
                s = COLUMNS[i] + j + 1
                # skip the square we're starting from
                if square == s
                    j++
                    continue
                squares.push
                    square: s
                    distance: squareDistance(square, s)
                j++
            i++
        # sort by distance
        squares.sort (a, b) ->
            `var i`
            a.distance - (b.distance)
        # just return the square code
        squares2 = []
        i = 0
        while i < squares.length
            squares2.push squares[i].square
            i++
        squares2

    # returns the square of the closest instance of piece
    # returns false if no instance of piece is found in position

    findClosestPiece = (position, piece, square) ->
        # create array of closest squares from square
        closestSquares = createRadius(square)
        # search through the position in order of distance for the piece
        i = 0
        while i < closestSquares.length
            s = closestSquares[i]
            if position.hasOwnProperty(s) == true and position[s] == piece
                return s
            i++
        false

    # calculate an array of animations that need to happen in order to get
    # from pos1 to pos2

    calculateAnimations = (pos1, pos2) ->
        `var i`
        `var i`
        `var i`
        # make copies of both
        pos1 = deepCopy(pos1)
        pos2 = deepCopy(pos2)
        animations = []
        squaresMovedTo = {}
        # remove pieces that are the same in both positions
        for i of pos2
            if pos2.hasOwnProperty(i) != true
                i++
                continue
            if pos1.hasOwnProperty(i) == true and pos1[i] == pos2[i]
                delete pos1[i]
                delete pos2[i]
        # find all the "move" animations
        for i of pos2
            if pos2.hasOwnProperty(i) != true
                i++
                continue
            closestPiece = findClosestPiece(pos1, pos2[i], i)
            if closestPiece != false
                animations.push
                    type: 'move'
                    source: closestPiece
                    destination: i
                    piece: pos2[i]
                delete pos1[closestPiece]
                delete pos2[i]
                squaresMovedTo[i] = true
        # add pieces to pos2
        for i of pos2
            if pos2.hasOwnProperty(i) != true
                i++
                continue
            animations.push
                type: 'add'
                square: i
                piece: pos2[i]
            delete pos2[i]
        # clear pieces from pos1
        for i of pos1
            if pos1.hasOwnProperty(i) != true
                i++
                continue
            # do not clear a piece if it is on a square that is the result
            # of a "move", ie: a piece capture
            if squaresMovedTo.hasOwnProperty(i) == true
                i++
                continue
            animations.push
                type: 'clear'
                square: i
                piece: pos1[i]
            delete pos1[i]
        animations

    #------------------------------------------------------------------------------
    # Control Flow
    #------------------------------------------------------------------------------

    drawPositionInstant = ->
        # clear the board
        boardEl.find('.' + CSS.piece).remove()
        # add the pieces
        for i of CURRENT_POSITION
            if CURRENT_POSITION.hasOwnProperty(i) != true
                i++
                continue
            $('#' + SQUARE_ELS_IDS[i]).append buildPiece(CURRENT_POSITION[i])
        return

    drawBoard = ->
        boardEl.html buildBoard(CURRENT_ORIENTATION)
        drawPositionInstant()
        if cfg.sparePieces == true
            if CURRENT_ORIENTATION == 'white'
                sparePiecesTopEl.html buildSparePieces('black')
                sparePiecesBottomEl.html buildSparePieces('white')
            else
                sparePiecesTopEl.html buildSparePieces('white')
                sparePiecesBottomEl.html buildSparePieces('black')
        return

    # given a position and a set of moves, return a new position
    # with the moves executed

    calculatePositionFromMoves = (position, moves) ->
        position = deepCopy(position)
        for i of moves
            if moves.hasOwnProperty(i) != true
                i++
                continue
            # skip the move if the position doesn't have a piece on the source square
            if position.hasOwnProperty(i) != true
                i++
                continue
            piece = position[i]
            delete position[i]
            position[moves[i]] = piece
        position

    setCurrentPosition = (position) ->
        oldPos = deepCopy(CURRENT_POSITION)
        newPos = deepCopy(position)
        oldFen = objToFen(oldPos)
        newFen = objToFen(newPos)
        # do nothing if no change in position
        if oldFen == newFen
            return
        # run their onChange function
        if cfg.hasOwnProperty('onChange') == true and typeof cfg.onChange == 'function'
            cfg.onChange oldPos, newPos
        # update state
        CURRENT_POSITION = position
        return

    isXYOnSquare = (x, y) ->
        for i of SQUARE_ELS_OFFSETS
            if SQUARE_ELS_OFFSETS.hasOwnProperty(i) != true
                i++
                continue
            s = SQUARE_ELS_OFFSETS[i]
            if x >= s.left and x < s.left + SQUARE_SIZE and y >= s.top and y < s.top + SQUARE_SIZE
                return i
        'offboard'

    # records the XY coords of every square into memory

    captureSquareOffsets = ->
        SQUARE_ELS_OFFSETS = {}
        for i of SQUARE_ELS_IDS
            if SQUARE_ELS_IDS.hasOwnProperty(i) != true
                i++
                continue
            SQUARE_ELS_OFFSETS[i] = $('#' + SQUARE_ELS_IDS[i]).offset()
        return

    removeSquareHighlights = ->
        boardEl.find('.' + CSS.square).removeClass CSS.highlight1 + ' ' + CSS.highlight2
        return

    snapbackDraggedPiece = ->
        # there is no "snapback" for spare pieces
        # animation complete

        complete = ->
            drawPositionInstant()
            draggedPieceEl.css 'display', 'none'
            # run their onSnapbackEnd function
            if cfg.hasOwnProperty('onSnapbackEnd') == true and typeof cfg.onSnapbackEnd == 'function'
                cfg.onSnapbackEnd DRAGGED_PIECE, DRAGGED_PIECE_SOURCE, deepCopy(CURRENT_POSITION), CURRENT_ORIENTATION
            return

        if DRAGGED_PIECE_SOURCE == 'spare'
            trashDraggedPiece()
            return
        removeSquareHighlights()
        # get source square position
        sourceSquarePosition = $('#' + SQUARE_ELS_IDS[DRAGGED_PIECE_SOURCE]).offset()
        # animate the piece to the target square
        opts = 
            duration: cfg.snapbackSpeed
            complete: complete
        draggedPieceEl.animate sourceSquarePosition, opts
        # set state
        DRAGGING_A_PIECE = false
        return

    trashDraggedPiece = ->
        removeSquareHighlights()
        # remove the source piece
        newPosition = deepCopy(CURRENT_POSITION)
        delete newPosition[DRAGGED_PIECE_SOURCE]
        setCurrentPosition newPosition
        # redraw the position
        drawPositionInstant()
        # hide the dragged piece
        draggedPieceEl.fadeOut cfg.trashSpeed
        # set state
        DRAGGING_A_PIECE = false
        return

    dropDraggedPieceOnSquare = (square) ->
        removeSquareHighlights()
        # update position
        newPosition = deepCopy(CURRENT_POSITION)
        delete newPosition[DRAGGED_PIECE_SOURCE]
        newPosition[square] = DRAGGED_PIECE
        setCurrentPosition newPosition
        # get target square information
        targetSquarePosition = $('#' + SQUARE_ELS_IDS[square]).offset()
        # animation complete

        complete = ->
            drawPositionInstant()
            draggedPieceEl.css 'display', 'none'
            # execute their onSnapEnd function
            if cfg.hasOwnProperty('onSnapEnd') == true and typeof cfg.onSnapEnd == 'function'
                cfg.onSnapEnd DRAGGED_PIECE_SOURCE, square, DRAGGED_PIECE
            return

        # snap the piece to the target square
        opts = 
            duration: cfg.snapSpeed
            complete: complete
        draggedPieceEl.animate targetSquarePosition, opts
        # set state
        DRAGGING_A_PIECE = false
        return

    beginDraggingPiece = (source, piece, x, y) ->
        # run their custom onDragStart function
        # their custom onDragStart function can cancel drag start
        if typeof cfg.onDragStart == 'function' and cfg.onDragStart(source, piece, deepCopy(CURRENT_POSITION), CURRENT_ORIENTATION) == false
            return
        # set state
        DRAGGING_A_PIECE = true
        DRAGGED_PIECE = piece
        DRAGGED_PIECE_SOURCE = source
        # if the piece came from spare pieces, location is offboard
        if source == 'spare'
            DRAGGED_PIECE_LOCATION = 'offboard'
        else
            DRAGGED_PIECE_LOCATION = source
        # capture the x, y coords of all squares in memory
        captureSquareOffsets()
        # create the dragged piece
        draggedPieceEl.attr('src', buildPieceImgSrc(piece)).css
            display: ''
            position: 'absolute'
            left: x - (SQUARE_SIZE / 2)
            top: y - (SQUARE_SIZE / 2)
        if source != 'spare'
            # highlight the source square and hide the piece
            $('#' + SQUARE_ELS_IDS[source]).addClass(CSS.highlight1).find('.' + CSS.piece).css 'display', 'none'
        return

    updateDraggedPiece = (x, y) ->
        # put the dragged piece over the mouse cursor
        draggedPieceEl.css
            left: x - (SQUARE_SIZE / 2)
            top: y - (SQUARE_SIZE / 2)
        # get location
        location = isXYOnSquare(x, y)
        # do nothing if the location has not changed
        if location == DRAGGED_PIECE_LOCATION
            return
        # remove highlight from previous square
        if validSquare(DRAGGED_PIECE_LOCATION) == true
            $('#' + SQUARE_ELS_IDS[DRAGGED_PIECE_LOCATION]).removeClass CSS.highlight2
        # add highlight to new square
        if validSquare(location) == true
            $('#' + SQUARE_ELS_IDS[location]).addClass CSS.highlight2
        # run onDragMove
        if typeof cfg.onDragMove == 'function'
            cfg.onDragMove location, DRAGGED_PIECE_LOCATION, DRAGGED_PIECE_SOURCE, DRAGGED_PIECE, deepCopy(CURRENT_POSITION), CURRENT_ORIENTATION
        # update state
        DRAGGED_PIECE_LOCATION = location
        return

    stopDraggedPiece = (location) ->
        # determine what the action should be
        action = 'drop'
        if location == 'offboard' and cfg.dropOffBoard == 'snapback'
            action = 'snapback'
        if location == 'offboard' and cfg.dropOffBoard == 'trash'
            action = 'trash'
        # run their onDrop function, which can potentially change the drop action
        if cfg.hasOwnProperty('onDrop') == true and typeof cfg.onDrop == 'function'
            newPosition = deepCopy(CURRENT_POSITION)
            # source piece is a spare piece and position is off the board
            #if (DRAGGED_PIECE_SOURCE === 'spare' && location === 'offboard') {...}
            # position has not changed; do nothing
            # source piece is a spare piece and position is on the board
            if DRAGGED_PIECE_SOURCE == 'spare' and validSquare(location) == true
                # add the piece to the board
                newPosition[location] = DRAGGED_PIECE
            # source piece was on the board and position is off the board
            if validSquare(DRAGGED_PIECE_SOURCE) == true and location == 'offboard'
                # remove the piece from the board
                delete newPosition[DRAGGED_PIECE_SOURCE]
            # source piece was on the board and position is on the board
            if validSquare(DRAGGED_PIECE_SOURCE) == true and validSquare(location) == true
                # move the piece
                delete newPosition[DRAGGED_PIECE_SOURCE]
                newPosition[location] = DRAGGED_PIECE
            oldPosition = deepCopy(CURRENT_POSITION)
            result = cfg.onDrop(DRAGGED_PIECE_SOURCE, location, DRAGGED_PIECE, newPosition, oldPosition, CURRENT_ORIENTATION)
            if result == 'snapback' or result == 'trash'
                action = result
        # do it!
        if action == 'snapback'
            snapbackDraggedPiece()
        else if action == 'trash'
            trashDraggedPiece()
        else if action == 'drop'
            dropDraggedPieceOnSquare location
        return

    #------------------------------------------------------------------------------
    # Browser Events
    #------------------------------------------------------------------------------

    isTouchDevice = ->
        'ontouchstart' of document.documentElement

    # reference: http://www.quirksmode.org/js/detect.html

    isMSIE = ->
        navigator and navigator.userAgent and navigator.userAgent.search(/MSIE/) != -1

    stopDefault = (e) ->
        e.preventDefault()
        return

    mousedownSquare = (e) ->
        # do nothing if we're not draggable
        if cfg.draggable != true
            return
        square = $(this).attr('data-square')
        # no piece on this square
        if validSquare(square) != true or CURRENT_POSITION.hasOwnProperty(square) != true
            return
        beginDraggingPiece square, CURRENT_POSITION[square], e.pageX, e.pageY
        return

    touchstartSquare = (e) ->
        # do nothing if we're not draggable
        if cfg.draggable != true
            return
        square = $(this).attr('data-square')
        # no piece on this square
        if validSquare(square) != true or CURRENT_POSITION.hasOwnProperty(square) != true
            return
        e = e.originalEvent
        beginDraggingPiece square, CURRENT_POSITION[square], e.changedTouches[0].pageX, e.changedTouches[0].pageY
        return

    mousedownSparePiece = (e) ->
        # do nothing if sparePieces is not enabled
        if cfg.sparePieces != true
            return
        piece = $(this).attr('data-piece')
        beginDraggingPiece 'spare', piece, e.pageX, e.pageY
        return

    touchstartSparePiece = (e) ->
        # do nothing if sparePieces is not enabled
        if cfg.sparePieces != true
            return
        piece = $(this).attr('data-piece')
        e = e.originalEvent
        beginDraggingPiece 'spare', piece, e.changedTouches[0].pageX, e.changedTouches[0].pageY
        return

    mousemoveWindow = (e) ->
        # do nothing if we are not dragging a piece
        if DRAGGING_A_PIECE != true
            return
        updateDraggedPiece e.pageX, e.pageY
        return

    touchmoveWindow = (e) ->
        # do nothing if we are not dragging a piece
        if DRAGGING_A_PIECE != true
            return
        # prevent screen from scrolling
        e.preventDefault()
        updateDraggedPiece e.originalEvent.changedTouches[0].pageX, e.originalEvent.changedTouches[0].pageY
        return

    mouseupWindow = (e) ->
        # do nothing if we are not dragging a piece
        if DRAGGING_A_PIECE != true
            return
        # get the location
        location = isXYOnSquare(e.pageX, e.pageY)
        stopDraggedPiece location
        return

    touchendWindow = (e) ->
        # do nothing if we are not dragging a piece
        if DRAGGING_A_PIECE != true
            return
        # get the location
        location = isXYOnSquare(e.originalEvent.changedTouches[0].pageX, e.originalEvent.changedTouches[0].pageY)
        stopDraggedPiece location
        return

    mouseenterSquare = (e) ->
        # do not fire this event if we are dragging a piece
        # NOTE: this should never happen, but it's a safeguard
        if DRAGGING_A_PIECE != false
            return
        if cfg.hasOwnProperty('onMouseoverSquare') != true or typeof cfg.onMouseoverSquare != 'function'
            return
        # get the square
        square = $(e.currentTarget).attr('data-square')
        # NOTE: this should never happen; defensive
        if validSquare(square) != true
            return
        # get the piece on this square
        piece = false
        if CURRENT_POSITION.hasOwnProperty(square) == true
            piece = CURRENT_POSITION[square]
        # execute their function
        cfg.onMouseoverSquare square, piece, deepCopy(CURRENT_POSITION), CURRENT_ORIENTATION
        return

    mouseleaveSquare = (e) ->
        # do not fire this event if we are dragging a piece
        # NOTE: this should never happen, but it's a safeguard
        if DRAGGING_A_PIECE != false
            return
        if cfg.hasOwnProperty('onMouseoutSquare') != true or typeof cfg.onMouseoutSquare != 'function'
            return
        # get the square
        square = $(e.currentTarget).attr('data-square')
        # NOTE: this should never happen; defensive
        if validSquare(square) != true
            return
        # get the piece on this square
        piece = false
        if CURRENT_POSITION.hasOwnProperty(square) == true
            piece = CURRENT_POSITION[square]
        # execute their function
        cfg.onMouseoutSquare square, piece, deepCopy(CURRENT_POSITION), CURRENT_ORIENTATION
        return

    #------------------------------------------------------------------------------
    # Initialization
    #------------------------------------------------------------------------------

    addEvents = ->
        # prevent browser "image drag"
        $('body').on 'mousedown mousemove', '.' + CSS.piece, stopDefault
        # mouse drag pieces
        boardEl.on 'mousedown', '.' + CSS.square, mousedownSquare
        containerEl.on 'mousedown', '.' + CSS.sparePieces + ' .' + CSS.piece, mousedownSparePiece
        # mouse enter / leave square
        boardEl.on('mouseenter', '.' + CSS.square, mouseenterSquare).on 'mouseleave', '.' + CSS.square, mouseleaveSquare
        # IE doesn't like the events on the window object, but other browsers
        # perform better that way
        if isMSIE() == true
            # IE-specific prevent browser "image drag"

            document.ondragstart = ->
                false

            $('body').on('mousemove', mousemoveWindow).on 'mouseup', mouseupWindow
        else
            $(window).on('mousemove', mousemoveWindow).on 'mouseup', mouseupWindow
        # touch drag pieces
        if isTouchDevice() == true
            boardEl.on 'touchstart', '.' + CSS.square, touchstartSquare
            containerEl.on 'touchstart', '.' + CSS.sparePieces + ' .' + CSS.piece, touchstartSparePiece
            $(window).on('touchmove', touchmoveWindow).on 'touchend', touchendWindow
        return

    initDom = ->
        # create unique IDs for all the elements we will create
        createElIds()
        # build board and save it in memory
        containerEl.html buildBoardContainer()
        boardEl = containerEl.find('.' + CSS.board)
        if cfg.sparePieces == true
            sparePiecesTopEl = containerEl.find('.' + CSS.sparePiecesTop)
            sparePiecesBottomEl = containerEl.find('.' + CSS.sparePiecesBottom)
        # create the drag piece
        draggedPieceId = uuid()
        $('body').append buildPiece('wP', true, draggedPieceId)
        draggedPieceEl = $('#' + draggedPieceId)
        # get the border size
        BOARD_BORDER_SIZE = parseInt(boardEl.css('borderLeftWidth'), 10)
        # set the size and draw the board
        widget.resize()
        return

    init = ->
        if checkDeps() != true or expandConfig() != true
            return
        initDom()
        addEvents()
        return

    cfg = cfg or {}
    #------------------------------------------------------------------------------
    # Constants
    #------------------------------------------------------------------------------
    MINIMUM_JQUERY_VERSION = '1.7.0'
    START_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR'
    START_POSITION = fenToObj(START_FEN)
    # use unique class names to prevent clashing with anything else on the page
    # and simplify selectors
    # NOTE: these should never change
    CSS = 
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
    #------------------------------------------------------------------------------
    # Module Scope Variables
    #------------------------------------------------------------------------------
    # DOM elements
    containerEl = undefined
    boardEl = undefined
    draggedPieceEl = undefined
    sparePiecesTopEl = undefined
    sparePiecesBottomEl = undefined
    # constructor return object
    widget = {}
    #------------------------------------------------------------------------------
    # Stateful
    #------------------------------------------------------------------------------
    ANIMATION_HAPPENING = false
    BOARD_BORDER_SIZE = 2
    CURRENT_ORIENTATION = 'white'
    CURRENT_POSITION = {}
    SQUARE_SIZE = undefined
    DRAGGED_PIECE = undefined
    DRAGGED_PIECE_LOCATION = undefined
    DRAGGED_PIECE_SOURCE = undefined
    DRAGGING_A_PIECE = false
    SPARE_PIECE_ELS_IDS = {}
    SQUARE_ELS_IDS = {}
    SQUARE_ELS_OFFSETS = undefined
    #------------------------------------------------------------------------------
    # Public Methods
    #------------------------------------------------------------------------------
    # clear the board

    widget.clear = (useAnimation) ->
        widget.position {}, useAnimation
        return

    # remove the widget from the page

    widget.destroy = ->
        # remove markup
        containerEl.html ''
        draggedPieceEl.remove()
        # remove event handlers
        containerEl.unbind()
        return

    # shorthand method to get the current FEN

    widget.fen = ->
        widget.position 'fen'

    # flip orientation

    widget.flip = ->
        widget.orientation 'flip'

    ###
    // TODO: write this, GitHub Issue #5
    widget.highlight = function() {
    
    };
    ###

    # move pieces

    widget.move = ->
        # no need to throw an error here; just do nothing
        if arguments.length == 0
            return
        useAnimation = true
        # collect the moves into an object
        moves = {}
        i = 0
        while i < arguments.length
            # any "false" to this function means no animations
            if arguments[i] == false
                useAnimation = false
                i++
                continue
            # skip invalid arguments
            if validMove(arguments[i]) != true
                error 2826, 'Invalid move passed to the move method.', arguments[i]
                i++
                continue
            tmp = arguments[i].split('-')
            moves[tmp[0]] = tmp[1]
            i++
        # calculate position from moves
        newPos = calculatePositionFromMoves(CURRENT_POSITION, moves)
        # update the board
        widget.position newPos, useAnimation
        # return the new position object
        newPos

    widget.orientation = (arg) ->
        # no arguments, return the current orientation
        if arguments.length == 0
            return CURRENT_ORIENTATION
        # set to white or black
        if arg == 'white' or arg == 'black'
            CURRENT_ORIENTATION = arg
            drawBoard()
            return CURRENT_ORIENTATION
        # flip orientation
        if arg == 'flip'
            CURRENT_ORIENTATION = if CURRENT_ORIENTATION == 'white' then 'black' else 'white'
            drawBoard()
            return CURRENT_ORIENTATION
        error 5482, 'Invalid value passed to the orientation method.', arg
        return

    widget.position = (position, useAnimation) ->
        # no arguments, return the current position
        if arguments.length == 0
            return deepCopy(CURRENT_POSITION)
        # get position as FEN
        if typeof position == 'string' and position.toLowerCase() == 'fen'
            return objToFen(CURRENT_POSITION)
        # default for useAnimations is true
        if useAnimation != false
            useAnimation = true
        # start position
        if typeof position == 'string' and position.toLowerCase() == 'start'
            position = deepCopy(START_POSITION)
        # convert FEN to position object
        if validFen(position) == true
            position = fenToObj(position)
        # validate position object
        if validPositionObject(position) != true
            error 6482, 'Invalid value passed to the position method.', position
            return
        if useAnimation == true
            # start the animations
            doAnimations calculateAnimations(CURRENT_POSITION, position), CURRENT_POSITION, position
            # set the new position
            setCurrentPosition position
        else
            setCurrentPosition position
            drawPositionInstant()
        return

    widget.resize = ->
        # calulate the new square size
        SQUARE_SIZE = calculateSquareSize()
        # set board width
        boardEl.css 'width', SQUARE_SIZE * 8 + 'px'
        # set drag piece size
        draggedPieceEl.css
            height: SQUARE_SIZE
            width: SQUARE_SIZE
        # spare pieces
        if cfg.sparePieces == true
            containerEl.find('.' + CSS.sparePieces).css 'paddingLeft', SQUARE_SIZE + BOARD_BORDER_SIZE + 'px'
        # redraw the board
        drawBoard()
        return

    # set the starting position

    widget.start = (useAnimation) ->
        widget.position 'start', useAnimation
        return

    # go time
    init()
    # return the widget object
    return widget
# end window.ChessBoard
# expose util functions
ChessBoard.fenToObj = fenToObj
ChessBoard.objToFen = objToFen

module.exports = {ChessBoard}
