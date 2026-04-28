// ── Typing Sound Engine — Water Droplet Aesthetic ────────────────────────────
// Web Audio API, pentatonic scale, anti-repetition, key variations.
// Designed to blend musically during fast typing without clipping or fatigue.

const TypingSounds = (() => {
  let ctx = null;
  let masterGain = null;
  let volume = 0.18;       // default low volume
  let enabled = true;
  let lastNote = -1;        // anti-repetition: last played scale index
  let lastTime = 0;         // for density throttle

  // A minor pentatonic: A3 C4 D4 E4 G4 A4 C5 D5 E5 G5
  const SCALE_HZ = [220.0, 261.6, 293.7, 329.6, 392.0,
                    440.0, 523.3, 587.3, 659.3, 784.0];

  function init() {
    if (ctx) return;
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    masterGain = ctx.createGain();
    masterGain.gain.value = volume;
    masterGain.connect(ctx.destination);
  }

  // ── Core droplet synthesizer ──────────────────────────────────────────────
  // Models a water droplet: sine with fast exponential decay + subtle FM shimmer.
  // attack_s: onset ramp; decay_s: exponential tail; freq: base frequency.
  function playDroplet(freq, attack_s, decay_s, gainMul = 1.0) {
    if (!ctx) return;
    const now = ctx.currentTime;

    // Carrier oscillator
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = freq;

    // Subtle FM: modulator at 2× carrier, depth = 8% of freq
    const mod = ctx.createOscillator();
    const modGain = ctx.createGain();
    mod.type = 'sine';
    mod.frequency.value = freq * 2.0;
    modGain.gain.value = freq * 0.08;
    mod.connect(modGain);
    modGain.connect(osc.frequency);

    // Envelope: fast S-curve attack → exponential decay
    const env = ctx.createGain();
    env.gain.setValueAtTime(0, now);
    env.gain.linearRampToValueAtTime(gainMul, now + attack_s);
    env.gain.exponentialRampToValueAtTime(0.0001, now + attack_s + decay_s);

    // Soft lowpass — removes harshness above 3kHz
    const lpf = ctx.createBiquadFilter();
    lpf.type = 'lowpass';
    lpf.frequency.value = 3200;
    lpf.Q.value = 0.7;

    osc.connect(env);
    env.connect(lpf);
    lpf.connect(masterGain);

    const end = now + attack_s + decay_s + 0.01;
    osc.start(now);
    mod.start(now);
    osc.stop(end);
    mod.stop(end);
  }

  // ── Pick next scale note (anti-repetition) ────────────────────────────────
  function pickNote(pool = SCALE_HZ) {
    // Build candidate list excluding last note index
    let idx;
    do { idx = Math.floor(Math.random() * pool.length); }
    while (pool.length > 1 && idx === lastNote);
    lastNote = idx;
    // ±3% pitch micro-variation for organic feel
    const jitter = 1.0 + (Math.random() * 0.06 - 0.03);
    return pool[idx] * jitter;
  }

  // ── Density throttle: fast typing → slight volume duck ───────────────────
  function densityGain() {
    const now = performance.now();
    const dt = now - lastTime;
    lastTime = now;
    // If keys < 80ms apart (>12 keys/s), duck to 70%
    return dt < 80 ? 0.70 : 1.0;
  }

  // ── Public sound triggers ─────────────────────────────────────────────────

  // Regular key: short droplet, mid-range pentatonic note
  function playKey() {
    if (!enabled || !ctx) return;
    const freq = pickNote();
    playDroplet(freq, 0.004, 0.09, densityGain() * 0.9);
  }

  // Space: deeper, softer — "pause breath"
  function playSpace() {
    if (!enabled || !ctx) return;
    // Use lower half of scale
    const low = SCALE_HZ.slice(0, 5);
    const freq = pickNote(low) * 0.75;  // drop an octave-ish
    playDroplet(freq, 0.006, 0.13, densityGain() * 0.7);
  }

  // Enter: brighter, slightly longer — "confirmation"
  function playEnter() {
    if (!enabled || !ctx) return;
    // Two-note micro-chord: root + major 3rd
    const root = pickNote(SCALE_HZ.slice(4, 9));
    playDroplet(root,        0.003, 0.18, 0.85);
    playDroplet(root * 1.26, 0.005, 0.14, 0.45);  // major 3rd, softer
  }

  // Backspace: dampened, slightly pitch-bent down — "undo"
  function playBackspace() {
    if (!enabled || !ctx) return;
    if (!ctx) return;
    const now = ctx.currentTime;
    const freq = pickNote(SCALE_HZ.slice(0, 6));

    const osc = ctx.createOscillator();
    osc.type = 'sine';
    // Pitch bends down 15% over the decay — "reverse" feel
    osc.frequency.setValueAtTime(freq, now);
    osc.frequency.exponentialRampToValueAtTime(freq * 0.85, now + 0.10);

    const env = ctx.createGain();
    env.gain.setValueAtTime(0.7, now);
    env.gain.exponentialRampToValueAtTime(0.0001, now + 0.10);

    const lpf = ctx.createBiquadFilter();
    lpf.type = 'lowpass';
    lpf.frequency.value = 1800;  // more muffled than regular keys

    osc.connect(env);
    env.connect(lpf);
    lpf.connect(masterGain);
    osc.start(now);
    osc.stop(now + 0.12);
  }

  // ── Global keydown listener ───────────────────────────────────────────────
  function attach() {
    document.addEventListener('keydown', e => {
      // Don't trigger on modifier-only keys
      if (e.ctrlKey || e.altKey || e.metaKey) return;
      // Resume AudioContext on first interaction (browser policy)
      if (ctx && ctx.state === 'suspended') ctx.resume();

      switch (e.key) {
        case ' ':         playSpace();     break;
        case 'Enter':     playEnter();     break;
        case 'Backspace': playBackspace(); break;
        default:
          if (e.key.length === 1) playKey();  // printable character
      }
    }, { passive: true });
  }

  // ── API ───────────────────────────────────────────────────────────────────
  return {
    init,
    attach,
    setVolume(v) {
      volume = Math.max(0, Math.min(1, v));
      if (masterGain) masterGain.gain.setTargetAtTime(volume, ctx.currentTime, 0.05);
    },
    setEnabled(v) { enabled = !!v; },
    getVolume()   { return volume; },
    isEnabled()   { return enabled; },
  };
})();

// Auto-init on first user interaction
document.addEventListener('keydown', () => TypingSounds.init(), { once: true });
document.addEventListener('click',   () => TypingSounds.init(), { once: true });
TypingSounds.attach();
