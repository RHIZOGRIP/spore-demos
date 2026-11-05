# Blender

Tested on Blender 4.3 on Debian 13.

## Start the bridge

From this directory, in a terminal:

```sh
blender --python spore_bridge.py
```

The terminal prints a paragraph to paste to your spore, with this start's token in it. Keep it for
the demo's task.

Each request is one undo step in Blender, and the viewport redraws after each request. Blender is
frozen while a request runs, so a long render shows nothing until it ends.

## Stop the bridge

Quit Blender, or open `spore_bridge.py` in the Text Editor and run it again.

## Demos

- [Chain reaction](chain-reaction/): a physics simulation, debugged from its own numbers.
- [Lighthouse](lighthouse/): a scene built from one prompt, improved by looking at its own renders.
