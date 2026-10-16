# Performance

Counts straight from the files (`data/manifest.json`). Vertices are three per triangle: the
models are flat shaded, so no corner is shared between faces. Parts are MeshParts per model.

## Per model

| Model | Triangles, average | Range | MeshParts | Vertices |
|---|---|---|---|---|
| Oak Sprout | 139 | 115 to 155 | 4 | 417 |
| Oak Sapling | 2,047 | 1,813 to 2,788 | 12 | 6,141 |
| Oak Grown | 3,725 | 3,018 to 4,342 | 19 | 11,175 |
| Oak Elder | 4,363 | 3,731 to 4,975 | 21 | 13,089 |
| Oak Ancient | 4,984 | 4,464 to 5,603 | 23 | 14,952 |
| Birch Sprout | 147 | 115 to 195 | 4 | 441 |
| Birch Sapling | 1,892 | 1,562 to 2,359 | 15 | 5,676 |
| Birch Grown | 3,391 | 2,771 to 3,850 | 23 | 10,173 |
| Birch Elder | 4,352 | 3,611 to 4,600 | 27 | 13,056 |
| Birch Ancient | 4,523 | 4,096 to 5,160 | 27 | 13,569 |
| Maple Sprout | 179 | 155 to 195 | 5 | 537 |
| Maple Sapling | 2,392 | 1,901 to 2,788 | 14 | 7,176 |
| Maple Grown | 2,896 | 2,743 to 3,075 | 14 | 8,688 |
| Maple Elder | 3,914 | 3,156 to 4,615 | 18 | 11,742 |
| Maple Ancient | 4,694 | 4,059 to 5,068 | 19 | 14,082 |
| Beech Sprout | 155 | 115 to 195 | 5 | 465 |
| Beech Sapling | 1,827 | 1,593 to 1,973 | 13 | 5,481 |
| Beech Grown | 2,682 | 2,543 to 2,930 | 16 | 8,046 |
| Beech Elder | 3,630 | 3,296 to 4,048 | 21 | 10,890 |
| Beech Ancient | 4,048 | 3,644 to 4,783 | 21 | 12,144 |
| Pine Sprout | 163 | 115 to 195 | 5 | 489 |
| Pine Sapling | 4,604 | 3,994 to 5,094 | 25 | 13,812 |
| Pine Grown | 6,886 | 5,800 to 7,752 | 36 | 20,658 |
| Pine Elder | 6,522 | 6,272 to 6,909 | 35 | 19,566 |
| Pine Ancient | 5,665 | 4,795 to 6,015 | 30 | 16,995 |
| Spruce Sprout | 726 | 704 to 748 | 6 | 2,178 |
| Spruce Sapling | 3,641 | 3,429 to 3,762 | 9 | 10,923 |
| Spruce Grown | 5,773 | 5,536 to 5,908 | 9 | 17,319 |
| Spruce Elder | 6,763 | 6,622 to 6,929 | 9 | 20,289 |
| Spruce Ancient | 7,374 | 7,241 to 7,635 | 9 | 22,122 |
| Fir Sprout | 690 | 660 to 726 | 6 | 2,070 |
| Fir Sapling | 2,812 | 2,713 to 2,940 | 9 | 8,436 |
| Fir Grown | 4,095 | 4,024 to 4,200 | 9 | 12,285 |
| Fir Elder | 4,619 | 4,407 to 4,741 | 9 | 13,857 |
| Fir Ancient | 5,021 | 4,715 to 5,184 | 9 | 15,063 |
| Bush Small | 404 | 300 to 430 | 8 | 1,212 |
| Bush Medium | 925 | 850 to 1,100 | 9 | 2,775 |
| Bush Large | 1,225 | 1,100 to 1,350 | 12 | 3,675 |
| BushDense Small | 728 | 620 to 890 | 18 | 2,184 |
| BushDense Medium | 2,342 | 2,090 to 2,720 | 24 | 7,026 |
| BushDense Large | 2,909 | 2,720 to 3,350 | 29 | 8,727 |
| BushFull Small | 996 | 915 to 1,050 | 24 | 2,988 |
| BushFull Medium | 2,742 | 2,490 to 3,120 | 28 | 8,226 |
| BushFull Large | 3,435 | 3,120 to 3,750 | 35 | 10,305 |
| Bramble Small | 754 | 656 to 820 | 15 | 2,262 |
| Bramble Medium | 951 | 820 to 1,148 | 19 | 2,853 |
| Bramble Large | 1,344 | 1,148 to 1,476 | 26 | 4,032 |
| Fern Small | 187 | 159 to 207 | 4 | 561 |
| Fern Medium | 255 | 231 to 279 | 4 | 765 |
| Fern Large | 346 | 327 to 375 | 4 | 1,038 |
| Branch | 299 | 274 to 319 | 1 | 897 |
| Log | 179 | 169 to 194 | 3 | 537 |
| Stump | 313 | 247 to 372 | 2 | 939 |

## Totals

| | Models | Triangles | MeshParts |
|---|---|---|---|
| One Grown tree, average | 1 | 4,207 | 18 |
| All trees | 175 | 606,720 | 2,736 |
| Whole kit | 265 | 708,407 | 4,090 |
| One forest chunk (66 models, Mixed_1) | 66 | about 134,000 | about 1,000 |

## What it means in a place

- Triangles are not what limits a Roblox forest. Roblox swaps distant MeshParts for lower-detail
  versions on its own (RenderFidelity Automatic, the import default) and StreamingEnabled keeps far
  chunks unloaded. 500 of these trees are an ordinary map for a recent phone or tablet.
- Parts are what costs. A Grown tree is 9 to 36 MeshParts, one per leaf shade group, so a 500-tree
  forest is roughly 9,000 anchored parts. Static, that is fine.
- The wind script is the only per-frame cost: it moves every leaf part of every tree within its
  radius. Ships with 400 studs at 30 updates a second on desktop, 150 studs at 20 on touch devices,
  and costs nothing when switched off (`workspace` attribute `FK_Wind = false`).
- Nothing has textures, so GPU memory stays small whatever the forest size.
- For mobile: keep the wind radius at 150 or less, use `THIN_UNDERSTORY = 0.5` in BuildChunk.lua,
  and turn StreamingEnabled on in the place.
