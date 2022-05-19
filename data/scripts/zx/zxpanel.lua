local GLOBALS = {
    GRID_LAYER = nil,
    INK_LAYER = nil,
    PAPER_LAYER = nil,
    PIXEL_GRP = nil,
    BRUSHES = 
    {
        SHADES = {0xffffffff,0xffbababa,0xff9b9b9b,0xff7c7c7c,0xff5d5d5d,0xff3e3e3e,0xff1f1f1f,0xff000000},
    },
    PALETTES = 
    {
        BRIGHT_ON = {0xff000000,0xffff0000,0xff0000ff,0xffff00ff,0xff00ff00,0xffffff00,0xff00ffff,0xffffffff},
        BRIGHT_OFF = {0xff000000,0xffd70000,0xff0000d7,0xffd700d7,0xff00d700,0xffd7d700,0xff00d7d7,0xffd7d7d7},
        BRIGHT_ON_INDEX_MAP = {},
        BRIGHT_OFF_INDEX_MAP = {}
    }
}

local DEFINES = {
    INK_LAYER = "INK",
    PAPER_LAYER = "PAPER",
    PIXELS_LAYER = "PIXELS",
    PIXELS_GROUP = "GRP_PIXELS",
    GRID_LAYER = "GRID",
    --
    SCR_ROWS = {0,8,16,24,32,40,48,56,1,9,17,25,33,41,49,57,2,10,18,26,34,42,50,58,3,11,19,27,35,43,51,59,4,12,20,28,36,44,52,60,5,13,21,29,37,45,53,61,6,14,22,30,38,46,54,62,7,15,23,31,39,47,55,63,64,72,80,88,96,104,112,120,65,73,81,89,97,105,113,121,66,74,82,90,98,106,114,122,67,75,83,91,99,107,115,123,68,76,84,92,100,108,116,124,69,77,85,93,101,109,117,125,70,78,86,94,102,110,118,126,71,79,87,95,103,111,119,127,128,136,144,152,160,168,176,184,129,137,145,153,161,169,177,185,130,138,146,154,162,170,178,186,131,139,147,155,163,171,179,187,132,140,148,156,164,172,180,188,133,141,149,157,165,173,181,189,134,142,150,158,166,174,182,190,135,143,151,159,167,175,183,191,}
}

------------------------
local function try(f, catch_f)
    local status, exception = pcall(f)
    if not status and catch_f ~= nil then catch_f(exception)
    end
end

local function paint8x8symbol(x, y, layer, frame, color)
    if (x < 0) or (y < 0) then return end

    sx = math.floor(x / 8)
    sy = math.floor(y / 8)

    local cel = layer:cel(frame)
    for ix = 0,7,1 do 
        for iy = 0,7,1 do
            cel.image:drawPixel((sx*8)+ix, (sy*8)+iy, color)
        end
    end
    app.refresh()
end

local function layerExistsIn(parent, lyrName)
    local result = nil
    for i,layer in ipairs(parent.layers) do
        if layer.name == lyrName
        then
            result = layer
            break
        end
        if layer.isGroup
        then
            result = layerExistsIn(layer, lyrName)
            if result ~= nil then break end
        end
    end
    return result
end
-------------------------
local function initPalette(bright)
    local sprite = app.activeSprite
    local palette = sprite.palettes[1]
    palette:resize(8)
    local used = bright and GLOBALS.PALETTES.BRIGHT_ON or GLOBALS.PALETTES.BRIGHT_OFF
    for i = 0,7,1 do
        palette:setColor(i,used[i+1])
    end
    --
    for index,value in pairs(GLOBALS.PALETTES.BRIGHT_OFF) do
        GLOBALS.PALETTES.BRIGHT_OFF_INDEX_MAP[value]=index
    end
    --
    for index,value in pairs(GLOBALS.PALETTES.BRIGHT_ON) do
        GLOBALS.PALETTES.BRIGHT_ON_INDEX_MAP[value]=index
    end
end

local function debugPaint()
    for x = 0, 31, 1 do
        for y = 0, 23, 1 do
            px = x * 8
            py = y * 8
            color0index = math.random(2,8)
            color1index = math.random(2,8)
            paint8x8symbol(px, py, GLOBALS.INK_LAYER, 1, GLOBALS.PALETTES.BRIGHT_OFF[color0index])
            paint8x8symbol(px, py, GLOBALS.PAPER_LAYER,1, GLOBALS.PALETTES.BRIGHT_OFF[color1index])
        end
    end
end

local function mergeImages(...)
    args = {...}
    image = Image(args[1].width, args[1].height, args.colorMode)
    for i,k in ipairs(args) do
        for x = 0, args[1].width - 1, 1 do
            for y = 0, args[1].height - 1, 1 do
                local c = args[i]:getPixel(x,y)
                if c == 0xff000000 then
                    image:drawPixel(x,y,0xff000000)
                end
            end
        end
    end
    return image
end

local function initBrushes()
    GLOBALS.BRUSHES.INDEX = {}
    GLOBALS.BRUSHES.MERGED = true
    --ADD MERGED BRUSHES
    GLOBALS.BRUSHES.IMAGES = {
        BASE = {size = 16, image = Image(4,4,ColorMode.RGB)},
        A = {size = 16, image = Image(4,4,ColorMode.RGB)},
        B = {size = 16, image = Image(4,4,ColorMode.RGB)},
        C = {size = 16, image = Image(4,4,ColorMode.RGB)},
        D = {size = 16, image = Image(4,4,ColorMode.RGB)},
        E = {size = 16, image = Image(4,4,ColorMode.RGB)},
        F = {size = 16, image = Image(4,4,ColorMode.RGB)},
        G = {size = 16, image = Image(4,4,ColorMode.RGB)},
        --
        MERGED_A = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_B = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_C = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_D = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_E = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_F = {size = 16, image = Image(4,4,ColorMode.RGB)},
        MERGED_G = {size = 16, image = Image(4,4,ColorMode.RGB)},
    }
    --BASE
    GLOBALS.BRUSHES.IMAGES.BASE.image:drawPixel(1,3,0xff000000)
    GLOBALS.BRUSHES.IMAGES.BASE.image:drawPixel(3,1,0xff000000)
    --A
    GLOBALS.BRUSHES.IMAGES.A.image:drawPixel(1,1,0xff000000)
    GLOBALS.BRUSHES.IMAGES.A.image:drawPixel(3,3,0xff000000)
    --B
    GLOBALS.BRUSHES.IMAGES.B.image:drawPixel(0,2,0xff000000)
    GLOBALS.BRUSHES.IMAGES.B.image:drawPixel(2,0,0xff000000)
    --C
    GLOBALS.BRUSHES.IMAGES.C.image:drawPixel(0,0,0xff000000)
    GLOBALS.BRUSHES.IMAGES.C.image:drawPixel(2,2,0xff000000)
    --D
    GLOBALS.BRUSHES.IMAGES.D.image:drawPixel(0,3,0xff000000)
    GLOBALS.BRUSHES.IMAGES.D.image:drawPixel(2,1,0xff000000)
    --E
    GLOBALS.BRUSHES.IMAGES.E.image:drawPixel(0,1,0xff000000)
    GLOBALS.BRUSHES.IMAGES.E.image:drawPixel(2,3,0xff000000)
    --F
    GLOBALS.BRUSHES.IMAGES.F.image:drawPixel(1,2,0xff000000)
    GLOBALS.BRUSHES.IMAGES.F.image:drawPixel(3,0,0xff000000)
    --G
    GLOBALS.BRUSHES.IMAGES.G.image:drawPixel(1,0,0xff000000)
    GLOBALS.BRUSHES.IMAGES.G.image:drawPixel(3,2,0xff000000)
    --MERGED_A
    GLOBALS.BRUSHES.IMAGES.MERGED_A.image = mergeImages(GLOBALS.BRUSHES.IMAGES.BASE.image, GLOBALS.BRUSHES.IMAGES.A.image)
    --MERGED_B
    GLOBALS.BRUSHES.IMAGES.MERGED_B.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_A.image, GLOBALS.BRUSHES.IMAGES.B.image)
    --MERGED_C
    GLOBALS.BRUSHES.IMAGES.MERGED_C.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_B.image, GLOBALS.BRUSHES.IMAGES.C.image)
    --MERGED_D
    GLOBALS.BRUSHES.IMAGES.MERGED_D.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_C.image, GLOBALS.BRUSHES.IMAGES.D.image)
    --MERGED_E
    GLOBALS.BRUSHES.IMAGES.MERGED_E.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_D.image, GLOBALS.BRUSHES.IMAGES.E.image)
    --MERGED_F
    GLOBALS.BRUSHES.IMAGES.MERGED_F.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_E.image, GLOBALS.BRUSHES.IMAGES.F.image)
    --MERGED_G
    GLOBALS.BRUSHES.IMAGES.MERGED_G.image = mergeImages(GLOBALS.BRUSHES.IMAGES.MERGED_F.image, GLOBALS.BRUSHES.IMAGES.G.image)
    --Init index table
    for index,value in pairs(GLOBALS.BRUSHES.SHADES) do
        GLOBALS.BRUSHES.INDEX[value]=index
    end
    --Init brushes
    GLOBALS.BRUSHES.PALETTE = {
        PIXEL = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.BASE.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.BASE.image, pattern=BrushPattern.ORIGIN},
        BASE = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.BASE.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.BASE.image, pattern=BrushPattern.ORIGIN},
        A = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.A.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.A.image, pattern=BrushPattern.ORIGIN},
        B = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.B.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.B.image, pattern=BrushPattern.ORIGIN},
        C = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.C.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.C.image, pattern=BrushPattern.ORIGIN},
        D = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.D.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.D.image, pattern=BrushPattern.ORIGIN},
        E = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.E.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.E.image, pattern=BrushPattern.ORIGIN},
        F = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.F.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.F.image, pattern=BrushPattern.ORIGIN},
        G = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.G.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.G.image, pattern=BrushPattern.ORIGIN},
        MERGED_A = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_A.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_A.image, pattern=BrushPattern.ORIGIN},
        MERGED_B = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_B.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_B.image, pattern=BrushPattern.ORIGIN},
        MERGED_C = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_C.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_C.image, pattern=BrushPattern.ORIGIN},
        MERGED_D = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_D.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_D.image, pattern=BrushPattern.ORIGIN},
        MERGED_E = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_E.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_E.image, pattern=BrushPattern.ORIGIN},
        MERGED_F = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_F.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_F.image, pattern=BrushPattern.ORIGIN},
        MERGED_G = Brush{type=BrushType.IMAGE, size = GLOBALS.BRUSHES.IMAGES.MERGED_G.size, angle=0, center=Point, image=GLOBALS.BRUSHES.IMAGES.MERGED_G.image, pattern=BrushPattern.ORIGIN}
    }
end

local function initLayers()
    local sprite = app.activeSprite
    local ink = layerExistsIn(sprite, DEFINES.INK_LAYER)
    local paper = layerExistsIn(sprite, DEFINES.PAPER_LAYER)
    local pxgroup = layerExistsIn(sprite, DEFINES.PIXELS_GROUP)
    local pixels = layerExistsIn(sprite, DEFINES.PIXELS_LAYER)
 
    if pixels == nil
    then
        pixels = sprite:newLayer()
        pixels.name = DEFINES.PIXELS_LAYER
        for i,frame in ipairs(sprite.frames) do
            local cel = sprite:newCel(pixels, i)
            cel.image:clear(0xffffffff)
        end
    end
    if pxgroup == nil
    then
        pxgroup = sprite:newGroup()
        pxgroup.name = DEFINES.PIXELS_GROUP
        pixels.parent = pxgroup
    end
    if ink == nil
    then
        ink = sprite:newLayer()
        ink.name = DEFINES.INK_LAYER
        for i,frame in ipairs(sprite.frames) do
            local cel = sprite:newCel(ink, i)
            cel.image:clear(GLOBALS.PALETTES.BRIGHT_OFF[8])
        end
        ink.blendMode = BlendMode.PIXEL_PAINT
    end
    if paper == nil
    then
        paper = sprite:newLayer()
        paper.name = DEFINES.PAPER_LAYER
        for i,frame in ipairs(sprite.frames) do
            local cel = sprite:newCel(paper, i)
            cel.image:clear(GLOBALS.PALETTES.BRIGHT_OFF[1])
        end
        paper.blendMode = BlendMode.EMPTY_PAINT
    end
    GLOBALS.INK_LAYER = ink
    GLOBALS.PAPER_LAYER = paper
    GLOBALS.PIXEL_GRP = pxgroup
end

-------------------------
local function getIndexByColor(color)
    result = {}
    result.index = 0
    result.bright = false

    index = GLOBALS.PALETTES.BRIGHT_OFF_INDEX_MAP[color]
    if index ~= nil then
        result.bright = false
        result.index = index - 1
        return result
    end

    index = GLOBALS.PALETTES.BRIGHT_ON_INDEX_MAP[color]
    if index ~= nil then
        result.bright = true
        result.index = index - 1
        return result
    end

    return result
end

local function selectTopLayerFromPixelGroup()
    GLOBALS.PIXEL_GRP.layers[#GLOBALS.PIXEL_GRP.layers].isActive = true
    return GLOBALS.PIXEL_GRP.layers[#GLOBALS.PIXEL_GRP.layers]
end

local function setPixelDraw(brush)
    initPalette(true)
    selectTopLayerFromPixelGroup()
    local currentToolId = app.activeTool:id()
    if currentToolId ~= "spray" then
        app.setActiveTool("pencil")
    end
    app.activeBrush = brush
    app.fgColor = GLOBALS.PALETTES.BRIGHT_ON[1]
    app.bgColor = GLOBALS.PALETTES.BRIGHT_ON[8]
end

local function setInkPaintFreehand() 
    GLOBALS.INK_LAYER.isActive = true
    app.setActiveTool("pencil")
    app.activeBrush = Brush{type=BrushType.CIRCLE, size=8, angle=0}
end

local function setPaperPaintFreehand() 
    GLOBALS.PAPER_LAYER.isActive = true
    app.setActiveTool("pencil")
    app.activeBrush = Brush{type=BrushType.CIRCLE, size=8, angle=0}
end

local function adjustColors()
    local function adjust8x8colors(i, j, pixelsLayer)
        local inkCel = GLOBALS.INK_LAYER:cel(app.activeFrame)
        local paperCel = GLOBALS.PAPER_LAYER:cel(app.activeFrame)
        local pixelsCel = pixelsLayer:cel(app.activeFrame)
        local maxInk = 0
        local maxPaper = 0
        local selectedInk = -1
        local selectedPaper = -1
        local inkColors = {}
        local paperColors = {}

        for x = i*8,i*8+7,1 do
            for y = j*8,j*8+7,1 do
                pixelColor = pixelsCel.image:getPixel(x,y)
                inkColor = inkCel.image:getPixel(x,y)
                paperColor = paperCel.image:getPixel(x,y)
                if not (pixelColor == 0xffffffff or ((pixelColor & 0xff000000) == 0)) then 
                    inkColors[inkColor] = inkColors[inkColor] == nil and 1 or inkColors[inkColor] + 1
                else
                    paperColors[paperColor] = paperColors[paperColor] == nil and 1 or paperColors[paperColor] + 1
                end
            end
        end

        for i,value in ipairs(GLOBALS.PALETTES.BRIGHT_ON) do
            if (inkColors[value] ~= nil) and (inkColors[value] > maxInk) then maxInk = inkColors[value] selectedInk = value end
            if (paperColors[value] ~= nil) and (paperColors[value] > maxPaper) then maxPaper = paperColors[value] selectedPaper = value end
        end
        for i,value in ipairs(GLOBALS.PALETTES.BRIGHT_OFF) do
            if (inkColors[value] ~= nil) and (inkColors[value] > maxInk) then maxInk = inkColors[value] selectedInk = value end
            if (paperColors[value] ~= nil) and (paperColors[value] > maxPaper) then maxPaper = paperColors[value] selectedPaper = value end
        end

        local paper = getIndexByColor(selectedPaper)
        local ink = getIndexByColor(selectedInk)
        if ink.bright ~= paper.bright then
            local palette = ink.bright and GLOBALS.PALETTES.BRIGHT_ON or GLOBALS.PALETTES.BRIGHT_OFF
            selectedPaper = palette[paper.index + 1]
        end

        paint8x8symbol(i*8, j*8, GLOBALS.PAPER_LAYER, app.activeFrame, selectedPaper)
        paint8x8symbol(i*8, j*8, GLOBALS.INK_LAYER, app.activeFrame, selectedInk)
    end

    -------
    local visGrid = GLOBALS.GRID_LAYER.isVisible
    local visInk = GLOBALS.INK_LAYER.isVisible
    local visPaper = GLOBALS.PAPER_LAYER.isVisible
    GLOBALS.GRID_LAYER.isVisible = false
    GLOBALS.INK_LAYER.isVisible = false
    GLOBALS.PAPER_LAYER.isVisible = false
    app.command.FlattenLayers{visibleOnly=true}
    flattened = app.activeLayer

    for i = 0, 31, 1 do
        for j = 0, 23, 1 do
            adjust8x8colors(i, j, flattened)
        end
    end
    --
    app.undo()
    GLOBALS.GRID_LAYER.isVisible = visGrid
    GLOBALS.INK_LAYER.isVisible = visInk
    GLOBALS.PAPER_LAYER.isVisible = visPaper
    app.refresh()
end

local function setInkPaint() 
    GLOBALS.INK_LAYER.isActive = true
    local luaTool = app.activateLuaTool()
    luaTool:setOnClick(
     function(px,py,bt)
        paint8x8symbol(px, py, GLOBALS.INK_LAYER, app.activeFrame, app.fgColor)
        --
        pixFgColor = app.pixelColor.rgba(app.fgColor.red, app.fgColor.green, app.fgColor.blue, 255)
        local paperCel = GLOBALS.PAPER_LAYER:cel(app.activeFrame)
        local paper = getIndexByColor(paperCel.image:getPixel(px, py))
        local ink = getIndexByColor(pixFgColor)
        if ink.bright ~= paper.bright then
            local palette = ink.bright and GLOBALS.PALETTES.BRIGHT_ON or GLOBALS.PALETTES.BRIGHT_OFF
            local ajustedColor = palette[paper.index + 1]
            paint8x8symbol(px, py, GLOBALS.PAPER_LAYER, app.activeFrame, ajustedColor)
        end
     end)
end

local function setPaperPaint() 
    GLOBALS.PAPER_LAYER.isActive = true
    local luaTool = app.activateLuaTool()
    luaTool:setOnClick(
        function(px,py,bt)
           paint8x8symbol(px, py, GLOBALS.PAPER_LAYER, app.activeFrame, app.fgColor)
           --
           pixFgColor = app.pixelColor.rgba(app.fgColor.red, app.fgColor.green, app.fgColor.blue, 255)
           local inkCel = GLOBALS.INK_LAYER:cel(app.activeFrame)
           local ink = getIndexByColor(inkCel.image:getPixel(px, py))
           local paper = getIndexByColor(pixFgColor)
           if ink.bright ~= paper.bright then
                local palette = paper.bright and GLOBALS.PALETTES.BRIGHT_ON or GLOBALS.PALETTES.BRIGHT_OFF
                local ajustedColor = palette[ink.index + 1]
                paint8x8symbol(px, py, GLOBALS.INK_LAYER, app.activeFrame, ajustedColor)
           end
        end)
end

local function setInvertPaint()
    GLOBALS.INK_LAYER.isActive = true
    local luaTool = app.activateLuaTool()
    luaTool:setOnClick(function(px,py,bt)
        local inkColor = GLOBALS.INK_LAYER:cel(app.activeFrame).image:getPixel(px, py)
        local paperColor = GLOBALS.PAPER_LAYER:cel(app.activeFrame).image:getPixel(px, py)
        paint8x8symbol(px, py, GLOBALS.INK_LAYER, app.activeFrame, paperColor)
        paint8x8symbol(px, py, GLOBALS.PAPER_LAYER, app.activeFrame, inkColor)
    end)
end

-------

local function toggleGrid(forceHidded)
    local create_toggle_cel = function(sprite, frame)
            local cel = sprite:newCel(GLOBALS.GRID_LAYER, frame)
            local img = Image(sprite.width, sprite.height)
            img:clear(0xffffffff)
            for x = 8,sprite.width,8 do 
                for y = 0,sprite.height,1 do
                    img:drawPixel(x, y, 0xff000000)
                end
            end
            for y = 8,sprite.height,8 do 
                for x = 0,sprite.width,1 do
                    img:drawPixel(x, y, 0xff000000)
                end
            end
            cel.image = img
            GLOBALS.GRID_LAYER.isEditable = false
            GLOBALS.GRID_LAYER.blendMode = BlendMode.NORMAL
    end

    forceHidded = forceHidded or false
    local sprite = app.activeSprite
    GLOBALS.GRID_LAYER = layerExistsIn(sprite, DEFINES.GRID_LAYER)
    if GLOBALS.GRID_LAYER == nil
    then
        GLOBALS.GRID_LAYER = sprite:newLayer()
        GLOBALS.GRID_LAYER.name = DEFINES.GRID_LAYER
        GLOBALS.GRID_LAYER.opacity = 64
    end
    for i,frame in ipairs(sprite.frames) do
        try(function() sprite:cel(GLOBALS.GRID_LAYER, i) end, create_toggle_cel(sprite, i))
    end
    GLOBALS.GRID_LAYER.isVisible = not(GLOBALS.GRID_LAYER.isVisible) and not(forceHidded)
    app.refresh()
end

local function newSprite()
    app.command.NewFile{ui=false,width=256,height=192,colorMode=ColorMode.RGB}
end

local function initSprite()
    initLayers()
    toggleGrid(true)
end

local function checkSprite()
    if (GLOBALS.GRID_LAYER ~= nil and app.activeSprite == GLOBALS.GRID_LAYER.sprite) then return end
    initSprite()
end

local function onPanelShown()
    local sprite = app.activeSprite
    if sprite == nil
    then
        newSprite()
    end
    initBrushes()
    initPalette(true)
    initSprite()
end

local function shadesSelect(ev)
      app.fgColor = ev.color
end

local function ditheringSelect(ev)
    local rgbaPixelValue = app.pixelColor.rgba(ev.color.red, ev.color.green, ev.color.blue, 255)
    index = GLOBALS.BRUSHES.INDEX[rgbaPixelValue]
    brush = nil
    if index == 1 then brush = GLOBALS.BRUSHES.PALETTE.BASE end
    if index == 2 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_A or GLOBALS.BRUSHES.PALETTE.A end
    if index == 3 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_B or GLOBALS.BRUSHES.PALETTE.B end
    if index == 4 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_C or GLOBALS.BRUSHES.PALETTE.C end
    if index == 5 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_D or GLOBALS.BRUSHES.PALETTE.D end
    if index == 6 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_E or GLOBALS.BRUSHES.PALETTE.E end
    if index == 7 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_F or GLOBALS.BRUSHES.PALETTE.F end
    if index == 8 then brush = GLOBALS.BRUSHES.MERGED and GLOBALS.BRUSHES.PALETTE.MERGED_G or GLOBALS.BRUSHES.PALETTE.G end
    if brush ~= nil then setPixelDraw(brush) end
end

local function importScr(filename)
    local inp = assert(io.open(filename, "rb"))
    --read and apply pixels  
    local layer = selectTopLayerFromPixelGroup()
    local cel = layer:cel()
    for i = 1, 192, 1 do
        local y = DEFINES.SCR_ROWS[i]
        for j = 1, 32, 1 do
            local data = inp:read(1)
            local byte = string.byte(data)
            for k = 7, 0, -1 do
                local x = (j - 1) * 8 + (7 - k)
                if byte & (1 << k) > 0 then
                    cel.image:drawPixel(x, y, 0xff000000)
                end
            end
        end
    end
    --read and apply attributes
    for j = 0,23,1 do
        for i = 0,31,1 do
            local data = inp:read(1)
            local byte = string.byte(data)
            local palette = ((byte & 1<<6) > 0) and GLOBALS.PALETTES.BRIGHT_ON or GLOBALS.PALETTES.BRIGHT_OFF
            local ink = (byte & 7)
            local paper = (byte >> 3) & 7
            paint8x8symbol(i * 8, j * 8, GLOBALS.INK_LAYER, app.activeFrame, palette[ink+1])
            paint8x8symbol(i * 8, j * 8, GLOBALS.PAPER_LAYER, app.activeFrame, palette[paper+1])
        end
    end
    assert(inp:close())
    app.refresh()
end

local function exportScr(filename)
    local visGrid = GLOBALS.GRID_LAYER.isVisible
    local visInk = GLOBALS.INK_LAYER.isVisible
    local visPaper = GLOBALS.PAPER_LAYER.isVisible
    GLOBALS.GRID_LAYER.isVisible = false
    GLOBALS.INK_LAYER.isVisible = false
    GLOBALS.PAPER_LAYER.isVisible = false
    app.command.FlattenLayers{visibleOnly=true}
    flattened = app.activeLayer
    local out = assert(io.open(filename, "wb"))
    local buff = {}
    --save pixels data
    local cel = flattened:cel(app.activeFrame)
    for i = 1, 192, 1 do
        y = DEFINES.SCR_ROWS[i]
        for j = 1, 32, 1 do
            local byte = 0
            for k = 7, 0, -1 do
                local x = (j - 1) * 8 + (7 - k)
                pixel = cel.image:getPixel(x, y)
                if not (pixel == 0xffffffff or ((pixel & 0xff000000) == 0)) then byte = byte | (1 << k) end
            end
            buff[#buff + 1] = byte
         end
    end
    --save attributes
    local inkCel = GLOBALS.INK_LAYER:cel(app.activeFrame)
    local paperCel = GLOBALS.PAPER_LAYER:cel(app.activeFrame)
    for j = 0,23,1 do
        for i = 0,31,1 do
            local x = i * 8
            local y = j * 8
            ink = getIndexByColor(inkCel.image:getPixel(x, y))
            paper = getIndexByColor(paperCel.image:getPixel(x, y))
            byte = paper.index << 3 | ink.index
            if ink.bright or paper.bright then
                byte = byte | (1 << 6)
            end
            buff[#buff + 1] = byte
        end
    end
    local sbuff = string.char(table.unpack(buff))
    out:write(sbuff)
    assert(out:close())
    --
    app.undo()
    GLOBALS.GRID_LAYER.isVisible = visGrid
    GLOBALS.INK_LAYER.isVisible = visInk
    GLOBALS.PAPER_LAYER.isVisible = visPaper
    app.refresh()
end

local dlg = Dialog("ZX Helper")
onPanelShown()
dlg
  :newrow{always=true}
  :separator{id="Misc",label="Misc",text="Misc"}
  :button{text="Toggle Grid",onclick=function() checkSprite() toggleGrid() end}
  :separator{id="Paint",label="Painting",text="Paint"}
  :button{text="PIXELS",onclick=function() checkSprite() setPixelDraw(nil) end}
  :button{text="PAINT INK",onclick=function() checkSprite() setInkPaint() end}
  :button{text="PAINT PAPER",onclick=function() checkSprite() setPaperPaint() end}
  :button{text="INVERT COLORS",onclick=function() checkSprite() setInvertPaint() end}
  :separator{id="Paint",label="Free Painting",text="Paint"}
  :button{text="FREEHAND INK",onclick=function() checkSprite() setInkPaintFreehand() end}
  :button{text="FREEHAND PAPER",onclick=function() checkSprite() setPaperPaintFreehand() end}
  :button{text="ADJUST COLORS",onclick=function() checkSprite()  adjustColors() end}
  :separator{id="Colors",label="Colors",text="Colors"}
  :shades{id="Shades", label="", mode="pick", colors=GLOBALS.PALETTES.BRIGHT_OFF, onclick=function(ev) checkSprite() initPalette(false) shadesSelect(ev) end}
  :shades{id="Shades", label="", mode="pick", colors=GLOBALS.PALETTES.BRIGHT_ON, onclick=function(ev) checkSprite() initPalette(true) shadesSelect(ev) end }
  :separator{id="Dithering",label="Dithering",text="Dithering"}
  :shades{id="Shades", label="", mode="pick", colors=GLOBALS.BRUSHES.SHADES, onclick=function(ev) checkSprite() ditheringSelect(ev) end }
  :check{id="Merged", label="", text="Merged", selected=true, onclick=function() GLOBALS.BRUSHES.MERGED = not(GLOBALS.BRUSHES.MERGED) end}
  :separator{id="SCR",label="",text="SCR File"}
  --:newrow{always=false}
  :button{text="New",onclick=function() newSprite() initSprite() end}
  :file{id="import",label="",title="Load",open=true,save=false,filename="Import", filetypes={"scr"},onchange=function() newSprite() initSprite() importScr(dlg.data.import) end }
  :file{id="export",label="",title="Save",open=false,save=true,filename="Export",onchange=function() checkSprite() exportScr(dlg.data.export) end }
  :show{wait=false}

