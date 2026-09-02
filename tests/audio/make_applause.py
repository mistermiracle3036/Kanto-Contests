"""Rebuild assets/applause.wav from klankbeeld's recording.

    python Kanto-Contests/tests/audio/make_applause.py SOURCE.wav [--hold N] [--bits B] [--fade S] [--curve P] [--gain G] [--out PATH]

SOURCE is Freesound #189831 "audience clap yell outdoor 02" by klankbeeld
(https://freesound.org/s/189831/), 8.8 s stereo 48 kHz 24-bit -- not kept in
the repo (2.5 MB); download it again from the link. Credit line required by
the author is in THIRD_PARTY_NOTICES.md.

Kept versions (tests/ is excluded from the zip, so these never ship):
  applause_0.34.13_keeper.wav  --hold 3 --bits 2 --fade 0.6 --curve 2 --gain 0.80
"""
import argparse, wave, numpy as np, os
ap = argparse.ArgumentParser()
ap.add_argument("source")
ap.add_argument("--hold", type=int, default=3, help="sample-and-hold factor at 11025 Hz (3 = ~3.7 kHz)")
ap.add_argument("--bits", type=int, default=2, help="amplitude bits (2 = 4 levels)")
ap.add_argument("--fade", type=float, default=0.6, help="tail fade seconds, applied AFTER the crunch")
ap.add_argument("--curve", type=float, default=2.0, help="fade curve exponent; lower = slower, gentler")
ap.add_argument("--gain", type=float, default=0.80, help="peak")
ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "assets", "applause.wav"))
A = ap.parse_args()

w = wave.open(A.source); n, rate, ch, sw = w.getnframes(), w.getframerate(), w.getnchannels(), w.getsampwidth(); raw = w.readframes(n); w.close()
assert sw == 3, "expected the 24-bit Freesound WAV"
a = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
ints = (a[:, 0].astype(np.int32) | (a[:, 1].astype(np.int32) << 8) | (a[:, 2].astype(np.int32) << 16))
ints = np.where(ints >= 1 << 23, ints - (1 << 24), ints)
x = (ints / (1 << 23)).reshape(-1, ch).mean(axis=1)

L = int(2.6 * rate)
yell = x[int(0.25 * rate):int(0.25 * rate) + L].copy()   # the opening: rise + the yell
clap = x[int(3.0 * rate):int(3.0 * rate) + L].copy()     # the clapping from 3 s
rms = lambda s: np.sqrt(np.mean(s ** 2))
clap *= (rms(yell) / rms(clap)) * 0.8                    # sits just under the yell
mix = yell + clap
mix[:int(0.02 * rate)] *= np.linspace(0, 1, int(0.02 * rate))

target = 11025; ratio = rate / target; blk = int(ratio)
idx = (np.arange(int(len(mix) / ratio)) * ratio).astype(int)
y = np.array([mix[i:i + blk].mean() for i in idx])
y = np.repeat(y[::A.hold], A.hold)[:len(y)]              # sample-and-hold: the aliasy grit
y = np.tanh(y / (np.abs(y).max() + 1e-9) * 2.2); y = y / np.abs(y).max()
q = 2 ** (A.bits - 1); y = np.round(y * q) / q            # bit-depth reduction
fo = int(A.fade * target); t = np.linspace(0, 1, fo); y[-fo:] *= (1 - t) ** A.curve   # the tail, after the crunch
y = y * A.gain
pcm = (y * 32767).astype(np.int16)
o = wave.open(A.out, "wb"); o.setnchannels(1); o.setsampwidth(2); o.setframerate(target); o.writeframes(pcm.tobytes()); o.close()
bins = int(0.2 * target); env = [np.abs(pcm[i:i + bins]).max() / 32767 for i in range(0, len(pcm), bins)]
print(f"hold {A.hold} (~{target // A.hold} Hz)  bits {A.bits}  fade {A.fade}s ^{A.curve}  gain {A.gain}")
print(f"{len(pcm) / target:.2f} s, peak {np.abs(pcm).max() / 32767:.2f} -> {A.out}")
print("peak per 0.2 s:", " ".join(f"{e:.2f}" for e in env))
