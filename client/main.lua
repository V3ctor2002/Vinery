local PlayerData, GUI, CurrentActionData, JobBlips = {}, {}, {}, {}
local HasAlreadyEnteredMarker, publicBlip = false, false
local LastZone, CurrentAction, CurrentActionMsg
ESX = nil
GUI.Time = 0

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function TeleportFadeEffect(entity, coords)

	Citizen.CreateThread(function()

		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(0)
		end

		ESX.Game.Teleport(entity, coords, function()
			DoScreenFadeIn(800)
		end)
	end)
end

--[[function OpenCloakroomMenu()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
			title    = _U('cloakroom'),
			align    = 'top-left',
			elements = {
				{label = _U('vine_clothes_civil'), value = 'citizen_wear'},
				{label = _U('vine_clothes_vine'), value = 'vigne_wear'},
			},
		}, function(data, menu)

			menu.close()

			if data.current.value == 'citizen_wear' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)
			end

			if data.current.value == 'vigne_wear' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					else
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
					end
				end)
			end

			CurrentAction     = 'vigne_actions_menu'
			CurrentActionMsg  = _U('open_menu')
			CurrentActionData = {}
		end, function(data, menu)
			menu.close()
		end)
end]]--

function OpenVigneActionsMenu()

	local elements = {
        {label = _U('cloakroom'), value = 'cloakroom'},
		{label = _U('deposit_stock'), value = 'put_stock'}
	}

	if Config.EnablePlayerManagement and PlayerData.job ~= nil and (PlayerData.job.grade_name ~= 'recrue' and PlayerData.job.grade_name ~= 'novice')then -- Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss'
		table.insert(elements, {label = _U('take_stock'), value = 'get_stock'})
	end
  
	if Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' then -- Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss'
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vigne_actions', {
			title    = _U('society_name'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)

			if data.current.value == 'cloakroom' then
				OpenCloakroomMenu()
			end

			if data.current.value == 'put_stock' then
				OpenPutStocksMenu()
			end

			if data.current.value == 'get_stock' then
				OpenGetStocksMenu()
			end

			if data.current.value == 'boss_actions' then
				TriggerEvent('esx_society:openBossMenu', 'vigne', function(data, menu)
					menu.close()
				end)
			end
		end, function(data, menu)

			menu.close()

			CurrentAction     = 'vigne_actions_menu'
			CurrentActionMsg  = _U('press_to_open')
			CurrentActionData = {}
		end)
end

function OpenVehicleSpawnerMenu()

	ESX.UI.Menu.CloseAll()

	if Config.EnableSocietyOwnedVehicles then

		local elements = {}

		ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)

			for i=1, #vehicles, 1 do
				table.insert(elements, {label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']', value = vehicles[i]})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
					title    = _U('veh_menu'),
					align    = 'top-left',
					elements = elements,
				}, function(data, menu)

					menu.close()

					local vehicleProps = data.current.value

					ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, 90.0, function(vehicle)
						ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
						local playerPed = GetPlayerPed(-1)
						TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
					end)

					TriggerServerEvent('esx_society:removeVehicleFromGarage', 'vigne', vehicleProps)
				end, function(data, menu)

					menu.close()

					CurrentAction     = 'vehicle_spawner_menu'
					CurrentActionMsg  = _U('spawn_veh')
					CurrentActionData = {}
				end)
		end, 'vigne')
	else
		local elements = {
			{label = _U('vehicle_name1'),  value = 'burrito3'},
			{label = _U('vehicle_name2'),  value = 'tractor'},
			{label = _U('vehicle_name3'),  value = 'tractor2'},
		}
		
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
				title    = _U('veh_menu'),
				align    = 'top-left',
				elements = elements,
			}, function(data, menu)

				menu.close()

				local model = data.current.value
		
				ESX.Game.SpawnVehicle(model, Config.Zones.VehicleSpawnPoint.Pos, 56.326, function(vehicle)
					local playerPed = GetPlayerPed(-1)
					TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
				end)
			end, function(data, menu)

				menu.close()

				CurrentAction     = 'vehicle_spawner_menu'
				CurrentActionMsg  = _U('spawn_veh')
				CurrentActionData = {}
			end)
	end
end

function OpenMobileVigneActionsMenu()

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_vigne_actions', {
			title    = 'vigne',
			align    = 'top-left',
			elements = {
				{label = _U('billing'), value = 'billing'}
			}
		}, function(data, menu)

			if data.current.value == 'billing' then

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
						title = _U('invoice_amount')
					}, function(data, menu)

						local amount = tonumber(data.value)

						if amount == nil or amount <= 0 then
							ESX.ShowNotification(_U('amount_invalid'))
						else
							menu.close()

							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

							if closestPlayer == -1 or closestDistance > 3.0 then
								ESX.ShowNotification(_U('no_players_near'))
							else
								local playerPed        = GetPlayerPed(-1)

								Citizen.CreateThread(function()
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
									Citizen.Wait(5000)
									ClearPedTasks(playerPed)
									TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_vigne', _U('society_name'), amount)
								end)
							end
						end
					end, function(data, menu)
						menu.close()
					end)
			end
		end, function(data, menu)
			menu.close()
		end)
end

function OpenGetStocksMenu()

	ESX.TriggerServerCallback('esx_vigneronjob:getStockItems', function(items)

		print(json.encode(items))

		local elements = {}

		for i=1, #items, 1 do
			if (items[i].count ~= 0) then
				table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
				title    = _U('vigneron_stock'),
				align    = 'top-left',
				elements = elements
			}, function(data, menu)

				local itemName = data.current.value

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
						title = _U('quantity')
					}, function(data2, menu2)
		
						local count = tonumber(data2.value)

						if count == nil or count <= 0 then
							ESX.ShowNotification(_U('quantity_invalid'))
						else
							menu2.close()
							menu.close()
							OpenGetStocksMenu()

							TriggerServerEvent('esx_vigneronjob:getStockItem', itemName, count)
						end
					end, function(data2, menu2)
						menu2.close()
					end)
			end, function(data, menu)
				menu.close()
			end)
	end)
end

function OpenPutStocksMenu()

	ESX.TriggerServerCallback('esx_vigneronjob:getPlayerInventory', function(inventory)

		local elements = {}

		for i=1, #inventory.items, 1 do

			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
				title    = _U('inventory'),
				elements = elements
			}, function(data, menu)

				local itemName = data.current.value

				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
						title = _U('quantity')
					}, function(data2, menu2)

						local count = tonumber(data2.value)

						if count == nil or count <= 0 then
							ESX.ShowNotification(_U('quantity_invalid'))
						else
							menu2.close()
							menu.close()
							OpenPutStocksMenu()

							TriggerServerEvent('esx_vigneronjob:putStockItems', itemName, count)
						end
					end, function(data2, menu2)
						menu2.close()
					end)
			end, function(data, menu)
				menu.close()
			end)
	end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	blips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	deleteBlips()
	blips()
end)

AddEventHandler('esx_vigneronjob:hasEnteredMarker', function(zone)
	if zone == 'RaisinFarm' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne'  then
		CurrentAction     = 'raisin_harvest'
		CurrentActionMsg  = _U('press_collect')
		CurrentActionData = {zone= zone}
	end
		
	if zone == 'TraitementVin' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne'  then
		CurrentAction     = 'vine_traitement'
		CurrentActionMsg  = _U('press_collect')
		CurrentActionData = {zone= zone}
	end		
		
	if zone == 'TraitementJus' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne'  then
		CurrentAction     = 'jus_traitement'
		CurrentActionMsg  = _U('press_traitement')
		CurrentActionData = {zone = zone}
	end
		
	if zone == 'SellFarm' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne'  then
		CurrentAction     = 'farm_resell'
		CurrentActionMsg  = _U('press_sell')
		CurrentActionData = {zone = zone}
	end

	if zone == 'VigneronActions' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
		CurrentAction     = 'vigne_actions_menu'
		CurrentActionMsg  = _U('press_to_open')
		CurrentActionData = {}
	end
  
	if zone == 'VehicleSpawner' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
		CurrentAction     = 'vehicle_spawner_menu'
		CurrentActionMsg  = _U('spawn_veh')
		CurrentActionData = {}
	end
		
	if zone == 'VehicleDeleter' and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then

		local playerPed = GetPlayerPed(-1)
		local coords    = GetEntityCoords(playerPed)
		
		if IsPedInAnyVehicle(playerPed,  false) then

			local vehicle, distance = ESX.Game.GetClosestVehicle({
				x = coords.x,
				y = coords.y,
				z = coords.z
			})

			if distance ~= -1 and distance <= 1.0 then

				CurrentAction     = 'delete_vehicle'
				CurrentActionMsg  = _U('store_veh')
				CurrentActionData = {vehicle = vehicle}
			end
		end
	end
end)

AddEventHandler('esx_vigneronjob:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	if (zone == 'RaisinFarm') and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
		TriggerServerEvent('esx_vigneronjob:stopHarvest')
	end  
	if (zone == 'TraitementVin' or zone == 'TraitementJus') and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
		TriggerServerEvent('esx_vigneronjob:stopTransform')
	end
	if (zone == 'SellFarm') and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
		TriggerServerEvent('esx_vigneronjob:stopSell')
	end
	CurrentAction = nil
end)

function deleteBlips()
	if JobBlips[1] ~= nil then
		for i=1, #JobBlips, 1 do
		RemoveBlip(JobBlips[i])
		JobBlips[i] = nil
		end
	end
end

-- Create Blips
function blips()
	if publicBlip == false then
		local blip = AddBlipForCoord(Config.Zones.VigneronActions.Pos.x, Config.Zones.VigneronActions.Pos.y, Config.Zones.VigneronActions.Pos.z)
		SetBlipSprite (blip, 85)
		SetBlipDisplay(blip, 4)
		SetBlipScale  (blip, 1.0)
		SetBlipColour (blip, 19)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString("Vignerons")
		EndTextCommandSetBlipName(blip)
		publicBlip = true
	end
	
    if PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then

		for k,v in pairs(Config.Zones)do
			if v.Type == 1 then
				local blip2 = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)

				SetBlipSprite (blip2, 85)
				SetBlipDisplay(blip2, 4)
				SetBlipScale  (blip2, 1.0)
				SetBlipColour (blip2, 19)
				SetBlipAsShortRange(blip2, true)

				BeginTextCommandSetBlipName('STRING')
				AddTextComponentString(v.Name)
				EndTextCommandSetBlipName(blip2)
				table.insert(JobBlips, blip2)
			end
		end
	end
end

-- Display markers
Citizen.CreateThread(function()
	while true do
		Wait(0)
		local coords = GetEntityCoords(GetPlayerPed(-1))

		for k,v in pairs(Config.Zones) do
			if PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then
				if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
					DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
				end
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do

		Wait(0)

		if PlayerData.job ~= nil and PlayerData.job.name == 'vigne' then

			local coords      = GetEntityCoords(GetPlayerPed(-1))
			local isInMarker  = false
			local currentZone = nil

			for k,v in pairs(Config.Zones) do
				if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
					isInMarker  = true
					currentZone = k
				end
			end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker = true
				LastZone                = currentZone
				TriggerEvent('esx_vigneronjob:hasEnteredMarker', currentZone)
			end

			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_vigneronjob:hasExitedMarker', LastZone)
			end
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do

		Citizen.Wait(0)

		if CurrentAction ~= nil then

			SetTextComponentFormat('STRING')
			AddTextComponentString(CurrentActionMsg)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)

			if IsControlPressed(0,  38) and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' and (GetGameTimer() - GUI.Time) > 300 then
				if CurrentAction == 'raisin_harvest' then
					TriggerServerEvent('esx_vigneronjob:startHarvest', CurrentActionData.zone)
				end
				if CurrentAction == 'jus_traitement' then
					TriggerServerEvent('esx_vigneronjob:startTransform', CurrentActionData.zone)
				end
				if CurrentAction == 'vine_traitement' then
					TriggerServerEvent('esx_vigneronjob:startTransform', CurrentActionData.zone)
				end
				if CurrentAction == 'farm_resell' then
					TriggerServerEvent('esx_vigneronjob:startSell', CurrentActionData.zone)
				end
				
				if CurrentAction == 'vigne_actions_menu' then
					OpenVigneActionsMenu()
				end
				if CurrentAction == 'vehicle_spawner_menu' then
					OpenVehicleSpawnerMenu()
				end
				if CurrentAction == 'delete_vehicle' then

					if Config.EnableSocietyOwnedVehicles then
						local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
						TriggerServerEvent('esx_society:putVehicleInGarage', 'vigne', vehicleProps)
					end

					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				end

				CurrentAction = nil
				GUI.Time      = GetGameTimer()
			end
		end

		if IsControlPressed(0,  167) and Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.name == 'vigne' and (GetGameTimer() - GUI.Time) > 150 then
			OpenMobileVigneActionsMenu()
			GUI.Time = GetGameTimer()
		end
	end
end)