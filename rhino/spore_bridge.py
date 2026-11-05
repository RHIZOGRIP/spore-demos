# Rhino 8, ScriptEditor (Python 3). Run once to start the bridge, run again to stop it.
# Takes one JSON line per connection on 127.0.0.1 — {"token": "...", "code": "..."} — runs the
# code on Rhino's UI thread with rs, sc, Rhino, System and doc in scope, and answers one JSON line:
# {"ok": true, "result": <the code's `result` variable>, "out": <what it printed>}
# or {"ok": false, "error": <traceback>, "out": ...}. Each request is one undo step in Rhino.

import contextlib
import io
import json
import secrets
import socket
import threading
import traceback

import System
import Rhino
import rhinoscriptsyntax as rs
import scriptcontext as sc

KEY = 'spore_bridge'
HOST, PORT = '127.0.0.1', 41999
MAX_REQUEST = 1 << 20
CONNECT = (
    'Rhino 8 is running on this computer and listens on 127.0.0.1:41999. Protocol: open a TCP '
    'connection, send one JSON line {"token": "%s", "code": "<Python 3>"} ending with a newline, '
    'read one JSON line back: {"ok": true, "result": ..., "out": ...} or {"ok": false, "error": '
    '<traceback>, "out": ...}. The code runs inside Rhino with rs (rhinoscriptsyntax), sc, Rhino '
    '(RhinoCommon), System and doc in scope; set a variable result to send a value back. One '
    'connection per request. Write a small client program in data/ and check it with '
    'result = rs.ExeVersion().'
)


def say(text):
    print(text)
    Rhino.RhinoApp.WriteLine(text)


def execute(code):
    doc = Rhino.RhinoDoc.ActiveDoc
    sc.doc = doc
    space = {'rs': rs, 'sc': sc, 'Rhino': Rhino, 'System': System, 'doc': doc}
    out = io.StringIO()
    record = doc.BeginUndoRecord('spore')
    try:
        with contextlib.redirect_stdout(out):
            exec(compile(code, '<spore>', 'exec'), space)
        return {'ok': True, 'result': space.get('result'), 'out': out.getvalue()}
    except Exception:
        return {'ok': False, 'error': traceback.format_exc(), 'out': out.getvalue()}
    finally:
        doc.EndUndoRecord(record)
        doc.Views.Redraw()


def on_ui(fn):
    done = threading.Event()
    box = {}

    def run():
        try:
            box['reply'] = fn()
        except Exception:
            box['reply'] = {'ok': False, 'error': traceback.format_exc(), 'out': ''}
        finally:
            done.set()

    Rhino.RhinoApp.InvokeOnUiThread(System.Action(run))
    done.wait()
    return box['reply']


def handle(conn, token):
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
    return on_ui(lambda: execute(code))


def serve(listener, token, stop):
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
                reply = handle(conn, token)
                conn.sendall((json.dumps(reply, default=repr) + '\n').encode())
            except Exception:
                say('spore bridge: a request failed — ' + traceback.format_exc())


running = sc.sticky.get(KEY)
if running:
    running['stop'].set()
    running['listener'].close()
    del sc.sticky[KEY]
    say('spore bridge stopped')
else:
    token = secrets.token_hex(8)
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.bind((HOST, PORT))
    listener.listen(4)
    stop = threading.Event()
    threading.Thread(target=serve, args=(listener, token, stop), daemon=True).start()
    sc.sticky[KEY] = {'stop': stop, 'listener': listener}
    say('spore bridge on {}:{} — run this script again to stop it'.format(HOST, PORT))
    say('Paste this to your spore, followed by a task:')
    say(CONNECT % token)
