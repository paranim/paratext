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

proc stbtt_InitFont*(info: ptr stbtt_fontinfo; data: cstring; offset: cint): cint {.cdecl, importc: "stbtt_InitFont".}

