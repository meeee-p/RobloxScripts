local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GROW_KEY = Enum.KeyCode.E
local SHRINK_KEY = Enum.KeyCode.Q

local Left = game.Workspace.Left
local Right = game.Workspace.Right

local LeftParts = {}
local RightParts = {}


local MAX_GROWTH = 1
local MIN_DECAY = 0

local DELTA_GROWTH = 1 --> how much it grows in 1 second
local currentGrowth = 1

local state = "neutral"

local function isPart(inst: Instance): boolean --> simple anonymous function
	return inst.ClassName ~= "SpawnLocation" and inst:IsA("BasePart") 
end

-- adds vec3 value & makes parts cancollide true
-- its cancollide false on server for collision reasons
local function initializeParts(folder: Folder, tableVar: Array<BasePart>): nil
	for _, descend in ipairs(folder:GetDescendants()) do
		if isPart(descend) then
			local size = Instance.new("Vector3Value")
			size.Name = "OriginalSize"
			size.Value = descend.Size
			size.Parent = descend
			
			descend.CanCollide = true
			
			table.insert(tableVar, descend) -- also adds to this table so i filter out stuff i dont want
		end
	end
end

local function changeObby(dt): nil
	if state == "neutral" then 
		return 
	end
	
	local sign = state == "growing" and 1 or -1
	
	-- this math is to make the growth independent of frame rate
	local fps = 1 / dt
	local deficitMultipler = 60 / fps 
	local deltaGain = (DELTA_GROWTH / 60) * deficitMultipler * sign

	currentGrowth += deltaGain
	currentGrowth = math.clamp(currentGrowth, MIN_DECAY, MAX_GROWTH)

	if state == "growing" then
		for i=1,#LeftParts do
			local part = LeftParts[i]
			local originalSize = part.OriginalSize.Value
			local newSize = Vector3.zero:Lerp(originalSize, currentGrowth / MAX_GROWTH)
			part.Size = newSize
		end
		
		for i=1,#RightParts do
			local part = RightParts[i]
			local originalSize = part.OriginalSize.Value
			local newSize = Vector3.zero:Lerp(originalSize, 1 - (currentGrowth / MAX_GROWTH))
			part.Size = newSize
		end

	elseif state == "shrinking" then
		for i=1,#LeftParts do
			local part = LeftParts[i]
			local originalSize = part.OriginalSize.Value
			local newSize = originalSize:Lerp(Vector3.zero, 1 - (currentGrowth / MAX_GROWTH))
			part.Size = newSize
		end

		for i=1,#RightParts do
			local part = RightParts[i]
			local originalSize = part.OriginalSize.Value
			local newSize = originalSize:Lerp(Vector3.zero, currentGrowth / MAX_GROWTH)
			part.Size = newSize
		end
	end
end


local function onInputBegan(input: InputObject, gp: boolean): nil
	if gp then return end
	
	if input.KeyCode == GROW_KEY then
		state = "growing"
	elseif input.KeyCode == SHRINK_KEY then
		state = "shrinking"
	end
end

local function onInputEnded(input: InputObject, gp: boolean): nil
	if gp then return end

	if input.KeyCode == GROW_KEY then
		if state == "growing" then
			state = "neutral"
		end

	elseif input.KeyCode == SHRINK_KEY then
		if state == "shrinking" then
			state = "neutral"
		end		
	end
end

initializeParts(Left, LeftParts)
initializeParts(Right, RightParts)

-- inits the parts
state = "growing"
changeObby(1/60)
state = "neutral"

RunService.Heartbeat:Connect(changeObby)
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)