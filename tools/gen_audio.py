"""Audio procédural : SFX et musiques originales, synthétisés avec numpy.

Ondes carrée / triangle / sinus / bruit, enveloppes ADSR, petites compositions
écrites ici même (progressions d'accords et motifs générés par graine fixe).
Sortie : WAV 16 bits mono 22 050 Hz (aucun encodeur OGG requis ; Godot compresse
les WAV en QOA à l'import).
"""
import os
import random
import struct
import wave
import zlib
from typing import Callable, Dict, List, Optional, Sequence, Tuple

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SEED = 20261111


def _rng(name: str) -> np.random.Generator:
    return np.random.default_rng(SEED ^ zlib.crc32(name.encode()))


def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(SR * dur)) / SR


def osc(kind: str, freq, dur: float, duty: float = 0.5, rng: Optional[np.random.Generator] = None) -> np.ndarray:
    """freq : nombre ou tableau (balayage)."""
    n = int(SR * dur)
    f = np.full(n, float(freq)) if np.isscalar(freq) else np.resize(np.asarray(freq, dtype=float), n)
    phase = np.cumsum(f) / SR
    frac = phase % 1.0
    if kind == "square":
        return np.where(frac < duty, 1.0, -1.0)
    if kind == "tri":
        return 4.0 * np.abs(frac - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * frac - 1.0
    if kind == "sine":
        return np.sin(2 * np.pi * phase)
    if kind == "noise":
        g = rng or _rng("noise")
        # bruit « échantillonné-bloqué » : la fréquence règle la couleur
        step = np.maximum(1, (SR / np.maximum(f, 1.0)).astype(int))
        idx = np.cumsum(1.0 / step).astype(int)
        table = g.uniform(-1, 1, idx[-1] + 2 if n else 2)
        return table[idx]
    raise ValueError(kind)


def adsr(n: int, a: float, d: float, s: float, r: float) -> np.ndarray:
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    env = np.full(n, s)
    if a_n:
        env[:a_n] = np.linspace(0, 1, a_n)[:n]
    if d_n and a_n < n:
        m = min(d_n, n - a_n)
        env[a_n:a_n + m] = np.linspace(1, s, d_n)[:m]
    if r_n:
        m = min(r_n, n)
        env[n - m:] *= np.linspace(1, 0, m)
    return env


def sweep(f0: float, f1: float, dur: float, curve: float = 1.0) -> np.ndarray:
    x = np.linspace(0, 1, int(SR * dur)) ** curve
    return f0 + (f1 - f0) * x


def decay(n: int, rate: float) -> np.ndarray:
    return np.exp(-np.arange(n) / SR * rate)


def mix(*parts: Tuple[np.ndarray, float]) -> np.ndarray:
    n = max(len(p) + int(o * SR) for p, o in parts)
    out = np.zeros(n)
    for p, o in parts:
        i = int(o * SR)
        out[i:i + len(p)] += p
    return out


def write_wav(path: str, data: np.ndarray, gain: float = 0.8) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = float(np.max(np.abs(data))) or 1.0
    pcm = np.clip(data / peak * gain, -1, 1)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((pcm * 32767).astype("<i2").tobytes())


# --- SFX -----------------------------------------------------------------------
def tone(kind: str, f0: float, f1: float, dur: float, a=0.005, d=0.05, s=0.5, r=0.05, duty=0.5, curve=1.0) -> np.ndarray:
    w = osc(kind, sweep(f0, f1, dur, curve), dur, duty)
    return w * adsr(len(w), a, d, s, r)


def burst(name: str, f0: float, f1: float, dur: float, rate: float = 18.0) -> np.ndarray:
    w = osc("noise", sweep(f0, f1, dur), dur, rng=_rng(name))
    return w * decay(len(w), rate)


def arp(kind: str, freqs: Sequence[float], step: float, duty=0.25, tail=0.12) -> np.ndarray:
    parts = [(tone(kind, f, f, step + tail, 0.004, 0.04, 0.5, tail, duty), i * step) for i, f in enumerate(freqs)]
    return mix(*parts)


def note_hz(semi: float) -> float:
    return 440.0 * 2 ** ((semi - 69) / 12.0)


def sfx_table() -> Dict[str, np.ndarray]:
    N = note_hz
    s: Dict[str, np.ndarray] = {}
    s["step_grass"] = burst("sg", 2600, 900, 0.07, 40) * 0.6
    s["step_dirt"] = burst("sd", 1400, 500, 0.08, 34) * 0.7
    s["step_wood"] = mix((tone("tri", 180, 120, 0.06, 0.001, 0.03, 0.2, 0.02), 0), (burst("sw", 2000, 900, 0.03, 60) * 0.4, 0))
    s["step_stone"] = mix((tone("square", 320, 240, 0.03, 0.001, 0.02, 0.2, 0.01, 0.3) * 0.4, 0), (burst("ss", 4200, 2000, 0.04, 60) * 0.5, 0))
    s["step_snow"] = burst("sn", 900, 2400, 0.10, 26) * 0.6
    s["hoe"] = mix((burst("hoe", 900, 300, 0.14, 22), 0), (tone("tri", 140, 70, 0.12, 0.001, 0.05, 0.2, 0.05), 0))
    s["water"] = mix((burst("wa", 5200, 2600, 0.30, 7) * 0.7, 0), (tone("sine", 900, 500, 0.22, 0.02, 0.1, 0.3, 0.1) * 0.3, 0.02))
    s["axe"] = mix((tone("tri", 240, 110, 0.10, 0.001, 0.04, 0.2, 0.04), 0), (burst("ax", 2400, 700, 0.07, 40) * 0.7, 0))
    s["tree_fall"] = mix((burst("tf", 1200, 200, 0.6, 5), 0), (tone("tri", 110, 45, 0.5, 0.01, 0.3, 0.3, 0.2), 0.05), (burst("tf2", 600, 150, 0.25, 12), 0.45))
    s["pick"] = mix((tone("square", 1250, 900, 0.05, 0.001, 0.03, 0.2, 0.02, 0.25) * 0.6, 0), (burst("pk", 5200, 2600, 0.05, 60) * 0.6, 0), (tone("tri", 190, 120, 0.07, 0.001, 0.04, 0.2, 0.03), 0))
    s["rock_break"] = mix((burst("rb", 1800, 300, 0.28, 12), 0), (tone("tri", 120, 50, 0.2, 0.001, 0.1, 0.2, 0.08), 0))
    s["scythe"] = burst("sc", 800, 5200, 0.16, 9) * np.linspace(0.2, 1, int(SR * 0.16)) ** 2
    s["sword"] = mix((burst("sw1", 1200, 6400, 0.12, 10) * 0.8, 0), (tone("saw", 900, 300, 0.1, 0.002, 0.05, 0.2, 0.04) * 0.25, 0.01))
    s["plant"] = mix((tone("tri", 300, 420, 0.06, 0.002, 0.03, 0.3, 0.02), 0), (burst("pl", 1800, 900, 0.05, 50) * 0.4, 0.02))
    s["harvest"] = arp("square", [N(72), N(76), N(79)], 0.045, 0.25, 0.08)
    s["pickup"] = arp("tri", [N(76), N(83)], 0.04, tail=0.07)
    s["cast"] = mix((burst("ca", 600, 4200, 0.25, 6) * np.linspace(0.3, 1, int(SR * 0.25)), 0), (tone("sine", 500, 1300, 0.25, 0.01, 0.1, 0.4, 0.1) * 0.25, 0))
    s["splash"] = mix((burst("sp", 3600, 800, 0.35, 9), 0), (tone("sine", 400, 150, 0.18, 0.001, 0.08, 0.2, 0.08) * 0.5, 0))
    s["bite"] = arp("square", [N(84), N(84)], 0.07, 0.125, 0.05)
    s["reel"] = np.concatenate([tone("square", 700 + i * 30, 700 + i * 30, 0.025, 0.001, 0.01, 0.4, 0.008, 0.2) for i in range(6)]) * 0.6
    s["fish_beat"] = tone("tri", N(79), N(79), 0.08, 0.002, 0.04, 0.3, 0.03)
    s["fish_perfect"] = arp("square", [N(84), N(88)], 0.04, 0.25, 0.08)
    s["fish_miss"] = tone("square", 190, 120, 0.16, 0.002, 0.08, 0.3, 0.06, 0.3)
    s["catch"] = arp("square", [N(72), N(76), N(79), N(84), N(88)], 0.06, 0.25, 0.18)
    s["line_snap"] = mix((tone("saw", 1400, 200, 0.12, 0.001, 0.05, 0.2, 0.05) * 0.6, 0), (burst("ls", 5000, 1000, 0.08, 40), 0))
    s["buy"] = arp("square", [N(88), N(93)], 0.05, 0.125, 0.12)
    s["coins"] = arp("square", [N(91), N(95), N(91), N(98)], 0.045, 0.125, 0.1)
    s["ui_click"] = tone("square", 880, 880, 0.035, 0.001, 0.02, 0.2, 0.01, 0.25) * 0.6
    s["ui_move"] = tone("tri", 660, 660, 0.03, 0.001, 0.02, 0.2, 0.01) * 0.6
    s["ui_open"] = arp("tri", [N(72), N(79)], 0.04, tail=0.06)
    s["ui_close"] = arp("tri", [N(79), N(72)], 0.04, tail=0.06)
    s["error"] = arp("square", [N(55), N(52)], 0.08, 0.3, 0.06) * 0.7
    s["text_blip"] = tone("square", 520, 520, 0.022, 0.001, 0.012, 0.2, 0.008, 0.25) * 0.45
    s["levelup"] = arp("square", [N(72), N(76), N(79), N(84), N(79), N(84), N(88)], 0.085, 0.25, 0.3)
    s["quest_done"] = arp("tri", [N(67), N(72), N(76), N(79), N(84)], 0.09, tail=0.35)
    s["heart"] = arp("sine", [N(81), N(88), N(93)], 0.08, tail=0.25)
    s["hurt"] = mix((tone("square", 320, 110, 0.18, 0.001, 0.08, 0.3, 0.06, 0.4), 0), (burst("hu", 1500, 500, 0.1, 25) * 0.5, 0))
    s["monster_hit"] = mix((tone("square", 240, 160, 0.07, 0.001, 0.04, 0.2, 0.02, 0.3), 0), (burst("mh", 2600, 900, 0.06, 45) * 0.7, 0))
    s["monster_die"] = mix((tone("square", 420, 60, 0.32, 0.001, 0.15, 0.3, 0.1, 0.3, 0.6), 0), (burst("md", 2200, 300, 0.3, 10) * 0.6, 0.02))
    s["shoot"] = tone("square", 1300, 500, 0.12, 0.001, 0.06, 0.3, 0.04, 0.2) * 0.6
    s["door"] = mix((tone("tri", 160, 110, 0.08, 0.001, 0.04, 0.3, 0.03), 0), (burst("do", 900, 400, 0.05, 50) * 0.5, 0), (tone("tri", 120, 90, 0.1, 0.001, 0.05, 0.3, 0.04), 0.14))
    s["chest"] = mix((tone("tri", 200, 320, 0.12, 0.005, 0.05, 0.4, 0.05), 0), (arp("square", [N(79), N(84)], 0.05, 0.125, 0.1) * 0.5, 0.1))
    s["sleep"] = arp("sine", [N(76), N(72), N(69), N(64), N(60)], 0.22, tail=0.5)
    s["rooster"] = mix((tone("saw", 520, 780, 0.12, 0.01, 0.05, 0.6, 0.03) * 0.5, 0), (tone("saw", 780, 700, 0.1, 0.01, 0.05, 0.6, 0.03) * 0.5, 0.14),
                       (tone("saw", 700, 900, 0.14, 0.01, 0.05, 0.6, 0.03) * 0.5, 0.26), (tone("saw", 900, 520, 0.4, 0.01, 0.1, 0.5, 0.2) * 0.5, 0.42))
    s["eat"] = np.concatenate([burst("eat%d" % i, 1600, 700, 0.07, 40) for i in range(3)])
    s["craft"] = mix((tone("tri", 200, 150, 0.05, 0.001, 0.03, 0.2, 0.02), 0), (tone("tri", 260, 200, 0.05, 0.001, 0.03, 0.2, 0.02), 0.09), (arp("square", [N(79), N(86)], 0.05, 0.25, 0.1) * 0.5, 0.18))
    s["furnace"] = burst("fu", 300, 900, 0.5, 4) * np.sin(np.linspace(0, np.pi, int(SR * 0.5)))
    s["machine_done"] = arp("square", [N(76), N(81)], 0.07, 0.125, 0.12) * 0.6
    bell_f = N(67)
    s["bell"] = sum(osc("sine", bell_f * m, 1.6) * decay(int(SR * 1.6), r) * g for m, r, g in ((1, 2.5, 1.0), (2.0, 3.5, 0.5), (2.76, 5, 0.35), (5.4, 8, 0.2)))
    s["bell_big"] = sum(osc("sine", N(48) * m, 2.6) * decay(int(SR * 2.6), r) * g for m, r, g in ((1, 1.5, 1.0), (2.0, 2.2, 0.6), (2.4, 3, 0.4), (3.0, 4, 0.3), (5.4, 6, 0.15)))
    s["thunder"] = mix((burst("th", 400, 60, 1.6, 2.5), 0), (burst("th2", 2000, 200, 0.2, 12) * 0.6, 0))
    s["explosion"] = mix((burst("ex", 900, 80, 0.7, 5), 0), (tone("tri", 110, 35, 0.5, 0.001, 0.2, 0.3, 0.2), 0))
    s["ladder"] = np.concatenate([tone("tri", 300 - i * 30, 280 - i * 30, 0.07, 0.001, 0.04, 0.2, 0.02) for i in range(4)])
    s["elevator"] = mix((tone("saw", 80, 140, 0.9, 0.05, 0.2, 0.5, 0.3) * 0.4, 0), (arp("square", [N(84)], 0.1, 0.25, 0.2) * 0.5, 0.85))
    s["cluck"] = np.concatenate([tone("square", 700, 500, 0.05, 0.002, 0.02, 0.4, 0.02, 0.3), np.zeros(int(SR * 0.04)), tone("square", 760, 560, 0.06, 0.002, 0.02, 0.4, 0.02, 0.3)]) * 0.6
    s["quack"] = np.concatenate([tone("saw", 420, 320, 0.09, 0.003, 0.03, 0.5, 0.03), np.zeros(int(SR * 0.03)), tone("saw", 400, 300, 0.1, 0.003, 0.03, 0.5, 0.04)]) * 0.5
    s["moo"] = tone("saw", 130, 105, 0.7, 0.08, 0.2, 0.6, 0.25) * (1 + 0.15 * np.sin(np.linspace(0, 30, int(SR * 0.7)))) * 0.5
    s["bleat"] = tone("saw", 420, 380, 0.45, 0.02, 0.1, 0.6, 0.15) * (1 + 0.5 * np.sign(np.sin(np.linspace(0, 90, int(SR * 0.45))))) * 0.35
    s["bark"] = np.concatenate([tone("saw", 300, 190, 0.09, 0.002, 0.04, 0.4, 0.03), np.zeros(int(SR * 0.06)), tone("saw", 320, 200, 0.1, 0.002, 0.04, 0.4, 0.04)]) * 0.55
    s["gift"] = arp("tri", [N(79), N(84), N(88)], 0.06, tail=0.15)
    s["fanfare"] = mix((arp("square", [N(67), N(72), N(76), N(79), N(76), N(79), N(84)], 0.11, 0.25, 0.4), 0), (arp("tri", [N(48), N(55), N(48), N(55), N(60)], 0.154, tail=0.3) * 0.6, 0))
    return s


# --- musique -----------------------------------------------------------------------
SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11], "mixo": [0, 2, 4, 5, 7, 9, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
}


class Song:
    def __init__(self, name: str, bpm: float, root: int, scale: str, beats: int = 4):
        self.name, self.bpm, self.root, self.scale, self.beats = name, bpm, root, SCALES[scale], beats
        self.beat = 60.0 / bpm
        self.events: List[Tuple[float, np.ndarray]] = []
        self.r = random.Random(SEED ^ zlib.crc32(name.encode()))
        self.bars = 0

    def deg(self, degree: int, octave: int = 0) -> float:
        """Degré de gamme (0 = tonique) → fréquence."""
        o, d = divmod(degree, 7)
        return note_hz(self.root + self.scale[d] + 12 * (o + octave))

    def play(self, t_beats: float, wave_: np.ndarray, vol: float) -> None:
        self.events.append((t_beats * self.beat, wave_ * vol))

    def lead(self, t: float, f: float, beats: float, kind: str = "square", vol: float = 0.22, duty: float = 0.25) -> None:
        d = beats * self.beat
        w = osc(kind, f * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * t_axis(d + 0.08))), d + 0.08, duty)
        self.play(t, w * adsr(len(w), 0.01, 0.08, 0.6, 0.08), vol)

    def bell(self, t: float, f: float, beats: float, vol: float = 0.25) -> None:
        d = max(beats * self.beat, 0.25) + 0.6
        w = osc("sine", f, d) + 0.4 * osc("sine", f * 2.0, d) + 0.2 * osc("sine", f * 3.01, d)
        self.play(t, w * decay(len(w), 4.0) * adsr(len(w), 0.003, 0.0, 1.0, 0.1), vol)

    def pad(self, t: float, freqs: Sequence[float], beats: float, vol: float = 0.07) -> None:
        d = beats * self.beat
        w = sum(osc("tri", f, d) for f in freqs)
        self.play(t, w * adsr(len(w), 0.12, 0.2, 0.8, 0.2), vol)

    def bass(self, t: float, f: float, beats: float, vol: float = 0.26) -> None:
        d = beats * self.beat
        w = osc("tri", f, d)
        self.play(t, w * adsr(len(w), 0.006, 0.1, 0.7, 0.05), vol)

    def pluck(self, t: float, f: float, vol: float = 0.12, duty: float = 0.125) -> None:
        d = 0.22
        w = osc("square", f, d, duty)
        self.play(t, w * decay(len(w), 14), vol)

    def kick(self, t: float, vol: float = 0.5) -> None:
        w = osc("sine", sweep(150, 45, 0.14, 0.5), 0.14)
        self.play(t, w * decay(len(w), 22), vol)

    def snare(self, t: float, vol: float = 0.2) -> None:
        w = osc("noise", 5000, 0.12, rng=_rng(self.name + "sn"))
        self.play(t, w * decay(len(w), 28), vol)

    def hat(self, t: float, vol: float = 0.07) -> None:
        w = osc("noise", 11000, 0.04, rng=_rng(self.name + "hh"))
        self.play(t, w * decay(len(w), 80), vol)

    def render(self) -> np.ndarray:
        total = int(self.bars * self.beats * self.beat * SR)
        out = np.zeros(total)
        for t, w in self.events:
            i = int(t * SR) % total
            n = len(w)
            if i + n <= total:
                out[i:i + n] += w
            else:  # la queue des notes finales revient au début : boucle sans couture
                k = total - i
                out[i:] += w[:k]
                rest = w[k:k + total]
                out[:len(rest)] += rest
        return out


def motif(song: Song, chord: Sequence[int], rhythm: Sequence[float], start: int, wander: int = 2) -> List[Tuple[float, int, float]]:
    """Mélodie d'une mesure : (temps, degré, durée). Vise les notes de l'accord sur les temps forts."""
    out = []
    t = 0.0
    deg = start
    tones = [c + 7 * k for k in (0, 1, 2) for c in chord]
    for dur in rhythm:
        if dur < 0:
            t += -dur
            continue
        if abs(t - round(t)) < 0.01 and int(round(t)) % 2 == 0:
            deg = min(tones, key=lambda x: abs(x - deg) + song.r.random() * 1.5)
        else:
            deg += song.r.choice([-wander, -1, -1, 1, 1, wander])
        deg = max(5, min(16, deg))
        out.append((t, deg, dur))
        t += dur
    return out


def compose(name: str, bpm: float, root: int, scale: str, prog_a: Sequence[int], prog_b: Sequence[int], form: str,
            style: Dict) -> np.ndarray:
    beats = style.get("beats", 4)
    s = Song(name, bpm, root, scale, beats)
    rhythms = style.get("rhythms", [[1, 0.5, 0.5, 1, 1], [0.5, 0.5, 1, 0.5, 0.5, 1], [1.5, 0.5, 1, 1], [2, 1, 1]])
    lead_kind = style.get("lead", "square")
    section_cache: Dict[str, List] = {}
    bar = 0
    for sec_i, sec in enumerate(form):
        prog = prog_a if sec in "Aa" else prog_b
        if sec.upper() not in section_cache:
            mel = []
            start = 9
            for ci, cd in enumerate(prog):
                chord = [cd, cd + 2, cd + 4]
                rh = s.r.choice(rhythms) if ci % 4 != 3 else rhythms[-1]
                rh = [x for x in rh]
                # ajuste la longueur de la mesure
                total = sum(abs(x) for x in rh)
                if total < beats:
                    rh.append(-(beats - total))
                m = motif(s, chord, rh, start, style.get("wander", 2))
                if m:
                    start = m[-1][1]
                mel.append(m)
            section_cache[sec.upper()] = mel
        mel = section_cache[sec.upper()]
        quiet = sec.islower()
        for ci, cd in enumerate(prog):
            t0 = bar * beats
            chord = [cd, cd + 2, cd + 4]
            # basse
            pat = style.get("bass", "root")
            if pat == "walk":
                for b in range(beats):
                    s.bass(t0 + b, s.deg(chord[(b * 2) % 3] if b % 2 else cd, -2), 0.9)
            elif pat == "waltz":
                s.bass(t0, s.deg(cd, -2), 0.95)
                for b in (1, 2):
                    s.pluck(t0 + b, s.deg(chord[1], -1), 0.09)
                    s.pluck(t0 + b, s.deg(chord[2], -1), 0.09)
            elif pat == "drone":
                s.bass(t0, s.deg(cd, -2), beats, 0.22)
            else:
                s.bass(t0, s.deg(cd, -2), beats / 2 - 0.1)
                s.bass(t0 + beats / 2, s.deg(cd + 4, -2) if ci % 2 else s.deg(cd, -2), beats / 2 - 0.1)
            # harmonie
            if style.get("pad", True):
                s.pad(t0, [s.deg(d, -1) for d in chord], beats, style.get("pad_vol", 0.06))
            ar = style.get("arp", 0)
            if ar and not quiet:
                n = int(beats * ar)
                for k in range(n):
                    s.pluck(t0 + k / ar, s.deg(chord[k % 3] + (7 if (k // 3) % 2 else 0), 0), style.get("arp_vol", 0.08))
            # mélodie
            if not (quiet and ci % 2 == 1):
                for (t, dg, du) in mel[ci]:
                    f = s.deg(dg, style.get("lead_oct", 0) - 1)
                    if lead_kind == "bell":
                        s.bell(t0 + t, f, du, style.get("lead_vol", 0.22))
                    else:
                        s.lead(t0 + t, f, du * 0.92, lead_kind, style.get("lead_vol", 0.2), style.get("duty", 0.25))
            # percussions
            dr = style.get("drums", "")
            if dr == "soft":
                s.kick(t0, 0.3)
                for b in range(beats):
                    s.hat(t0 + b + 0.5, 0.05)
            elif dr == "full" and not quiet:
                for b in range(beats):
                    if b % 2 == 0:
                        s.kick(t0 + b, 0.45)
                    else:
                        s.snare(t0 + b, 0.16)
                    s.hat(t0 + b, 0.05)
                    s.hat(t0 + b + 0.5, 0.07)
            elif dr == "mine":
                s.kick(t0, 0.3)
                if ci % 2:
                    s.snare(t0 + beats - 1, 0.08)
            bar += 1
    s.bars = bar
    return s.render()


def music_table() -> Dict[str, Callable[[], np.ndarray]]:
    # degrés d'accords : 0 = I, 3 = IV, 4 = V, 5 = vi…
    return {
        # printemps : clair, arpèges qui pétillent
        "spring": lambda: compose("spring", 104, 62, "major", [0, 4, 5, 3, 0, 4, 3, 4], [5, 3, 0, 4, 5, 3, 1, 4], "AABA",
                                  dict(arp=2, drums="soft", lead="square", duty=0.25)),
        # été : plus rapide, basse qui marche, batterie complète
        "summer": lambda: compose("summer", 118, 67, "mixo", [0, 6, 3, 0, 0, 6, 3, 4], [3, 0, 4, 5, 3, 0, 1, 4], "AABAb",
                                  dict(arp=2, drums="full", bass="walk", lead="square", duty=0.5, arp_vol=0.06,
                                       rhythms=[[0.5, 0.5, 0.5, 0.5, 1, 1], [1, 0.5, 0.5, 0.5, 0.5, 1], [0.75, 0.75, 0.5, 1, 1], [2, 2]])),
        # automne : dorien, triangle mélancolique
        "autumn": lambda: compose("autumn", 88, 57, "dorian", [0, 3, 6, 0, 0, 3, 4, 0], [5, 3, 0, 6, 5, 3, 4, 4], "AABA",
                                  dict(arp=1, drums="soft", lead="tri", lead_vol=0.3, pad_vol=0.08,
                                       rhythms=[[1.5, 0.5, 2], [1, 1, 1, 1], [2, 1, 1], [3, -1]])),
        # hiver : lydien, clochettes et silences
        "winter": lambda: compose("winter", 72, 65, "lydian", [0, 1, 0, 4, 5, 1, 0, 0], [3, 4, 5, 1, 3, 4, 0, 0], "AaBA",
                                  dict(arp=1, lead="bell", lead_vol=0.26, pad_vol=0.07, bass="drone", lead_oct=1,
                                       rhythms=[[1, 1, 2], [2, 2], [1, 0.5, 0.5, 2], [4]])),
        # nuit : mineur, très espacé
        "night": lambda: compose("night", 66, 57, "minor", [0, 5, 3, 4, 0, 5, 6, 0], [3, 6, 0, 4, 3, 6, 4, 0], "AaBa",
                                 dict(lead="bell", lead_vol=0.2, pad_vol=0.09, bass="drone", wander=1,
                                      rhythms=[[2, 2], [1, 1, 2], [3, -1], [4]])),
        # village : valse à trois temps
        "village": lambda: compose("village", 132, 60, "major", [0, 0, 3, 3, 4, 4, 0, 0, 5, 5, 3, 3, 1, 4, 0, 0],
                                   [3, 3, 0, 0, 4, 4, 5, 5, 3, 3, 0, 0, 1, 4, 0, 0], "ABA",
                                   dict(beats=3, bass="waltz", pad=False, lead="square", duty=0.5, lead_vol=0.2,
                                        rhythms=[[1, 1, 1], [2, 1], [1, 0.5, 0.5, 1], [3]])),
        # mine : phrygien, bourdon et percussions sourdes
        "mine": lambda: compose("mine", 80, 52, "phrygian", [0, 0, 1, 0, 0, 5, 1, 0], [3, 3, 1, 0, 6, 5, 1, 0], "AaBA",
                                dict(drums="mine", lead="tri", lead_vol=0.24, pad_vol=0.09, bass="drone", arp=1, arp_vol=0.05,
                                     wander=1, rhythms=[[1, -1, 1, 1], [0.5, 0.5, -1, 2], [2, -2], [1, 1, -2]])),
        # festival : danse rapide
        "festival": lambda: compose("festival", 138, 62, "major", [0, 3, 0, 4, 0, 3, 4, 0], [5, 3, 4, 0, 5, 3, 4, 4], "AABABA",
                                    dict(arp=2, drums="full", bass="walk", lead="square", duty=0.25, lead_vol=0.22,
                                         rhythms=[[0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1], [1, 0.5, 0.5, 1, 0.5, 0.5], [0.5, 0.5, 1, 0.5, 0.5, 1], [1, 1, 2]])),
        # titre : calme, cloches du carillon
        "title": lambda: compose("title", 84, 60, "major", [0, 5, 3, 4, 0, 5, 1, 4], [3, 4, 5, 0, 3, 4, 0, 0], "AABA",
                                 dict(arp=2, lead="bell", lead_vol=0.26, arp_vol=0.06, pad_vol=0.08, lead_oct=1,
                                      rhythms=[[1, 1, 2], [1.5, 0.5, 2], [1, 0.5, 0.5, 1, 1], [4]])),
    }


def main() -> Tuple[int, int]:
    sfx = sfx_table()
    for name, data in sfx.items():
        write_wav(os.path.join(OUT, "sfx", name + ".wav"), np.asarray(data, dtype=float), 0.75)
    songs = music_table()
    for name, fn in songs.items():
        data = fn()
        write_wav(os.path.join(OUT, "music", name + ".wav"), data, 0.7)
        print("  musique %-9s %5.1f s" % (name, len(data) / SR))
    return len(sfx), len(songs)


if __name__ == "__main__":
    a, b = main()
    print("audio : %d SFX, %d musiques" % (a, b))
