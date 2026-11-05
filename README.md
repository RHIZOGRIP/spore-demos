# spore demos

[Spore](https://github.com/RHIZOGRIP/spore) piloting complex software, with no plugin. A small
socket bridge runs inside the app, and the agent writes its own client from one paragraph of
protocol.

| Demo | App | Status |
|---|---|---|
| [Chain reaction](blender/chain-reaction/) | Blender | run once, video, telemetry and checks included |
| [Lighthouse](blender/lighthouse/) | Blender | run once, renders included |
| [Sphere grid](rhino/) | Rhino 8 | run once, Windows with spore in WSL 2 |

## How it works

1. You start the app with the bridge, a script of under 150 lines.
2. The bridge listens on `127.0.0.1` and prints a paragraph with the protocol and a fresh token.
3. You paste that paragraph to a spore, followed by a task.
4. The spore writes a client, sends Python to the app, reads what comes back, and carries on until
   the task is done. Where the task produces images, it looks at them and fixes what is wrong.

The bridge takes one JSON line per connection, `{"token": "...", "code": "<Python>"}`, runs the code
inside the app, and answers one JSON line. Each app has its own bridge because each runs code on
its main thread in its own way. The protocol is the same.

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

## Adding a demo

Any app with a scripting runtime inside it will do. Copy a bridge, and change how it runs code on
the app's main thread and which names it puts in scope. Then write the paragraph that tells the
agent what it needs to know about the app.
