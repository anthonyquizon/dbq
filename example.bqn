a←10 ⋄ b←20
c←1+a+b⋄d←c+2 # ?? break on this line
e←{𝕩+a}¨↕3    # +a ?? break on first bytecode matching +a
