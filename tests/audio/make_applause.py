"""Rebuild assets/applause.wav from klankbeeld's recording.

    python Kanto-Contests/tests/audio/make_applause.py SOURCE.wav [--hold N] [--bits B] [--fade S] [--curve P] [--gain G] [--out PATH]

SOURCE is Freesound #189831 "audience clap yell outdoor 02" by klankbeeld
(https://freesound.org/s/189831/), 8.8 s stereo 48 kHz 24-bit -- not kept in
the repo (2.5 MB); download it again from the link. Credit line required by
the author is in THIRD_PARTY_NOTICES.md.

Kept versions (tests/ is excluded from the zip, so these never ship):
  applause_0.34.12_keeper.wav  --hold 2 --bits 3 --fade 0.6 --curve 2 --gain 0.97
    (recovered from git c104b30; the developer's pick, 2026-09-02. This IS the
    shipping clip from 0.34.18 on -- byte-identical. 0.34.17's EQ was dropped.)
  applause_0.34.13_keeper.wav  --hold 3 --bits 2 --fade 0.6 --curve 2 --gain 0.80
  applause_0.34.15.wav         --hold 3 --bits 2 --drive 3.2 --fade 1.1 --curve 1.5 --gain 0.80
    (0.34.14 was hold 4: the yell's 745 Hz mirrored to a 2 kHz "chime", a third
    above it. --postsmooth halved it but could not remove it, so the extra
    crush comes from --drive instead, which leaves the mirror tones where 0.34.13 had them.)
"""
import argparse, wave, numpy as np, os
ap = argparse.ArgumentParser()
ap.add_argument("source")
ap.add_argument("--hold", type=int, default=3, help="sample-and-hold factor at 11025 Hz (3 = ~3.7 kHz)")
ap.add_argument("--bits", type=int, default=2, help="amplitude bits (2 = 4 levels)")
ap.add_argument("--fade", type=float, default=0.6, help="tail fade seconds, applied AFTER the crunch")
ap.add_argument("--curve", type=float, default=2.0, help="fade curve exponent; lower = slower, gentler")
ap.add_argument("--gain", type=float, default=0.80, help="peak")
ap.add_argument("--drive", type=float, default=2.2,
                help="tanh saturation before the bit reduction; more = harder, squarer crush without "
                     "moving the hold's mirror tones (raising --hold does move them: 4 rang at 2 kHz)")
ap.add_argument("--smooth", action="store_true",
                help="average each hold block before holding (a low-pass): kills the pitched aliasing "
                     "tones raw sample-and-hold folds down -- 0.34.14 at hold 4 rang at ~2 kHz like a chime")
ap.add_argument("--postsmooth", action="store_true",
                help="moving average the width of the hold AFTER holding: removes the tones the staircase "
                     "mirrors around the hold rate (0.34.14's chime) while keeping the low-rate softness")
ap.add_argument("--dither", type=float, default=0.0,
                help="triangular dither before the bit reduction, as a fraction of one level (0.3 is gentle); "
                     "stops the quantiser locking onto tones")
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
if A.smooth:
    # low-pass by averaging each block, THEN hold: the same staircase rate,
    # without the fold-down tones raw decimation produces
    m = len(y) // A.hold * A.hold
    blocks = y[:m].reshape(-1, A.hold).mean(axis=1)
    y = np.repeat(blocks, A.hold)
else:
    y = np.repeat(y[::A.hold], A.hold)[:len(y)]          # raw sample-and-hold: the aliasy grit
if A.postsmooth:
    # reconstruction low-pass AFTER the hold: the staircase mirrors every
    # tone around the hold rate (the yell's 745 Hz became a 2013/3499 Hz
    # "chime" at hold 4); a moving average the width of the hold takes the
    # mirror images out and leaves the tone, the crunch and the softness
    k = np.ones(A.hold) / A.hold
    y = np.convolve(y, k, mode="same")
y = np.tanh(y / (np.abs(y).max() + 1e-9) * A.drive); y = y / np.abs(y).max()
q = 2 ** (A.bits - 1)
if A.dither > 0:
    rng = np.random.default_rng(189831)                   # seeded: the same file every run
    y = y + (rng.random(len(y)) - rng.random(len(y))) * (A.dither / q)   # triangular, sub-level
y = np.round(y * q) / q                                   # bit-depth reduction
fo = int(A.fade * target); t = np.linspace(0, 1, fo); y[-fo:] *= (1 - t) ** A.curve   # the tail, after the crunch
y = y * A.gain
pcm = (y * 32767).astype(np.int16)
o = wave.open(A.out, "wb"); o.setnchannels(1); o.setsampwidth(2); o.setframerate(target); o.writeframes(pcm.tobytes()); o.close()
bins = int(0.2 * target); env = [np.abs(pcm[i:i + bins]).max() / 32767 for i in range(0, len(pcm), bins)]
print(f"hold {A.hold} (~{target // A.hold} Hz)  bits {A.bits}  fade {A.fade}s ^{A.curve}  gain {A.gain}")
print(f"{len(pcm) / target:.2f} s, peak {np.abs(pcm).max() / 32767:.2f} -> {A.out}")
print("peak per 0.2 s:", " ".join(f"{e:.2f}" for e in env))
