# Create a variable slot.
# A slot also functions as a variable reference, one kind of reference.
# References support some of the following fields:
# - Get:  Get value
# - GetC: Get value, and clear the slot (variable only)
# - SetN: Define value
# - SetU: Change value
# - SetQ: Set value and return 0 if possible, and return 1 if not
# - GetF: Get corresponding field from namespace 𝕩
MakeVar ← { program 𝕊 name:
  n⇐(=⟜¯1)◶⟨⊑⟜program.names,@⟩ name
  v⇐@  # Value
  Get ⇐ {𝕊:
    err←"Runtime: Variable referenced before definition"
    program.vmap.Has◶⟨!∘err,program.vmap.Get⟩ n
  }
  SetU ⇐ !∘"↩: Variable modified before definition"
  SetN ⇐ {
    Get ↩ {𝕊:v}
    (SetU ↩ {v↩𝕩}) 𝕩
  }
  SetQ ⇐ 0∘SetN
  GetC ⇐ {
    r ← Get𝕩
    #Get↩SetU↩SetN↩!∘"Internal error: Variable used after clear"
    r
  }
  GetF ⇐ {program 𝕩.Field name}
}

# Other kinds of references, and reference utilities
ref ← {
  # Constant-matching reference, like 𝕊2: in a header
  Matcher ⇐ {𝕊 const:
    SetQ ⇐ const˙ ≢ ⊢
  }
  # Array destructuring ⟨a,b,c⟩←
  Array ⇐ {𝕊 arr:
    Get  ⇐ {𝕩.Get@}¨ arr˙
    # Common code for all setter functions
    # 𝕨S𝕩 sets reference 𝕨 to 𝕩, and e indicates error handling
    al ← ∨´ {⟨al⟩:al;0}¨ arr
    _set_ ← {S _𝕣_ e:
      Err ← {(e∾": "∾𝕩)!e≡@ ⋄ ⟨1⟩} # e≡@ indicates SetQ, which can't error
      c ← (e≡@) ⊑ {𝔽}‿{𝔽⎊1}        # GetF or Get in F can error
      # Get field for reference 𝕨 from namespace, if possible
      F ← {⟨G⇐GetF⟩𝕊𝕩:(G𝕩).Get@ ; !Err"Cannot extract non-name from namespace"}
      {
        0=•Type𝕩 ? Err⍟al "Can't use alias in list destructuring"
                   arr ≡○≢◶⟨Err∘"Target and value shapes don't match", S¨⟩ 𝕩 ;
        6=•Type𝕩 ? (⊢ S F⟜𝕩)_c¨ arr ;
        Err "Multiple targets but atomic value"
      }
    }
    SetN ⇐    {𝕨.SetN𝕩}_set_"←"
    SetU ⇐    {𝕨.SetU𝕩}_set_"↩"
    SetQ ⇐ ∨´ {𝕨.SetQ𝕩}_set_@
    # Create a merged reference array based on this one
    Merge ⇐ {𝕊:
      Split ← {
        "[…]←: Value must have rank 1 or more" ! 1≤=𝕩
        <˘ 𝕩
      }
      Get ⇐ > Get
      SetN‿SetU‿SetQ ⇐ {𝕏⟜Split}¨ SetN‿SetU‿SetQ
    }
  }
  # Alias, like ⇐vals in ⟨a‿b⇐vals⟩←
  # It behaves like ⟨a‿b⟩← except when destructuring a namespace (GetF)
  Alias ⇐ {env‿name 𝕊 r:
    SetN‿SetU‿SetQ ⇐ r
    GetF ⇐ {env.program 𝕩.Field name}
    al ⇐ 1
  }
  # Destructuring placeholder ·
  not ⇐ { SetU⇐SetN⇐⊢ ⋄ SetQ⇐0˙ }
}

# Create an environment: essentially, a list of variable slots and a
# reference to the parent environment.
MakeEnv ← { 𝕊⟨
    p  # Parent environment
    v  # Total number of slots (special names plus named variables)
    n  # ID numbers of named variables
    e  # Which named variables are exported
  ⟩:
  ns ← v-≠n  # Number of special names
  parent ⇐ p
  program ⇐ p.program  # Determines the meaning of ID numbers
  vars ⇐ program⊸MakeVar¨ (ns⥊¯1) ∾ n  # Variables
  SetProgram⇐{program↩𝕩}
  # Return a namespace for this environment.
  # A namespace is represented as a namespace with one field, Field.
  # 𝕨 ns.Field 𝕩 returns the value of the field with ID 𝕩 in program 𝕨.
  MakeNS ⇐ {𝕤
    v ← @ ⊣´¨ n ⊔○(e⊸/) ns↓vars  # Lookup table
    # TODO create update function
    Field ⇐ {𝕨𝕊i:
      cross ← 𝕨 { 𝕨1⊘≡𝕩 ? ⊢ ; ⊑ 𝕩.names ⊐ ⊏⟜𝕨.names } program
      (Cross i) ⊑ v
    }
  }
}

# Return a function that reads the variable from slot s at depth d.
# The input is taken from the bytecode stream.
VO ← { d←𝕏@, s←𝕏@, s⊑·{𝕩.vars}{𝕩.parent}⍟d }

# Namespace from environment
Namespace ← {𝕩.MakeNS@}
# Read field 𝕨 from program 𝕩, where 𝕨 is the environment and index
GetField ← { e‿i 𝕊 𝕩:
  "Key lookup in non-namespace" ! 6=•Type𝕩
  (e.program 𝕩.Field i).Get @
}

# Constants
nothing  ← {⇐}  # Used when 𝕨 is ·
skipMark ← {⇐}  # Indicates body aborted instead of returning

# Execution stack: every body evaluation makes one of these
MakeStack ← {
  s ⇐ 𝕩                          # Stack (a list)
  cont ⇐ 1                       # Whether to continue execution
  rslt ⇐ skipMark                # Result: skipMark to abort current body
  Push ⇐ {s∾↩<𝕩}                 # Push a value
  Pop  ⇐ {t←-𝕩 ⋄ (s↓˜↩t) ⊢ ⌽t↑s} # Pop 𝕩 values; return as list
  Peek ⇐ {𝕊:0=≠s?⟨⟩;¯1⊑s}               # Return but don't pop top value
  Ret  ⇐ {rslt↩𝕩 ⋄ cont↩0 ⋄ "Internal compiler error: Wrong stack size"!𝕨≥≠s}
  Skip ⇐ {𝕊:       cont↩0}       # Exit with no return value
}

# All the opcodes
# Each one is a function that takes the next-opcode function so it can
# read values from the bytecode stream. It returns a function to be
# called on the stack s and environment e at evaluation time.
ops ← ((!∘"Unknown opcode")˙⊣´⊢)¨ ⊔˝ ⍉> ⟨
  # Constants and drop
   0‿{i←𝕏@ ⋄ {s𝕊e: s.Push         i⊑e.program.consts } }
   1‿{i←𝕏@ ⋄ {s𝕊e: s.Push e {𝕎𝕩}˜ i⊑e.program.blocks } }
   6‿(       {s𝕊e: s.Pop 1 }˙)
  # Returns
   7‿(       {s𝕊e: 0 s.Ret ⊑s.Pop 1 }˙)
   8‿(       {s𝕊e: 1 s.Ret Namespace e }˙)
  # Arrays
  11‿{i←𝕏@ ⋄ {s𝕊e: s.Push           ⌽s.Pop i } }
  12‿{i←𝕏@ ⋄ {s𝕊e: s.Push ref.Array ⌽s.Pop i } }
  13‿{i←𝕏@ ⋄ {s𝕊e: s.Push > ⌽s.Pop i } }
  14‿{i←𝕏@ ⋄ {s𝕊e: s.Push {𝕩.Merge@} ref.Array ⌽s.Pop i } }
  # Application
  16‿(       {s𝕊e: s.Push {   f‿x: F x     } s.Pop 2 }˙) 
  17‿(       {s𝕊e: s.Push { w‿f‿x: w F x   } s.Pop 3 }˙) 
  20‿(       {s𝕊e: s.Push {   g‿h:   G H   } s.Pop 2 }˙)
  21‿(       {s𝕊e: s.Push { f‿g‿h: F G H   } s.Pop 3 }˙)
  26‿(       {s𝕊e: s.Push { f‿m  : F _m    } s.Pop 2 }˙)
  27‿(       {s𝕊e: s.Push { f‿m‿g: F _m_ g } s.Pop 3 }˙)
  # Application with Nothing
  18‿(       {s𝕊e: s.Push {   f‿x:                     F⍟(nothing⊸≢) x } s.Pop 2 }˙) # Like 16
  19‿(       {s𝕊e: s.Push { w‿f‿x: (nothing≢w˙)◶⟨F,w˙⊸F⟩⍟(nothing⊸≢) x } s.Pop 3 }˙) # Like 17
  23‿(       {s𝕊e: s.Push { f‿g‿h: {f≡nothing?G H;F G H}               } s.Pop 3 }˙) # Like 21
  22‿(       {s𝕊e: "Left argument required" ! nothing≢s.Peek@ }˙)
  # Variables
  32‿{v←VO𝕩⋄ {s𝕊e: s.Push (V e).Get @ } }
  34‿{v←VO𝕩⋄ {s𝕊e: s.Push (V e).GetC@ } }
  33‿{v←VO𝕩⋄ {s𝕊e: s.Push  V e        } }
  # Headers
  42‿(       {s𝕊e: {0:s.Skip@; 1:@; 𝕊:!"Predicate value must be 0 or 1"} ⊑s.Pop 1 }˙)
  43‿(       {s𝕊e: s.Push ref.Matcher ⊑s.Pop 1 }˙)
  44‿(       {s𝕊e: s.Push ref.not }˙)
  # Assignment
  47‿(       {s𝕊e: s.Skip⍟⊢{r‿  v: r.SetQ   v           } s.Pop 2 }˙)  # r:
  48‿(       {s𝕊e: s.Push { r‿  v: r.SetN⊸⊢ v           } s.Pop 2 }˙)  # r  ←v
  49‿(       {s𝕊e: s.Push { r‿  v: r.SetU⊸⊢ v           } s.Pop 2 }˙)  # r  ↩v
  50‿(       {s𝕊e: s.Push { r‿f‿x: r.SetU⊸⊢ (r.Get@)F x } s.Pop 3 }˙)  # r F↩x
  51‿(       {s𝕊e: s.Push { r‿f  : r.SetU⊸⊢ F r.Get@    } s.Pop 2 }˙)  # r F↩
  # Namespaces
  64‿{i←𝕏@ ⋄ {s𝕊e: s.Push e‿i GetField  ⊑s.Pop 1 } }
  66‿{i←𝕏@ ⋄ {s𝕊e: s.Push e‿i ref.Alias ⊑s.Pop 1 } }
⟩

# convert env to hashmap - variable names to functions that return variables
# env 𝕊 args→(𝕊→vmap)
MakeVmap←{ 
  env 𝕊 args: {𝕊: 
    h←"𝕊𝕩𝕨"•HashMap 3↑args
    h⊣{ 
      𝕊 ⟨vs⇐vars⋄p⇐parent⟩:
        mv←{1∘𝕩.Get⎊0 @}¨vs # mask for existing values
        mn←{𝕩.n≢@}¨vs # mask for existing names
        v←(mn∧mv)/vs
        ({𝕩.n}¨v){
          𝕨 {𝕨 h.Set 𝕩.Get@}⍟(¬∘h.Has⊢) 𝕩
        }¨v
        𝕊 p
    ; 𝕊 ·: h 
    } env
  } 
}

# Evaluate a body
RunBC ← { hooks‿file𝕊bc‿pos‿env‿args:  # bytecode, starting position, environment
  Next ← {𝕊: (pos+↩1) ⊢ pos⊑bc }
  stack ← MakeStack ⟨⟩
  {𝕊:
    i  ← pos
    op ← (Next@) ⊑ ops
    op ↩ Op next

    vmap←env MakeVmap args
    vmap hooks._Pre i‿file‿stack
    # TODO toggle base bqn interpreter errors vs caught errors since stack is not captured
    #stack Op env
    stack Op⎊{𝕊:vmap hooks._Err i‿file‿stack} env
    vmap hooks._Post i‿file‿stack

    stack.cont  # Changes to 0 on return or abort
  } •_while_ ⊢ 1
  hooks.End file
  stack.rslt
}

# Evaluate a program, given the compiler output
Eval⇐{ hooks‿vmap‿file VM bc‿consts‿blockInfo‿bodyInfo‿loc‿token:
  consts { # Wrap namespace to vm compatable namespace 
    𝕊 ns: 6≡•Type ns?Field⇐{p𝕊i: Get ⇐ {𝕊:ns •ns.Get i⊑p.names}}
  ; 𝕊 𝕩: 𝕩
  }¨↩
  
  bodies ← {start‿vars‿names‿export:
    {parent 𝕊 args: # Called when the body is evaluated
      env ← MakeEnv parent‿vars‿names‿export
      (⊢ {𝕩.SetN 𝕨}¨≠↑env.vars˙) args  # Initialize arguments
      hooks‿file RunBC bc‿start‿env‿args
    }
  }¨ bodyInfo

  blocks ← {type‿imm‿body:
    # Handle operands - modifier arguments 𝔽 𝔾
    inner ← imm ⊑ type ⊑ ⟨
      2⥊⟨{𝕊n: N ⟨⟩}⟩
      {𝕊n: {d←N 𝕣‿𝕗  ⋄𝕨D𝕩}}‿{𝕊n: {N 𝕣‿𝕗  }}
      {𝕊n: {d←N 𝕣‿𝕗‿𝕘⋄𝕨D𝕩}}‿{𝕊n: {N 𝕣‿𝕗‿𝕘}}
    ⟩
    # Handle arguments 𝕨 𝕩
    outer ← imm ⊑ ⟨{
      m‿d: {𝕊v: {M 𝕤‿𝕩‿nothing∾v;D 𝕤‿𝕩‿𝕨∾v}} ;
      ⟨b⟩: {𝕊v: {B 𝕤‿𝕩‿(𝕨⊣nothing)∾v}}
    }, ⊑⟩

    # Assemble bodies
    nmc  ← "No matching case"
    Then ← {first 𝕊 next: {skipMark≢r←𝕨First𝕩 ? r ; 𝕨Next𝕩}}
    run  ← {
      1=•Type 𝕩  ? ⟨(𝕩⊑bodies) Then {!∘nmc}⟩
    ; 1≠=𝕩       ? "Internal compiler error: Invalid body indices"!0
    ; (≠𝕩)≢2-imm ? ""!0 # TODO error message
    ; 𝕩 Then´⟜(⊏⟜bodies)˜⟜{!∘𝕩}¨{
          imm?⟨nmc⟩;(0=≠¨𝕩)nmc⍟⊣¨"Left argument"⊸∾¨⟨"not allowed","required"⟩
        } 𝕩
    } body
    {𝕊 par: Inner Outer {par 𝕏 ⊢}¨run}
  }¨ blockInfo

  (⊑blocks){𝔽} {program⇐{
    consts⇐consts, blocks⇐blocks, names⇐0⊑2⊑token, vmap⇐vmap
  }}
}
