const ttf = staticRead("Roboto-Regular.ttf")

import unittest

import paratext

test "load font":
  discard initFont(ttf = ttf, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)
