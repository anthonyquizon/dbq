# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
glyphs ← ⟨
  "+-×÷⋆√⌊⌈|¬∧∨<>≠=≤≥≡≢⊣⊢⥊∾≍⋈↑↓↕«»⌽⍉/⍋⍒⊏⊑⊐⊒∊⍷⊔!"
  "˙˜˘¨⌜⁼´˝`"
  "∘○⊸⟜⌾⊘◶⎉⚇⍟⎊"
⟩

compile ← glyphs •Import "c.bqn"
vm      ←        •Import "vm.bqn"

io←•args

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"
boldCyan‿red‿magenta‿boldRed‿reset←e⊸∾¨"[1;36m"‿"[31m"‿"[35m"‿"[1;31m"‿"[0m"

# flags
flg_brk←0
flg_shw←0
last_brk←@

prompt←"    "

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>? "
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐‿"

imports←•HashMap˜⟨⟩

dbg_ops←⟨
  16,17,20,21,26,27,                                                                                   # Application
  18,19,23,22                                                                                          # Application with Nothing
⟩
shw_ops←⟨47,48,49,50,51⟩

ctx‿dbg ← {𝕊:{
  s    ⇐ ⟨⟩
  Push ⇐ {𝕊:s∾↩<𝕩}
  Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}                                                                              # Return but don't pop top value
  Pop  ⇐ {t←-𝕩⋄(s↓˜↩t)⊢⌽t↑s}                                                                           # Pop 𝕩 values; return as list
}}¨↕2

sysfile←{
  Lines⇐{
    𝕩 : "/"≤○≠◶0‿(⊣≡≠⊸↑)𝕩 ? •file.Lines 𝕩
  ; 𝕩 : •file.Lines ∾⟜𝕩 •file.Parent ctx.Peek @
  }
  List ⇐{ •file.List ∾⟜𝕩 •file.Parent ctx.Peek @ }
}

Show←{
  # TODO current line in file
  •Show 𝕩
}

ShowAll←{𝕊:
  # TODO current line in file
  flg_shw↩1
}

Break←{flg_brk↩1⋄𝕩}

syslist←⟨
    "bqn"‿•Bqn
    "break"‿Break
    "brk"‿Break
    "debug"‿Break
    "currenterror"‿•CurrentError
    "exit"‿•Exit
    "ffi"‿•FFI
    "file"‿sysfile
    "flines"‿sysfile.Lines
    "fmt"‿•Fmt
    "hash"‿•Hash
    "hashmap"‿•HashMap
    "internal"‿•internal
    "unixtime"‿•unixtime
    "makerand"‿•MakeRand
    "math"‿•math
    "ns"‿•ns
    "out"‿•Out
    "parsefloat"‿•ParseFloat
    "path"‿•path
    "primitives"‿•Primitives
    "repr"‿•Repr
    "rand"‿•rand
    "show"‿Show
    "showall"‿ShowAll
    "term"‿•term
    "toutf8"‿•ToUTF8
    "type"‿•Type
    "wdpath"‿•wdpath
    "while"‿•_while_
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
    o←|-´(pos-1)⊑¨loc                                                                                  # offset 
    c←cols⊑˜⊑(pos-1)⊑¨loc                                                                              # column
    l←1+line⊑˜pos⊑⊑loc                                                                                 # line

    ##-- cbqn like stack trace --
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l⟩
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",(l-1)⊑sl⟩
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨dbg.s
}

# shows compiler errors
_CmpCatch←{ f Exit _𝕣 src:
  l←+`src=lf ⋄ sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                                                              # l: line numbers, sl: source file in lines

  •Show •CurrentError@
  { 𝕊 loc‿msg:
      s‿e←loc↩⥊⊑˘loc
      # TODO locations
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

_PreHook←{vmap _𝕣 pos‿file‿stack:
  ⟨cm,src,cols,brk,line⟩←imports.Get file ⋄ bc‿·‿·‿·‿loc‿·←cm

  i←pos⊑⊑loc
  ll←i⊑line
  { 𝕩:(last_brk≠ll)∧⊑ll∊brk ?
      last_brk↩ll
      flg_brk↩1
  ; 𝕩:@
  }⍟⊣⊑brk∊˜i⊑line

  # TODO cleanup
  {𝕊:Repl vmap‿cm‿file‿pos}⍟⊣ flg_brk

  {𝕊: dbg.Push ⟨file,pos⟩}⍟⊣ (pos⊑bc)⍷dbg_ops
}

_PostHook←{· _𝕣 pos‿file‿stack:
  ⟨cm⟩←imports.Get file ⋄ bc‿·‿·‿·‿·‿·←cm
  {𝕊: dbg.Pop 1}⍟⊣ (pos⊑bc)⍷dbg_ops
  # TODO print location via loc
  {𝕊:•Show (stack.Peek@) }⍟⊣ flg_shw∧(pos⊑bc)⍷shw_ops
}

_ErrorHook←{vmap _𝕣 pos‿file‿·:
  ⟨cm,src,cols,brk,line⟩←imports.Get file ⋄ bc‿·‿·‿·‿loc‿·←cm
  VMCatch@
  Repl vmap‿cm‿file‿pos
}

# Hooks to run in VM
hooks←{
  _Pre  ⇐ _PreHook
  _Post ⇐ _PostHook
  _Err  ⇐ _ErrorHook
  End   ⇐ {𝕊: flg_shw↩0 }
}

# Wrap namespace to vm compatable namespace 
Import ← {
    𝕊 𝕩     : ⟨⟩ 𝕊 𝕩
; 𝕨 𝕊 ⟨file⇐file⟩ : imports.Has file ? (imports.Get file).Get @
; 𝕨 𝕊 ⟨file⇐file⟩ :
    src←•file.Chars file
    cm ← (⟨1⊸⊑¨•primitives, System 𝕨, ⟨⟩⟩⊸Compile)⎊(file⊸(•Exit _CmpCatch)) src

    # Saved data for imports
    ns←{
      line  ⇐ +`src=lf                                                                                 # line numbers
      cols  ⇐ ∾(↕≠)¨⊔˜line                                                                             # column numbers
      cm    ⇐ cm                                                                                       # compilation result
      brk   ⇐ /{∨´(≠𝕩)↑"??"⍷𝕩}¨line⊔src
      src   ⇐ src                                                                                      # raw source code (helps for debugging)

      Get    ⇐ !∘"Import result referenced before completion"
      SetRet ⇐ {𝕊 v: Get↩{𝕊:v}}
    }

    ctx.Push file
    file imports.Set ns
    ns.SetRet ret←hooks‿{Has⇐0˙}‿file vm.Eval cm
    ctx.Pop 1
    ret
; 𝕨 𝕊 𝕩 :                                                                                              # canonicalize filename
    file←'/'⊸∾⍟(¬∘∨´"./"⊸⍷) 𝕩
    file↩𝕩∾˜(0⊸≢≠)◶""‿•file.Parent ctx.Peek @                                                          # resolve relative file location
    𝕨 𝕊 {file⇐file}
}

Repl⇐{
  𝕊 vmap‿cm‿file‿pos: 3=•Type vmap ?
    ⟨src,cols,line⟩←imports.Get file ⋄ bc‿·‿·‿·‿loc‿·←cm
    # TODO cleanup
    i←pos⊑⊑loc ⋄ o←|-´pos⊑¨loc ⋄ c←i⊑cols ⋄ l←i⊑line ⋄ ln←l⊑line⊔src                                   # i: position from bc to src. o: offset between start and end postions. c: current column number. l: current line number. ln: current line as string
    h‿m‿t←3↑ln⊔˜+`((1+o+c)⊸=∨c⊸=)↕≠ln                                                                  # h: head, m: middle, t: tail

    io.term.RawMode 1
    io.term.OutRaw •ToUTF8     ∾⟨magenta,file/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷file,':',•Fmt l,reset⟩      # TODO move this to repl?
    io.term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",h(⊣/˜≠)lf,magenta,m,reset,t⟩
    io.term.OutRaw •ToUTF8 prompt
    io.term.Flush@

    hn←1-˜≠history←⟨⟩                                                                                  # TODO read history from file

    vmap↩Vmap @ ⋄ ch←⟨⟩ ⋄ ps←0 ⋄ cont←0                                                                # vmap: variable mappings. ch: character buffer. ps: cursor offset
    hooks←{_Pre⇐_Post⇐{_𝕣:@}⋄_Err⇐{_𝕣:VMCatch}⋄End⇐{𝕩}}
    flg_brk↩0

    SetHistory←{
      0=≠history? ""‿0‿1
    ; ch↩history⊑˜hn↩(1-˜≠history)⌊0⌈𝕩+hn
      ch‿(≠ch)‿1
    }

    Continue←{𝕊:
      io.term.OutRaw clear
      io.term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
      io.term.OutRaw lf∾˜"Continue"
      flg_brk↩0
      ⟨⟩‿0‿0
    }

    Reload←{𝕊:
      imports←•HashMap˜⟨⟩
      ⟨⟩‿0‿0
    }

    Help←{𝕊: 
      # TODO
      ⟨⟩‿0‿1
    }

    Cmd←{
      "":
        io.term.OutRaw •ToUTF8 lf∾˜prompt
        ⟨⟩‿0‿1
    ; ")list":
        io.term.OutRaw clear
        io.term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
        io.term.OutRaw •ToUTF8 lf∾˜∾∾⟜" "¨vmap.Keys@
        ⟨⟩‿0‿1
    ; ")c": Continue 𝕩
    ; ")cont": Continue 𝕩
    ; ")continue": Continue 𝕩
    ; ")r": Continue 𝕩
    ; ")reload": Continue 𝕩
    ; ")h": Help 𝕩
    ; ")help": Help 𝕩
    ; 𝕩: ")"≡1↑𝕩 ? 
        io.term.OutRaw clear
        io.term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
        io.term.OutRaw •ToUTF8 lf∾˜"unknown command"
        ⟨⟩‿0‿1
    ; 𝕩:
        io.term.OutRaw clear
        io.term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
        in←"x__arg‿w__arg←•args ⋄ w__arg {𝕊:"∾𝕩∾"} x__arg"                                             # HACK: wrap in function via string manipulation to expose 𝕊 𝕨 𝕩 variables 
        cm ← (⟨1⊸⊑¨•primitives, System vmap.Get¨"𝕩𝕨", vmap.Keys@⟩⊸Compile)⎊(""⊸({𝕊:@}_CmpCatch)) in
        {@:1; io.Out hooks‿vmap‿@ vm.Eval 𝕩} cm
        hn↩≠history ∾⟜(⋈𝕩) ↩
        ⟨⟩‿0‿1
    }

    Patch←{0=≠ch?⟨⟩;∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch}                                               # add 𝕩 into ch at ps position with 𝕨 deletions
    Exit ←{𝕊:io.term.OutRaw •ToUTF8 lf∾˜""⋄•Exit 0 }                                                   # add trailing newline before exit to keep terminal happy

    # Tip: use `cat -v` in the terminal to find out key codes
    # Map of key buffer to function that returns ch‿pos‿continue
    Map←{                                                                                              # map of inputs to ⟨ch, ps, eff⟩. ch: new character list, ps: position, eff: side effect function⟩  
      𝕩:𝕩≡e∾"[D"             ? ⟨ch,0⌈ps-1, 1⟩                                                          # arrow left
    ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,(≠ch)⌊ps+1,1⟩                                                       # arrow right
    ; 𝕩:𝕩≡e∾"[A"             ? SetHistory⟜¯1                                                           # arrow up
    ; 𝕩:𝕩≡e∾"[B"             ? SetHistory⟜1                                                            # arrow down
    ; 𝕩:𝕩≡e∾"[46;5u"         ? {𝕊:flg_brk↩1⋄⟨⟩‿0‿0}                                                    # ctrl+; next bytecode
    ; 𝕩:𝕩≡e∾"[109;5u"        ? ⟨⟨⟩,0,1⟩
    ; 𝕩:𝕩≡e∾"[27;5;13~"      ? Continue                                                                # ctrl+enter
    ; 𝕩:𝕩≡≍@+10              ? {𝕊: Cmd ((∨`∧∨⟜«)' '⊸≠)⊸/ch}                                            # enter and run command
    ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "", 0⌈ps-1, 1⟩                                                 # backspace
    ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,0,1⟩                                                                # ctrl+u
    ; 𝕩:𝕩≡≍@+3               ? Exit                                                                    # ctrl+c
    ; 𝕩:𝕩≡≍@+4               ? Exit                                                                    # Ctrl+d
    ; 𝕩:0=≠ch                ? ⟨𝕩,1,1⟩
    # TODO reload
    # TODO list variables
    ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                               ⟨ch0←1 Patch z, (≠z)+ps-1, 1⟩                                           # replace '/' with unicode chars
    ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,      1⟩
    }

    # consume utf8 or ANSI control chars
    Input←{
       𝕊@:𝕊io.In@
    ;  𝕊𝕩:𝕩=e?𝕩∾e𝕊io.In@
    ;  𝕊𝕩:𝕩<@+128?⟨𝕩⟩
    ;  𝕊𝕩:𝕩<@+224?•FromUTF8𝕩∾⟨io.In@⟩
    ;  𝕊𝕩:𝕩<@+240?•FromUTF8𝕩∾⟨io.In@,io.In@⟩
    ;  𝕊𝕩:        •FromUTF8𝕩∾⟨io.In@,io.In@,io.In@⟩
    ; e𝕊𝕩:⊑𝕩∊∾'~'∾+⟜(↕26)¨"Aa"?𝕩
    ; e𝕊𝕩:𝕩∾e𝕊io.In@
    }

    {𝕊:
      eff←Map Input@⋄ch‿ps‿cont↩Eff@
      io.term.OutRaw clear                                                                             # clear line and set to start of line
      io.term.OutRaw •ToUTF8 prompt
      io.term.OutRaw •ToUTF8 ch
      io.term.OutRaw e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
      io.term.Flush@
      cont
    }•_while_ ⊢ 1

    io.term.OutRaw •ToUTF8 lf∾˜""
}

Run ⇐ {
  Import 𝕩
  io.term.OutRaw •ToUTF8 lf∾˜"-- dbq end --"
}

