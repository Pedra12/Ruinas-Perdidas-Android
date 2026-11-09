#!/usr/bin/env python3
"""Reduz texturas PNG grandes (as do Nature Kit têm até 4K) para economizar memória no celular.
Uso: pip install pillow && python3 tools/reduzir_texturas.py [pasta] [tamanho_max]
Padrão: assets/nature, 1024 px. Sobrescreve os PNGs (faça commit antes).
"""
import os
import sys

from PIL import Image

root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "assets", "nature")
limit = int(sys.argv[2]) if len(sys.argv) > 2 else 1024

for folder, _, files in os.walk(root):
    for f in files:
        if not f.lower().endswith(".png"):
            continue
        p = os.path.join(folder, f)
        with Image.open(p) as im:
            if max(im.size) <= limit:
                continue
            k = limit / max(im.size)
            new = (max(1, int(im.width * k)), max(1, int(im.height * k)))
            out = im.resize(new, Image.LANCZOS)
        out.save(p, optimize=True)
        print("reduzida", p, "->", new)
