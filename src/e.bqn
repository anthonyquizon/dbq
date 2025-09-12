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

imports←•HashMap˜⟨⟩ 

instr ← (⊏/¨1⊸↓)'0'-˜⟨ # For each instruction, number of:
  "11411311121111111315114131131111=111"  # Codes until next opcode
  "111000111100000000002221100000000111"  # Arguments
  "000111////23232303230000011022232111"  # Stack values consumed
  "111000111111111101111111101101111111"  # Stack values output
  "000000000011111101010000000000010000"  # Position determiner
⟩


dbg_ops←⟨
  16,17,20,21,26,27,   # Application
  18,19,23,22          # Application with Nothing
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
    "term"‿•term
    "wdpath"‿•wdpath
    "currenterror"‿•CurrentError
    "hashmap"‿•HashMap
    "toutf8"‿•ToUTF8
    "ns"  ‿•ns
    "show"‿•Show
    "bqn"‿•Bqn
    "fmt"‿•Fmt
    "makerand"‿•MakeRand
    "primitives"‿•Primitives
    "repr"‿•Repr
    "type"‿•Type
⟩

# find system function
System ←{
  F ← {
    i ← 𝕨⊐𝕩
    {!∾⟨"Unknown system value",(1≠≠𝕩)/"s",":"⟩∾" •"⊸∾¨𝕩}∘/⟜𝕩⍟(∨´) i=≠𝕨 
    i
  }
  {𝕨⊸F⊏𝕩˙}´∾<˘⋈˘⍉>syslist∾⟨"import"‿Import, "args"‿𝕩⟩
}

PrintStackTrace←{𝕊:
  {𝕊 f‿pos : 
    𝕩
    ⟨line, cols, src, cm⟩←imports.Get f ⋄ ·‿·‿·‿·‿loc‿·←cm
    sl←(lf⊸≠)⊸/¨src⊔˜»line
    o←|-´(pos-1)⊑¨loc     # offset 
    c←cols⊑˜⊑(pos-1)⊑¨loc # column
    l←1+line⊑˜pos⊑⊑loc    # line

    ##-- cbqn like stack trace --
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l⟩
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",(l-1)⊑sl⟩
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨dbg.s
}

# shows compiler errors
_CmpCatch←{ f Exit _𝕣 src:
  l←+`src=lf ⋄ sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                  # l: line numbers, sl: source file in lines

  { 𝕊 loc‿msg:
      s‿e←loc↩⥊loc
      io.term.OutRaw •ToUTF8 lf∾˜"Error: "∾msg
      io.term.OutRaw •ToUTF8 lf∾˜(s⊑l)⊑sl
      io.term.OutRaw •ToUTF8 lf∾˜⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  ; 𝕊 𝕩: 
      io.term.OutRaw •ToUTF8 lf∾˜"Error: "∾(•Fmt 𝕩)
      PrintStackTrace @
  }•CurrentError@
  Exit 1
}

VMCatch⇐{𝕊 ·:
  io.term.OutRaw •ToUTF8 lf∾˜∾⟨boldRed,"Error: ", •CurrentError@, reset⟩
  PrintStackTrace @
}

_PreHook←{vmap _𝕣 pos‿file: 
  ⟨cm,src,cols,line,break⟩←imports.Get file ⋄ bc‿·‿·‿·‿loc‿·←cm

  {𝕊: 
    i←pos⊑⊑loc ⋄ o←|-´pos⊑¨loc ⋄ c←i⊑cols ⋄ l←i⊑line ⋄ ln←l⊑line⊔src # i: position from bc to src. o: offset between start and end postions. c: current column number. l: current line number. ln: current line as string
    h‿m‿t←3↑ln⊔˜+`((1+o+c)⊸=∨c⊸=)↕≠ln # h: head, m: middle, t: tail
    io.term.OutRaw •ToUTF8     ∾⟨magenta,file/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷file,':',•Fmt l,reset⟩ # TODO move this to repl?
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",h(⊣/˜≠)lf,magenta,m,reset,t⟩
    Repl vmap
  }⍟⊣ flag_step∨∨´pos⍷break

  {𝕊: dbg.Push ⟨file,pos⟩}⍟⊣ (pos⊑bc)⍷dbg_ops
}

_PostHook←{· _𝕣 pos‿file: 
  ⟨cm⟩←imports.Get file ⋄ bc‿·‿·‿·‿·‿·←cm
  {𝕊: dbg.Pop 1}⍟⊣ (pos⊑bc)⍷dbg_ops
}

# Hooks to run in VM
hooks←{
  _Pre  ⇐ _PreHook
  _Post ⇐ _PostHook
  _Err  ⇐ {vmap _𝕣 ·: VMCatch@ ⋄ Repl vmap}
}

# Wrap namespace to vm compatable namespace 
Import ← {
    𝕊 𝕩     : ⟨⟩ 𝕊 𝕩
; 𝕨 𝕊 ⟨file⇐file⟩ : imports.Has file ? (imports.Get file).Get @
; 𝕨 𝕊 ⟨file⇐file⟩ : 

    h←'#' # avoid breaking vims syntax highlighting
    s←•file.Chars file 
    cm ← (⟨1⊸⊑¨•primitives, System 𝕨, ⟨⟩⟩⊸Compile)⎊(file⊸(•Exit _CmpCatch)) s
    bc‿·‿·‿·‿loc‿·←cm ⋄ i‿·←loc # i: index of start position of bytecodes
    ba‿·‿·‿·←instr

    m ← { # Mask of instruction starts
      n ← (↕≠bc)+1+ba(⊣⊏˜≠⊸>×⊢)bc
      Se←≠(>/⊢)∾⟜≠{(⊏˜𝕨)𝕊⍟(≠○(¯1⊸⊑))𝕩∾𝕩⊏𝕨}⟨0⟩˙
      (≠↑·/⁼Se) n
    }

    # construct break points
    l←+`s=lf                           # lines TODO remove newline chars?
    g←l⊔s                             
    q←{2⊑3↑𝕩⊔˜+`(=⟜h∨(≠∘⊢↑"??"⊸⍷))𝕩}¨g # 
    q↩∾g{(≠𝕨)↑(0≠≠𝕩)×(Trim 2↓𝕩)⍷𝕨}¨q
    q↩(i⊏q)∧6≠m×bc                # separate by pop instructions (6) and filter out only valid bytecode types
    q↩1↓(↕≠q)⊔˜(0=⊒i)×q×m×+`»⊸<q # group instruction sets and dedup same instructions on same line
    q↩⊑¨q/˜(0≠≠)¨q # break only on first match in group (ie. take first of break group)

    # Saved data for imports
    ns←{
      line  ⇐ l         # line numbers
      cols  ⇐ ∾(↕≠)¨⊔˜l # column numbers
      break ⇐ q         # break point bytecode mask - accessed by pos
      cm    ⇐ cm        # compilation result
      src   ⇐ s         # raw source code (helps for debugging)

      Get    ⇐ !∘"Import result referenced before completion"
      SetRet ⇐ {𝕊 v: Get↩{𝕊:v}}
    }

    ctx.Push file
    file imports.Set ns
    ns.SetRet ret←hooks‿{Has⇐0˙}‿file vm.Eval cm
    ctx.Pop 1 
    ret
; 𝕨 𝕊 𝕩 :  # canonicalize filename
    file←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    file↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent ctx.Peek @     # resolve relative file location
    𝕨 𝕊 {file⇐file}
}

Run ⇐ {
  Import 𝕩
  io.term.OutRaw •ToUTF8 lf∾˜"Done"
}

# f: lazy function to construct hashmap of variables
Repl⇐{𝕊 vmap:
  io.term.RawMode 1
  io.term.OutRaw •ToUTF8 prompt
  io.term.Flush@

  vmap↩Vmap @ ⋄ ch←⟨⟩ ⋄ ps←0 # vmap: variable mappings. ch: character buffer. ps: cursor offset
  hooks←{_Pre⇐_Post⇐{_𝕣:@}⋄Err⇐VMCatch}
  flag_step↩0

  Cmd←{
    ch 𝕊·: ""≡Trim ch? # ignore empty statements
      io.term.OutRaw •ToUTF8 lf∾˜prompt
      1  
  ; ch 𝕊·:
      io.term.OutRaw clear
      io.term.OutRaw •ToUTF8 lf∾˜prompt∾ch
      in←"x__arg‿w__arg←•args ⋄ w__arg {𝕊:"∾ch∾"} x__arg" # HACK: wrap in function via string manipulation to expose 𝕊 𝕨 𝕩 variables 
      cm ← (⟨1⊸⊑¨•primitives, System vmap.Get¨"𝕩𝕨", vmap.Keys@⟩⊸Compile)⎊(""⊸({𝕊:@}_CmpCatch)) in
      {@:1; io.Out hooks‿vmap‿@ vm.Eval 𝕩} cm
      1
  }

  Continue←{𝕊:io.term.OutRaw lf∾˜"Continue"⋄flag_step↩0⋄0}
  Next    ←{𝕊:flag_step↩1⋄0} 

  Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} # add 𝕩 into ch at ps position with 𝕨 deletions

  # Tip: use `cat -v` in the terminal to find out key codes
  Map←{ # map of inputs to ⟨ch, ps, eff⟩. ch: new character list, ps: position, eff: side effect function⟩ 
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,            0⌈ps-1,          1          ⟩ # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,            (≠ch)⌊ps+1,      1          ⟩ # arrow right
  ; 𝕩:𝕩≡e∾"[46;5u"         ? ⟨⟨⟩,            0,               Next       ⟩ # ctrl+; next bytecode
  ; 𝕩:𝕩≡e∾"[109;5u"        ? ⟨⟨⟩,            0,               1          ⟩ # 
  ; 𝕩:𝕩≡e∾"[27;5;13~"        ? ⟨⟨⟩,           0,              Continue   ⟩ # ctrl+enter
  ; 𝕩:𝕩≡≍@+10              ? ⟨⟨⟩,            0,               ch⊸Cmd     ⟩ # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "",    0⌈ps-1,          1          ⟩ # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,            0,               1          ⟩ # ctrl+u
  ; 𝕩:𝕩≡≍@+3               ? ⟨⟨⟩,            0,               {𝕊:•Exit 0}⟩ # ctrl+c
  ; 𝕩:0=≠ch                ? ⟨𝕩,             1,               1          ⟩
  # TODO add command
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1,       1          ⟩ # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,            1          ⟩ 
  }

  # if e consume chars until letter (ANSI format parsing)
  Input←{
     𝕊@:𝕊io.In@
  ;  𝕊𝕩:𝕩=e?𝕩∾e𝕊io.In@ 
  ;  𝕊𝕩:⟨𝕩⟩
  ; e𝕊𝕩:⊑𝕩∊∾'~'∾+⟜(↕26)¨"Aa"?𝕩
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
