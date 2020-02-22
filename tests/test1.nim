const ttf = staticRead("Roboto-Regular.ttf")

import unittest

import paratext

test "load font":
  var info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info = info.addr, data = ttf, offset = 0)

  const fontHeight = 32f
  const size = 512
  const bitmapSize = size * size
  var tempBitmap: array[bitmapSize, cuchar]
  var cdata: array[96, stbtt_bakedchar]
  doAssert 0 != stbtt_BakeFontBitmap(data = ttf, offset = 0, pixel_height = fontHeight,
                                     pixels = tempBitmap[0].addr, pw = size, ph = size, first_char = 32,
                                     num_chars = cdata.len.cint, chardata = cdata[0].addr)

  var ascent, descent, lineGap: cint
  stbtt_GetFontVMetrics(info = info.addr, ascent = ascent.addr,
                        descent = descent.addr, lineGap = lineGap.addr)
  let scale = stbtt_ScaleForPixelHeight(info = info.addr, pixels = fontHeight)
