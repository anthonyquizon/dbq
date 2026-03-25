# dbq - Debugger for BQN

Modified version of [bqn.bqn](https://github.com/mlochbaum/BQN/blob/master/bqn.bqn) to provide a debugging and repl driven development experience

## Breakpoints

**System function**
```bqn
•BRK@ # break at this line
```
or 
```bqn
# ?? - break at closes previous or current line with code
```

**Key mappings**
- ctrl-Enter: continue to next breakpoint
