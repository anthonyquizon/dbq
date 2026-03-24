# socket server
# Reference: https://github.com/Brian-ED/bqn-socket/blob/master/socket.bqn

⟨In,term⟩←•args
Out←term.OutRaw

prompt←"    "
history←{
  f←•wdpath∾"/.dbq.history"
  n←1-˜≠s←•file.Lines⎊⟨⟩ f
  Set←{
    0=≠s?""
  ; (n+𝕩)≥≠s?""
  ; s⊑˜n↩(1-˜≠s)⌊0⌈𝕩+n
  }
  Add⇐{
    n↩≠s∾⟜(⋈𝕩)↩
    f •file.Lines s
  }
  Inc⇐Set⟜1
  Dec⇐Set⟜¯1
}

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

SocketServer⇐{𝕊:
  af_inet      ← 2
  inaddr_any   ← 0
  sock_stream  ← 1
  sol_socket   ← 65535                                                                                 # 0xffff
  so_reuseaddr ← 2                                                                                     # 0x0004
  port         ← 8080

  sockaddr    ← "{u16,[14]u8}"
  sockaddr_in ← "{u16,u16,{u32},[8]u8}"

  socket     ← @ •FFI "i32"‿"socket"‿"i32"‿"i32"‿"i32"
  setsockopt ← @ •FFI "i32"‿"setsockopt"‿"i32"‿"i32"‿"i32"‿"*i32"‿"i32"
  bind       ← @ •FFI "i32"‿"bind"‿"i32"‿('&'∾sockaddr_in)‿"u32"
  listen     ← @ •FFI "i32"‿"listen"‿"i32"‿"i32"
  accept     ← @ •FFI "i32"‿"accept"‿"i32"‿('&'∾sockaddr)‿"&u32"
  send       ← @ •FFI "i64"‿"send"‿"i32"‿"*u8"‿"u64"‿"i32"

  htons      ← @ •FFI "i32"‿"htons"‿"i32"
  read       ← @ •FFI "i32"‿"read"‿"i32"‿"&u8"‿"i32"
  
  srv_addr ← ⟨af_inet,Htons ⟨port⟩,⟨0⟩,8⥊0⟩

  srv_fd←Socket af_inet‿sock_stream‿0
  Setsockopt srv_fd‿sol_socket‿so_reuseaddr‿⟨1⟩‿4
  Bind ⟨srv_fd,⋈srv_addr,16⟩
  Listen srv_fd‿3

  •Show "listening to port "∾•Fmt port
  {𝕊:
    c_fd‿·‿· ← Accept⟨srv_fd, ⋈⟨0, 14⥊0⟩, ⋈16⟩
    n‿buf←Read ⟨c_fd,1024⥊0,1024⟩
    •SHow •FromUTF8 n↑buf
    𝕩
  } •_while_ ⊢ 1
}

# ===== READ LINE ======

asc←"`1234567890-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}asdfghjkl;''ASDFGHJKL:""|zxcvbnm,./ZXCVBNM<>? "
uni←"˜˘¨⁼⌜´˝7∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧y⊔⊏⊐π←→↙𝕎⍷𝕣⍋YU⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↩\↖𝕊D𝔽𝔾«J⌾»·˙|⥊𝕩↓∨⌊n≡∾≍≠⋈𝕏C⍒⌈N≢≤≥⇐‿"

Cmd←{
  "":
    Out •ToUTF8 lf∾˜prompt
    ⟨⟩‿0‿1

; 𝕩:
  Out clear
  Out •ToUTF8 lf∾˜prompt∾𝕩

  #in←"x__arg‿w__arg←•args ⋄ w__arg {𝕊:"∾𝕩∾"} x__arg"                                             # HACK: wrap in function via string manipulation to expose 𝕊 𝕨 𝕩 variables
  #cm ← (⟨1⊸⊑¨•primitives, System vmap.Get¨"𝕩𝕨", vmap.Keys@⟩⊸Compile)⎊(""⊸({𝕊:@}_CmpCatch)) in
  #{@:1; io.Out hooks‿vmap‿@ vm.Eval 𝕩} cm

  history.Add 𝕩
  ⟨⟩‿0‿1
}

Exit ←{𝕊: Out •ToUTF8 lf∾˜"" ⋄ •Exit 0 }

# consume utf8 or ANSI control chars as unicode
Input←{
   𝕊@:𝕊In@
;  𝕊𝕩:𝕩=e?𝕩∾e𝕊In@
;  𝕊𝕩:𝕩<@+128?⟨𝕩⟩
;  𝕊𝕩:𝕩<@+224?•FromUTF8𝕩∾⟨In@⟩
;  𝕊𝕩:𝕩<@+240?•FromUTF8𝕩∾⟨In@,In@⟩
;  𝕊𝕩:        •FromUTF8𝕩∾⟨In@,In@,In@⟩
; e𝕊𝕩:⊑𝕩∊∾'~'∾+⟜(↕26)¨"Aa"?𝕩
; e𝕊𝕩:𝕩∾e𝕊In@
}

ReadLine⇐{𝕊:
  #vmap‿cm‿file‿pos←𝕩
  #⟨src,cols,line⟩←imports.Get file ⋄ bc‿·‿·‿·‿loc‿·←cm
  #"variable map should be a function" ! 3=•Type vmap
  #vmap↩Vmap@ ⋄ 
  ch←⟨⟩⋄ps←cont←0

  term.RawMode 1
  #Out •ToUTF8     ∾⟨magenta,file/˜¬(1¨↕1-˜≠p)∾(p←•wdpath∾'/')⍷file,':',•Fmt l,reset⟩      # TODO move this to repl?
  #Out •ToUTF8 lf∾˜∾⟨"  ",h(⊣/˜≠)lf,magenta,m,reset,t⟩
  Out •ToUTF8 prompt
  term.Flush@

  Patch←{
    ·𝕊· : 0=≠ch?⟨⟩
  ; n𝕊𝕩: ∾(∾⟜𝕩(-n)⊸↓)¨⌾(1⊸↑)ps(⊢⊔˜≤⟜(↕≠))ch
  }
  
  # Tip: use `cat -v` in the terminal to find out key codes
  # Map of key buffer to function that returns chars‿position‿continue
  Handler←{
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,0⌈ps-1, 1⟩                                                               # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,(≠ch)⌊ps+1,1⟩                                                             # arrow right
  ; 𝕩:𝕩≡e∾"[A"             ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}  # arrow up
  ; 𝕩:𝕩≡e∾"[B"             ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}  # arrow down
  ; 𝕩:𝕩≡≍@+16              ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}  # ctrl+p
  ; 𝕩:𝕩≡≍@+14              ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}  # ctrl+n 
  ; 𝕩:𝕩≡e∾"^P"             ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}  # arrow up
  ; 𝕩:𝕩≡e∾"^N"             ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}  # arrow down
  #; 𝕩:𝕩≡e∾"[46;5u"         ? {𝕊:flg_brk↩1⋄⟨⟩‿0‿0}                                                    # ctrl+; next bytecode
  ; 𝕩:𝕩≡e∾"[109;5u"        ? ⟨⟨⟩,0,1⟩
  #; 𝕩:𝕩≡e∾"[27;5;13~"      ? Continue                                                                # ctrl+enter
  ; 𝕩:𝕩≡≍@+10              ? {𝕊: Cmd ((∨`∧∨⟜«)' '⊸≠)⊸/ch}                                            # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "", 0⌈ps-1, 1⟩                                                 # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,0,1⟩                                                                # ctrl+u
  ; 𝕩:𝕩≡≍@+3               ? Exit                                                                    # ctrl+c
  ; 𝕩:𝕩≡≍@+4               ? Exit                                                                    # Ctrl+d
  ; 𝕩:0=≠ch                ? ⟨𝕩,1,1⟩
  # TODO reload
  # TODO list variables
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1, 1⟩                                               # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,      1⟩
  }

  {𝕊:
    eff←Handler Input@
    ch‿ps‿cont↩Eff@

    Out clear                                                                             # clear line and set to start of line
    Out •ToUTF8 prompt
    Out •ToUTF8 ch
    Out e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
    term.Flush@
    cont
  }•_while_ ⊢ 1

  Out •ToUTF8 lf∾˜""
}
