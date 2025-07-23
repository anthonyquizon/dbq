in‿out←⟨⟩‿⟨⟩
#⟨Import,Repl⟩←{
  #Out     ⇐{out∾⟜𝕩↩}
  #Show    ⇐{out∾⟜𝕩↩}
  #CharB   ⇐{𝕊:⊑in  }
  #OutRaw  ⇐{out∾⟜𝕩↩}
  #RawMode ⇐{𝕩}
  #Flush   ⇐{𝕩}
#} •Import "../src/e.bqn"

⟨Import,Repl⟩←{
  Out     ⇐•Out
  Show    ⇐•Show
  CharB   ⇐•term.CharB
  OutRaw  ⇐•term.OutRaw∘•ToUTF8
  RawMode ⇐•term.RawMode
  Flush   ⇐•term.Flush
} •Import "../src/e.bqn"

Import •path∾'/'∾"src.a.bqn"

