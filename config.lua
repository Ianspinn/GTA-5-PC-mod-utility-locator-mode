Config = {}

-- ============================================================
-- Utility Locate — configuration
-- Buried-utility locating job for FiveM (GTA V)
-- APWA paint colours: red = electric, yellow = gas,
-- orange = fiber/comms, blue = water, green = sewer
-- ============================================================

-- Job hub: utility yard, Cypress Flats
Config.Depot        = vector3(560.0, -1700.0, 29.0)
Config.TruckSpawn   = vector3(552.0, -1690.0, 29.0)
Config.TruckHeading = 270.0
Config.TruckModel   = 'utillitruck3' -- GTA V utility truck

-- Gameplay tuning
Config.MarksRequired     = 4    -- paint marks needed to close a ticket
Config.MinMarkSpacing    = 4.0  -- metres between marks along the line
Config.MarkDistance      = 2.5  -- how close to the true line you must be to paint
Config.MaxSignalDistance = 15.0 -- receiver hears the signal inside this range
Config.TransmitterRange  = 60.0 -- receiver only works this far from the transmitter

-- Pay (standalone mode just reports it; ESX / QBCore actually pay it out)
Config.PayBase          = 250
Config.PayAccuracyBonus = 250 -- scaled 0-1 by mark accuracy

-- 'standalone', 'esx' or 'qbcore'
Config.Framework = 'standalone'

Config.Utilities = {
    electric = { label = 'Electric',      r = 255, g = 0,   b = 0,   blip = 1  },
    gas      = { label = 'Gas',           r = 255, g = 255, b = 0,   blip = 5  },
    fiber    = { label = 'Fiber / Comms', r = 255, g = 128, b = 0,   blip = 17 },
    water    = { label = 'Water',         r = 0,   g = 120, b = 255, blip = 3  },
    sewer    = { label = 'Sewer',         r = 0,   g = 200, b = 80,  blip = 2  },
}

-- Locate tickets. Each site is one buried line segment.
-- line: start/end as vector2 (x, y) — depth is simulated, not z-based,
-- so lines work on slopes and uneven ground.
-- access: where the transmitter hooks up (pedestal / valve box).
Config.Sites = {
    { label = 'Legion Square',   utility = 'electric', depth = 0.9, line = { vector2(190.0, -900.0),  vector2(260.0, -820.0)  }, access = vector3(186.0, -904.0, 30.0) },
    { label = 'Vinewood Blvd',   utility = 'fiber',    depth = 0.6, line = { vector2(250.0, 180.0),   vector2(330.0, 120.0)   }, access = vector3(246.0, 184.0, 105.0) },
    { label = 'Mirror Park',     utility = 'gas',      depth = 1.2, line = { vector2(1080.0, -650.0), vector2(1160.0, -580.0) }, access = vector3(1076.0, -654.0, 57.0) },
    { label = 'Del Perro Pier',  utility = 'water',    depth = 1.5, line = { vector2(-1550.0, -750.0), vector2(-1470.0, -690.0) }, access = vector3(-1554.0, -754.0, 5.0) },
    { label = 'Sandy Shores',    utility = 'electric', depth = 0.9, line = { vector2(1380.0, 3610.0), vector2(1460.0, 3670.0) }, access = vector3(1376.0, 3606.0, 34.0) },
    { label = 'Grapeseed',       utility = 'fiber',    depth = 0.6, line = { vector2(1720.0, 4950.0), vector2(1800.0, 5010.0) }, access = vector3(1716.0, 4946.0, 42.0) },
    { label = 'Paleto Bay',      utility = 'gas',      depth = 1.2, line = { vector2(-250.0, 6310.0), vector2(-170.0, 6370.0) }, access = vector3(-254.0, 6306.0, 32.0) },
    { label = 'Cypress Flats',   utility = 'water',    depth = 1.5, line = { vector2(650.0, -1650.0), vector2(730.0, -1580.0) }, access = vector3(646.0, -1654.0, 30.0) },
    { label = 'Vespucci Beach',  utility = 'fiber',    depth = 0.6, line = { vector2(-1200.0, -1380.0), vector2(-1130.0, -1310.0) }, access = vector3(-1204.0, -1384.0, 5.0) },
    { label = 'Banham Canyon',   utility = 'electric', depth = 0.9, line = { vector2(-2100.0, 4800.0), vector2(-2020.0, 4870.0) }, access = vector3(-2104.0, 4796.0, 40.0) },
}
