local QBCore = exports['qb-core']:GetCoreObject()
lib.locale()

lib.callback.register('neko_jobcenter:server:get_available_jobs', function(source, data)
    local jobs = {}

    for key, data in pairs(Config.availablesJobs) do
        table.insert(jobs, { value = key, label = data.label })
    end

    return jobs
end)

lib.callback.register('neko_jobcenter:server:send_postulacion', function(source, data)
    local player          = QBCore.Functions.GetPlayer(source)
    local playerFName     = player.PlayerData.charinfo.firstname
    local playerLName     = player.PlayerData.charinfo.lastname
    local playerCID       = player.PlayerData.citizenid
    local playerPhone     = player.PlayerData.charinfo.phone
    local playerBirthDate = FormatFechaNacimiento(player.PlayerData.charinfo.birthdate)

    if Config.availablesJobs[data.job] == nil then
        return TriggerClientEvent('ox_lib:notify', source, { description = locale('error_business_not_exist'), type = 'error' })
    end

    if Config.availablesJobs[data.job].webhook == nil then
        return TriggerClientEvent('ox_lib:notify', source, { description = locale('error_business_inbox_unknown'), type = 'error' })
    end

    local embedData = {
        title = locale('webhook_new_postulation'),
        color = 16711900,
        footer = { text = locale('webhook_from_lsjc') },
        fields = {
            { inline = true, name = locale('webhook_field_firstname'), value = "```"..playerFName.."```" },
            { inline = true, name = locale('webhook_field_lastname'), value = "```"..playerLName.."```" },
            { inline = true, name = locale('webhook_field_cid'), value = "```"..playerCID.."```" },
            { inline = true, name = locale('webhook_field_birth'), value = "```"..playerBirthDate.."```" },
            { inline = true, name = locale('webhook_field_phone'), value = "```"..playerPhone.."```" },
            { inline = false, name = locale('webhook_field_experience'), value = "```"..data.exp.."```" },
            { inline = false, name = locale('webhook_field_reason'), value = "```"..data.reason.."```" },
            { inline = false, name = locale('webhook_field_position'), value = "```"..data.position.."```" },
        }
    }

    PerformHttpRequest(
        Config.availablesJobs[data.job].webhook,
        function(err, text, headers) end,
        'POST',
        json.encode({ embeds = { embedData } }),
        { ['Content-Type'] = 'application/json' }
    )

    return TriggerClientEvent('ox_lib:notify', source, { description = locale('success_postulation_send'), type = 'success' })
end)

RegisterNetEvent("neko_jobcenter:server:set_job")
AddEventHandler("neko_jobcenter:server:set_job", function(data)
    local src = source
    local availablesJobs = lib.callback.await('neko_jobcenter:client:get_open_jobs', src)

    if availablesJobs[data.job] == nil then
        return TriggerClientEvent('ox_lib:notify', src, { description = locale('error_job_not_available') , type = 'error' })
    else
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.SetJob(data.job, 0)
        return TriggerClientEvent('ox_lib:notify', src, { description = locale('success_new_job', availablesJobs[data.job]) , type = 'success' })
    end
end)

-- ===== Funciones
function FormatFechaNacimiento(date)
    local anho, mes, dia = string.sub(date, 1, 4), string.sub(date, 6, 7), string.sub(date, 9, 10)
    if string.len(dia) == 1 then dia = "0"..dia end
    if string.len(mes) == 1 then mes = "0"..mes end
    return dia..'/'..mes..'/'..anho
end