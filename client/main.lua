function CreateBlip(coords, blipConfig)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipColour(blip, blipConfig.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.name)
    EndTextCommandSetBlipName(blip)
end

function CreateNPCAndTarget(npc)
    RequestModel(GetHashKey(npc.model))
    while not HasModelLoaded(GetHashKey(npc.model)) do
        Wait(1)
    end

    local ped = CreatePed(4, GetHashKey(npc.model), npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.heading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if npc.showBlip then
        CreateBlip(npc.coords, npc.blip)
    end

    if npc.animation then
        RequestAnimDict(npc.animation.dict)
        while not HasAnimDictLoaded(npc.animation.dict) do
            Wait(1)
        end
        TaskPlayAnim(ped, npc.animation.dict, npc.animation.clip, 8.0, -8.0, -1, npc.animation.flag or 1, 0, false, false, false)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'npc_paycheck_' .. npc.model,
            label = Config.TargetOptions[1].label,
            icon = Config.TargetOptions[1].icon,
            event = Config.TargetOptions[1].event,
            distance = Config.TargetOptions[1].distance
        }
    })
end

Citizen.CreateThread(function()
    for _, npc in pairs(Config.NPC) do
        CreateNPCAndTarget(npc)
    end
end)

RegisterNetEvent('jayzie-paycheck:openMenu')
AddEventHandler('jayzie-paycheck:openMenu', function()
    TriggerServerEvent('jayzie-paycheck:requestPaycheckBalance')
end)

RegisterNetEvent('jayzie-paycheck:showPaycheckMenu')
AddEventHandler('jayzie-paycheck:showPaycheckMenu', function(balance)
    lib.registerContext({
        id = 'paycheck_menu',
        title = 'Paycheck Menu',
        options = {
            {
                title = 'Balance: $' .. balance,
                description = 'Your total paycheck balance',
                icon = 'fas fa-money-bill-wave',
            },
            {
                title = 'Withdraw All',
                icon = 'fas fa-wallet',
                onSelect = function()
                    ShowWithdrawMethodMenu(balance, 'all')
                end
            },
            {
                title = 'Withdraw Custom Amount',
                icon = 'fas fa-wallet',
                onSelect = function()
                    local input = lib.inputDialog("Withdraw Custom Amount", {
                        { type = "number", label = "Amount to Withdraw", required = true, min = 1, max = balance }
                    })

                    if input then
                        local withdrawAmount = tonumber(input[1])
                        if withdrawAmount and withdrawAmount <= balance then
                            ShowWithdrawMethodMenu(withdrawAmount, 'custom')
                        else
                            lib.notify({ type = 'error', description = 'Invalid amount!' })
                        end
                    end
                end
            }
        }
    })

    lib.showContext('paycheck_menu')
end)

function ShowWithdrawMethodMenu(amount, withdrawType)
    if amount <= 0 then
        lib.notify({
            title = 'Paycheck',
            description = 'You have no paycheck to withdraw!',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'withdraw_method_menu',
        title = 'Select Withdrawal Method',
        options = {
            {
                title = 'Withdraw to Cash',
                icon = 'fas fa-money-bill-wave',
                onSelect = function()
                    PerformWithdrawAnimation(amount, 'cash', withdrawType)
                end
            },
            {
                title = 'Withdraw to Bank',
                icon = 'fas fa-university',
                onSelect = function()
                    PerformWithdrawAnimation(amount, 'bank', withdrawType)
                end
            }
        }
    })

    lib.showContext('withdraw_method_menu')
end

function PerformWithdrawAnimation(amount, method, withdrawType)
    local playerPed = PlayerPedId()
    
    FreezeEntityPosition(playerPed, true)

    if lib.progressBar({
        duration = 5000,
        label = 'Withdrawing $' .. amount .. ' to ' .. method,
        useWhileDead = false,
        canCancel = false,
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    }) then
        FreezeEntityPosition(playerPed, false)

        TriggerServerEvent('jayzie-paycheck:withdraw', amount, method, withdrawType)
    else
        FreezeEntityPosition(playerPed, false)
        lib.notify({type = 'error', description = 'Withdrawal canceled!'})
    end
end

RegisterNetEvent('jayzie-paycheck:payReceived')
AddEventHandler('jayzie-paycheck:payReceived', function(amount, method)
    lib.notify({
        title = "Paycheck",
        description = ('You withdrew $%s to your %s'):format(amount, method),
        type = 'success'
    })
end)
