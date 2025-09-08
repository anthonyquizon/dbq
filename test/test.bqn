lf←@+10 # line feed
e←@+27 
cont←e∾"[44;5u"  # ctrl+.

term←{
  OutRaw  ⇐ {𝕩}
  Flush   ⇐ {𝕩}
  RawMode ⇐ {𝕩}
}

Test←{ f 𝕊 inb‿exp:
  inb↩∾(cont¨↕10)∾˜lf∾˜¨inb ⋄ outb←⟨⟩ # inb append with mulitple continues to eventually exit program without running ctrl+
  ⟨Run⟩←{
    Out  ⇐ {outb∾⟜⟨•Fmt𝕩⟩↩}
    In   ⇐ {𝕊:t←⊑1↑inb⋄inb↩1↓inb⋄t}
    term ⇐ term
  } •Import "../src/e.bqn"

  Run •path∾'/'∾f

  ! outb≡exp
}

#"cases/break.a.bqn" Test ⟨"a","b"⟩‿⟨"10", "20"⟩                          # should print out argument variables in break point position
"cases/break.a.bqn" Test ⟨"𝕩"⟩‿⟨"20"⟩                          # should print out argument variables in break point position
#"cases/error.a.bqn" Test ⟨"a"⟩‿⟨"⟨ 0 1 2 ⟩"⟩                             # should print out assigned variables
#"cases/error.c.bqn" Test ⟨"a","𝕨", "b", "𝕩"⟩‿⟨"111", "111","555","555"⟩  # should print out argument variables in function

•Out "ok ✓"
