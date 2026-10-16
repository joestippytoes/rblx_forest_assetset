# Setting up Forest Kit in Roblox Studio

Everything the download needs, step by step, with every switch. The scripts referred to are in
[../scripts/](../scripts/) and in the `Scripts` folder of the download.

## 1. Import

File > Import 3D. Pick the GLB files of one folder at a time (a Studio import handles a few dozen
files comfortably). In the import dialog keep the meshes as separate parts: do not merge them into
one mesh. Each file becomes a Model named after the file (`Oak_Grown_03`) holding MeshParts named
`Trunk`, `TrunkTop`, `Branches`, `Collider`, `Canopy_01_Leaf2` and so on, with `Snow` caps, and
on birch `Marks` and `MarksTop`. Shrubs hold `Branches` (or `Stems` on ferns), Canopy parts and
`Snow`; deadwood holds `Wood`, `Grain`, `Moss`.

Colour comes in with the mesh, so the models look right before any script runs. The Collider is a
bark-coloured tube inside the trunk and is not visible until a tree sways.

## 2. Setup.lua

Select the imported Models, or a Folder holding them, paste the whole of `Setup.lua` into the
Command Bar (View > Command Bar) and press Enter. Per Model it:

- anchors every part;
- writes the attributes `Family`, `Stage`, `Variant` from the name;
- writes `FK_Role` on every part (`Bark`, `BarkLight`, `BarkDark`, `Leaf1` to `Leaf4`, `Snow`, `Wood`, `Grain`, `Moss`) so the Seasons script can retint it;
- gives every part that sways (`TrunkTop`, `Branches` or `Stems`, every `Canopy_*`, `Snow`, `MarksTop`) one shared pivot at the trunk axis at the lowest branch, the attribute `FK_Reach`, the tag `FK_Canopy`, and `CanCollide = false`;
- makes the `Collider` invisible, solid (`CollisionFidelity` Hull) and ignored by raycasts and touch;
- hides the `Snow` caps (`Transparency = 1`); the Seasons script shows them in winter;
- puts the Model's pivot at the base centre on the ground, so `model:PivotTo(CFrame.new(x, groundY, z))` plants it and `model:ScaleTo(k)` scales it about the base (`Trunk` or `Wood` becomes the PrimaryPart);
- tags the Model `ForestKit`.

Run it again at any time; it is idempotent.

## 3. Verify.lua

Select the same Models and paste `Verify.lua` into the Command Bar. It changes nothing and prints
one line per problem: a name that is not a kit id, a missing part, a leaf part without a shade in
its name, an unanchored part, a part without `FK_Role`, a visible snow cap, a visible or non-solid
collider, a pivot that is not at the base, or a height outside the stage's range (which means the
import scale is wrong). The last line is the summary. No problems means the models are ready.

## 4. Wind

Put `Wind.client.lua` into StarterPlayer > StarterPlayerScripts as a LocalScript. Every part tagged
`FK_Canopy` sways around its shared pivot: trunk top, branches, leaves and snow of one tree bend
together, with a small flutter per leaf mass; the trunk below the lowest branch stands still.

| Switch | Where | Effect |
|---|---|---|
| `STRENGTH` | top of the script | default multiplier; 0 ships the place with the wind off at no cost |
| `FK_Wind` | attribute on `workspace`, boolean | false switches the wind off at runtime, parts return to rest; true or absent is on |
| `FK_WindStrength` | attribute on `workspace`, number | 0 to 2; 0 is the same as off |
| `FK_WindRadius` | attribute on `workspace`, number | studs from the camera beyond which parts stay still |

Defaults: desktop 400 studs at 30 updates a second, touch devices 150 studs at 20. A game can set
the attributes from a settings menu or from a device check.

## 5. Seasons

Put `Seasons.server.lua` into ServerScriptService as a Script and `Palettes.lua` inside it as a
ModuleScript (or next to it). On the first run it creates the Folder `ReplicatedStorage.ForestKitSeasons`
with these attributes:

| Attribute | Default | Meaning |
|---|---|---|
| `Enabled` | false | nothing happens until this is true |
| `Mode` | Cycle | `Cycle`: one year every `YearLength` seconds, starting at `SeasonTime`. `Realtime`: follows the real calendar, spring starts 20 March. `Manual`: your own script writes `SeasonTime` and this one follows. |
| `YearLength` | 3600 | seconds per year in Cycle mode; 60 gives a one-minute year for testing |
| `SeasonTime` | 0.35 | 0 early spring, 0.25 early summer, 0.5 early autumn, 0.75 early winter |
| `UpdateEvery` | 4 | seconds between retints; lower is smoother, 4 is plenty for a slow fade |

The script retints every part with an `FK_Role` on every Model tagged `ForestKit`, fading between
the twelve keyframes in `Palettes.lua`. Colour and Transparency replicate, so clients see it.
Models added later are picked up on the next retint.

## 6. Forest chunks

Keep the set-up Models in a Folder, by default `ServerStorage.ForestKit`, with `Chunks.lua` inside
it as a ModuleScript. Edit the settings at the top of `BuildChunk.lua` and paste it into the Command Bar:

| Setting | Default | Meaning |
|---|---|---|
| `SOURCE` | `ServerStorage.ForestKit` | the Folder with the models |
| `RECIPE` | `"Oak_1"` | which chunk: `Oak`, `Birch`, `Pine`, `Taiga`, `Hardwood`, `Mixed`, each `_1` to `_5` |
| `ORIGIN` | `0, 0, 0` | world position of the chunk's corner |
| `GROUND` | true | drop every model onto the terrain or parts below it (raycast) |
| `THIN_UNDERSTORY` | 1.0 | 1 = everything; 0.5 = half the ferns, shrubs and deadwood, for mobile |

The chunk lands in `workspace.ForestChunk_<name>`. Chunks are 120 by 120 studs and tile with
themselves, so repeat with `ORIGIN` moved 120 studs over to grow the forest. The same recipes are in
[../data/chunks/](../data/chunks/) as JSON for your own tooling.

## Updating from an earlier import

Delete the old Models and import the new files; then run `Setup.lua` and `Verify.lua` again.
Model and part names have not changed since 1.0, so chunks and scripts keep working.

## Publishing the pack on the Creator Store

The store sells one Model asset that holds everything. Importing GLB files uploads one mesh asset
per file into your inventory; those are the storage behind the MeshParts, they stay private and
nothing needs deleting. To turn the imported models into the pack:

1. Select the imported Models (or nothing, to take every kit model in Workspace), paste
   `Organize.lua` into the Command Bar, press Enter. It builds `Workspace.ForestKit`, a Model with the
   folders `Trees/<Species>/<Species>_Size<N>_<Stage>`, `Shrubs/...`, `Deadwood/...`, a disabled
   `README` script with the link to this repository, and a `Scripts` folder of empty, correctly typed
   script instances named `Setup`, `Verify`, `Wind`, `Seasons` (with `Palettes` inside), `BuildChunk`,
   `Chunks`. Open each one and paste in the matching Lua file. Keep Setup, Verify, Wind, Seasons
   and BuildChunk disabled; buyers enable what they use.
2. Optional, for the automatic thumbnail: build one chunk (`BuildChunk.lua`) and move its folder
   into `ForestKit` as `Showcase`. The store renders the thumbnail from the model's contents, so a
   finished forest in front of the library reads far better than 265 trees in rows.
3. Right-click `ForestKit` > Save to Roblox. In the dialog: name, description (put the repository
   link in the first line), creator (you or your group), turn on "Distribute on Creator Store", set
   the price. Submit; moderation takes a while for a model with scripts.
4. For separate tiers, make one Model per tier with only its folders and publish each the same way.
