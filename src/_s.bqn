
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

Cmd←{𝕊:
  # TODO add to history
  •term.OutRaw clear
  •Show "command" 
  •Show 𝕨
}

# add 𝕩 into ch at ps position with 𝕨 deletions
Patch←{∾(∾⟜𝕩(-𝕨)⊸↓)¨⌾(1⊸↑) ps(⊢⊔˜≤⟜(↕≠))ch} 

# map of inputs to ⟨ch, ps, eff⟩ 
# ch: new character list, ps: position, eff: side effect function⟩
Map←{
  𝕩:𝕩≡e∾"[D"             ? ⟨ch,            0⌈ps-1,          {𝕩}   ⟩
; 𝕩:𝕩≡e∾"[C"             ? ⟨ch,            (≠ch)⌊ps+1,      {𝕩}   ⟩
; 𝕩:𝕩≡≍@+10              ? ⟨⟨⟩,            0,               ch⊸Cmd⟩ 
; 𝕩:𝕩≡≍@+127             ? ⟨1 Patch "",    0⌈ps-1,          {𝕩}   ⟩
; 𝕩:𝕩≡≍@+21              ? ⟨⟨⟩,            0,               {𝕩}   ⟩
; 𝕩:0=≠ch                ? ⟨𝕩,             1,               {𝕩}   ⟩
; 𝕩:'\'=ch(⊣⊑˜0⌈≠⊸⌊)ps-1 ? z←t/˜u∊𝕩
                           ⟨ch0←1 Patch z, (≠z)+ps-1,       {𝕩}   ⟩
; 𝕩:                       ⟨ch0←0 Patch 𝕩, ps+1,            {𝕩}   ⟩ 
}
#⟨∾(∾⟜(z←t/˜u∊𝕩))¨⌾(1⊸↑)ch⊔˜ps≤↕≠ch, (≠z)+ps-1, {𝕊:•Show "woo"}⟩

# if e consume chars until letter (ANSI format for keypresses)
Input←{
   𝕊@:𝕊•term.CharB@
;  𝕊𝕩:𝕩=e?𝕩∾e𝕊•term.CharB@
;  𝕊𝕩:⟨𝕩⟩
; e𝕊𝕩:⊑𝕩∊∾+⟜(↕26)¨"Aa"?𝕩
; e𝕊𝕩:𝕩∾e𝕊•term.CharB@
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

