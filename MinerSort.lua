local vault = peripheral.find("create:item_vault")
local bin = peripheral.find("fxntstorage:storage_box_entity")

function config()
    local file = io.open("sortConfig.txt","w")
    local preserveItems = {}
    for slot,item in pairs(vault.list()) do
        preserveItems[item.name] = 1
    end
    for name,_ in pairs(preserveItems) do
        print(string.format("keep %s ?",name))
        local input = io.read()
        if input == "1" or input == "y" or input == "Y" then
            file:write(string.format("%s\n",name))
        end
    end
    file:close()
end
function select()
    local preserveItems = {}
    for line in io.lines("sortConfig.txt") do
        preserveItems[line] = 1
    end
    for slot,item in pairs(vault.list()) do
        if not preserveItems[item.name] then
            vault.pushItems(peripheral.getName(bin),slot)
        end
    end
end
if not arg[1] then
    select()
elseif arg[1] == "c" or arg[1] == "C" then
    config()
else
    print("use \"c\" to start configuration")
end