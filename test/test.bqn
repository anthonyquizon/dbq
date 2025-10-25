lf←@+10 # line feed
e←@+27 
cont←e∾"[27;5;13~"  # ctrl+enter

term←{
  OutRaw  ⇐ {𝕩}
  Flush   ⇐ {𝕩}
  RawMode ⇐ {𝕩}
}

# TODO flag for print all errors

fltr←∾≠⊸↑•args

Test←{ 
  file 𝕊 inb‿exp: ∨´fltr⍷file ? 
    •Out "test "∾file

    inb↩∾(cont¨↕10)∾˜lf∾˜¨inb ⋄ outb←⟨⟩                                    # inb append with mulitple continues to eventually exit program without running ctrl+
    # TODO expect done key sequence
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
# should print out argument variables in break point position where undefined variables print out @
"cases/break.a.bqn" Test ⟨
  ⟨"a", "b", cont, "a",  "b"⟩
  ⟨"@", "@",       "1",  "@"⟩
⟩

# should print out argument variables in break point position
"cases/break.b.bqn" Test ⟨
  ⟨"𝕩", "a",  cont, "𝕩", "a" ⟩ # TODO explicit done sequence
  ⟨"0", "10",     , "1", "10"⟩
⟩ 
"cases/break.c.bqn" Test ⟨
  ⟨"a", "b", "c"⟩
  ⟨"1", "@", "@"⟩
⟩
"cases/break.d.bqn" Test ⟨
  ⟨"A", cont, "𝕩"⟩
  ⟨"@",     , "10"⟩
⟩ # should print out argument variables in break point position

## Error tests
"cases/error.a.bqn" Test ⟨"a"⟩‿⟨"⟨ 0 1 2 ⟩"⟩                             # should print out assigned variables
"cases/error.b.bqn" Test ⟨"a","𝕨", "b", "𝕩"⟩‿⟨"111", "111","555","555"⟩  # should print out argument variables in function

# Print tests
"cases/print.a.bqn" Test ⟨⟩‿⟨"111", "111","555","555"⟩  

•Out "ok ✓"
