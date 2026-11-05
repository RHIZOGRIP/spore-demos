# Rhino 8

Run once, with Rhino 8 on Windows and spore in WSL 2. Rhino is commercial software; you need your
own licence.

## 1. Windows: mirrored networking (once)

Spore runs on Linux, so on Windows it runs in WSL 2. Mirrored networking lets WSL reach Rhino on
`127.0.0.1`. In `%UserProfile%\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
```

In PowerShell, run `wsl --shutdown`, then reopen Ubuntu. Check it there:

```sh
wslinfo --networking-mode
```

It prints `mirrored`.

## 2. Start the bridge

In Rhino 8, run `ScriptEditor`, make a new Python 3 script, paste `spore_bridge.py` into it and run
it. The output prints a paragraph to paste to your spore, with this start's token in it.

Each request is one Ctrl+Z in Rhino. Running the same script again stops the bridge.

## 3. Run it

`spore tui main`, then paste the bridge's paragraph, followed by this:

```
Make a layer named spore-test and draw a 10×10 grid of spheres on it, radius growing along x. Tell me what you did.
```
