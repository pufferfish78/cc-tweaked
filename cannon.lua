-- 检查参数
local args = {...}

-- 配置文件路径
local configPath = "cannon_config.txt"

-- 数学常量
local PI = math.pi

-- 写入配置文件
local function writeConfig()
    print("=== Cannon Configuration ===")
    
    -- 获取输入
    print("Enter cannon base coordinates:")
    io.write("x: ")
    local baseX = tonumber(read())
    io.write("y: ")
    local baseY = tonumber(read())
    io.write("z: ")
    local baseZ = tonumber(read())
    
    print("\nEnter target coordinates:")
    io.write("x: ")
    local targetX = tonumber(read())
    io.write("y: ")
    local targetY = tonumber(read())
    io.write("z: ")
    local targetZ = tonumber(read())
    
    print("\nEnter barrel length:")
    local barrelLength = tonumber(read())
    
    print("Enter projectile speed:")
    local projectileSpeed = tonumber(read())
    
    -- 验证输入
    if not baseX or not baseY or not baseZ or 
       not targetX or not targetY or not targetZ or
       not barrelLength or not projectileSpeed then
        print("Error: Invalid number input")
        return false
    end
    
    -- 写入文件
    local file = fs.open(configPath, "w")
    file.write(string.format("%.2f,%.2f,%.2f\n", baseX, baseY, baseZ))
    file.write(string.format("%.2f,%.2f,%.2f\n", targetX, targetY, targetZ))
    file.write(string.format("%.2f\n", barrelLength))
    file.write(string.format("%.2f\n", projectileSpeed))
    file.close()
    
    print("\nConfiguration saved to " .. configPath)
    return true
end

-- 读取配置文件
local function readConfig()
    if not fs.exists(configPath) then
        print("Error: Config file not found: " .. configPath)
        print("Please run: program c to create configuration first")
        return nil
    end
    
    local file = fs.open(configPath, "r")
    local baseLine = file.readLine()
    local targetLine = file.readLine()
    local barrelLine = file.readLine()
    local speedLine = file.readLine()
    file.close()
    
    -- 解析坐标
    local bx, by, bz = baseLine:match("([^,]+),([^,]+),([^,]+)")
    local tx, ty, tz = targetLine:match("([^,]+),([^,]+),([^,]+)")
    
    local config = {
        baseX = tonumber(bx),
        baseY = tonumber(by),
        baseZ = tonumber(bz),
        targetX = tonumber(tx),
        targetY = tonumber(ty),
        targetZ = tonumber(tz),
        barrelLength = tonumber(barrelLine),
        projectileSpeed = tonumber(speedLine)
    }
    
    return config
end

-- 计算函数
local function f(theta, x, y, v, k)
    local sec = 1 / math.cos(theta)
    local tan = math.tan(theta)
    local term1 = x * tan
    local term2 = (100 * x / v) * sec
    local inner = 1 - (x * sec - k) / (5 * v)
    local term3 = 500 * math.log(inner)
    return term1 + term2 + term3 - y + 2 - (100*k/v)
end

-- 计算导数
local function df(theta, x, y, v, k)
    local sec = 1 / math.cos(theta)
    local sec2 = sec * sec
    local tan = math.tan(theta)
    local term1 = x * sec2
    local term2 = (100 * x / v) * tan * sec
    local inner = 1 - (x * sec - k) / (5 * v)
    local term3 = (500 / inner) * (-x / (5 * v) * math.sin(theta) / (math.cos(theta) * math.cos(theta)))
    return term1 + term2 + term3
end

-- 牛顿法求解
local function newtonMethod(x, y, v, k)
    -- 定义域
    local lowerBound = -PI / 6
    local upperBound = PI / 3
    
    -- 限制条件
    local cosLimit = x / (5 * v + k)
    if cosLimit < 1 then
        local angleLimit = math.acos(cosLimit)
        lowerBound = math.max(lowerBound, -angleLimit)
        upperBound = math.min(upperBound, angleLimit)
    end
    
    -- 尝试多个初始值
    local initialGuesses = {0, 0.1, -0.1, 0.2, -0.2, 0.3, -0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
    
    for _, guess in ipairs(initialGuesses) do
        if guess >= lowerBound and guess <= upperBound then
            local theta = guess
            local maxIterations = 100
            local tolerance = 1e-6
            
            for i = 1, maxIterations do
                local fVal = f(theta, x, y, v, k)
                local dfVal = df(theta, x, y, v, k)
                
                if math.abs(dfVal) < 1e-10 then
                    break
                end
                
                local newTheta = theta - fVal / dfVal
                
                -- 保持在定义域内
                if newTheta < lowerBound or newTheta > upperBound then
                    break
                end
                
                if math.abs(newTheta - theta) < tolerance then
                    return newTheta
                end
                
                theta = newTheta
            end
        end
    end
    
    return nil
end

-- 计算方位角
local function calculateAzimuth(baseX, baseZ, targetX, targetZ)
    local dx = targetX - baseX
    local dz = targetZ - baseZ
    
    -- 水平距离
    local horizontalDist = math.sqrt(dx * dx + dz * dz)
    
    if horizontalDist < 1e-6 then
        return 0  -- Target is directly above
    end
    
    -- 计算角度
    -- Definition: (0, ~, 1) direction is 0 degrees, (-1, ~, 0) direction is 90 degrees
    -- Use atan2 to calculate angle
    local angle = math.atan2(-dx, dz)
    
    -- Convert to degrees
    local angleDeg = math.deg(angle)
    
    -- Normalize to 0-360 degrees
    if angleDeg < 0 then
        angleDeg = angleDeg + 360
    end
    
    return angleDeg
end

-- 主程序
local function main()
    local config = readConfig()
    if not config then
        return
    end
    
    -- 显示配置
    print("\n=== Current Configuration ===")
    print(string.format("Cannon base coordinates: (%.2f, %.2f, %.2f)", 
        config.baseX, config.baseY, config.baseZ))
    print(string.format("Target coordinates: (%.2f, %.2f, %.2f)", 
        config.targetX, config.targetY, config.targetZ))
    print(string.format("Barrel length: %.2f", config.barrelLength))
    print(string.format("Projectile speed: %.2f", config.projectileSpeed))
    
    -- 计算水平距离和高度差
    local dx = config.targetX - config.baseX
    local dz = config.targetZ - config.baseZ
    local horizontalDist = math.sqrt(dx * dx + dz * dz)
    local heightDiff = config.targetY - config.baseY
    
    print(string.format("\nHorizontal distance: %.2f", horizontalDist))
    print(string.format("Height difference: %.2f", heightDiff))
    
    -- 计算仰角
    local elevation = newtonMethod(
        horizontalDist, 
        heightDiff, 
        config.projectileSpeed, 
        config.barrelLength
    )
    
    if elevation then
        local elevationDeg = math.deg(elevation)
        print(string.format("\nRecommended elevation angle: %.2f degrees", elevationDeg))
    else
        print("\nWarning: Unable to find valid elevation angle solution")
    end
    
    -- 计算方位角
    local azimuth = calculateAzimuth(
        config.baseX, config.baseZ, 
        config.targetX, config.targetZ
    )
    print(string.format("Recommended azimuth angle: %.2f degrees", azimuth))
end

-- 主入口
if args[1] == 'c' or args[1] == 'C' then
    writeConfig()
else
    main()
end