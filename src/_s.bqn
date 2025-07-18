
t←"𝕨𝕩"
u←"wx"

e←@+27
eff←@
hist←⟨⟩
ch←⟨⟩
ps←0 # cursor position
hi←0 # history position

# ctrl-enter - continue
# ctrl-. - next

clear←e∾"[2K"∾e∾"[0G"

Nop←{𝕊:@}
Cmd←{𝕊:
  # TODO add to history
  •term.OutRaw clear
  •Show "command" 
}

Map←{
  #𝕨𝕊𝕩: ⊑"\"=¯1↑𝕨 ? ⟨(¯1↓𝕨)∾z←t/˜𝕩=u, (≠z)+ps-1, nop⟩ # TODO insert in current position
  𝕩:𝕩≡e∾"[D"? ⟨ch,     0⌈ps-1,     Nop⟩
; 𝕩:𝕩≡e∾"[C"? ⟨ch,     (≠ch)⌊ps+1, Nop⟩
; 𝕩:𝕩≡≍@+10 ? ⟨⟨⟩,     0,          Cmd⟩ 
; 𝕩:𝕩≡≍@+127? ⟨¯1↓ch,  ps-1,       Nop⟩ # TODO delete current position first
; 𝕩:𝕩≡≍@+21 ? ⟨⟨⟩,     0,          Nop⟩
; 𝕩:0=≠ch   ? ⟨𝕩,      1,          Nop⟩
; 𝕩:          ⟨∾(∾⟜𝕩)¨⌾(1⊸↑)ch⊔˜ps≤↕≠ch, ps+1, Nop⟩ # TODO fix 𝕩 is list of chars, insert character in position ps
}

# Consume chars until letter (ANSI format for keypresses)
# if e [ -> consume until letter
Input←{
   𝕊@:                    𝕊•term.CharB@
;  𝕊𝕩:𝕩=e             ?𝕩∾e𝕊•term.CharB@
;  𝕊𝕩:                ⟨𝕩⟩
; e𝕊𝕩:⊑𝕩∊∾+⟜(↕26)¨"Aa"?𝕩
; e𝕊𝕩:                 𝕩∾e𝕊•term.CharB@
}

•term.RawMode 1
{𝕊:
  ch‿ps‿Eff↩Map Input@
  Eff @

  •term.OutRaw clear # clear line and set to start of line
  •term.OutRaw •ToUTF8 ch
  •term.OutRaw e∾"["∾(•Fmt ps+1)∾"G"
  •term.Flush@
}•_while_ 1 @

