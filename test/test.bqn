in‿outb←⟨⟩‿⟨⟩

lf←@+10
# TODO escape escape so that its visible in buffer
# print output but also accumulate output as well as autmatically send input 
⟨Import⟩←{
  Out     ⇐{•Out  𝕩⋄outb∾⟜⟨𝕩,    lf⟩↩}
  Show    ⇐{•Show 𝕩⋄outb∾⟜⟨•Fmt𝕩,lf⟩↩}
  term⇐{
    CharB   ⇐{𝕊:t←⊑1↑in⋄in↩1↓in⋄t}
    OutRaw  ⇐{•term.OutRaw𝕩⋄outb∾⟜𝕩↩}
    RawMode ⇐•term.RawMode
    Flush   ⇐•term.Flush
  }
  file⇐{
    Chars⇐{𝕩} # TODO
    Parent⇐{𝕊:""}
  }
} •Import "../src/e.bqn"

in↩"a"∾(@+10)∾@+3
#Import •path∾'/'∾"src.a.bqn"
Import •path∾'/'∾"src.c.bqn"
•term.Flush@ 
•term.RawMode 0

# TODO escape escape so that its visible in buffer
#•Out outb

