# -*- coding: utf-8 -*-
"""Lint GDScript cua rieng du an (khong tinh addons/).

    python tool/lint.py

Kiem hai thu:

  1. FORMAT  - tab (khong space), khong CRLF, <= 100 cot, khong khoang trang cuoi dong,
               co newline cuoi file, khong thua dong trong cuoi file.
  2. SYMBOL CHET - const / func / var khai bao ma khong cho nao trong repo dung tới.

Luu y hai false positive da biet:

  - `minigame/mini_game.gd` va `minigame/tank/xe_tang.gd` bao CRLF: .gitattributes co
    `* text=auto eol=lf` nen index luu LF, git coi nhu khong doi. Do la artifact cua
    working tree, dung "sua" lam gi.
  - `main.gd:375,385` dai > 100 cot: comment co san, khong phai cua ai dang sua.
"""

import io, os, re, subprocess, glob
files = sorted(glob.glob('minigame/**/*.gd', recursive=True)) + ['main.gd']
print('=== FORMAT ===')
bad = 0
for f in files:
    raw = io.open(f, 'rb').read()
    txt = raw.decode('utf-8')
    issues = []
    if b'\r\n' in raw: issues.append('CRLF')
    if b'\t' not in raw and len(txt.split('\n')) > 20: issues.append('khong dung tab')
    for i, l in enumerate(txt.split('\n'), 1):
        if l.rstrip() != l: issues.append('line %d: khoang trang cuoi dong' % i)
        if l.startswith('    ') and not l.startswith('\t'): issues.append('line %d: thut bang space' % i)
        # do rong hien thi: tab = 4
        w = len(l.replace('\t', '    '))
        if w > 100: issues.append('line %d: dai %d cot' % (i, w))
    if not txt.endswith('\n'): issues.append('thieu newline cuoi file')
    if txt.endswith('\n\n'): issues.append('thua dong trong cuoi file')
    if issues:
        bad += 1
        print('  %s' % f)
        for x in issues[:6]: print('      %s' % x)
        if len(issues) > 6: print('      ... va %d nua' % (len(issues) - 6))
if not bad: print('  tat ca sach: tab, khong CRLF, <=100 cot, khong khoang trang cuoi dong')

print()
print('=== SYMBOL CHET (const / func khong ai goi trong ca repo) ===')
blob = []
for f in glob.glob('**/*.gd', recursive=True) + glob.glob('**/*.tscn', recursive=True):
    if f.startswith('addons'): continue
    try: blob.append(io.open(f, encoding='utf-8', errors='replace').read())
    except Exception: pass
blob = '\n'.join(blob)
found = 0
for f in files:
    txt = io.open(f, encoding='utf-8').read()
    dead = []
    for m in re.finditer(r'^const\s+([A-Z_0-9]+)\s*:?=', txt, re.M):
        n = m.group(1)
        if len(re.findall(r'\b' + n + r'\b', blob)) <= 1: dead.append('const ' + n)
    for m in re.finditer(r'^(?:static\s+)?func\s+([a-z_0-9]+)\s*\(', txt, re.M):
        n = m.group(1)
        if n.startswith('_') and n in ('_ready','_init','_process','_physics_process',
                '_unhandled_input','_input','_enter_tree','_exit_tree','_notification'): continue
        if len(re.findall(r'\b' + n + r'\b', blob)) <= 1: dead.append('func ' + n + '()')
    for m in re.finditer(r'^var\s+(_?[a-z_0-9]+)', txt, re.M):
        n = m.group(1)
        if len(re.findall(r'\b' + n + r'\b', blob)) <= 1: dead.append('var ' + n)
    if dead:
        found += 1
        print('  %s' % f)
        for d in dead: print('      %s' % d)
if not found: print('  khong co')
