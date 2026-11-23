-- Utility Locate — server
-- Validates payouts server-side so clients can't fake them.

RegisterNetEvent('utility-locate:complete', function(ticketLabel, accuracy, clientPay)
    local src = source
    accuracy = tonumber(accuracy) or 0.0
    accuracy = math.max(0.0, math.min(1.0, accuracy))
    -- Recompute the payout here; the client's number is never trusted.
    local pay = Config.PayBase + math.floor(Config.PayAccuracyBonus * accuracy + 0.5)

    local paid = false
    if Config.Framework == 'esx' then
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addMoney(pay)
                paid = true
            end
        end
    elseif Config.Framework == 'qbcore' then
        local ok, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and QBCore then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                Player.Functions.AddMoney('cash', pay)
                paid = true
            end
        end
    end

    local pct = math.floor(accuracy * 100 + 0.5)
    if paid then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^2[Utility Locate]', ('Ticket closed: %s — accuracy %d%%. You earned $%d.'):format(ticketLabel, pct, pay) }
        })
    else
        -- Standalone: no economy hooked up, just report the payout.
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^3[Utility Locate]', ('Ticket closed: %s — accuracy %d%%. Payout $%d (standalone mode — set Config.Framework to esx/qbcore to pay it out).'):format(ticketLabel, pct, pay) }
        })
    end
    print(('[utility-locate] %s closed "%s" at %d%% accuracy — $%d'):format(GetPlayerName(src) or tostring(src), ticketLabel, pct, pay))
end)
