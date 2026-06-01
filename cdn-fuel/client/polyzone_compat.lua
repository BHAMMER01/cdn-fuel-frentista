local function pointInPolygon(point, polygon)
    local inside = false
    local j = #polygon

    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > point.y) ~= (yj > point.y)) and
            (point.x < (xj - xi) * (point.y - yi) / ((yj - yi) + 0.0) + xi) then
            inside = not inside
        end

        j = i
    end

    return inside
end

PolyZone = PolyZone or {}

function PolyZone:Create(points, options)
    options = options or {}

    local zone = {
        points = points,
        minZ = options.minZ or options.minz or -10000.0,
        maxZ = options.maxZ or options.maxz or 10000.0,
        destroyed = false,
    }

    function zone:isPointInside(coords)
        if coords.z < self.minZ or coords.z > self.maxZ then return false end
        return pointInPolygon(coords, self.points)
    end

    function zone:onPlayerInOut(callback)
        CreateThread(function()
            local wasInside = false

            while not self.destroyed do
                local inside = self:isPointInside(GetEntityCoords(PlayerPedId()))

                if inside ~= wasInside then
                    wasInside = inside
                    callback(inside)
                end

                Wait(500)
            end

            if wasInside then callback(false) end
        end)
    end

    function zone:destroy()
        self.destroyed = true
    end

    return zone
end
