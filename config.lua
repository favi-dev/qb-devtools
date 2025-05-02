Config = {}

Config.UsePermissions = true
Config.RequiredPermission = 'admin'
Config.AllowedIdentifiers = {
}

Config.OpenCommand = 'Favi.Dev'
Config.AdminOpenCommand = 'Favi.Dev'

Config.UISettings = {
    HotKey = 'F7',
    DefaultFontSize = 14,
    Theme = 'dark',
    ShowClock = true,
    Animation = true,
    BlurBackground = true,
}

Config.Features = {
    EventMonitoring = {
        Enabled = true,
        BlacklistedEvents = {
            'playerLoaded',
            'onPlayerDeath',
        },
        MaxEventsHistory = 100,
    },
    LuaExecution = {
        Enabled = true,
        RestrictedFunctions = {
            'os.execute',
            'io.popen',
        },
        MaxExecutionTime = 5000,
    },
    ResourceManager = {
        Enabled = true,
        BlockedResources = {
            'qb-core',
            'mysql-async',
            'oxmysql',
        },
    },
    DebugTools = {
        Enabled = true,
        ShowCoordinates = true,
        ShowHeading = true,
        ShowEntityInfo = true,
        ShowServerInfo = true,
    },
    LiveLogs = {
        Enabled = true,
        MaxLogEntries = 200,
        AutoScroll = true,
    }
}

Config.TeleportLocations = {
    { name = 'LSPD', x = 440.91, y = -983.04, z = 30.69 },
    { name = 'Hospital', x = 307.76, y = -594.99, z = 43.28 },
    { name = 'Garage', x = -330.01, y = -780.33, z = 33.96 },
}
