#!/usr/bin/env python3
"""Streams the waveform and spectrum of whatever is playing, for the audio panel.

Reads the default output's monitor with parec (mono, 44.1 kHz), keeps a rolling
window of N samples and, ~30 times a second, prints one line:

    w <96 samples in -1..1> s <48 band levels in 0..1>

The spectrum is a Hann-windowed FFT, grouped into log-spaced bands from 40 Hz to
16 kHz and mapped from -70..0 dB to 0..1. Runs only while the panel is open.
"""

import ctypes
import signal
import subprocess
import sys

import numpy as np

RATE = 44100
N = 2048  # FFT window (~46 ms)
HOP = RATE // 30  # new samples per frame
BANDS = 48
WAVE_POINTS = 96
FLOOR_DB = -70


def die_with_parent():
    # parec gets SIGTERM if this script dies, so it never records on its own
    ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG


parec = subprocess.Popen(
    ["parec", "-d", "@DEFAULT_MONITOR@", "--format=s16le", f"--rate={RATE}", "--channels=1", "--latency-msec=30", "--raw"],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    preexec_fn=die_with_parent,
)


def stop(*_):
    parec.terminate()
    sys.exit(0)


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

window = np.hanning(N)
freqs = np.fft.rfftfreq(N, 1 / RATE)
# FFT bin range for each band (at least one bin each)
edges = np.searchsorted(freqs, np.geomspace(40, 16000, BANDS + 1))
ranges = [(a, max(b, a + 1)) for a, b in zip(edges[:-1], edges[1:])]

buf = np.zeros(N)
while True:
    data = parec.stdout.read(HOP * 2)
    if not data:
        break
    x = np.frombuffer(data, "<i2") / 32768.0
    buf = np.concatenate((buf[len(x):], x))

    # Amplitude spectrum, scaled so a full-scale sine reads ~0 dB
    mag = np.abs(np.fft.rfft(buf * window)) / (N / 4)
    bands = np.array([mag[a:b].max() for a, b in ranges])
    levels = np.clip((20 * np.log10(bands + 1e-9) - FLOOR_DB) / -FLOOR_DB, 0, 1)

    # The last ~1000 samples (~23 ms), every 10th
    wave = np.clip(buf[-WAVE_POINTS * 10 :: 10], -1, 1)

    try:
        print("w " + ",".join(f"{v:.2f}" for v in wave) + " s " + ",".join(f"{v:.2f}" for v in levels), flush=True)
    except BrokenPipeError:
        stop()

stop()
