#!/bin/sed -nurf
# -*- coding: UTF-8, tab-width: 2 -*-

s~^\{?\s*~~
s~"?,?\}?$~~
s~\r~~g
s~^"([A-Za-z0-9_-]+)": "?~\1\r~
/\r/{
  s~'~&\\&&~g
  s~$~'~
  s~^(\S+)\r~[\1]='~
  p
}
