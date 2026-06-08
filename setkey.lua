-- setkey.lua -- save your Kromer wallet private key for the shop. Run ONCE.
-- Stores the key locally in wallet.secret (the same place Radon reads it from),
-- so it survives re-downloading config.lua and you never re-enter it.
term.clear()
term.setCursorPos(1, 1)
print("=== Kromer wallet setup ===")
print("")
print("In Minecraft chat run:  /kromer info")
print("Click 'Copy key', then right-click here to paste.")
print("(input is hidden)")
print("")
write("Private key: ")
local key = read("*")
key = (tostring(key or ""):gsub("^%s*(.-)%s*$", "%1"))
if key == "" then
    print("No key entered -- nothing saved.")
    return
end

local store = {}
if fs.exists("wallet.secret") then
    local f = fs.open("wallet.secret", "r")
    local ok, data = pcall(textutils.unserialize, f.readAll())
    f.close()
    if ok and type(data) == "table" then store = data end
end
store["kromer"] = key
local f = fs.open("wallet.secret", "w")
f.write(textutils.serialize(store))
f.close()

print("")
print("Saved to wallet.secret. You're set.")
print("Make sure config.lua has mockKromer = false,")
print("then run:  radon")
