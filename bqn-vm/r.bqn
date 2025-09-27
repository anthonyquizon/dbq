
# f: lazy function to construct hashmap of variables
Repl⇐{𝕊 vmap:
  io.term.RawMode 1
  io.term.OutRaw •ToUTF8 prompt
  io.term.Flush@

  vmap↩Vmap @ ⋄ ch←⟨⟩ ⋄ ps←0 # vmap: variable mappings. ch: character buffer. ps: cursor offset
  hooks←{_Pre⇐_Post⇐{_𝕣:@}⋄Err⇐VMCatch}
  bkt_next↩0

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

  Continue←{𝕊:io.term.OutRaw lf∾˜"Continue"⋄bkt_next↩0⋄0}
  Next    ←{𝕊:bkt_next↩1⋄0} 

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
