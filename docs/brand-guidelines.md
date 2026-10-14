# SAFAR — Brand Guidelines & Design System

## 1. Brand Identity & Vision
**SAFAR** is an ultra-premium, intuitive travel companion designed for modern explorers. The experience balances calm natural aesthetics with tactile, fluid motion and subtle 3D spatial depth.

---

## 2. Visual Palette (Three-Layer Token Architecture)

### Layer 1: Primitive Tokens
| Token | Hex | Role |
| :--- | :--- | :--- |
| `--color-teal-500` | `#1EB980` | Signature Emerald Teal |
| `--color-teal-600` | `#169E6C` | Deep Teal Accent |
| `--color-teal-glow` | `rgba(30, 185, 128, 0.25)` | Micro-glow aura |
| `--color-mint-50` | `#F1F8F5` | Ambient Mint Cream Background |
| `--color-slate-900` | `#111E18` | Deep Forest Charcoal Text |
| `--color-slate-600` | `#6B7E76` | Alpine Mist Muted Text |
| `--color-amber-500` | `#F59E0B` | Sun Amber Badges & Ratings |

### Layer 2: Semantic Tokens
- `primary`: `#1EB980`
- `background`: `#F1F8F5`
- `surface`: `#FFFFFF`
- `text-primary`: `#111E18`
- `text-secondary`: `#6B7E76`

### Layer 3: Component Tokens
- **Pill CTA Button:** Height 58px, border-radius 999px, subtle top-edge specular highlight, spring-press scale 0.96.
- **Glassmorphism Containers:** Blur 12-16px, background `rgba(255, 255, 255, 0.78-0.88)`, 1.2px border `rgba(255, 255, 255, 0.65)`.
- **Card Shadows:** Soft multi-stop ambient shadow `0 10px 24px rgba(18, 43, 30, 0.05)`.

---

## 3. Typography
- **Primary Typeface:** `Plus Jakarta Sans` via Google Fonts.
- **Display Hero:** 36-40px, Extra-Bold (w800), line-height 1.15.
- **Subtitles:** 15-16px, Semi-Bold (w600), letter-spacing 0.2px.
- **Body:** 14px, Regular (w400), line-height 1.5.

---

## 4. Motion & 3D Spatial Guidelines
1. **Interactive 3D Perspective:**
   - Perspective matrix set to `Matrix4.identity()..setEntry(3, 2, 0.0012)`.
   - Clamped rotation angles to a maximum of 7-8 degrees (0.12 rad) to maintain elegance and prevent visual distortion.
2. **Multi-layer Parallax:**
   - Deep background shifts at 0.3x multiplier.
   - Midground alpine crags shift at 0.6x multiplier.
   - Foreground ridge and adventurer shift at 1.0x multiplier.
   - Floating elements (Compass, Weather tag, Elevation pill) live on distinct forward Z-planes.
3. **Repaint Isolation:**
   - All animated canvas painters are isolated with `RepaintBoundary` to prevent full-screen layout thrashing and maintain 60/120 FPS.
