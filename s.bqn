
# picosat?

r←•MakeRand 10
#gr←2 ⋄ gl←1.5⋄ sr←1⋄ sl←0.9                     # sl: length shrink factor, gr: range factor, rs: shrink range factor, gl: length factor

# G: generator function
# F: function to test
# m: message
#_Gen_←{ G _𝕣_ F m:
  #p←@
  #j←10⋄v←@⋄rs←1⋄i←0 ⋄ t←⍉>⟨0∾gr⋆↕10, 0∾⌊gl⋆↕10⟩ # rs: result

  #{𝕊:                                           # grow
    #x‿y←i⊏t ⋄ i↩i+1 ⋄ l‿h←x×¯1‿1 ⋄ p↩v
    #(i<≠t)∧rs↩G F v↩l+y r.Range 1+h-l
  #} •_while_ (0⊸≢) @

  #{𝕊:                                           # shrink
    #v {𝕩↑˜⌊sl×≠𝕩}⍟(0.5<(r.Range 0)⋆1.2) ↩       # shrink length
    #v {(⊣-sr⊸×∘×)⌾((⊑⍒|𝕩)⊸⊏) 𝕩}⍟(0⊸≠≠) ↩        # shrink lagrest delta from 0
    #(j-⟜1↩)∧(1≡(G⟜F)⍟(≢⟜p) v)
  #} •_while_ {(0≢𝕩)∧¬rs} @

  #⊢◶⟨
    #{𝕊: •Out¨m‿"Counter example:"‿(•Fmt F p) }
    #{𝕊: •Out m∾": Ok" }
  #⟩ rs
#}

_Gen←{ F _𝕣 𝕩:
  p←v←r.Deal ×´𝕩
  •Show 10 r.Range 10
  #m←(10 r.Deal ×´𝕩)×(r.Deal<r.Deal) ×´𝕩
  #•SHow m
  #•Show 𝕩⥊v
  #•Show 𝕩⥊v+m

  #{𝕊:

    #⎊
  #} •_While_ ⊣ 1
}

Fmt←{c𝕊q:                                       # format string to replace ⌾X values 
  k←»z←c='⌾' ⋄ c‿k (¬z)⊸/˜¨↩                    # with empty strings as default value
  ∾(q((⟨""⟩∾˜1⊸⊏)∘⊣⊏˜⊏⊸⊐)k/c)⌾(k⊸/) c
}

#~ 𝕩:⟨4,3⟩ → ⟨4,3⟩ | 𝕩>0
F←{ 𝕩+1 }

F _Gen 4‿3

#prop⇐{
  #r←•MakeRand 10
  #gr←2 ⋄ gl←1.5⋄ sr←1⋄ sl←0.9 # sl: length shrink factor, gr: range factor, rs: shrink range factor, gl: length factor

#}

#c←"
##~ {a⇐,b⇐} → ⟨2,n⟩ | a:⟨1,4⟩ b:⟨4,n⟩
#Foo←{ 𝕩 }
#"

#d←"
##~ {a:⟨1,4⟩, b:[2,4,n]} 𝕊 ⟨a₁,a₂⟩ → ⟨a₁,n⟩ 
#Foo←{ 𝕩+2 }
#"

#e←"
## same shape
##~ ⟨2,3⟩ → ⟨2,3,4⟩
##~ ⟨2,3⟩ → ⟨x₁...xₙ⟩ 
#Foo←{ 𝕩+2 }
#"

#c←•FChars ⊑•args
#•Show •Import ⊑•args

# compile specs
# generate tests?
# generate and shrink inputs


