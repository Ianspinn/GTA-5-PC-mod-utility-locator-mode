-- Utility Locate — client
-- Transmitter + receiver buried-utility locating job.
--
-- Loop: pick up a ticket at the depot -> drive to the site ->
-- hook up the transmitter at the access point -> walk the
-- receiver, follow the tone -> paint marks on the line ->
-- close the ticket and get paid on accuracy.

local currentTicket = nil -- site table from Config.Sites
local lastTicketIndex = 0
local transmitterOn = false
local transmitterObj = nil
local receiverOn = false
local marks = {} -- { x, y, z, dist }
local siteBlip = nil
local depotBlip = nil
local truck = nil
local nextBeep = 0

local KEY_E = 38 -- INPUT_CONTEXT

-- ---------- helpers ----------

local function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

local function ShowHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function GroundZ(x, y, z)
    local found, gz = GetGroundZFor_3dCoord(x, y, z + 50.0, 0.0, false)
    if found then return gz end
    return z
end

-- 2D distance from point (px, py) to segment a -> b
local function DistToSegment(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local lenSq = dx * dx + dy * dy
    local t = 0.0
    if lenSq > 0 then
        t = ((px - ax) * dx + (py - ay) * dy) / lenSq
        t = math.max(0.0, math.min(1.0, t))
    end
    local cx, cy = ax + t * dx, ay + t * dy
    return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2)
end

-- Signal strength 0-1 plus true distance to the line.
-- Deeper lines read slightly weaker; a little noise keeps
-- the needle feeling analogue instead of digital.
local function SignalAt(x, y)
    if not currentTicket then return 0.0, 999.0 end
    local a, b = currentTicket.line[1], currentTicket.line[2]
    local dist = DistToSegment(x, y, a.x, a.y, b.x, b.y)
    local depthFactor = 1.0 - (currentTicket.depth * 0.08)
    local strength = math.max(0.0, 1.0 - (dist / Config.MaxSignalDistance)) * depthFactor
    strength = strength + (math.random() - 0.5) * 0.04
    return math.max(0.0, math.min(1.0, strength)), dist
end

local function MakeBlip(coords, sprite, colour, name, route)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    if route then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, colour)
    end
    return blip
end

-- ---------- job flow ----------

local function SpawnTruck()
    if DoesEntityExist(truck) then return end
    local model = GetHashKey(Config.TruckModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    truck = CreateVehicle(model, Config.TruckSpawn.x, Config.TruckSpawn.y, Config.TruckSpawn.z, Config.TruckHeading, true, false)
    SetEntityAsMissionEntity(truck, true, true)
    SetVehicleNumberPlateText(truck, 'LOCATE1')
    SetModelAsNoLongerNeeded(model)
    Notify('Your utility truck is waiting at the yard.')
end

local function StartJob()
    local idx = math.random(#Config.Sites)
    if #Config.Sites > 1 then
        while idx == lastTicketIndex do idx = math.random(#Config.Sites) end
    end
    lastTicketIndex = idx
    currentTicket = Config.Sites[idx]
    marks = {}
    transmitterOn = false
    receiverOn = false
    local util = Config.Utilities[currentTicket.utility]
    siteBlip = MakeBlip(currentTicket.access, 1, util.blip, 'Locate: ' .. currentTicket.label, true)
    Notify(string.format('~y~New locate ticket:~s~ %s — %s, %.1fm deep. Head to the site and hook up the transmitter.', currentTicket.label, util.label, currentTicket.depth))
    SpawnTruck()
end

local function DeployTransmitter()
    local ped = PlayerPedId()
    local pos = currentTicket.access
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)
    ShowHelp('Hooking up transmitter...')
    Wait(3000)
    ClearPedTasks(ped)
    local model = GetHashKey('prop_tool_box_04')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local gz = GroundZ(pos.x, pos.y, pos.z)
    transmitterObj = CreateObject(model, pos.x, pos.y, gz, true, false, false)
    PlaceObjectOnGroundProperly(transmitterObj)
    SetEntityAsMissionEntity(transmitterObj, true, true)
    SetModelAsNoLongerNeeded(model)
    transmitterOn = true
    PlaySoundFrontend(-1, 'Beep_Green', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    Notify('Transmitter live on the ' .. Config.Utilities[currentTicket.utility].label .. ' line. Press G to power up the receiver.')
end

local function ToggleReceiver()
    if not currentTicket or not transmitterOn then
        Notify('No live transmitter. Hook one up at the access point first.')
        return
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        Notify('Get out of the truck to walk the locate.')
        return
    end
    receiverOn = not receiverOn
    SendNUIMessage({ action = 'setVisible', visible = receiverOn })
    if receiverOn then
        Notify('Receiver on — sweep the area and follow the tone.')
    else
        Notify('Receiver off.')
    end
end

local function CleanupJob()
    if transmitterObj and DoesEntityExist(transmitterObj) then
        DeleteObject(transmitterObj)
    end
    transmitterObj = nil
    transmitterOn = false
    receiverOn = false
    SendNUIMessage({ action = 'setVisible', visible = false })
    if siteBlip and DoesBlipExist(siteBlip) then RemoveBlip(siteBlip) end
    siteBlip = nil
    currentTicket = nil
    marks = {}
end

local function CompleteJob()
    local total = 0.0
    for _, m in ipairs(marks) do total = total + m.dist end
    local avg = total / math.max(1, #marks)
    local accuracy = math.max(0.0, math.min(1.0, 1.0 - (avg / Config.MarkDistance)))
    local pay = Config.PayBase + math.floor(Config.PayAccuracyBonus * accuracy + 0.5)
    TriggerServerEvent('utility-locate:complete', currentTicket.label, accuracy, pay)
    Notify(string.format('Locate closed — accuracy %d%%. Payout $%d.', math.floor(accuracy * 100 + 0.5), pay))
    CleanupJob()
end

local function TryPaintMark()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local _, dist = SignalAt(pos.x, pos.y)
    if dist > Config.MarkDistance then
        Notify('No signal here — move until the tone peaks.')
        return
    end
    for _, m in ipairs(marks) do
        if #(vector3(pos.x, pos.y, 0.0) - vector3(m.x, m.y, 0.0)) < Config.MinMarkSpacing then
            Notify('Too close to your last mark — walk further down the line.')
            return
        end
    end
    local gz = GroundZ(pos.x, pos.y, pos.z)
    marks[#marks + 1] = { x = pos.x, y = pos.y, z = gz, dist = dist }
    PlaySoundFrontend(-1, 'Beep_Green', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    Notify('Mark ' .. #marks .. '/' .. Config.MarksRequired .. ' painted.')
    if #marks >= Config.MarksRequired then
        CompleteJob()
    end
end

RegisterCommand('receiver', ToggleReceiver, false)
RegisterKeyMapping('receiver', 'Toggle utility locator receiver', 'keyboard', 'G')

RegisterCommand('locate', function()
    if currentTicket then
        Notify('You already have an open ticket — finish it or /cancellocate first.')
    else
        StartJob()
    end
end, false)

RegisterCommand('cancellocate', function()
    if currentTicket then
        CleanupJob()
        Notify('Locate ticket cancelled.')
    end
end, false)

-- ---------- main interaction thread ----------

CreateThread(function()
    depotBlip = MakeBlip(Config.Depot, 50, 5, 'Utility Locate Depot', false)

    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local wait = 500

        -- Depot marker: pick up a ticket
        local depotDist = #(pos - Config.Depot)
        if depotDist < 25.0 then
            wait = 0
            DrawMarker(1, Config.Depot.x, Config.Depot.y, Config.Depot.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 255, 200, 0, 120, false, false, 2, false, nil, nil, false)
            if depotDist < 3.0 then
                if currentTicket then
                    ShowHelp('You already have an open locate ticket.')
                else
                    ShowHelp('Press ~INPUT_CONTEXT~ to pick up a locate ticket')
                    if IsControlJustReleased(0, KEY_E) then StartJob() end
                end
            end
        end

        if currentTicket then
            local util = Config.Utilities[currentTicket.utility]

            -- Access point: hook up the transmitter
            if not transmitterOn then
                local access = currentTicket.access
                local aDist = #(pos - access)
                if aDist < 25.0 then
                    wait = 0
                    local gz = GroundZ(access.x, access.y, access.z)
                    DrawMarker(1, access.x, access.y, gz - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, util.r, util.g, util.b, 120, false, false, 2, false, nil, nil, false)
                    if aDist < 3.0 then
                        ShowHelp('Press ~INPUT_CONTEXT~ to hook up the transmitter')
                        if IsControlJustReleased(0, KEY_E) then DeployTransmitter() end
                    end
                end
            end

            -- Paint marks + paint prompt
            if transmitterOn then
                for _, m in ipairs(marks) do
                    DrawMarker(1, m.x, m.y, m.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.05, util.r, util.g, util.b, 200, false, false, 2, false, nil, nil, false)
                end
                if receiverOn then
                    wait = 0
                    local _, dist = SignalAt(pos.x, pos.y)
                    if dist <= Config.MarkDistance then
                        ShowHelp('On the line — press ~INPUT_CONTEXT~ to paint a mark')
                        if IsControlJustReleased(0, KEY_E) then TryPaintMark() end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

-- ---------- receiver thread: HUD + tone ----------

CreateThread(function()
    while true do
        if receiverOn and currentTicket and transmitterOn then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local strength, dist
            if #(pos - currentTicket.access) > Config.TransmitterRange then
                strength, dist = 0.0, 999.0
            else
                strength, dist = SignalAt(pos.x, pos.y)
            end

            local status = 'NO SIGNAL'
            if strength > 0.85 then status = 'ON THE LINE'
            elseif strength > 0.5 then status = 'STRONG'
            elseif strength > 0.2 then status = 'WEAK'
            elseif strength > 0.03 then status = 'FAINT' end

            SendNUIMessage({
                action = 'update',
                strength = math.floor(strength * 100 + 0.5),
                utility = Config.Utilities[currentTicket.utility].label,
                depth = currentTicket.depth,
                marks = #marks,
                required = Config.MarksRequired,
                status = status,
            })

            -- Audio tone: faster beeps = stronger signal
            local now = GetGameTimer()
            if strength > 0.03 and now >= nextBeep then
                PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
                local interval = 900 - (strength * 800) -- 900ms weak -> 100ms peak
                nextBeep = now + math.floor(interval)
            end
            Wait(100)
        else
            Wait(500)
        end
    end
end)
