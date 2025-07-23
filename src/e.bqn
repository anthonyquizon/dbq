# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"
vm      ←    •Import "vm.bqn"

io←{⟨Out,Show,CharB,RawMode,OutRaw,Flush⟩⇐•args}

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"
boldCyan←e∾"[1;36m"
red     ←e∾"[31m"
magenta ←e∾"[35m"
boldRed ←e∾"[1;31m"
reset   ←e∾"[0m"

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>?"
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐"

# imports: filename→⟨result, source code⟩
imports←⟨⟩ •HashMap ⟨⟩ 

ctx‿dbg ← {𝕊:{
  s    ⇐ ⟨⟩
  Push ⇐ {𝕊:s∾↩<𝕩}
  Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}                 # Return but don't pop top value
  Pop  ⇐ {t←-𝕩⋄(s↓˜↩t) ⊢ ⌽t↑s}            # Pop 𝕩 values; return as list
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

System ←{ 𝕊 args:
  F ← {                                                                                 # find system function
    i ← 𝕨⊐𝕩 ⋄ {!∾⟨"Unknown system value",(1≠≠𝕩)/"s",":"⟩∾" •"⊸∾¨𝕩}∘/⟜𝕩⍟(∨´) i=≠𝕨 ⋄ i
  }
  {𝕨⊸F⊏𝕩˙}´∾<˘⋈˘⍉>syslist∾⟨"import"‿Import, "args"‿𝕩⟩
}

# shows compiler errors
CmpCatch←{ f 𝕊 src:
  l←+`src=lf ⋄ sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                  # l: line numbers, sl: source file in lines
  ⟨loc,msg⟩←•CurrentError@⋄s‿e←loc↩⥊loc
  io.Out "Error: "∾msg
  io.Out f∾":"∾ •Fmt s⊑sl
  io.Out (s⊑l)⊑sl
  io.Out ⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  •Exit 1
}

VMCatch⇐{ 𝕊:
  •Out ∾⟨boldRed,"Error: ", •CurrentError@, reset⟩

  {𝕊 f‿pos : 
    ⟨·,cm,s⟩←imports.Get f ⋄ ·‿·‿·‿·‿loc‿·←cm
    c←∾(↕≠)¨⊔˜+`s=@+10 ⋄ l←+`s=lf
    sl←(lf⊸≠)⊸/¨s⊔˜»+`lf=s

    o←|-´(pos-1)⊑¨loc     # offset
    c↩c⊑˜1-˜⊑(pos-1)⊑¨loc # column
    l↩1+l⊑˜pos⊑⊑loc       # line
    io.Out ∾⟨red, f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l, reset⟩
    io.Out ∾⟨"  ",(l-1)⊑sl⟩
    io.Out ∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨⌽dbg.s

  # TODO run repl
}

# Hooks to run in VM
hooks←{
  Pre⇐{𝕊 pos: dbg.Push ⟨ctx.Peek @,pos⟩ }
  Post⇐{𝕩}
  Err⇐VMCatch
}

Import ⇐ {
    𝕊 𝕩     : ⟨⟩ 𝕊 𝕩
; 𝕨 𝕊 ⟨f⇐f⟩ : imports.Has f ? 
    ≠⟜@◶⟨𝕨⊸𝕊⟜𝕩,⊢⟩ ⊑imports.Get f # if imports result is not realized
; 𝕨 𝕊 ⟨f⇐f⟩ : 
    s←•file.Chars f 
    ctx.Push f
      cm ← (⟨1⊸⊑¨•primitives, System 𝕨, ⟨⟩⟩⊸Compile)⎊(f⊸CmpCatch) s
      f imports.Set ⟨@,cm,s⟩
      f imports.Set ⟨r←hooks VM cm,cm,s⟩
    ctx.Pop 1 
    r
; 𝕨 𝕊 𝕩 :  # canonicalize filename
    f←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    f↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent ctx.Peek @     # resolve relative file location
    𝕨 𝕊 {f⇐f}
}

Repl⇐{𝕊 opt:
  io.RawMode 1
  io.OutRaw opt.prompt

  ch←⟨⟩ ⋄ ps←0 # ch: character buffer. ps: cursor offset
  Cmd←{ch𝕊·:io.OutRaw clear⋄opt.Cmd ch}
  Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} # add 𝕩 into ch at ps position with 𝕨 deletions

  # map of inputs to ⟨ch, ps, eff⟩ 
  # ch: new character list, ps: position, eff: side effect function⟩
  Map←{
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,            0⌈ps-1,          {𝕩}   ⟩ # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,            (≠ch)⌊ps+1,      {𝕩}   ⟩ # arrow right
  ; 𝕩:𝕩≡≍@+10              ? ⟨⟨⟩,            0,               ch⊸Cmd⟩ # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "",    0⌈ps-1,          {𝕩}   ⟩ # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,            0,               {𝕩}   ⟩ # ctrl+u
  ; 𝕩:0=≠ch                ? ⟨𝕩,             1,               {𝕩}   ⟩
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1,       {𝕩}   ⟩ # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,            {𝕩}   ⟩ 
  }

  # if e consume chars until letter (ANSI format for keypimportsses)
  Input←{
     𝕊@:𝕊io.CharB@
  ;  𝕊𝕩:𝕩=e?𝕩∾e𝕊io.CharB@
  ;  𝕊𝕩:⟨𝕩⟩
  ; e𝕊𝕩:⊑𝕩∊∾+⟜(↕26)¨"Aa"?𝕩
  ; e𝕊𝕩:𝕩∾e𝕊io.CharB@
  }

  {𝕊:
    eff←@⋄ch‿ps‿Eff↩Map Input@
    Eff @

    io.OutRaw clear # clear line and set to start of line
    io.OutRaw opt.prompt
    io.OutRaw ch
    io.OutRaw e∾"["∾(•Fmt (≠opt.prompt)+ps+1)∾"G"
    io.Flush@
  }•_while_ 1 @
}
