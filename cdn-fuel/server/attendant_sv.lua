local ActiveAttendantServices = {}

local CoreObject = nil
if Config.Core ~= "ESX" then
	CoreObject = exports[Config.Core]:GetCoreObject()
else
	ESX = ESX or exports["es_extended"]:getSharedObject()
end

local function globalTax(value)
	if Config.GlobalTax < 0.1 then
		return 0
	end

	return value / 100 * Config.GlobalTax
end

local function getPlayer(src)
	if Config.Core == "ESX" then
		return ESX.GetPlayerFromId(src)
	end

	return CoreObject.Functions.GetPlayer(src)
end

local function normalizePaymentType(purchasetype)
	if purchasetype == "bank" then
		return "bank"
	end

	return "cash"
end

local function getMoney(player, account)
	if Config.Core == "ESX" then
		if account == "bank" then
			local bank = player.getAccount("bank")
			return bank and bank.money or 0
		end

		return player.getMoney()
	end

	return player.PlayerData.money[account] or 0
end

local function removeMoney(player, account, amount, reason)
	if amount <= 0 then return true end

	if Config.Core == "ESX" then
		if account == "bank" then
			player.removeAccountMoney("bank", amount)
		else
			player.removeMoney(amount)
		end

		return true
	end

	return player.Functions.RemoveMoney(account, amount, reason)
end

local function addMoney(player, account, amount, reason)
	if amount <= 0 then return true end

	if Config.Core == "ESX" then
		if account == "bank" then
			player.addAccountMoney("bank", amount)
		else
			player.addMoney(amount)
		end

		return true
	end

	return player.Functions.AddMoney(account, amount, reason)
end

local function playerJob(player)
	if Config.Core == "ESX" then
		local job = player.getJob()
		return job and job.name, true
	end

	local job = player.PlayerData and player.PlayerData.job or {}
	return job.name, job.onduty
end

local function getsEmergencyDiscount(player, vehicleClass)
	if not Config.EmergencyServicesDiscount or not Config.EmergencyServicesDiscount.enabled then
		return false
	end

	if Config.EmergencyServicesDiscount.emergency_vehicles_only and tonumber(vehicleClass) ~= 18 then
		return false
	end

	local jobName, onDuty = playerJob(player)
	local discountedJobs = Config.EmergencyServicesDiscount.job
	local jobMatches = false

	if type(discountedJobs) == "table" then
		for i = 1, #discountedJobs do
			if jobName == discountedJobs[i] then
				jobMatches = true
				break
			end
		end
	else
		jobMatches = jobName == discountedJobs
	end

	if not jobMatches then return false end
	if Config.Core ~= "ESX" and Config.EmergencyServicesDiscount.ondutyonly and not onDuty then
		return false
	end

	return true
end

local function stationRow(location)
	if not Config.PlayerOwnedGasStationsEnabled or Config.UnlimitedFuel then
		return nil
	end

	local result = MySQL.query.await('SELECT fuel, fuelprice, balance FROM fuel_stations WHERE location = ?', { location })
	return result and result[1] or nil
end

local function buildQuote(src, location, vehicleClass)
	if not Config.AttendantFuel or not Config.AttendantFuel.enabled then
		return nil, "attendant_unavailable"
	end

	location = tonumber(location)
	if not location or not Config.GasStations[location] then
		return nil, "attendant_unavailable"
	end

	if Config.PlayerOwnedGasStationsEnabled and Config.GasStations[location].shutoff then
		return nil, "emergency_shutoff_active"
	end

	local player = getPlayer(src)
	if not player then
		return nil, "attendant_unavailable"
	end

	local row = stationRow(location)
	if Config.PlayerOwnedGasStationsEnabled and not Config.UnlimitedFuel and not row then
		return nil, "attendant_unavailable"
	end

	local basePrice = Config.CostMultiplier
	if row and row.fuelprice then
		basePrice = tonumber(row.fuelprice) or basePrice
	end

	if Config.AirAndWaterVehicleFueling and Config.AirAndWaterVehicleFueling.enabled then
		vehicleClass = tonumber(vehicleClass)
		if vehicleClass == 14 then
			basePrice = Config.AirAndWaterVehicleFueling.water_fuel_price
		elseif vehicleClass == 15 or vehicleClass == 16 then
			basePrice = Config.AirAndWaterVehicleFueling.air_fuel_price
		end
	end

	local chargedPrice = basePrice
	if getsEmergencyDiscount(player, vehicleClass) then
		local discount = tonumber(Config.EmergencyServicesDiscount.discount) or 0
		discount = math.max(0, math.min(100, discount))
		chargedPrice = basePrice - (basePrice * (discount / 100))
	end

	return {
		location = location,
		fuelPrice = chargedPrice,
		stationFuelPrice = basePrice,
		reserves = row and tonumber(row.fuel) or nil,
		balance = row and tonumber(row.balance) or nil,
		unlimited = not Config.PlayerOwnedGasStationsEnabled or Config.UnlimitedFuel,
		serviceFee = tonumber(Config.AttendantFuel.serviceFee) or 0,
	}
end

lib.callback.register('cdn-fuel:server:attendant:getQuote', function(source, location, vehicleClass)
	local quote, message = buildQuote(source, location, vehicleClass)
	if not quote then
		return { ok = false, message = message or "attendant_unavailable" }
	end

	return {
		ok = true,
		fuelPrice = quote.fuelPrice,
		reserves = quote.reserves,
		unlimited = quote.unlimited,
		serviceFee = quote.serviceFee,
	}
end)

lib.callback.register('cdn-fuel:server:attendant:start', function(source, data)
	if ActiveAttendantServices[source] then
		return { ok = false, message = "attendant_busy" }
	end

	data = data or {}
	local amount = math.floor(tonumber(data.amount) or 0)
	if amount < 1 then
		return { ok = false, message = "more_than_zero" }
	end

	local quote, message = buildQuote(source, data.location, data.vehicleClass)
	if not quote then
		return { ok = false, message = message or "attendant_unavailable" }
	end

	if quote.reserves and not quote.unlimited and amount > math.floor(quote.reserves) then
		return { ok = false, message = "station_not_enough_fuel" }
	end

	local player = getPlayer(source)
	if not player then
		return { ok = false, message = "attendant_unavailable" }
	end

	local account = normalizePaymentType(data.purchasetype)
	local fuelCost = amount * quote.fuelPrice
	local total = math.ceil(fuelCost + globalTax(fuelCost) + quote.serviceFee)

	if getMoney(player, account) < total then
		if account == "bank" then
			return { ok = false, message = "not_enough_money_in_bank" }
		end

		return { ok = false, message = "not_enough_money_in_cash" }
	end

	if not removeMoney(player, account, total, Translate("menu_pay_label_1") .. quote.fuelPrice .. Translate("menu_pay_label_2")) then
		return { ok = false, message = "attendant_payment_failed" }
	end

	ActiveAttendantServices[source] = {
		location = quote.location,
		amount = amount,
		account = account,
		total = total,
		fuelPrice = quote.fuelPrice,
		stationFuelPrice = quote.stationFuelPrice,
	}

	return {
		ok = true,
		total = total,
		fuelPrice = quote.fuelPrice,
	}
end)

local function refundService(src, service)
	local player = getPlayer(src)
	if player then
		addMoney(player, service.account, service.total, Translate("phone_refund_payment_label"))
	end
end

local function updateStationSale(service)
	if not Config.PlayerOwnedGasStationsEnabled or Config.UnlimitedFuel then return end

	local row = stationRow(service.location)
	if not row then return end

	local currentFuel = tonumber(row.fuel) or 0
	local currentBalance = tonumber(row.balance) or 0
	local stationGetAmount = math.floor(Config.StationFuelSalePercentage * (service.stationFuelPrice * service.amount))
	local newFuel = math.max(0, currentFuel - service.amount)
	local newBalance = currentBalance + stationGetAmount

	MySQL.query.await('UPDATE fuel_stations SET fuel = ?, balance = ? WHERE location = ?', { newFuel, newBalance, service.location })
end

RegisterNetEvent('cdn-fuel:server:attendant:finish', function(success)
	local src = source
	local service = ActiveAttendantServices[src]
	if not service then return end

	if success then
		updateStationSale(service)
	else
		refundService(src, service)
	end

	ActiveAttendantServices[src] = nil
end)

AddEventHandler('playerDropped', function()
	local src = source
	local service = ActiveAttendantServices[src]
	if not service then return end

	refundService(src, service)
	ActiveAttendantServices[src] = nil
end)
