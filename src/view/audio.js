/* =====================================================================
   AUDIO: a cozy, generative sound engine (Web Audio, no samples).
   - Warm master chain (gentle low-pass + soft compression + shared reverb)
   - Every effect is randomised (pitch, timing, filter, variant) and rate-limited
   - Positional effects: volume falls off and pans with distance from you
   - Generative music per zone and time of day, with a boss-fight layer
   - Ambient beds and events: wind, birds, crickets, owls, frogs, drips, anvil, fountain
   ===================================================================== */
const AU = { on: true, ctx: null, vol: { master: .8, music: .55, amb: .6, sfx: .75 }, steps: true };
let A = null;
function au() {
  if (AU.ctx) { if (AU.ctx.state === 'suspended') AU.ctx.resume().catch(() => { }); return AU.ctx; }
  try { const C = window.AudioContext || window.webkitAudioContext; if (!C) return null; AU.ctx = new C({ latencyHint: 'playback' }); buildGraph(AU.ctx); }
  catch (e) { AU.ctx = null; }
  return AU.ctx;
}
function makeIR(c, secs, decay) {
  const n = Math.floor(c.sampleRate * secs), b = c.createBuffer(2, n, c.sampleRate);
  for (let ch = 0; ch < 2; ch++) { const d = b.getChannelData(ch); let lp = 0; for (let i = 0; i < n; i++) { const t = i / n; lp = lp * .55 + (Math.random() * 2 - 1) * .45; d[i] = lp * Math.pow(1 - t, decay) * (i < c.sampleRate * .012 ? i / (c.sampleRate * .012) : 1); } }
  return b;
}
function makeNoise(c, pink) {
  const n = c.sampleRate * 3, b = c.createBuffer(1, n, c.sampleRate), d = b.getChannelData(0);
  let b0 = 0, b1 = 0, b2 = 0;
  for (let i = 0; i < n; i++) { const w = Math.random() * 2 - 1; if (pink) { b0 = .99765 * b0 + w * .099; b1 = .963 * b1 + w * .2965; b2 = .57 * b2 + w * 1.0527; d[i] = (b0 + b1 + b2 + w * .1848) * .18; } else d[i] = w; }
  return b;
}
function buildGraph(c) {
  const master = c.createGain(), warm = c.createBiquadFilter(), comp = c.createDynamicsCompressor();
  warm.type = 'lowpass'; warm.frequency.value = 8200; warm.Q.value = .4;
  comp.threshold.value = -20; comp.knee.value = 14; comp.ratio.value = 3; comp.attack.value = .012; comp.release.value = .3;
  master.connect(warm); warm.connect(comp); comp.connect(c.destination);
  const verb = c.createConvolver(); verb.buffer = makeIR(c, 3.2, 2.8);
  const verbOut = c.createGain(); verbOut.gain.value = .55; const verbTone = c.createBiquadFilter(); verbTone.type = 'lowpass'; verbTone.frequency.value = 4200;
  verb.connect(verbTone); verbTone.connect(verbOut); verbOut.connect(master);
  const bus = (send) => { const g = c.createGain(), s = c.createGain(); g.connect(master); s.gain.value = send; s.connect(verb); return [g, s]; };
  const [sfxB, sfxS] = bus(.22), [musB, musS] = bus(.5), [ambB, ambS] = bus(.35);
  const musTheme = c.createGain(); musTheme.gain.value = 0; musTheme.connect(musB); musTheme.connect(musS);
  A = { c, master, warm, verb, verbOut, sfx: sfxB, sfxSend: sfxS, music: musB, musicSend: musS, musTheme, amb: ambB, ambSend: ambS,
    white: makeNoise(c, false), pink: makeNoise(c, true), ks: new Map(), last: {}, voices: 0, beds: {}, ev: {}, mus: { theme: null, target: null, next: 0, bar: 0, phrase: 0, prog: null, switching: false } };
  applyVolumes();
}
function applyVolumes() {
  if (!A) return; const t = A.c.currentTime, v = AU.vol, on = AU.on ? 1 : 0;
  A.master.gain.setTargetAtTime(v.master * on * 2.1, t, .05);
  A.sfx.gain.setTargetAtTime(v.sfx, t, .05); A.sfxSend.gain.setTargetAtTime(v.sfx * .22, t, .05);
  A.music.gain.setTargetAtTime(v.music * .8, t, .1); A.musicSend.gain.setTargetAtTime(v.music * .45, t, .1);
  A.amb.gain.setTargetAtTime(v.amb, t, .1); A.ambSend.gain.setTargetAtTime(v.amb * .3, t, .1);
}
const rv = (v, s) => v * (1 + (Math.random() - .5) * (s == null ? .12 : s));
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
function kill(nodes, t) { setTimeout(() => { for (const n of nodes) try { n.disconnect(); } catch (e) { } }, Math.max(50, t * 1000 + 200)); }

/* ---------- primitives (all route into `out`) ---------- */
function envGain(t, a, peak, d, curve) { const g = A.c.createGain(); g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(peak, t + a); if (curve === 'lin') g.gain.linearRampToValueAtTime(0.0001, t + a + d); else g.gain.exponentialRampToValueAtTime(0.0001, t + a + d); return g; }
function tone(out, type, f0, f1, t, dur, peak, att) {
  const c = A.c, o = c.createOscillator(), g = envGain(t, att || .005, peak, dur);
  o.type = type; o.frequency.setValueAtTime(f0, t); if (f1 && f1 !== f0) o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + (att || .005) + dur);
  o.connect(g); g.connect(out); o.start(t); o.stop(t + (att || .005) + dur + .05); kill([o, g], t - c.currentTime + dur + .2); return o;
}
function noise(out, t, dur, peak, ftype, f0, q, f1, att, pink) {
  const c = A.c, s = c.createBufferSource(); s.buffer = pink ? A.pink : A.white; const off = Math.random() * 2;
  const f = c.createBiquadFilter(); f.type = ftype || 'bandpass'; f.frequency.setValueAtTime(f0 || 1000, t); if (f1) f.frequency.exponentialRampToValueAtTime(f1, t + dur); f.Q.value = q == null ? 1 : q;
  const g = envGain(t, att || .004, peak, dur); s.connect(f); f.connect(g); g.connect(out); s.start(t, off, dur + (att || 0) + .1); kill([s, f, g], t - c.currentTime + dur + .3);
}
function ksBuf(freq, bright, dur) {
  const key = Math.round(freq * 4) + '|' + bright; let b = A.ks.get(key); if (b) return b;
  const c = A.c, sr = c.sampleRate, n = Math.floor(sr * (dur || 2.2)), p = Math.max(2, Math.round(sr / freq));
  b = c.createBuffer(1, n, sr); const d = b.getChannelData(0); const ring = new Float32Array(p);
  for (let i = 0; i < p; i++) ring[i] = Math.random() * 2 - 1;
  for (let pass = 0; pass < (bright > .6 ? 1 : 3); pass++) for (let i = 1; i < p; i++) ring[i] = (ring[i] + ring[i - 1]) * .5; // soften the attack
  const damp = .4985 + bright * .0012; let ix = 0;
  for (let i = 0; i < n; i++) { const a = ring[ix], nx = ring[(ix + 1) % p]; d[i] = a; ring[ix] = (a + nx) * damp; ix = (ix + 1) % p; }
  if (A.ks.size > 90) A.ks.delete(A.ks.keys().next().value);
  A.ks.set(key, b); return b;
}
function pluck(out, freq, t, vel, bright, pan, lp) {
  const c = A.c, s = c.createBufferSource(); s.buffer = ksBuf(freq, bright == null ? .5 : bright);
  const f = c.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lp || 3200; const g = c.createGain(); g.gain.value = vel;
  let last = g; s.connect(f); f.connect(g);
  if (pan && c.createStereoPanner) { const p = c.createStereoPanner(); p.pan.value = pan; g.connect(p); last = p; }
  last.connect(out); s.start(t); kill([s, f, g, last], t - c.currentTime + 2.4);
}
function bell(out, freq, t, vel, dec, parts) {
  for (const [r, a, dd] of parts || [[1, 1, 1], [2.0, .45, .6], [3.01, .25, .4], [4.2, .12, .25]]) tone(out, 'sine', freq * r, null, t, (dec || 1) * dd, vel * a, .003);
}

/* ---------- positional output ---------- */
function voice(src, range) {
  let g = 1, pan = 0;
  if (src && S.player && src !== S.player && src.x != null) { const dx = src.x - S.player.x, dy = src.y - S.player.y, d = Math.hypot(dx, dy * 1.2); const R2 = range || 18; if (d > R2) return null; g = Math.pow(Math.max(0, 1 - d / R2), 1.4); pan = clamp(dx / 11, -.8, .8); }
  if (g < .03) return null;
  const c = A.c, gn = c.createGain(); gn.gain.value = g; let last = gn;
  if (pan && c.createStereoPanner) { const p = c.createStereoPanner(); p.pan.value = pan; gn.connect(p); last = p; }
  last.connect(A.sfx); last.connect(A.sfxSend); kill([gn, last], 4); return gn;
}
const SFX_GAP = { hit: .045, swing: .05, miss: .08, hurt: .09, gold: .07, pickup: .06, click: .035, whisper: .6, error: .2, step: .12, mdie: .06, aggro: .5, heal: .12, fire: .06, portal: .3, rare: .25, arrow: .06, drink: .12 };
function sfx(n, src) {
  if (!AU.on || !A || A.c.state !== 'running') return;
  const now = A.c.currentTime; const key = n + (src && src.id ? '' : ''); const gap = SFX_GAP[n] || .04;
  if (A.last[key] && now - A.last[key] < gap) return; A.last[key] = now;
  if (A.voices > 34) return;
  const out = voice(src); if (!out) return;
  A.voices++; setTimeout(() => A.voices--, 700);
  try { (SFX[n] || SFX.click)(out, now + .005, src); } catch (e) { }
}

/* ---------- effect designs ---------- */
const PENTA = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21];
function chimeRun(out, t, root, n, step, vel, dec, up) { let deg = Math.floor(Math.random() * 3); for (let i = 0; i < n; i++) { bell(out, mtof(root + PENTA[Math.min(PENTA.length - 1, deg)]), t + i * step * rv(1, .3), vel * rv(1, .3), dec, [[1, 1, 1], [2.0, .3, .5], [3.0, .12, .3]]); deg += up === false ? -1 : 1 + (Math.random() < .3 ? 1 : 0); if (deg < 0) deg = 0; } }
const SURF = () => { const m = S.map, p = S.player; if (!m || !p) return 'grass'; const gg = m.g[idx(m, p.x, p.y)]; return gg === G.PAVE || gg === G.ROAD || gg === G.TFLOOR || gg === G.CARPET || gg === G.ABYSS ? 'stone' : gg === G.CAVE || gg === G.CAVE2 ? 'cave' : gg === G.DIRT || gg === G.FARM || gg === G.SAND ? 'dirt' : gg === G.WATER ? 'water' : 'grass'; };
const SFX = {
  swing: (o, t) => { const f = rv(520, .3); noise(o, t, rv(.17, .2), rv(.09, .3), 'bandpass', f, .9, f * rv(3, .3), .03); },
  miss: (o, t) => noise(o, t, .14, .04, 'bandpass', rv(900), .7, rv(2600), .03),
  hit: (o, t, src) => { tone(o, 'sine', rv(150, .25), 50, t, rv(.13, .2), rv(.3, .2)); noise(o, t, rv(.07, .3), rv(.16, .3), 'lowpass', rv(1100, .4), .7); if (Math.random() < .4) noise(o, t + .01, .05, .05, 'bandpass', rv(2400, .3), 3); },
  hurt: (o, t) => { tone(o, 'sine', rv(120, .2), 55, t, .2, .28); noise(o, t, .14, .14, 'lowpass', rv(500, .3), .8); noise(o, t + .02, .1, .03, 'bandpass', rv(800, .2), 4); },
  fire: (o, t) => { noise(o, t, rv(.5, .2), rv(.16, .2), 'lowpass', rv(280), .8, rv(1600, .3), .07, true); for (let i = 0; i < 6; i++) noise(o, t + Math.random() * .45, .012, rv(.05, .6), 'highpass', rv(3500, .4), .7); },
  thunder: (o, t) => { noise(o, t, .09, .3, 'highpass', rv(1800), .6); noise(o, t + .02, rv(1.6, .2), .34, 'lowpass', rv(170, .2), .7, 60, .03, true); tone(o, 'sine', rv(70), 38, t + .03, 1.1, .2, .02); },
  ice: (o, t) => { chimeRun(o, t, 84 + Math.floor(Math.random() * 5), 5, .045, .045, .6); noise(o, t, .5, .035, 'highpass', 6500, .5); },
  heal: (o, t) => { const root = 72 + [0, 2, 5, 7][Math.floor(Math.random() * 4)]; chimeRun(o, t, root, 3, .09, .06, 1.2); tone(o, 'sine', mtof(root - 12), null, t, .9, .04, .25); },
  buff: (o, t) => { chimeRun(o, t, 76 + Math.floor(Math.random() * 3), 4, .06, .045, .9); noise(o, t, .6, .03, 'bandpass', 3000, .6, 7000, .2); },
  level: (o, t) => { const root = 60 + [0, 2, 5, 7][Math.floor(Math.random() * 4)]; [0, 4, 7, 12, 16, 19].forEach((s2, i) => pluck(o, mtof(root + s2), t + i * .085, .32, .55, (i - 2.5) * .12)); [0, 4, 7, 12].forEach(s2 => tone(o, 'triangle', mtof(root - 12 + s2), null, t, 1.6, .035, .5)); chimeRun(o, t + .55, root + 24, 4, .07, .04, 1.1); },
  gold: (o, t) => { const n = 2 + (Math.random() * 2 | 0); for (let i = 0; i < n; i++) bell(o, rv(2600, .35), t + i * rv(.06, .4), rv(.05, .3), .18, [[1, 1, 1], [2.76, .4, .5], [5.4, .15, .3]]); },
  pickup: (o, t) => { noise(o, t, .09, .1, 'bandpass', rv(700, .3), .8, null, .01, true); pluck(o, mtof(76 + PENTA[Math.random() * 5 | 0]), t + .03, .12, .7); },
  rare: (o, t) => { chimeRun(o, t, 79 + (Math.random() * 3 | 0), 6, .07, .06, 1.4); tone(o, 'sine', mtof(55), null, t, 1.6, .05, .3); noise(o, t, 1.2, .025, 'bandpass', 5000, .5, 9000, .3); },
  mythic: (o, t) => { SFX.rare(o, t); [43, 50, 55, 59].forEach(m => { tone(o, 'sawtooth', mtof(m) * rv(1, .01), null, t, 2.4, .012, 1); }); bell(o, 110, t + .1, .12, 3.5, [[1, 1, 1], [2.4, .5, .6], [3.9, .3, .4]]); },
  portal: (o, t) => { noise(o, t, 1.1, .1, 'bandpass', 220, 1.2, rv(1800), .45, true); tone(o, 'sine', rv(180), rv(420), t, 1, .06, .4); chimeRun(o, t + .3, 84, 3, .1, .025, .8); },
  die: (o, t) => { [45, 48, 52, 57].forEach((m, i) => tone(o, 'triangle', mtof(m), null, t + i * .05, 3, .05, .6)); noise(o, t, 1.8, .05, 'lowpass', 300, .5, 120, .4, true); },
  click: (o, t) => { noise(o, t, .025, .05, 'bandpass', rv(2400, .3), 3); tone(o, 'sine', rv(1300, .2), 900, t, .03, .015); },
  paper: (o, t) => noise(o, t, rv(.14, .3), .035, 'bandpass', rv(3200, .3), .7, rv(1800), .02),
  error: (o, t) => { tone(o, 'triangle', 220, 190, t, .1, .06); tone(o, 'triangle', 196, 170, t + .1, .12, .05); },
  boss: (o, t) => { for (const [m, d] of [[31, 0], [38, .02]]) { const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .45, .14, 2.2); os.type = 'sawtooth'; os.frequency.value = mtof(m); f.type = 'lowpass'; f.frequency.setValueAtTime(200, t); f.frequency.linearRampToValueAtTime(700, t + .6); f.frequency.linearRampToValueAtTime(250, t + 2.4); os.connect(f); f.connect(g); g.connect(o); os.start(t + d); os.stop(t + 2.8); kill([os, f, g], 3.2); } MUSIC_DRUM(o, t, .5); MUSIC_DRUM(o, t + .5, .35); },
  whisper: (o, t) => { const r = 81 + [0, 2, 4][Math.random() * 3 | 0]; bell(o, mtof(r), t, .03, .8, [[1, 1, 1], [2, .3, .5]]); bell(o, mtof(r + 5), t + .11, .025, .9, [[1, 1, 1], [2, .3, .5]]); },
  arrow: (o, t) => { pluck(o, rv(170, .15), t, .12, .9, 0, 2500); noise(o, t + .02, .16, .05, 'bandpass', 1200, 1, 3200, .03); },
  drink: (o, t) => { for (let i = 0; i < 3 + (Math.random() * 2 | 0); i++) tone(o, 'sine', rv(280, .3), rv(620, .3), t + i * rv(.09, .5), .05, .05, .005); },
  step: (o, t) => {
    const s = SURF(); const L = Math.random() < .5 ? -1 : 1;
    if (s === 'grass') noise(o, t, rv(.07, .3), rv(.045, .3), 'lowpass', rv(900, .3), .6, null, .01, true);
    else if (s === 'dirt') noise(o, t, rv(.06, .3), rv(.05, .3), 'lowpass', rv(520, .3), .8, null, .005, true);
    else if (s === 'water') noise(o, t, .12, .05, 'bandpass', rv(900, .4), 1.5, rv(500), .01);
    else { noise(o, t, rv(.045, .3), rv(.05, .3), 'bandpass', rv(1500, .3), 1.1, null, .002); tone(o, 'sine', rv(180, .2), 90, t, .04, .03); }
  },
  mdie: (o, t, e) => { CREATURE(o, t, e, 'die'); tone(o, 'sine', rv(95, .2), 40, t, .22, .18); noise(o, t, .18, .08, 'lowpass', 500, .7, null, .01, true); },
  aggro: (o, t, e) => CREATURE(o, t, e, 'aggro'),
  mhit: (o, t) => { tone(o, 'sine', rv(130, .3), 55, t, .1, .14); noise(o, t, .06, .07, 'lowpass', rv(900, .4), .7); },
};
function CREATURE(o, t, e, why) {
  const d = e && e.def; if (!d) return; const big = d.boss ? 1 : 0; const sz = d.size || 1;
  const kind = d.boss ? 'roar' : d.body === 'hen' ? 'hen' : d.body === 'quad' ? (d.tusks ? 'boar' : 'deer') : d.body === 'flyer' ? (d.moth ? 'moth' : 'bat') : d.body === 'spider' || d.body === 'snake' ? 'hiss' : d.body === 'worm' ? 'squelch' : d.bone ? 'rattle' : d.hunch ? 'groan' : d.stone ? 'grind' : d.ears === 1 ? 'cat' : 'gibber';
  switch (kind) {
    case 'hen': for (let i = 0; i < (why === 'die' ? 2 : 3); i++) { noise(o, t + i * rv(.09, .3), .05, .05, 'bandpass', rv(1300, .2), 5); tone(o, 'triangle', rv(760, .2), rv(520, .2), t + i * .09, .05, .03); } break;
    case 'deer': { const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .04, .045, .35); os.type = 'sawtooth'; os.frequency.setValueAtTime(rv(460, .1), t); os.frequency.linearRampToValueAtTime(rv(380, .1), t + .38); f.type = 'bandpass'; f.frequency.value = 1100; f.Q.value = 2; os.connect(f); f.connect(g); g.connect(o); os.start(t); os.stop(t + .5); kill([os, f, g], .8); break; }
    case 'boar': for (let i = 0; i < 2; i++) noise(o, t + i * .14, rv(.12, .2), .09, 'bandpass', rv(240, .2), 2.5, 180, .02, true); break;
    case 'bat': tone(o, 'sine', rv(3800, .1), rv(3000, .1), t, .05, .025); tone(o, 'sine', rv(4000, .1), rv(3200, .1), t + .08, .05, .02); break;
    case 'moth': for (let i = 0; i < 5; i++) noise(o, t + i * .035, .025, .03, 'bandpass', 600, 1, null, .004, true); break;
    case 'hiss': noise(o, t, rv(.4, .3), .045, 'highpass', rv(3600, .2), .7, null, .05); break;
    case 'squelch': noise(o, t, .25, .08, 'lowpass', 320, 3, 150, .03, true); break;
    case 'rattle': for (let i = 0; i < 7; i++) noise(o, t + Math.random() * .22, .018, rv(.05, .5), 'bandpass', rv(2600, .3), 4); break;
    case 'groan': { const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .15, .05, .8, 'lin'); os.type = 'sawtooth'; os.frequency.setValueAtTime(rv(95, .1), t); os.frequency.linearRampToValueAtTime(rv(70, .1), t + .9); f.type = 'bandpass'; f.frequency.value = 480; f.Q.value = 3; os.connect(f); f.connect(g); g.connect(o); os.start(t); os.stop(t + 1.1); kill([os, f, g], 1.4); break; }
    case 'grind': noise(o, t, .55, .08, 'lowpass', 260, .9, 120, .08, true); tone(o, 'sine', 55, 45, t, .5, .06, .1); break;
    case 'cat': { const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .03, .03, .3); os.type = 'triangle'; os.frequency.setValueAtTime(rv(600, .15), t); os.frequency.linearRampToValueAtTime(rv(900, .15), t + .12); os.frequency.linearRampToValueAtTime(rv(500, .15), t + .32); f.type = 'bandpass'; f.frequency.value = 1500; f.Q.value = 1.2; os.connect(f); f.connect(g); g.connect(o); os.start(t); os.stop(t + .45); kill([os, f, g], .8); break; }
    case 'gibber': for (let i = 0; i < 3; i++) { const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t + i * .08, .01, .035, .07); os.type = 'sawtooth'; os.frequency.value = rv(210 / sz, .3); f.type = 'bandpass'; f.frequency.value = rv(900, .3); f.Q.value = 4; os.connect(f); f.connect(g); g.connect(o); os.start(t + i * .08); os.stop(t + i * .08 + .12); kill([os, f, g], .6); } break;
    case 'roar': { noise(o, t, 1.3, .2, 'lowpass', 420, 1, 160, .15, true); const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .2, .12, 1.2); os.type = 'sawtooth'; os.frequency.setValueAtTime(rv(75, .1), t); os.frequency.linearRampToValueAtTime(48, t + 1.3); f.type = 'lowpass'; f.frequency.value = 520; os.connect(f); f.connect(g); g.connect(o); os.start(t); os.stop(t + 1.5); kill([os, f, g], 1.8); break; }
  }
}

/* =================== MUSIC =================== */
function MUSIC_DRUM(o, t, vel) { tone(o, 'sine', 95, 42, t, .55, vel * .45, .004); noise(o, t, .25, vel * .18, 'lowpass', 260, .7, 90, .003, true); }
function mPad(notes, t, dur, vel, cut, type) {
  const c = A.c; const f = c.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = cut || 1100; f.Q.value = .3;
  const g = c.createGain(); g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(vel, t + Math.min(1.6, dur * .4)); g.gain.setValueAtTime(vel, t + dur * .7); g.gain.linearRampToValueAtTime(0.0001, t + dur + .8);
  f.connect(g); g.connect(A.musTheme); const oscs = [];
  for (const m of notes) for (const det of [-5, 5]) { const o = c.createOscillator(); o.type = type || 'triangle'; o.frequency.value = mtof(m); o.detune.value = det + (Math.random() - .5) * 4; o.connect(f); o.start(t); o.stop(t + dur + 1); oscs.push(o); }
  kill([...oscs, f, g], t - c.currentTime + dur + 1.2);
}
function mHarp(m, t, vel, pan) { pluck(A.musTheme, mtof(m), t, vel, .45, pan == null ? (Math.random() - .5) * .5 : pan, 3000); }
function mFlute(m, t, dur, vel) {
  const c = A.c, o = c.createOscillator(), o2 = c.createOscillator(), g = c.createGain(), lfo = c.createOscillator(), lg = c.createGain();
  o.type = 'sine'; o2.type = 'triangle'; o.frequency.value = mtof(m); o2.frequency.value = mtof(m); const g2 = c.createGain(); g2.gain.value = .18;
  lfo.frequency.value = rv(5, .15); lg.gain.setValueAtTime(0, t); lg.gain.linearRampToValueAtTime(mtof(m) * .006, t + Math.min(.5, dur)); lfo.connect(lg); lg.connect(o.frequency); lg.connect(o2.frequency);
  g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(vel, t + .07); g.gain.setValueAtTime(vel * .85, t + dur * .8); g.gain.linearRampToValueAtTime(0.0001, t + dur + .12);
  o.connect(g); o2.connect(g2); g2.connect(g); g.connect(A.musTheme); for (const x of [o, o2, lfo]) { x.start(t); x.stop(t + dur + .2); }
  noise(A.musTheme, t, Math.min(.12, dur), vel * .25, 'bandpass', mtof(m) * 2, 6, null, .03);
  kill([o, o2, g, g2, lfo, lg], t - c.currentTime + dur + .4);
}
function mKalimba(m, t, vel) { const f = mtof(m); tone(A.musTheme, 'sine', f, null, t, 1.1, vel, .003); tone(A.musTheme, 'sine', f * 4.1, null, t, .18, vel * .18, .002); tone(A.musTheme, 'triangle', f * 2, null, t, .4, vel * .1, .003); }
function mChoir(notes, t, dur, vel) {
  const c = A.c;
  for (const m of notes) for (const [fr, q, a] of [[720, 5, 1], [1180, 6, .5]]) { const o = c.createOscillator(), f = c.createBiquadFilter(), g = c.createGain(), lfo = c.createOscillator(), lg = c.createGain(); o.type = 'sawtooth'; o.frequency.value = mtof(m); o.detune.value = (Math.random() - .5) * 12; lfo.frequency.value = rv(4.6, .2); lg.gain.value = 3; lfo.connect(lg); lg.connect(o.detune); f.type = 'bandpass'; f.frequency.value = fr; f.Q.value = q; g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(vel * a, t + 2); g.gain.setValueAtTime(vel * a, t + dur * .75); g.gain.linearRampToValueAtTime(0.0001, t + dur + 1.2); o.connect(f); f.connect(g); g.connect(A.musTheme); o.start(t); lfo.start(t); o.stop(t + dur + 1.4); lfo.stop(t + dur + 1.4); kill([o, f, g, lfo, lg], t - c.currentTime + dur + 1.6); }
}
function mBass(m, t, dur, vel) { pluck(A.musTheme, mtof(m), t, vel, .25, 0, 700); tone(A.musTheme, 'sine', mtof(m), null, t, dur, vel * .25, .02); }
function mBell(m, t, vel) { bell(A.musTheme, mtof(m), t, vel, 2.2, [[1, 1, 1], [2.76, .35, .5], [5.4, .12, .3]]); }

/* Themes: chords are semitone offsets from root; scale is for melodies. */
const THEMES = {
  title: { root: 62, bpm: 60, scale: [0, 2, 4, 7, 9, 12, 14, 16], progs: [[[0, 4, 7, 11], [-3, 0, 4, 7], [-7, -3, 0, 4], [-5, -1, 2, 7]]], lead: 'harp', mel: 'flute', arp: .5, melP: .5, pad: 1100 },
  town_day: { root: 62, bpm: 70, scale: [0, 2, 4, 7, 9, 12, 14, 16, 19], progs: [[[0, 4, 7, 11], [-3, 0, 4, 7], [-7, -3, 0, 4], [-5, -1, 2, 7]], [[-7, -3, 0, 4], [0, 4, 7, 11], [-5, -1, 2, 7], [-3, 0, 4, 7]], [[0, 4, 7, 14], [-7, -3, 0, 7], [-3, 0, 4, 9], [-5, -1, 2, 9]]], lead: 'harp', mel: 'flute', arp: .72, melP: .55, pad: 1200, bass: 1 },
  field_day: { root: 55, bpm: 76, scale: [0, 2, 4, 7, 9, 12, 14, 16], progs: [[[0, 4, 7], [7, 11, 14], [9, 12, 16], [5, 9, 12]], [[5, 9, 12], [0, 4, 7], [7, 11, 14], [4, 7, 11]]], lead: 'harp', mel: 'flute', arp: .6, melP: .6, pad: 1300, bass: 1 },
  night: { root: 57, bpm: 58, scale: [0, 3, 5, 7, 10, 12, 15], progs: [[[0, 3, 7, 10], [5, 9, 12, 15], [-2, 2, 5, 9], [0, 3, 7, 14]], [[-4, 0, 3, 7], [-2, 2, 5, 9], [0, 3, 7, 10], [0, 3, 7, 10]]], lead: 'harp', mel: 'kalimba', arp: .35, melP: .45, pad: 800 },
  mine: { root: 38, bpm: 48, scale: [0, 1, 5, 7, 8, 12, 13], drone: 1, progs: [[[0, 7], [0, 7], [1, 8], [0, 7]]], lead: 'lowharp', mel: 'bell', arp: .22, melP: .35, pad: 500 },
  forest: { root: 52, bpm: 64, scale: [0, 2, 3, 7, 9, 10, 12, 14, 15], progs: [[[0, 3, 7, 10], [5, 9, 12, 15], [0, 3, 7, 10], [-2, 2, 5, 9]], [[3, 7, 10, 14], [-2, 2, 5, 9], [0, 3, 7, 10], [5, 9, 12, 16]]], lead: 'kalimba', mel: 'flute', arp: .55, melP: .45, pad: 900, bass: 1 },
  temple: { root: 48, bpm: 54, scale: [0, 2, 3, 7, 8, 12, 14, 15], choir: 1, progs: [[[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -1, 2]], [[0, 3, 7], [5, 8, 12], [-4, 0, 3], [-5, 2, 7]]], lead: 'lowharp', mel: 'bell', arp: .3, melP: .35, pad: 700, drum: .5 },
  sanctum: { root: 47, bpm: 52, scale: [0, 1, 3, 6, 7, 10, 12], choir: 1, drone: 1, progs: [[[0, 3, 6], [1, 5, 8], [0, 3, 7], [-2, 1, 5]]], lead: 'lowharp', mel: 'bell', arp: .25, melP: .3, pad: 600, drum: .7 },
};
function themeFor() {
  if (!S.running || !S.map) return 'title';
  const id = S.map.id, night = S.map.outdoor && dayPhase().night > .45;
  if (id === 'mine') return 'mine'; if (id === 'temple') return 'temple'; if (id === 'sanctum') return 'sanctum';
  if (id === 'mirewood') return night ? 'night' : 'forest';
  if (night) return 'night';
  return S.map.safe && inSafe(S.player.x, S.player.y) ? 'town_day' : 'field_day';
}
function bossNear() { if (!S.running || !S.player) return false; for (const e of S.ents) if (e.kind === 'mon' && !e.dead && e.def.boss && e.target && cheb(e.x, e.y, S.player.x, S.player.y) < 16) return true; return false; }
function scheduleBar(th, t) {
  const M = A.mus, beat = 60 / th.bpm, bar = beat * 4;
  if (M.bar % 4 === 0) { M.phrase++; M.prog = th.progs[Math.floor(Math.random() * th.progs.length)]; M.sparse = Math.random() < .2; }
  const ch = M.prog[M.bar % 4].map(x => x + th.root);
  // pad / choir / drone
  if (th.choir) mChoir(ch.map(m => m - (m > th.root + 5 ? 12 : 0)), t, bar, .016);
  else mPad(ch, t, bar, .022, th.pad, 'triangle');
  if (th.drone && M.bar % 2 === 0) { tone(A.musTheme, 'sine', mtof(th.root - 12), null, t, bar * 2, .05, 1.5); tone(A.musTheme, 'sine', mtof(th.root - 5), null, t, bar * 2, .025, 1.8); }
  if (th.bass && !M.sparse) mBass(ch[0] - 12, t, beat * 2, .22);
  // arpeggio: patterns vary every bar
  const pats = [[0, 1, 2, 3, 2, 1, 0, 2], [0, 2, 1, 3, 0, 2, 3, 1], [0, 1, 2, 1, 3, 2, 1, 2], [3, 2, 1, 0, 1, 2, 3, 2]];
  const pat = pats[Math.floor(Math.random() * pats.length)]; const dens = th.arp * (M.sparse ? .45 : 1);
  for (let i = 0; i < 8; i++) {
    if (Math.random() > dens) continue; const n = ch[pat[i] % ch.length] + (i >= 4 && Math.random() < .3 ? 12 : 0); const tt = t + i * beat / 2 + (Math.random() - .5) * .02;
    const v = (i % 2 ? .1 : .14) * rv(1, .3);
    if (th.lead === 'kalimba') mKalimba(n + 12, tt, v * .6); else if (th.lead === 'lowharp') mHarp(n, tt, v * .9); else mHarp(n + 12, tt, v);
  }
  // melody phrase on some bars
  if (Math.random() < th.melP && !M.sparse) {
    let deg = M.melDeg == null ? 2 : M.melDeg; let tt = t + beat * (Math.random() < .5 ? 0 : 1); const end = t + bar - .1;
    const rh = [[1, .5, .5, 1, 1], [.5, .5, 1, 2], [1.5, .5, 2], [1, 1, 1, 1], [2, 1, 1]][Math.floor(Math.random() * 5)];
    for (const r of rh) { if (tt >= end) break; deg = clamp(deg + [-2, -1, -1, 1, 1, 2, 0][Math.floor(Math.random() * 7)], 0, th.scale.length - 1); const m = th.root + 12 + th.scale[deg]; const dur = r * beat;
      if (Math.random() < .85) { if (th.mel === 'flute') mFlute(m, tt, dur * .92, .05); else if (th.mel === 'kalimba') mKalimba(m + 12, tt, .07); else mBell(m + 12, tt, .035); }
      tt += dur; }
    M.melDeg = deg;
  }
  if (th.drum && M.bar % 2 === 0) MUSIC_DRUM(A.musTheme, t, th.drum * .6);
  // boss layer: war drums + ostinato
  if (M.boss) { for (let i = 0; i < 4; i++) MUSIC_DRUM(A.musTheme, t + i * beat, i % 2 ? .45 : .8); for (let i = 0; i < 8; i++) if (i !== 3 && i !== 7) pluck(A.musTheme, mtof(th.root - 12 + (i % 4 === 2 ? 7 : 0)), t + i * beat / 2, .18, .8, 0, 900); }
  M.bar++;
  return bar;
}
function musicTick() {
  const M = A.mus, c = A.c, now = c.currentTime;
  const want = themeFor(); M.boss = bossNear();
  if (want !== M.theme && !M.switching) {
    M.switching = true; const fade = M.theme ? 2.2 : .1;
    A.musTheme.gain.cancelScheduledValues(now); A.musTheme.gain.setValueAtTime(A.musTheme.gain.value, now); A.musTheme.gain.linearRampToValueAtTime(0, now + fade);
    setTimeout(() => { M.theme = want; M.bar = 0; M.next = A.c.currentTime + .15; const t2 = A.c.currentTime; A.musTheme.gain.cancelScheduledValues(t2); A.musTheme.gain.setValueAtTime(0, t2); A.musTheme.gain.linearRampToValueAtTime(1, t2 + 3); M.switching = false; }, fade * 1000 + 50);
  }
  if (!M.theme || M.switching) return;
  const th = THEMES[M.theme];
  if (M.next < now) M.next = now + .05;
  while (M.next < now + .8) M.next += scheduleBar(th, M.next);
}

/* =================== AMBIENCE =================== */
function bed(name, make) { if (A.beds[name]) return A.beds[name]; const b = make(); A.beds[name] = b; return b; }
function noiseBed(ftype, f, q, pink) {
  const c = A.c, s = c.createBufferSource(); s.buffer = pink ? A.pink : A.white; s.loop = true;
  const fl = c.createBiquadFilter(); fl.type = ftype; fl.frequency.value = f; fl.Q.value = q;
  const g = c.createGain(); g.gain.value = 0; s.connect(fl); fl.connect(g); g.connect(A.amb); g.connect(A.ambSend); s.start(); return { s, f: fl, g };
}
function setBed(b, v, tc) { b.g.gain.setTargetAtTime(v, A.c.currentTime, tc || 1.2); }
function ambOut(pan, g) { const c = A.c, gn = c.createGain(); gn.gain.value = g == null ? 1 : g; let last = gn; if (pan && c.createStereoPanner) { const p = c.createStereoPanner(); p.pan.value = pan; gn.connect(p); last = p; } last.connect(A.amb); last.connect(A.ambSend); kill([gn, last], 6); return gn; }
function bird(t) {
  const o = ambOut((Math.random() - .5) * 1.4, rv(.6, .5)); const sp = Math.random() * 4 | 0; const base = [2600, 3400, 2000, 4200][sp];
  const n = [3, 5, 2, 7][sp] + (Math.random() * 3 | 0);
  for (let i = 0; i < n; i++) { const tt = t + i * [.09, .07, .22, .05][sp] * rv(1, .3); const f0 = rv(base, .15), f1 = sp === 2 ? f0 * .7 : rv(f0 * 1.35, .1); tone(o, 'sine', f0, f1, tt, [.06, .045, .16, .035][sp], .018 * rv(1, .4), .006); }
}
function cricket(t) { const o = ambOut((Math.random() - .5) * 1.6, rv(.5, .6)); const f = rv(4400, .08); const n = 3 + (Math.random() * 4 | 0); for (let i = 0; i < n; i++) tone(o, 'sine', f, null, t + i * .045, .025, .012, .003); }
function owl(t) { const o = ambOut((Math.random() - .5) * 1.2, .7); for (const [d, f] of [[0, 390], [.45, 370], [.62, 360]]) tone(o, 'sine', f, f * .92, t + d, .28, .03, .06); }
function frog(t) { const o = ambOut((Math.random() - .5) * 1.4, rv(.5, .5)); const c = A.c, os = c.createOscillator(), f = c.createBiquadFilter(), g = envGain(t, .01, .04, .18), am = c.createOscillator(), ag = c.createGain(); os.type = 'sawtooth'; os.frequency.value = rv(130, .2); am.frequency.value = rv(28, .2); ag.gain.value = .5; am.connect(ag); ag.connect(g.gain); f.type = 'bandpass'; f.frequency.value = 600; f.Q.value = 3; os.connect(f); f.connect(g); g.connect(o); os.start(t); am.start(t); os.stop(t + .25); am.stop(t + .25); kill([os, f, g, am, ag], .6); }
function drip(t) { const o = ambOut((Math.random() - .5) * 1.4, rv(.7, .5)); const f = rv(1400, .3); tone(o, 'sine', f, f * .55, t, .06, .04, .002); if (Math.random() < .5) tone(o, 'sine', f * 1.2, f * .7, t + rv(.12, .4), .05, .02, .002); }
function anvil(t, g, pan) { const o = ambOut(pan, g); for (let i = 0; i < 2 + (Math.random() * 2 | 0); i++) { const tt = t + i * rv(.42, .15); bell(o, rv(1650, .05), tt, .05, .5, [[1, 1, 1], [2.63, .6, .6], [4.1, .35, .4], [5.9, .2, .3]]); noise(o, tt, .03, .06, 'highpass', 3000, .7); } }
function crackle(t, g) { const o = ambOut((Math.random() - .5) * .6, g); for (let i = 0; i < 4; i++) noise(o, t + Math.random() * .3, .01, rv(.03, .6), 'highpass', rv(2500, .4), .7); }
function distantBell(t) { const o = ambOut((Math.random() - .5), .5); bell(o, rv(196, .05), t, .03, 4, [[1, 1, 1], [2.4, .4, .6], [3.9, .2, .4]]); }
function rumble(t) { const o = ambOut(0, .6); noise(o, t, 3, .05, 'lowpass', 90, .6, 50, 1, true); }
function ambTick(dt) {
  const c = A.c, now = c.currentTime; const E = A.ev;
  const wind = bed('wind', () => noiseBed('bandpass', 420, .5, true)), water = bed('water', () => noiseBed('bandpass', 1400, .35, false)), crowd = bed('crowd', () => noiseBed('bandpass', 520, .9, true)), fire = bed('fire', () => noiseBed('lowpass', 500, .5, true));
  if (!S.running || !S.map || !S.player) { setBed(wind, .05); setBed(water, 0); setBed(crowd, 0); setBed(fire, 0); return; }
  const m = S.map, p = S.player, night = m.outdoor ? dayPhase().night : 0; const indoor = !m.outdoor;
  // slowly breathing wind
  const wv = indoor ? (m.id === 'mine' ? .11 : .06) : .09 + Math.sin(now * .13) * .04 + night * .03;
  setBed(wind, wv, 2); wind.f.frequency.setTargetAtTime((indoor ? 300 : 460) + Math.sin(now * .21) * 140, now, 2);
  // fountain & town murmur
  let fw = 0, cr = 0; if (m.id === 'ashvale') { const d = Math.hypot(p.x - 76, (p.y - 59) * 1.2); fw = Math.max(0, 1 - d / 13) * .16; if (inSafe(p.x, p.y)) cr = .035 * (1 - night * .7); }
  setBed(water, fw, .6); setBed(crowd, cr, 2);
  // nearest fire light (torches, braziers, lamps)
  let fd = 99; for (const l of m.lights) { if (!/255,1[4-9]0/.test(l.c) && !/170,80/.test(l.c)) continue; const d = cheb(l.x, l.y, p.x, p.y); if (d < fd) fd = d; }
  setBed(fire, fd < 6 ? (1 - fd / 6) * .05 : 0, .8);
  const due = (k, a, b) => { if (!E[k]) E[k] = now + a + Math.random() * (b - a); if (now >= E[k]) { E[k] = now + a + Math.random() * (b - a); return true; } return false; };
  if (m.outdoor) {
    if (night < .4 && due('bird', m.id === 'mirewood' ? 1.5 : 2.5, m.id === 'mirewood' ? 5 : 8)) bird(now + .05);
    if (night > .35 && due('cricket', .25, .9)) cricket(now + .02);
    if (night > .55 && due('owl', 22, 50)) owl(now + .1);
    if (m.id === 'mirewood' && due('frog', night > .4 ? 1.2 : 5, night > .4 ? 4 : 14)) frog(now + .05);
  } else {
    if ((m.id === 'mine' || m.id === 'temple') && due('drip', 1.2, 4.5)) drip(now + .05);
    if (m.id === 'mine' && due('rumble', 25, 60)) rumble(now + .1);
    if ((m.id === 'temple' || m.id === 'sanctum') && due('dbell', 18, 40)) distantBell(now + .1);
  }
  if (fd < 5 && due('crack', .4, 1.4)) crackle(now + .02, (1 - fd / 5) * .8);
  // the blacksmith hammers away
  if (m.id === 'ashvale') { const d = Math.hypot(p.x - 71, p.y - 69); if (d < 14 && due('anvil', 2.5, 6)) anvil(now + .05, Math.max(0, 1 - d / 14) * .9, clamp((71 - p.x) / 10, -.8, .8)); }
}

/* =================== TICK & SETTINGS =================== */
function audioTick(dt) {
  if (!A || A.c.state !== 'running') return;
  A._t = (A._t || 0) + dt; if (A._t < .1) return; A._t = 0;
  // room acoustics per area
  const id = S.running && S.map ? S.map.id : 'title';
  const wet = id === 'mine' ? .85 : id === 'temple' || id === 'sanctum' ? .9 : id === 'mirewood' ? .45 : .35;
  A.verbOut.gain.setTargetAtTime(wet, A.c.currentTime, 1.5);
  try { musicTick(); } catch (e) { }
  try { ambTick(.1); } catch (e) { }
}
function loadAudioPrefs(P) { if (P && P.audio) { Object.assign(AU.vol, P.audio.vol || {}); AU.steps = P.audio.steps !== false; } applyVolumes(); }
function saveAudioPrefs(P) { if (P) P.audio = { vol: Object.assign({}, AU.vol), steps: AU.steps }; }
document.addEventListener('pointerdown', () => { au(); }, { capture: true });
document.addEventListener('keydown', () => { au(); }, { capture: true });
