# spore demos

[Spore](https://github.com/RHIZOGRIP/spore) piloting complex software, with no plugin. In most
demos a small socket bridge runs inside the app, and the agent writes its own client from one
paragraph of protocol.

| Demo | App | Status |
|---|---|---|
| [Chain reaction](blender/chain-reaction/) | Blender | run once, video, telemetry and checks included |
| [Lighthouse](blender/lighthouse/) | Blender | run once, renders included |
| [Sphere grid](rhino/) | Rhino 8 | run once, Windows with spore in WSL 2 |
| [Kêr-Is](godot/keris/) | Godot 4.7 | two turns, game, videos, bot data and checks included |

## What these demos show

A spore working by itself for a long time, on complex work in several phases, from one prompt or a
few. It builds, measures, finds what failed and carries on until the result holds.

They don't show:

- **Finished work.** A real game or a real Blender production would take more turns and a more
  detailed scope.
- **The intelligence of a model.** These demos are about spore, not the model behind it. A different
  model brings different intelligence to the same prompt.

## How it works

1. You start the app with the bridge, a script of under 150 lines.
2. The bridge listens on `127.0.0.1` and prints a paragraph with the protocol and a fresh token.
3. You paste that paragraph to a spore, followed by a task.
4. The spore writes a client, sends Python to the app, reads what comes back, and carries on until
   the task is done. Where the task produces images, it looks at them and fixes what is wrong.

The bridge takes one JSON line per connection, `{"token": "...", "code": "<Python>"}`, runs the code
inside the app, and answers one JSON line. Each app has its own bridge because each runs code on
its main thread in its own way. The protocol is the same.

The [Godot demo](godot/) needs no bridge. Godot runs from the command line, so the spore runs it
itself, inside its sandbox.

## Before you start

```sh
npm install -g @rhizogrip/spore-cli
spore setup
```

The model has to read images for any demo that looks at renders.

## What the bridge gives the agent

**Code sent through a bridge runs outside spore's sandbox.** It runs inside the app, as your user,
with everything your user can reach. Spore's confinement holds for the agent and the commands it
runs, but the token hands it a way out, by design.

So:

- run a demo on a machine and an account where that is acceptable;
- stop the bridge when you are done;
- don't give the token to anything you wouldn't let run code as you.

The bridge listens on loopback only, and the token changes at every start. It has no other guard.
These scripts are demos, not products.

In production, run the app in a sandbox of its own, with only the files it needs. Then give the
bridge to spore's runner as a
[source](https://github.com/RHIZOGRIP/spore/blob/main/docs/operating.md#sources-sourcesjson), so the
agent asks for it by name and never holds its address or its token. A source speaks HTTP, so these
bridges would need an HTTP front first. We haven't built that.

## Adding a demo

Any app with a scripting runtime inside it will do. Copy a bridge, and change how it runs code on
the app's main thread and which names it puts in scope. Then write the paragraph that tells the
agent what it needs to know about the app.
