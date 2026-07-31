local log = io.open("peripherals.txt","w")
local peripherals = peripheral.getNames()
local types = {}
log:write("types:\n")
for i,name in pairs(peripherals) do
    types[peripheral.getType(name)] = 1
end
for type,_ in pairs(types) do
    log:write(type.."\n")
end
log:write("=========\nnames:\n")

for i,name in pairs(peripherals) do
    log:write(name.."\n")
end
log:close()
