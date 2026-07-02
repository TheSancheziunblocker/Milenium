-- MileniumLoader.lua
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

------------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------------
local GITHUB_USER   = "TheSancheziunblocker"
local GITHUB_REPO   = "Milenium"
local GITHUB_BRANCH = "main"
local API_URL       = string.format(
    "https://api.github.com/repos/%s/%s/contents/Scripts?ref=%s",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)
local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/Scripts/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

------------------------------------------------------------------------
-- SAFE LOADSTRING
------------------------------------------------------------------------
local _loadstring = loadstring
    or (syn and syn.loadstring)
    or (_G and _G.loadstring)
    or nil

------------------------------------------------------------------------
-- SAFE HTTP
------------------------------------------------------------------------
local function HttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res and res ~= "" then return res end
    local reqFn = (syn and syn.request) or (http and http.request) or (request) or nil
    if reqFn then
        local ok2, r = pcall(reqFn, {Url = url, Method = "GET"})
        if ok2 and r and r.Body then return r.Body end
    end
    return nil
end

------------------------------------------------------------------------
-- EXECUTE SCRIPT
------------------------------------------------------------------------
local function ExecScript(filename)
    local src = HttpGet(RAW_BASE .. filename)
    if not src or src == "" then return false, "fetch failed" end

    local fn, err
    for _, ls in ipairs({
        _loadstring,
        syn and syn.loadstring,
        _G and _G.loadstring,
    }) do
        if ls then
            local ok, a, b = pcall(ls, src)
            if ok and type(a) == "function" then fn = a; break
            elseif ok then err = tostring(b)
            else err = tostring(a) end
        end
    end

    if not fn then return false, err or "loadstring unavailable" end
    local rok, rerr = pcall(fn)
    if not rok then return false, rerr end
    return true
end

------------------------------------------------------------------------
-- THEME
------------------------------------------------------------------------
local C = {
    BgWindow  = Color3.fromRGB(15,  17,  21),
    BgHeader  = Color3.fromRGB(10,  11,  15),
    BgCard    = Color3.fromRGB(21,  24,  29),
    BgInput   = Color3.fromRGB(26,  29,  36),
    BgPage    = Color3.fromRGB(13,  15,  19),
    Accent    = Color3.fromRGB(29,  191, 158),
    AccentDim = Color3.fromRGB(19,  128, 106),
    BtnBg     = Color3.fromRGB(38,  42,  52),
    BtnHover  = Color3.fromRGB(50,  55,  68),
    BtnDown   = Color3.fromRGB(22,  26,  34),
    TextMain  = Color3.fromRGB(209, 213, 219),
    TextMuted = Color3.fromRGB(107, 114, 128),
    TextDis   = Color3.fromRGB(46,  50,  59),
    White     = Color3.fromRGB(255, 255, 255),
    Red       = Color3.fromRGB(210, 60,  60),
    Green     = Color3.fromRGB(29,  191, 100),
}

------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
local function Tw(o, props, t, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(
        t or 0.15,
        Enum.EasingStyle[style or "Quad"],
        Enum.EasingDirection[dir or "Out"]
    ), props)
    tw:Play(); return tw
end

local function N(cls, p)
    local o = Instance.new(cls)
    for k, v in pairs(p) do if k ~= "Parent" then o[k] = v end end
    if p.Parent then o.Parent = p.Parent end
    return o
end

local function Cor(p, r) N("UICorner", {CornerRadius = UDim.new(0, r or 4), Parent = p}) end

local function Stroke(p, col, th, tr)
    N("UIStroke", {Color = col or C.White, Thickness = th or 1, Transparency = tr or 0.92, Parent = p})
end

local function Pad(p, t, b, l, r)
    N("UIPadding", {
        PaddingTop    = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft   = UDim.new(0, l or 10),
        PaddingRight  = UDim.new(0, r or 10),
        Parent        = p,
    })
end

local function VList(p, gap, ha)
    N("UIListLayout", {
        Padding             = UDim.new(0, gap or 0),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Center,
        Parent              = p,
    })
end

local function Draggable(frame, handle)
    local on, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            on = true; ds = i.Position; sp = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if on and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then on = false end
    end)
end

------------------------------------------------------------------------
-- GAME INFO
------------------------------------------------------------------------
local infoCache = {}

local function GetGameInfo(placeId)
    if infoCache[placeId] then return infoCache[placeId] end
    local raw = HttpGet("https://apis.roblox.com/universes/v1/places/" .. placeId .. "/universe")
    if not raw then return nil end
    local ok, ud = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or not ud or not ud.universeId then return nil end
    local uid = ud.universeId

    local draw = HttpGet("https://games.roblox.com/v1/games?universeIds=" .. uid)
    if not draw then return nil end
    local dok, dd = pcall(function() return HttpService:JSONDecode(draw) end)
    if not dok or not dd or not dd.data or not dd.data[1] then return nil end
    local name = dd.data[1].name or ("Game " .. tostring(placeId))

    local icon = ""
    local iraw = HttpGet(
        "https://thumbnails.roblox.com/v1/games/icons?universeIds=" .. uid ..
        "&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false"
    )
    if iraw then
        local iok, id = pcall(function() return HttpService:JSONDecode(iraw) end)
        if iok and id and id.data and id.data[1] then icon = id.data[1].imageUrl or "" end
    end

    local info = {name = name, icon = icon, placeId = placeId}
    infoCache[placeId] = info
    return info
end

------------------------------------------------------------------------
-- PARSE FILENAME
------------------------------------------------------------------------
local function ParseFilename(fn)
    local base = fn:match("^(.+)%.lua$") or fn
    local id   = base:match("^(%d+)")
    if id then return {isGame = true,  placeId = tonumber(id), raw = fn} end
    return          {isGame = false, name = base,              raw = fn}
end

------------------------------------------------------------------------
-- SCREEN GUI
------------------------------------------------------------------------
local SG
do
    local ok = pcall(function()
        local old = CoreGui:FindFirstChild("MileniumLoader")
        if old then old:Destroy() end
        SG = N("ScreenGui", {
            Name = "MileniumLoader", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true, Parent = CoreGui,
        })
    end)
    if not ok or not SG then
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local old = pg:FindFirstChild("MileniumLoader")
        if old then old:Destroy() end
        SG = N("ScreenGui", {
            Name = "MileniumLoader", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true, Parent = pg,
        })
    end
end

------------------------------------------------------------------------
-- DIMENSIONS
------------------------------------------------------------------------
local W, H   = 360, 320
local HEAD   = 36
local COR    = 8

------------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------------
local win = N("Frame", {
    Name                   = "Win",
    Size                   = UDim2.new(0, W * 0.9, 0, H * 0.9),
    Position               = UDim2.new(0.5, -(W * 0.9) / 2, 0.5, -(H * 0.9) / 2),
    BackgroundColor3       = C.BgWindow,
    BackgroundTransparency = 0.08,
    BorderSizePixel        = 0,
    ClipsDescendants       = true,
    Parent                 = SG,
})
Cor(win, COR)
N("UIStroke", {Color = Color3.fromRGB(38, 42, 52), Thickness = 1, Transparency = 0.1, Parent = win})

------------------------------------------------------------------------
-- HEADER
------------------------------------------------------------------------
local hdrOuter = N("Frame", {
    Size             = UDim2.new(1, 0, 0, HEAD),
    BackgroundColor3 = C.BgHeader,
    BorderSizePixel  = 0,
    ZIndex           = 6,
    Parent           = win,
})
Cor(hdrOuter, COR)
-- Flatten bottom corners
N("Frame", {
    Size = UDim2.new(1, 0, 0, COR), Position = UDim2.new(0, 0, 1, -COR),
    BackgroundColor3 = C.BgHeader, BorderSizePixel = 0, ZIndex = 7, Parent = hdrOuter,
})
-- Divider
N("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.White, BackgroundTransparency = 0.9,
    BorderSizePixel = 0, ZIndex = 8, Parent = hdrOuter,
})

local hdrHit = N("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 7, Parent = hdrOuter,
})
Draggable(win, hdrHit)

-- Accent dot
local acDot = N("Frame", {
    Size = UDim2.new(0, 7, 0, 7),
    Position = UDim2.new(0, 12, 0.5, -3),
    BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 8, Parent = hdrOuter,
})
Cor(acDot, 4)

-- Title
N("TextLabel", {
    Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(0, 26, 0, 0),
    BackgroundTransparency = 1, Text = "Milenium Loader",
    Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = C.Accent, TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8, Parent = hdrOuter,
})

-- Close button (TextButton so it captures clicks properly)
local closeBtn = N("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(1, -30, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(48, 24, 24),
    BorderSizePixel = 0,
    Text = "x",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(210, 70, 70),
    AutoButtonColor = false,
    ZIndex = 9,
    Parent = hdrOuter,
})
Cor(closeBtn, 4)
closeBtn.MouseEnter:Connect(function()
    Tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(80, 28, 28)}, 0.1)
end)
closeBtn.MouseLeave:Connect(function()
    Tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(48, 24, 24)}, 0.1)
end)
closeBtn.MouseButton1Click:Connect(function()
    Tw(win, {BackgroundTransparency = 1}, 0.18)
    task.delay(0.22, function()
        if SG and SG.Parent then SG:Destroy() end
    end)
end)

------------------------------------------------------------------------
-- PAGE SYSTEM
------------------------------------------------------------------------
-- All pages sit in a clip frame below the header
local pageClip = N("Frame", {
    Size = UDim2.new(1, 0, 1, -HEAD),
    Position = UDim2.new(0, 0, 0, HEAD),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
    Parent = win,
})

local pages      = {}
local activePage = nil

local function ShowPage(name, instant)
    local target = pages[name]
    if not target or activePage == name then return end

    -- slide old page out to the left
    if activePage and pages[activePage] then
        local old = pages[activePage]
        old.ZIndex = 2
        if instant then
            old.Position = UDim2.new(-1, 0, 0, 0)
        else
            Tw(old, {Position = UDim2.new(-1, 0, 0, 0)}, 0.22, "Quad", "In")
            task.delay(0.22, function() old.Visible = false end)
        end
    end

    activePage = name
    target.Visible   = true
    target.ZIndex    = 3
    if instant then
        target.Position = UDim2.new(0, 0, 0, 0)
    else
        target.Position = UDim2.new(1, 0, 0, 0)
        Tw(target, {Position = UDim2.new(0, 0, 0, 0)}, 0.22, "Quad", "Out")
    end
end

local function ShowPageBack(name)
    local target = pages[name]
    if not target or activePage == name then return end

    if activePage and pages[activePage] then
        local old = pages[activePage]
        old.ZIndex = 2
        Tw(old, {Position = UDim2.new(1, 0, 0, 0)}, 0.22, "Quad", "In")
        task.delay(0.22, function() old.Visible = false end)
    end

    activePage = name
    target.Visible   = true
    target.ZIndex    = 3
    target.Position  = UDim2.new(-1, 0, 0, 0)
    Tw(target, {Position = UDim2.new(0, 0, 0, 0)}, 0.22, "Quad", "Out")
end

local function NewPage(name)
    local pg = N("Frame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.BgPage,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 2,
        Parent = pageClip,
    })
    pages[name] = pg
    return pg
end

------------------------------------------------------------------------
-- SHARED HELPERS
------------------------------------------------------------------------
local function MkBtn(parent, text, order, accent)
    local bg = accent and C.Accent or C.BtnBg
    local tc = accent and Color3.fromRGB(10, 10, 12) or C.TextMain

    local btn = N("TextButton", {
        Size             = UDim2.new(1, -28, 0, 34),
        BackgroundColor3 = bg,
        BorderSizePixel  = 0,
        Text             = text,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 11,
        TextColor3       = tc,
        AutoButtonColor  = false,
        LayoutOrder      = order or 1,
        ZIndex           = 4,
        Parent           = parent,
    })
    Cor(btn, 6)
    if not accent then Stroke(btn, C.White, 1, 0.95) end

    btn.MouseEnter:Connect(function()
        Tw(btn, {BackgroundColor3 = accent and C.AccentDim or C.BtnHover}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, {BackgroundColor3 = bg}, 0.1)
    end)
    btn.MouseButton1Down:Connect(function()
        Tw(btn, {BackgroundColor3 = C.BtnDown}, 0.07)
    end)
    btn.MouseButton1Up:Connect(function()
        Tw(btn, {BackgroundColor3 = accent and C.AccentDim or C.BtnHover}, 0.07)
    end)
    return btn
end

local function BackBar(parent, dest)
    local bar = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = C.BgHeader,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = parent,
    })
    -- bottom border
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.White, BackgroundTransparency = 0.92,
        BorderSizePixel = 0, ZIndex = 5, Parent = bar,
    })

    local backBtn = N("TextButton", {
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(0, 8, 0.5, -10),
        BackgroundColor3 = C.BgInput,
        BorderSizePixel = 0,
        Text = "< Back",
        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
        TextColor3 = C.TextMuted,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = bar,
    })
    Cor(backBtn, 4)
    backBtn.MouseEnter:Connect(function()
        Tw(backBtn, {TextColor3 = C.TextMain}, 0.1)
    end)
    backBtn.MouseLeave:Connect(function()
        Tw(backBtn, {TextColor3 = C.TextMuted}, 0.1)
    end)
    backBtn.MouseButton1Click:Connect(function()
        ShowPageBack(dest)
    end)
    return bar
end

local function SearchBar(parent, placeholder, yPos)
    local wrap = N("Frame", {
        Size             = UDim2.new(1, -24, 0, 26),
        Position         = UDim2.new(0, 12, 0, yPos or 40),
        BackgroundColor3 = C.BgInput,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = parent,
    })
    Cor(wrap, 6)
    Stroke(wrap, C.White, 1, 0.93)

    N("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = "S",
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = C.TextDis, ZIndex = 5, Parent = wrap,
    })

    local box = N("TextBox", {
        Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = placeholder or "Search...",
        PlaceholderColor3 = C.TextDis,
        Text = "", Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = C.TextMain, ClearTextOnFocus = false,
        ZIndex = 5, Parent = wrap,
    })
    return box
end

local function Toast(msg, col, dur)
    col = col or C.Accent; dur = dur or 2.5
    local t = N("Frame", {
        Size = UDim2.new(0, 280, 0, 32),
        Position = UDim2.new(0.5, -140, 1, 8),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel = 0, ZIndex = 60, Parent = SG,
    })
    Cor(t, 6)
    N("UIStroke", {Color = col, Thickness = 1, Transparency = 0.35, Parent = t})
    local strip = N("Frame", {
        Size = UDim2.new(0, 3, 1, -10), Position = UDim2.new(0, 7, 0, 5),
        BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 61, Parent = t,
    })
    Cor(strip, 2)
    N("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1, Text = msg,
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = C.TextMain, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 61, Parent = t,
    })
    Tw(t, {Position = UDim2.new(0.5, -140, 1, -40)}, 0.22, "Back", "Out")
    task.delay(dur, function()
        if t and t.Parent then
            Tw(t, {Position = UDim2.new(0.5, -140, 1, 8)}, 0.18, "Quad", "In")
            task.delay(0.22, function() if t and t.Parent then t:Destroy() end end)
        end
    end)
end

local function WireLoad(btn, filename, displayName)
    btn.MouseButton1Click:Connect(function()
        if btn:GetAttribute("busy") then return end
        btn:SetAttribute("busy", true)
        local orig = btn.Text
        btn.Text = "Loading..."
        Tw(btn, {BackgroundColor3 = C.BtnBg, TextColor3 = C.TextMuted}, 0.1)
        task.spawn(function()
            local ok, err = ExecScript(filename)
            if ok then
                Toast("Loaded: " .. displayName, C.Green)
            else
                Toast("Error: " .. tostring(err):sub(1, 50), C.Red, 4)
            end
            task.wait(0.4)
            if btn and btn.Parent then
                btn.Text = orig
                btn:SetAttribute("busy", nil)
                Tw(btn, {BackgroundColor3 = C.Accent, TextColor3 = Color3.fromRGB(10,10,12)}, 0.12)
            end
        end)
    end)
end

------------------------------------------------------------------------
-- STATUS OVERLAY (shown on the home page while loading)
------------------------------------------------------------------------
local statusLbl  -- assigned later on home page

------------------------------------------------------------------------
-- HOME PAGE
------------------------------------------------------------------------
local homePage = NewPage("home")

-- Centered content holder
local homeInner = N("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = homePage,
})
VList(homeInner, 14, Enum.HorizontalAlignment.Center)
Pad(homeInner, 26, 14, 0, 0)

-- Title block
local titleBlock = N("Frame", {
    Size = UDim2.new(1, -28, 0, 44),
    BackgroundColor3 = C.BgCard,
    BorderSizePixel = 0,
    LayoutOrder = 1,
    ZIndex = 3,
    Parent = homeInner,
})
Cor(titleBlock, 7)
Stroke(titleBlock, C.White, 1, 0.96)

N("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0, 6),
    BackgroundTransparency = 1,
    Text = "Milenium Loader",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = C.Accent,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 4,
    Parent = titleBlock,
})

statusLbl = N("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 26),
    BackgroundTransparency = 1,
    Text = "Fetching scripts...",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = C.TextMuted,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 4,
    Parent = titleBlock,
})

-- The three main buttons (created but text updated after fetch)
local btnGames   = MkBtn(homeInner, "Browse Games",   2, false)
local btnCurrent = MkBtn(homeInner, "Current Game",   3, false)
local btnUni     = MkBtn(homeInner, "Universal",      4, false)

-- Dim them until ready
btnGames.TextColor3   = C.TextDis
btnCurrent.TextColor3 = C.TextDis
btnUni.TextColor3     = C.TextDis
btnGames.BackgroundColor3   = C.BgCard
btnCurrent.BackgroundColor3 = C.BgCard
btnUni.BackgroundColor3     = C.BgCard

------------------------------------------------------------------------
-- GAMES PAGE
------------------------------------------------------------------------
local gamesPage = NewPage("games")
BackBar(gamesPage, "home")

local gSearchBox = SearchBar(gamesPage, "Search by game name...", 40)

local gScrollClip = N("Frame", {
    Size = UDim2.new(1, 0, 1, -72),
    Position = UDim2.new(0, 0, 0, 72),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 3,
    Parent = gamesPage,
})

local gScroll = N("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.BgInput,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
    Parent = gScrollClip,
})
VList(gScroll, 7, Enum.HorizontalAlignment.Center)
Pad(gScroll, 8, 12, 0, 0)

------------------------------------------------------------------------
-- UNIVERSAL PAGE
------------------------------------------------------------------------
local uniPage = NewPage("universal")
BackBar(uniPage, "home")

local uSearchBox = SearchBar(uniPage, "Search scripts...", 40)

local uScrollClip = N("Frame", {
    Size = UDim2.new(1, 0, 1, -72),
    Position = UDim2.new(0, 0, 0, 72),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 3,
    Parent = uniPage,
})

local uScroll = N("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.BgInput,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
    Parent = uScrollClip,
})
VList(uScroll, 7, Enum.HorizontalAlignment.Center)
Pad(uScroll, 8, 12, 0, 0)

------------------------------------------------------------------------
-- CURRENT GAME PAGE  (built after data is ready)
------------------------------------------------------------------------
local currentPage = NewPage("current")

------------------------------------------------------------------------
-- ROW BUILDERS
------------------------------------------------------------------------
local function MakeGameRow(parent, info, filename, order)
    local row = N("Frame", {
        Size = UDim2.new(1, -24, 0, 48),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 4,
        Parent = parent,
    })
    Cor(row, 6)
    Stroke(row, C.White, 1, 0.96)

    -- Icon
    local iconF = N("Frame", {
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 6, 0.5, -18),
        BackgroundColor3 = Color3.fromRGB(8, 10, 14),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = row,
    })
    Cor(iconF, 5)
    if info.icon and info.icon ~= "" then
        local img = N("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = info.icon, ScaleType = Enum.ScaleType.Crop,
            ZIndex = 6, Parent = iconF,
        })
        Cor(img, 5)
    else
        N("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "?", Font = Enum.Font.GothamBold, TextSize = 16,
            TextColor3 = C.TextDis, TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 6, Parent = iconF,
        })
    end

    -- Name
    N("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 48, 0, 0),
        BackgroundTransparency = 1,
        Text = info.name or "Unknown",
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = C.TextMain,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
        Parent = row,
    })

    -- Load btn
    local lb = N("TextButton", {
        Size = UDim2.new(0, 52, 0, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Text = "Load",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(10, 10, 12),
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = row,
    })
    Cor(lb, 5)
    WireLoad(lb, filename, info.name or filename)
    return row
end

local function MakeUniRow(parent, name, filename, order)
    local row = N("Frame", {
        Size = UDim2.new(1, -24, 0, 40),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 4,
        Parent = parent,
    })
    Cor(row, 6)
    Stroke(row, C.White, 1, 0.96)

    local dot = N("Frame", {
        Size = UDim2.new(0, 5, 0, 5),
        Position = UDim2.new(0, 10, 0.5, -2),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0, ZIndex = 5, Parent = row,
    })
    Cor(dot, 3)

    N("TextLabel", {
        Size = UDim2.new(1, -88, 1, 0),
        Position = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamSemibold, TextSize = 11,
        TextColor3 = C.TextMain,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5, Parent = row,
    })

    local lb = N("TextButton", {
        Size = UDim2.new(0, 52, 0, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Text = "Load",
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = Color3.fromRGB(10, 10, 12),
        AutoButtonColor = false, ZIndex = 5, Parent = row,
    })
    Cor(lb, 5)
    WireLoad(lb, filename, name)
    return row
end

local function EmptyMsg(parent, msg)
    N("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = msg, Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = C.TextDis,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 1, ZIndex = 4, Parent = parent,
    })
end

------------------------------------------------------------------------
-- POPULATE (called after fetch)
------------------------------------------------------------------------
local function Populate(gameScripts, universalScripts, currentPlaceId)

    -- Update home button labels
    local matchEntry = nil
    for _, e in ipairs(gameScripts) do
        if tostring(e.info.placeId) == tostring(currentPlaceId) then
            matchEntry = e; break
        end
    end

    btnGames.Text   = "Browse Games  (" .. #gameScripts .. ")"
    btnUni.Text     = "Universal  (" .. #universalScripts .. ")"

    -- Current game button label
    if matchEntry then
        -- strip .lua from filename for display
        local scriptName = matchEntry.filename:match("^(.+)%.lua$") or matchEntry.filename
        btnCurrent.Text = matchEntry.info.name .. "  -  " .. scriptName
    else
        local gameName
        local ok2, gi = pcall(GetGameInfo, currentPlaceId)
        if ok2 and gi then gameName = gi.name else gameName = "this game" end
        btnCurrent.Text = gameName .. "  (no script)"
        btnCurrent.TextColor3 = C.TextDis
    end

    -- Re-enable game + uni buttons
    btnGames.TextColor3 = C.TextMain
    btnGames.BackgroundColor3 = C.BtnBg
    btnUni.TextColor3 = C.TextMain
    btnUni.BackgroundColor3 = C.BtnBg
    if matchEntry then
        btnCurrent.TextColor3 = C.TextMain
        btnCurrent.BackgroundColor3 = C.BtnBg
    end

    -- Wire home buttons
    btnGames.MouseButton1Click:Connect(function() ShowPage("games") end)
    btnUni.MouseButton1Click:Connect(function() ShowPage("universal") end)
    btnCurrent.MouseButton1Click:Connect(function() ShowPage("current") end)

    ----------------------------------------------------------------
    -- Games page  list
    ----------------------------------------------------------------
    local function RebuildGames(filter)
        for _, ch in ipairs(gScroll:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
        end
        local n = 0
        for _, e in ipairs(gameScripts) do
            local lc = (e.info.name or ""):lower()
            if filter == "" or lc:find(filter:lower(), 1, true) then
                n = n + 1
                MakeGameRow(gScroll, e.info, e.filename, n)
            end
        end
        if n == 0 then EmptyMsg(gScroll, "No scripts found.") end
    end
    RebuildGames("")
    gSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RebuildGames(gSearchBox.Text)
    end)

    ----------------------------------------------------------------
    -- Universal page list
    ----------------------------------------------------------------
    local function RebuildUni(filter)
        for _, ch in ipairs(uScroll:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
        end
        local n = 0
        for _, e in ipairs(universalScripts) do
            if filter == "" or e.name:lower():find(filter:lower(), 1, true) then
                n = n + 1
                MakeUniRow(uScroll, e.name, e.filename, n)
            end
        end
        if n == 0 then EmptyMsg(uScroll, "No scripts found.") end
    end
    RebuildUni("")
    uSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RebuildUni(uSearchBox.Text)
    end)

    ----------------------------------------------------------------
    -- Current game page
    ----------------------------------------------------------------
    BackBar(currentPage, "home")

    local cpInner = N("Frame", {
        Size = UDim2.new(1, 0, 1, -32),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = currentPage,
    })
    VList(cpInner, 12, Enum.HorizontalAlignment.Center)
    Pad(cpInner, 20, 14, 14, 14)

    if matchEntry then
        local info = matchEntry.info

        -- Icon + name card
        local card = N("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = C.BgCard,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            ZIndex = 4,
            Parent = cpInner,
        })
        Cor(card, 7)
        Stroke(card, C.White, 1, 0.95)

        local iconF = N("Frame", {
            Size = UDim2.new(0, 56, 0, 56),
            Position = UDim2.new(0, 12, 0.5, -28),
            BackgroundColor3 = Color3.fromRGB(8, 10, 14),
            BorderSizePixel = 0, ZIndex = 5, Parent = card,
        })
        Cor(iconF, 6)
        if info.icon and info.icon ~= "" then
            local img = N("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = info.icon, ScaleType = Enum.ScaleType.Crop,
                ZIndex = 6, Parent = iconF,
            })
            Cor(img, 6)
        end

        N("TextLabel", {
            Size = UDim2.new(1, -80, 0, 22),
            Position = UDim2.new(0, 78, 0, 14),
            BackgroundTransparency = 1,
            Text = info.name or "Unknown",
            Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = C.TextMain,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5, Parent = card,
        })

        local scriptShort = matchEntry.filename:match("^(.+)%.lua$") or matchEntry.filename
        N("TextLabel", {
            Size = UDim2.new(1, -80, 0, 14),
            Position = UDim2.new(0, 78, 0, 38),
            BackgroundTransparency = 1,
            Text = "Script: " .. scriptShort,
            Font = Enum.Font.Code, TextSize = 10,
            TextColor3 = C.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5, Parent = card,
        })

        local badge = N("Frame", {
            Size = UDim2.new(0, 100, 0, 16),
            Position = UDim2.new(0, 78, 0, 56),
            BackgroundColor3 = Color3.fromRGB(14, 50, 34),
            BorderSizePixel = 0, ZIndex = 5, Parent = card,
        })
        Cor(badge, 4)
        N("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "Script Available",
            Font = Enum.Font.GothamSemibold, TextSize = 9,
            TextColor3 = C.Green,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 6, Parent = badge,
        })

        -- Execute button
        local execBtn = N("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = C.Accent,
            BorderSizePixel = 0,
            Text = "Execute for " .. (info.name or "this game"),
            Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = Color3.fromRGB(10, 10, 12),
            AutoButtonColor = false,
            LayoutOrder = 2,
            ZIndex = 4, Parent = cpInner,
        })
        Cor(execBtn, 7)
        WireLoad(execBtn, matchEntry.filename, info.name or matchEntry.filename)

        execBtn.MouseEnter:Connect(function()
            Tw(execBtn, {BackgroundColor3 = C.AccentDim}, 0.1)
        end)
        execBtn.MouseLeave:Connect(function()
            Tw(execBtn, {BackgroundColor3 = C.Accent}, 0.1)
        end)

    else
        -- No script for current game
        local noCard = N("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = C.BgCard,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            ZIndex = 4,
            Parent = cpInner,
        })
        Cor(noCard, 7)
        Stroke(noCard, C.White, 1, 0.96)

        N("TextLabel", {
            Size = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 8, 0, 10),
            BackgroundTransparency = 1,
            Text = "No script for this game.",
            Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = C.TextMain,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 5, Parent = noCard,
        })
        N("TextLabel", {
            Size = UDim2.new(1, -16, 0, 14),
            Position = UDim2.new(0, 8, 0, 34),
            BackgroundTransparency = 1,
            Text = "Place ID: " .. tostring(currentPlaceId),
            Font = Enum.Font.Code, TextSize = 10,
            TextColor3 = C.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 5, Parent = noCard,
        })

        local noBadge = N("Frame", {
            Size = UDim2.new(0, 120, 0, 16),
            Position = UDim2.new(0.5, -60, 0, 56),
            BackgroundColor3 = Color3.fromRGB(50, 18, 18),
            BorderSizePixel = 0, ZIndex = 5, Parent = noCard,
        })
        Cor(noBadge, 4)
        N("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "No Script Available",
            Font = Enum.Font.GothamSemibold, TextSize = 9,
            TextColor3 = C.Red, TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 6, Parent = noBadge,
        })

        N("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = "Browse the Games tab for available scripts.",
            Font = Enum.Font.Gotham, TextSize = 10,
            TextColor3 = C.TextDis,
            TextXAlignment = Enum.TextXAlignment.Center,
            LayoutOrder = 2, ZIndex = 4, Parent = cpInner,
        })
    end
end

------------------------------------------------------------------------
-- SHOW HOME IMMEDIATELY, START FETCH
------------------------------------------------------------------------
ShowPage("home", true)

-- Pop-in animation
Tw(win, {
    Size     = UDim2.new(0, W, 0, H),
    Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
    BackgroundTransparency = 0.08,
}, 0.3, "Back", "Out")

task.spawn(function()
    statusLbl.Text = "Connecting to repository..."

    local raw = HttpGet(API_URL)
    if not raw or raw == "" then
        statusLbl.Text = "Failed to reach repository."
        Toast("Cannot reach GitHub API.", C.Red, 5)
        return
    end

    local ok, list = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(list) ~= "table" then
        statusLbl.Text = "Bad API response."
        Toast("Invalid API response.", C.Red, 5)
        return
    end

    local filenames = {}
    for _, item in ipairs(list) do
        if type(item) == "table" and type(item.name) == "string" then
            if item.name:match("%.lua$") then
                table.insert(filenames, item.name)
            end
        end
    end

    if #filenames == 0 then
        statusLbl.Text = "No scripts found in /Scripts."
        return
    end

    local gameScripts, universalScripts = {}, {}
    local currentPlaceId = game.PlaceId

    for i, fn in ipairs(filenames) do
        statusLbl.Text = string.format("Resolving %d / %d...", i, #filenames)
        local parsed = ParseFilename(fn)
        if parsed.isGame then
            local info = GetGameInfo(parsed.placeId) or {
                name = "Game " .. tostring(parsed.placeId),
                icon = "", placeId = parsed.placeId,
            }
            table.insert(gameScripts, {filename = fn, info = info})
        else
            table.insert(universalScripts, {filename = fn, name = parsed.name})
        end
        task.wait()
    end

    statusLbl.Text = "Ready."
    Populate(gameScripts, universalScripts, currentPlaceId)

    Toast(
        string.format("Ready  %d game  %d universal", #gameScripts, #universalScripts),
        C.Accent, 3
    )
end)
