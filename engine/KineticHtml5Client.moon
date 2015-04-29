-- Javascript wrapping

jsKinetic = js.global.Kinetic

_G.jsObject = (obj) ->
    jsObj = js.new(js.global.Object)
    for k,v in pairs(obj)
        jsObj[k] = v
    return jsObj

Kinetic = {
    Stage: (obj)      -> js.new(jsKinetic.Stage, jsObject(obj))
    Layer: ()         -> js.new(jsKinetic.Layer)
    Rect: (obj)       -> js.new(jsKinetic.Rect, jsObject(obj))
    Image: (obj) -> 
        obj.width, obj.height = sizeFromImageName(obj.image.src)
        return js.new(jsKinetic.Image, jsObject(obj))
    Group: (obj)      -> js.new(jsKinetic.Group, jsObject(obj))
}

ImgSetLoader = newType {
    init: (@folder) =>
        @imageLoadCount = 0
        @loadCallbacks = {}
        @srcToImage = {}
        @srcIsLoaded = {}
    getPath: (src) => "src/#{@folder}/images/#{src}"
    get: (src) =>
        assert(@srcIsLoaded[src], "'#{src}' not finished loading!")
        return @srcToImage[src]
    load: (src) =>
        if @srcToImage[src]
            return @srcToImage[src]
        print "Loading #{@getPath(src)}"
        image = js.new(js.global.Image)
        @srcToImage[src] = image
        -- Expand to real location:
        @imageLoadCount += 1
        image.onload = () ->
            @srcIsLoaded[src] = true
            @imageLoadCount -= 1
            if @imageLoadCount == 0
                for callback in *@loadCallbacks do callback() 
                @loadCallbacks = {}
        image.src = @getPath(src)
        return image
    ensureLoadedBefore: (f) =>
        if @imageLoadCount == 0 then f()
        else append(@loadCallbacks, f)
}

print = (...) -> js.global.console\log(...)

-- Base methods for games using KineticJS as their target
_G.KineticHtml5Client = {
    init: () =>
        @imageLoader = ImgSetLoader(@name)
        @cursorImage = false
        -- Create the shape of our stage:
        width, height = @getPlayAreaSize()
        @stage = Kinetic.Stage({container: "board-container", :width, :height})
        @layer = Kinetic.Layer()
        @uilayer = Kinetic.Layer()
        @stage\add(@layer)
        @stage\add(@uilayer)
        @prestart()
        @_hasStarted = false

    _relativePointerPosition: () =>
        pointer = @stage\getPointerPosition()
        pos = @stage\getPosition()
        offset = @stage\getOffset()
        scale = @stage\getScale()
        return ((pointer.x / scale.x) - (pos.x / scale.x) + offset.x), ((pointer.y / scale.y) - (pos.y / scale.y) + offset.y)

    prestart: () =>
        -- Part of ensuring everything is loaded by the time we start():
        for grid in *@grids
            @imageLoader\load(grid.image)
        for pieceType in *@pieceTypes 
            if pieceType.image then @imageLoader\load(pieceType.image)

    _clickOnGrid: (grid) =>
        gX, gY = grid\getXy()
        cW, cH = grid\getCellSize()
    	mX, mY = @_relativePointerPosition()
    	adjustedX, adjustedY = mX - gX, mY - gY
    	clickX, clickY = math.ceil(adjustedX / cW), math.ceil(adjustedY / cH)
        for move in *@moves
            for trigger in *move.triggers
                if getmetatable(trigger) == ClickTrigger
                	{:area, :x, :y} = trigger.pos
                	if x == clickX and y == clickY
                    	@doMove(move)
                    	return
    _img: (img, x, y) => Kinetic.Image({image: @imageLoader\get(img), :x, :y})
    _afterLoading: (f) => @imageLoader\ensureLoadedBefore(f)
    start: () => @imageLoader\ensureLoadedBefore () ->
    	@_hasStarted = true
        for grid in *@grids
            grid._sprite = @_img(grid.image, 0, 0)
            grid._rect = Kinetic.Rect {
                x: 0, y: 0, width: grid.size[1], height: grid.size[2], fill: 'white', stroke: 'black', strokeWidth: 2
            }
            x, y = grid\getXy()
            -- Initialize the image group for the grid:
            grid._group = Kinetic.Group({:x,:y})
            grid._group\add(grid._rect)
            grid._group\add(grid._sprite)
            grid._group\on "mousedown", () -> @_clickOnGrid(grid)
            @layer\add(grid._group)
        -- Use a small dependency
        js.global.KineticScreenAutoSize\init(@stage, "board-container")

        @stage\on "mouseleave", () ->
            @_removeIfNotMatching()
            @draw()
        @stage\on "mousemove", () -> @updateCursor()

    _removeIfNotMatching: (match) =>
        if @cursorImage and ((not match) or @cursorImage\getImage() ~= @imageLoader\get(match))
            @cursorImage\remove()
            @cursorImage = false

    updateCursor: () => 
    	if not @_hasStarted
    		return
        mX,mY = @_relativePointerPosition()
        imageName = nil
        for grid in *@grids
            gX, gY = grid\getXy()
            gW, gH = grid\getSize()
            if mX < gX or mX > gX + gW or mY < gY or mY > gY + gH
                continue
            imageName = grid.cursorImage
        -- Remove any incorrect cursor:
        @_removeIfNotMatching(imageName)
        -- Add the correct cursor, if any:
        if imageName ~= nil
            if not @cursorImage
                img = @_img(imageName, mX, mY)
                img\setOffsetX(img\getWidth()/2)
                img\setOffsetY(img\getHeight()/2)
                img\setListening(false)
                @uilayer\add(img)
                @cursorImage = img
            @cursorImage\setX(mX)
            @cursorImage\setY(mY)
        @draw()
    draw: () =>
        @layer\draw()
        @uilayer\draw()
    turnStart: () => @_afterLoading () ->
        for grid in *@grids do for y=1,grid.gridHeight do for x=1,grid.gridHeight
            piece = grid.pieceGrid[y][x]
            if piece and not piece._sprite and piece.image
                pX, pY = grid\getPieceXy(piece)
                piece._sprite = @_img(piece.image, pX, pY)
                grid._group\add(piece._sprite)
        @draw()
}
