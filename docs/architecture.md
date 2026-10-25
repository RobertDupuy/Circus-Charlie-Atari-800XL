# Rendering and cartridge architecture

## Frame contract

The stock 64 KB Atari 800XL presents a complete frame every two television
refreshes: nominal 30 FPS NTSC / 25 FPS PAL. Act 1 uses 89 simulation ticks per
44 NTSC pictures, or 107 ticks per 44 PAL pictures, targeting the arcade's
60.606 Hz clock. Its simulation batch runs immediately before rendering.
Other acts have two NTSC ticks per picture and a 2,2,3,2,3 PAL cadence.
VBI samples the active joystick
port and latches fire edges. In those other acts the next batch is computed after a
completed render, using the idle time before publication. This changes the
scheduling of work, not the tick count or game rules.

The renderer writes the hidden screen, fonts and PM DMA buffer. VBI publishes
only a completed combination. A late buffer retains the previous complete
frame and increments the deadline counter. Loading, applause and title/menu
states have separate contracts and are excluded from active-play timing.

## ANTIC and DLI schedule

The playfield is 160 colour pixels by 176 scanlines in ANTIC mode 4. Normal
characters select background, dark red, cream and gold; inverse characters
replace the fourth entry with blue. This supplies five colours across a band,
subject to the ANTIC per-character restriction. Four hires text rows surround
it. Three character bands normally cover 8, 9 and 5 rows, each with 128 glyph slots. Normal Act 3 instead uses 8/12/2 rows to retain its four performer poses and tall pedestals.

The common DLI schedule changes palettes or fonts at playfield scanlines
0,24,56,64,72,104,136,160 and176. Ground scenes retain 104 for field shading
and omit 160 except in water. Highwire/trapeze retain the lower audience
and floor changes; trapeze omits the redundant 56 and 72 events. Character banks change at 64 and136, then the footer returns
to the HUD font. PAL colours are translated once at stage entry. Audio runs in
VBI and at the 24-line DLI, with enough space before the next display event.

Act 1 retains the 104 and 160 events and adds background-only changes at
80, 96 and 120 for alternating green field bands. These do not copy screen data.

Act 1 uses PRIOR=4 to keep character rims and white hangers in front of player
flames; other acts use PRIOR=1. Missile DMA is disabled. Tightrope, trampolines,
water, horse and trapeze enable player DMA only in bands intersecting their actual player
bitmaps. Three guard scanlines preserve zero GTIA latches when DMA stops;
VBI clears the latches before the empty top border. GRACTL follows DMACTL
at each scheduled boundary, preventing display-list bus data from appearing
as stray player pixels while player DMA is off. The schedule is staged
per buffer and published with its fonts. `tests/dma_windows.py` independently
checks every disabled scanline against the native player data;
`tests/dma_registers.py` executes the VBI/DLI paths and checks the register pair.
Lion and balls keep player DMA enabled. This build does not multiplex players horizontally.

## Prepared assets and compositing

Charlie and combined lion/rider stamps use a dense cell directory followed by
packed glyph bytes. Per-band ranges are reserved before other allocation.
Contiguous glyph runs are copied, then a bounded queue masks only overlapping
cells. A lookup expands zero foreground pixels into transparency masks.
Alternate-colour backgrounds have a prepared conversion atlas; uncommon entries
fall back to the same conversion at runtime.

Ordinary objects have compact ten-byte cell records. Cached fixed-Y objects
hold resident glyphs and prepared screen stores, with explicit clipped paths.
Hoop prize bags include the adjacent hoop pixels offline. Brown monkeys and
variable-width springboards mark immutable patterns inside their ten-byte
records; overlaps retain the generic mask. Rope records use three bytes per
cell, with separate full-cell and endpoint counts for each recovered rope
length. Lookup maps select resident glyphs; uncommon patterns use the dynamic
pool. Native hero mask routines share exact instruction suffixes in unused
directory space. Pixel comparisons retain the generic rendering paths.
The ball act selects among four resident phase fonts without copying a font
per frame. Water platforms similarly use immutable glyphs and screen codes.

Two small native ROM programs per crowd family select transposed phase data
and store screen codes at fixed addresses. Identical phase vectors share loads.
Hoop PM programs store the exact prepared flame bytes at their fixed Y. These
programs are authored by the asset builder and occupy reserved cartridge ranges.

Hero and cached-object footprints use rectangle restore lists. Regions whose
background rows are uniform use a repeated store per row; other rectangles copy
the actual background cells. Remaining objects use dirty-cell lists. The
renderer then draws the scrolling crowd and the new objects. Both buffers own
independent restore lists and PM history.

## RAM map

| Range | Purpose |
| --- | --- |
| $0400–$05FF | Resident fixed-object metadata and drawing helpers |
| $0600–$09FF | Game state, diagnostics, independent player records, objects |
| $0A00–$0DFF | Dirty-cell lists for both buffers |
| $0E00–$0E7F | Staged PM registers and player-DMA schedules |
| $0E80–$0EFF | Prepared rope cell records |
| $0F00–$0FFF | Trapeze arrays, or Act 3 projectiles and shared-player metadata |
| $1000–$2FFF | Main native code, rendering, tables and text |
| $3000–$33FF | Hires HUD font |
| $3400–$37FF | Background screen map |
| $3800–$3FFF | Two character screen maps |
| $4000–$4BFF / $4C00–$57FF | Three font bands per buffer |
| $5800–$5FFF / $6000–$67FF | Two PM DMA areas |
| $6800–$69FF | Display lists |
| $6A00–$6B3F | Two HUD text areas |
| $6C00–$73FF | Alternate-background atlas, or extra immutable ball fonts |
| $7400–$7FFF | Common PM patterns/metadata, replaced by rope atlas pointers and caches in trapeze |
| $8000–$BFFF | SIC 16 KB cartridge window |
| $C000–$CFFF | Resident audio, selection/settings and PCM code |
| $D800–$D83F | Audio stream state under the disabled OS |
| $D840–$D8FF | Title unpacker and title DLI |
| $D900–$D9FF | Mutable obstacle/rope/support state |
| $DA00–$DBFF | One independent checkpoint page per player |
| $DC00–$DCFF | Mechanics and graphics state, palette schedule |
| $DD00–$DDFF | Bounded hero-mask queue |
| $DE00–$DFFF | One rectangle list per display buffer |
| $E000–$EFFF | Audited mechanics and rendering helpers |
| $F000–$FBFF | New graphics helpers |
| $FC00–$FCFF | Transparency lookup |
| $FD00–$FDFF | PAL/NTSC colour lookup |
| $FFFA–$FFFF | Native interrupt/reset vectors |

Ball phase fonts 0/1 reuse the otherwise-unused dynamic third bands at $4800
and $5400; phases 2/3 use $6C00 and $7000. Leaving trapeze restores the common
$7000–$7FFF data, including the ball flags. Water/reward/celebration helpers run in bank28
at $8000; player, continue, setup and DMA-schedule helpers run in bank31 at $B400.
The title's compressed fonts/map occupy explicitly unused background-font
tails. Its particle state and title code are separate from gameplay sprites.
The arcade ball/monkey/horse rules run in bank30 at $AD00; the trapeze apparatus
model and original tables run in bank29. Act 3 rules and player compositors use bank26; its last two reserved pages seed $0400–$05FF at boot. The next 4 KB holds prizes precomposed against their exact scrolling-crowd position.
RAM wrappers restore the required bank after nested drawing calls. Audio IRQ
work preserves the full SIC control byte and uses private zero page. Interrupt
entry clears decimal mode; RTI restores interrupted scoring flags.

## SIC layout and build boundaries

The image has 32 banks of 16 KB, with a common 256-byte boot/vector tail in
all banks. Bank0 supplies main code/common data; its unused $B000 tail is audio.
Bank28 reserves $8000–$8FFF for water/rewards/celebrations and $9000–$97FF for the precomposed water prizes.
Banks1–6 supply scenery and metadata; bank3 also supplies the water lower bands.
Bank7 contains the stamp directory and native hero compositors, banks8–17 the shifted animation payloads.
Banks18/19 contain crowd programs, bank20 resident-object stores, bank21 the
alternate-background atlases, bank22 clipped-edge programs and bank23 hoop PM
programs. Near-rim programs use bank23–25 and an unused animation-bank tail; their pointer directory is in bank20 at $B600–$B67F. Explicit unused tails and remaining banks hold prepared audio.
Bank29 holds the trapeze model. Bank30 supplies the resident XL/mechanics/graphics
code, title DLI and arcade motion helpers; bank31 holds ball
fonts, input demonstrations, HUD templates and system helpers.

The packer reserves every generated native-code range before placing audio.
Build assertions guard program segments, directory/data boundaries and the
common reset tail. The ROM is exactly 524,288 bytes. The emulator CAR adds a
16-byte type-56 SIC header. The game does not write cartridge flash.

## Sound and limits

Two prepared register streams drive music and effects. Runtime code does not
execute an arcade CPU, convert notes or decode PCM during active play. The
unrolled decoder reproduces all 58 verified PAL/NTSC streams. Applause uses
foreground PCM during a frozen intermission after an eight-VBI presentation
delay. Playfield DMA and DLIs remain active so GREAT/FAROUT and the last
completed picture remain visible. The audio packer protects the common ball
flags, title code and generated native-code ranges.
The sample clock advances on its original two-scanline timeline, catching up
after a display interrupt instead of accumulating playback drift.

Hardware-emulator deadlines, font limits, object capacity, pixel-reference
comparisons and actual input tests are the acceptance checks. CPU cycle totals
in evidence/ exclude ANTIC DMA and interrupts. They must not be interpreted
as an available budget for another feature or another graphics layer.

## Hoop clearance revision

The higher rim uses the same 16×72 and 16×56 canvases. Its near semicircle
is composited only into private actor glyphs after the ordinary draw. The
interior excludes flame pixels, including their double-width PM representation.
The native opening is tested against the whole actor silhouette independently
of the compositor’s reference mask.

To keep the larger rim within the existing frame deadline, actor clipping
selects its branch once per stamp, numeric HUD updates redraw only the bonus
when the other cached values match, and an empty generic dirty list skips its
restore setup. These paths preserve the picture and game simulation.

## Act 3 rendering

Cached performer/pedestal columns clip once before all fixed-row stores. Six
uniform bottom rows are restored once per frame. The actor window advances or
retreats with Charlie, so inactive offscreen waves do not consume per-tick
work. Each visible performer's shots share a hardware-player bitmap. The first
shot writes cleared pixels; subsequent shots OR their prepared masks into it.
Unrolled stores clear old extents. DMA bands cover every live shot, with guard
lines and the skipped 104-line event accounted for. The player bitmap reference
test checks both buffers for missing shots and old trails.

Prize bags move with the same camera as the crowd. Their underlying tile phase
is therefore fixed by trampoline index and horizontal alignment. Prepared
composites preserve the generic renderer's pixels while avoiding repeated
background masking. The regular generic path remains the pixel reference.

## Candidate rendering and packet changes

Green ground scenes use the existing font-boundary DLIs for C8/C6/C4 shading; extra raster interrupts remain specific to the lion field. The water renderer visits only pedestals intersecting the viewport and uses clipped native stores at both edges. Its prize cache includes the exact scrolling-crowd phase. Dolphin detail tiles use immutable glyphs when the backdrop is empty, with the original mask fallback for overlaps.

Spring/monkey/detail cache decoding is inline in the sprite cell loop. The generic masked reference path remains available to the pixel tests. The trapeze finish clears the staged positions of unused hardware players before drawing its two-character celebration, preventing the old blue hero accent from remaining beside the couple.

Audio packets fold the ninth register-mask bit into duration bit 7. Long waits split into empty packets; bank links and all output register frames are preserved. This saves 16,994 bytes over the earlier encoding. The packer protects the bank28 code/prize region before allocating its audio tail.
