⟨Run,Repl⟩←{
  Out  ⇐ •Show
  In   ⇐ •term.CharB
  term ⇐ •term
} •Import "./e.bqn"

usage←∾∾⟜(@+10)¨⟨
  "Usage: vbqn [options] [file.bqn [arguments]]"
⟩

# TODO parse flags

{𝕊:•Out usage⋄•Exit 0}⍟(0⊸=)≠•args 
Run •wdpath∾'/'∾⊑•args
