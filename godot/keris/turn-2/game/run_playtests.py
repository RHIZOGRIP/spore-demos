#!/usr/bin/env python3
"""Regenerate full-future oracle witnesses, replay them in Godot, then run EVERY policy.
No seed-specific decisions: search.py receives complete schedules and enumerates actions.
"""
import argparse,hashlib,json,pathlib,shutil,subprocess,sys
BASE=pathlib.Path(__file__).resolve().parent

def main():
 p=argparse.ArgumentParser();p.add_argument('--godot');p.add_argument('--out',default=str(BASE/'test-output/playtest.json'));p.add_argument('--width',type=int,default=256);a=p.parse_args()
 godot=a.godot or shutil.which('godot4') or str(BASE.parent/'godot/godot4')
 godot=str(pathlib.Path(godot).resolve());output=pathlib.Path(a.out).resolve();output.parent.mkdir(parents=True,exist_ok=True)
 work=output.parent/(output.stem+'-oracle');work.mkdir(exist_ok=True)
 def run(cmd,name):
  r=subprocess.run(cmd,cwd=BASE,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=240)
  (work/(name+'.log')).write_text(r.stdout);(work/(name+'.err')).write_text(r.stderr)
  if r.returncode or 'SCRIPT ERROR' in r.stdout+r.stderr or 'ERROR:' in r.stdout+r.stderr:
   raise RuntimeError(f'{name} failed exit={r.returncode}: {r.stderr[-2000:]} (logs {work})')
  return r.stdout
 schedules=work/'schedules.json';plans=work/'plans.json'
 run([godot,'--headless','--path',str(BASE),'--script','export_schedules.gd','--','--out='+str(schedules)],'export')
 run([sys.executable,str(BASE/'planner/search.py'),str(schedules),str(plans),'--width',str(a.width)],'search')
 data=json.loads(plans.read_text());data['input_sha256']=hashlib.sha256(schedules.read_bytes()).hexdigest();data['input_config']=json.loads(schedules.read_text())['config']
 plans.write_text(json.dumps(data,separators=(',',':')))
 replay=run([godot,'--headless','--path',str(BASE),'--script','replay_oracle.gd','--',str(plans)],'replay')
 assert 'GODOT_WITNESS_REPLAY PASS' in replay,replay
 result=run([godot,'--headless','--path',str(BASE),'--script','test.gd','--','--out='+str(output),'--oracle='+str(plans)],'bots')
 shutil.copyfile(plans,BASE/'oracle-plans.json')
 d=json.loads(output.read_text());print(result)
 print('All required check IDs:',json.dumps(d['checks'],sort_keys=True));print('Saved',output)
 return 0 if d['all_pass'] else 1
if __name__=='__main__':sys.exit(main())
