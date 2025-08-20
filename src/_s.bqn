a←"a←1⋄•Show a+2 # a+ ?? this is a comment"
h←'#'
c‿q‿·←a⊔˜+`(=⟜h∨(≠∘⊢↑"??"⊸⍷))a # c: code, q: query
q↩((∨`∧∨⟜«)' '⊸≠)⊸/1⊸↓q
•Show q
•Show c
•Show (≠a)↑q⍷c # mask index for query location
