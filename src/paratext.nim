{.compile: "stb_truetype.c".}

type
  stbtt_buf* {.bycopy.} = object
    data*: ptr cuchar
    cursor*: cint
    size*: cint

  stbtt_fontinfo* {.bycopy.} = object
    userdata*: pointer
    data*: ptr cuchar         ##  pointer to .ttf file
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

  stbtt_bakedchar* {.bycopy.} = object
    x0*: cushort
    y0*: cushort
    x1*: cushort
    y1*: cushort
    xoff*: cfloat
    yoff*: cfloat
    xadvance*: cfloat

proc stbtt_InitFont*(info: ptr stbtt_fontinfo; data: cstring; offset: cint): cint {.cdecl, importc: "stbtt_InitFont".}

proc stbtt_BakeFontBitmap*(data: cstring; offset: cint; pixel_height: cfloat;
                           pixels: ptr cuchar; pw: cint; ph: cint; first_char: cint;
                           num_chars: cint; chardata: ptr stbtt_bakedchar): cint {.cdecl, importc: "stbtt_BakeFontBitmap".}

proc stbtt_GetFontVMetrics*(info: ptr stbtt_fontinfo; ascent: ptr cint;
                            descent: ptr cint; lineGap: ptr cint) {.cdecl, importc: "stbtt_GetFontVMetrics".}

proc stbtt_ScaleForPixelHeight*(info: ptr stbtt_fontinfo; pixels: cfloat): cfloat {.cdecl, importc: "stbtt_ScaleForPixelHeight".}
