lf←@+10 # line feed
cl←@+3  # ctrl+c
e←@+27 

Test←{ f 𝕊 inb‿exp:
  •Out "=== testing " ∾ f ∾ " ==="
  inb↩∾lf∾˜¨inb
  outb←⟨⟩

  ⟨Import⟩←{
    Out ⇐{•Show𝕩⋄outb∾⟜⟨•Fmt𝕩⟩↩}
    In  ⇐{𝕊:t←⊑1↑inb⋄inb↩1↓inb⋄t}
  } •Import "../src/e.bqn"

  Import •path∾'/'∾f

  •term.OutRaw ≍lf
  •term.Flush@ 
  •term.RawMode 0

  ! outb≡exp
  •Out "=== " ∾ f ∾ " ok ✓ ==="
}

"ex.a.bqn" Test ⟨"a",cl⟩‿⟨"⟨ 0 1 2 ⟩"⟩
"ex.c.bqn" Test ⟨"a","𝕨",cl⟩‿⟨"111", "111"⟩

