--[[
ForestKit organize. Turns the imported Models into the one Model you publish.

How to use:
  1. Import the GLB files (File > Import 3D, separate parts) and run Setup.lua on them.
  2. Select the imported Models, or a Folder holding them, or nothing to take every kit
     model in Workspace.
  3. Paste this whole file into the Command Bar, press Enter.

It builds a Model named "ForestKit" in Workspace and moves the selected models into the
pack's folder structure:
  ForestKit (Model)
    README            Script, disabled, with the link to the docs
    Trees/<Species>/<Species>_Size<N>_<Stage>/   the tree models
    Shrubs/<Family>/<Family>_Size<N>_<Size>/     the shrub models
    Deadwood/<Family>/                           the deadwood models
    Scripts           empty Script instances named like the Lua files: open each and paste
                      the file's contents in (Setup, Verify, BuildChunk: Script, disabled;
                      Wind: LocalScript, disabled; Seasons: Script, disabled, with Palettes
                      ModuleScript inside; Chunks: ModuleScript)
Models whose name is not a kit id are left where they are and listed.

Then right-click ForestKit > Save to Roblox to publish it as one Model asset.
]]

local Selection = game:GetService("Selection")

local DOCS = "https://github.com/joestippytoes/rblx_forest_assetset"
local TREES = { Oak = true, Birch = true, Maple = true, Beech = true, Pine = true, Spruce = true, Fir = true }
local SHRUBS = { Bush = true, BushDense = true, BushFull = true, Bramble = true, Fern = true }
local DEADWOOD = { Branch = true, Log = true, Stump = true }
local STAGE = { Sprout = 1, Sapling = 2, Grown = 3, Elder = 4, Ancient = 5, Small = 1, Medium = 2, Large = 3 }

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function script_(parent, name, class, disabled, text)
	local s = parent:FindFirstChild(name)
	if not s then
		s = Instance.new(class)
		s.Name = name
		s.Source = text
		if disabled then
			s.Disabled = true
		end
		s.Parent = parent
	end
	return s
end

local root = workspace:FindFirstChild("ForestKit")
if not root or not root:IsA("Model") then
	root = Instance.new("Model")
	root.Name = "ForestKit"
	root.Parent = workspace
end

script_(root, "README", "Script", true, table.concat({
	"--[[", "FOREST KIT  ·  low-poly trees, shrubs and deadwood", "",
	"Full instructions, scripts and docs:", DOCS, "",
	"Quick start", "  1. Select the models, paste Scripts/Setup into the Command Bar, press Enter.",
	"  2. Paste Scripts/Verify the same way to check everything imported right.",
	"  3. Wind: put Scripts/Wind in StarterPlayerScripts and enable it. Off: workspace attribute FK_Wind = false.",
	"  4. Seasons (optional): Scripts/Seasons with Palettes inside into ServerScriptService, enable it,",
	"     then set Enabled = true on ReplicatedStorage.ForestKitSeasons.",
	"  5. A whole forest in one run: Scripts/BuildChunk with Chunks, see the docs.", "",
	"Keep the model names (Oak_Grown_03 ...): the scripts look them up.",
	"Using an AI assistant to build with this kit? Point it at docs/AI_GUIDE.md in the repo.", "]]" }, "\n"))

local scripts = folder(root, "Scripts")
local paste = function(name) return "-- Paste the contents of " .. name .. " from the download or " .. DOCS .. " here.\n" end
script_(scripts, "Setup", "Script", true, paste("Setup.lua"))
script_(scripts, "Verify", "Script", true, paste("Verify.lua"))
script_(scripts, "Wind", "LocalScript", true, paste("Wind.client.lua"))
local seasons = script_(scripts, "Seasons", "Script", true, paste("Seasons.server.lua"))
script_(seasons, "Palettes", "ModuleScript", false, paste("Palettes.lua"))
script_(scripts, "BuildChunk", "Script", true, paste("BuildChunk.lua"))
script_(scripts, "Chunks", "ModuleScript", false, paste("Chunks.lua"))

-- which models to sort
local candidates = {}
local function collect(inst)
	if inst:IsA("Model") and inst ~= root and not inst:IsDescendantOf(root) then
		table.insert(candidates, inst)
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("Model") and not d:IsDescendantOf(root) and not d.Parent:IsA("Model") then
			table.insert(candidates, d)
		end
	end
end
local selected = Selection:Get()
if #selected == 0 then
	collect(workspace)
else
	for _, inst in ipairs(selected) do
		collect(inst)
	end
end

local moved, skipped = 0, {}
for _, model in ipairs(candidates) do
	local family, stage, variant = model.Name:match("^(%a+)_(%a+)_(%d+)$")
	local dest
	if family and TREES[family] and STAGE[stage] and STAGE[stage] <= 5 and stage ~= "Small" and stage ~= "Medium" and stage ~= "Large" then
		dest = folder(folder(folder(root, "Trees"), family), ("%s_Size%d_%s"):format(family, STAGE[stage], stage))
	elseif family and SHRUBS[family] and (stage == "Small" or stage == "Medium" or stage == "Large") then
		dest = folder(folder(folder(root, "Shrubs"), family), ("%s_Size%d_%s"):format(family, STAGE[stage], stage))
	else
		local fam2 = model.Name:match("^(%a+)_(%d+)$")
		if fam2 and DEADWOOD[fam2] then
			dest = folder(folder(root, "Deadwood"), fam2)
		end
	end
	if dest then
		model.Parent = dest
		moved += 1
	else
		table.insert(skipped, model.Name)
	end
end

print(("ForestKit: %d models sorted into Workspace.ForestKit%s"):format(moved,
	#skipped > 0 and (", left alone: " .. table.concat(skipped, ", ")) or ""))
