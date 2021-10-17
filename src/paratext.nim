{.compile: "paratext/stb_truetype.c".}

type
  stbtt_buf* {.bycopy.} = object
    data*: ptr uint8
    cursor*: cint
    size*: cint

  stbtt_fontinfo* {.bycopy.} = object
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

  RootFont*[CharN: static[int], CharT] = object of RootObj
    info*: stbtt_fontinfo
    chars*: array[CharN, CharT]
    bitmap*: tuple[width: cint, height: cint, data: seq[uint8]]
    bakeResult*: cint
    ascent*: cint
    descent*: cint
    lineGap*: cint
    scale*: cfloat
    baseline*: cfloat
    height*: cfloat

  BakedChar* {.bycopy.} = object
    x0*: cushort
    y0*: cushort
    x1*: cushort
    y1*: cushort
    xoff*: cfloat
    yoff*: cfloat
    xadvance*: cfloat

  BakedFont*[CharN: static[int]] = object of RootFont[CharN, BakedChar]
    firstChar*: cint

  Font*[CharN: static[int]] = BakedFont[CharN] # this is for backwards compat

proc stbtt_InitFont(info: ptr stbtt_fontinfo; data: cstring; offset: cint): cint {.cdecl, importc.}

proc stbtt_BakeFontBitmap(data: cstring; offset: cint; pixelHeight: cfloat;
                          pixels: ptr uint8; pw: cint; ph: cint; firstChar: cint;
                          numChars: cint; chardata: ptr BakedChar): cint {.cdecl, importc.}

proc stbtt_GetFontVMetrics(info: ptr stbtt_fontinfo; ascent: ptr cint;
                           descent: ptr cint; lineGap: ptr cint) {.cdecl, importc.}

proc stbtt_ScaleForPixelHeight(info: ptr stbtt_fontinfo; pixels: cfloat): cfloat {.cdecl, importc.}

proc initFont*(
      ttf: cstring,
      fontHeight: cfloat,
      firstChar: cint,
      bitmapWidth: static[int],
      bitmapHeight: static[int],
      charCount: static[int],
    ): BakedFont[charCount] =
  result.info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info = result.info.addr, data = ttf, offset = 0)

  result.bitmap.width = bitmapWidth
  result.bitmap.height = bitmapHeight
  result.bitmap.data = newSeq[uint8](bitmapWidth * bitmapHeight)
  result.bakeResult = stbtt_BakeFontBitmap(data = ttf, offset = 0, pixelHeight = fontHeight,
                                           pixels = result.bitmap.data[0].addr, pw = result.bitmap.width, ph = result.bitmap.height, firstChar = firstChar,
                                           numChars = charCount, chardata = result.chars[0].addr)
  stbtt_GetFontVMetrics(info = result.info.addr, ascent = result.ascent.addr,
                        descent = result.descent.addr, lineGap = result.lineGap.addr)
  result.scale = stbtt_ScaleForPixelHeight(info = result.info.addr, pixels = fontHeight)
  result.baseline = result.ascent.cfloat * result.scale
  result.height = fontHeight
  result.firstChar = firstChar

type
  stbtt_pack_context* {.bycopy.} = object
    user_allocator_context*: pointer
    pack_info*: pointer
    width*: cint
    height*: cint
    stride_in_bytes*: cint
    padding*: cint
    skip_missing*: cint
    h_oversample*: cuint
    v_oversample*: cuint
    pixels*: ptr cuchar
    nodes*: pointer

  PackedChar* {.bycopy.} = object
    x0*: cushort
    y0*: cushort
    x1*: cushort
    y1*: cushort               ##  coordinates of bbox in bitmap
    xoff*: cfloat
    yoff*: cfloat
    xadvance*: cfloat
    xoff2*: cfloat
    yoff2*: cfloat

  PackedFont*[CharN: static[int]] = object of RootFont[CharN, PackedChar]

proc stbtt_PackBegin(spc: ptr stbtt_pack_context, pixels: ptr uint8, width: cint, height: cint, stride_in_bytes: cint, padding: cint, alloc_context: pointer): cint {.cdecl, importc.}

proc stbtt_PackFontRange(spc: ptr stbtt_pack_context, fontdata: cstring, font_index: cint, font_size: cfloat,
                         first_unicode_char_in_range: cint, num_chars_in_range: cint, chardata_for_range: ptr PackedChar): cint {.cdecl, importc.}

proc stbtt_PackEnd(spc: ptr stbtt_pack_context) {.cdecl, importc.}

proc initFont*(
      ttf: cstring,
      fontHeight: cfloat,
      ranges: openArray[tuple[firstChar: cint, lastChar: cint]],
      bitmapWidth: static[int],
      bitmapHeight: static[int],
      charCount: static[int],
    ): PackedFont[charCount] =
  result.info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info = result.info.addr, data = ttf, offset = 0)

  result.bitmap.width = bitmapWidth
  result.bitmap.height = bitmapHeight
  result.bitmap.data = newSeq[uint8](bitmapWidth * bitmapHeight)

  var ctx: stbtt_pack_context
  result.bakeResult = stbtt_PackBegin(spc = ctx.addr, pixels = result.bitmap.data[0].addr, width = result.bitmap.width, height = result.bitmap.height,
                                      stride_in_bytes = 0, padding = 1, alloc_context = nil)
  var numCharsSoFar = 0
  for (firstChar, lastChar) in ranges:
    assert firstChar <= lastChar
    assert numCharsSoFar <= charCount
    let numChars = lastChar - firstChar + 1
    if result.bakeResult == 0:
      break
    result.bakeResult = stbtt_PackFontRange(spc = ctx.addr, fontdata = ttf, font_index = 0, font_size = fontHeight,
                                            first_unicode_char_in_range = firstChar, num_chars_in_range = numChars, result.chars[numCharsSoFar].addr)
    numCharsSoFar += numChars
  stbtt_PackEnd(ctx.addr)

  stbtt_GetFontVMetrics(info = result.info.addr, ascent = result.ascent.addr,
                        descent = result.descent.addr, lineGap = result.lineGap.addr)
  result.scale = stbtt_ScaleForPixelHeight(info = result.info.addr, pixels = fontHeight)
  result.baseline = result.ascent.cfloat * result.scale
  result.height = fontHeight

