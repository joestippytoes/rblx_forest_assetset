# Forest Kit: guide for AI assistants and scripts

The contract an assistant or a script needs to find, place, retint and switch the kit's assets
without a human in the loop. Everything here is checkable against [../data/manifest.json](../data/manifest.json).

## 0. Quick recipes

The models live in Studio as Models named by id, usually in `ServerStorage.ForestKit`, with
`Setup.lua` already run on them (see [SETUP.md](SETUP.md)).

```lua
-- Plant one model at a world position. The pivot is the base centre on the ground.
local kit = game:GetService("ServerStorage"):WaitForChild("ForestKit")
local hit = workspace:Raycast(Vector3.new(120, 500, 40), Vector3.new(0, -1000, 0))
local groundY = hit and hit.Position.Y or 0
local tree = kit:FindFirstChild("Oak_Grown_03"):Clone()
tree:PivotTo(CFrame.new(120, groundY, 40) * CFrame.Angles(0, math.rad(35), 0))
tree:ScaleTo(0.9) -- optional; 0.8 to 1.2 keeps the proportions believable
tree.Parent = workspace
```

```lua
-- Every kit model in the place, with what it is
local CollectionService = game:GetService("CollectionService")
for _, model in ipairs(CollectionService:GetTagged("ForestKit")) do
	print(model.Name, model:GetAttribute("Family"), model:GetAttribute("Stage"), model:GetAttribute("Variant"))
end
```

```lua
-- Retint by role: every part carries FK_Role (Bark, BarkLight, BarkDark, Leaf1..Leaf4, Snow, Wood, Grain, Moss)
for _, part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") and part:GetAttribute("FK_Role") == "Leaf4" then
		part.Color = Color3.fromHex("dd953c")
	end
end
```

```lua
-- Wind and seasons, from any server or client script
workspace:SetAttribute("FK_Wind", false)        -- wind off; true or nil is on
workspace:SetAttribute("FK_WindStrength", 1.5)  -- gusty, 0 to 2
local seasons = game:GetService("ReplicatedStorage"):WaitForChild("ForestKitSeasons")
seasons:SetAttribute("Enabled", true)
seasons:SetAttribute("Mode", "Manual")
seasons:SetAttribute("SeasonTime", 0.55)        -- 0 spring, 0.25 summer, 0.5 autumn, 0.75 winter
```

```lua
-- A whole forest: BuildChunk.lua does this for one recipe; the recipe format is in section 5
local Chunks = require(kit:FindFirstChild("Chunks"))
for _, item in ipairs(Chunks["Mixed_2"].items) do
	local id, x, z, rot, scale = item[1], item[2], item[3], item[4], item[5]
	-- clone kit[id], PivotTo(origin + (x, groundY, z)) rotated by rot degrees about Y, ScaleTo(scale)
end
```

## 1. What exists

| Where | What |
|---|---|
| The download, `Trees/<Species>/<Species>_Size<N>_<Stage>/<Id>.glb` etc. | 265 GLB models, flat colours, no textures. Groups `Trees`, `Shrubs`, `Deadwood`. |
| [../data/manifest.json](../data/manifest.json) | One entry per model under `meshes`: `id`, `file`, `family`, `stage`, `variant`, `groups` (part names), `materials`, `triangles`, `height`, `width`. Plus `palettes`: four fixed palettes per family. |
| [../data/seasons.json](../data/seasons.json) | Twelve colour keyframes a year per living family, with leaf and snow opacity. |
| [../data/chunks/](../data/chunks/) | 30 forest layouts, `<Archetype>_<seed>.json`, and `index.json`. The same data as `scripts/Chunks.lua`. |
| [../scripts/](../scripts/) | `Setup.lua`, `Verify.lua`, `Wind.client.lua`, `Seasons.server.lua`, `Palettes.lua`, `BuildChunk.lua`, `Chunks.lua`. |

## 2. Naming

- Model id: `<Family>_<Stage>_<NN>` for trees and shrubs, `<Family>_<NN>` for deadwood. `NN` is the
  variant, `01` to `05`. Examples: `Oak_Ancient_03`, `BushFull_Large_02`, `Log_04`.
- Families: trees `Oak Birch Maple Beech Pine Spruce Fir`; shrubs `Bush BushDense BushFull Bramble Fern`;
  deadwood `Branch Log Stump`. Broadleaves (Oak, Birch, Maple, Beech) go bare in winter; evergreens
  (Pine, Spruce, Fir) keep their needles and carry snow.
- Tree stages, youngest first: `Sprout Sapling Grown Elder Ancient` (folders `Size1` to `Size5`).
  Shrub sizes: `Small Medium Large` (`Size1` to `Size3`).
- Heights in studs (a player is 5): Sprout 2 to 3, Sapling 7 to 12, Grown 21 to 32, Elder 32 to 46,
  Ancient 42 to 60; birch is the shortest of each stage. Shrubs about 2, 3.5 and 5.5. Logs lie flat,
  8 to 16 long. Exact values per model: `height` and `width` in the manifest.
- `Bush` shows stems under its dome, `BushDense` is leafed to the lowest fifth, `BushFull` to the ground.

## 3. Inside a model

Each GLB holds separate named meshes, which Studio imports as MeshParts, each with one flat-colour
material named `<Family>_<Role>`. The import keeps the part names; `Setup.lua` writes the role into
the `FK_Role` attribute because Studio drops material names.

| Part name | Role | Sways | Collides | Notes |
|---|---|---|---|---|
| `Trunk` | `Bark` | no | yes | Trunk below the lowest branch, with flare and roots. PrimaryPart of trees. |
| `Collider` | `Bark` | no | yes | Trees above Sprout: a plain tube inside the trunk, ground to trunk top. Invisible after Setup; it is what a player bumps into above the lowest branch. `CanQuery` false, so raycasts pass through it. |
| `TrunkTop` | `Bark` (`BarkLight` on Pine) | yes | no | Trunk above the lowest branch; overlaps the Trunk from inside so no crack shows. |
| `Branches` | `BarkLight` (trees), `Bark` (shrubs) | yes | no | All limbs and twigs. Its bottom is the shared wind pivot. |
| `Stems` | `Bark` | yes | no | Fern only. |
| `Canopy_NN_LeafK` | `LeafK`, K in 1..4 | yes | no | One leaf mass or shade group. 1 is darkest, 4 lightest. |
| `Snow` | `Snow` | yes | no | Snow caps on every leaf mass. Hidden except in winter. |
| `Marks`, `MarksTop` | `BarkDark` | no, yes | no | Birch only: black bark marks on the Trunk and on the TrunkTop. |
| `Wood`, `Grain`, `Moss` | same | no | yes | Deadwood only. PrimaryPart is `Wood`. |

Units are studs, Y up. Spruce and Fir carry exactly four Canopy parts, one per shade, each spanning
the whole crown; other trees carry one Canopy part per leaf mass (9 to 36 parts per tree).

## 4. After Setup.lua: attributes and tags

| On | Name | Value |
|---|---|---|
| Model | tag `ForestKit` | every kit model |
| Model | `Family`, `Stage`, `Variant` | from the name, e.g. `Oak`, `Grown`, 3. Deadwood has no `Stage`. |
| Model | pivot | base centre on the ground: `GetPivot().Position.Y` is the ground, `PivotTo` plants, `ScaleTo` scales about the base |
| Part | `FK_Role` | `Bark`, `BarkLight`, `BarkDark`, `Leaf1` to `Leaf4`, `Snow`, `Wood`, `Grain`, `Moss`; the Collider has none |
| Swaying part | tag `FK_Canopy`, `FK_Reach` | the wind script moves every part with the tag about its `PivotOffset`; `FK_Reach` is the distance from that pivot to the tree top in studs |
| `workspace` | `FK_Wind`, `FK_WindStrength`, `FK_WindRadius` | read by the wind script every tick; absent means default |
| `ReplicatedStorage.ForestKitSeasons` | `Enabled`, `Mode`, `YearLength`, `SeasonTime`, `UpdateEvery` | the Seasons script's settings |

## 5. Colour and seasons

- `manifest.palettes[Family][Palette][Role]` is a hex colour or `null` (hidden) for the four fixed
  palettes `Summer`, `Autumn`, `Snow`, `Bare`. Deadwood is `palettes.Wood`.
- `seasons.families[Family]` is a list of 12 keyframes in year order, `seasons.keyframes` their
  names (`EarlySpring` to `LateWinter`). Each keyframe maps every role to a hex colour and adds `leaf`
  and `snow` opacity in 0..1. Time of year `t` in 0..1 selects keyframes `floor(t * 12)` and the next,
  blended by the fraction; that is exactly what `Seasons.server.lua` does. Broadleaves and shrubs are
  bare in winter (`leaf` 0), evergreens carry snow in midwinter (`snow` 1), ferns die back.
- Every colour as a table: [PALETTES.md](PALETTES.md).

## 6. Chunk recipes

A recipe (`data/chunks/Oak_1.json`) is `{name, archetype, seed, size, items}`; `size` is 120. Each
item is `{id, x, z, rot, scale, understory}`: `x` and `z` in studs from the chunk's corner, `rot` in
degrees about Y, `scale` near 1, `understory` true for ferns, shrubs and deadwood (what
`THIN_UNDERSTORY` thins). In `Chunks.lua` the same items are arrays in that order. Ground height is
not stored; place each model on your terrain. A chunk tiles against a copy of itself without a seam.

Archetypes: `Oak`, `Birch`, `Pine`, `Taiga` (spruce and fir), `Hardwood` (beech and maple), `Mixed`;
five seeds each. Spacing used in studs: Ancient 13, Elder 10, Grown 7.5, Sapling 3.5, Sprout 2,
shrubs 2 to 4, ferns 1 to 1.6; trees never closer than 0.85 of the sum of their radii. Use the same
numbers if you lay out your own forest.

## 7. Performance pointers

Triangles per model and totals: [PERFORMANCE.md](PERFORMANCE.md). Rules of thumb: parts cost more
than triangles; the wind script is the only per-frame cost and `FK_Wind = false` makes it free;
no textures anywhere; StreamingEnabled and `THIN_UNDERSTORY = 0.5` for mobile.
