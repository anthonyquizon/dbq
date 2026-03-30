a←1
b←1+1+1
# Should break •Break with context a b
•Break@
c←a+b
# Should break •Break with context a b c
#•Break@

#import←•Import "break.b.import.bqn"
## Should break on import with context a←2
#import.F 1
## Should break on import with context a←3
#import.F 2

## Should catch error 
#a↩↕3 ⋄ 5⊑a

## Should catch error in body
#111 {a𝕊b:𝕩⊑𝕨} 555 
