#!/usr/bin/env bqn

inB←exp←outB←⟨⟩
lf←@+10
end←@+4
cont←(@+27)∾"[27;5;13~"                      # ctrl+enter

Check←{𝕊: 
  •Show outB
  •Show exp
}

⟨Run⟩←{
  Out  ⇐ {outB∾⟜⟨𝕩⟩↩}
  Exit ⇐ •Exit∘Check
  term ⇐ {
    CharB⇐{𝕊:h‿t←1(↑⋈↓)inB⋄⊑h⊣inB↩t} 
    outRaw⇐flush⇐rawMode⇐0
  }
} •Import "./../src/rt.bqn"

inB↩∾lf⊸∾˜¨⟨"a", "b", end⟩
exp↩       ⟨"1", "3"   ⟩
Run "../test/cases.bqn"
Check@

•Out "ok ✓"
