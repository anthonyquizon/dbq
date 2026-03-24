# Reference: https://github.com/anthonyquizon/vbqn/blob/main/src/v.bqn
glyphs ← ⟨
  "+-×÷⋆√⌊⌈|¬∧∨<>≠=≤≥≡≢⊣⊢⥊∾≍⋈↑↓↕«»⌽⍉/⍋⍒⊏⊑⊐⊒∊⍷⊔!"
  "˙˜˘¨⌜⁼´˝`"
  "∘○⊸⟜⌾⊘◶⎉⚇⍟⎊"
⟩

compile  ← glyphs •Import "c.bqn"
vm       ←        •Import "vm.bqn"

⟨Interrupt⟩ ← •args

entry←@
e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

# flags
flg_brk←0
flg_shw←0
last_brk←@

dbg_ops←⟨
  16,17,20,21,26,27,                                                                                   # Application
  18,19,23,22                                                                                          # Application with Nothing
⟩
shw_ops←⟨47,48,49,50,51⟩

ctx‿dbg‿imports←3⥊@
Init←{𝕊:
  imports↩•HashMap˜⟨⟩
  ctx‿dbg↩{𝕊:{
    s    ⇐ ⟨⟩
    Push ⇐ {𝕊:s∾↩<𝕩}
    Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}                                                                            # Return but don't pop top value
    Pop  ⇐ {t←-𝕩⋄(s↓˜↩t)⊢⌽t↑s}                                                                         # Pop 𝕩 values; return as list
  }}¨↕2
}

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
    #•term.OutRaw •ToUTF8 lf∾˜∾⟨f/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷f,':',•Fmt l⟩
    #•term.OutRaw •ToUTF8 lf∾˜∾⟨"  ",(l-1)⊑sl⟩
    #•term.OutRaw •ToUTF8 lf∾˜∾⟨red, "  ",(' '¨↕c), '∧'¨↕o+1, reset⟩
  }¨dbg.s
}

# shows compiler errors
_CmpCatch←{ f Exit _𝕣 src:
  l←+`src=lf ⋄ sl←(lf⊸≠)⊸/¨src⊔˜»+`lf=src                                                              # l: line numbers, sl: source file in lines

  •Show •CurrentError@
  { 𝕊 loc‿msg:
      s‿e←loc↩⥊⊑˘loc
      # TODO locations
      •term.OutRaw •ToUTF8 lf∾˜"Error: "∾msg
      •term.OutRaw •ToUTF8 lf∾˜(s⊑l)⊑sl
      •term.OutRaw •ToUTF8 lf∾˜⊣◶" ∧"¨«((↕≠src)/˜∨´l⊸=¨loc⊏l)∊s+↕1+e-s
  ; 𝕊 𝕩:
      •term.OutRaw •ToUTF8 lf∾˜"Error: "∾(•Fmt 𝕩)
      PrintStackTrace @
  }•CurrentError@
  Exit 1
}

VMCatch⇐{𝕊 ·:
  #•term.OutRaw •ToUTF8 lf∾˜∾⟨boldRed,"Error: ", •CurrentError@, reset⟩
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
  {𝕊:Interrupt vmap‿cm‿file‿pos}⍟⊣ flg_brk

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
  Interrupt vmap‿cm‿file‿pos
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

Run ⇐ {
  Init@
  entry↩𝕩

  # TODO parse .dbq file
  # parse 

  Import 𝕩
  #io.term.OutRaw •ToUTF8 lf∾˜"-- dbq end --"
}

