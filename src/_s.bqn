
•term.RawMode 1


t←"𝕨𝕩"
u←"wx"

e←@+27

ch←⟨⟩

CharP←{ 'R':⟨⟩; c∾𝕊 c←•term.CharB @ }
Pos←{𝕊:•ParseFloat¨';'((⊢-˜+`×¬)∘=⊔⊢) ¯1↓2↓CharP @}

Map←{
  𝕨𝕊𝕩: ⊑"\"=¯1↑𝕨 ? (¯1↓𝕨)∾t/˜𝕩=u 
; 𝕨𝕊𝕩: 𝕩=@+10   ? ⟨⟩             # TODO execute command
; 𝕨𝕊𝕩: 𝕩=@+127  ? ¯1↓𝕨 # 
; 𝕨𝕊𝕩: 𝕩=@+21   ? ⟨⟩
; 𝕨𝕊𝕩: 𝕩=e      ? •Show⟨•term.CharB @, •term.CharB @⟩ ⋄ ""
; 𝕨𝕊"[D"        : •Show 𝕩 ⋄𝕨
; 𝕨𝕊"[C"        : •Show 𝕩 ⋄𝕨
; 𝕨𝕊𝕩: 𝕨∾𝕩
}

{𝕊:
  ch↩ch Map •term.CharB @

  #•term.OutRaw e∾"[6n"
  #•term.Flush@
   #¯1↓2↓CharP @ # drop escape,[ and R
  #ps←•ParseFloat¨';'((⊢-˜+`×¬)∘=⊔⊢) ¯1↓2↓CharP @ # drop escape,[ and R
  #•SHow ps

  •term.OutRaw e∾"[2K"∾e∾"[0G"
  •term.OutRaw •ToUTF8 ch
  #(k=@+127)◶{𝕊:•term.OutRaw •ToUTF8 ch}‿{𝕊:""} @
  •term.Flush@
}•_while_ 1 @

