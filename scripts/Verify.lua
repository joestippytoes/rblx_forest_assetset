--[[
ForestKit verify. After importing and running Setup.lua, select the Models (or a Folder of
them) and paste this whole file into the Command Bar. It prints one line per problem and a
summary, and changes nothing.

Checks: the model name is a kit id (Oak_Grown_03, BushFull_Large_01, Log_04); the parts a
model of that family must have are present; every part has an FK_Role; leaf parts carry their
shade; nothing is unanchored; the Snow caps are hidden; the Collider is invisible and solid;
the model's pivot sits at its base; the model's size is in the expected range for its stage.
]]

local Selection = game:GetService("Selection")

local TREES = { Oak = true, Birch = true, Maple = true, Beech = true, Pine = true, Spruce = true, Fir = true }
local SHRUBS = { Bush = true, BushDense = true, BushFull = true, Bramble = true, Fern = true }
local DEADWOOD = { Branch = true, Log = true, Stump = true }
local HEIGHT = { Sprout = { 1.5, 3.5 }, Sapling = { 6, 13 }, Grown = { 20, 34 }, Elder = { 30, 48 }, Ancient = { 40, 62 },
	Small = { 0.3, 3 }, Medium = { 0.6, 4.5 }, Large = { 1.0, 7 } }

local problems, models = 0, 0
local function report(model, text)
	problems += 1
	print(("  %s: %s"):format(model.Name, text))
end

local function check(model)
	models += 1
	local family, stage, variant = model.Name:match("^(%a+)_(%a+)_(%d+)$")
	if not family then
		family, variant = model.Name:match("^(%a+)_(%d+)$")
	end
	if not family or not (TREES[family] or SHRUBS[family] or DEADWOOD[family]) then
		report(model, "name is not a kit id")
		return
	end
	local names, canopies = {}, 0
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			names[part.Name] = true
			if part.Name:match("^Canopy") then
				canopies += 1
				if not part.Name:match("^Canopy_%d+_Leaf%d$") then
					report(model, "leaf part without a shade in its name: " .. part.Name)
				end
			end
			if not part.Anchored then
				report(model, "unanchored part " .. part.Name)
			end
			if not part:GetAttribute("FK_Role") and part.Name ~= "Collider" then
				report(model, "no FK_Role on " .. part.Name .. " (run Setup.lua)")
			end
			if part.Name == "Snow" and part.Transparency < 1 then
				report(model, "snow cap visible (run Setup.lua)")
			end
			if part.Name == "Collider" and (part.Transparency < 1 or not part.CanCollide) then
				report(model, "collider visible or not solid (run Setup.lua)")
			end
		end
	end
	local need
	if TREES[family] then
		need = stage == "Sprout" and { "Trunk" } or { "Trunk", "TrunkTop", "Branches", "Snow", "Collider" }
		if family == "Birch" and stage ~= "Sprout" then
			table.insert(need, "Marks")
			table.insert(need, "MarksTop")
		end
	elseif family == "Fern" then
		need = { "Stems" }
	elseif SHRUBS[family] then
		need = { "Branches", "Snow" }
	elseif family == "Log" then
		need = { "Wood", "Grain", "Moss" }
	elseif family == "Stump" then
		need = { "Wood", "Grain" }
	else
		need = { "Wood" }
	end
	for _, n in ipairs(need) do
		if not names[n] then
			report(model, "missing part " .. n)
		end
	end
	if (TREES[family] or SHRUBS[family]) and canopies == 0 then
		report(model, "no Canopy parts")
	end
	if model:GetAttribute("Family") ~= family then
		report(model, "Family attribute not set (run Setup.lua)")
	end
	local cf, size = model:GetBoundingBox()
	local pivotY = model:GetPivot().Position.Y
	if math.abs(pivotY - (cf.Position.Y - size.Y / 2)) > 0.5 then
		report(model, ("pivot %.1f studs above the base (run Setup.lua)"):format(pivotY - (cf.Position.Y - size.Y / 2)))
	end
	local range = stage and HEIGHT[stage]
	if range then
		local size = model:GetExtentsSize()
		if size.Y < range[1] or size.Y > range[2] then
			report(model, ("height %.1f studs, expected %d to %d: check the import scale"):format(size.Y, range[1], range[2]))
		end
	end
end

for _, inst in ipairs(Selection:Get()) do
	if inst:IsA("Model") then
		check(inst)
	end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("Model") and d.Parent and not d.Parent:IsA("Model") then
			check(d)
		end
	end
end
print(("ForestKit verify: %d models checked, %d problems"):format(models, problems))
