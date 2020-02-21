const ttf = staticRead("Roboto-Regular.ttf")

import unittest

import paratext

test "load font":
  var info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info.addr, ttf, 0)

  const size = 512
  const bitmapSize = size * size
  var tempBitmap: array[bitmapSize, cuchar]
  var cdata: array[96, stbtt_bakedchar]
  doAssert 0 != stbtt_BakeFontBitmap(data = ttf, offset = 0, pixel_height = 32,
                                     pixels = tempBitmap[0].addr, pw = size, ph = size, first_char = 32,
                                     num_chars = cdata.len.cint, chardata = cdata[0].addr)
