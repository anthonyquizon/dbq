Foo ← {𝕊:
  "a"
  {
    # --- should print everything below this line only in the current body
    "should print z"
    "should print y"
    "should print z"
  } 
  # should not print
  "should not print b"
  "should not print c"
}

# Bar should not print
Bar ←{
  "Should not print. " ∾ 𝕩
}

Foo 10
Bar "abc"
