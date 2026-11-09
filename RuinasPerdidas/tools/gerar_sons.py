#!/usr/bin/env python3
"""Gera todos os sons do jogo (WAV 16 bits mono, 22050 Hz) por síntese.
Uso: python3 tools/gerar_sons.py    (precisa de numpy)
Os arquivos vão para audio/sfx e audio/music. Sem licenças externas: tudo gerado aqui.
"""
import os
import wave
import numpy as np

SR = 22050
rng = np.random.default_rng(7)
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


def t(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def env(n, a=0.01, r=0.1):
    e = np.ones(n)
    na, nr = max(1, int(SR * a)), max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] = np.minimum(e[-nr:], np.linspace(1, 0, nr))
    return e


def decay(n, k=6.0):
    return np.exp(-k * np.linspace(0, 1, n))


def noise(n):
    return rng.uniform(-1, 1, n)


def lowpass(x, a=0.1):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc)
        y[i] = acc
    return y


def sine(freq, d, phase=0.0):
    return np.sin(2 * np.pi * freq * t(d) + phase)


def sweep(f0, f1, d):
    tt = t(d)
    f = f0 + (f1 - f0) * tt / d
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def save(path, x, gain=0.8):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    pcm = (x * 32767).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("ok", os.path.relpath(path))


def sfx(name, x, gain=0.8):
    save(os.path.join(ROOT, "sfx", name + ".wav"), x, gain)


def music(name, x, gain=0.55):
    save(os.path.join(ROOT, "music", name + ".wav"), x, gain)


def echo(x, delay=0.28, fb=0.35, times=4):
    out = np.copy(x)
    for i in range(1, times + 1):
        d = int(SR * delay * i)
        out = np.concatenate([out, np.zeros(max(0, d + len(x) - len(out)))])
        out[d:d + len(x)] += x * (fb ** i)
    return out


# ---------------------------------------------------------------- efeitos
n = int(SR * 0.28)
sfx("swing", lowpass(noise(n), 0.25) * np.sin(np.pi * np.linspace(0, 1, n)) ** 2)

n = int(SR * 0.22)
x = sine(120, 0.22) * decay(n, 9) + lowpass(noise(n), 0.4) * decay(n, 12)
sfx("hit", x)

x = (sine(988, 0.08) * env(int(SR * 0.08), 0.002, 0.03)).tolist()
x = np.concatenate([x, sine(1319, 0.22) * decay(int(SR * 0.22), 5)])
sfx("coin", x)

notes = [523.25, 659.25, 783.99, 1046.5]
x = np.concatenate([sine(f, 0.16) * decay(int(SR * 0.16), 3) for f in notes] + [sine(1046.5, 0.5) * decay(int(SR * 0.5), 3)])
sfx("gem", echo(x, 0.12, 0.3, 2))

d = 2.2
n = int(SR * d)
x = lowpass(noise(n), 0.03) * 2.0 + sweep(50, 90, d) * 0.7
x *= env(n, 0.3, 0.6)
sfx("gate_open", x)

n = int(SR * 0.12)
sfx("footstep", lowpass(noise(n), 0.12) * decay(n, 10), 0.6)

n = int(SR * 0.45)
sfx("roll", lowpass(noise(n), 0.12) * np.sin(np.pi * np.linspace(0, 1, n)) ** 1.5, 0.7)

sfx("jump", sweep(260, 520, 0.18) * env(int(SR * 0.18), 0.005, 0.08), 0.6)

n = int(SR * 0.35)
x = sweep(320, 90, 0.35) * decay(n, 4)
x = np.sign(x) * np.abs(x) ** 0.6
sfx("player_hurt", x, 0.8)

n = int(SR * 0.7)
x = lowpass(noise(n), 0.2) * decay(n, 5) + sweep(260, 60, 0.7) * decay(n, 3) * 0.7
sfx("enemy_die", x)

n = int(SR * 0.35)
sfx("enemy_alert", (sweep(180, 260, 0.35) * np.sign(sine(30, 0.35)) * 0.5 + noise(n) * 0.1) * env(n, 0.02, 0.15), 0.6)

d = 1.6
n = int(SR * d)
x = sweep(90, 45, d) * (0.6 + 0.4 * sine(18, d)) + lowpass(noise(n), 0.05) * 1.2
x = np.tanh(x * 2.0) * env(n, 0.05, 0.5)
sfx("boss_roar", x)

d = 1.4
n = int(SR * d)
x = sweep(150, 320, d) * (0.5 + 0.5 * np.sin(2 * np.pi * 11 * t(d))) * 0.5
spark = np.concatenate([sine(2093 + 300 * i, 0.12) * decay(int(SR * 0.12), 5) for i in range(int(d / 0.12) + 1)])
spark = np.pad(spark, (0, max(0, n - len(spark))))[:n]
x += spark * 0.4
sfx("chest_open", x * env(n, 0.05, 0.3))

notes = [392.0, 523.25, 659.25, 784.0, 1046.5]
x = np.concatenate([sine(f, 0.2) * decay(int(SR * 0.2), 2.5) for f in notes] + [(sine(523.25, 1.2) + sine(659.25, 1.2) + sine(784, 1.2) + sine(1046.5, 1.2)) * decay(int(SR * 1.2), 2.5)])
sfx("win", echo(x, 0.2, 0.3, 2))

notes = [392.0, 349.23, 311.13, 261.63]
x = np.concatenate([(sine(f, 0.4) + 0.5 * sine(f / 2, 0.4)) * decay(int(SR * 0.4), 2) for f in notes])
sfx("lose", x)

x = sine(880, 0.09) * env(int(SR * 0.09), 0.003, 0.05)
sfx("ui_click", x, 0.5)


# ---------------------------------------------------------------- músicas (loop)
def pad(freqs, d, vol=1.0):
    tt = t(d)
    x = np.zeros_like(tt)
    for f in freqs:
        for det in (-0.6, 0.0, 0.7):
            x += np.sin(2 * np.pi * (f + det) * tt + rng.uniform(0, 6.28)) * 0.33
        x += np.sin(2 * np.pi * f * 2 * tt) * 0.08
    return x * vol * env(len(tt), 0.8, 0.8)


def build_music(chords, bar, bass_oct=0.5, arp=None, arp_vol=0.0):
    parts = [pad(c, bar) for c in chords]
    total = np.concatenate(parts)
    bass = np.concatenate([sine(c[0] * bass_oct, bar) * env(int(SR * bar), 0.3, 0.6) * 0.5 for c in chords])
    mix = total + bass
    if arp:
        step = bar / 8
        notes_out = []
        for c in chords:
            for i in range(8):
                f = c[arp[i % len(arp)] % len(c)] * 2
                notes_out.append(sine(f, step) * decay(int(SR * step), 5) * arp_vol)
        arp_sig = np.concatenate(notes_out)
        m = min(len(mix), len(arp_sig))
        mix = mix[:m] + arp_sig[:m]
    fade = int(SR * 0.05)
    mix[:fade] *= np.linspace(0, 1, fade)
    mix[-fade:] *= np.linspace(1, 0, fade)
    return mix


A3, C4, E4, F3, G3, D4, B3, A2 = 220.0, 261.63, 329.63, 174.61, 196.0, 293.66, 246.94, 110.0
calm = [[A3, C4, E4], [F3, A3, C4], [C4, E4, G3 * 2], [G3, B3, D4]]
music("music_menu", build_music(calm, 6.0, 0.5, [0, 1, 2, 1, 2, 1, 0, 2], 0.12), 0.5)
music("music_game", build_music(calm, 5.0, 0.5, [0, 2, 1, 2], 0.10), 0.5)
tense = [[A3, C4, 311.13], [F3, 207.65, C4], [G3, 233.08, D4], [A3, C4, 311.13]]
music("music_boss", build_music(tense, 3.2, 0.5, [0, 1, 0, 2], 0.18), 0.6)
print("Pronto.")
