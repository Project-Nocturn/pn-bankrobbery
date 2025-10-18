-- Script name: pn-bankrobbery
-- Copyright (C) 2025 Project Nocturn
-- This file is distributed under the GNU General Public License v3.
-- See the LICENSE file at the root of the repository for the full text.
-- Modified by: Project Nocturn, 2025

fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'

shared_scripts {
    'sh_config.lua', -- Shared config
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    'cl_config.lua', -- Client config
    'client/fleeca.lua',
    'client/pacific.lua',
    'client/powerstation.lua',
    'client/doors.lua',
    'client/paleto.lua'
}

server_scripts {
    'sv_config.lua', -- Server config
    'server/main.lua'
}


dependencies {
    'PolyZone',
    'glitch-minigames',
    'qb-doorlock'
}
