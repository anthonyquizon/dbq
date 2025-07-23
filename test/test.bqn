in‿out←⟨⟩‿⟨⟩
⟨Import,Repl⟩←{
  Out     ⇐{out∾⟜𝕩↩}
  Show    ⇐{out∾⟜𝕩↩}
  CharB   ⇐{𝕊:⊑in  }
  OutRaw  ⇐{out∾⟜𝕩↩}
  RawMode ⇐{𝕩}
  Flush   ⇐{𝕩}
} •Import "../src/e.bqn"

Import •wdpath∾'/'∾"src.a.bqn"
