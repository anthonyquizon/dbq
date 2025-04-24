# test imports
b←•Import "b.bqn"

# test nested 
{a←↕𝕩⋄{a←𝕩+1}¨a}¨↕4

# test reassign
z←1
z↩2
z↩3
z↩4
