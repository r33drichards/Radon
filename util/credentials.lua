-- credentials.lua
--
-- Keeps wallet private keys OUT of config.lua. On first run Radon prompts for
-- each currency's key with hidden input and stores it locally on the computer
-- in wallet.secret, reusing it on later runs. config.lua can be shared safely
-- because it never contains the key.

local SECRET_FILE = "wallet.secret"

local function trim(s)
    return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
end

local function loadStore()
    if fs.exists(SECRET_FILE) then
        local f = fs.open(SECRET_FILE, "r")
        local raw = f.readAll()
        f.close()
        local ok, data = pcall(textutils.unserialize, raw)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function saveStore(store)
    local f = fs.open(SECRET_FILE, "w")
    f.write(textutils.serialize(store))
    f.close()
end

local function promptKey(currencyId)
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Radon wallet setup: " .. currencyId .. " ===")
    print("")
    print("In Minecraft chat, run:  /kromer info")
    print("Click 'Copy key', then right-click here to paste.")
    print("(your key stays hidden and is saved to wallet.secret)")
    print("")
    write("Private key: ")
    return trim(read("*"))
end

-- Fill in currency.pkey for any currency that doesn't have one, from the local
-- store or by prompting. Call this after loading config and before validation.
local function ensureCredentials(config)
    local store = loadStore()
    local changed = false
    for _, currency in ipairs(config.currencies) do
        if not currency.pkey or currency.pkey == "" then
            local key = trim(store[currency.id])
            while key == "" do
                key = promptKey(currency.id)
            end
            if key ~= store[currency.id] then
                store[currency.id] = key
                changed = true
            end
            currency.pkey = key
        end
    end
    if changed then
        saveStore(store)
    end
end

return {
    ensureCredentials = ensureCredentials,
}
