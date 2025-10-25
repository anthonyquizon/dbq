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
    ⟨Run⟩←args •Import "../db.bqn"
    Run •path∾'/'∾file

    # TODO diff
    ! outb≡exp
; ·𝕊· : @
}

## Breakpoint tests
"cases/break.a.bqn" Test ⟨
  ⟨"a", "b", cont, "c"⟩
  ⟨"1", "2",       "3"      ⟩
⟩

"cases/break.b.bqn" Test ⟨
  ⟨"𝕩", "a", cont, "𝕩", "a"⟩ 
  ⟨"1", "2",     , "2", "3"      ⟩
⟩ 

## Error tests
"cases/error.a.bqn" Test ⟨
  ⟨"a"        ⟩
  ⟨"⟨ 0 1 2 ⟩"⟩
⟩
"cases/error.b.bqn" Test ⟨
  ⟨"a",     "𝕨",  "b",  "𝕩"⟩
  ⟨"111", "111","555","555"⟩
⟩

•Out "ok ✓"
