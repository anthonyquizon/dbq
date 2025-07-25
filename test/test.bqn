in‿outb←⟨⟩‿⟨⟩

# TODO escape escape so that its visible in buffer
#⟨Import,Repl⟩←{
  #Out     ⇐{outb∾⟜𝕩↩}
  #Show    ⇐{outb∾⟜(•Fmt𝕩)↩}
  #CharB   ⇐{𝕊:t←⊑1↑in⋄in↩1↓in⋄t}
  #OutRaw  ⇐{outb∾⟜𝕩↩}
  #RawMode ⇐{𝕩}
  #Flush   ⇐{𝕩}
#} •Import "../src/e.bqn"

⟨Import,Repl⟩←{
  Out     ⇐•Out
  Show    ⇐•Show
  CharB   ⇐{𝕊:t←⊑1↑in⋄in↩1↓in⋄t}
  OutRaw  ⇐•term.OutRaw∘•ToUTF8
  RawMode ⇐•term.RawMode
  Flush   ⇐•term.Flush
} •Import "../src/e.bqn"

#⟨Import,Repl⟩←{
  #Out     ⇐•Out
  #Show    ⇐•Show
  #CharB   ⇐•term.CharB
  #OutRaw  ⇐•term.OutRaw∘•ToUTF8
  #RawMode ⇐•term.RawMode
  #Flush   ⇐•term.Flush
#} •Import "../src/e.bqn"

in↩"a"∾(@+10)∾@+3
Import •path∾'/'∾"src.a.bqn"

# TODO escape escape so that its visible in buffer
#•Out outb

