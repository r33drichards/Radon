-- diag2.lua -- tests the Kromer connection FROM THE TURTLE.
-- If the websocket can't open here, the shop stays grey ("Connecting...").
term.clear()
term.setCursorPos(1, 1)
local node = "https://kromer.reconnected.cc/api/krist/"

print("== KROMER CONNECTION TEST ==")

-- 1. motd (plain http.get)
local r = http.get(node .. "motd")
if r then
    print("motd GET: " .. tostring(r.getResponseCode()))
    r.close()
else
    print("motd GET: FAILED (http blocked?)")
    return
end

-- 2. ws/start (http.post -> websocket url)
local p = http.post(node .. "ws/start",
    textutils.serializeJSON({ privatekey = "diagtest" }),
    { ["content-type"] = "application/json" })
if not p then
    print("ws/start POST: FAILED")
    return
end
local body = p.readAll()
p.close()
local data = textutils.unserializeJSON(body)
if not (data and data.url) then
    print("ws/start: no url -> " .. tostring(body):sub(1, 80))
    return
end
print("ws url: ok")

-- 3. the actual gate: http.websocket(url)
print("opening websocket...")
local ws, err = http.websocket(data.url)
if ws then
    print("WEBSOCKET: OK  <-- connection works")
    local m = ws.receive(5)
    print("first msg: " .. tostring(m and tostring(m):sub(1, 50)))
    ws.close()
    print("")
    print(">> Connection is fine. Grey is NOT the connection.")
else
    print("WEBSOCKET: FAILED")
    print("err: " .. tostring(err))
    print("")
    print(">> THIS is why the shop is grey:")
    print(">> the turtle can't open the Kromer websocket.")
    print(">> (server likely blocks CC websockets)")
end
