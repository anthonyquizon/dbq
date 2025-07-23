gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"

a←"
  a←1%⋄•Show a+2
  b←1%⋄•Show b+3
"

z←a='%'
•SHow ' '¨⌾(z⊸/) a
