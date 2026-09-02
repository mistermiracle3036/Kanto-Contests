"""Bake assets/ding.wav: the crowd's heart ding. ORIGINAL, synthesized here --
nothing in it is read from, rendered from, or derived from the cartridge.

    python tests/audio/make_ding.py [--note 932] [--duty 0.125] [--decay 0.55]
                                    [--highpass HZ] [--peak HZ Q DB] [--bits N] [--gain G]

Why a baked file: 0.34.20-0.34.22 rang the game's own ting through a
slowed clone of its LOVE source (the player's own game data, never shipped).
"Very tinny" is a filter, and LOVE's Source:setFilter needs an OpenAL
extension iOS does not ship -- and rendering the cart's sound program to a
WAV would put ROM-derived audio in the zip, which THIRD_PARTY_NOTICES.md
promises this mod never contains. So this is a plain chiptune bell of our
own: one pulse wave at a musical note, a linear-in-steps decay, then the
small-speaker treatment -- a steep high-pass so the fundamental thins out
and the odd harmonics carry the note, a resonant peak up top, a light bit
reduction. The default note (A#5, 932 Hz) is the pitch the developer
approved by ear on 0.34.22.

Kept versions (tests/ never ships):
  ding_0.34.23.wav   --note 932 --duty 0.125 --decay 0.55 --highpass 1800 --peak 3600 2.5 6 --bits 5
"""
import argparse, math, os, wave
import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument("--note", type=float, default=932.0, help="fundamental, Hz (932 = A#5)")
ap.add_argument("--duty", type=float, default=0.125, help="pulse duty; thinner = more tinny")
ap.add_argument("--decay", type=float, default=0.55, help="seconds from full to silent")
ap.add_argument("--steps", type=int, default=13, help="volume steps in the decay (a stair, like a chip envelope)")
ap.add_argument("--highpass", type=float, default=1800.0, help="4th-order high-pass corner, Hz")
ap.add_argument("--peak", nargs=3, type=float, default=(3600.0, 2.5, 6.0), metavar=("HZ", "Q", "DB"))
ap.add_argument("--bits", type=int, default=5, help="amplitude bits after filtering (5 = 32 levels)")
ap.add_argument("--gain", type=float, default=0.85, help="peak")
ap.add_argument("--rate", type=int, default=22050)
ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ding.wav"))
A = ap.parse_args()

rate = A.rate
dur = A.decay + 0.05
n = int(dur * rate); t = np.arange(n) / rate
vol = np.clip(A.steps - np.floor(t / (A.decay / A.steps)), 0, A.steps) / A.steps
phase = (t * A.note) % 1.0
x = np.where(phase < A.duty, 1.0, -1.0) * vol

def biquad(x, b, a):
    y = np.zeros_like(x); x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        v = b[0] * x[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        x2, x1, y2, y1 = x1, x[i], y1, v; y[i] = v
    return y
def highpass(f0, q=0.707):
    w0 = 2 * math.pi * f0 / rate; c = math.cos(w0); alpha = math.sin(w0) / (2 * q)
    b = np.array([(1 + c) / 2, -(1 + c), (1 + c) / 2]); a = np.array([1 + alpha, -2 * c, 1 - alpha])
    return b / a[0], a / a[0]
def peaking(f0, q, db):
    A_ = 10 ** (db / 40); w0 = 2 * math.pi * f0 / rate; alpha = math.sin(w0) / (2 * q); c = math.cos(w0)
    b = np.array([1 + alpha * A_, -2 * c, 1 - alpha * A_]); a = np.array([1 + alpha / A_, -2 * c, 1 - alpha / A_])
    return b / a[0], a / a[0]

y = biquad(x, *highpass(A.highpass))
y = biquad(y, *highpass(A.highpass))
y = biquad(y, *peaking(A.peak[0], A.peak[1], A.peak[2]))
y = y / (np.abs(y).max() + 1e-12)
q = 2 ** (A.bits - 1)
y = np.round(y * q) / q
fo = int(0.02 * rate); y[-fo:] *= np.linspace(1, 0, fo)
y = y * A.gain
pcm = (y * 32767).astype(np.int16)
o = wave.open(A.out, "wb"); o.setnchannels(1); o.setsampwidth(2); o.setframerate(rate); o.writeframes(pcm.tobytes()); o.close()

spec = np.abs(np.fft.rfft(pcm / 32767.0)) ** 2; f = np.fft.rfftfreq(len(pcm), 1 / rate); tot = spec.sum()
share = lambda m: 10 * math.log10(spec[m].sum() / tot + 1e-12)
print(f"{A.note:.0f} Hz pulse, duty {A.duty}, {dur:.2f} s, peak {np.abs(pcm).max() / 32767:.2f} -> {A.out}")
print(f"energy share: <1.2k {share(f < 1200):+.1f} dB | 1.2-3k {share((f >= 1200) & (f < 3000)):+.1f} dB | >3k {share(f >= 3000):+.1f} dB")
