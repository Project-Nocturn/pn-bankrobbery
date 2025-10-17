-- Script name: pn-bankrobbery
-- Copyright (C) 2025 Project Nocturn
-- This file is distributed under the GNU General Public License v3.
-- See the LICENSE file at the root of the repository for the full text.
-- Modified by: Project Nocturn, 2025
local QBCore = exports['qb-core']:GetCoreObject()
local CurrentCops = 0

local closestStation = 0
local currentStation = 0
local currentFires = {}
local currentGate = 0
local currentThermiteGate = 0
local requiredItems = {[1] = {name = QBCore.Shared.Items["thermite"]["name"], image = QBCore.Shared.Items["thermite"]["image"]}}

-- Functions

--- This will create a fire at the given coords and for the given time
--- @param coords vector3
--- @param time number
--- @return nil
local function CreateFire(coords, time)
    for _ = 1, math.random(1, 7), 1 do
        TriggerServerEvent("thermite:StartServerFire", coords, 24, false)
    end
    Wait(time)
    TriggerServerEvent("thermite:StopFires")
end

--- This will load an animation dictionary so you can play an animation in that dictionary
--- @param dict string
--- @return nil
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

-- Fonction pour gérer le succès du minijeu
local function HandleThermiteSuccess()
    ClearPedTasks(PlayerPedId())
    local time = 3
    local coords = GetEntityCoords(PlayerPedId())
    while time > 0 do
        QBCore.Functions.Notify(Lang:t("general.thermite_detonating_in_seconds", {time = time}))
        Wait(1000)
        time = time - 1
    end
    local randTime = math.random(10000, 15000)
    CreateFire(coords, randTime)
    if currentStation ~= 0 then
        QBCore.Functions.Notify(Lang:t("success.fuses_are_blown"), "success")
        TriggerServerEvent("pn-bankrobbery:server:SetStationStatus", currentStation, true)
    elseif currentGate ~= 0 then
        QBCore.Functions.Notify(Lang:t("success.door_has_opened"), "success")
        Config.DoorlockAction(currentGate, false)
        currentGate = 0
    end
end

-- Fonction pour gérer l'échec du minijeu
local function HandleThermiteFailed()
    PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
    ClearPedTasks(PlayerPedId())
    local coords = GetEntityCoords(PlayerPedId())
    local randTime = math.random(10000, 15000)
    CreateFire(coords, randTime)
end

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

-- Events

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

RegisterNetEvent('thermite:StartFire', function(coords, maxChildren, isGasFire)
    if #(vector3(coords.x, coords.y, coords.z) - GetEntityCoords(PlayerPedId())) < 100 then
        local pos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        }
        pos.z = pos.z - 0.9
        local fire = StartScriptFire(pos.x, pos.y, pos.z, maxChildren, isGasFire)
        currentFires[#currentFires+1] = fire
    end
end)

RegisterNetEvent('thermite:StopFires', function()
    for i = 1, #currentFires do
        RemoveScriptFire(currentFires[i])
    end
    currentFires = {}
end)

RegisterNetEvent('thermite:UseThermite', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if closestStation ~= 0 then
        Config.OnEvidence(pos, 85)
        local dist = #(pos - Config.PowerStations[closestStation].coords)
        if dist < 1.5 then
            if CurrentCops >= Config.MinimumThermitePolice then
                if not Config.PowerStations[closestStation].hit then
                    loadAnimDict("weapon@w_sp_jerrycan")
                    TaskPlayAnim(PlayerPedId(), "weapon@w_sp_jerrycan", "fire", 3.0, 3.9, 180, 49, 0, 0, 0, 0)
                    Config.ShowRequiredItems(requiredItems, false)
                    local success = exports['bl_ui']:RapidLines(1, 2, 4)
                    if success then
                        HandleThermiteSuccess()
                    else
                        HandleThermiteFailed()
                    end
                    currentStation = closestStation
                else
                    QBCore.Functions.Notify(Lang:t("error.fuses_already_blown"), "error")
                end
            else
                QBCore.Functions.Notify(Lang:t("error.minium_police_required", {police = Config.MinimumThermitePolice}), "error")
            end
        end
    elseif currentThermiteGate ~= 0 then
        Config.OnEvidence(pos, 85)
        if CurrentCops >= Config.MinimumThermitePolice then
            currentGate = currentThermiteGate
            loadAnimDict("weapon@w_sp_jerrycan")
            TaskPlayAnim(PlayerPedId(), "weapon@w_sp_jerrycan", "fire", 3.0, 3.9, -1, 49, 0, 0, 0, 0)
            Config.ShowRequiredItems(requiredItems, false)
            local success = exports['bl_ui']:RapidLines(1, 2, 4)
            if success then
                HandleThermiteSuccess()
            else
                HandleThermiteFailed()
            end
        else
            QBCore.Functions.Notify(Lang:t("error.minium_police_required", {police = Config.MinimumThermitePolice}), "error")
        end
    end
end)

RegisterNetEvent('pn-bankrobbery:client:SetStationStatus', function(key, isHit)
    Config.PowerStations[key].hit = isHit
end)

-- Threads

CreateThread(function()
    for k = 1, #Config.PowerStations do
        local stationZone = BoxZone:Create(Config.PowerStations[k].coords, 1.0, 1.0, {
            name = 'powerstation_coords_'..k,
            heading = 90.0,
            minZ = Config.PowerStations[k].coords.z - 1,
            maxZ = Config.PowerStations[k].coords.z + 1,
            debugPoly = false
        })
        stationZone:onPlayerInOut(function(inside)
            if inside and not Config.PowerStations[k].hit then
                closestStation = k
                -- Remplace ShowRequiredItems par un texte 3D
                CreateThread(function()
                    while closestStation == k do
                        local pos = GetEntityCoords(PlayerPedId())
                        local stationPos = Config.PowerStations[k].coords
                        local dist = #(pos - stationPos)
                        if dist < 10.0 then
                            DrawText3D(stationPos.x, stationPos.y, stationPos.z + 1.0, "~y~Thermite~w~ requis", 0.35)
                        end
                        Wait(0)
                    end
                end)
            else
                if closestStation == k then
                    closestStation = 0
                end
            end
        end)
    end
end)
