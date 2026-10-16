--[[
ForestKit wind. Put this LocalScript in StarterPlayer > StarterPlayerScripts.

Every BasePart tagged "FK_Canopy" sways around its pivot. The Setup script
gives every moving part of one tree (TrunkTop, Branches, Canopy_*, Snow) the
same pivot, the trunk axis at the lowest branch, and the same FK_Reach, so
they all turn by the same angle in the same phase: the crown, its branches
and the trunk inside it bend as one tree while the trunk below stands still.
A small flutter of each part's own sits on top.

Cost: one PivotTo per swaying part within RADIUS studs of the camera, RATE
times a second. Triangles are not the limit on phones and tablets, moving
parts are, so on touch devices the defaults move fewer trees, less often.
A forest of 500 trees is fine with the wind off or with these defaults.

Switches, all optional, read every tick so a game can change them at runtime:
  workspace attribute FK_Wind (boolean)      false switches the wind off; parts return to rest
  workspace attribute FK_WindStrength (number) multiplier, 0 to 2; 0 is the same as off
  workspace attribute FK_WindRadius (number)   studs from the camera beyond which parts stay still
Set STRENGTH to 0 below to ship with the wind off by default.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TAG = "FK_Canopy"
local MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local STRENGTH = 1.0                   -- default multiplier; 0 freezes the forest and costs nothing
local RADIUS = MOBILE and 150 or 400   -- studs from the camera beyond which parts stay still
local RATE = MOBILE and 1 / 20 or 1 / 30 -- seconds between updates

local entries = {} -- part -> { base = CFrame, phase = number, amp = number }

local function register(part)
	if not part:IsA("BasePart") then
		return
	end
	local reach = part:GetAttribute("FK_Reach") or math.max(part.Size.Y, 1)
	local pivot = part:GetPivot().Position
	entries[part] = {
		base = part:GetPivot(),
		-- Phase from the shared pivot: the same for every part of one tree, different for its neighbours.
		phase = (pivot.X * 0.37 + pivot.Z * 0.53) % (2 * math.pi),
		-- Each part's own small flutter, only for masses out on a limb: a part centred on the
		-- trunk axis is the tree's body and gets none.
		flutter = (part.Position.X * 0.74 + part.Position.Z * 1.06) % (2 * math.pi),
		fl = math.min(1, math.sqrt((part.Position.X - pivot.X) ^ 2 + (part.Position.Z - pivot.Z) ^ 2) / (0.15 * reach)),
		-- Tall trees move through a smaller angle; the tip still travels further.
		amp = math.rad(1.6) * math.clamp(18 / reach, 0.6, 1.4),
	}
end

local function unregister(part)
	entries[part] = nil
end

for _, part in ipairs(CollectionService:GetTagged(TAG)) do
	register(part)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)

local function rest()
	for part, e in pairs(entries) do
		if part.Parent then
			part:PivotTo(e.base)
		else
			entries[part] = nil
		end
	end
end

local accumulator, resting = 0, false
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < RATE then
		return
	end
	accumulator = 0

	local strength = workspace:GetAttribute("FK_WindStrength") or STRENGTH
	if workspace:GetAttribute("FK_Wind") == false or strength <= 0 then
		-- wind off: put everything back once, then do nothing per tick
		if not resting then
			rest()
			resting = true
		end
		return
	end
	resting = false
	local radius = workspace:GetAttribute("FK_WindRadius") or RADIUS

	local t = os.clock()
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position

	for part, e in pairs(entries) do
		if not part.Parent then
			entries[part] = nil
			continue
		end
		if camPos and (part.Position - camPos).Magnitude > radius then
			continue
		end
		local p, q = e.phase, e.flutter
		local a = e.amp * strength
		local f = a * e.fl
		-- One body sway for the whole tree plus a quarter-size flutter for masses out on a limb, same as the web preview.
		local z = a * (math.sin(t * 1.1 + p) * 0.7 + math.sin(t * 2.7 + p * 1.6) * 0.3) + f * 0.25 * math.sin(t * 3.3 + q)
		local x = a * 0.6 * math.sin(t * 0.9 + p * 2.1) + f * 0.15 * math.sin(t * 2.9 + q * 1.3)
		part:PivotTo(e.base * CFrame.Angles(x, 0, z))
	end
end)
