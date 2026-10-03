# MWM Les: visual design spec

Owner: graphic-designer. Builder reads this before touching any color, font, shader or UI node. Every token carries its rule and its reason.
Audience: children aged 4-7 who cannot read yet (Norwegian first). Every screen must work with the sound off for a parent and with no reading for the child.

## 1. Visual theme
A sunny, toy-like island world seen in bright cel-shaded light, where letters glow like treasure and every character is big, round and friendly.

References (we take the LOOK only; no assets, code or textures from any of them):
- **Zelda: The Wind Waker HD**: two-tone cel lighting with a hard shadow edge, saturated blue sea with white painted foam, chunky islands, stylized puffy clouds and swirly wind trails, big heads and big readable faces, blob shadows under characters.
- **Toca Boca / Sago Mini apps**: pre-reader UI with icon-only buttons, huge targets, voice prompts, nothing to fail.
- **KayKit / Kenney chibi proportion** (our actual character sources, see `docs/ASSETS.md`): head about 1/3 of body height, short limbs, solid color blocks. This is the proportion every character and animal must match.

Mood words for the hero scene: morning, warm sun, sea breeze, treasure.

## 2. Palette
### UI chrome (menus, HUD, buttons). Light by default, no purple.
| Token | Hex | Godot | Use | Why |
|---|---|---|---|---|
| ui_bg | #FFF6E5 | Color(1.00, 0.96, 0.90) | menu backgrounds, parent area | warm light, not paper white |
| ui_panel | #FFFFFF | Color(1.00, 1.00, 1.00) | cards, dialogs | |
| ink | #1D2B45 | Color(0.11, 0.17, 0.27) | outlines, icons on light, the few numbers | 13.19:1 on ui_bg, 14.15:1 on white (my calc) |
| go | #1F7F3A | Color(0.12, 0.50, 0.23) | "play / go / yes" button | white icon 5.05:1 (my calc); 4.71:1 against ui_bg so the button reads as a shape |
| sea_btn | #1C64B8 | Color(0.11, 0.39, 0.72) | secondary buttons (map, replay voice) | white icon 5.89:1 (my calc) |
| gold | #FFC21A | Color(1.00, 0.76, 0.10) | letters, stars, rewards: the ONE "touch me" color | ink icon on gold 8.75:1 (my calc) |
| coral | #C9461F | Color(0.79, 0.27, 0.12) | back / close only (never "wrong") | white icon 4.80:1 (my calc) |

Split: 60 ui_bg/ui_panel, 30 go + sea_btn, 10 gold. There is no "danger" red: a 4-year-old never sees a fail state, only "try again" with a friendly sound.

### World (play content)
| Token | Hex | Godot | Use |
|---|---|---|---|
| sky_top | #5BB4F0 | Color(0.36, 0.71, 0.94) | sky gradient top |
| sky_horizon | #D8F1FF | Color(0.85, 0.95, 1.00) | sky gradient horizon, fog color |
| sea_deep | #1E6FD9 | Color(0.12, 0.44, 0.85) | open sea |
| sea_shallow | #3FB8E8 | Color(0.25, 0.72, 0.91) | near islands (vertex color blend) |
| foam | #F5FBFF | Color(0.96, 0.98, 1.00) | painted foam, cloud lit side |
| sand | #F4D58D | Color(0.96, 0.84, 0.55) | beaches, paths |
| grass | #6CC24A | Color(0.42, 0.76, 0.29) | island tops (lit band) |
| grass_shade | #3E8E3A | Color(0.24, 0.56, 0.23) | grass shadow band (ramp end, not black) |
| rock | #8C7B6B | Color(0.55, 0.48, 0.42) | cliffs |
| hero_red | #E8412C | Color(0.91, 0.25, 0.17) | hero cape, pirate flags |
| unicorn_pink | #FF8FC0 | Color(1.00, 0.56, 0.75) | unicorn mane, unicorn island accents |
| shadow_tint | #2A3550 | Color(0.16, 0.21, 0.31) | multiply color for toon shadow band (cool blue, never gray) |

Per-theme islands shift the 30% band, never the gold: Pirate cove = sea + sand + hero_red; Unicorn meadow = grass + unicorn_pink + foam; Hero city = sea_btn blue + hero_red + white; Activity park = grass + gold flags. Play content may use purple (a unicorn crystal, a sunset); UI chrome never does.

## 3. Typography
Font: **Andika** (SIL Open Font License 1.1; download from software.sil.org/andika, ship `OFL.txt` next to the .ttf). SIL designed it "especially for use as a literacy font" with letterforms that are not easily confused; Latin coverage includes Æ Ø Å. Builder: confirm the single-story a and g in the shipped .ttf specimen before generating letter meshes.
Children never need to read UI text. Text appears only as:
- The letters and words being learned (in-world 3D, see section 7, and the word strip): 160 px cap height at 1080 wide.
- Parent area (behind the parent gate): title 64 px, body 44 px, buttons 48 px, ink on ui_bg.
- Numbers (star count): 72 px, ink, 8 px white outline.

## 4. Components
Sizes in px at 1080 wide (about 2.7 px per dp). The studio minimum is 48 dp; small hands miss more, so this game goes bigger.
| Component | Size | Notes |
|---|---|---|
| Primary button (play, go) | 260 x 260 px (96 dp), circle | go green, white icon 140 px, 10 px ink outline, drop shadow 0,10 px ink 25% |
| Secondary button (map, voice replay, home) | 200 x 200 px (74 dp), circle | sea_btn, white icon 110 px |
| Smallest anything tappable (letters in the word strip, back) | 176 x 176 px (64 dp) | never smaller, also not in the parent area |
| In-world tappables (letters, chests, NPCs) | screen footprint at least 176 px; the touch collider is 1.5x the visual | a missed tap on a letter is the most common frustration at this age |
| Gap between targets | 48 px (18 dp) minimum | |
| Pressed state | scale 0.92 in 0.08 s, then back with a bounce 0.18 s; a "pop" sound on every press | |
| Voice replay button | always top-left, speaker icon, sea_btn | replays the current spoken instruction; the one constant in the game |
| Panels/dialogs | ui_panel, radius 48 px, 8 px ink outline | dialogs contain pictures and one big green "OK/go" circle, no text |
| Progress | a row of star or letter slots (filled = gold), never a bar with numbers | |
| Parent gate | hold two marked corners for 3 s (spoken "this is for grown-ups"), then the parent area | no reading-based gate; pre-readers cannot read one, 4-year-olds cannot hold two corners on purpose |

Input rules: tap only for the child. No double-tap, no long-press, no pinch, no swipe gestures that must be discovered. Drag is allowed only for big objects (letter into word slot). Every icon speaks its meaning the first time it is pressed in a session.

## 5. Layout
- Portrait 1080x1920 (studio default). Safe area: 64 px from all edges plus the device inset.
- Top-left: voice replay. Top-right: home (house icon) and the parent gate corners. Nothing else up top: a child's hand covers the bottom of the screen, a parent's thumb the top.
- Bottom third: the word strip (slots for the letters being collected) and at most one action button, centered.
- The middle 60% of the screen is the world, kept clear of HUD. The focal letter or character sits on a rule-of-thirds point.

## 6. Depth and motion
- Outlines: ink (#1D2B45) inverted-hull outline on characters, animals, letters and anything tappable (section 7). Never on terrain, sea or distant props: an outline is the "you can interact" signal.
- Shadows: hard edged, never blurred (toon look and cheaper). Characters use a blob shadow quad; static scenery uses the one directional shadow.
- UI tweens 0.15-0.25 s, ease out back for pops. World reactions (letter collected, chest opens) 0.4-0.8 s so a 4-year-old can follow cause and effect.
- Particles: only at the focal point (letter sparkle, collect burst, footstep dust). At most 3 emitters alive, 24 particles each, CPUParticles3D or GPUParticles3D with small quads.
- Screen shake: none. Camera flash: none. No strobing above 3 Hz anywhere (photosensitivity, young audience).
- Every reaction has sound: tap pop, letter phoneme, success jingle. Visuals never carry information alone.

## 7. Game art

### 7.1 Toon shader (one shared ShaderMaterial family, Mobile renderer)
Approach: custom `light()` function with a ramp, not post-processing.
- `shaders/toon.gdshader`: `render_mode diffuse_toon, specular_disabled` is not enough; write `light()`:
  `float ndl = dot(NORMAL, LIGHT); float band = smoothstep(ramp_edge - 0.02, ramp_edge + 0.02, ndl * ATTENUATION);`
  then `DIFFUSE_LIGHT += mix(shadow_tint_rgb, vec3(1.0), band) * LIGHT_COLOR / PI * albedo_factor;` with ramp_edge 0.15-0.3 per biome. Folding `ATTENUATION` (shadow) into the band gives the Wind Waker hard shadow edge for free.
- Option for a 3-band look on hero characters only: sample a `GradientTexture1D` (64x1, nearest filter) instead of smoothstep. One ramp per biome, stored in `assets/ramps/`.
- Ambient: WorldEnvironment ambient light from color (sky_horizon at 0.35 energy), not from the sky radiance (cheaper and flatter, which is the look). Reflected light off.
- Rim light on characters and letters only: `rim = pow(1.0 - dot(NORMAL, VIEW), 3.0) * band` added in white at 0.25. Separates characters from the background at the high camera angle.
- Albedo: flat colors from a gradient atlas (KayKit/Kenney style: one 256-512 px palette texture per character set), no normal maps, no roughness maps. Roughness is meaningless under this shader.
- Sea: unshaded spatial shader, 1 plane, vertex wave (2 sine sums), scrolling foam pattern texture 256 px, shoreline foam from a painted mask texture per island. **No `DEPTH_TEXTURE` or `SCREEN_TEXTURE` reads**: on the Mobile renderer they force a full-screen copy, which the 32-bit tablet cannot afford.
- Sky: gradient sky_top to sky_horizon (ProceduralSkyMaterial with sun disk off or a 10-line sky shader), plus 6-10 hand-shaped cloud meshes (flat-shaded, foam color, unshaded) instead of volumetric anything.

### 7.2 Outlines: inverted hull, not post-process
| | Inverted hull (chosen) | Post-process (depth/normal edge pass) |
|---|---|---|
| GPU cost | +1 draw call and the vertex count of each outlined mesh; no full-screen pass | 1 full-screen pass reading depth and normals: on the Mobile renderer this forces depth/normal copies, heavy memory bandwidth on tile-based phone GPUs, every frame, whole screen |
| Control | per object (only tappables get outlines, which carries meaning) | everything gets outlined, including terrain noise |
| Look | thick toy-like outline like WW HD characters | thin technical lines |
Implementation: `next_pass` ShaderMaterial, `render_mode unshaded, cull_front, depth_draw_opaque`; vertex `VERTEX += NORMAL * width`, width scaled by view distance so it stays about 4 px on screen; color ink.
Trap: low-poly models with hard edges have split normals and the hull cracks at corners. Fix in Blender before export: store smoothed normals in a color attribute (or `CUSTOM0`) and extrude along those. Budget: outlined objects at most 12 on screen (12 extra draw calls).

### 7.3 Letters as glowing 3D objects (the heart of the game)
- Mesh: extruded from Andika in Blender (extrude 0.12, bevel 0.02 with 2 segments, curve resolution 4), 300-700 tris per glyph, uppercase A-Z plus Æ Ø Å first; lowercase as a later set (the game-designer decides when). One `.glb` per glyph in `assets/letters/`, origin at the glyph center, about 1.2 m tall (child-character height, so it reads as a big treasure).
- Material: gold, unshaded with a 2-band fake shading baked into vertex colors (front face gold, bevel FFE38A), plus the ink outline and the rim term. Unshaded keeps letters identical in sun and shade, so the target never gets lost.
- Glow without bloom: an additive camera-facing halo quad (soft radial texture 128 px, gold at 40%) behind each letter, scale pulsing 0.95-1.05 at 0.8 Hz. Bloom/glow in WorldEnvironment stays **off** (full-screen passes; four-question check failed on the 32-bit tablet).
- Idle motion: bob 0.15 m at 0.6 Hz, rotate +-20 degrees around Y (never a full spin: a spinning N reads as Z/И), 6-8 sparkle particles.
- Approach: when the hero is within 3 m, the letter turns to face the camera and the halo grows to 1.3x; its phoneme plays once (letter SOUND, "mmm", not the letter name).
- Collect: on tap, scale 1.3 with elastic ease 0.25 s, phoneme plays, then the letter flies along an arc into its slot in the bottom word strip (0.6 s), burst of 16 gold particles. The word strip letter is the 2D version in Andika, gold on ui_panel with ink outline.
- Contrast: gold against grass (1.37:1) and sand (1.14:1) is too weak alone (my calc); the ink outline gives 8.75:1 and the halo does the rest. Never remove the outline from letters.
- Wrong letter: it wobbles, plays a soft "boing", and stays. No red, no X, no lost lives.

### 7.4 Characters and animals
- Sources, licences and picks: `docs/ASSETS.md`. All characters share chibi proportions; anything realistic gets a bigger head (scale head bone 1.4-1.6 in the rest pose, re-export) before it ships.
- Rigs: humanoids retarget onto Godot's `SkeletonProfileHumanoid` at import so one AnimationLibrary drives every humanoid.
- Faces: eyes are part of the albedo atlas; add a blink by swapping UVs or a 2-frame eyelid mesh. Expressions matter more than polygons at this age.
- Textures: characters share one palette atlas (512 px max, 256 px for NPCs), environment one atlas per biome (1024 px), hero props 512 px. 2048 is the hard cap and nothing here needs it. VRAM compressed (ETC2/ASTC; `import_etc2_astc=true`).

### 7.5 Camera
- Third-person follow, fixed pitch 38 degrees, FOV 50, distance 8 m, height so the hero stands on the lower third line. The child never rotates the camera.
- Movement: tap on the ground to walk there (the game-designer owns input; this camera is built for tap-to-move, not a virtual stick).
- Eased follow (lerp 4.0 * delta), dead zone 1.5 m so the camera does not swim during idle animations.
- Story moments: 2-3 s framed shots (character close-up, letter reveal) with eased cuts, then back to follow. Always foreground (grass tufts, rocks), midground (hero, letter), background (sea, islands, clouds).

### 7.6 Phone budget (gate: 60 fps on PerfOverlay on the owner's 32-bit Samsung tablet)
| Item | Budget |
|---|---|
| Visible triangles | 60k target, 100k hard cap (studio) |
| Draw calls | 70 target, 100 hard cap; outline passes count |
| Hero character | at most 5k tris, 1 material, 1 atlas; up to 64 bones (strip IK/control bones on import) |
| NPC humanoid | at most 2k tris (Kenney mini characters are 956) |
| Animal / mount | at most 3k tris (Quaternius horse 2.2k) |
| Letter | at most 700 tris |
| Skinned meshes on screen | at most 6 at once; NPCs beyond 15 m stop animating (`AnimationTree` active=false) |
| Lights | 1 DirectionalLight3D with shadow (orthogonal, max distance 30 m, 2048 atlas, soft shadows off); no omni/spot lights in gameplay |
| Transparency | halo quads and particles only, small screen area |
| Off on mobile | SSAO, SSR, SSIL, SDFGI, volumetric fog, glow/bloom, screen-space reads |
| Repeated props | MultiMeshInstance3D (grass tufts, rocks, shells); `visibility_range_end` 40 m on props |
| Animation | imported at 30 fps, compression on, unused tracks removed |

## 8. Do and don't
- Do: one gold for everything touchable; ink outlines only on interactables; speak every instruction; reward every action; big round shapes.
- Do: hard-edged toon shadows tinted cool blue (shadow_tint), never gray or black.
- Do: test every new character next to a KayKit Knight at camera distance; if it looks thinner or more realistic, it is wrong.
- Don't: text a child must read, timers, fail screens, lives, red X marks, flashing, screen shake.
- Don't: purple, purple-blue gradients, glassmorphism or glowing orbs in UI chrome. Purple may appear only as world content.
- Don't: bloom, depth/screen texture reads, post-process outlines, realtime omni lights, normal maps.
- Don't: Mixamo files in the repo (licence, see `docs/ASSETS.md`), or any asset whose licence is not recorded in `docs/ASSETS.md`.
- Don't: copy anything from Wind Waker or the recomp project (models, textures, music, UI). The reference is the look, nothing else.

## 9. Store assets
- Icon: the hero (KayKit-based, red cape) holding a big glowing gold "A", head and letter filling 80% of the frame, sea_deep to sea_shallow background. Must read at 48 px: test the shrunk icon.
- Feature graphic (1024x500): island with the unicorn, the pirate ship and the hero, a trail of glowing letters leading to a chest. sky + sea background, no white/black/dark-gray background, no text claims.
- Screenshots (real captures from the game-qa bot, never mock-ups): (1) hero reaching a glowing letter on the beach, (2) unicorn meadow with the word strip half filled, (3) pirate cove chest opening with letters flying out.

## 10. Visual tier
**Premium stylized 3D.** Sections 1-9 plus the rules below.

### Premium stylized 3D rules
Target: a polished commercial mobile game, stylized, never photoreal. No voxel/block look, no bare primitives, no default Godot lighting or default camera.
- **Hero scene first.** Before building levels, make one small scene look final: the first beach of Pirate cove with the hero, one glowing letter, the sea, two islands and clouds, at the real camera, with the HUD. the owner signs it off from screenshots, then content copies its setup.
- **Geometry:** strong silhouettes, bevelled/rounded edges, a few good assets over many crude ones. Source from the vetted list in `docs/ASSETS.md` before scripting primitives.
- **Materials:** the toon family from 7.1 only. Flat color from atlases.
- **Lighting:** one directional key light with shadow, flat ambient color fill, rim on characters and letters. Bake (LightmapGI) static islands where it saves the realtime shadow.
- **Camera:** section 7.5.
- **Color:** one palette per biome from section 2; gold marks what the player should touch.
- **Performance budget (phone):** section 7.6. Hold 60 fps on the FPS overlay.

### Four questions before any visual feature
1. Will the player notice it at the real camera distance?
2. What does it cost on the phone GPU (draw calls, overdraw, shader cost)?
3. Can a cheaper trick (baked light, texture, vertex color, fake shadow) get the same look?
4. Does it fit this spec?

Answered for the features in this spec:
| Feature | 1. Noticed? | 2. Cost | 3. Cheaper trick? | 4. Fits? | Verdict |
|---|---|---|---|---|---|
| Toon ramp `light()` | yes, it is the whole look | a few ALU ops per pixel, less than the default PBR light | no, it is already cheaper than default | yes | ship |
| Inverted-hull outline | yes, marks interactables | +1 draw call per outlined object, up to 12 | a baked dark rim in the texture (no silhouette effect) | yes | ship, capped at 12 |
| Post-process outline | yes | full-screen pass plus depth/normal copies | inverted hull | no | rejected |
| Bloom/glow for letters | yes | 2-4 full-screen blur passes | additive halo quad + unshaded gold | no | rejected, halo quad instead |
| Realtime sea reflections/refraction | barely at 38 degree pitch | screen texture copy | painted foam + vertex color depth tint | no | rejected |
| Blob shadow quads under characters | yes, grounds characters | 1 small transparent quad each | is the cheap trick | yes (WW does it) | ship |
| Sparkle particles on letters | yes, focal point | 6-8 small quads | n/a | yes | ship, capped |
