lf←@+10 # line feed
cl←@+3  # ctrl+c
e←@+27 

Test←{ f 𝕊 in‿exp:
  res←⟨⟩ 

  ⟨Import⟩←{
    Out     ⇐•Out
    Show    ⇐•Show
    Result  ⇐{•Show𝕩⋄res∾⟜⟨•Fmt𝕩⟩↩}
    term⇐{
      CharB   ⇐{𝕊:t←⊑1↑in⋄in↩1↓in⋄t}
      OutRaw  ⇐•term.OutRaw
      RawMode ⇐•term.RawMode
      Flush   ⇐•term.Flush
    }
  } •Import "../src/e.bqn"

  Import •path∾'/'∾f

  •term.Flush@ 
  •term.RawMode 0

  ! res≡exp
}

"ex.a.bqn" Test ⟨'a',lf,cl⟩‿⟨"⟨ 0 1 2 ⟩"⟩

