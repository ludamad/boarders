local rawget = rawget
local new, jaws = js.new, js.global.jaws
local RES_X, RES_Y = 512, 512
_G.SpriteGrid = newType({
  init = function(self, w, h)
    assert(w and h)
    for y = 1, h do
      do
        local _accum_0 = { }
        local _len_0 = 1
        for x = 1, w do
          _accum_0[_len_0] = false
          _len_0 = _len_0 + 1
        end
        self[y] = _accum_0
      end
    end
  end
})
_G.JawsWrapper = newType({
  _newGameObj = function(self)
    local gameObj = _GAME_MAP[self.gamePath]()
    return rawset(gameObj, "setCursorOptions", function(_, options)
      local image, area, align
      image, area, align = options.image, options.area, options.align
      self.cursorOptions.sprite = image and self:getSprite(image, jaws.mouse_x, jaws.mouse_y)
      self.cursorOptions.align = align
      self.cursorOptions.area = area
    end)
  end,
  init = function(self, gamePath)
    self.gamePath = gamePath
    self.gameObj = self:_newGameObj()
    self.assetsAdded = { }
    self.spriteSheets = { }
    self.imagePaths = { }
    self.areaToSpriteGrid = { }
    self.areaToBackgroundSprite = { }
    self.activeSprites = { }
    self.cursorOptions = { }
  end,
  _setSpriteXyInBox = function(self, obj, x, y, w, h)
    obj.x = x + (w - obj.width) / 2
    obj.y = y + (h - obj.height) / 2
    return obj
  end,
  _toAreaXy = function(self, area, x, y)
    local bg = self.areaToBackgroundSprite[area]
    local ax, ay = bg.x, bg.y
    local aw, ah = bg.width, bg.height
    local rows, cols = #area[1], #area
    local sw, sh = aw / rows, ah / cols
    return math.floor((x - ax) / sw), math.floor((y - ay) / sh)
  end,
  _centralize = function(self, obj)
    local w, h = obj.image.width, obj.image.height
    if not obj.x then
      obj.x = (RES_X - w) / 2
    end
    if not obj.y then
      obj.y = (RES_Y - h) / 2
    end
    return obj
  end,
  _toJsArray = function(self, arr)
    local jsCpy = new(js.global.Array)
    for _index_0 = 1, #arr do
      local v = arr[_index_0]
      jsCpy:push(v)
    end
    return jsCpy
  end,
  addAssets = function(self, imageName)
    local isAdded = self.assetsAdded[imageName]
    if not isAdded then
      return jaws.assets:add("src/" .. tostring(self.gamePath) .. "/images/" .. tostring(imageName))
    end
  end,
  getSpriteSheet = function(self, imageName)
    local sheet = self.spriteSheets[imageName]
    if not sheet then
      local options = self:_toJsObject({
        image = "src/" .. tostring(self.gamePath) .. "/images/" .. tostring(imageName)
      })
      sheet = new(jaws.SpriteSheet, options)
      self.spriteSheets[imageName] = sheet
    end
    return sheet
  end,
  getSprite = function(self, imageName, x, y)
    local options = self:_toJsObject(self:_centralize({
      image = self:getSpriteSheet(imageName).frames[0],
      x = x,
      y = y
    }))
    return new(jaws.Sprite, options)
  end,
  update = function(self) end,
  setup = function(self)
    self.gameObj:update()
    self.activeSprites = { }
    local areas = rawget(self.gameObj, "areas")
    for i = 1, #areas do
      local area = rawget(areas, i)
      if not self.areaToSpriteGrid[area] then
        self.areaToSpriteGrid[area] = SpriteGrid(#area[1], #area)
      end
      local img = rawget(area, "image")
      local ax, ay = rawget(area, "x"), rawget(area, "y")
      local aw, ah = rawget(area, "w"), rawget(area, "h")
      if img ~= nil and img ~= "none" then
        local sprite = self:getSprite(img, ax, ay)
        append(self.activeSprites, sprite)
        self.areaToBackgroundSprite[area] = sprite
        ax, ay = sprite.x, sprite.y
        aw, ah = sprite.width, sprite.height
      end
      for y = 1, #area do
        local row = rawget(area, y)
        for x = 1, #row do
          local val = rawget(row, x)
          local pieceMap = rawget(self.gameObj, "pieceMap")
          local piece = rawget(pieceMap, val)
          local image = rawget(piece, "image")
          local sprite = false
          if image ~= nil and image ~= "none" then
            local pw, ph = aw / #row, ah / #area
            sprite = self:_setSpriteXyInBox(self:getSprite(image), ax + pw * (x - 1), ay + ph * (y - 1), pw, ph)
            append(self.activeSprites, sprite)
          end
          self.areaToSpriteGrid[area][y][x] = sprite
        end
      end
    end
  end,
  _mwrap = function(self, method)
    return function(...)
      return self[method](self, ...)
    end
  end,
  _toJsObject = function(self, obj)
    local jsObj = new(js.global.Object)
    for k, v in pairs(obj) do
      jsObj[k] = v
    end
    return jsObj
  end,
  start = function(self)
    local _list_0 = rawget(self.gameObj, "pieces")
    for _index_0 = 1, #_list_0 do
      local piece = _list_0[_index_0]
      local img = rawget(piece, "image")
      if img ~= nil and img ~= "none" then
        self:addAssets(img)
      end
    end
    local _list_1 = rawget(self.gameObj, "areas")
    for _index_0 = 1, #_list_1 do
      local area = _list_1[_index_0]
      if rawget(area, "image") then
        self:addAssets(rawget(area, "image"))
      end
    end
    local jsGameObj = self:_toJsObject({
      setup = self:_mwrap("setup"),
      update = self:_mwrap("update"),
      draw = self:_mwrap("draw")
    })
    return jaws:start(jsGameObj, {
      fps = 30
    })
  end,
  _withinArea = function(self, area, x, y, w, h)
    local bg = self.areaToBackgroundSprite[area]
    local bg_w, bg_h = bg.width, bg.height
    if x + w / 2 < bg.x or y + h / 2 < bg.y then
      return false
    end
    if x - w / 2 > bg.x + bg_w or y - h / 2 > bg.y + bg_h then
      return false
    end
    return true
  end,
  draw = function(self)
    jaws.context.fillStyle = "#FFF"
    jaws.context:fillRect(0, 0, jaws.width, jaws.height)
    jaws.context.strokeStyle = "#000000"
    jaws.context:strokeRect(0, 0, jaws.width, jaws.height)
    local _list_0 = self.activeSprites
    for _index_0 = 1, #_list_0 do
      local sprite = _list_0[_index_0]
      sprite:draw()
    end
    if self.cursorOptions.sprite then
      local area, sprite, align
      do
        local _obj_0 = self.cursorOptions
        area, sprite, align = _obj_0.area, _obj_0.sprite, _obj_0.align
      end
      sprite.x, sprite.y = jaws.mouse_x - sprite.width / 2, jaws.mouse_y - sprite.height / 2
      if not area or self:_withinArea(area, jaws.mouse_x, jaws.mouse_y, sprite.width, sprite.height) then
        if align then
          local ax, ay = self:_toAreaXy(area, jaws.mouse_x, jaws.mouse_y)
          sprite.x, sprite.y = ax * 140, ay * 140
        else
          sprite.x, sprite.y = jaws.mouse_x - sprite.width / 2, jaws.mouse_y - sprite.height / 2
        end
        return sprite:draw()
      end
    end
  end
})
