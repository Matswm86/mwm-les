# MWM Les: 3D character sources

Owner: graphic-designer. Every asset in this repo must have a row here with its licence, checked on the source page. The repo is PUBLIC, so the raw model files themselves are published: only sources that allow that are usable.
Licences below were read on the live pages on 2026-10-03. "Rigged" = has a skeleton; "animated" = ships its own clips.

## Verdict
| Rank | Source | Licence (verified) | Raw files in a public repo? | Use for |
|---|---|---|---|---|
| 1 | KayKit (Kay Lousberg) | CC0 1.0 | Yes | Hero, superhero, adventurers, extra animations |
| 2 | Quaternius, via Poly Pizza copies labelled CC0 | CC0 1.0 on each Poly Pizza page | Yes (CC0 copies) | Pirate captain, horse to unicorn, animals |
| 3 | Kenney | CC0 1.0 | Yes | NPC crowd (12 mini characters), pirate props |
| - | Mixamo (Adobe) | Adobe terms | **No** | Do not use |

## 1. KayKit (Kay Lousberg)
- **Adventurers Character Pack 1.0**: https://kaylousberg.itch.io/kaykit-adventurers and GitHub mirror https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
  - Licence: `LICENSE.txt` in the repo: "License: (Creative Commons Zero, CC0) ... free to use in personal, educational and commercial projects". The itch page adds a request (not a licence term) not to resell unmodified copies. Credit optional.
  - Contents (my check of `Knight.glb` in Blender 4.5): 4 free characters (Knight, Barbarian, Mage, Rogue + Rogue_Hooded), 41-bone rig, **76 clips** per character including Idle, Walking_A/B/C, Running_A/B, Jump_Start/Idle/Land/Full_Short/Full_Long, **Cheer**, Interact, PickUp, Use_Item, Throw, Sit_Floor/Chair, Lie_Down, Dodge, Spellcast, Hit, Death. No Wave clip in this pack.
  - Format: glTF (.glb) and FBX. Style: chibi low-poly, one 1024 px gradient atlas per character (downsample to 256-512).
  - Knight body without weapons: about 4.2k tris (my calc from the mesh parts; full file with all props 7.0k). Has a **red cape mesh (`Knight_Cape`)**.
- **Character Animations**: https://kaylousberg.itch.io/kaykit-character-animations. Licence on page: "Creative Commons Zero v1.0 Universal ... Free for personal and commercial use, no attribution required." 150+ humanoid clips (general, movement, combat, emotes) for the same Rig_Medium, FBX and glTF. Not downloaded yet (itch download flow); this is where Wave and more emotes should come from.
- **Skeletons pack** (same licence, GitHub `KayKit-Character-Pack-Skeletons-1.0`): friendly-looking skeleton crew for the pirate cove.
- Theme fit: superhero YES (Knight minus helmet, recolored cape), kids/heroes YES, pirate partly (Rogue with bandana + Skeletons), unicorn/animals NO.

## 2. Quaternius
- Pack pages (https://quaternius.com/packs/piratekit.html, ultimateanimatedanimals.html, ultimatedanimatedcharacter.html, universalanimationlibrary.html) show "License CC0".
- **Licence conflict:** https://quaternius.com/license.html now shows "Quaternius Asset License (QAL) v1.0, last updated 8/28/2026". It allows use in games but section 3a forbids redistributing "the Assets themselves ... as a standalone asset ... whether for free or for payment"; it only clears "a completed Product that merely incorporates the Assets". Whether raw .glb files in a public source repo count as "incorporated" is not settled by the text. Section 7 says changes are not retroactive.
- **Rule for this game:** use only Quaternius files whose download page states CC0 1.0 and keep a copy of that page's licence line in `assets/<folder>/LICENSE_SOURCE.txt`. The Poly Pizza uploads by the Quaternius account are labelled "Public Domain (CC0)" / `"Licence":"CC0 1.0"` and date from 2021-2023, before the QAL; CC0 cannot be withdrawn from copies already released under it. Do NOT download fresh packs from quaternius.com or itch until Quaternius confirms CC0 for them (email the contact address on quaternius.com), even though the itch page for the Universal Animation Library still says CC0.
- Downloaded (CC0 Poly Pizza copies, in `assets/_candidates/quaternius_polypizza/`):
  | File | Page | Tris (page) | Clips (my check) |
  |---|---|---|---|
  | PirateCaptain.glb | https://poly.pizza/m/sN18LyyHAU | 10,576 | 14 incl. Idle, Walk, Run, Jump, **Wave**, Yes, No, Duck, Punch, Sword, HitReact, Death. Comes with a parrot ("Ernest") and a cutlass |
  | WhiteHorse.glb | https://poly.pizza/m/bEdE4rmZy9 | 1,934 | 13: Idle, Idle_2, Idle_Headlow, Eating, Walk, **Gallop**, **Gallop_Jump**, Jump_toIdle, Attack_Kick, Attack_Headbutt, HitReact L/R, Death |
  | Horse_D3h.glb | https://poly.pizza/m/D3hAeqeDBE | about 2,700 | 8. **Rejected:** blocky voxel style, breaks the "no voxel look" rule |
- Also on Poly Pizza as CC0 from the same account: Horse (https://poly.pizza/m/qvTrSG9pZF, animated, 1,874 tris), Adventurer (https://poly.pizza/m/5EGWBMpuXq, animated, 3,388 tris), Donkey, more animals.
- Theme fit: pirate YES (captain + parrot), unicorn via horse YES, animals YES, superhero no.

## 3. Kenney
- Licence: https://kenney.nl/support: "all game assets on the asset pages are public domain licensed (CC0)". The bundled `License.txt` (Mini Characters 1.0) says "License: (Creative Commons Zero, CC0) ... personal, educational, and commercial purposes". Credit optional. The Kenney logo is not ours to use.
- **Mini Characters** (https://kenney.nl/assets/mini-characters): 12 characters (6 female, 6 male) plus mobility aids (wheelchair, cane, crutch, glasses, hearing aid). My check of `character-female-a.glb`: 956 tris, **31 clips** incl. idle, walk, sprint, jump, fall, crouch, sit, pick-up, interact, emote-yes, emote-no, drive and 7 wheelchair clips. Ideal NPC crowd and shows children of all kinds. Not copied into the repo yet (zip was inspected in scratch only).
- **Pirate Kit** (https://kenney.nl/assets/pirate-kit): 70 CC0 models (ships, props) for the pirate cove environment.
- Also CC0 and animated: Blocky Characters (voxel look, do not use), Animated Characters Protagonists (older human-proportion set, off-style), Cube Pets (cube style, off-style).

## 4. Mixamo (Adobe): licence blocker, confirmed
- Adobe's pinned "Mixamo FAQ - Licensing, Royalties, Ownership, EULA and TOS" (community.adobe.com, 2022-09-29) lists under "NO, you cannot create": "Any type of free distribution of character or animation raw files", and "really the only thing you can't do is distribute the raw character and animation files". A public GitHub repo containing Mixamo FBX (or the same clips re-saved as Godot `.res`/`.glb`) is free distribution of the raw files.
- Verdict: **no Mixamo in this repo.** The CC0 libraries above (KayKit Character Animations 150+, Kenney 31, Quaternius CC0 copies) cover walk, run, jump, idle, wave, cheer.

## 5. Godot humanoid retargeting (how one animation set drives every character)
From the Godot 4 docs (https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html):
1. In the Import dock of each humanoid `.glb`: Skeleton3D > Retarget > **Bone Map** = new BoneMap with **SkeletonProfileHumanoid**; auto-mapping matches common names. Check the map by hand once per rig family (KayKit uses `hips/spine/chest/upperarm.l`, Quaternius `Hips/Abdomen/Torso/UpperArm.L`) and save it as `assets/rigs/<family>_bonemap.tres`.
2. Rest Fixer: **Overwrite Axis** on (the docs call it the most important option for sharing animations), **Fix Silhouette** on for A-pose vs T-pose models, **Normalize Position Tracks** on so stride scales with height. Bone Renamer: **Unique Node** on, so track paths are the same in every scene.
3. For the shared `AnimationLibrary`: Remove Tracks > **Except Bone Transform**, **Unimportant Positions**, **Unmapped Bones** on.
4. Caveat from the docs: Overwrite Axis "can produce horrible results if the original Bone Rest set externally is important"; check the fingers and the cape.
- Animals (horse) are not humanoid: they keep their own clips, no retargeting.
- Plan: the hero is a KayKit character with KayKit clips (native rig, no retarget). Retargeting is the path to put KayKit clips (Wave, Cheer) on the Quaternius pirate and on Kenney NPCs. Test the pirate first: the Quaternius rig has finger bones, the KayKit rig does not.

## 6. Picks
| Role | Pick | Licence | Work needed |
|---|---|---|---|
| Hero / superhero | KayKit Knight (and Mage/Rogue as friends) | CC0 | Hide helmet and weapons, recolor cape hero_red and body to a hero suit, add a chest emblem; clips native (Cheer, Jump, Run, Interact) |
| Pirate | Quaternius Pirate Captain + parrot (Poly Pizza copy) | CC0 | Decimate 10.6k to about 5k tris; friendlier eyebrows in the atlas; KayKit Skeletons as crew |
| Unicorn | Quaternius White Horse (Poly Pizza copy) + our own horn and mane | CC0 | Scale head bone 1.55 in rest pose (tested, reads as a cute foal), add horn mesh on the Head bone, chunkier pink mane mesh, pastel recolor, gold hooves. Clips: Walk, Gallop, Gallop_Jump, Idle, Eating |
| Kids / NPCs | Kenney Mini Characters | CC0 | Use as-is; retarget KayKit Wave/Cheer |
| Pirate world props | Kenney Pirate Kit | CC0 | Toon material swap |

## 7. Files in this repo
| Path | Source | Licence |
|---|---|---|
| assets/_candidates/kaykit_adventurers/Knight.glb, Mage.glb, *_texture.png, LICENSE.txt | KayKit GitHub mirror, Adventurers 1.0 | CC0 |
| assets/_candidates/kaykit_adventurers/preview_knight_mage.png | my Blender render (Cheer + Idle) | ours |
| assets/_candidates/quaternius_polypizza/PirateCaptain.glb, WhiteHorse.glb, Horse_D3h.glb, LICENSE_SOURCE.txt | Poly Pizza, Quaternius account | CC0 1.0 |
| assets/_candidates/quaternius_polypizza/preview_horse_pirate.png, preview_unicorn_from_whitehorse.png, preview_unicorn_from_horse.png | my Blender renders | ours |
`_candidates` is a holding folder: move picked files to `assets/characters/<name>/` with their licence file, and delete rejected ones (Horse_D3h.glb) before the first release.

## Licence risk decision (2026-10-03)
The owner accepts licence risk for the private test phase (owner plus one tester). Mixamo and post-2026-08-28 Quaternius files are allowed for now. Re-check every asset licence before any public release or store listing.
