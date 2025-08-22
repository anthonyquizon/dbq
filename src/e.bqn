# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
gl      ←    •Import "glyphs.bqn"
compile ← gl •Import "c.bqn"
vm      ←    •Import "vm.bqn"

io←•args

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"
boldCyan←e∾"[1;36m"
red     ←e∾"[31m"
magenta ←e∾"[35m"
boldRed ←e∾"[1;31m"
reset   ←e∾"[0m"

flag_step←0

prompt←"    "

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>? "
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐‿"

imports←⟨⟩ •HashMap ⟨⟩ 

# opt codes to break for
hook_ops←⟨
  16,17,20,21,26,27,   # Application
  18,19,23,22          # Application with Nothing
  47,48,49,50,51       # Assignment
⟩

Trim←((∨`∧∨⟜«)' '⊸≠)⊸/

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
  io.term.OutRaw lf∾˜"Error: "∾msg
  #io.term.OutRaw lf∾˜f∾":"∾ •Fmt s⊑sl
  io.term.OutRaw lf∾˜(s⊑l)⊑sl
  io.term.OutRaw lf∾˜⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  Exit 1
}

VMCatch⇐{𝕊 ·:
  io.term.OutRaw •ToUTF8 lf∾˜∾⟨boldRed,"Error: ", •CurrentError@, reset⟩
  {𝕊 f‿pos : 
    𝕩
    ⟨line, cm⟩←imports.Get f ⋄ ·‿·‿·‿·‿loc‿·←cm
    #c←∾(↕≠)¨⊔˜+`s=@+10 ⋄ l←+`s=lf ⋄ sl←(lf⊸≠)⊸/¨s⊔˜»+`lf=s 
    #o←|-´(pos-1)⊑¨loc     # offset 
    #c↩c⊑˜⊑(pos-1)⊑¨loc # column
    #l↩1+l⊑˜pos⊑⊑loc       # line

    #ln←(l-1)⊑sl
    #h‿m‿t←3↑ln⊔˜+`((1+o+c)⊸=∨c⊸=)↕≠ln
    #•Out ∾⟨magenta,f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l,reset⟩
    #•Out ∾⟨"  ",h,boldRed,m,reset,t⟩

    ##-- cbqn like stack trace --
    #io.term.OutRaw lf∾˜∾⟨f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l⟩
    #io.term.OutRaw lf∾˜∾⟨"  ",(l-1)⊑sl⟩
    #io.term.OutRaw lf∾˜∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨dbg.s
}

_PreHook←{f _𝕣 pos: 
  ⟨cm,src,cols,line,break⟩←imports.Get file←ctx.Peek @ ⋄ bc‿·‿·‿·‿loc‿·←cm

  {𝕊: 
    sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src
    o←|-´pos⊑¨loc     # offset 
    c←cols⊑˜⊑pos⊑¨loc # column
    l←1+line⊑˜pos⊑⊑loc       # line

    # TODO highlight line
    # TODO print previous and next lines

    ln←(l-1)⊑sl
    h‿m‿t←3↑ln⊔˜+`((1+o+c)⊸=∨c⊸=)↕≠ln
    io.term.OutRaw •ToUTF8     ∾⟨magenta,file/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷file,':',•Fmt l,reset⟩
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",h,magenta,m,reset,t⟩

    Repl f
  }⍟⊣ flag_step∨∨´pos⍷break

  dbg.Push ⟨file,pos⟩ 
}

# Hooks to run in VM
hooks←{
  _Pre⇐_PreHook
  Err⇐{VMCatch 𝕩 ⋄ Repl 𝕩 }
}

# Wrap namespace to vm compatable namespace 
Import ← {
    𝕊 𝕩     : ⟨⟩ 𝕊 𝕩
; 𝕨 𝕊 ⟨f⇐f⟩ : imports.Has f ? (imports.Get f).Get @
; 𝕨 𝕊 ⟨f⇐f⟩ : 
    s←•file.Chars f 
    cm ← (⟨1⊸⊑¨•primitives, System 𝕨, ⟨⟩⟩⊸Compile)⎊(f⊸(•Exit _CmpCatch)) s
    bc‿·‿·‿·‿loc‿·←cm ⋄ i‿·←loc # i: index of start position of bytecodes

    # construct break points
    l←+`s=lf                    # lines
    m←bc∊hook_ops               # mask of valid break positions
    bp←/(∨´"??"⊸⍷)¨s⊔˜+`s=lf    # find lines with break point marks
    bp↩bp∊˜i⊏l                  # map to bytecode positions
    bp↩bp∧(bc≠6)                # separate by pop instructions (6)
    bp↩1↓(↕≠bc)⊔˜m∧bp×+`»⊸<bp   # break point index groups
    bp↩⊑¨bp/˜(0≠≠)¨bp

    # Saved data for imports
    ns←{
      line  ⇐ l                 # delete?
      cols  ⇐ ∾(↕≠)¨⊔˜+`s=@+10  # delete?
      break ⇐ bp                # break point bytecode mask - accessed by pos
      cm    ⇐ cm                # compilation result
      src   ⇐ s                 # raw source code (helps for debugging)

      Get    ⇐ !∘"Import result referenced before completion"
      SetRet ⇐ {𝕊 v: Get↩{𝕊:v}}
    }

    ctx.Push f
    f imports.Set ns
    ns.SetRet ret←hooks‿{Has⇐0˙} vm.Eval cm
    ctx.Pop 1 
    ret
; 𝕨 𝕊 𝕩 :  # canonicalize filename
    f←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    f↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent ctx.Peek @     # resolve relative file location
    𝕨 𝕊 {f⇐f}
}

Run ⇐ {
  Import 𝕩
  io.term.OutRaw •ToUTF8 lf∾˜"Done"
}

# f: lazy function to construct hashmap of variables
Repl⇐{𝕊 f:
  io.term.RawMode 1
  io.term.OutRaw •ToUTF8 prompt
  io.term.Flush@

  vmap←F @ ⋄ ch←⟨⟩ ⋄ ps←0 # vmap: variable mappings. ch: character buffer. ps: cursor offset
  hooks←{_Pre⇐{_𝕣:@}⋄Err⇐VMCatch}
  flag_step↩0

  Cmd←{
    ch 𝕊·: ""≡Trim ch? # ignore empty statements
      io.term.OutRaw •ToUTF8 lf∾˜prompt
      1  
  ; ch 𝕊·:
      io.term.OutRaw clear
      io.term.OutRaw •ToUTF8 lf∾˜prompt∾ch
      in←"x‿w←•args ⋄ w {𝕊:"∾ch∾"} x" # HACK: wrap in function via string manipulation to expose 𝕊 𝕨 𝕩 variables
      cm ← (⟨1⊸⊑¨•primitives, System vmap.Get¨"𝕩𝕨", vmap.Keys@⟩⊸Compile)⎊(""⊸({𝕊:@}_CmpCatch)) in
      {@:1; io.Out hooks‿vmap vm.Eval 𝕩} cm
      1
  }

  Continue←{𝕊:io.term.OutRaw lf∾˜"Continue"⋄flag_step↩0⋄0}
  Next    ←{𝕊:flag_step↩1⋄0} 

  Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} # add 𝕩 into ch at ps position with 𝕨 deletions

  # Tip: use `cat -v` in the terminal to find out key codes
  Map←{ # map of inputs to ⟨ch, ps, eff⟩. ch: new character list, ps: position, eff: side effect function⟩ 
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,            0⌈ps-1,          1          ⟩ # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,            (≠ch)⌊ps+1,      1          ⟩ # arrow right
  ; 𝕩:𝕩≡e∾"[44;5u"         ? ⟨⟨⟩,            0,               Continue   ⟩ # ctrl+. continue
  ; 𝕩:𝕩≡e∾"[46;5u"         ? ⟨⟨⟩,            0,               Next       ⟩ # ctrl+; next bytecode
  ; 𝕩:𝕩≡≍@+10              ? ⟨⟨⟩,            0,               ch⊸Cmd     ⟩ # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "",    0⌈ps-1,          1          ⟩ # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,            0,               1          ⟩ # ctrl+u
  ; 𝕩:𝕩≡≍@+3               ? ⟨⟨⟩,            0,               {𝕊:•Exit 0}⟩ # ctrl+c
  ; 𝕩:0=≠ch                ? ⟨𝕩,             1,               1          ⟩
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1,       1          ⟩ # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,            1          ⟩ 
  }

  # if e consume chars until letter (ANSI format for keypimportsses)
  Input←{
     𝕊@:𝕊io.In@
  ;  𝕊𝕩:𝕩=e?𝕩∾e𝕊io.In@ 
  ;  𝕊𝕩:⟨𝕩⟩
  ; e𝕊𝕩:⊑𝕩∊∾+⟜(↕26)¨"Aa"?𝕩
  ; e𝕊𝕩:𝕩∾e𝕊io.In@
  }

  {𝕊:
    eff←@⋄ch‿ps‿Eff↩Map Input@
    ret←Eff @

    io.term.OutRaw clear # clear line and set to start of line
    io.term.OutRaw •ToUTF8 prompt
    io.term.OutRaw •ToUTF8 ch
    io.term.OutRaw e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
    io.term.Flush@
    ret
  }•_while_ ⊢ 1

  io.term.OutRaw •ToUTF8 lf∾˜""
}
