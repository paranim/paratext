const ttf = staticRead("Roboto-Regular.ttf")

import unittest

import paratext

test "load font":
  var info = stbtt_fontinfo()
  doAssert 1 == stbtt_InitFont(info.addr, ttf, 0)
