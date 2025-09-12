lf←@+10 # line feed
e←@+27 
cont←e∾"[27;5;13~"  # ctrl+enter

term←{
  OutRaw  ⇐ {𝕩}
  Flush   ⇐ {𝕩}
  RawMode ⇐ {𝕩}
}

fltr←∾≠⊸↑•args

Test←{ 
  file 𝕊 inb‿exp: ∨´fltr⍷file ? 
    •Out "test "∾file

    inb↩∾(cont¨↕10)∾˜lf∾˜¨inb ⋄ outb←⟨⟩                                    # inb append with mulitple continues to eventually exit program without running ctrl+
    args←{
      Out  ⇐ {outb∾⟜⟨•Fmt𝕩⟩↩}
      In   ⇐ {𝕊:t←⊑1↑inb⋄inb↩1↓inb⋄t}
      term ⇐ term
    }
    ⟨Run⟩←args •Import "../src/e.bqn"
    Run •path∾'/'∾file

    ! outb≡exp
; ·𝕊· : @
}

## Breakpoint tests
"cases/break.a.bqn" Test ⟨"a","b"⟩‿⟨"10", "20"⟩                          # should print out argument variables in break point position
"cases/break.b.bqn" Test ⟨"𝕩"⟩‿⟨"20"⟩                                    # should print out argument variables in break point position
"cases/break.c.bqn" Test ⟨"𝕩"⟩‿⟨"20"⟩                                    # should print out argument variables in break point position

## Error tests
"cases/error.a.bqn" Test ⟨"a"⟩‿⟨"⟨ 0 1 2 ⟩"⟩                             # should print out assigned variables
"cases/error.b.bqn" Test ⟨"a","𝕨", "b", "𝕩"⟩‿⟨"111", "111","555","555"⟩  # should print out argument variables in function

•Out "ok ✓"
