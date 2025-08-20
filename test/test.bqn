lf←@+10 # line feed
cl←@+3  # ctrl+c
e←@+27 

term←{
  OutRaw  ⇐ {𝕩}
  Flush   ⇐ {𝕩}
  RawMode ⇐ {𝕩}
}

Test←{ f 𝕊 inb‿exp:
  inb↩∾cl∾˜lf∾˜¨inb ⋄ outb←⟨⟩
  ⟨Run⟩←{
    Out  ⇐ {outb∾⟜⟨•Fmt𝕩⟩↩}
    In   ⇐ {𝕊:t←⊑1↑inb⋄inb↩1↓inb⋄t}
    term ⇐ term
  } •Import "../src/e.bqn"

  Run •path∾'/'∾f

  ! outb≡exp
}

#"ex.a.bqn" Test ⟨"a"⟩‿⟨"⟨ 0 1 2 ⟩"⟩                             # should print out assigned variables
#"ex.c.bqn" Test ⟨"a","𝕨", "b", "𝕩"⟩‿⟨"111", "111","555","555"⟩  # should print out argument variables in function
# TODO test imports
"ex.e.bqn" Test ⟨"a","b"⟩‿⟨"10", "20"⟩                          # should print out argument variables in break point position

•Out "ok ✓"
