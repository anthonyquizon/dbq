
# picosat?
FFI←{"../extern/libpicosat.so" •FFI 𝕩}

none‿sat‿unsat←0‿10‿20

c_init     ← FFI "*"‿"picosat_init"
c_reset    ← FFI ""‿"picosat_reset"‿"*"
c_set_seed ← FFI ""‿"picosat_set_seed"‿"*"‿"i32"
c_print    ← FFI ""‿"picosat_print"‿"*"‿"*u32"
c_sat      ← FFI "i32"‿"picosat_sat"‿"*"‿"u32"
c_add      ← FFI "i32"‿"picosat_add"‿"*"‿"i32"
c_deref    ← FFI "i32"‿"picosat_deref"‿"*"‿"i32"

Init←{𝕊:
  p←C_init ⟨⟩

  Gen⇐{
    q←⍷∾|𝕩
    C_add¨p⊸∾⌜∾∾⟜0¨𝕩  
    C_sat p‿100
    ⍉q∾˘C_deref¨p⊸∾⌜q # return literals under variable index
  }

  # TODO add deref to new clause and regen

  End⇐{𝕊: C_reset⋈p }
}

#•Show "--"
#p←Init@
#•Show p.Gen ⟨ 1‿¯2, 1‿2, 9‿2, 7‿3 ⟩
#p.End@


•Show 1=100
#•Show ∨´(1=•Type)¨"woo"

# encode ∃∀x<≠x | xᵢ<x
#! ⟨r₁...⟩
#! ⟨x,n⟩|(xᵢ=xⱼ,i≠j) () → 
#Foo←{
  #𝕩: 𝕩⊏𝕩
#}



#C_add p‿1
#C_add p‿¯2
#C_add p‿0
#C_add p‿1
#C_add p‿2
#C_add p‿0
#•Show C_sat p‿100

#•SHow a← C_deref p‿2

#C_add p‿(a)
#C_add p‿0
#C_sat p‿100
#•SHow C_deref p‿2

##C_set_seed ⟨p, 100⟩

C←{
  𝕊  𝕩: 2=•Type𝕩
; 𝕊⁼ ⟨foo⇐foo⟩: foo
; 𝕊⁼ 𝕩: 111
}


r←•MakeRand 10

•Show 2=•Type¨⟨1,'c',3⟩
•Show ∨´2=•Type¨⟨1,'c',3⟩

•Show C⁼ {foo⇐2}
•Show C⁼ 111
•Show '0'+100 r.Range 100
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

# get domain with random distribution
# propagator D→⊆D
# a=b -> a-b→c, 0‿1‿1

_Gen←{ F _𝕣 𝕩:
  p←v←r.Deal ×´𝕩
  •SHow "--"
  •Show b←30 r.Range 2
  #•Show c←7≥30 r.Range 10
  #•Show d←6≥30 r.Range 10
  #•Show e←8≥30 r.Range 10
  #•SHow b×c
  #•SHow b×c×d
  #•SHow t←e/b×c×d
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
#F←{ 𝕩+1 }

#F _Gen 4‿3



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


