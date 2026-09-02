"""EQ a finished applause clip -- a post-stage on top of a KEPT clip, so the
base recipe is never re-derived.

    python tests/audio/eq_applause.py tests/audio/applause_0.34.12_keeper.wav
        [--lowshelf HZ DB] [--peak HZ Q DB] [--highshelf HZ DB] [--out PATH]

0.34.17: the developer chose 0.34.12's clip as "closest to perfect" and asked
for one thing on top: lows and mids a little quieter, a tiny lift up top, so it
sounds tinnier. Defaults are that request. Biquads are the RBJ cookbook forms
(no scipy on this machine); the result is re-normalised to the input's peak so
loudness does not move, only the balance.

Kept versions (tests/ never ships):
  applause_0.34.12_keeper.wav  the recovered 0.34.12 clip, untouched
                               (git c104b30 == Phone Test Builds zip, md5 f4185cb85b)
  applause_0.34.17.wav         that clip through this script's defaults --
                               tried once and DROPPED in 0.34.18; the plain
                               0.34.12 clip ships. Kept for the next request.
"""
import argparse, math, os, wave
import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument("source")
ap.add_argument("--lowshelf", nargs=2, type=float, default=(250, -4.0), metavar=("HZ", "DB"),
                help="shelf below HZ (default 250 Hz, -4 dB)")
ap.add_argument("--peak", nargs=3, type=float, default=(900, 1.0, -3.0), metavar=("HZ", "Q", "DB"),
                help="peaking cut/boost (default 900 Hz, Q 1.0, -3 dB: the mids)")
ap.add_argument("--highshelf", nargs=2, type=float, default=(2500, 3.0), metavar=("HZ", "DB"),
                help="shelf above HZ (default 2500 Hz, +3 dB: the tinny lift)")
ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "assets", "applause.wav"))
A = ap.parse_args()

w = wave.open(A.source); rate, n, ch, sw = w.getframerate(), w.getnframes(), w.getnchannels(), w.getsampwidth()
assert sw == 2 and ch == 1, "expected the mod's 16-bit mono clip"
x = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64) / 32767.0; w.close()

# --- RBJ cookbook biquads --------------------------------------------------
def shelf(f0, db, kind):
    A_ = 10 ** (db / 40); w0 = 2 * math.pi * f0 / rate; c, s = math.cos(w0), math.sin(w0)
    alpha = s / 2 * math.sqrt((A_ + 1 / A_) * (1 / 1.0 - 1) + 2)      # S = 1 (gentle slope)
    sq = 2 * math.sqrt(A_) * alpha
    if kind == "low":
        b0 = A_ * ((A_ + 1) - (A_ - 1) * c + sq); b1 = 2 * A_ * ((A_ - 1) - (A_ + 1) * c); b2 = A_ * ((A_ + 1) - (A_ - 1) * c - sq)
        a0 = (A_ + 1) + (A_ - 1) * c + sq;        a1 = -2 * ((A_ - 1) + (A_ + 1) * c);   a2 = (A_ + 1) + (A_ - 1) * c - sq
    else:
        b0 = A_ * ((A_ + 1) + (A_ - 1) * c + sq); b1 = -2 * A_ * ((A_ - 1) + (A_ + 1) * c); b2 = A_ * ((A_ + 1) + (A_ - 1) * c - sq)
        a0 = (A_ + 1) - (A_ - 1) * c + sq;        a1 = 2 * ((A_ - 1) - (A_ + 1) * c);    a2 = (A_ + 1) - (A_ - 1) * c - sq
    return np.array([b0, b1, b2]) / a0, np.array([1, a1 / a0, a2 / a0])

def peaking(f0, q, db):
    A_ = 10 ** (db / 40); w0 = 2 * math.pi * f0 / rate; alpha = math.sin(w0) / (2 * q); c = math.cos(w0)
    b = np.array([1 + alpha * A_, -2 * c, 1 - alpha * A_]); a = np.array([1 + alpha / A_, -2 * c, 1 - alpha / A_])
    return b / a[0], a / a[0]

def biquad(x, b, a):
    y = np.zeros_like(x); x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        v = b[0] * x[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        x2, x1, y2, y1 = x1, x[i], y1, v; y[i] = v
    return y

def bands(sig):
    spec = np.abs(np.fft.rfft(sig)) ** 2; f = np.fft.rfftfreq(len(sig), 1 / rate)
    tot = spec.sum()
    return {k: 10 * math.log10(spec[m].sum() / tot + 1e-12) for k, m in
            (("low <300", f < 300), ("mid 300-2000", (f >= 300) & (f < 2000)), ("high >2000", f >= 2000))}

peak_in = np.abs(x).max()
y = x
y = biquad(y, *shelf(A.lowshelf[0], A.lowshelf[1], "low"))
y = biquad(y, *peaking(A.peak[0], A.peak[1], A.peak[2]))
y = biquad(y, *shelf(A.highshelf[0], A.highshelf[1], "high"))
y = y / (np.abs(y).max() + 1e-12) * peak_in                            # same peak as the input
pcm = np.clip(np.round(y * 32767), -32768, 32767).astype(np.int16)
o = wave.open(A.out, "wb"); o.setnchannels(1); o.setsampwidth(2); o.setframerate(rate); o.writeframes(pcm.tobytes()); o.close()

bi, bo = bands(x), bands(y)
print(f"low shelf {A.lowshelf[0]:.0f} Hz {A.lowshelf[1]:+.1f} dB | peak {A.peak[0]:.0f} Hz Q{A.peak[1]:.1f} {A.peak[2]:+.1f} dB | high shelf {A.highshelf[0]:.0f} Hz {A.highshelf[1]:+.1f} dB")
print(f"{len(pcm) / rate:.2f} s, peak {np.abs(pcm).max() / 32767:.2f} -> {A.out}")
for k in bi: print(f"  {k:14s} share of energy: {bi[k]:+6.1f} dB -> {bo[k]:+6.1f} dB  ({bo[k] - bi[k]:+.1f})")
