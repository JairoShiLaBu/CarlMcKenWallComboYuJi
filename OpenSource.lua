local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local COLLECTION_SERVICE = game:GetService("CollectionService")
local DEBRIS = game:GetService("Debris")

local localPlayer = PLAYERS.LocalPlayer
local vfxFolder = REPLICATED_STORAGE:WaitForChild("Emotes"):WaitForChild("AmplifyVfx")

-- VFX Pathing
local SKILL_VFX_TEMPLATE = REPLICATED_STORAGE:WaitForChild("Emotes"):WaitForChild("VFX"):WaitForChild("VfxMods"):WaitForChild("LastWill"):WaitForChild("vfx"):WaitForChild("Hit1Fx"):WaitForChild("Attachment")

local WALL_ORIGINAL = "rbxassetid://15955393872"
local REPLACEMENT_1 = "rbxassetid://15943915877"
local EMOTE_ANIM_ID = "rbxassetid://106778226674700"

local connections = {}

local function track(conn)
	table.insert(connections, conn)
end

local function selfDestruct()
	for _, conn in pairs(connections) do
		if conn then conn:Disconnect() end
	end
	script:Destroy()
end

local function createTrack(animator, id, priority)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local t = animator:LoadAnimation(anim)
	t.Priority = priority or Enum.AnimationPriority.Action4
	return t
end

local function fadeVfx(attachment, duration)
	if not attachment then return end
	for _, child in ipairs(attachment:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
		end
	end
	DEBRIS:AddItem(attachment, duration or 2)
end

local function spawnVfx(name, parent, root, lists)
	local template = vfxFolder:FindFirstChild(name)
	if not template then return end

	local vfx = template:Clone()
	vfx.Parent = parent
	DEBRIS:AddItem(vfx, 5)
	
	vfx:SetAttribute("EmoteProperty", true)
	COLLECTION_SERVICE:AddTag(vfx, "emoteendstuff_" .. localPlayer.Name)

	local motor = vfx:FindFirstChildOfClass("Motor6D")
	if motor then
		vfx.CanCollide = false
		vfx.Massless = true
		motor.Part0 = parent
		motor.Part1 = vfx
	else
		vfx.CFrame = root.CFrame * CFrame.new(0, 0, -2)
	end

	for _, d in ipairs(vfx:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d:Emit(d:GetAttribute("EmitCount") or 10)
			if motor then d.Enabled = true end
			if lists then
				if lists.all then table.insert(lists.all, d) end
			end
		end
	end
	return vfx
end

local function handleCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")
	
	track(humanoid.AnimationPlayed:Connect(function(animationTrack)
		if animationTrack.Animation.AnimationId == WALL_ORIGINAL then
			animationTrack:AdjustWeight(0)
			animationTrack:Stop(0)

			local track1 = createTrack(animator, REPLACEMENT_1)
			local emoteTrack = createTrack(animator, EMOTE_ANIM_ID)

			track1:Play(0.05)
			
			task.delay(0.9, function()
				if track1 then track1:Stop(0.1) end
				task.wait(0.1)
				
				-- Wind VFX
				local skillVfx = SKILL_VFX_TEMPLATE:Clone()
				skillVfx.Parent = root
				for _, child in ipairs(skillVfx:GetChildren()) do
					if child:IsA("ParticleEmitter") then
						child:Emit(15)
						child.Enabled = true
					end
				end

				-- Startup Sound
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://112089323132965"
				sound.Volume = 2
				sound.Parent = root
				sound:Play()

				-- Marker Connections
				local spawnedVfx = {}
				local m1 = emoteTrack:GetMarkerReachedSignal("first"):Connect(function()
					local allList = {}
					table.insert(spawnedVfx, spawnVfx("arm", character:FindFirstChild("Right Arm"), root, { all = allList }))
					table.insert(spawnedVfx, spawnVfx("head", character.Head, root, { all = allList }))
					task.wait(1.1)
					for _, e in ipairs(allList) do if e then e.Enabled = false end end
				end)

				local m2 = emoteTrack:GetMarkerReachedSignal("sec"):Connect(function()
					table.insert(spawnedVfx, spawnVfx("arm2", character:FindFirstChild("Left Arm"), root))
					table.insert(spawnedVfx, spawnVfx("auraoff", character:FindFirstChild("Left Arm"), root))
				end)

				emoteTrack:Play(0.1)
				
				emoteTrack.Stopped:Wait()
				
				-- Cleanup
				fadeVfx(skillVfx)
				
				if sound then 
					task.delay(0.5, function() sound:Stop() sound:Destroy() end) 
				end
				
				m1:Disconnect()
				m2:Disconnect()
				for _, v in pairs(spawnedVfx) do if v then v:Destroy() end end
			end)
		end
	end))

	track(humanoid.Died:Connect(selfDestruct))
end

if localPlayer.Character then handleCharacter(localPlayer.Character) end
track(localPlayer.CharacterAdded:Connect(handleCharacter))
