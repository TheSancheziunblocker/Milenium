-- LoaderUI.lua
-- Fetches scripts from GitHub repo "Scripts" folder, resolves Roblox game info,
-- and presents a loader with Games, Current Game, and Universal tabs.

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer      = Players.LocalPlayer

------------------------------------------------------------------------
-- CONFIG - Edit these to point at your repo
------------------------------------------------------------------------
local GITHUB_USER   = "TheSancheziunblocker"
local GITHUB_REPO   = "Milenium"
local GITHUB_BRANCH = "main"
-- API endpoint to list folder contents
local API_URL       = string.format(
    "https://api.github.com/repos/%s/%s/contents/Scripts?ref=%s",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)
-- Raw base for actually loading scripts
local RAW_BASE      = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/Scripts/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

------------------------------------------------------------------------
-- THEME (matches hub style)
------------------------------------------------------------------------
local C = {
    BgMain      = Color3.fromRGB(12,  13,  17),
    BgWindow    = Color3.fromRGB(17,  19,  23),
    BgCard      = Color3.fromRGB(21,  24,  29),
    BgInput     = Color3.fromRGB(26,  29,  36),
    Accent      = Color3.fromRGB(29,  191, 158),
    AccentDim   = Color3.fromRGB(19,  128, 106),
    BtnBg       = Color3.fromRGB(38,  42,  52),
    BtnBgHover  = Color3.fromRGB(50,  55,  68),
    BtnBgDown   = Color3.fromRGB(28,  32,  42),
    TextMain    = Color3.fromRGB(209, 213, 219),
    TextMuted   = Color3.fromRGB(107, 114, 128),
    TextDis     = Color3.fromRGB(46,  50,  59),
    White       = Color3.fromRGB(255, 255, 255),
    BgHeader    = Color3.fromRGB(10,  11,  15),
    BgSidebar   = Color3.fromRGB(8,   9,   11),
    Red         = Color3.fromRGB(220, 60,  60),
    Green       = Color3.fromRGB(29,  191, 100),
}

------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
local function Tw(o, props, t, style, dir)
    local tw = TweenService:Create(o,
        TweenInfo.new(t or 0.15,
            Enum.EasingStyle[style  or "Quad"],
            Enum.EasingDirection[dir or "Out"]),
        props)
    tw:Play()
    return tw
end

local function N(cls, p)
    local o = Instance.new(cls)
    for k, v in pairs(p) do
        if k ~= "Parent" then o[k] = v end
    end
    if p.Parent then o.Parent = p.Parent end
    return o
end

local function Cor(p, r)
    N("UICorner", {CornerRadius = UDim.new(0, r or 4), Parent = p})
end

local function Stroke(p, col, th, tr)
    N("UIStroke", {
        Color        = col or C.White,
        Thickness    = th  or 1,
        Transparency = tr  or 0.92,
        Parent       = p,
    })
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

local function VList(p, gap)
    N("UIListLayout", {
        Padding             = UDim.new(0, gap or 0),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent              = p,
    })
end

local function HList(p, gap, ha, va)
    N("UIListLayout", {
        Padding             = UDim.new(0, gap or 0),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va or Enum.VerticalAlignment.Center,
        Parent              = p,
    })
end

local function Grid(p, cellSize, cellPad)
    N("UIGridLayout", {
        CellSize            = cellSize  or UDim2.new(0, 120, 0, 140),
        CellPaddingSize     = cellPad   or UDim2.new(0, 10,  0, 10),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
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
            frame.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then on = false end
    end)
end

------------------------------------------------------------------------
-- GAME INFO FETCHER
-- Given a numeric place/universe ID, returns {name, iconUrl}
-- Returns nil if the ID is invalid or the fetch fails.
------------------------------------------------------------------------
local gameInfoCache = {}

local function GetGameInfo(placeId)
    if gameInfoCache[placeId] then return gameInfoCache[placeId] end

    -- Convert place ID → universe ID
    local uniOk, uniData = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet(
                "https://apis.roblox.com/universes/v1/places/" .. placeId .. "/universe"
            )
        )
    end)

    if not uniOk or not uniData or not uniData.universeId then return nil end
    local universeId = uniData.universeId

    -- Fetch game details
    local detOk, detData = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet(
                "https://games.roblox.com/v1/games?universeIds=" .. universeId
            )
        )
    end)

    if not detOk or not detData or not detData.data or not detData.data[1] then return nil end
    local det  = detData.data[1]
    local name = det.name or ("Game " .. placeId)

    -- Fetch icon
    local iconUrl = ""
    local icOk, icData = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet(
                "https://thumbnails.roblox.com/v1/games/icons?universeIds=" ..
                universeId ..
                "&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false"
            )
        )
    end)
    if icOk and icData and icData.data and icData.data[1] then
        iconUrl = icData.data[1].imageUrl or ""
    end

    local info = {name = name, icon = iconUrl, placeId = placeId}
    gameInfoCache[placeId] = info
    return info
end

------------------------------------------------------------------------
-- PARSE SCRIPT FILENAME
-- Rules:
--   "12345678.lua"          → placeId = 12345678  (game script)
--   "12345678_something.lua"→ placeId = 12345678  (game script)
--   "something.lua"         → placeId = nil        (universal)
------------------------------------------------------------------------
local function ParseFilename(filename)
    -- strip .lua
    local base = filename:match("^(.+)%.lua$") or filename

    -- try leading numeric segment
    local id = base:match("^(%d+)")
    if id then
        return {
            isGame  = true,
            placeId = tonumber(id),
            raw     = filename,
        }
    end

    return {
        isGame  = false,
        placeId = nil,
        name    = base,
        raw     = filename,
    }
end

------------------------------------------------------------------------
-- LOAD SCRIPT FROM RAW URL
------------------------------------------------------------------------
local function LoadScript(filename)
    local url = RAW_BASE .. filename
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if not ok or not src or src == "" then
        warn("[Loader] Failed to fetch:", url)
        return
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[Loader] Syntax error in", filename, ":", err)
        return
    end
    task.spawn(fn)
end

------------------------------------------------------------------------
-- SCREEN GUI (separate from hub)
------------------------------------------------------------------------
local SG
do
    local ok = pcall(function()
        SG = N("ScreenGui", {
            Name           = "LoaderUI",
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            Parent         = CoreGui,
        })
    end)
    if not ok then
        SG = N("ScreenGui", {
            Name           = "LoaderUI",
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            Parent         = LocalPlayer:WaitForChild("PlayerGui"),
        })
    end
end

------------------------------------------------------------------------
-- WINDOW DIMENSIONS
------------------------------------------------------------------------
local LW, LH   = 620, 440
local LHEAD    = 38
local LCORNER  = 6
local TAB_H    = 34

------------------------------------------------------------------------
-- ROOT WINDOW
------------------------------------------------------------------------
local loaderWin = N("Frame", {
    Name                   = "LoaderWin",
    Size                   = UDim2.new(0, LW, 0, LH),
    Position               = UDim2.new(0.5, -LW / 2, 0.5, -LH / 2),
    BackgroundColor3       = C.BgWindow,
    BackgroundTransparency = 0.45,
    BorderSizePixel        = 0,
    ClipsDescendants       = true,
    Parent                 = SG,
})
Cor(loaderWin, LCORNER)
N("UIStroke", {
    Color        = Color3.fromRGB(40, 44, 54),
    Thickness    = 1,
    Transparency = 0.15,
    Parent       = loaderWin,
})

------------------------------------------------------------------------
-- HEADER
------------------------------------------------------------------------
local hdrOuter = N("Frame", {
    Size             = UDim2.new(1, 0, 0, LHEAD),
    BackgroundColor3 = C.BgHeader,
    BorderSizePixel  = 0,
    ZIndex           = 5,
    Parent           = loaderWin,
})
Cor(hdrOuter, LCORNER)
-- Cover bottom corners so only top corners are rounded
N("Frame", {
    Size             = UDim2.new(1, 0, 0, LCORNER),
    Position         = UDim2.new(0, 0, 1, -LCORNER),
    BackgroundColor3 = C.BgHeader,
    BorderSizePixel  = 0,
    ZIndex           = 6,
    Parent           = hdrOuter,
})
-- Thin divider line at bottom of header
N("Frame", {
    Size                   = UDim2.new(1, 0, 0, 1),
    Position               = UDim2.new(0, 0, 1, -1),
    BackgroundColor3       = C.White,
    BackgroundTransparency = 0.91,
    BorderSizePixel        = 0,
    ZIndex                 = 7,
    Parent                 = hdrOuter,
})

local hdrContent = N("Frame", {
    Size                   = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex                 = 7,
    Parent                 = hdrOuter,
})

-- Logo / title area
local loaderTitleF = N("Frame", {
    Size                   = UDim2.new(0, 160, 1, 0),
    Position               = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex                 = 7,
    Parent                 = hdrContent,
})
HList(loaderTitleF, 7, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
Pad(loaderTitleF, 0, 0, 12, 0)

-- Small accent dot / logo
local logoDot = N("Frame", {
    Size             = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = C.Accent,
    BorderSizePixel  = 0,
    LayoutOrder      = 1,
    ZIndex           = 8,
    Parent           = loaderTitleF,
})
Cor(logoDot, 4)

N("TextLabel", {
    Size                   = UDim2.new(0, 130, 1, 0),
    BackgroundTransparency = 1,
    Text                   = "Script Loader",
    Font                   = Enum.Font.GothamBold,
    TextSize               = 13,
    TextColor3             = C.Accent,
    TextXAlignment         = Enum.TextXAlignment.Left,
    LayoutOrder            = 2,
    ZIndex                 = 8,
    Parent                 = loaderTitleF,
})

-- Close button
local closeBtn = N("TextButton", {
    Size             = UDim2.new(0, 24, 0, 24),
    Position         = UDim2.new(1, -32, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(55, 30, 30),
    BorderSizePixel  = 0,
    Text             = "✕",
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    TextColor3       = Color3.fromRGB(220, 80, 80),
    AutoButtonColor  = false,
    ZIndex           = 8,
    Parent           = hdrContent,
})
Cor(closeBtn, 4)
closeBtn.MouseEnter:Connect(function()
    Tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(80, 30, 30)}, 0.1)
end)
closeBtn.MouseLeave:Connect(function()
    Tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(55, 30, 30)}, 0.1)
end)
closeBtn.MouseButton1Click:Connect(function()
    Tw(loaderWin, {BackgroundTransparency = 1}, 0.2)
    task.delay(0.25, function() loaderWin:Destroy() end)
end)

Draggable(loaderWin, hdrContent)

------------------------------------------------------------------------
-- BODY
------------------------------------------------------------------------
local bodyFrame = N("Frame", {
    Size                   = UDim2.new(1, 0, 1, -LHEAD),
    Position               = UDim2.new(0, 0, 0, LHEAD),
    BackgroundTransparency = 1,
    ClipsDescendants       = false,
    Parent                 = loaderWin,
})

------------------------------------------------------------------------
-- TAB BAR  (Games | Current Game | Universal)
------------------------------------------------------------------------
local tabBar = N("Frame", {
    Size             = UDim2.new(1, 0, 0, TAB_H),
    BackgroundColor3 = C.BgHeader,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = bodyFrame,
})
-- Thin bottom border on tab bar
N("Frame", {
    Size                   = UDim2.new(1, 0, 0, 1),
    Position               = UDim2.new(0, 0, 1, -1),
    BackgroundColor3       = C.White,
    BackgroundTransparency = 0.93,
    BorderSizePixel        = 0,
    ZIndex                 = 5,
    Parent                 = tabBar,
})

local tabList = N("Frame", {
    Size                   = UDim2.new(1, -16, 1, 0),
    Position               = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    ZIndex                 = 5,
    Parent                 = tabBar,
})
HList(tabList, 4, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

-- Content area below tab bar
local contentArea = N("Frame", {
    Size                   = UDim2.new(1, 0, 1, -TAB_H),
    Position               = UDim2.new(0, 0, 0, TAB_H),
    BackgroundTransparency = 1,
    ClipsDescendants       = true,
    Parent                 = bodyFrame,
})

------------------------------------------------------------------------
-- TAB BUTTON FACTORY
------------------------------------------------------------------------
local tabButtons  = {}
local tabPanels   = {}
local activeTab   = nil

local function MakeTab(label, order)
    local btn = N("TextButton", {
        Size             = UDim2.new(0, 0, 0, TAB_H - 6),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = C.BgInput,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "",
        AutoButtonColor  = false,
        LayoutOrder      = order,
        ZIndex           = 6,
        Parent           = tabList,
    })
    Pad(btn, 0, 0, 10, 10)
    Cor(btn, 4)

    local lbl = N("TextLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = label,
        Font                   = Enum.Font.GothamSemibold,
        TextSize               = 11,
        TextColor3             = C.TextMuted,
        AutomaticSize          = Enum.AutomaticSize.X,
        ZIndex                 = 7,
        Parent                 = btn,
    })

    local underline = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = btn,
    })
    Cor(underline, 1)

    local panel = N("ScrollingFrame", {
        Name                   = "Panel_" .. label,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = C.BgInput,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Visible                = false,
        ZIndex                 = 3,
        Parent                 = contentArea,
    })

    local entry = {
        btn       = btn,
        lbl       = lbl,
        underline = underline,
        panel     = panel,
        label     = label,
    }
    table.insert(tabButtons, entry)
    table.insert(tabPanels, panel)

    local function activate()
        if activeTab then
            Tw(activeTab.lbl,       {TextColor3             = C.TextMuted}, 0.12)
            Tw(activeTab.underline, {BackgroundTransparency = 1},           0.12)
            Tw(activeTab.btn,       {BackgroundTransparency = 1},           0.12)
            activeTab.panel.Visible = false
        end
        activeTab = entry
        Tw(lbl,       {TextColor3             = C.Accent}, 0.12)
        Tw(underline, {BackgroundTransparency = 0},        0.12)
        Tw(btn,       {BackgroundTransparency = 0.88},     0.12)
        panel.Visible = true
    end

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if activeTab ~= entry then
            Tw(lbl, {TextColor3 = Color3.fromRGB(160, 166, 176)}, 0.1)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= entry then
            Tw(lbl, {TextColor3 = C.TextMuted}, 0.1)
        end
    end)

    entry.activate = activate
    return entry
end

local tabGames   = MakeTab("🎮  Games",        1)
local tabCurrent = MakeTab("⚡  Current Game",  2)
local tabUni     = MakeTab("🌐  Universal",     3)

------------------------------------------------------------------------
-- SEARCH BAR FACTORY (used in Games + Universal panels)
------------------------------------------------------------------------
local function MakeSearchBar(parent)
    local wrap = N("Frame", {
        Size             = UDim2.new(1, -20, 0, 28),
        Position         = UDim2.new(0, 10, 0, 8),
        BackgroundColor3 = C.BgInput,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = parent,
    })
    Cor(wrap, 6)
    Stroke(wrap, C.White, 1, 0.94)

    -- Magnifier icon label
    N("TextLabel", {
        Size                   = UDim2.new(0, 20, 1, 0),
        Position               = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text                   = "🔍",
        TextSize               = 11,
        Font                   = Enum.Font.Gotham,
        TextColor3             = C.TextMuted,
        ZIndex                 = 6,
        Parent                 = wrap,
    })

    local box = N("TextBox", {
        Size                   = UDim2.new(1, -32, 1, 0),
        Position               = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText        = "Search games...",
        PlaceholderColor3      = C.TextDis,
        Text                   = "",
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextColor3             = C.TextMain,
        ClearTextOnFocus       = false,
        ZIndex                 = 6,
        Parent                 = wrap,
    })

    return box, wrap
end

------------------------------------------------------------------------
-- STATUS / LOADING OVERLAY
------------------------------------------------------------------------
local statusOverlay = N("Frame", {
    Size                   = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex                 = 20,
    Parent                 = contentArea,
})

local statusLbl = N("TextLabel", {
    Size                   = UDim2.new(1, 0, 0, 20),
    Position               = UDim2.new(0, 0, 0.5, -10),
    BackgroundTransparency = 1,
    Text                   = "Fetching scripts...",
    Font                   = Enum.Font.GothamSemibold,
    TextSize               = 13,
    TextColor3             = C.TextMuted,
    TextXAlignment         = Enum.TextXAlignment.Center,
    ZIndex                 = 21,
    Parent                 = statusOverlay,
})

-- Animated dot strip
local dotRow = N("Frame", {
    Size                   = UDim2.new(0, 60, 0, 8),
    Position               = UDim2.new(0.5, -30, 0.5, 14),
    BackgroundTransparency = 1,
    ZIndex                 = 21,
    Parent                 = statusOverlay,
})
HList(dotRow, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

local dotFrames = {}
for i = 1, 3 do
    local d = N("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel  = 0,
        LayoutOrder      = i,
        ZIndex           = 22,
        Parent           = dotRow,
    })
    Cor(d, 3)
    table.insert(dotFrames, d)
end

-- Pulse the dots
task.spawn(function()
    local t = 0
    while statusOverlay and statusOverlay.Parent do
        t = t + task.wait(0.08)
        for i, d in ipairs(dotFrames) do
            local phase = math.sin(t * 4 + (i - 1) * 1.2)
            local tr    = 0.3 + 0.5 * (1 - (phase + 1) / 2)
            if d and d.Parent then
                d.BackgroundTransparency = tr
            end
        end
    end
end)

local function HideStatus()
    statusOverlay.Visible = false
end

local function ShowStatus(msg)
    statusOverlay.Visible = true
    statusLbl.Text        = msg or "Loading..."
end

------------------------------------------------------------------------
-- NOTIFICATION TOAST
------------------------------------------------------------------------
local function Toast(msg, color, duration)
    color    = color    or C.Accent
    duration = duration or 2.5

    local toast = N("Frame", {
        Size             = UDim2.new(0, 280, 0, 36),
        Position         = UDim2.new(0.5, -140, 1, 10),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel  = 0,
        ZIndex           = 50,
        Parent           = SG,
    })
    Cor(toast, 6)
    N("UIStroke", {Color = color, Thickness = 1, Transparency = 0.4, Parent = toast})

    -- Accent strip on left
    local strip = N("Frame", {
        Size             = UDim2.new(0, 3, 1, -12),
        Position         = UDim2.new(0, 8, 0, 6),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = 51,
        Parent           = toast,
    })
    Cor(strip, 2)

    N("TextLabel", {
        Size                   = UDim2.new(1, -26, 1, 0),
        Position               = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text                   = msg,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextColor3             = C.TextMain,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 51,
        Parent                 = toast,
    })

    -- Slide in
    Tw(toast, {Position = UDim2.new(0.5, -140, 1, -46)}, 0.25, "Back", "Out")
    task.delay(duration, function()
        if toast and toast.Parent then
            Tw(toast, {Position = UDim2.new(0.5, -140, 1, 10)}, 0.2, "Quad", "In")
            task.delay(0.25, function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end
    end)
end

------------------------------------------------------------------------
-- GAME CARD BUILDER  (icon + name + Load button)
------------------------------------------------------------------------
local CARD_W = 130
local CARD_H = 155

local function MakeGameCard(parent, info, filename, order)
    local card = N("Frame", {
        Size             = UDim2.new(0, CARD_W, 0, CARD_H),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel  = 0,
        LayoutOrder      = order,
        ZIndex           = 5,
        Parent           = parent,
    })
    Cor(card, 6)
    Stroke(card, C.White, 1, 0.96)

    -- Icon
    local iconBg = N("Frame", {
        Size             = UDim2.new(1, -16, 0, 80),
        Position         = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Color3.fromRGB(8, 10, 13),
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = card,
    })
    Cor(iconBg, 5)

    local iconImg = N("ImageLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image                  = info.icon or "",
        ScaleType              = Enum.ScaleType.Crop,
        ZIndex                 = 7,
        Parent                 = iconBg,
    })
    Cor(iconImg, 5)

    -- Placeholder spinner while icon loads (just a dim label)
    if info.icon == "" then
        N("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "🎮",
            TextSize               = 28,
            Font                   = Enum.Font.Gotham,
            TextColor3             = C.TextDis,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 7,
            Parent                 = iconBg,
        })
    end

    -- Name label
    N("TextLabel", {
        Size                   = UDim2.new(1, -12, 0, 32),
        Position               = UDim2.new(0, 6, 0, 94),
        BackgroundTransparency = 1,
        Text                   = info.name or "Unknown",
        Font                   = Enum.Font.GothamSemibold,
        TextSize               = 10,
        TextColor3             = C.TextMain,
        TextXAlignment         = Enum.TextXAlignment.Center,
        TextWrapped            = true,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 6,
        Parent                 = card,
    })

    -- Load button
    local loadBtn = N("TextButton", {
        Size             = UDim2.new(1, -16, 0, 22),
        Position         = UDim2.new(0, 8, 1, -30),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Text             = "Load",
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = Color3.fromRGB(10, 10, 10),
        AutoButtonColor  = false,
        ZIndex           = 7,
        Parent           = card,
    })
    Cor(loadBtn, 4)

    loadBtn.MouseEnter:Connect(function()
        Tw(loadBtn, {BackgroundColor3 = C.AccentDim}, 0.1)
    end)
    loadBtn.MouseLeave:Connect(function()
        Tw(loadBtn, {BackgroundColor3 = C.Accent}, 0.1)
    end)
    loadBtn.MouseButton1Click:Connect(function()
        loadBtn.Text = "Loading..."
        Tw(loadBtn, {BackgroundColor3 = C.BtnBg}, 0.1)
        task.spawn(function()
            LoadScript(filename)
            Toast("✓  Loaded: " .. (info.name or filename), C.Green)
            task.wait(0.5)
            if loadBtn and loadBtn.Parent then
                loadBtn.Text = "Load"
                Tw(loadBtn, {BackgroundColor3 = C.Accent}, 0.1)
            end
        end)
    end)

    return card
end

------------------------------------------------------------------------
-- UNIVERSAL ROW BUILDER  (name + Load button, no icon)
------------------------------------------------------------------------
local function MakeUniversalRow(parent, name, filename, order)
    local row = N("Frame", {
        Size             = UDim2.new(1, -20, 0, 40),
        BackgroundColor3 = C.BgCard,
        BorderSizePixel  = 0,
        LayoutOrder      = order,
        ZIndex           = 5,
        Parent           = parent,
    })
    Cor(row, 5)
    Stroke(row, C.White, 1, 0.96)

    -- Small accent dot
    local dot = N("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 10, 0.5, -3),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = row,
    })
    Cor(dot, 3)

    N("TextLabel", {
        Size                   = UDim2.new(1, -100, 1, 0),
        Position               = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text                   = name,
        Font                   = Enum.Font.GothamSemibold,
        TextSize               = 11,
        TextColor3             = C.TextMain,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 6,
        Parent                 = row,
    })

    local loadBtn = N("TextButton", {
        Size             = UDim2.new(0, 64, 0, 24),
        Position         = UDim2.new(1, -74, 0.5, -12),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Text             = "Load",
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = Color3.fromRGB(10, 10, 10),
        AutoButtonColor  = false,
        ZIndex           = 7,
        Parent           = row,
    })
    Cor(loadBtn, 4)

    loadBtn.MouseEnter:Connect(function()
        Tw(loadBtn, {BackgroundColor3 = C.AccentDim}, 0.1)
    end)
    loadBtn.MouseLeave:Connect(function()
        Tw(loadBtn, {BackgroundColor3 = C.Accent}, 0.1)
    end)
    loadBtn.MouseButton1Click:Connect(function()
        loadBtn.Text = "Loading..."
        Tw(loadBtn, {BackgroundColor3 = C.BtnBg}, 0.1)
        task.spawn(function()
            LoadScript(filename)
            Toast("✓  Loaded: " .. name, C.Green)
            task.wait(0.5)
            if loadBtn and loadBtn.Parent then
                loadBtn.Text = "Load"
                Tw(loadBtn, {BackgroundColor3 = C.Accent}, 0.1)
            end
        end)
    end)

    return row
end

------------------------------------------------------------------------
-- POPULATE TABS
-- Run after fetching and resolving all script info.
------------------------------------------------------------------------
local function PopulateTabs(gameScripts, universalScripts, currentPlaceId)

    ----------------------------------------------------------------
    -- GAMES TAB
    ----------------------------------------------------------------
    local gPanel = tabGames.panel
    Pad(gPanel, 8, 8, 10, 10)

    local searchBox, _ = MakeSearchBar(gPanel)

    -- Grid container
    local gridWrap = N("Frame", {
        Size                   = UDim2.new(1, -20, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Position               = UDim2.new(0, 10, 0, 46),
        BackgroundTransparency = 1,
        ZIndex                 = 4,
        Parent                 = gPanel,
    })
    Grid(gridWrap, UDim2.new(0, CARD_W, 0, CARD_H), UDim2.new(0, 10, 0, 10))
    Pad(gridWrap, 0, 10, 0, 0)

    -- Keep a map of card → game name for filtering
    local gameCards = {}

    local function RebuildGameGrid(filter)
        -- Clear existing children except layout/padding
        for _, ch in ipairs(gridWrap:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        local n = 0
        for _, entry in ipairs(gameScripts) do
            local show = filter == "" or
                entry.info.name:lower():find(filter:lower(), 1, true)
            if show then
                n = n + 1
                MakeGameCard(gridWrap, entry.info, entry.filename, n)
            end
        end
        if n == 0 then
            N("TextLabel", {
                Size                   = UDim2.new(0, 300, 0, 40),
                BackgroundTransparency = 1,
                Text                   = "No scripts found.",
                Font                   = Enum.Font.Gotham,
                TextSize               = 11,
                TextColor3             = C.TextDis,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = 1,
                ZIndex                 = 5,
                Parent                 = gridWrap,
            })
        end
    end

    RebuildGameGrid("")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RebuildGameGrid(searchBox.Text)
    end)

    ----------------------------------------------------------------
    -- CURRENT GAME TAB
    ----------------------------------------------------------------
    local cPanel = tabCurrent.panel
    Pad(cPanel, 16, 16, 16, 16)

    -- Find if there's a script for current place
    local matchEntry = nil
    for _, entry in ipairs(gameScripts) do
        if tostring(entry.info.placeId) == tostring(currentPlaceId) then
            matchEntry = entry
            break
        end
    end

    if matchEntry then
        -- Show current game info + big load button
        local info = matchEntry.info

        local cHeader = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 110),
            BackgroundColor3 = C.BgCard,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            Parent           = cPanel,
        })
        Cor(cHeader, 8)
        Stroke(cHeader, C.White, 1, 0.95)

        local iconBg = N("Frame", {
            Size             = UDim2.new(0, 90, 0, 90),
            Position         = UDim2.new(0, 10, 0.5, -45),
            BackgroundColor3 = Color3.fromRGB(8, 10, 13),
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = cHeader,
        })
        Cor(iconBg, 6)
        local iconImg = N("ImageLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image                  = info.icon or "",
            ScaleType              = Enum.ScaleType.Crop,
            ZIndex                 = 7,
            Parent                 = iconBg,
        })
        Cor(iconImg, 6)

        N("TextLabel", {
            Size                   = UDim2.new(1, -120, 0, 24),
            Position               = UDim2.new(0, 110, 0, 18),
            BackgroundTransparency = 1,
            Text                   = info.name or "Unknown",
            Font                   = Enum.Font.GothamBold,
            TextSize               = 14,
            TextColor3             = C.TextMain,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 6,
            Parent                 = cHeader,
        })
        N("TextLabel", {
            Size                   = UDim2.new(1, -120, 0, 16),
            Position               = UDim2.new(0, 110, 0, 44),
            BackgroundTransparency = 1,
            Text                   = "Place ID: " .. tostring(currentPlaceId),
            Font                   = Enum.Font.Code,
            TextSize               = 10,
            TextColor3             = C.TextMuted,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 6,
            Parent                 = cHeader,
        })

        -- Green "script available" badge
        local badge = N("Frame", {
            Size             = UDim2.new(0, 110, 0, 18),
            Position         = UDim2.new(0, 110, 0, 66),
            BackgroundColor3 = Color3.fromRGB(15, 55, 35),
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = cHeader,
        })
        Cor(badge, 4)
        N("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "✓  Script Available",
            Font                   = Enum.Font.GothamSemibold,
            TextSize               = 10,
            TextColor3             = C.Green,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 7,
            Parent                 = badge,
        })

        -- Big load button below header
        local bigLoad = N("TextButton", {
            Size             = UDim2.new(1, 0, 0, 38),
            Position         = UDim2.new(0, 0, 0, 118),
            BackgroundColor3 = C.Accent,
            BorderSizePixel  = 0,
            Text             = "⚡  Execute Script for " .. (info.name or "this game"),
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            TextColor3       = Color3.fromRGB(8, 10, 12),
            AutoButtonColor  = false,
            ZIndex           = 6,
            Parent           = cPanel,
        })
        Cor(bigLoad, 6)

        bigLoad.MouseEnter:Connect(function()
            Tw(bigLoad, {BackgroundColor3 = C.AccentDim}, 0.1)
        end)
        bigLoad.MouseLeave:Connect(function()
            Tw(bigLoad, {BackgroundColor3 = C.Accent}, 0.1)
        end)
        bigLoad.MouseButton1Click:Connect(function()
            bigLoad.Text = "Loading..."
            task.spawn(function()
                LoadScript(matchEntry.filename)
                Toast("✓  Script executed!", C.Green)
                task.wait(0.5)
                if bigLoad and bigLoad.Parent then
                    bigLoad.Text = "⚡  Execute Script for " .. (info.name or "this game")
                end
            end)
        end)

    else
        -- No script for current game
        local noScriptF = N("Frame", {
            Size                   = UDim2.new(1, 0, 0, 120),
            BackgroundColor3       = C.BgCard,
            BorderSizePixel        = 0,
            ZIndex                 = 5,
            Parent                 = cPanel,
        })
        Cor(noScriptF, 8)
        Stroke(noScriptF, C.White, 1, 0.96)

        N("TextLabel", {
            Size                   = UDim2.new(1, -20, 0, 30),
            Position               = UDim2.new(0, 10, 0, 18),
            BackgroundTransparency = 1,
            Text                   = "No script found for this game.",
            Font                   = Enum.Font.GothamBold,
            TextSize               = 13,
            TextColor3             = C.TextMain,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 6,
            Parent                 = noScriptF,
        })
        N("TextLabel", {
            Size                   = UDim2.new(1, -20, 0, 22),
            Position               = UDim2.new(0, 10, 0, 50),
            BackgroundTransparency = 1,
            Text                   = "Place ID: " .. tostring(currentPlaceId),
            Font                   = Enum.Font.Code,
            TextSize               = 10,
            TextColor3             = C.TextMuted,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 6,
            Parent                 = noScriptF,
        })

        -- Dim badge
        local badge = N("Frame", {
            Size             = UDim2.new(0, 130, 0, 18),
            Position         = UDim2.new(0.5, -65, 0, 80),
            BackgroundColor3 = Color3.fromRGB(50, 20, 20),
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = noScriptF,
        })
        Cor(badge, 4)
        N("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "✕  No Script Available",
            Font                   = Enum.Font.GothamSemibold,
            TextSize               = 10,
            TextColor3             = C.Red,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 7,
            Parent                 = badge,
        })

        -- Suggest checking Games tab
        N("TextLabel", {
            Size                   = UDim2.new(1, -20, 0, 18),
            Position               = UDim2.new(0, 10, 0, 130),
            BackgroundTransparency = 1,
            Text                   = "Browse the Games tab for available scripts.",
            Font                   = Enum.Font.Gotham,
            TextSize               = 10,
            TextColor3             = C.TextDis,
            TextXAlignment         = Enum.TextXAlignment.Center,
            ZIndex                 = 5,
            Parent                 = cPanel,
        })
    end

    ----------------------------------------------------------------
    -- UNIVERSAL TAB
    ----------------------------------------------------------------
    local uPanel = tabUni.panel
    Pad(uPanel, 8, 8, 10, 10)

    local uSearchBox, _ = MakeSearchBar(uPanel)
    uSearchBox.PlaceholderText = "Search universal scripts..."

    local uListWrap = N("Frame", {
        Size                   = UDim2.new(1, -20, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Position               = UDim2.new(0, 10, 0, 46),
        BackgroundTransparency = 1,
        ZIndex                 = 4,
        Parent                 = uPanel,
    })
    VList(uListWrap, 6)

    local function RebuildUniversalList(filter)
        for _, ch in ipairs(uListWrap:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        local n = 0
        for _, entry in ipairs(universalScripts) do
            local show = filter == "" or
                entry.name:lower():find(filter:lower(), 1, true)
            if show then
                n = n + 1
                MakeUniversalRow(uListWrap, entry.name, entry.filename, n)
            end
        end
        if n == 0 then
            N("TextLabel", {
                Size                   = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text                   = "No universal scripts found.",
                Font                   = Enum.Font.Gotham,
                TextSize               = 11,
                TextColor3             = C.TextDis,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = 1,
                ZIndex                 = 5,
                Parent                 = uListWrap,
            })
        end
    end

    RebuildUniversalList("")
    uSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RebuildUniversalList(uSearchBox.Text)
    end)

    ----------------------------------------------------------------
    -- Activate the first sensible tab
    ----------------------------------------------------------------
    if matchEntry then
        tabCurrent.activate()
    else
        tabGames.activate()
    end
end

------------------------------------------------------------------------
-- MAIN ASYNC LOADER LOGIC
------------------------------------------------------------------------
task.spawn(function()
    ShowStatus("Connecting to repository...")

    -- 1. Fetch file listing from GitHub API
    local listOk, listRaw = pcall(function()
        return game:HttpGet(API_URL)
    end)

    if not listOk or not listRaw then
        statusLbl.Text = "Failed to reach GitHub API."
        Toast("✕  Cannot reach repository.", C.Red, 4)
        return
    end

    local listData
    local parseOk = pcall(function()
        listData = HttpService:JSONDecode(listRaw)
    end)

    if not parseOk or type(listData) ~= "table" then
        statusLbl.Text = "Invalid API response."
        Toast("✕  Bad API response.", C.Red, 4)
        return
    end

    -- 2. Collect .lua filenames
    local filenames = {}
    for _, item in ipairs(listData) do
        if type(item) == "table" and item.name then
            local n = item.name
            if n:match("%.lua$") then
                table.insert(filenames, n)
            end
        end
    end

    if #filenames == 0 then
        statusLbl.Text = "No scripts found in /Scripts."
        return
    end

    ShowStatus(string.format("Resolving %d script(s)...", #filenames))

    -- 3. Parse filenames and resolve game info
    local gameScripts     = {}  -- { filename, info: {name, icon, placeId} }
    local universalScripts = {} -- { filename, name }

    local currentPlaceId = game.PlaceId

    for i, fn in ipairs(filenames) do
        statusLbl.Text = string.format("Resolving %d / %d...", i, #filenames)

        local parsed = ParseFilename(fn)

        if parsed.isGame then
            -- Try to get game info; fallback gracefully
            local info = GetGameInfo(parsed.placeId) or {
                name    = "Game " .. tostring(parsed.placeId),
                icon    = "",
                placeId = parsed.placeId,
            }
            table.insert(gameScripts, {filename = fn, info = info})
        else
            table.insert(universalScripts, {filename = fn, name = parsed.name})
        end

        task.wait() -- yield so the UI stays responsive
    end

    ShowStatus("Building UI...")
    task.wait()

    HideStatus()
    PopulateTabs(gameScripts, universalScripts, currentPlaceId)

    -- Animate the window in
    loaderWin.BackgroundTransparency = 1
    Tw(loaderWin, {BackgroundTransparency = 0.45}, 0.3, "Quad", "Out")

    Toast(
        string.format("✓  Loaded %d game + %d universal scripts",
            #gameScripts, #universalScripts),
        C.Accent,
        3
    )
end)

-- Initial window pop-in animation
loaderWin.Size     = UDim2.new(0, LW * 0.88, 0, LH * 0.88)
loaderWin.Position = UDim2.new(0.5, -(LW * 0.88) / 2, 0.5, -(LH * 0.88) / 2)
Tw(loaderWin, {
    Size     = UDim2.new(0, LW, 0, LH),
    Position = UDim2.new(0.5, -LW / 2, 0.5, -LH / 2),
}, 0.35, "Back", "Out")

-- Activate default tab immediately so the layout isn't empty
tabGames.activate()
