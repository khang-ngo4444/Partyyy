# -*- coding: utf-8 -*-
"""Tim file .gd/.tscn/.tres khong cho nao tham chieu tới.

    python tool/orphan.py

Bo qua: addons/, asset/, builds/, entry point (main.*, project.godot), va kiem_luat*
(chay bang `--script` nen khong ai tro tới).

Luu y: `player/characters/*.tscn` bao mo coi la DUNG nhung dung xoa - do la thu vien
model KayKit; `character_visual.gd` chi preload 5/22 va cac cai khac la de dung sau.
`test_physics_placer.tscn` la harness test tay cho addon physics_placer, cung la entry
point theo ban chat.
""" 
import io, os, re, subprocess
tracked = [f for f in subprocess.run(['git','ls-files'],capture_output=True,text=True).stdout.split('\n') if f]
blob = []
for f in tracked:
    if f.endswith(('.gd','.tscn','.tres','.godot','.cfg','.gdextension')):
        try: blob.append(io.open(f, encoding='utf-8', errors='replace').read())
        except Exception: pass
blob = '\n'.join(blob)

ENTRY = {'main.tscn', 'main.gd', 'project.godot', 'icon.svg'}
orphan = []
for f in tracked:
    if f.startswith(('addons/', 'asset/', 'builds/', '.github/')): continue
    if not f.endswith(('.tscn', '.gd', '.tres', '.gdshader')): continue
    base = os.path.basename(f)
    if base in ENTRY or base.startswith('kiem_luat'): continue
    path = f.replace(os.sep, '/')
    hits = len(re.findall(re.escape(path), blob)) + len(re.findall(r'\b' + re.escape(base) + r'\b', blob))
    if hits > 1: continue
    cls = ''
    if f.endswith('.gd'):
        try:
            m = re.search(r'^class_name\s+(\w+)', io.open(f, encoding='utf-8', errors='replace').read(), re.M)
            if m:
                cls = m.group(1)
                if len(re.findall(r'\b' + cls + r'\b', blob)) > 1: continue
        except Exception: pass
    orphan.append((f, cls))
print('=== FILE KHONG AI THAM CHIEU ===')
for f, c in orphan:
    print('  %s%s' % (f, ('   (class_name %s cung khong ai dung)' % c) if c else ''))
if not orphan: print('  khong co')
