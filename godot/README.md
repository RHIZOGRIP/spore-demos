# Godot

Unlike the Blender and Rhino demos, this one has no bridge. Godot's projects are text and it runs
from the command line, so the spore runs Godot itself, inside its sandbox. Nothing it writes runs
outside, unless you open the game yourself.

| Demo | What the spore does |
|---|---|
| [Kêr-Is](keris/) | Makes a whole game in two turns, balances it with bots over 200 seeds, films it and exports it for the web |

## What works in the sandbox

Tested on Debian 13 with Godot 4.7.2:

| Need | How |
|---|---|
| Run the game, playtest with bots | `--headless` works as it is |
| Export for the web | Needs a self-contained copy of Godot, below |
| See the game | Headless Weston and Godot's Movie Maker, below |
| Run the web build in a browser | Doesn't work: test it yourself |

**Export.** Godot writes `/tmp/tmpproject.binary` during an export and ignores `$TMPDIR`. A spore
can't write to `/tmp`, so the export exits 0 but leaves `project.binary` out of the pack. In
self-contained mode, with a `._sc_` file beside the binary, the temporary file goes to
`editor_data/temp/` instead.

**Seeing the game.** Xvfb needs `/tmp`, and `--headless` has no renderer. Weston's headless backend
needs only a private `XDG_RUNTIME_DIR`. Godot then renders on Mesa's software driver, and
`--write-movie` saves the frames and the sound.

**Browser.** Headless Chromium's GPU process died in all 8 attempts, even with `--disable-gpu`. We
don't know why. The sandbox also refuses a local server.

## Setup

You need spore 1.57.0 or newer, and a model that reads images. Download
[Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) for Linux and its
export templates, then:

```sh
sudo apt install weston ffmpeg unzip g++
spore define keris
spore edit keris
```

In the editor, set these lines:

```
rounds: [120, 150]
cost: [5, 8]
wall: [60m, 75m]
images: [12, 30MB]
```

Then give the spore its copy of Godot, from the folder with your downloads:

```sh
GODOT=~/.spore/keris/data/godot
TEMPLATES="$GODOT/editor_data/export_templates/4.7.2.stable"
mkdir -p "$TEMPLATES"
unzip -j Godot_v4.7.2-stable_linux.x86_64.zip -d "$GODOT"
mv "$GODOT/Godot_v4.7.2-stable_linux.x86_64" "$GODOT/godot4"
touch "$GODOT/._sc_"
unzip -j Godot_v4.7.2-stable_export_templates.tpz 'templates/web_nothreads_*' 'templates/version.txt' -d "$TEMPLATES"
```
