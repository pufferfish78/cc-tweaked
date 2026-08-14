local ingredients = peripheral.find("minecraft:barrel")
local fluid_tanks = {peripheral.find("create:fluid_tank")}
local equipments = {}
local liquids = {
    ["minecraft:water_bucket"] = "minecraft:water",
    ["minecraft:lava_bucket"] = "minecraft:lava",
    ["minecraft:milk_bucket"] = "minecraft:milk",
    ["create:honey_bucket"] = "create:honey",
    ["create:chocolate_bucket"] = "create:chocolate"
}
function config()
    local SequenceAssemblyConfig = io.open("SequenceAssemblyConfig.txt","w")
    if not ingredients.getItemDetail(1) then
        print("Put an item in the first slot of the barrel")
        while not ingredients.getItemDetail(1) do 
            os.sleep(1)
        end
    end
    local sets = {
        "create:deployer",
        "create:spout",
        "create:mechanical_saw",
        "create:mechanical_press"
    }
    local depots = {peripheral.find("create:depot")}
    
    for _,depot in pairs(depots) do
        depot.pullItems(peripheral.getName(ingredients),1)
        print("Enter the equipment number for the current depot")
        for idx,equipment in pairs(sets) do
            print(string.format("[%d]%s",idx,equipment))
        end
        local idx = tonumber(io.read())
        SequenceAssemblyConfig:write(string.format("%s\n%s\n",sets[idx],peripheral.getName(depot)))
        sets[idx] = nil
        depot.pushItems(peripheral.getName(ingredients),1)
        
    end
    SequenceAssemblyConfig:close()
end
function pickIngre(temp,ptr)
    for idx = 0,#temp do
        ptr[idx] = nil
        if equipments[temp[idx]] then
            --print(string.format("%s is an equipment",temp[idx]))
        elseif liquids[temp[idx]] then
            for _,tank in pairs(fluid_tanks) do
                if tank.tanks()[1].name == liquids[temp[idx]] and tank.tanks()[1].amount >= 1000 then
                    ptr[idx] = peripheral.getName(tank)
                    goto continue1
                end
            end
            print(string.format("%s not enough",liquids[temp[idx]]))
            return false
        else
            for slot, item in pairs(ingredients.list()) do
                if item.name == temp[idx] then
                    if idx==0 or (item.count >= temp.circ) or item.name == "create:wrench" then
                        ptr[idx] = slot
                        --print(string.format("%s at %d",temp[idx],slot))
                        break
                    end
                end
            end
            if not ptr[idx] then
                print(string.format("%s not enough",temp[idx]))
                return false
            end
        end
        ::continue1::
    end
    return true
end
function storeFluid(basin)
    local input = basin.tanks()[1]
    
    if not input then
        print("done")
        return
    end
    local vacant=false
    for i,fluid_tank in pairs(fluid_tanks) do
        local content = fluid_tank.tanks()[1]
        if not content then
            vacant = true
        elseif content.name == input.name then
            if basin.pushFluid(peripheral.getName(fluid_tank)) == input.amount then
                print("stored")
                return
            else
                print("tank full")
                return
            end
        end
    end
    if vacant then
        for i,fluid_tank in pairs(fluid_tanks) do
            if not fluid_tank.tanks()[1] then
                basin.pushFluid(peripheral.getName(fluid_tank))
                print("stored in new tank")
                return
            end
        end
    else
        print("no vacant tank")
        return
    end
end
function operation()
    local deployer = peripheral.find("create:deployer")
    local spout = peripheral.find("create:spout")
    local saw = peripheral.find("create:saw")
    local template = peripheral.find("minecraft:chest")
    local SequenceAssemblyConfig = io.open("SequenceAssemblyConfig.txt","r")
    local key = nil
    for line in SequenceAssemblyConfig:lines() do 
        if not key then
            key = line
        else 
            equipments[key] = line
            key = nil
        end
    end
    SequenceAssemblyConfig:close()
    local recipes = {}
    local pointer = {}
    local EMPTY = {}
    for i=1,template.size()/9,1 do
        if not template.getItemDetail(i*9-8) then
            break
        end
        local j = 0
        recipes[i] = {}
        pointer[i] = {}
        recipes[i].circ = 1
        while template.getItemDetail(i*9-8+j) do
            if template.getItemDetail(i*9-8+j).name == "minecraft:stone_button" then
                recipes[i].circ = template.getItemDetail(i*9-8+j).count
                break;
            else
                recipes[i][j] = template.getItemDetail(i*9-8+j).name 
            j = j+1
            end
        end
    end
    while recipes[1] do
        local state = false
        for i=1,#recipes do
            if not pickIngre(recipes[i],pointer[i]) then
                --[[for j=i,#recipes do
                    recipes[j] = recipes[j+1]
                    pointer[j] = pointer[j+1]
                end
                break]]--
                goto continue3
            end
            state = true
            local circ = recipes[i].circ
            local nbt
            local name
            local toname
            local fromname = peripheral.getName(ingredients)
            local fromslot = pointer[i][0]
            
            for l=1,circ do
                for k=1,#recipes[i] do
                    if recipes[i][k] == "create:mechanical_saw" then
                        ingredients.pullItems(equipments["create:mechanical_saw"],1)
                        toname = peripheral.getName(saw)

                    elseif equipments[recipes[i][k]] then
                        toname = equipments[recipes[i][k]]
                    elseif liquids[recipes[i][k]] then
                        storeFluid(spout)
                        toname = equipments["create:spout"]
                        spout.pullFluid(pointer[i][k])
                    else
                        deployer.pushItems(peripheral.getName(ingredients),1)
                        toname = equipments["create:deployer"]
                        deployer.pullItems(peripheral.getName(ingredients),pointer[i][k],1)

                    end
                    if fromname ~= toname then
                        peripheral.wrap(fromname).pushItems(toname,fromslot,1)
                        fromslot = 1
                        if equipments[recipes[i][k]] then
                            fromname = equipments[recipes[i][k]]
                        elseif liquids[recipes[i][k]] then
                            fromname = equipments["create:spout"]
                        else 
                            fromname = equipments["create:deployer"]
                        end
                    end
                    local cur_depot = peripheral.wrap(fromname)
                    nbt = (cur_depot.getItemDetail(1) or EMPTY).nbt
                    name = (cur_depot.getItemDetail(1) or EMPTY).name
                    print(name)
                    print("here")
                    while nbt == (cur_depot.getItemDetail(1) or EMPTY).nbt and name == (cur_depot.getItemDetail(1) or EMPTY).name do
                        os.sleep(0.1)
                    end
                    
                end
            end
            ingredients.pullItems(fromname,fromslot)
            ingredients.pullItems(peripheral.getName(deployer),1)
            ingredients.pullItems(equipments["create:mechanical_saw"],1)
            storeFluid(spout)
            ::continue3::
        end
        if not state then
            break
        end
    end
    print("ingredients used up")
end
if not arg[1] then
    operation()
elseif arg[1] == "c" or arg[1] == "C" then
    config()
elseif arg[1] == "f" or arg[1] == "F" then
    storeFluid(peripheral.find("create:item_drain"))
else
    print("\"c/C\":start configuration")
end


