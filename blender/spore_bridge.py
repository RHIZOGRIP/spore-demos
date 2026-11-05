# Blender 4.x. Start Blender with `blender --python spore_bridge.py` from a terminal, which prints
# what to paste to the spore. Running this file again from the Text Editor stops the bridge.
# Takes one JSON line per connection on 127.0.0.1 — {"token": "...", "code": "..."} — runs the code
# on Blender's main thread with bpy, C (bpy.context), D (bpy.data) and mathutils in scope, and
# answers one JSON line: {"ok": true, "result": <the code's `result` variable>, "out": <what it
# printed>} or {"ok": false, "error": <traceback>, "out": ...}. Each request is one undo step.

import contextlib
import io
import json
import queue
import secrets
import socket
import threading
import traceback

import bpy
import mathutils

KEY = 'spore_bridge'
HOST, PORT = '127.0.0.1', 41998
MAX_REQUEST = 1 << 20
CONNECT = (
    'Blender %s is running on this machine and listens on 127.0.0.1:41998. Protocol: open a TCP '
    'connection, send one JSON line {"token": "%s", "code": "<Python 3>"} ending with a newline, '
    'read one JSON line back: {"ok": true, "result": ..., "out": ...} or {"ok": false, "error": '
    '<traceback>, "out": ...}. The code runs on Blender\'s main thread with bpy, C (bpy.context), '
    'D (bpy.data) and mathutils in scope; set a variable result to send a value back. One '
    'connection per request. Blender is frozen during a request, so keep each one under 3 minutes '
    'and give the read a 5-minute timeout. There is no 3D view in the code\'s context: prefer the '
    'bpy.data API, and wrap an operator that needs a viewport in bpy.context.temp_override. '
    'EEVEE\'s engine id is BLENDER_EEVEE_NEXT or BLENDER_EEVEE, depending on the version. Blender '
    'runs outside your sandbox, so give it absolute paths. Write a small client program in data/ '
    'and check it with result = bpy.app.version_string.'
)


def execute(code):
    space = {'bpy': bpy, 'C': bpy.context, 'D': bpy.data, 'mathutils': mathutils}
    out = io.StringIO()
    try:
        with contextlib.redirect_stdout(out):
            exec(compile(code, '<spore>', 'exec'), space)
        reply = {'ok': True, 'result': space.get('result'), 'out': out.getvalue()}
    except Exception:
        reply = {'ok': False, 'error': traceback.format_exc(), 'out': out.getvalue()}
    bpy.ops.ed.undo_push(message='spore')
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            area.tag_redraw()
    return reply


def make_pump(jobs, stop):
    def pump():
        if stop.is_set():
            return None
        while True:
            try:
                code, box, done = jobs.get_nowait()
            except queue.Empty:
                return 0.1
            try:
                box['reply'] = execute(code)
            except Exception:
                box['reply'] = {'ok': False, 'error': traceback.format_exc(), 'out': ''}
            done.set()
    return pump


def on_main(jobs, code):
    box, done = {}, threading.Event()
    jobs.put((code, box, done))
    done.wait()
    return box['reply']


def handle(conn, token, jobs):
    data = b''
    while not data.endswith(b'\n'):
        chunk = conn.recv(65536)
        if not chunk:
            break
        data += chunk
        if len(data) > MAX_REQUEST:
            return {'ok': False, 'error': 'request over 1 MB'}
    try:
        request = json.loads(data)
    except ValueError:
        return {'ok': False, 'error': 'send one JSON object on one line, ending with a newline'}
    if not isinstance(request, dict) or not secrets.compare_digest(str(request.get('token', '')), token):
        return {'ok': False, 'error': 'wrong token'}
    code = request.get('code')
    if not isinstance(code, str):
        return {'ok': False, 'error': 'code must be a string of Python'}
    return on_main(jobs, code)


def serve(listener, token, jobs, stop):
    listener.settimeout(0.5)
    while not stop.is_set():
        try:
            conn, _ = listener.accept()
        except socket.timeout:
            continue
        except OSError:
            break
        with conn:
            try:
                conn.settimeout(30)
                reply = handle(conn, token, jobs)
                conn.sendall((json.dumps(reply, default=repr) + '\n').encode())
            except Exception:
                print('spore bridge: a request failed — ' + traceback.format_exc())


running = bpy.app.driver_namespace.get(KEY)
if running:
    running['stop'].set()
    running['listener'].close()
    if bpy.app.timers.is_registered(running['pump']):
        bpy.app.timers.unregister(running['pump'])
    while not running['jobs'].empty():
        _, box, done = running['jobs'].get_nowait()
        box['reply'] = {'ok': False, 'error': 'bridge stopped', 'out': ''}
        done.set()
    del bpy.app.driver_namespace[KEY]
    print('spore bridge stopped')
else:
    token = secrets.token_hex(8)
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.bind((HOST, PORT))
    listener.listen(4)
    jobs, stop = queue.Queue(), threading.Event()
    pump = make_pump(jobs, stop)
    bpy.app.timers.register(pump, persistent=True)
    threading.Thread(target=serve, args=(listener, token, jobs, stop), daemon=True).start()
    bpy.app.driver_namespace[KEY] = {'stop': stop, 'listener': listener, 'pump': pump, 'jobs': jobs}
    print('spore bridge on {}:{} — run this script again from the Text Editor to stop it'.format(HOST, PORT))
    print('\nPaste this to your spore, followed by a task:\n\n' + CONNECT % (bpy.app.version_string, token) + '\n')
