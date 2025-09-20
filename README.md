# qBQN

## Breakpoints

**System function**
```bqn
•Break@ # break at this line
`` 

**Comment Syntax**
Specify breakpoints as comments in source code
- `<code> # <comment> ?? ` break point
- `<code> # <comment> ?? <pattern>` breakpoint where bytecode matches `<pattern>`

**Key mappings**
- ctrl-Enter: continue to next breakpoint
