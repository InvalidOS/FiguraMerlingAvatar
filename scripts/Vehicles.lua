-- Required scripts
local parts   = require("lib.GroupIndex")(models)
local carrier = require("lib.GSCarrier")
local pose    = require("scripts.Posing")

-- GSCarrier rider
carrier.rider.addRoots(models)
carrier.rider.addTag("gscarrier:humanoid")
carrier.rider.controller.setGlobalOffset(vec(0, -10, 0))
carrier.rider.controller.setModifyCamera(false)
carrier.rider.controller.setModifyEye(false)
carrier.rider.controller.setAimEnabled(false)

-- GSCarrier vehicle
carrier.vehicle.addTag("gscarrier:humanoid", "gscarrier:land", "gscarrier:water")

-- Seat 1
carrier.vehicle.newSeat("Seat1", parts.Seat1, {
	priority = 1,
	tags = {["gscarrier:piggyback"] = true}
})

function events.TICK()
	
	local swim = pose.swim or pose.crawl or animations["models.Merling"].crawl:isPlaying()
	parts.Seat1:pos(swim and vec(0, 0, -4) or nil)
	
end