local AttendantFuel = {
	active = false,
	paid = false,
	ped = nil,
	nozzle = nil,
	rope = nil,
}

local FuelPumpModels = {
	"prop_gas_pump_1d",
	"prop_gas_pump_1a",
	"prop_gas_pump_1b",
	"prop_gas_pump_1c",
	"prop_vintage_pump",
	"prop_gas_pump_old2",
	"prop_gas_pump_old3",
	"denis3d_prop_gas_pump",
}

local FuelPortBones = {
	"wheel_lr",
	"wheel_lm1",
	"wheel_lm2",
	"petrolcap",
	"petrolcap ",
	"petrolcap_l",
	"petrolcap_r",
	"petroltank",
	"petroltank_l",
	"petroltank_r",
}

function IsAttendantFuelActive()
	return AttendantFuel.active
end exports('IsAttendantFuelActive', IsAttendantFuelActive)

local function attendantConfig()
	return Config.AttendantFuel or {}
end

local function deleteEntity(entity)
	if entity and entity ~= 0 and DoesEntityExist(entity) then
		DeleteEntity(entity)
	end
end

local function cleanupNozzle()
	if AttendantFuel.rope then
		DeleteRope(AttendantFuel.rope)
		RopeUnloadTextures()
		AttendantFuel.rope = nil
	end

	deleteEntity(AttendantFuel.nozzle)
	AttendantFuel.nozzle = nil
end

local function cleanupAttendant()
	cleanupNozzle()
	deleteEntity(AttendantFuel.ped)
	AttendantFuel.ped = nil
	AttendantFuel.active = false
	AttendantFuel.paid = false
end

local function finishPaidService(success)
	if AttendantFuel.paid then
		TriggerServerEvent('cdn-fuel:server:attendant:finish', success == true)
		AttendantFuel.paid = false
	end
end

local function loadModel(model)
	local modelHash = type(model) == "number" and model or joaat(model)
	RequestModel(modelHash)

	local timeout = GetGameTimer() + 5000
	while not HasModelLoaded(modelHash) do
		Wait(20)
		if GetGameTimer() > timeout then
			return nil
		end
	end

	return modelHash
end

local function getVector4Coords(coords)
	if not coords then return nil end

	if coords.x then
		return vector4(coords.x, coords.y, coords.z, coords.w or coords.h or 0.0)
	end

	return nil
end

local function headingTo(fromCoords, toCoords)
	return GetHeadingFromVector_2d(toCoords.x - fromCoords.x, toCoords.y - fromCoords.y)
end

local function normalizedDirection(fromCoords, toCoords)
	local x = toCoords.x - fromCoords.x
	local y = toCoords.y - fromCoords.y
	local length = math.sqrt((x * x) + (y * y))
	if length < 0.05 then
		return 0.0, 1.0
	end

	return x / length, y / length
end

local function resolveGroundCoords(coords, referenceZ, allowSafeCoord)
	referenceZ = referenceZ or coords.z
	RequestCollisionAtCoord(coords.x, coords.y, referenceZ)

	local foundSafe, safeCoords = false, nil
	if allowSafeCoord then
		foundSafe, safeCoords = GetSafeCoordForPed(coords.x, coords.y, referenceZ, true, 16)
	end

	if foundSafe and safeCoords and math.abs(safeCoords.z - referenceZ) <= 2.0 and #(vector3(safeCoords.x, safeCoords.y, referenceZ) - vector3(coords.x, coords.y, referenceZ)) <= 2.5 then
		return vector4(safeCoords.x, safeCoords.y, safeCoords.z + 0.05, coords.w or 0.0)
	end

	for i = 1, 25 do
		local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, referenceZ + 1.0, false)
		if foundGround and math.abs(groundZ - referenceZ) <= 2.0 then
			return vector4(coords.x, coords.y, groundZ + 0.05, coords.w or 0.0)
		end

		Wait(20)
	end

	return vector4(coords.x, coords.y, referenceZ + 0.05, coords.w or 0.0)
end

local function offsetPoint(originCoords, directionX, directionY, distance, heading, referenceZ, allowSafeCoord)
	return resolveGroundCoords(vector4(
		originCoords.x + (directionX * distance),
		originCoords.y + (directionY * distance),
		referenceZ or originCoords.z,
		heading or 0.0
	), referenceZ or originCoords.z, allowSafeCoord)
end

local function getPumpApproachCandidates(pumpCoords, vehicle)
	local cfg = attendantConfig()
	local vehicleCoords = GetEntityCoords(vehicle)
	local directionX, directionY = normalizedDirection(pumpCoords, vehicleCoords)
	local sideX, sideY = -directionY, directionX
	local approachDistance = cfg.pumpApproachDistance or 2.6
	local pumpReachDistance = cfg.pumpReachDistance or 3.2
	local candidates = {
		{ x = directionX, y = directionY, distance = approachDistance },
		{ x = sideX, y = sideY, distance = approachDistance },
		{ x = -sideX, y = -sideY, distance = approachDistance },
		{ x = -directionX, y = -directionY, distance = approachDistance },
		{ x = directionX, y = directionY, distance = approachDistance + 0.8 },
		{ x = sideX, y = sideY, distance = approachDistance + 0.8 },
		{ x = -sideX, y = -sideY, distance = approachDistance + 0.8 },
	}
	local results = {}

	for i = 1, #candidates do
		local candidate = candidates[i]
		local coords = offsetPoint(pumpCoords, candidate.x, candidate.y, candidate.distance, 0.0, pumpCoords.z, true)
		if math.abs(coords.z - pumpCoords.z) <= 2.0 and #(vector3(coords.x, coords.y, coords.z) - vehicleCoords) >= 1.8 and #(vector3(coords.x, coords.y, coords.z) - pumpCoords) <= pumpReachDistance then
			results[#results + 1] = vector4(coords.x, coords.y, coords.z, headingTo(coords, pumpCoords))
		end
	end

	local coords = offsetPoint(pumpCoords, directionX, directionY, approachDistance, 0.0, pumpCoords.z, false)
	results[#results + 1] = vector4(coords.x, coords.y, coords.z, headingTo(coords, pumpCoords))
	return results
end

local function getWheelFuelPortCoords(vehicle)
	local cfg = attendantConfig()
	local wheelBoneIndex = GetEntityBoneIndexByName(vehicle, "wheel_lr")
	if not wheelBoneIndex or wheelBoneIndex == -1 then
		return nil, nil
	end

	local wheelCoords = GetWorldPositionOfEntityBone(vehicle, wheelBoneIndex)
	local wheelLocal = GetOffsetFromEntityGivenWorldCoords(vehicle, wheelCoords.x, wheelCoords.y, wheelCoords.z)
	local side = wheelLocal.x < 0.0 and -1.0 or 1.0
	local portHeight = cfg.fuelPortHeight or 0.75
	local rearOffset = cfg.fuelPortRearOffset or 0.2
	local portCoords = GetOffsetFromEntityInWorldCoords(vehicle, wheelLocal.x, wheelLocal.y + rearOffset, wheelLocal.z + portHeight)

	return portCoords, side
end

local function getFallbackFuelPortCoords(vehicle, pumpCoords)
	local vehicleCoords = GetEntityCoords(vehicle)
	local rightRef = GetOffsetFromEntityInWorldCoords(vehicle, 1.0, 0.0, 0.0)
	local pumpVector = pumpCoords - vehicleCoords
	local rightVector = rightRef - vehicleCoords
	local side = 1.0

	if ((rightVector.x * pumpVector.x) + (rightVector.y * pumpVector.y)) < 0.0 then
		side = -1.0
	end

	return GetOffsetFromEntityInWorldCoords(vehicle, side * 0.95, -1.2, 0.0)
end

local function getFuelPortCoords(vehicle, pumpCoords)
	local wheelPortCoords, wheelSide = getWheelFuelPortCoords(vehicle)
	if wheelPortCoords then
		return wheelPortCoords, wheelSide
	end

	for i = 1, #FuelPortBones do
		local boneName = FuelPortBones[i]
		if boneName ~= "wheel_lr" and boneName ~= "wheel_lm1" and boneName ~= "wheel_lm2" then
			local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
			if boneIndex and boneIndex ~= -1 then
				local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
				local boneLocal = GetOffsetFromEntityGivenWorldCoords(vehicle, boneCoords.x, boneCoords.y, boneCoords.z)
				local side = boneLocal.x < 0.0 and -1.0 or 1.0
				return boneCoords, side
			end
		end
	end

	return getFallbackFuelPortCoords(vehicle, pumpCoords), nil
end

local function getVehicleApproachCoords(vehicle, pumpCoords)
	local cfg = attendantConfig()
	local fuelPortCoords, side = getFuelPortCoords(vehicle, pumpCoords)
	local fuelPortLocal = GetOffsetFromEntityGivenWorldCoords(vehicle, fuelPortCoords.x, fuelPortCoords.y, fuelPortCoords.z)
	if not side then
		side = fuelPortLocal.x < 0.0 and -1.0 or 1.0
	end

	local approachDistance = cfg.vehicleApproachDistance or 1.05
	local serviceCoords = GetOffsetFromEntityInWorldCoords(vehicle, fuelPortLocal.x + (side * approachDistance), fuelPortLocal.y, 0.0)
	local target = vector4(serviceCoords.x, serviceCoords.y, pumpCoords.z, 0.0)
	local coords = resolveGroundCoords(target, pumpCoords.z, false)
	return vector4(coords.x, coords.y, coords.z, headingTo(coords, fuelPortCoords)), fuelPortCoords
end

local function getSpawnCoords(location, pumpCoords, vehicle)
	local cfg = attendantConfig()
	local station = Config.GasStations[location]
	local configured = station and getVector4Coords(station.attendantcoords)
	if configured then
		local offset = cfg.spawnOffset or vector4(0.0, 0.0, 0.0, 0.0)
		return resolveGroundCoords(vector4(configured.x + offset.x, configured.y + offset.y, configured.z + offset.z, (configured.w or 0.0) + (offset.w or 0.0)), pumpCoords.z, false)
	end

	local vehicleCoords = GetEntityCoords(vehicle)
	local directionX, directionY = normalizedDirection(vehicleCoords, pumpCoords)
	local sideX, sideY = -directionY, directionX
	local spawnDistance = cfg.spawnDistance or 5.0
	local candidates = {
		{ x = directionX, y = directionY, distance = spawnDistance },
		{ x = sideX, y = sideY, distance = spawnDistance },
		{ x = -sideX, y = -sideY, distance = spawnDistance },
		{ x = directionX, y = directionY, distance = spawnDistance + 4.0 },
	}

	if cfg.useStationPedCoords and station and station.pedcoords then
		local base = getVector4Coords(station.pedcoords)
		local offset = cfg.spawnOffset or vector4(4.0, 4.0, 0.0, 0.0)
		if base then
			local stationSpawn = resolveGroundCoords(vector4(base.x + offset.x, base.y + offset.y, pumpCoords.z, (base.w or 0.0) + (offset.w or 0.0)), pumpCoords.z, false)
			if #(vector3(stationSpawn.x, stationSpawn.y, stationSpawn.z) - pumpCoords) <= 30.0 and math.abs(stationSpawn.z - pumpCoords.z) <= 2.0 then
				return vector4(stationSpawn.x, stationSpawn.y, stationSpawn.z, headingTo(stationSpawn, pumpCoords))
			end
		end
	end

	for i = 1, #candidates do
		local candidate = candidates[i]
		local spawnCoords = offsetPoint(pumpCoords, candidate.x, candidate.y, candidate.distance, 0.0, pumpCoords.z, true)
		if math.abs(spawnCoords.z - pumpCoords.z) <= 2.0 and #(vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z) - vehicleCoords) >= 3.0 then
			return vector4(spawnCoords.x, spawnCoords.y, spawnCoords.z, headingTo(spawnCoords, pumpCoords))
		end
	end

	local spawnCoords = offsetPoint(pumpCoords, directionX, directionY, spawnDistance, 0.0, pumpCoords.z, false)
	return vector4(spawnCoords.x, spawnCoords.y, spawnCoords.z, headingTo(spawnCoords, pumpCoords))
end

local function walkTo(ped, coords, timeout, arriveDistance, useNavmesh)
	if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
		return false
	end

	arriveDistance = arriveDistance or 1.0
	if useNavmesh then
		TaskFollowNavMeshToCoord(ped, coords.x, coords.y, coords.z, 1.0, timeout or 10000, arriveDistance, false, coords.w or 0.0)
	else
		TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, 1.0, timeout or 10000, coords.w or 0.0, 0.2)
	end

	local deadline = GetGameTimer() + (timeout or 10000)
	while #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) > arriveDistance do
		Wait(250)
		if not DoesEntityExist(ped) or IsEntityDead(ped) then
			return false
		end

		if GetGameTimer() > deadline then
			ClearPedTasks(ped)
			return false
		end
	end

	ClearPedTasks(ped)
	SetEntityHeading(ped, coords.w or GetEntityHeading(ped))
	return true
end

local function isPedNearPump(ped, pumpCoords)
	if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
		return false
	end

	return #(GetEntityCoords(ped) - pumpCoords) <= (attendantConfig().pumpReachDistance or 3.2)
end

local function isPedNearFuelPort(ped, vehicle, fuelPortCoords, serviceCoords)
	if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
		return false
	end

	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
		return false
	end

	local pedCoords = GetEntityCoords(ped)
	local portFlat = vector3(fuelPortCoords.x, fuelPortCoords.y, pedCoords.z)
	local serviceFlat = vector3(serviceCoords.x, serviceCoords.y, pedCoords.z)
	local cfg = attendantConfig()

	return #(pedCoords - serviceFlat) <= (cfg.vehicleReachDistance or 2.0) and #(pedCoords - portFlat) <= (cfg.fuelPortReachDistance or 3.0) and #(pedCoords - GetEntityCoords(vehicle)) <= 4.0
end

local function isPedCloseEnoughToFuel(ped, vehicle, fuelPortCoords)
	if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
		return false
	end

	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
		return false
	end

	local cfg = attendantConfig()
	local pedCoords = GetEntityCoords(ped)
	local portFlat = vector3(fuelPortCoords.x, fuelPortCoords.y, pedCoords.z)

	return #(pedCoords - portFlat) <= ((cfg.fuelPortReachDistance or 3.0) + 0.75) and #(pedCoords - GetEntityCoords(vehicle)) <= 4.0
end

local function faceFuelPort(ped, fuelPortCoords)
	local pedCoords = GetEntityCoords(ped)
	SetEntityHeading(ped, headingTo(pedCoords, fuelPortCoords))
	TaskTurnPedToFaceCoord(ped, fuelPortCoords.x, fuelPortCoords.y, fuelPortCoords.z, 800)
	Wait(800)
end

local function startRefuelAnimation(ped)
	ClearPedTasks(ped)
	LoadAnimDict(Config.RefuelAnimationDictionary)
	TaskPlayAnim(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 8.0, 1.0, -1, 1, 0, false, false, false)
	Wait(250)

	if not IsEntityPlayingAnim(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 3) then
		TaskPlayAnim(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 8.0, 1.0, -1, 1, 0, false, false, false)
	end
end

local function adjustToFuelPort(ped, vehicle, serviceCoords, fuelPortCoords)
	if isPedNearFuelPort(ped, vehicle, fuelPortCoords, serviceCoords) then
		faceFuelPort(ped, fuelPortCoords)
		return true
	end

	walkTo(ped, serviceCoords, 4000, 1.25, false)

	if isPedNearFuelPort(ped, vehicle, fuelPortCoords, serviceCoords) or isPedCloseEnoughToFuel(ped, vehicle, fuelPortCoords) then
		faceFuelPort(ped, fuelPortCoords)
		return true
	end

	return false
end

local function playPickupAnim(ped)
	LoadAnimDict("anim@am_hold_up@male")
	TaskPlayAnim(ped, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, 900, 50, 0, false, false, false)
	PlayFuelSound("pickupnozzle", 0.4)
	Wait(600)
	StopAnimTask(ped, "anim@am_hold_up@male", "shoplift_high", 1.0)
end

local function attachNozzleToPed(ped)
	AttendantFuel.nozzle = CreateObject(joaat('prop_cs_fuel_nozle'), 1.0, 1.0, 1.0, true, true, false)
	local leftHand = GetPedBoneIndex(ped, 18905)
	AttachEntityToEntity(AttendantFuel.nozzle, ped, leftHand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, false, true, false, true, 0, true)
end

local function attachRopeToPump(pumpCoords, pump, location)
	if not Config.PumpHose or not pump or pump == 0 or not DoesEntityExist(pump) then return end

	RopeLoadTextures()
	while not RopeAreTexturesLoaded() do
		Wait(0)
		RopeLoadTextures()
	end

	local pumpHeightAdd = 2.1
	if Config.GasStations[location] and Config.GasStations[location].pumpheightadd then
		pumpHeightAdd = Config.GasStations[location].pumpheightadd
	end

	AttendantFuel.rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z, 0.0, 0.0, 0.0, 3.0, Config.RopeType['fuel'], 8.0, 0.0, 1.0, false, false, false, 1.0, true)
	if not AttendantFuel.rope then return end

	ActivatePhysics(AttendantFuel.rope)
	Wait(100)

	local nozzlePos = GetOffsetFromEntityInWorldCoords(AttendantFuel.nozzle, 0.0, -0.033, -0.195)
	local ropeLength = #(pumpCoords - nozzlePos) + 1.5
	AttachEntitiesToRope(AttendantFuel.rope, pump, AttendantFuel.nozzle, pumpCoords.x, pumpCoords.y, pumpCoords.z + pumpHeightAdd, nozzlePos.x, nozzlePos.y, nozzlePos.z, ropeLength, false, false, nil, nil)
end

local function findClosestFuelPump(coords, radius)
	local closestPump = nil
	local closestCoords = nil
	local closestDistance = nil

	for i = 1, #FuelPumpModels do
		local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, joaat(FuelPumpModels[i]), true, true, true)
		if pump and pump ~= 0 and DoesEntityExist(pump) then
			local pumpCoords = GetEntityCoords(pump)
			local distance = #(coords - pumpCoords)
			if not closestDistance or distance < closestDistance then
				closestPump = pump
				closestCoords = pumpCoords
				closestDistance = distance
			end
		end
	end

	return closestPump, closestCoords
end

local function getPumpFromTarget(data, vehicle)
	local entity = data and data.entity
	if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) ~= 2 then
		return entity, GetEntityCoords(entity)
	end

	local playerCoords = GetEntityCoords(PlayerPedId())
	local pumpCoords, pump = GetClosestPump(playerCoords, false)
	if pump and pump ~= 0 and DoesEntityExist(pump) then
		return pump, pumpCoords
	end

	pumpCoords, pump = GetClosestPump(GetEntityCoords(vehicle), false)
	if pump and pump ~= 0 and DoesEntityExist(pump) then
		return pump, pumpCoords
	end

	local cfg = attendantConfig()
	pump, pumpCoords = findClosestFuelPump(playerCoords, cfg.pumpDistance or 4.0)
	if pump and pumpCoords then
		return pump, pumpCoords
	end

	pump, pumpCoords = findClosestFuelPump(GetEntityCoords(vehicle), cfg.pumpDistance or 4.0)
	if pump and pumpCoords then
		return pump, pumpCoords
	end

	return nil, nil
end

local function getVehicleFromTarget(data)
	local entity = data and data.entity
	if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
		return entity
	end

	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
		return vehicle
	end

	vehicle = GetClosestVehicle()
	if vehicle and vehicle ~= -1 and DoesEntityExist(vehicle) then
		return vehicle
	end

	return nil
end

local function resolveServiceTargets(data)
	local vehicle = getVehicleFromTarget(data)
	if not vehicle then
		return nil, nil, nil, Translate("attendant_no_vehicle")
	end

	if Config.ElectricVehicleCharging and GetCurrentVehicleType(vehicle) == 'electricvehicle' then
		return nil, nil, nil, Translate("need_electric_charger")
	end

	if IsVehicleBlacklisted(vehicle) then
		return nil, nil, nil, Translate("attendant_unavailable")
	end

	local pump, pumpCoords = getPumpFromTarget(data, vehicle)
	if not pump or not pumpCoords then
		return nil, nil, nil, Translate("attendant_unavailable")
	end

	local cfg = attendantConfig()
	local vehicleCoords = GetEntityCoords(vehicle)
	local playerDistance = #(GetEntityCoords(PlayerPedId()) - vehicleCoords)
	local pumpDistance = #(pumpCoords - vehicleCoords)
	if playerDistance > (cfg.vehicleDistance or 6.0) and pumpDistance > (cfg.pumpDistance or 4.0) then
		return nil, nil, nil, Translate("attendant_vehicle_too_far")
	end

	if pumpDistance > (cfg.pumpDistance or 4.0) then
		return nil, nil, nil, Translate("attendant_vehicle_too_far")
	end

	return vehicle, pump, pumpCoords
end

function CanCallFuelAttendant(entity)
	if not Config.AttendantFuel or not Config.AttendantFuel.enabled or not IsInGasStation() then
		return false
	end

	local vehicle = nil
	if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
		vehicle = entity
	else
		vehicle = getVehicleFromTarget(nil)
	end

	if not vehicle then
		return false
	end

	local _, _, _, errorMessage = resolveServiceTargets({ entity = vehicle })
	return errorMessage == nil
end exports('CanCallFuelAttendant', CanCallFuelAttendant)

local function openAttendantInput(quote, currentFuel, maxFuel)
	local totalToFill = math.ceil((maxFuel * quote.fuelPrice) + GlobalTax(maxFuel * quote.fuelPrice) + quote.serviceFee)

	if Config.Ox.Input then
		local input = lib.inputDialog(Translate("attendant_input_header"), {
			{ type = "input", label = Translate("attendant_input_fuel_price"), default = "$" .. quote.fuelPrice .. " / litro", disabled = true },
			{ type = "input", label = Translate("attendant_input_current_fuel"), default = math.floor(currentFuel) .. "L", disabled = true },
			{ type = "input", label = Translate("attendant_input_max_fuel"), default = maxFuel .. "L", disabled = true },
			{ type = "slider", label = Translate("attendant_input_total") .. ": $" .. totalToFill, default = maxFuel, min = 1, max = maxFuel },
			{
				type = "select",
				label = Translate("attendant_input_payment"),
				default = "cash",
				options = {
					{ value = "cash", label = Translate("attendant_pay_cash") },
					{ value = "bank", label = Translate("attendant_pay_bank") },
				},
				required = true,
			},
		})

		if not input then return nil end
		return tonumber(input[4]), input[5] or "cash"
	end

	local input = exports['qb-input']:ShowInput({
		header = Translate("attendant_input_header"),
		submitText = Translate("call_attendant"),
		inputs = {
			{
				type = 'number',
				isRequired = true,
				name = 'amount',
				text = Translate("attendant_input_amount") .. " (1-" .. maxFuel .. "L)"
			},
			{
				type = 'radio',
				isRequired = true,
				name = 'purchasetype',
				options = {
					{ value = 'cash', text = Translate("attendant_pay_cash") },
					{ value = 'bank', text = Translate("attendant_pay_bank") },
				}
			},
		}
	})

	if not input then return nil end
	return tonumber(input.amount), input.purchasetype or "cash"
end

local function returnNozzleToPump(ped, pumpApproachCoords)
	if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
		cleanupNozzle()
		return
	end

	Notify(Translate("attendant_returning"), 'primary', 3500)
	StopAnimTask(ped, Config.RefuelAnimationDictionary, Config.RefuelAnimation, 2.0)
	PlayFuelSound("fuelstop", 0.4)
	if walkTo(ped, pumpApproachCoords, attendantConfig().approachTimeout or 15000, 1.6, true) then
		playPickupAnim(ped)
	end
	cleanupNozzle()
end

local function finishAttendantScene(ped, spawnCoords)
	if ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) then
		walkTo(ped, spawnCoords, attendantConfig().approachTimeout or 15000, 1.5, true)
		TaskStartScenarioInPlace(ped, attendantConfig().smokeScenario or "WORLD_HUMAN_SMOKING", 0, true)
		Wait(attendantConfig().smokeTime or 15000)
	end

	cleanupAttendant()
end

local function cancelAttendantService(message)
	finishPaidService(false)
	if message then
		Notify(message, 'error', 7500)
	end
	cleanupAttendant()
end

local function cancelAfterNozzle(message, ped, pumpApproachCoords, spawnCoords)
	finishPaidService(false)
	if message then
		Notify(message, 'error', 7500)
	end
	returnNozzleToPump(ped, pumpApproachCoords)
	finishAttendantScene(ped, spawnCoords)
end

local function runAttendantService(vehicle, pump, pumpCoords, location, amount)
	local cfg = attendantConfig()
	local modelHash = loadModel(cfg.pedModel or "s_m_m_autoshop_01")
	if not modelHash then
		finishPaidService(false)
		cleanupAttendant()
		Notify(Translate("attendant_unavailable"), 'error', 7500)
		return
	end

	AttendantFuel.active = true
	AttendantFuel.paid = true

	local pumpApproachCandidates = getPumpApproachCandidates(pumpCoords, vehicle)
	local pumpApproachCoords = pumpApproachCandidates[1]
	local spawnCoords = getSpawnCoords(location, pumpCoords, vehicle)

	RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
	AttendantFuel.ped = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, false, true)
	SetModelAsNoLongerNeeded(modelHash)

	if not AttendantFuel.ped or AttendantFuel.ped == 0 then
		cancelAttendantService(Translate("attendant_unavailable"))
		return
	end

	FreezeEntityPosition(AttendantFuel.ped, true)
	SetEntityInvincible(AttendantFuel.ped, true)
	SetPedDiesWhenInjured(AttendantFuel.ped, false)
	SetBlockingOfNonTemporaryEvents(AttendantFuel.ped, true)
	SetPedCanRagdoll(AttendantFuel.ped, false)
	SetEntityCoordsNoOffset(AttendantFuel.ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
	SetEntityHeading(AttendantFuel.ped, spawnCoords.w)

	local collisionTimeout = GetGameTimer() + 3000
	while not HasCollisionLoadedAroundEntity(AttendantFuel.ped) and GetGameTimer() < collisionTimeout do
		RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
		Wait(50)
	end

	FreezeEntityPosition(AttendantFuel.ped, false)

	Notify(Translate("attendant_started"), 'success', 5000)

	local reachedPump = false
	local pumpAttemptTimeout = cfg.pumpAttemptTimeout or 6000
	for i = 1, #pumpApproachCandidates do
		pumpApproachCoords = pumpApproachCandidates[i]
		if walkTo(AttendantFuel.ped, pumpApproachCoords, pumpAttemptTimeout, 1.6, true) or isPedNearPump(AttendantFuel.ped, pumpCoords) then
			reachedPump = true
			break
		end
	end

	if not reachedPump then
		cancelAttendantService(Translate("attendant_cancelled"))
		return
	end

	if not isPedNearPump(AttendantFuel.ped, pumpCoords) then
		cancelAttendantService(Translate("attendant_cancelled"))
		return
	end

	TaskTurnPedToFaceEntity(AttendantFuel.ped, pump, 800)
	Wait(800)
	playPickupAnim(AttendantFuel.ped)
	attachNozzleToPed(AttendantFuel.ped)
	attachRopeToPump(pumpCoords, pump, location)

	local fuelCoords, fuelPortCoords = getVehicleApproachCoords(vehicle, pumpCoords)
	local reachedFuelArea = walkTo(AttendantFuel.ped, fuelCoords, cfg.approachTimeout or 15000, 1.2, true)
	if not reachedFuelArea and not isPedCloseEnoughToFuel(AttendantFuel.ped, vehicle, fuelPortCoords) then
		cancelAfterNozzle(Translate("attendant_cancelled"), AttendantFuel.ped, pumpApproachCoords, spawnCoords)
		return
	end

	if not adjustToFuelPort(AttendantFuel.ped, vehicle, fuelCoords, fuelPortCoords) then
		cancelAfterNozzle(Translate("attendant_vehicle_too_far"), AttendantFuel.ped, pumpApproachCoords, spawnCoords)
		return
	end

	startRefuelAnimation(AttendantFuel.ped)
	PlayFuelSound("refuel", 0.3)

	local duration = amount * Config.RefuelTime
	if amount < 10 then duration = 10 * Config.RefuelTime end

	local completed = true
	if Config.Ox.Progress then
		completed = lib.progressCircle({
			duration = duration,
			label = Translate("attendant_refueling"),
			position = 'bottom',
			useWhileDead = false,
			canCancel = false,
			disable = {
				combat = true
			},
		})
	else
		Wait(duration)
	end

	local stillCloseToFuel = isPedNearFuelPort(AttendantFuel.ped, vehicle, fuelPortCoords, fuelCoords) or isPedCloseEnoughToFuel(AttendantFuel.ped, vehicle, fuelPortCoords)
	if completed and DoesEntityExist(vehicle) and DoesEntityExist(AttendantFuel.ped) and not IsEntityDead(AttendantFuel.ped) and stillCloseToFuel and #(GetEntityCoords(vehicle) - pumpCoords) <= (cfg.pumpDistance or 4.0) then
		SetFuel(vehicle, math.min(100.0, GetFuel(vehicle) + amount))
		finishPaidService(true)
		Notify(Translate("attendant_finished"), 'success', 5000)
	else
		finishPaidService(false)
		Notify(Translate("attendant_cancelled"), 'error', 7500)
	end

	returnNozzleToPump(AttendantFuel.ped, pumpApproachCoords)
	finishAttendantScene(AttendantFuel.ped, spawnCoords)
end

RegisterNetEvent('cdn-fuel:client:attendant:openMenu', function(data)
	if not Config.AttendantFuel or not Config.AttendantFuel.enabled then
		Notify(Translate("attendant_unavailable"), 'error', 7500)
		return
	end

	if AttendantFuel.active then
		Notify(Translate("attendant_busy"), 'error', 7500)
		return
	end

	if not IsInGasStation() then
		Notify(Translate("attendant_unavailable"), 'error', 7500)
		return
	end

	local vehicle, pump, pumpCoords, errorMessage = resolveServiceTargets(data)
	if not vehicle then
		Notify(errorMessage or Translate("attendant_unavailable"), 'error', 7500)
		return
	end

	local location = FetchCurrentLocation()
	local quote = lib.callback.await('cdn-fuel:server:attendant:getQuote', 200, location, GetVehicleClass(vehicle))
	if not quote or not quote.ok then
		Notify(Translate((quote and quote.message) or "attendant_unavailable"), 'error', 7500)
		return
	end

	local currentFuel = GetFuel(vehicle)
	if currentFuel >= 99.0 then
		Notify(Translate("tank_already_full"), 'error', 7500)
		return
	end

	local maxFuel = math.floor(100.0 - currentFuel)
	if quote.reserves and not quote.unlimited then
		maxFuel = math.min(maxFuel, math.floor(tonumber(quote.reserves) or 0))
	end

	if maxFuel < 1 then
		Notify(Translate("station_no_fuel"), 'error', 7500)
		return
	end

	local amount, purchasetype = openAttendantInput(quote, currentFuel, maxFuel)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then
		Notify(Translate("more_than_zero"), 'error', 7500)
		return
	end

	if amount > maxFuel then
		Notify(Translate("tank_cannot_fit"), 'error', 7500)
		return
	end

	local payment = lib.callback.await('cdn-fuel:server:attendant:start', 200, {
		location = location,
		amount = amount,
		purchasetype = purchasetype,
		vehicleClass = GetVehicleClass(vehicle),
	})

	if not payment or not payment.ok then
		Notify(Translate((payment and payment.message) or "attendant_payment_failed"), 'error', 7500)
		return
	end

	AttendantFuel.active = true
	AttendantFuel.paid = true

	CreateThread(function()
		runAttendantService(vehicle, pump, pumpCoords, location, amount)
	end)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	finishPaidService(false)
	cleanupAttendant()
end)
