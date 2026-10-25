Config = {}

-- Prints extra diagnostics to the server console when enabled.
Config.Debug = false

-- UI language: 'tr' or 'en'. Locale files live in locales/.
Config.Locale = 'tr'

-- Background blur strength while the menu is open. Set to 0 to disable.
Config.BlurLevel = 0

-- Storage clerk ped.
Config.NPC = {
    model = `s_m_m_movspace_01`,
    coords = vector4(-68.1458, -1208.8668, 28.1284, 313.9380),
}

-- Interaction
Config.InteractionDistance = 2.0
Config.MenuOpenKey = 38 -- E

-- One-time purchase price for a new storage.
Config.Pricing = {
    bank = 10000,
    cash = 10000,
}

-- Hard limits enforced by both the UI and the server.
Config.Limits = {
    maxSlots = 100,
    maxWeight = 500000, -- grams (500 kg)
    minNameLength = 3,
    maxStoragesPerPlayer = 10,
}

-- Password and login protection.
Config.Security = {
    minPasswordLength = 4,
    maxPasswordLength = 50,
    maxLoginAttempts = 3,
    lockoutDuration = 300, -- seconds
}

-- Toggle optional management actions.
Config.Features = {
    allowLeaveStorage = true,
    allowPasswordRemoval = true,
    allowCapacityUpdate = true,
    requireUniqueNames = true,
}

Config.DefaultImage = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiMwMGFkYmUiIHN0cm9rZS13aWR0aD0iMS41IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMSA4bC05LTktOSA5IDkgOSA5LTl6Ii8+PHBhdGggZD0iTTMuMyA3bDguNyA0LjVMMjAuNyA3Ii8+PHBhdGggZD0iTTEyIDIyVjEyIi8+PC9zdmc+"
