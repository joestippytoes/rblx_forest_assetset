--[[
ForestKit seasons. Put this Script in ServerScriptService and the Palettes ModuleScript
(roblox/ForestKit/Palettes.lua) inside it or next to it.

It retints every ForestKit model as the year turns: leaves bud in spring, deepen in
summer, turn in autumn, fall for winter; evergreens shift hue and carry snow in
midwinter; ferns die back. Twelve colour keyframes a year per family come from
Palettes, and the script interpolates between neighbouring keyframes, so the change
is a slow fade, never a pop. Colour and Transparency replicate, so clients see it.

OFF BY DEFAULT. Turn it on with Enabled = true below, or at runtime through the
attributes on ReplicatedStorage.ForestKitSeasons (created on first run):
  Enabled      false        nothing happens until this is true
  Mode         "Cycle"      "Cycle": one year every YearLength seconds, starting at SeasonTime
                            "Realtime": follows the real calendar (spring starts 20 March)
                            "Manual": your own script writes SeasonTime (0..1) and this one follows
  YearLength   3600         seconds per year in Cycle mode (60 = a one-minute year for testing)
  SeasonTime   0.35         0 = early spring, 0.25 = early summer, 0.5 = early autumn, 0.75 = early winter
  UpdateEvery  4            seconds between retints; lower is smoother, 4 is plenty for a slow fade

Requires Setup.lua to have run on the models: it tags them ForestKit, writes the Family
attribute and the FK_Role attribute every part is coloured by.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palettes = require(script:FindFirstChild("Palettes") or script.Parent:FindFirstChild("Palettes"))

local DEFAULTS = { Enabled = false, Mode = "Cycle", YearLength = 3600, SeasonTime = 0.35, UpdateEvery = 4 }

local config = ReplicatedStorage:FindFirstChild("ForestKitSeasons")
if not config then
	config = Instance.new("Folder")
	config.Name = "ForestKitSeasons"
	config.Parent = ReplicatedStorage
end
for key, value in pairs(DEFAULTS) do
	if config:GetAttribute(key) == nil then
		config:SetAttribute(key, value)
	end
end

local colorCache = {}
local function color(hex)
	local c = colorCache[hex]
	if not c then
		c = Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
		colorCache[hex] = c
	end
	return c
end

-- part -> { frames = the family's twelve keyframes, role = "Leaf2" }
local entries = {}

local function register(model)
	local family = model:GetAttribute("Family")
	local frames = family and Palettes.families[family]
	if not frames then
		return -- deadwood and anything that is not ours keeps its colours
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local role = part:GetAttribute("FK_Role")
			if role and frames[1][role] ~= nil then
				entries[part] = { frames = frames, role = role }
			end
		end
	end
end

local function unregister(model)
	for _, part in ipairs(model:GetDescendants()) do
		entries[part] = nil
	end
end

for _, model in ipairs(CollectionService:GetTagged("ForestKit")) do
	register(model)
end
CollectionService:GetInstanceAddedSignal("ForestKit"):Connect(register)
CollectionService:GetInstanceRemovedSignal("ForestKit"):Connect(unregister)

local cycleStart, cycleOffset = os.clock(), config:GetAttribute("SeasonTime")

local function yearTime()
	local mode = config:GetAttribute("Mode")
	if mode == "Manual" then
		return config:GetAttribute("SeasonTime") % 1
	elseif mode == "Realtime" then
		local day = os.date("!*t").yday -- spring starts around 20 March, day 79
		return ((day - 79) % 365) / 365
	end
	local length = math.max(10, config:GetAttribute("YearLength"))
	return (cycleOffset + (os.clock() - cycleStart) / length) % 1
end

local function apply(t)
	local n = #Palettes.keyframes
	local x = t * n
	local k = math.floor(x)
	local f = x - k
	local i, j = k % n + 1, (k + 1) % n + 1
	for part, e in pairs(entries) do
		if not part.Parent then
			entries[part] = nil
		else
			local a, b = e.frames[i], e.frames[j]
			part.Color = color(a[e.role]):Lerp(color(b[e.role]), f)
			if e.role:sub(1, 4) == "Leaf" then
				part.Transparency = 1 - (a.leaf + (b.leaf - a.leaf) * f)
			elseif e.role == "Snow" then
				part.Transparency = 1 - (a.snow + (b.snow - a.snow) * f)
			end
		end
	end
end

-- a change of Mode or SeasonTime restarts the cycle from there
config:GetAttributeChangedSignal("Mode"):Connect(function()
	cycleStart, cycleOffset = os.clock(), config:GetAttribute("SeasonTime")
end)

while true do
	if config:GetAttribute("Enabled") then
		local t = yearTime()
		apply(t)
		if config:GetAttribute("Mode") ~= "Manual" then
			config:SetAttribute("SeasonTime", t)
		end
	end
	task.wait(math.max(0.5, config:GetAttribute("UpdateEvery")))
end
