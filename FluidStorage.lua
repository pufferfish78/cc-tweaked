local fluid_tanks = {peripheral.find("create:fluid_tank")}
local basin = peripheral.find("create:basin")
function input(input)
    if not input then
        return
    end
    local vacant=false
    for i,fluid_tank in pairs(fluid_tanks) do
        local content = fluid_tank.tanks()[1]
        if not content then
            vacant = true
        elseif content.name == input.name then
            if basin.pushFluid(peripheral.getName(fluid_tank)) == input.amount then
                return
            else
                return
            end
        end
    end
    if vacant then
        for i,fluid_tank in pairs(fluid_tanks) do
            if not fluid_tank.tanks()[1] then
                basin.pushFluid(peripheral.getName(fluid_tank))
                return
            end
        end
    else
    end
end
function output(name)
    for i,fluid_tank in pairs(fluid_tanks) do
        if fluid_tank.tanks()[1].name == name then
            basin.pullFluid(peripheral.getName(fluid_tank))
            print("done")
            return
        end
    end
    print("not found")
end
function check()
    for i,fluid_tank in pairs(fluid_tanks) do
        if fluid_tank.tanks()[1] then
            print(string.format("[%d]%s",i,fluid_tank.tanks()[1].name))
        end
    end
    local id = tonumber(io.read())
    if fluid_tanks[id] then
        basin.pullFluid(peripheral.getName(fluid_tanks[id]))
        return
    else
        print("invalid id\nexit")
        return
    end
end
if not arg[1] then
    for i,slot in pairs(basin.tanks()) do
        input(slot)
    end
    print("done")
elseif arg[1] == "c" or arg[1] == "C" then
    check()
else
    output(arg[1])
end





    