COLUMN_NAMES = {"A", "B", "C"}

GameDefine {
    name: "TicTacToe"
    -- Create a new TicTacToe board, define the pieces and players
    init: () =>
        -- Define the pieces and their appearance:
        @PieceType {value: 0, name: "Empty", charRepr: "-"}
        @PieceType {value: 1, name: "X", charRepr: "X", image: "X_64x64.png"}
        @PieceType {value: -1, name: "O", charRepr: "O", image: "O_64x64.png"}
        -- Define the boards:
        @board = @GameGrid {
            name: "Board" 
            image: "Board_420x420.png"
            -- Board size and location:
            placement: "center"
            {0, 0, 1}
            {0, 0, -1}
            {0, 0, 1}
        }
        @player = 1
        -- Define the player objects. The first one added is assigned to @player
        @Player {value: 1, name: "X Player"}
        @Player {value: -1, name: "O Player"}

    -- Generate the moves available at this position.
    turnStart: () =>
        img = if @player.name == "X Player" then "X_64x64.png" else "O_64x64.png"
        @board\setCursor {
            image: img
            aligned: true
        }
        for y=1,3 do for x=1,3
            if @board[y][x] == 0 then @Move {
                name: COLUMN_NAMES[x] .. y -- Used in serialization?
                trigger: ClickTrigger(@board, x, y)
                action: SetAction(@player.value, Pos(@board, x, y))
            }
    -- Perform a Move, switches player turn
    doMove: (move) =>
        move\doMove()
        @turnEnd()
        @turnStart()

    -- Helper for gameWinStatus, returns if a line
    -- is completely of own piece type
    _checkLine: (x,y,dx,dy) =>
        -- Assume wins at first
        allX, allO = true, true
        while true 
            row = @board[y]
            -- Bail if not valid y location:
            if not row then break
            piece = row[x]
            -- Bail if not valid x location:
            if not piece then break
            -- Check if any win assumptions are invalidated:
            if piece ~=  1 then allX = false
            if piece ~= -1 then allO = false
            -- Move to the next position in the line:
            x += dx
            y += dy
        if allX then return  1
        if allO then return -1
        return nil

    -- Has the game been won?
    gameWinStatus: () =>
        result = nil
        checkResult = (candidate) ->
            if candidate ~= nil
                result = candidate
        -- The two diagonals
        checkResult @_checkLine(1,1, 1,1)
        checkResult @_checkLine(3,1, -1,1)
        -- The orthogonals
        for x=1,3 do checkResult @_checkLine(x,1, 0,1)
        for y=1,3 do checkResult @_checkLine(1,y, 1,0)
        -- Returns nil if no win, otherwise returns +1 or -1
        return result
}

--gamePlay "TicTacToe"
