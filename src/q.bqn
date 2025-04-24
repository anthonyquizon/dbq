gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"
vm      ←    •Import "vm.bqn"

fnc←0 # flag no colour

ctx←@ ⋄ dbg←@
infm←⟨⟩ •HashMap ⟨⟩
resm←⟨⟩ •HashMap ⟨⟩
lf←@+10

MakeStack ⇐ {
  s ⇐ 𝕩
  Push ⇐ {𝕊: s∾↩<𝕩}
  Peek ⇐ {𝕊: 0=≠s ? ⟨⟩;¯1⊑s}                 # Return but don't pop top value
  Pop  ⇐ {t←-𝕩 ⋄ (s↓˜↩t) ⊢ ⌽t↑s}             # Pop 𝕩 values; return as list
}

CmpCatch←{ 𝕊 src:
  f←ctx.Peek@⋄⟨loc,msg⟩←•CurrentError@⋄s‿e←loc↩⥊loc
  in←infm.Get f
  •Out "Error: "∾msg
  •Out f∾":"∾ •Fmt s⊑in.n
  •Out (s⊑in.n)⊑in.l
  •Out ⊣◶" ∧"¨«((↕≠src)/˜∨´in.n⊸=¨loc⊏in.n)∊s+↕1+e-s
  •Exit 1
}

sysfile⇐{
  Lines⇐{ 
    𝕩 : "/"≤○≠◶0‿(⊣≡≠⊸↑)𝕩 ? •file.Lines 𝕩 
  ; 𝕩 : •file.Lines ∾⟜𝕩 •file.Parent ctx.Peek @ ⋄ 
  } 
  List ⇐{ •file.List ∾⟜𝕩 •file.Parent ctx.Peek @ } 
}

syslist←⟨
    "p"‿•Show # TODO show file and line number
    "while"‿•_while_
    "hash"‿•Hash
    "parsefloat"‿•ParseFloat
    "ffi"‿•FFI
    "out"‿•Out
    "exit"‿•Exit
    "file"‿sysfile
    "flines"‿sysfile.Lines
    "math"‿•math
    "ns"  ‿•ns
    "show"‿•Show
    "bqn"‿•Bqn
    "repr"‿•Repr
    "type"‿•Type
⟩

System ←{ 𝕊 args:
  F ← {                                                                                 # find system function
    i ← 𝕨⊐𝕩 ⋄ { ! ∾⟨"Unknown system value",(1≠≠𝕩)/"s",":"⟩∾" •"⊸∾¨𝕩 }∘/⟜𝕩⍟(∨´) i=≠𝕨 ⋄ i
  }
  { 𝕨⊸F⊏𝕩˙ }´∾<˘⋈˘⍉>syslist∾⟨ "import"‿Import, "args"‿𝕩 ⟩
}

Info←{ 
  f ⇐ 𝕩⋄("Missing file "∾f)!•file.Exists f # filename
  s ⇐ •file.Chars f                        # source files in chars
  l ⇐ (lf⊸≠)⊸/¨s⊔˜»+`lf=s                  # source file in lines
  n ⇐ +`s=lf                               # line numbers
  c ⇐ ∾(↕≠)¨⊔˜+`s=@+10                     # column numbers
  m ⇐ ≠/˜⌽0<+`⌽¬(0⊸=≠¨l)∨∧´¨' '⊸=¨l        # maximum line number TODO delete - instead snap to nearest line above
}

Import ⇐ {
    𝕊 𝕩 : ⟨⟩ 𝕊 𝕩
; · 𝕊 𝕩 : resm.Has 𝕩 ? resm.Get 𝕩
; args 𝕊 𝕩 : 
    f←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    f↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent ctx.Peek @
    ctx.Push f
    f infm.Set in←Info f
    # TODO precompile
    r ← VM (⟨1⊸⊑¨•primitives, System args, ⟨⟩⟩⊸Compile)⎊CmpCatch in.s
    f resm.Set r
    ctx.Pop 1 
    r
}

usage←∾∾⟜lf¨⟨
  "Usage: vbqn [options] [file.bqn [arguments]]"
⟩

{
  ctx↩MakeStack ⟨⟩
  dbg↩MakeStack ⟨⟩

  {𝕊:•Out usage⋄•Exit 0}⍟(0⊸=)≠•args 

  Import •wdpath∾'/'∾⊑•args
}

