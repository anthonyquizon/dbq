
# headers 
```
  42‿(       {s𝕊e: {0:s.Skip@; 1:@; 𝕊:!"Predicate value must be 0 or 1"} ⊑s.Pop 1 }˙) # eg. 𝕩<1 in {𝕩 : 𝕩<1 ? 𝕩}
  43‿(       {s𝕊e: s.Push ref.Matcher ⊑s.Pop 1 }˙)
  44‿(       {s𝕊e: s.Push ref.not }˙)
```

s.Skip@ skips bytecode eval loop of body by setting s.cont to false
