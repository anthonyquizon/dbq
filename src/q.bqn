⟨Import,Repl⟩←{
  Out ⇐•Out
  In  ⇐•term.CharB
} •Import "./e.bqn"

usage←∾∾⟜(@+10)¨⟨
  "Usage: vbqn [options] [file.bqn [arguments]]"
⟩

{𝕊:•Out usage⋄•Exit 0}⍟(0⊸=)≠•args 
Import •wdpath∾'/'∾⊑•args
