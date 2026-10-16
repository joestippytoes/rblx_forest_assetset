--[[
ForestKit setup. Run once in Roblox Studio after importing the GLB files.

How to use:
  1. File > Import 3D, pick the GLB files. Each file becomes a Model whose
     children are MeshParts named after the meshes (Trunk, TrunkTop, Branches,
     Canopy_01, ...). Keep "Import as single model" OFF so the groups stay
     separate parts.
  2. Select the imported Models (or a Folder holding them).
  3. Paste this whole file into the Command Bar (View > Command Bar) and press Enter.

What it does to every selected Model:
  - Anchors every part.
  - Names the model's attributes Family / Stage / Variant from its name
    (Pine_Grown_03, Bush_Large_07, Log_02).
  - Gives every part that moves in the wind (TrunkTop, Branches or Stems,
    Canopy_*, Snow) one shared pivot: the trunk axis at the bottom of the
    Branches part, i.e. the lowest branch. Tags them FK_Canopy and writes the
    FK_Reach attribute (pivot to tree top) so Wind.client.lua sways the whole
    crown as one tree, with the trunk below the lowest branch standing still.
  - Turns collision off for everything that sways so players don't snag, and makes the
    Collider (a plain tube inside the trunk, ground to trunk top) invisible and solid: it is
    what a player bumps into. Leaves and branches can be walked through.
  - Writes an FK_Role attribute on every part (Bark, BarkLight, BarkDark, Leaf1..Leaf4,
    Snow, Wood, Grain, Moss) from the part's name, so Seasons.server.lua can retint it.
  - Hides the Snow caps (Transparency 1); the Seasons script shows them in winter.
  - Puts the Model's pivot at the base centre on the ground (Trunk or Wood as PrimaryPart with
    its PivotOffset there), so model:PivotTo(CFrame.new(x, groundY, z)) plants it, and
    model:ScaleTo(k) scales it about its base. Tags the Model "ForestKit".
]]

local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local SWAYS = { TrunkTop = true, Branches = true, Stems = true, Snow = true, MarksTop = true }
local function sways(part)
	return part.Name:match("^Canopy") ~= nil or SWAYS[part.Name] == true
end

local TREES = { Oak = true, Birch = true, Maple = true, Beech = true, Pine = true, Spruce = true, Fir = true }
-- The role a part was coloured with, from its name. Leaf parts carry their shade (Canopy_07_Leaf2).
local function roleOf(part, family)
	local name = part.Name
	local leaf = name:match("^Canopy_%d+_(Leaf%d)$")
	if leaf then return leaf end
	if name:match("^Canopy") then return "Leaf2" end
	if name == "Trunk" then return "Bark" end
	if name == "TrunkTop" then return family == "Pine" and "BarkLight" or "Bark" end
	if name == "Marks" or name == "MarksTop" then return "BarkDark" end
	if name == "Branches" then return TREES[family] and "BarkLight" or "Bark" end
	if name == "Stems" then return "Bark" end
	if name == "Snow" or name == "Wood" or name == "Grain" or name == "Moss" then return name end
	return nil
end

local function setup(model)
	local trunk = model:FindFirstChild("Trunk")
	local pivotPos = model:GetPivot().Position
	local axisX = trunk and trunk.Position.X or pivotPos.X
	local axisZ = trunk and trunk.Position.Z or pivotPos.Z

	local family, stage, variant = model.Name:match("^(%a+)_(%a+)_(%d+)$")
	if not family then
		family, variant = model.Name:match("^(%a+)_(%d+)$")
	end
	if family then
		model:SetAttribute("Family", family)
		model:SetAttribute("Stage", stage)
		model:SetAttribute("Variant", tonumber(variant))
	end
	CollectionService:AddTag(model, "ForestKit")

	-- One pivot for the whole crown: the bottom of the Branches (or Stems) part, else the lowest moving part.
	local moving = {}
	local top, pivotY, lowest, bottom = -math.huge, nil, math.huge, math.huge
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			local role = roleOf(part, family)
			if role then
				part:SetAttribute("FK_Role", role)
			end
			if part.Name == "Snow" then
				part.Transparency = 1
			elseif part.Name == "Collider" then
				part.Transparency = 1
				part.CanCollide = true
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				pcall(function()
					part.CollisionFidelity = Enum.CollisionFidelity.Hull
				end)
			elseif part.Name == "Marks" then
				part.CanCollide = false
			end
			top = math.max(top, part.Position.Y + part.Size.Y / 2)
			bottom = math.min(bottom, part.Position.Y - part.Size.Y / 2)
			if sways(part) then
				table.insert(moving, part)
				local bottom = part.Position.Y - part.Size.Y / 2
				lowest = math.min(lowest, bottom)
				if part.Name == "Branches" or part.Name == "Stems" then
					pivotY = bottom
				end
			end
		end
	end
	pivotY = pivotY or lowest
	for _, part in ipairs(moving) do
		part.PivotOffset = part.CFrame:ToObjectSpace(CFrame.new(axisX, pivotY, axisZ))
		part:SetAttribute("FK_Reach", top - pivotY)
		part.CanCollide = false
		CollectionService:AddTag(part, "FK_Canopy")
	end
	-- The model's pivot is the base centre on the ground: PivotTo plants, ScaleTo scales about the base.
	local base = CFrame.new(axisX, bottom, axisZ)
	local still = trunk or model:FindFirstChild("Wood")
	if still then
		still.PivotOffset = still.CFrame:ToObjectSpace(base)
		model.PrimaryPart = still
	else
		model.PrimaryPart = nil
		model.WorldPivot = base
	end
end

local count = 0
for _, inst in ipairs(Selection:Get()) do
	if inst:IsA("Model") then
		setup(inst)
		count += 1
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("Model") then
			setup(d)
			count += 1
		end
	end
end
print(("ForestKit: set up %d models"):format(count))
