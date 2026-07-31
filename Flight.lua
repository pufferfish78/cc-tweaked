function flight()
    local file = io.open("param.txt","r")
    local log = io.open("log.txt","w")
    local kp = tonumber(file:read("*l"))
    local ki = tonumber(file:read("*l"))
    local kd = tonumber(file:read("*l"))
    local dt = tonumber(file:read("*l"))
    local ff = tonumber(file:read("*l"))
    local mi = 15/ki
    local i = 0
    local t = 0
    file:close()
    local height = {}
    monitor.setTextScale(0.5)
    local uside = "right"
    local u = 0
    if not height[-1] then
        height[-1] = sensor.getHeight()
    end
    while true do
        height[0] = sensor.getHeight()
        local err = target_height - height[0]
        i = i + err*math.exp(-err/10)
        if i>mi then
            i=mi
        elseif i<-mi then
            i=-mi
        end
        u = kp*err + kd*(height[-1]-height[0])/dt + ki*i + ff
        if u>15 then
            u=15
        elseif u<0 then
            u=0
        end
        t = t+dt
        log:write(t)
        log:write(" ")
        log:write(height[0])
        log:write("\n")
        redstone.setAnalogOutput(uside,u)
        height[-1]=height[0]
        os.sleep(dt)
    end
    log:close()
end
function screen()
    while true do
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write(string.format("tgt:%d",target_height))
        monitor.setCursorPos(1,2)
        monitor.write(string.format("crnt:%d",sensor.getHeight()))
        monitor.setBackgroundColor(colors.white)
        monitor.setCursorPos(1,3)
        monitor.write(" ")
        monitor.setCursorPos(1,5)
        monitor.write(" ")
        monitor.setBackgroundColor(colors.black)
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        
        if event == "monitor_touch" then
            local x = eventData[3]
            local y = eventData[4]
            if y >= 3 and y < 4 then
                target_height = target_height + 1
            elseif y >= 5 and y < 6 then
                target_height = target_height - 1
            end
        end
    end
end
if not io.open("param.txt","r") then
    local file = io.open("param.txt","w")
    local content = "2.00000\n"..
                    "0.05000\n"..
                    "5.000000\n"..
                    "0.200000\n"..
                    "5\n"
    file:write(content)
    file:close()
end
if not arg[1] or tonumber(arg[1]) then
    target_height = arg[1] or 100
    sensor = peripheral.find("altitude_sensor")
    monitor = peripheral.find("monitor")
    parallel.waitForAny(flight,screen)
end
        