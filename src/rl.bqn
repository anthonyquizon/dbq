
⟨asc,uni⟩←•Import "cs.bqn"

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

prompt←"    "

⟨Out,Exit,term⟩←•args

term.RawMode 1
term.OutRaw •ToUTF8 prompt
term.Flush@

history←{
  history_file←{⟨history_file⟩:history_file; ⟨⟩} •args 
  f←•wdpath∾history_file
  n←1-˜≠s←•file.Lines⎊⟨⟩ f
  Set←{
    0=≠s?""
  ; (n+𝕩)≥≠s?""
  ; s⊑˜n↩(1-˜≠s)⌊0⌈𝕩+n
  }
  Add⇐{
    n↩≠s∾⟜(⋈𝕩)↩
    {⟨⟩:@; f •file.Lines s} history_file
  }
  Inc⇐Set⟜1
  Dec⇐Set⟜¯1
}

# consume utf8 or ANSI control chars as unicode
Input←{
   𝕊@:𝕊term.CharB@
;  𝕊𝕩:𝕩=e?𝕩∾e𝕊term.CharB@
;  𝕊𝕩:𝕩<@+128?⟨𝕩⟩
;  𝕊𝕩:𝕩<@+224?•FromUTF8𝕩∾⟨term.CharB@⟩
;  𝕊𝕩:𝕩<@+240?•FromUTF8𝕩∾⟨term.CharB@,term.CharB@⟩
;  𝕊𝕩:        •FromUTF8𝕩∾⟨term.CharB@,term.CharB@,term.CharB@⟩
; e𝕊𝕩:⊑𝕩∊∾'~'∾+⟜(↕26)¨"Aa"?𝕩
; e𝕊𝕩:𝕩∾e𝕊term.CharB@
}

# ===== READ LINE ======
_ReadLine⇐{
  Op←𝔽 ⋄ ch←⟨⟩⋄ps←cont←ret←0

  Patch←{
    ·𝕊· : 0=≠ch?⟨⟩
  ; n𝕊𝕩: ∾(∾⟜𝕩(-n)⊸↓)¨⌾(1⊸↑)ps(⊢⊔˜≤⟜(↕≠))ch
  }

  Cmd←{
    "":
      term.OutRaw •ToUTF8 lf∾˜prompt
      ⟨⟩‿0‿1

  ; 𝕩: ")"≡1↑𝕩 ?
    term.OutRaw clear
    term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
    term.OutRaw •ToUTF8 lf∾˜"unknown command"
    ⟨⟩‿0‿1
  ; 𝕩:
    term.OutRaw clear
    term.OutRaw •ToUTF8 lf∾˜prompt∾𝕩
    Out •Fmt Op 𝕩
    history.Add 𝕩
    ⟨⟩‿0‿1
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
  ; 𝕩:𝕩≡≍@+21              ? ⟨⟩‿0‿1                             # ctrl+u

  ; 𝕩:𝕩≡e∾"^C"             ? Exit             
  ; 𝕩:𝕩≡≍@+3               ? Exit                                       # ctrl+c
  ; 𝕩:𝕩≡≍@+4               ? Exit                                       # Ctrl+d
  ; 𝕩:𝕩≡⟨0⟩                ? Exit
  ; 𝕩:0=≠ch                ? 𝕩‿1‿1
  # TODO reload
  # TODO list variables
  ; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←uni/˜asc∊𝕩
                             ⟨ch0←1 Patch z, (≠z)+ps-1, 1⟩              # replace '/' with unicode chars
  ; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,      1⟩
  }

  {𝕊:
    eff←Handler Input@
    ch‿ps‿cont↩Eff@

    term.OutRaw clear                                                          # clear line and set to start of line
    term.OutRaw •ToUTF8 prompt
    term.OutRaw •ToUTF8 ch
    term.OutRaw e∾"["∾(•Fmt (≠prompt)+ps+1)∾"G"
    term.Flush@
    cont
  }•_while_ ⊢ 1

  term.OutRaw •ToUTF8 lf∾˜""
  ret
}

