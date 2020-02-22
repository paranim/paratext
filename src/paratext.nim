{.compile: "stb_truetype.c".}

type
  stbtt_buf {.bycopy.} = object
    data*: ptr uint8
    cursor*: cint
    size*: cint

  stbtt_fontinfo {.bycopy.} = object
    userdata*: pointer
    data*: ptr uint8          ##  pointer to .ttf file
    fontstart*: cint          ##  offset of start of font
    numGlyphs*: cint          ##  number of glyphs, needed for range checking
    loca*: cint
    head*: cint
    glyf*: cint
    hhea*: cint
    hmtx*: cint
    kern*: cint
    gpos*: cint
    svg*: cint                ##  table locations as offset from start of .ttf
    index_map*: cint          ##  a cmap mapping for our chosen character encoding
    indexToLocFormat*: cint   ##  format needed to map from glyph index to glyph
    cff*: stbtt_buf           ##  cff font data
    charstrings*: stbtt_buf   ##  the charstring index
    gsubrs*: stbtt_buf        ##  global charstring subroutines index
    subrs*: stbtt_buf         ##  private charstring subroutines index
    fontdicts*: stbtt_buf     ##  array of font dicts
    fdselect*: stbtt_buf      ##  map from glyph to fontdict

  stbtt_bakedchar {.bycopy.} = object
    x0*: cushort
    y0*: cushort
    x1*: cushort
    y1*: cushort
    xoff*: cfloat
    yoff*: cfloat
    xadvance*: cfloat

  Font* = object
    bakedChars*: seq[stbtt_bakedchar]
    bakeResult: cint
    ascent*: cint
    descent*: cint
    lineGap*: cint
    scale*: cfloat
    baseline*: cfloat
    fontHeight: cfloat
    bitmap*: tuple[width: cint, height: cint, data: seq[uint8]]
    charCount*: cint

proc stbtt_InitFont(info: ptr stbtt_fontinfo; data: cstring; offset: cint): cint {.cdecl, importc: "stbtt_InitFont".}

proc stbtt_BakeFontBitmap(data: cstring; offset: cint; pixelHeight: cfloat;
                          pixels: ptr uint8; pw: cint; ph: cint; firstChar: cint;
                          numChars: cint; chardata: ptr stbtt_bakedchar): cint {.cdecl, importc: "stbtt_BakeFontBitmap".}

proc stbtt_GetFontVMetrics(info: ptr stbtt_fontinfo; ascent: ptr cint;
                           descent: ptr cint; lineGap: ptr cint) {.cdecl, importc: "stbtt_GetFontVMetrics".}

proc stbtt_ScaleForPixelHeight(info: ptr stbtt_fontinfo; pixels: cfloat): cfloat {.cdecl, importc: "stbtt_ScaleForPixelHeight".}

proc initFont*(ttf: cstring, fontHeight: cfloat, firstChar: cint, bitmapWidth: static[int], bitmapHeight: static[int], charCount: static[int]): Font =
  var info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info = info.addr, data = ttf, offset = 0)

  result.bitmap = (bitmapWidth.cint, bitmapHeight.cint, newSeq[uint8](bitmapWidth * bitmapHeight))
  var cdata: array[charCount, stbtt_bakedchar]
  result.bakeResult = stbtt_BakeFontBitmap(data = ttf, offset = 0, pixelHeight = fontHeight,
                                           pixels = result.bitmap.data[0].addr, pw = result.bitmap.width, ph = result.bitmap.height, firstChar = firstChar,
                                           numChars = charCount, chardata = cdata[0].addr)
  for i in 0 ..< cdata.len:
    result.bakedChars.add(cdata[i])

  stbtt_GetFontVMetrics(info = info.addr, ascent = result.ascent.addr,
                        descent = result.descent.addr, lineGap = result.lineGap.addr)
  result.scale = stbtt_ScaleForPixelHeight(info = info.addr, pixels = fontHeight)
  result.baseline = result.ascent.cfloat * result.scale
  result.fontHeight = fontHeight
  result.charCount = charCount
