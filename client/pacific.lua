-- Script name: pn-bankrobbery
-- Copyright (C) 2025 Project Nocturn
-- This file is distributed under the GNU General Public License v3.
-- See the LICENSE file at the root of the repository for the full text.
-- Modified by: Project Nocturn, 2025
local QBCore = exports['qb-core']:GetCoreObject()
local inBankCardBZone = false
local inElectronickitZone = false
local currentLocker = 0
local copsCalled = false

-- Fonction pour afficher du texte 3D dans le monde
function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 41, 41, 150)
end

-- Functions

--- This will load an animation dictionary so you can play an animation in that dictionary
--- @param dict string
--- @return nil
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Events

RegisterNetEvent('pn-bankrobbery:UseBankcardB', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    Config.OnEvidence(pos, 85)
    if not inBankCardBZone then return end
    QBCore.Functions.TriggerCallback('pn-bankrobbery:server:isRobberyActive', function(isBusy)
        if not isBusy then
            if CurrentCops >= Config.MinimumPacificPolice then
                if not Config.BigBanks["pacific"]["isOpened"] then
                    Config.ShowRequiredItems({
                        [1] = {name = QBCore.Shared.Items["security_card_02"]["name"], image = QBCore.Shared.Items["security_card_02"]["image"]}
                    }, false)
                    loadAnimDict("anim@gangops@facility@servers@")
                    TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                    QBCore.Functions.Progressbar("security_pass", Lang:t("general.validating_bankcard"), math.random(5000, 10000), false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- Done
                        StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
                        Config.DoorlockAction(1, false)
                        TriggerServerEvent('pn-bankrobbery:server:removeBankCard', '02')
                        if copsCalled or not Config.BigBanks["pacific"]["alarm"] then return end
                        TriggerServerEvent("pn-bankrobbery:server:callCops", "pacific", 0, pos)
                        copsCalled = true
                    end, function() -- Cancel
                        StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
                        QBCore.Functions.Notify(Lang:t("error.cancel_message"), "error")
                    end)
                else
                    QBCore.Functions.Notify(Lang:t("error.bank_already_open"), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t("error.minimum_police_required", {police = Config.MinimumPacificPolice}), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t("error.security_lock_active"), "error", 5500)
        end
    end)
end)

RegisterNetEvent('electronickit:UseElectronickit', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if not inElectronickitZone then return end
    QBCore.Functions.TriggerCallback('pn-bankrobbery:server:isRobberyActive', function(isBusy)
        if not isBusy then
            if CurrentCops >= Config.MinimumPacificPolice then
                if not Config.BigBanks["pacific"]["isOpened"] then
                    local hasItem = Config.HasItem({"trojan_usb", "electronickit"})
                    if hasItem then
                        Config.ShowRequiredItems(nil, false)
                        loadAnimDict("anim@gangops@facility@servers@")
                        TaskPlayAnim(ped, 'anim@gangops@facility@servers@', 'hotwire', 3.0, 3.0, -1, 1, 0, false, false, false)
                        QBCore.Functions.Progressbar("hack_gate", Lang:t("general.connecting_hacking_device"), math.random(5000, 10000), false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {}, {}, {}, function() -- Done
                            TriggerServerEvent('pn-bankrobbery:server:removeElectronicKit')
                            StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
                            local success = exports['qb-minigames']:Hacking(5, 30) -- code block size & seconds to solve
                            if success then
                                TriggerServerEvent('pn-bankrobbery:server:setBankState', 'pacific')
                            end
                            if copsCalled or not Config.BigBanks["pacific"]["alarm"] then return end
                            TriggerServerEvent("pn-bankrobbery:server:callCops", "pacific", 0, pos)
                            copsCalled = true
                        end, function() -- Cancel
                            StopAnimTask(ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
                            QBCore.Functions.Notify(Lang:t("error.cancel_message"), "error")
                        end)
                    else
                        QBCore.Functions.Notify(Lang:t("error.missing_item"), "error")
                    end
                else
                    QBCore.Functions.Notify(Lang:t("error.bank_already_open"), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t("error.minimum_police_required", {police = Config.MinimumPacificPolice}), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t("error.security_lock_active"), "error", 5500)
        end
    end)
end)

-- Threads

CreateThread(function()
    local bankCardBZone = BoxZone:Create(Config.BigBanks["pacific"]["coords"][1], 1.0, 1.0, {
        name = 'pacific_coords_bankcardb',
        heading = Config.BigBanks["pacific"]["heading"].closed,
        minZ = Config.BigBanks["pacific"]["coords"][1].z - 1,
        maxZ = Config.BigBanks["pacific"]["coords"][1].z + 1,
        debugPoly = false
    })
    bankCardBZone:onPlayerInOut(function(inside)
        inBankCardBZone = inside
        if inside and not Config.BigBanks["pacific"]["isOpened"] then
            -- Remplace ShowRequiredItems par un texte 3D
            CreateThread(function()
                while inBankCardBZone and not Config.BigBanks["pacific"]["isOpened"] do
                    local pos = GetEntityCoords(PlayerPedId())
                    local doorPos = Config.BigBanks["pacific"]["coords"]
                    local dist = #(pos - doorPos)
                    if dist < 10.0 then
                        DrawText3D(doorPos.x, doorPos.y, doorPos.z + 1.0, "~y~Carte de sécurité B~w~ requise")
                    end
                    Wait(0)
                end
            end)
        end
    end)
    local electronickitZone = BoxZone:Create(Config.BigBanks["pacific"]["coords"][2], 1.0, 1.0, {
        name = 'pacific_coords_electronickit',
        heading = Config.BigBanks["pacific"]["heading"].closed,
        minZ = Config.BigBanks["pacific"]["coords"][2].z - 1,
        maxZ = Config.BigBanks["pacific"]["coords"][2].z + 1,
        debugPoly = false
    })
    electronickitZone:onPlayerInOut(function(inside)
        inElectronickitZone = inside
        if inside and not Config.BigBanks["pacific"]["isOpened"] then
            -- Remplace ShowRequiredItems par un texte 3D
            CreateThread(function()
                while inElectronickitZone and not Config.BigBanks["pacific"]["isOpened"] do
                    local pos = GetEntityCoords(PlayerPedId())
                    local hackPos = Config.BigBanks["pacific"]["coords"]
                    local dist = #(pos - hackPos)
                    if dist < 10.0 then
                        DrawText3D(hackPos.x, hackPos.y, hackPos.z + 1.0, "~y~Kit électronique~w~ et ~y~Clé USB Trojan~w~ requis")
                    end
                    Wait(0)
                end
            end)
        end
    end)
    local thermite1Zone = BoxZone:Create(Config.BigBanks["pacific"]["thermite"][1]["coords"], 1.0, 1.0, {
        name = 'pacific_coords_thermite_1',
        heading = Config.BigBanks["pacific"]["heading"].closed,
        minZ = Config.BigBanks["pacific"]["thermite"][1]["coords"].z - 1,
        maxZ = Config.BigBanks["pacific"]["thermite"][1]["coords"].z + 1,
        debugPoly = false
    })
    thermite1Zone:onPlayerInOut(function(inside)
        if inside and not Config.BigBanks["pacific"]["thermite"][1]["isOpened"] then
            currentThermiteGate = Config.BigBanks["pacific"]["thermite"][1]["doorId"]
            -- Remplace ShowRequiredItems par un texte 3D
            CreateThread(function()
                while currentThermiteGate == Config.BigBanks["pacific"]["thermite"][1]["doorId"] do
                    local pos = GetEntityCoords(PlayerPedId())
                    local doorPos = Config.BigBanks["pacific"]["thermite"][1]["coords"]
                    local dist = #(pos - doorPos)
                    if dist < 10.0 then
                        DrawText3D(doorPos.x, doorPos.y, doorPos.z + 0.5, "~y~Thermite~w~ requise")
                    end
                    Wait(0)
                end
            end)
        else
            if currentThermiteGate == Config.BigBanks["pacific"]["thermite"][1]["doorId"] then
                currentThermiteGate = 0
            end
        end
    end)
    local thermite2Zone = BoxZone:Create(Config.BigBanks["pacific"]["thermite"][2]["coords"], 1.0, 1.0, {
        name = 'pacific_coords_thermite_2',
        heading = Config.BigBanks["pacific"]["heading"].closed,
        minZ = Config.BigBanks["pacific"]["thermite"][2]["coords"].z - 1,
        maxZ = Config.BigBanks["pacific"]["thermite"][2]["coords"].z + 1,
        debugPoly = false
    })
    thermite2Zone:onPlayerInOut(function(inside)
        if inside and not Config.BigBanks["pacific"]["thermite"][2]["isOpened"] then
            currentThermiteGate = Config.BigBanks["pacific"]["thermite"][2]["doorId"]
            -- Remplace ShowRequiredItems par un texte 3D
            CreateThread(function()
                while currentThermiteGate == Config.BigBanks["pacific"]["thermite"][2]["doorId"] do
                    local pos = GetEntityCoords(PlayerPedId())
                    local doorPos = Config.BigBanks["pacific"]["thermite"][2]["coords"]
                    local dist = #(pos - doorPos)
                    if dist < 10.0 then
                        DrawText3D(doorPos.x, doorPos.y, doorPos.z + 0.5, "~y~Thermite~w~ requise")
                    end
                    Wait(0)
                end
            end)
        else
            if currentThermiteGate == Config.BigBanks["pacific"]["thermite"][2]["doorId"] then
                currentThermiteGate = 0
            end
        end
    end)
    for k in pairs(Config.BigBanks["pacific"]["lockers"]) do
        if Config.UseTarget then
            exports['qb-target']:AddBoxZone('pacific_coords_locker_'..k, Config.BigBanks["pacific"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'pacific_coords_locker_'..k,
                heading = Config.BigBanks["pacific"]["heading"].closed,
                minZ = Config.BigBanks["pacific"]["lockers"][k]["coords"].z - 1,
                maxZ = Config.BigBanks["pacific"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            }, {
                options = {
                    {
                        action = function()
                            openLocker("pacific", k)
                        end,
                        canInteract = function()
                            return not IsDrilling and Config.BigBanks["pacific"]["isOpened"] and not Config.BigBanks["pacific"]["lockers"][k]["isBusy"] and not Config.BigBanks["pacific"]["lockers"][k]["isOpened"]
                        end,
                        icon = 'fa-solid fa-vault',
                        label = Lang:t("general.break_safe_open_option_target"),
                    },
                },
                distance = 1.5
            })
        else
            local lockerZone = BoxZone:Create(Config.BigBanks["pacific"]["lockers"][k]["coords"], 1.0, 1.0, {
                name = 'pacific_coords_locker_'..k,
                heading = Config.BigBanks["pacific"]["heading"].closed,
                minZ = Config.BigBanks["pacific"]["lockers"][k]["coords"].z - 1,
                maxZ = Config.BigBanks["pacific"]["lockers"][k]["coords"].z + 1,
                debugPoly = false
            })
            lockerZone:onPlayerInOut(function(inside)
                if inside and not IsDrilling and Config.BigBanks["pacific"]["isOpened"] and not Config.BigBanks["pacific"]["lockers"][k]["isBusy"] and not Config.BigBanks["pacific"]["lockers"][k]["isOpened"] then
                    exports['qb-core']:DrawText(Lang:t("general.break_safe_open_option_drawtext"), 'right')
                    currentLocker = k
                else
                    if currentLocker == k then
                        currentLocker = 0
                        exports['qb-core']:HideText()
                    end
                end
            end)
        end
    end
    if not Config.UseTarget then
        while true do
            local sleep = 1000
            if isLoggedIn then
                if currentLocker ~= 0 and not IsDrilling and Config.BigBanks["pacific"]["isOpened"] and not Config.BigBanks["pacific"]["lockers"][currentLocker]["isBusy"] and not Config.BigBanks["pacific"]["lockers"][currentLocker]["isOpened"] then
                    sleep = 0
                    if IsControlJustPressed(0, 38) then
                        exports['qb-core']:KeyPressed()
                        Wait(500)
                        exports['qb-core']:HideText()
                        if CurrentCops >= Config.MinimumPacificPolice then
                            openLocker("pacific", currentLocker)
                        else
                            QBCore.Functions.Notify(Lang:t("error.minimum_police_required", {police = Config.MinimumPacificPolice}), "error")
                        end
                        sleep = 1000
                    end
                end
            end
            Wait(sleep)
        end
    end
end)
