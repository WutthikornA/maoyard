local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local API_URL = "https://wareguardv2.xyz/api"
local API_KEY  = "rexhub_9a972e4c4e87a58494ef86b22130bf3b"
local SERVICE  = "rexhub"
-- HWID: บางมือถือไม่รองรับ RbxAnalyticsService ให้ใช้ fallback
local hwid = ""
pcall(function()
    hwid = game:GetService("RbxAnalyticsService"):GetClientId()
end)
if hwid == "" then
    pcall(function()
        hwid = tostring(game:GetService("Players").LocalPlayer.UserId)
    end)
end
if hwid == "" then
    hwid = tostring(game.JobId)
end

-- HTTP helpers (mobile-first: HttpGet works on all executors)
local function httpGet(url)
    -- game:HttpGet ใช้ได้ทุก executor ทั้งมือถือและ PC
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and body and body ~= "" then
        return body
    end
    error("httpGet failed")
end

local function httpRequest(options)
    -- สำหรับ POST: ลองตามลำดับ syn -> http -> request
    local _reqFn = rawget(_G, "request") or rawget(_G, "http_request")
    local _syn = rawget(_G, "syn")
    local _http = rawget(_G, "http")
    if _syn and _syn.request then
        return _syn.request(options)
    elseif _http and _http.request then
        return _http.request(options)
    elseif _reqFn then
        return _reqFn(options)
    end
    error("No HTTP POST function found")
end

local GameScripts = {
    ["Anime Final Quest"] = {
        Ids = {7798947148},
        Link = "https://wareguardv2.xyz/raw?service=rexhub&script=AnimeFinalQuest",
        PremiumLink = "https://wareguardv2.xyz/raw?service=rexhub&script=AnimeFinalQuestPremium"
    },
    ["SailorPiece"] = {
        Ids = {77747658251236},
        Link = "https://wareguardv2.xyz/raw?service=rexhub&script=SailorPiece",
        PremiumLink = "https://wareguardv2.xyz/raw?service=rexhub&script=SailorPiecePremium"
    },
    ["All Star Tower Defense"] = {
        Ids = {1720936166}, -- ใช้ Universe ID นี้เลย จบในตัวเดียว!
        Link = "https://wareguardv2.xyz/raw?service=rexhub&script=Astd", -- สมมติใช้ชื่อ script=astd แบบเดียวกับชื่อไฟล์คุณ
        PremiumLink = "https://wareguardv2.xyz/raw?service=rexhub&script=AstdPremium"
    },
    ["Anime Ranger X"] = {
        Ids = {9774981774},
        Link = "https://wareguardv2.xyz/raw?service=rexhub&script=AnimeRangerX",
        PremiumLink = "https://wareguardv2.xyz/raw?service=rexhub&script=AnimeRangerXPremium"
    }
}

-- หา script ของเกมปัจจุบัน
local currentPlaceId = tonumber(game.PlaceId)
local currentGameId = tonumber(game.GameId) -- ดึง Universe ID ด้วยเพื่อครอบคลุมทุกโหมดของเกมนั้นๆ
local currentGame = nil

for name, gameData in pairs(GameScripts) do
    for _, id in ipairs(gameData.Ids) do
        local checkId = tonumber(id)
        -- เช็คทั้ง PlaceId ปัจจุบัน และ GameId หลักของแมพ
        if checkId == currentPlaceId or checkId == currentGameId then
            currentGame = gameData
            break
        end
    end
    if currentGame then break end
end

-- ถ้าไม่เจอเกม แสดง UI แต่ปิดปุ่ม Verify (ไม่ return ออกทิ้ง)

-- ล้าง UI เก่า
pcall(function()
    if CoreGui:FindFirstChild("RexHubKeySystem") then
        CoreGui.RexHubKeySystem:Destroy()
    end
end)

-- Blur (pcall เพราะบางมือถือ error)
local blur = nil
pcall(function()
    blur = Instance.new("BlurEffect", game:GetService("Lighting"))
    blur.Size = 10
end)

-- ScreenGui: ลอง CoreGui ก่อน ถ้าไม่ได้ใช้ PlayerGui
local guiParent = CoreGui
pcall(function()
    -- ทดสอบว่า CoreGui ใช้ได้ไหม
    local test = Instance.new("Frame")
    test.Parent = CoreGui
    test:Destroy()
end)
if not pcall(function() local _ = CoreGui.Name end) then
    guiParent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "RexHubKeySystem"
sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false
sg.Parent = guiParent

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BorderSizePixel = 0
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Parent = sg

local AspectRatio = Instance.new("UIAspectRatioConstraint")
AspectRatio.AspectRatio = 1.58
AspectRatio.Parent = Main

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(45, 45, 55)
Stroke.Parent = Main

-- Top accent line
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = Color3.fromRGB(90, 100, 250)
topBar.BorderSizePixel = 0
topBar.Parent = Main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "REX HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

-- Subtitle
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 20)
SubTitle.Position = UDim2.new(0, 0, 0, 40)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Please authenticate to access the script"
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.Parent = Main

-- Input Frame
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(0.85, 0, 0, 45)
InputFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
InputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
InputFrame.Parent = Main
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(50, 50, 60)
InputStroke.Parent = InputFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.new(0, 10, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Text = ""
KeyInput.PlaceholderText = "Enter License Key..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputFrame

-- Button Grid
local ButtonGrid = Instance.new("Frame")
ButtonGrid.Size = UDim2.new(0.85, 0, 0, 40)
ButtonGrid.Position = UDim2.new(0.5, 0, 0.75, 0)
ButtonGrid.AnchorPoint = Vector2.new(0.5, 0.5)
ButtonGrid.BackgroundTransparency = 1
ButtonGrid.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Parent = ButtonGrid

local function CreateBtn(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 1, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = ButtonGrid
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.1)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)

    return btn
end

local GetBtn   = CreateBtn("Get Key",        Color3.fromRGB(40, 40, 45))
local CheckBtn = CreateBtn("Verify License", Color3.fromRGB(90, 100, 250))

-- Status Label
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 1, -28)
Status.BackgroundTransparency = 1
Status.Text = currentGame and "System Ready" or "Game not supported"
Status.TextColor3 = currentGame and Color3.fromRGB(100, 100, 110) or Color3.fromRGB(220, 100, 80)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = Main

if not currentGame then
    CheckBtn.Active = false
    CheckBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
end

-- Dragging
local dragStart, startPos, dragging = nil, nil, false

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Get Key
GetBtn.MouseButton1Click:Connect(function()
    local url = "https://wareguardv2.xyz/getkey.php?service="
        .. HttpService:UrlEncode(SERVICE) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    pcall(setclipboard, url)
    Status.Text = "Link copied to clipboard!"
    Status.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

-- Verify
CheckBtn.MouseButton1Click:Connect(function()
    if not currentGame then return end

    local key = KeyInput.Text
    if key == "" then
        Status.Text = "Please enter your key"
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    Status.Text = "Validating..."
    Status.TextColor3 = Color3.fromRGB(160, 160, 170)
    CheckBtn.Active = false

    local validateUrl = API_URL
        .. "?action=validate_key"
        .. "&api_key=" .. HttpService:UrlEncode(API_KEY)
        .. "&key="     .. HttpService:UrlEncode(key)
        .. "&hwid="    .. HttpService:UrlEncode(hwid)

    local ok, rawBody = pcall(function()
        return game:HttpGet(validateUrl)
    end)

    if not ok or not rawBody or rawBody == "" then
        Status.Text = "Request failed. Check connection."
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckBtn.Active = true
        return
    end

    local data
    pcall(function() data = HttpService:JSONDecode(rawBody) end)

    if not data then
        Status.Text = "Invalid server response."
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckBtn.Active = true
        return
    end

    if data.valid then
        local tag = data.is_premium and " [PREMIUM]" or ""
        Status.Text = "Access Granted!" .. tag
        Status.TextColor3 = Color3.fromRGB(100, 255, 150)

        -- เลือก link
        local link = nil
        if data.is_premium and currentGame.PremiumLink then
            link = currentGame.PremiumLink
        else
            link = currentGame.Link
        end

        if not link then
            Status.Text = "No script link found."
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            CheckBtn.Active = true
            return
        end

        -- Fetch & Execute Loop (Max 5 times)
        task.spawn(function()
            local success = false
            local attempt = 1
            local maxAttempts = 15
            
            -- ปิด UI ทีเดียว
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
                Position = UDim2.new(0.5, 0, 1.5, 0)
            }):Play()
            task.wait(0.6)
            blur:Destroy()
            sg:Destroy()

            while attempt <= maxAttempts and not success do
                local scriptContent = nil
                local fetchOk, fetchErr = pcall(function()
                    local separator = string.find(link, "?") and "&" or "?"
                    local cacheBuster = link .. separator .. "t=" .. tostring(math.random(1000000, 9999999))
                    scriptContent = httpGet(cacheBuster)
                end)

                if fetchOk and type(scriptContent) == "string" and scriptContent ~= "" then
                    local fn, compileErr = loadstring(scriptContent)
                    if fn then
                        local runOk, runErr = pcall(function() return fn() end)
                        if runOk then
                            success = true
                            print("[RexHub] Script completely loaded on attempt " .. attempt .. "!")
                        else
                            warn("[RexHub] Execution bugged on attempt " .. attempt .. " (WeAreDevs/Executor issue). Refetching...")
                        end
                    else
                        warn("[RexHub] Compile error on attempt " .. attempt)
                    end
                else
                    warn("[RexHub] Fetch error on attempt " .. attempt)
                end
                
                if not success then
                    attempt = attempt + 1
                    task.wait(1)
                end
            end
            
            if not success then
                warn("[RexHub] WeAreDevs Obfuscator completely broke after " .. maxAttempts .. " re-downloads. Please use an unobfuscated script or change Obfuscator!")
            end
        end)
    else
        local getkey_url = "https://wareguardv2.xyz/getkey.php?service="
            .. HttpService:UrlEncode(SERVICE) .. "&hwid=" .. HttpService:UrlEncode(hwid)
        pcall(setclipboard, getkey_url)
        Status.Text = data.error or "Invalid key. URL copied!"
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckBtn.Active = true
    end
end)

-- Intro animation
TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 380, 0, 240)
}):Play()
