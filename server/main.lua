local function GetPlayerFrameworkObject()
    if Config.Framework == 'esx' then
        return exports["es_extended"]:getSharedObject()
    elseif Config.Framework == 'qbcore' then
        return exports['qb-core']:GetCoreObject()
    end
end

local Framework = GetPlayerFrameworkObject()

AddEventHandler('playerLoaded', function(playerId)
    local identifier
    if Config.Framework == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(playerId)
        identifier = xPlayer.identifier
    elseif Config.Framework == 'qbcore' then
        local xPlayer = Framework.Functions.GetPlayer(playerId)
        identifier = xPlayer.PlayerData.citizenid 
    end

    MySQL.Async.fetchAll('SELECT * FROM `paychecks` WHERE `identifier` = ?', { identifier }, function(result)
        if not result or #result == 0 then
            MySQL.Async.execute('INSERT INTO `paychecks` (`identifier`, `paycheck_amount`) VALUES (?, 0)', { identifier }, function(affectedRows)
                if affectedRows > 0 then
                    print(('New player paycheck entry created for %s with initial amount of $0'):format(identifier))
                end
            end)
        end
    end)
end)

RegisterNetEvent('jayzie-paycheck:requestPaycheckBalance')
AddEventHandler('jayzie-paycheck:requestPaycheckBalance', function()
    local src = source
    local identifier

    if Config.Framework == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(src)
        identifier = xPlayer.identifier
    elseif Config.Framework == 'qbcore' then
        local xPlayer = Framework.Functions.GetPlayer(src)
        identifier = xPlayer.PlayerData.citizenid 
    end

    MySQL.Async.fetchAll('SELECT paycheck_amount FROM `paychecks` WHERE `identifier` = ?', { identifier }, function(result)
        if result and result[1] then
            local balance = result[1].paycheck_amount
            TriggerClientEvent('jayzie-paycheck:showPaycheckMenu', src, balance)
        else
            TriggerClientEvent('esx:showNotification', src, 'No paycheck found for this character.')
        end
    end)
end)

RegisterNetEvent('jayzie-paycheck:withdraw')
AddEventHandler('jayzie-paycheck:withdraw', function(amount, method, withdrawType)
    local src = source
    local identifier
    local xPlayer

    if Config.Framework == 'esx' then
        xPlayer = Framework.GetPlayerFromId(src)
        identifier = xPlayer.identifier
    elseif Config.Framework == 'qbcore' then
        xPlayer = Framework.Functions.GetPlayer(src)
        identifier = xPlayer.PlayerData.citizenid 
    end

    MySQL.Async.fetchAll('SELECT paycheck_amount FROM `paychecks` WHERE `identifier` = ?', { identifier }, function(result)
        if result and result[1] then
            local currentBalance = result[1].paycheck_amount

            if withdrawType == 'all' and currentBalance > 0 then
                amount = currentBalance
            elseif withdrawType == 'custom' and amount > currentBalance then
                TriggerClientEvent('esx:showNotification', src, 'Insufficient paycheck balance.')
                return
            end

            local newBalance = currentBalance - amount

            MySQL.Async.execute('UPDATE `paychecks` SET `paycheck_amount` = ? WHERE `identifier` = ?', { newBalance, identifier }, function(affectedRows)
                if affectedRows > 0 then
                    local account
                    if Config.Framework == 'esx' then
                        account = method == 'cash' and 'money' or 'bank'
                        xPlayer.addAccountMoney(account, amount)
                    elseif Config.Framework == 'qbcore' then
                        account = method == 'cash' and 'cash' or 'bank'
                        xPlayer.Functions.AddMoney(account, amount)
                    end
                    TriggerClientEvent('jayzie-paycheck:payReceived', src, amount, method)
                end
            end)
        else
            TriggerClientEvent('esx:showNotification', src, 'No paycheck found for this character.')
        end
    end)
end)

exports('addToPaycheck', function(source, amount)
    local identifier
    local xPlayer

    if Config.Framework == 'esx' then
        xPlayer = Framework.GetPlayerFromId(source)
        identifier = xPlayer.identifier
    elseif Config.Framework == 'qbcore' then
        xPlayer = Framework.Functions.GetPlayer(source)
        identifier = xPlayer.PlayerData.citizenid
    end

    if not xPlayer then
        print(('Invalid player source: %s'):format(source))
        return
    end

    MySQL.Async.fetchAll('SELECT paycheck_amount FROM `paychecks` WHERE `identifier` = ?', { identifier }, function(result)
        if result and result[1] then
            local newAmount = result[1].paycheck_amount + amount
            MySQL.Async.execute('UPDATE `paychecks` SET `paycheck_amount` = ? WHERE `identifier` = ?', { newAmount, identifier }, function(affectedRows)
                if affectedRows > 0 then
                    print(('Paycheck updated: Added $%s to %s\'s paycheck'):format(amount, identifier))
                end
            end)
        else
            MySQL.Async.execute('INSERT INTO `paychecks` (`identifier`, `paycheck_amount`) VALUES (?, ?)', { identifier, amount }, function(id)
                print(('New paycheck record created for %s with amount $%s'):format(identifier, amount))
            end)
        end
    end)
end)
