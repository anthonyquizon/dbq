FFI←{"../extern/libpicosat.so" •FFI 𝕩}

c_init     ← FFI "*"‿"picosat_init"
c_reset    ← FFI ""‿"picosat_reset"‿"*"
c_set_seed ← FFI ""‿"picosat_set_seed"‿"*"‿"i32"
c_print    ← FFI ""‿"picosat_print"‿"*"‿"*u32"
c_sat      ← FFI "i32"‿"picosat_sat"‿"*"‿"u32"
c_add      ← FFI "i32"‿"picosat_add"‿"*"‿"i32"
c_deref    ← FFI "i32"‿"picosat_deref"‿"*"‿"i32"

Init←{𝕊:
  p←C_init ⟨⟩

  Gen⇐{
    C_add¨p⊸∾⌜∾∾⟜0¨𝕩  
    C_sat p‿100
  }
}

p←Init@
•Show p.Gen ⟨ 1‿¯2, 1‿2 ⟩

#unknown‿sat‿unsat←0‿10‿20

#C_add p‿1
#C_add p‿¯2
#C_add p‿0
#C_add p‿1
#C_add p‿2
#C_add p‿0
#•Show C_sat p‿100

#•SHow a← C_deref p‿2

#C_add p‿(a)
#C_add p‿0
#C_sat p‿100
#•SHow C_deref p‿2

##C_set_seed ⟨p, 100⟩
