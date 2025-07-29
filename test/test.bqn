lf←@+10 # line feed
cl←@+3  # ctrl+c

Test←{ f 𝕊 in‿exp:
  outb←⟨⟩ # differentiate between Out function

  ⟨Import⟩←{
    Out     ⇐{•Out  𝕩⋄outb∾⟜⟨𝕩,    lf⟩↩}
    Show    ⇐{•Show 𝕩⋄outb∾⟜⟨•Fmt𝕩,lf⟩↩}
    term⇐{
      CharB   ⇐{𝕊:t←⊑1↑in⋄in↩1↓in⋄t}
      OutRaw  ⇐{•term.OutRaw𝕩⋄outb∾⟜𝕩↩}
      RawMode ⇐•term.RawMode
      Flush   ⇐•term.Flush
    }
  } •Import "../src/e.bqn"

  Import •path∾'/'∾f

  •term.Flush@ 
  •term.RawMode 0

  ! outb≡exp
}

"ex.a.bqn" Test ⟨'a',lf,cl⟩‿"⟨1 2 3⟩"

