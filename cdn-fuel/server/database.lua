local function defaultFuelPrice()
    return math.floor(tonumber(Config.CostMultiplier) or 3)
end

CreateThread(function()
    if not Config.PlayerOwnedGasStationsEnabled then return end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `fuel_stations` (
            `location` int(11) NOT NULL,
            `owned` int(11) DEFAULT 0,
            `owner` varchar(50) DEFAULT '0',
            `fuel` int(11) DEFAULT 100000,
            `fuelprice` int(11) DEFAULT 3,
            `balance` int(255) DEFAULT 0,
            `label` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`location`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    for location, station in pairs(Config.GasStations or {}) do
        MySQL.insert.await([[
            INSERT IGNORE INTO `fuel_stations`
                (`location`, `owned`, `owner`, `fuel`, `fuelprice`, `balance`, `label`)
            VALUES (?, 0, '0', ?, ?, 0, ?)
        ]], {
            location,
            tonumber(Config.MaxFuelReserves) or 100000,
            defaultFuelPrice(),
            station.label or ('Posto %s'):format(location),
        })
    end
end)
