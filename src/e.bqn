# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"
vm      ←    •Import "vm.bqn"

io←{⟨Out,Show,CharB,RawMode,OutRaw,Flush⟩⇐•args}

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>?"
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐"

imports←⟨⟩ •HashMap ⟨⟩ 

ctx‿dbg ← {
  s    ⇐ 𝕩
  Push ⇐ {𝕊:s∾↩<𝕩}
  Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}                 # Return but don't pop top value
  Pop  ⇐ {t←-𝕩⋄(s↓˜↩t) ⊢ ⌽t↑s}            # Pop 𝕩 values; return as list
}¨⟨{f⇐""}⟩‿⟨⟩

# show compiler errors
CmpCatch←{ f‿l 𝕊 src:
  sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                  # source file in lines
  ⟨loc,msg⟩←•CurrentError@⋄s‿e←loc↩⥊loc
  io.Out "Error: "∾msg
  io.Out f∾":"∾ •Fmt s⊑sl
  io.Out (s⊑l)⊑sl
  io.Out ⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  # TODO run repl
  •Exit 1
}

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

Import ⇐ {
    𝕊 𝕩 : ⟨⟩ 𝕊 𝕩
; · 𝕊 𝕩 : imports.Has 𝕩 ? imports.Get 𝕩
; args 𝕊 𝕩 : 
    ⟨p⇐f⟩←ctx.Peek @
    f←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    f↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent p     # resolve relative file location
    s←•file.Chars f ⋄ c←∾(↕≠)¨⊔˜+`s=@+10 ⋄ l←+`s=lf #s: src, f: file, c: columns, l: lines
    ctx.Push {f⇐f⋄c⇐c⋄l⇐l} 
      bc ← (⟨1⊸⊑¨•primitives, System args, ⟨⟩⟩⊸Compile)⎊(f‿l⊸CmpCatch) s
      f imports.Set r←VM bc
    ctx.Pop 1 
    r
}

Repl⇐{𝕊 opt:
  io.RawMode 1
  io.OutRaw opt.prompt

  # ch: character buffer. ps: cursor offset
  ch←⟨⟩ ⋄ ps←0 

  Cmd←{ch𝕊·:io.OutRaw clear⋄opt.Cmd ch}

  # add 𝕩 into ch at ps position with 𝕨 deletions
  Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} 

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
