# Seeing the game

Dev tooling for a bug the user sees in game: mostly text, small images only when asked for. Nothing here ships
(`.pkgmeta` ignores `tools`). Output goes under `screenshots/game/` (gitignored).

| Want | Run | Costs about |
| --- | --- | --- |
| The UI's state at a bug, the session's errors | in game `/puisee <note>`, `/reload`; read `screenshots/game/digest.md` | 0.5-1.5k tokens of text |
| The spot the user pointed at | the mark's crop named in the digest (640x400) | 340 tokens |
| The whole screen at a mark | the mark's `-full.jpg` (960x540) | 690 tokens |
| The screen right now | `npm run look` (960x540) | 690 tokens |
| A part of it, full size | `npm run look region=x,y,w,h` (or `region=mouse`, `region=mark`) | w x h / 750 (640x400: 340) |
| What happened over time (the game window, while it has focus) | `npm run rec:start`, `npm run rec:stop`; the sheet | 230 per row of 4 tiles; 12 tiles: 920 |
| A small spot in motion (a flicker) | `npm run rec:start -- strip region=mouse size=240x80` (or `diff`) | about 900 at most; 12 tiles of 240x80: 470 |
| One recorded frame's detail | `npm run crop <frame> region=x,y,w,h` | w x h / 750 |

An image costs about width x height / 750 tokens; every tool line prints it. A full 1920x1080 screenshot is about
1,800, and text in it is half size. Read the text first, then the smallest image that answers the question.

## In game: marks (`tools/see/Polestar_UI_See`, `tools/see.js`)

Setup, once: `npm run link:see`, enable "Polestar: UI See" in the addon list. Keep `npm run see:watch` running (Claude:
in the background; each digest prints one `SEE ...` line).

1. The user points the mouse at the bug and types `/puisee the Buy tab eats clicks` (the note is optional; a key can
   be bound under Key Bindings > AddOns). The addon stores the state as text and calls `Screenshot()`.
2. The user types `/reload`. The client writes saved variables only on `/reload` or logout, and an addon can write
   nothing else, so no mark reaches disk before that. Several marks can go in one reload (one per 2 s, the last 10
   kept).
3. The watcher writes `screenshots/game/digest.md` (the newest only; `npm run see` rewrites it by hand):
   - per new mark: the note, combat, the frame under the mouse with its parents (type, strata/level, mouse, alpha,
     size, position), every visible mouse-enabled frame under the cursor top first (what can eat a click), shown
     tooltips with owner and first line, our windows showing, stock windows on screen (`!!`: while our module is on),
     modules off; and the two images' paths (`screenshots/game/see/mark-<HHMMSS>.jpg`, `-full.jpg`), the cursor
     boxed in magenta;
   - the header: client build, resolution, UI scale, scheme and skin, addon versions, nameplate CVars, and a warning
     when the game's `Polestar_UI` folder is not a link to this checkout;
   - this session's errors from `!BugGrabber.lua`: ours with message, count and 8 stack lines, others one line each
     (locals: the bug-hunt skill's `bugs.js`);
   - the events since the load: load, enter world, combat on/off, `ns.Show`/`ns.Switch` calls, blocked and forbidden
     actions, Lua warnings, errors, marks.

The addon only reads (frame getters under `pcall`, forbidden frames skipped, secret values printed as `?`), plus
post-hooks on `ns.Show` and `ns.Switch`; no stock frame is written, hooked, shown or hidden. A mark works in combat.

## Outside the game: the screen (`tools/look.js`, ffmpeg)

These record the picture as any screen recorder does, and ask Windows which window has focus (a small PowerShell
helper, user32). No game memory is read and nothing is injected, so the client's rules do not apply and no reload is
needed. Needs `ffmpeg` on PATH (checked with 9.0.2). Three grabs are used:

- the game window alone: ffmpeg's `gfxcapture` (Windows.Graphics.Capture) on the window of the process matching
  `exe=` (default `^wow`). It gives the window's own picture even when another window covers it (not when minimised).
  `rec` uses it by default, `look` with `game`.
- the monitor, or a region of it: `ddagrab` (Desktop Duplication) with `video_size`/`offset`; whatever is on screen
  there is what gets captured. `look`, every `region=`, and `rec screen`. `monitor=n` picks another monitor.
- `gdi`: the same through `gdigrab`. Its `title=` window grab also returns the game (tried once, game in front) but is not used: `gfxcapture` takes the window handle, no title to match.

The mouse pointer is drawn in. Regions are in screen pixels of the primary monitor.

- `npm run look [region=x,y,w,h | region=mouse | region=mark] [size=WxH] [game] [scale=s] [fit=px]`: the monitor now,
  960 px wide, or a region at full size. `region=mouse`: `size` (640x400) round the mouse pointer; `region=mark`:
  round the cursor of the last digested `/puisee` mark. Look at the whole first, then ask for the region. The newest
  20 are kept in `screenshots/game/look/`.
- `npm run rec:start [seconds=60] [every=1] [threshold=0.02] [max=12] [text] [screen]`: waits (60 s at most) until
  the game window has focus, then samples it every `every` seconds until the time is up or `npm run rec:stop`,
  keeping a frame only when the picture changed (ffmpeg's scene score against the frame before; lower `threshold`
  for small changes such as a tooltip). Frames taken while the game has no focus are dropped and counted in the last
  line. One line per kept frame (number, time, score, file), also in `frames.txt`; then `sheet.jpg`: up to `max`
  kept frames spread evenly, 320 px tiles, 4 a row, numbered and timed. Run it in the background. The 3D world
  moves all the time, so in play most samples are kept: record short, or over a still scene. `screen` (and a
  missing game) records the monitor whatever has focus, as before.
- `text`: the same, lines only, no file written: a cheap "did the screen change, and when".
- Zoom: `npm run rec:start -- region=x,y,w,h` (or `region=mouse`, taken when the recording starts, or
  `region=mark`) records only that part of the screen at full size; the change score is the region's. A region up
  to 640 px wide is tiled at native size, as many a row as fit 1280 px, and by default as many tiles as about 900
  tokens hold (200x60: 44; 640x400: 4). `fps=5` or `fps=10` (30 at most) in place of `every`. A region run ends with a `CHECK` line: frame 1 against a `look` cut of the same region taken just before (`look.jpg` in the run), a warning over a mean difference of 50.
- Bursts, for a flicker: `npm run rec:start -- strip region=mouse size=240x80` keeps every frame (10 fps for 5 s
  unless told) and measures each against the one before (mean difference, 0-255, in `frames.txt`); the sheet is
  `max` frames in a row from `from=n`. `diff` in place of `strip`: the sheet holds only the frames that differ from
  both neighbours (labelled in red with `*`), each with its two neighbours; `threshold` (0.1) is the difference that
  counts. Over the moving 3D world every frame differs from both: `diff` says so; use `strip`, or a still
  background.
- `npm run rec:sheet <run folder> [from=n] [max=n]`: another strip from a finished run's frames (nothing is
  recorded again).
- `npm run crop <image> [out] region=x,y,w,h | at=fx,fy [size=WxH]`: a full-size piece of a kept frame or of any
  screenshot.

Flags pass without dashes through npm (`npm run look region=0,0,640,400`); `node tools/look.js look --region
0,0,640,400` works too.

Not done: regions on a second monitor (`region=mouse`/`mark` take the primary's pixels), named region presets per
frame, and the changed region of a frame in text.
