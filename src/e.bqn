# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"
vm      ←    •Import "vm.bqn"

io←{⟨Out,Show,Result,term⟩⇐•args ⋄ file⇐•file}

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"
boldCyan←e∾"[1;36m"
red     ←e∾"[31m"
magenta ←e∾"[35m"
boldRed ←e∾"[1;31m"
reset   ←e∾"[0m"

prompt←"    "

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>? "
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐‿"

# imports: filename→⟨result, source code⟩
imports←⟨⟩ •HashMap ⟨⟩ 

ctx‿dbg ← {𝕊:{
  s    ⇐ ⟨⟩
  Push ⇐ {𝕊:s∾↩<𝕩}
  Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}               # Return but don't pop top value
  Pop  ⇐ {t←-𝕩⋄(s↓˜↩t)⊢⌽t↑s}            # Pop 𝕩 values; return as list
}}¨↕2

sysfile←{
  Lines⇐{ 
    𝕩 : "/"≤○≠◶0‿(⊣≡≠⊸↑)𝕩 ? •file.Lines 𝕩 
  ; 𝕩 : •file.Lines ∾⟜𝕩 •file.Parent ctx.Peek @ ⋄ 
  } 
  List ⇐{ •file.List ∾⟜𝕩 •file.Parent ctx.Peek @ } 
}

syslist←⟨
    "while"‿•_while_
    "hash"‿•Hash
    "parsefloat"‿•ParseFloat
    "ffi"‿•FFI
    "out"‿io.Out
    "exit"‿•Exit
    "file"‿sysfile
    "flines"‿sysfile.Lines
    "math"‿•math
    "ns"  ‿•ns
    "show"‿io.Show
    "bqn"‿•Bqn
    "repr"‿•Repr
    "type"‿•Type
⟩

System ←{
  F ← {                                                                                 # find system function
    i ← 𝕨⊐𝕩 ⋄ {!∾⟨"Unknown system value",(1≠≠𝕩)/"s",":"⟩∾" •"⊸∾¨𝕩}∘/⟜𝕩⍟(∨´) i=≠𝕨 ⋄ i
  }
  {𝕨⊸F⊏𝕩˙}´∾<˘⋈˘⍉>syslist∾⟨"import"‿Import, "args"‿𝕩⟩
}

# shows compiler errors
_CmpCatch←{ f Exit _𝕣 src:
  l←+`src=lf ⋄ sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                  # l: line numbers, sl: source file in lines
  ⟨loc,msg⟩←•CurrentError@⋄s‿e←loc↩⥊loc
  io.Out "Error: "∾msg
  io.Out f∾":"∾ •Fmt s⊑sl
  io.Out (s⊑l)⊑sl
  io.Out ⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  Exit 1
}

VMCatch⇐{𝕊 ·:
  io.Out ∾⟨boldRed,"Error: ", •CurrentError@, reset⟩
  {𝕊 f‿pos : 
    ⟨·,cm,s⟩←imports.Get f ⋄ ·‿·‿·‿·‿loc‿·←cm
    c←∾(↕≠)¨⊔˜+`s=@+10 ⋄ l←+`s=lf
    sl←(lf⊸≠)⊸/¨s⊔˜»+`lf=s 

    o←|-´(pos-1)⊑¨loc     # offset 
    c↩c⊑˜⊑(pos-1)⊑¨loc # column
    l↩1+l⊑˜pos⊑⊑loc       # line

    #ln←(l-1)⊑sl
    #h‿m‿t←3↑ln⊔˜+`((1+o+c)⊸=∨c⊸=)↕≠ln
    #io.Out ∾⟨magenta,f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l,reset⟩
    #io.Out ∾⟨"  ",h,boldRed,m,reset,t⟩

    #-- cbqn like stack trace --
    io.Out ∾⟨f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l⟩
    io.Out ∾⟨"  ",(l-1)⊑sl⟩
    io.Out ∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨dbg.s
}

# Hooks to run in VM
hooks←{
  Pre⇐{𝕊 pos: dbg.Push ⟨ctx.Peek @,pos⟩ }
  Post⇐{𝕩}
  Err⇐{VMCatch 𝕩 ⋄ Repl 𝕩 }
}

# Wrap namespace to vm compatable namespace 
Import ⇐ {
    𝕊 𝕩     : ⟨⟩ 𝕊 𝕩
; 𝕨 𝕊 ⟨f⇐f⟩ : imports.Has f ? 
    ≠⟜@◶⟨𝕨⊸𝕊⟜𝕩,⊢⟩ ⊑imports.Get f # if imports result is not realized
; 𝕨 𝕊 ⟨f⇐f⟩ : 
    s←io.file.Chars f 
    ctx.Push f
      cm ← (⟨1⊸⊑¨•primitives, System 𝕨, ⟨⟩⟩⊸Compile)⎊(f⊸(•Exit _CmpCatch)) s
      # TODO preparse break points via compiled bytecodes?
      f imports.Set ⟨@,cm,s⟩
      f imports.Set ⟨r←hooks‿{Has⇐0˙} vm.Eval cm,cm,s⟩
    ctx.Pop 1 
    r
; 𝕨 𝕊 𝕩 :  # canonicalize filename
    f←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    f↩𝕩∾˜(0⊸≢≠)◶""‿io.file.Parent ctx.Peek @     # resolve relative file location
    𝕨 𝕊 {f⇐f}
}

# f: lazy function to construct hashmap of variables
Repl⇐{𝕊 f:
  io.term.RawMode 1
  io.term.OutRaw prompt
  io.term.Flush@

  vmap←F @ ⋄ ch←⟨⟩ ⋄ ps←0 # vmap: variable mappings. ch: character buffer. ps: cursor offset
  Cmd←{ch𝕊·:
    io.term.OutRaw clear
    hooks←{Pre⇐Post⇐{𝕩}⋄Err⇐VMCatch}
    in←"x‿w←•args ⋄ w {𝕊:"∾ch∾"} x" # HACK: wrap in function via string manipulation to expose 𝕊 𝕨 𝕩 variables
    cm ← (⟨1⊸⊑¨•primitives, System vmap.Get¨"𝕩𝕨", vmap.Keys@⟩⊸Compile)⎊(""⊸({𝕊:@}_CmpCatch)) in
    {@:1; io.Result hooks‿vmap vm.Eval 𝕩} cm
    1
  }

  Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} # add 𝕩 into ch at ps position with 𝕨 deletions

  Map←{ # map of inputs to ⟨ch, ps, eff⟩. ch: new character list, ps: position, eff: side effect function⟩ 
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,            0⌈ps-1,          1   ⟩ # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,            (≠ch)⌊ps+1,      1   ⟩ # arrow right
  ; 𝕩:𝕩≡≍@+10              ? ⟨⟨⟩,            0,               ch⊸Cmd⟩ # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "",    0⌈ps-1,          1   ⟩ # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,            0,               1   ⟩ # ctrl+u
  ; 𝕩:𝕩≡≍@+3               ? ⟨⟨⟩,            0,               0   ⟩ # ctrl+c
  ; 𝕩:0=≠ch                ? ⟨𝕩,             1,               1   ⟩
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1,       1   ⟩ # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,            1   ⟩ 
  }

  # if e consume chars until letter (ANSI format for keypimportsses)
  Input←{
     𝕊@:𝕊io.term.CharB@
  ;  𝕊𝕩:𝕩=e?𝕩∾e𝕊io.term.CharB@ 
  ;  𝕊𝕩:⟨𝕩⟩
  ; e𝕊𝕩:⊑𝕩∊∾+⟜(↕26)¨"Aa"?𝕩
  ; e𝕊𝕩:𝕩∾e𝕊io.term.CharB@
  }

  {𝕊:
    eff←@⋄ch‿ps‿Eff↩Map Input@
    ret←Eff @

    io.term.OutRaw clear # clear line and set to start of line
    io.term.OutRaw prompt
    io.term.OutRaw ch
    io.term.OutRaw e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
    io.term.Flush@
    ret
  }•_while_ ⊢ 1
}
