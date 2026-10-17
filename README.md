# IF Stepper

A stepper for [IF](https://github.com/tinyinterpreters/if).

## Try it

You'll need [Nix](https://nixos.org/) with flakes enabled.

```bash
nix develop
elm reactor
```

Open `http://localhost:8000/` in your browser and click on `src/Main.elm` to run the stepper.

## Example

Here's an example of the stepper working through a nested conditional.

![A screenshot of the IF Stepper](./screenshot.png)

The expression between `[` and `]` is currently being evaluated. The curly brackets, `{` and `}`, are used to denote values which can be either integers or Booleans.
