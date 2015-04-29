--------------------------------------------------------------------------------    
-- Generic utility functions
--------------------------------------------------------------------------------

setmetatable _G, {
    __index: (k) => 
        error "Attempted to access non-existent global variable '#{k}'"
}

_G.append = table.insert

_G.newType = (methods) ->
    meta = {__index: methods}
    setmetatable meta, {
        __index: methods
        __newindex: methods
        __call: (...) =>
            obj = setmetatable({}, meta)
            methods.init(obj, ...)
            return obj
    }
    return meta

table.index_of = (table, v) -> for i=1,#table do if (table[i] == v) then return i
   
--------------------------------------------------------------------------------    
-- Game definition 
--------------------------------------------------------------------------------

_G.sizeFromImageName = (str) ->
    w, h = str\match("_(%d+)x(%d+)%.")
    assert(w and h, "'#{str}' does not have proper size format in name! (eg name_40x40.png}")
    return w, h

-- The position and piece types

_G.Pos = newType {
	init: (@area, @x, @y) =>
	get: () =>    @area\get(@x, @y)
	set: (val) => @area\set(@x, @y, val)
}

PieceType = (gameObj, pieceDesc) ->
    -- The piece type:
    type = newType {
        init: (@pos) =>
        image: pieceDesc.image
        -- set the size if we have an image
        size: pieceDesc.image and {sizeFromImageName(pieceDesc.image)}
        placement: pieceDesc.placement
    }
	append(gameObj.pieceTypes, type)
	if pieceDesc.value
		gameObj.pieceTypeValMap[pieceDesc.value] = type
	return type

-- The move types

_G.MoveAction = newType {
	init: (@from, @to) =>
	doAction: () => 
		@to\set(@from\get())
		@from\set(false)
}

_G.SetAction = newType {
	init: (@val, @to) =>
        assert(@val and @to)
	doAction: () => @to\set(@val)
}

_G.ClickTrigger = newType {
	init: (...) =>
		@pos = Pos(...)
}

_G.DragTrigger = newType {
    init: (@from, @to) =>
}

Move = newType {
	init: (@gameObj, data) =>
		@triggers = data.triggers or {data.trigger}
		@actions = data.actions or {data.action}
		append @gameObj.moves, @
	doMove: () =>
		for action in *@actions
			action\doAction()
}

-- The grid and game classes are implemented as parametric types.
-- This is used to connect to user supplied rules, and the client output.

GameGrid = newType {
    init: (@gameObj, valGrid) =>
        -- Add to the list of game grids
        append(@gameObj.grids, @)
        -- Copy over the value grid.
        -- For now, do a very literal copy:
        for k,v in pairs(valGrid)
            @[k] = v
        assert(@name)
        if @image
            @size = {sizeFromImageName(@image)}
        @gridWidth, @gridHeight = #valGrid[1], #valGrid
    	-- Positioning information:
        @scale or= {1, 1}
        @placement or= {0, 0}
        -- Piece grid for higher level access.
        -- Copied directly from valGrid if valGrid is full of objects
        @pieceGrid = [ [false for x=1, @gridWidth] for y=1,@gridHeight]
    	@_pieceValSync()
        @setCursor {} -- Set to defaults
    setCursor: (options) =>
        @cursorImage   = options.image or false
        @cursorAligned = options.aligned or false
        @gameObj\updateCursor()
    _pieceValSync: () =>
    	for y=1,@gridHeight
    		for x=1,@gridWidth
    			val = @[y][x]
                assert(val ~= nil, "grid val should not be nil!")
    			if not getmetatable(val)
	    			pieceType = @gameObj.pieceTypeValMap[val]
                    if pieceType ~= getmetatable(@pieceGrid[y][x])
    	    			val = pieceType(Pos(@, x, y))
                        @pieceGrid[y][x] = val
                else
                    @pieceGrid[y][x] = val

    -- Getters and setters: 
    getScale: () =>
        if not @scale then return 1,1
        return @scale[1], @scale[2]
    set: (x, y, val) =>
        assert(val ~= nil, "val cannot be nil!")
    	@[y][x] = val
    	@_pieceValSync()
    get: (x, y) =>
    	return @[y][x]
    getSize: () =>
    	if @size then return @size[1], @size[2]
    	-- else, calculate size relatively
    	fullW, fullH = @gameObj\getPlayAreaSize()
    	areaW, areaH = @getScale()
    	return (fullW * areaW), (fullH * areaH)
    _resolvePlacement: (p = "center") =>
        if p == "center" then p = {0.5, 0.5}
        elseif p == "left"   then p = {0, 0.5}
        elseif p == "right"  then p = {1.0, 0.5}
        return p[1], p[2]
    getXy: () =>
        fullW, fullH = @gameObj\getPlayAreaSize()
        w, h = @getSize()
        pX, pY = @_resolvePlacement(@placement)
        return (fullW * pX - (w * (1-pX))), (fullH * pY - (h * (1-pY)))
    getCellSize: () =>
        w, h = @getSize()
        return w / @gridWidth, h / @gridHeight
    getPieceXy: (piece) =>
        x, y = piece.pos.x, piece.pos.y
        fullW, fullH = @getCellSize()
        w, h = piece.size[1], piece.size[2]
        pX, pY = @_resolvePlacement(piece.placement)
        oX, oY = @getOffset(x, y)
        return (oX + fullW * pX - (w * (1-pX))), oY + (fullH * pY - (h * (1-pY)))
    getOffset: (x, y) =>
        cw, ch = @getCellSize()
        return (x-1) * cw, (y-1) * ch
}

Player = newType {
    init: (@gameObj, fields) => 
        for k,v in pairs(fields)
            @[k] = v
        append @gameObj.players, @
}

-- Used below to extend two types
extendType2 = (base1, base2, extension) ->
	for k, v in pairs(base1) do extension[k] or= v
	for k, v in pairs(base2) do extension[k] or= v
	return newType(extension)

-- Create a game state type, extended both by the rules and the interface
makeGameStateType = (Rules, Interface) -> extendType2 Rules, Interface, {
	init: () =>
		@players = {}
	    @pieceTypes, @pieceTypeValMap = {}, {}
	    @grids, @hands, @moves = {}, {}, {}
		Rules.init(@)
		Interface.init(@)
        Interface.prestart(@)
	-- Expose the classes that need gameObj as a parameter in the form of "@Class"
	:GameGrid, :Player, :Move, :PieceType
    turnEnd: () =>
        nextPlayerId = 1 + (table.index_of(@players, @player)) % #@players
        @player = @players[nextPlayerId]
    turnStart: () =>
        @moves = {}
        Rules.turnStart(@)
        Interface.turnStart(@)
	start: () =>
        @player = @players[1]
		if Rules.start     then Rules.start(@)
        Rules.turnStart(@)
        if Interface.start then Interface.start(@)
        Interface.turnStart(@)
	getPlayAreaSize: () => 512, 512
}

_GAME_MAP = {}
_G.gameLookup = (name) -> _GAME_MAP[name]

_G.GameDefine = (Rules) ->
	_GAME_MAP[Rules.name] = makeGameStateType(Rules, KineticHtml5Client)

--------------------------------------------------------------------------------    
-- Appendix: ASCII helpers
--------------------------------------------------------------------------------

-- Implemented in core so that all clients can use it:
GameGrid.asciiDraw = () =>
    print  "-- #{@name} --\n"
    for row in *@
        rowStr = ""
        for val in *row
            rowStr ..= @gameObj\pieceToAscii(val) .. ' '
        print rowStr