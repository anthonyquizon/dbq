# socket server
# Reference: https://github.com/Brian-ED/bqn-socket/blob/master/socket.bqn

⟨asc,uni⟩←•Import "cs.bqn"
⟨In,Out,term⟩←•args
ROut←term.OutRaw

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

_SocketServer⇐{
  af_inet      ← 2
  inaddr_any   ← 0
  sock_stream  ← 1
  sol_socket   ← 65535                                                  # 0xffff
  so_reuseaddr ← 2                                                      # 0x0004
  port         ← 𝕩
  Op           ← 𝔽

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

  Out "listening to port "∾•Fmt port
  {𝕊:
    c_fd‿·‿· ← Accept⟨srv_fd, ⋈⟨0, 14⥊0⟩, ⋈16⟩
    n‿buf←Read ⟨c_fd,1024⥊0,1024⟩
    Op •FromUTF8 n↑buf
  } •_while_ ⊢ 1
}

# ===== READ LINE ======
_ReadLine⇐{
  Op←𝔽 ⋄ ch←⟨⟩⋄ps←cont←0
  prompt←"    "

  term.RawMode 1
  ROut •ToUTF8 prompt
  term.Flush@

  history←{
    f←•wdpath∾"/.dbq.history"
    n←1-˜≠s←•file.Lines⎊⟨⟩ f
    Set←{
      0=≠s?""
    ; (n+𝕩)≥≠s?""
    ; s⊑˜n↩(1-˜≠s)⌊0⌈𝕩+n
    }
    Add⇐{n↩≠s∾⟜(⋈𝕩)↩⋄f •file.Lines s}
    Inc⇐Set⟜1
    Dec⇐Set⟜¯1
  }

  Exit ←{𝕊: ROut •ToUTF8 lf∾˜"" ⋄ •Exit 0 }

  Patch←{
    ·𝕊· : 0=≠ch?⟨⟩
  ; n𝕊𝕩: ∾(∾⟜𝕩(-n)⊸↓)¨⌾(1⊸↑)ps(⊢⊔˜≤⟜(↕≠))ch
  }

  Cmd←{
    "":
      ROut •ToUTF8 lf∾˜prompt
      ⟨⟩‿0‿1

  ; 𝕩:
    ROut clear
    ROut •ToUTF8 lf∾˜prompt∾𝕩
    Out •Fmt Op 𝕩
    history.Add 𝕩
    ⟨⟩‿0‿1
  }

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
  
  # Tip: use `cat -v` in the terminal to find out key codes
  # Map of key buffer to function that returns chars‿position‿continue
  Handler←{
    𝕩:𝕩≡e∾"[D"             ? ⟨ch,0⌈ps-1, 1⟩                             # arrow left
  ; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,(≠ch)⌊ps+1,1⟩                          # arrow right
  ; 𝕩:𝕩≡e∾"[A"             ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}             # arrow up
  ; 𝕩:𝕩≡e∾"[B"             ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}             # arrow down
  ; 𝕩:𝕩≡≍@+16              ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}             # ctrl+p
  ; 𝕩:𝕩≡≍@+14              ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}             # ctrl+n 
  ; 𝕩:𝕩≡e∾"^P"             ? {𝕊:ch←history.Dec@⋄⟨ch,≠ch,1⟩}             # arrow up
  ; 𝕩:𝕩≡e∾"^N"             ? {𝕊:ch←history.Inc@⋄⟨ch,≠ch,1⟩}             # arrow down
  #; 𝕩:𝕩≡e∾"[46;5u"         ? {𝕊:flg_brk↩1⋄⟨⟩‿0‿0}                                                    # ctrl+; next bytecode
  ; 𝕩:𝕩≡e∾"[109;5u"        ? ⟨⟨⟩,0,1⟩
  #; 𝕩:𝕩≡e∾"[27;5;13~"      ? Continue                                                                # ctrl+enter
  ; 𝕩:𝕩≡≍@+10              ? {𝕊: Cmd ((∨`∧∨⟜«)' '⊸≠)⊸/ch}               # enter and run command
  ; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "", 0⌈ps-1, 1⟩                    # backspace
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,0,1⟩                                   # ctrl+u
  ; 𝕩:𝕩≡≍@+3               ? Exit                                       # ctrl+c
  ; 𝕩:𝕩≡≍@+4               ? Exit                                       # Ctrl+d
  ; 𝕩:0=≠ch                ? ⟨𝕩,1,1⟩
  # TODO reload
  # TODO list variables
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1, 1⟩              # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,      1⟩
  }

  {𝕊:
    eff←Handler Input@
    ch‿ps‿cont↩Eff@

    ROut clear                                                           # clear line and set to start of line
    ROut •ToUTF8 prompt
    ROut •ToUTF8 ch
    ROut e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
    term.Flush@
    cont
  }•_while_ ⊢ 1

  ROut •ToUTF8 lf∾˜""
}

