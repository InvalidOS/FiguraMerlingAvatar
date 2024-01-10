-- Required scripts
local model      = require("scripts.ModelParts")
local pose       = require("scripts.Posing")
local waterTicks = require("scripts.WaterTicks")

-- Config setup
config:name("Merling")
local armMove = config:load("AvatarArmMove") or false

-- Get the average of a vector
local function average(vec)
	
	local sum = 0
	for _, v in ipairs{vec:unpack()} do
		sum = sum + v
	end
	return sum / #vec
	
end

-- Left arm lerp table
local leftArm = {
	current    = 0,
	nextTick   = 0,
	target     = 0,
	currentPos = 0
}

-- Right arm lerp table
local rightArm = {
	current    = 0,
	nextTick   = 0,
	target     = 0,
	currentPos = 0
}

-- Set lerp start on init
function events.ENTITY_INIT()
	
	local apply = armMove and 1 or 0
	for k, v in pairs(leftArm) do
		leftArm[k] = apply
	end
	for k, v in pairs(rightArm) do
		rightArm[k] = apply
	end
	
end

-- Gradual value
function events.TICK()
	
	-- Arm variables
	local handedness  = player:isLeftHanded()
	local activeness  = player:getActiveHand()
	local leftActive  = not handedness and "OFF_HAND" or "MAIN_HAND"
	local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
	local leftSwing   = player:getSwingArm() == leftActive
	local rightSwing  = player:getSwingArm() == rightActive
	local leftItem    = player:getHeldItem(not handedness)
	local rightItem   = player:getHeldItem(handedness)
	local using       = player:isUsingItem()
	local usingL      = activeness == leftActive and leftItem:getUseAction() or "NONE"
	local usingR      = activeness == rightActive and rightItem:getUseAction() or "NONE"
	local crossL      = leftItem.tag and leftItem.tag["Charged"] == 1
	local crossR      = rightItem.tag and rightItem.tag["Charged"] == 1
	
	-- Movement overrides
	local shouldMove = waterTicks.under >= 20 or average(model.tailRoot:getScale()) <= 0.5 or animations.Merling.crawl:isPlaying()
	
	-- Targets
	leftArm.target  = (armMove or shouldMove or leftSwing or ((crossL or crossR) or (using and usingL ~= "NONE"))) and 0 or 1
	rightArm.target = (armMove or shouldMove or rightSwing or ((crossL or crossR) or (using and usingR ~= "NONE"))) and 0 or 1
	
	-- Tick lerps
	leftArm.current   = leftArm.nextTick
	rightArm.current  = rightArm.nextTick
	leftArm.nextTick  = math.lerp(leftArm.nextTick,  leftArm.target,  0.5)
	rightArm.nextTick = math.lerp(rightArm.nextTick, rightArm.target, 0.5)
	
end

function events.RENDER(delta, context)
	
	-- Override arm movements
	local idleTimer  = world.getTime(delta)
	local idleRot    = vec(math.deg(math.sin(idleTimer * 0.067) * 0.05), 0, math.deg(math.cos(idleTimer * 0.09) * 0.05 + 0.05))
	local bodyOffset = (vanilla_model.BODY:getOriginRot() * 0.75) + model.body:getTrueRot()
	
	-- Render lerp
	leftArm.currentPos  = math.lerp(leftArm.current,  leftArm.nextTick,  delta)
	rightArm.currentPos = math.lerp(rightArm.current, rightArm.nextTick, delta)
	
	-- First person check
	local firstPerson = context == "FIRST_PERSON"
	
	-- Apply
	model.leftArm:rot( firstPerson and 0 or (-vanilla_model.LEFT_ARM:getOriginRot() + -idleRot + bodyOffset) * leftArm.currentPos)
	model.rightArm:rot(firstPerson and 0 or (-vanilla_model.RIGHT_ARM:getOriginRot() + idleRot + bodyOffset) * rightArm.currentPos)
	
end

-- Arm movement toggle
local function setArmMove(boolean)
	
	armMove = boolean
	config:save("AvatarArmMove", armMove)
	
end

-- Sync variable
local function syncArms(a)
	
	armMove = a
	
end

-- Ping setup
pings.setAvatarArmMove = setArmMove
pings.syncArms         = syncArms

-- Sync on tick
if host:isHost() then
	function events.TICK()
		
		if world.getTime() % 200 == 0 then
			pings.syncArms(armMove)
		end
		
	end
end

-- Activate action
setArmMove(armMove)

-- Table setup
local t = {}

-- Action wheel
t.movePage = action_wheel:newAction("ArmMovement")
	:title("§9§lArm Movement Toggle\n\n§bToggles the movement swing movement of the arms.\nActions are not effected.")
	:hoverColor(vectors.hexToRGB("55FFFF"))
	:toggleColor(vectors.hexToRGB("5555FF"))
	:item("minecraft:red_dye")
	:toggleItem("minecraft:rabbit_foot")
	:onToggle(pings.setAvatarArmMove)
	:toggled(armMove)

-- Return action wheel pages
return t