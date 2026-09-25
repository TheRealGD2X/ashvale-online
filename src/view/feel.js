/* ================= GAME FEEL =================
   Camera smoothing, screen shake (trauma model), hit-stop, and the little impulses that make a hit
   feel like a hit. Everything here is presentation only: it never changes game state.

   VIEW.hitStop(sec)          slow the sim to 15% for `sec` (used on crits and kills)
   VIEW.shake(amount, dx, dy) add trauma 0..1 with an optional direction bias
   VIEW.camera(px, py, dt)    → {x, y} smoothed camera centre with look-ahead and shake            */
const VIEW = {
  stop: 0, trauma: 0, shakeDir: { x: 0, y: 0 }, cam: null,
  hitStop(sec) { VIEW.stop = Math.max(VIEW.stop, sec); },
  shake(amount, dx, dy) { VIEW.trauma = Math.min(1, VIEW.trauma + amount); if (dx || dy) { const l = Math.hypot(dx, dy) || 1; VIEW.shakeDir = { x: dx / l, y: dy / l }; } },
  /* time scale for the sim this frame (1 = normal) */
  timeScale(dt) { if (VIEW.stop > 0) { VIEW.stop -= dt; return .15; } return 1; },
  camera(px, py, dt, vx, vy) {
    const c = VIEW.cam;
    if (!c || Math.hypot(c.x - px, c.y - py) > 420) { VIEW.cam = { x: px, y: py, lx: 0, ly: 0 }; return { x: px, y: py }; }
    // look-ahead: lean 22px toward the direction of travel, eased
    const tx = (vx || 0) * 22, ty = (vy || 0) * 14; const le = 1 - Math.exp(-dt * 4);
    c.lx += (tx - c.lx) * le; c.ly += (ty - c.ly) * le;
    const k = 1 - Math.exp(-dt * 9);            // ~110 ms to close most of the gap
    c.x += (px + c.lx - c.x) * k; c.y += (py + c.ly - c.y) * k;
    // shake: amplitude grows with trauma², decays over ~0.4 s
    let sx = 0, sy = 0;
    if (VIEW.trauma > 0) {
      const a = VIEW.trauma * VIEW.trauma * 11, t = S.time * 60;
      const n1 = Math.sin(t * 1.7) * .6 + Math.sin(t * 3.3) * .4, n2 = Math.cos(t * 1.9) * .6 + Math.sin(t * 2.7) * .4;
      sx = n1 * a + VIEW.shakeDir.x * a * .6; sy = n2 * a * .7 + VIEW.shakeDir.y * a * .4;
      VIEW.trauma = Math.max(0, VIEW.trauma - dt * 2.4);
    }
    return { x: c.x + sx, y: c.y + sy };
  }
};
