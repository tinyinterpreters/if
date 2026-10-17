# IF

IF extends [ZERO](https://github.com/tinyinterpreters/zero) with conditional expressions:

```txt
if zero?(0) then 2 else 3
```

A conditional evaluates its condition first, then uses the resulting Boolean value to choose which branch to evaluate. The other branch remains unevaluated.

That means this program succeeds:

```txt
if zero?(0) then 2 else -(zero?(0), 1)
```

even though the else branch would produce a runtime type error if it were evaluated.

For a closer look, read [IF: Conditional Expressions and Selective Evaluation](https://blog.tinyinterpreters.dev/posts/if/).

## Try it

You'll need [Nix](https://nixos.org/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import IF.Interpreter as I

I.run "if zero?(0) then 2 else 3"
-- Ok (VNumber 2)
```
