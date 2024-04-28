local QBCore = exports['qb-core']:GetCoreObject()
lib.locale()
SpawnedPed = {}

-- ===== Blip
local blip = AddBlipForCoord(Config.blip.coords.x, Config.blip.coords.y, Config.blip.coords.z)
SetBlipSprite(blip, Config.blip.blip)
SetBlipAsShortRange(blip, true)
SetBlipScale(blip, Config.blip.size)
SetBlipColour(blip, Config.blip.color)
BeginTextCommandSetBlipName("STRING")
AddTextComponentString(Config.blip.label)
EndTextCommandSetBlipName(blip)


-- ===== Peds
for key, pedData in pairs(Config.recruitmentPoints) do
    RequestModel(pedData.pedHash)
    while (not HasModelLoaded(pedData.pedHash)) do Wait(1) end
    SpawnedPed[key] = CreatePed(1, pedData.pedHash, pedData.position.x, pedData.position.y, (pedData.position.z - 1.0), pedData.heading, false, true)
    SetEntityInvincible(SpawnedPed[key], true)
    SetBlockingOfNonTemporaryEvents(SpawnedPed[key], true)
    FreezeEntityPosition(SpawnedPed[key], true)

    exports['qb-target']:AddTargetEntity(SpawnedPed[key], {
        distance = 5.0,
        options = {
            { type = "client", event = "neko_jobcenter:client:open_recruitment_menu", icon = 'fas fa-briefcase', label = locale('open_recruitment_menu') }
        },
    })
end

for key, pedData in pairs(Config.postulationPoints) do
    RequestModel(pedData.pedHash)
    while (not HasModelLoaded(pedData.pedHash)) do Wait(1) end
    SpawnedPed[key] = CreatePed(1, pedData.pedHash, pedData.position.x, pedData.position.y, (pedData.position.z - 1.0), pedData.heading, false, true)
    SetEntityInvincible(SpawnedPed[key], true)
    SetBlockingOfNonTemporaryEvents(SpawnedPed[key], true)
    FreezeEntityPosition(SpawnedPed[key], true)

    exports['qb-target']:AddTargetEntity(SpawnedPed[key], {
        distance = 5.0,
        options = {
            { type = "client", event = "neko_jobcenter:client:open_postulation_form", icon = 'fas fa-briefcase', label = locale('open_postulation_menu') }
        },
    })
end

-- ===== Eventos
RegisterNetEvent('neko_jobcenter:client:open_recruitment_menu', function(data)
    local availableJobs = {}

    for _, jobData in pairs(Config.jobs) do
        availableJobs[jobData.id] = {
            title       = locale('recruitment_menu_option_title', jobData.label, jobData.salary),
            description = jobData.description,
            icon        = 'briefcase',
            arrow       = true,
            metadata    = { locale('recruitment_menu_option_hover') },
            serverEvent = 'neko_jobcenter:server:set_job',
            args        = { job = jobData.id }
        }
    end

    lib.registerContext({
        id    = 'neko_jobcenter__recruitment_menu',
        title = locale('recruitment_menu_label'),
        options = availableJobs
    })

    lib.showContext('neko_jobcenter__recruitment_menu')
end)

RegisterNetEvent('neko_jobcenter:client:open_postulation_form', function(data)
    local availableBusiness = lib.callback.await('neko_jobcenter:server:get_available_jobs', false)

    local player = QBCore.Functions.GetPlayerData()
    local playerName      = player.charinfo.firstname..' '..player.charinfo.lastname
    local playerCID       = player.citizenid
    local playerPhone     = player.charinfo.phone
    local playerBirthDate = FormatFechaNacimiento(player.charinfo.birthdate)

    local input = lib.inputDialog(locale('postulation__form'), {
        {
            type        = 'input',
            icon        = { 'fas', 'user' },
            required    = true,
            disabled    = true,
            label       = locale('postulation__name'),
            default     = playerName
        },
        {
            type        = 'input',
            icon        = { 'fas', 'id-card' },
            required    = true,
            disabled    = true,
            label       = locale('postulation__clientcid'),
            default     = playerCID
        },
        {
            type        = 'input',
            icon        = { 'fas', 'mobile-alt' },
            required    = true,
            disabled    = true,
            label       = locale('postulation__phone'),
            default     = playerPhone
        },
        {
            type        = 'input',
            icon        = { 'fas', 'calendar' },
            required    = true,
            disabled    = true,
            label       = locale('postulation__birthdate'),
            default     = playerBirthDate
        },
        {
            type        = 'select',
            icon        = { 'fas', 'briefcase' },
            required    = true,
            label       = locale('postulation__business'),
            options     = availableBusiness
        },
        {
            type        = 'input',
            icon        = { 'fas', 'certificate' },
            required    = true,
            label       = locale('postulation__position'),
        },
        {
            type        = 'textarea',
            icon        = { 'fas', 'sticky-note' },
            required    = true,
            label       = locale('postulation__experience'),
            min         = 3,
            max         = 3,
            autosize    = false
        },
        {
            type        = 'textarea',
            icon        = { 'fas', 'question' },
            required    = true,
            label       = locale('postulation__why_you'),
            min         = 3,
            max         = 3,
            autosize    = false
        },
    })

    if not input then return end

    lib.callback.await('neko_jobcenter:server:send_postulacion', false, { job = input[5], position = input[6], exp = input[7], reason = input[8] })
end)

-- ===== Callbacks
lib.callback.register('neko_jobcenter:client:get_open_jobs', function()
    local availableJobs = {}

    for _, jobData in pairs(Config.jobs) do
        availableJobs[jobData.id] = jobData.label
    end
    return availableJobs
end)

-- ===== Funciones
function FormatFechaNacimiento(date)
    local anho, mes, dia = string.sub(date, 1, 4), string.sub(date, 6, 7), string.sub(date, 9, 10)
    if string.len(dia) == 1 then dia = "0" .. dia end
    if string.len(mes) == 1 then mes = "0" .. mes end
    return dia..'/'..mes..'/'..anho
end