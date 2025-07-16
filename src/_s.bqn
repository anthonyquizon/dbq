
t←"𝕨𝕩"
u←"wx"

e←@+27

ch←⟨⟩
ps←0

asn‿del‿mov‿cmd‿clr←↕5 # effect flags

# TODO up and down for history

Map←{
  𝕨𝕊𝕩: ⊑"\"=¯1↑𝕨 ? ⟨(¯1↓𝕨)∾t/˜𝕩=u, asn⟩
; 𝕨𝕊𝕩: 𝕩=@+10    ? ⟨⟨⟩,            cmd⟩ # TODO execute command
; 𝕨𝕊𝕩: 𝕩=@+127   ? ⟨¯1↓𝕨,          del⟩ # TODO delete current position first
; 𝕨𝕊𝕩: 𝕩=@+21    ? ⟨⟨⟩,            clr⟩
; 𝕨𝕊𝕩: 𝕩=e       ? ⟨𝕨,             mov⟩
; 𝕨𝕊𝕩: 0=≠𝕨      ? ⟨𝕨∾𝕩,           asn⟩
; 𝕨𝕊𝕩:             
    ⟨∾(∾⟜𝕩)¨⌾(1⊸↑) 𝕨⊔˜ps≤↕≠𝕨, asn⟩ # insert character in position ps
}

•term.RawMode 1
{𝕊:
  ⟨ch0,eff⟩←ch  Map •term.CharB@
  { 𝕊𝕩:𝕩=asn ? ps 1⊸+↩ ⋄ch↩ch0
  ; 𝕊𝕩:𝕩=clr ? ps ↩0   ⋄ch↩ch0
  ; 𝕊𝕩:𝕩=mov ? {"[D":ps↩ps-1;"[C": ps↩ps+1;·:@}⟨•term.CharB@,•term.CharB@⟩ 
  ; 𝕊𝕩:@
  } eff

  •term.OutRaw e∾"[2K"∾e∾"[0G" # clear line and set to start of line
  •term.OutRaw •ToUTF8 ch
  •term.OutRaw e∾"["∾(•Fmt ps+1)∾"G"
  •term.Flush@
}•_while_ 1 @

