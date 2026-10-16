--[[
ForestKit chunk builder: a finished forest in one run.

How to use:
  1. Put the pack's Models in a Folder (default ServerStorage.ForestKit), named as
     imported (Oak_Grown_03, BushFull_Large_01, Log_02 ...), with Setup.lua already run.
  2. Put the Chunks ModuleScript (roblox/ForestKit/Chunks.lua) in that same Folder.
  3. Edit the settings below, paste this whole file into the Command Bar, press Enter.

Every chunk is 120 x 120 studs, about ten trees across, laid out so that a chunk tiles
against itself without a seam. Chunk names: Oak_1..5, Birch_1..5, Pine_1..5, Taiga_1..5
(spruce and fir), Hardwood_1..5 (beech and maple), Mixed_1..5. Repeat with another ORIGIN
120 studs over to grow the forest.
]]

local SOURCE = game:GetService("ServerStorage"):FindFirstChild("ForestKit") -- Folder with the models
local RECIPE = "Oak_1"          -- which chunk
local ORIGIN = Vector3.new(0, 0, 0) -- world position of the chunk's corner
local GROUND = true             -- drop every model onto the terrain or parts below it
local THIN_UNDERSTORY = 1.0     -- 1 = everything; 0.5 = half the ferns, shrubs and deadwood (mobile)

local Chunks = require(SOURCE:FindFirstChild("Chunks"))
local recipe = Chunks[RECIPE]
assert(recipe, "no chunk named " .. RECIPE)

local folder = Instance.new("Folder")
folder.Name = "ForestChunk_" .. RECIPE
folder.Parent = workspace

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { folder }

local rng = Random.new(recipe.seed or 1)
local placed, missing = 0, {}
for _, item in ipairs(recipe.items) do
	local id, x, z, rot, scale, understory = item[1], item[2], item[3], item[4], item[5], item[6]
	if understory and rng:NextNumber() > THIN_UNDERSTORY then
		continue
	end
	local source = SOURCE:FindFirstChild(id)
	if not source then
		missing[id] = true
		continue
	end
	local model = source:Clone()
	local y = ORIGIN.Y
	if GROUND then
		local hit = workspace:Raycast(Vector3.new(ORIGIN.X + x, ORIGIN.Y + 500, ORIGIN.Z + z), Vector3.new(0, -1000, 0), params)
		if hit then
			y = hit.Position.Y
		end
	end
	model:PivotTo(CFrame.new(ORIGIN.X + x, y, ORIGIN.Z + z) * CFrame.Angles(0, math.rad(rot), 0))
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model.Parent = folder
	placed += 1
end

local list = {}
for id in pairs(missing) do
	table.insert(list, id)
end
print(("ForestKit: built %s with %d models%s"):format(RECIPE, placed,
	#list > 0 and (", missing " .. table.concat(list, ", ")) or ""))
