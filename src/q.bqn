⟨Import,Repl⟩←{
  Out    ⇐•Out
  Show   ⇐•Show
  Result ⇐•Show
  term⇐{
    CharB   ⇐•term.CharB
    OutRaw  ⇐•term.OutRaw∘•ToUTF8
    RawMode ⇐•term.RawMode
    Flush   ⇐•term.Flush
  }
} •Import "./e.bqn"

usage←∾∾⟜(@+10)¨⟨
  "Usage: vbqn [options] [file.bqn [arguments]]"
⟩

{𝕊:•Out usage⋄•Exit 0}⍟(0⊸=)≠•args 
Import •wdpath∾'/'∾⊑•args
