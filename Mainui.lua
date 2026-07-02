local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
-- THEME (moved up so everything can reference C)

local C = {
BgMain = Color3.fromRGB(12, 13, 17),
BgWindow = Color3.fromRGB(17, 19, 23),
BgSidebar = Color3.fromRGB(8, 9, 11),
BgCard = Color3.fromRGB(21, 24, 29),
BgInput = Color3.fromRGB(26, 29, 36),
Accent = Color3.fromRGB(29, 191, 158),
AccentDim = Color3.fromRGB(19, 128, 106),
BtnBg = Color3.fromRGB(38, 42, 52),
BtnBgHover = Color3.fromRGB(50, 55, 68),
BtnBgDown = Color3.fromRGB(28, 32, 42),
TextMain = Color3.fromRGB(209, 213, 219),
TextMuted = Color3.fromRGB(107, 114, 128),
TextDis = Color3.fromRGB(46, 50, 59),
White = Color3.fromRGB(255, 255, 255),
Black = Color3.fromRGB(0, 0, 0),
BgHeader = Color3.fromRGB(10, 11, 15),
}

local WIN_TRANS = 0.6
local MAIN_TRANS = 0.6
local SIDE_TRANS = 0.35
-- BLUR SYSTEM

local BLUR_SIZE = Vector2.new(10, 10)
local PART_SIZE = 0.01
local PART_TRANSPARENCY = 1 - 1e-7
local START_INTENSITY = 0.25

-- Remove old DepthOfFieldEffect if re-running
for _, v in ipairs(Lighting:GetChildren()) do
if v:IsA("DepthOfFieldEffect") and v.Name == "UILibDOF" then
v:Destroy()
end
end

local BLUR_OBJ = Instance.new("DepthOfFieldEffect")
BLUR_OBJ.Name = "UILibDOF"
BLUR_OBJ.FarIntensity = 0
BLUR_OBJ.NearIntensity = START_INTENSITY
BLUR_OBJ.FocusDistance = 0.25
BLUR_OBJ.InFocusRadius = 0
BLUR_OBJ.Parent = Lighting

local PartsList = {}
local BlursList = {}
local BlurObjects = {}
local BlurredGui = {}
BlurredGui.__index = BlurredGui

local function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDirection)
local n = planeNormal
local d = rayDirection
local v = rayOrigin - planePos
local num = n.xv.x + n.yv.y + n.zv.z
local den = n.xd.x + n.yd.y + n.zd.z
local a = -num / den
return rayOrigin + a * rayDirection, a
end

local function rebuildPartsList()
PartsList = {}
BlursList = {}
for blurObj, part in pairs(BlurObjects) do
table.insert(PartsList, part)
table.insert(BlursList, blurObj)
end
end

local function updateGui(blurObj)
if not blurObj.Frame.Visible then
blurObj.Part.Transparency = 1
return
end

text

local cam   = workspace.CurrentCamera
local frame = blurObj.Frame
local part  = blurObj.Part
local mesh  = blurObj.Mesh

local absSize = frame.AbsoluteSize
if absSize.X <= 1 or absSize.Y <= 1 then
    part.Transparency = 1
    return
end

part.Transparency = PART_TRANSPARENCY

local corner0 = frame.AbsolutePosition + BLUR_SIZE
local corner1 = corner0 + absSize - BLUR_SIZE * 2

local ray0 = cam:ScreenPointToRay(corner0.X, corner0.Y, 1)
local ray1 = cam:ScreenPointToRay(corner1.X, corner1.Y, 1)

local planeOrigin = cam.CFrame.Position + cam.CFrame.LookVector * (0.05 - cam.NearPlaneZ)
local planeNormal = cam.CFrame.LookVector
local pos0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
local pos1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

pos0 = cam.CFrame:PointToObjectSpace(pos0)
pos1 = cam.CFrame:PointToObjectSpace(pos1)

local size   = pos1 - pos0
local center = (pos0 + pos1) / 2

mesh.Offset = center
mesh.Scale  = size / PART_SIZE

end

function BlurredGui.updateAll()
BLUR_OBJ.NearIntensity = START_INTENSITY

text

for i = 1, #BlursList do
    updateGui(BlursList[i])
end

if #PartsList > 0 then
    local cframes = table.create(#BlursList, workspace.CurrentCamera.CFrame)
    workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

BLUR_OBJ.FocusDistance = 0.25 - camera.NearPlaneZ

end

function BlurredGui.new(frame, shape)
local blurPart = Instance.new("Part")
blurPart.Size = Vector3.new(1, 1, 1) * PART_SIZE
blurPart.Anchored = true
blurPart.CanCollide = false
blurPart.CanTouch = false
blurPart.Material = Enum.Material.Glass
blurPart.Transparency = PART_TRANSPARENCY
blurPart.Parent = workspace.CurrentCamera

text

local mesh
if shape == "Rectangle" then
    mesh        = Instance.new("BlockMesh")
    mesh.Parent = blurPart
elseif shape == "Oval" then
    mesh          = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Parent   = blurPart
end

local new = setmetatable({
    Frame          = frame,
    Part           = blurPart,
    Mesh           = mesh,
    IgnoreGuiInset = true,
}, BlurredGui)

BlurObjects[new] = blurPart
rebuildPartsList()

return new

end

function BlurredGui:Destroy()
self.Part:Destroy()
BlurObjects[self] = nil
rebuildPartsList()
end

-- Unbind any previous render step from a prior loadstring run
pcall(function()
RunService:UnbindFromRenderStep("UILibraryBlurUpdate")
end)

RunService:BindToRenderStep(
"UILibraryBlurUpdate",
Enum.RenderPriority.Camera.Value + 1,
function()
BlurredGui.updateAll()
end
)
-- UTILITY

local function Tw(o, props, t, style, dir)
local tw = TweenService:Create(o,
TweenInfo.new(t or 0.15,
Enum.EasingStyle[style or "Quad"],
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
Color = col or C.White,
Thickness = th or 1,
Transparency = tr or 0.92,
Parent = p,
})
end

local function Pad(p, t, b, l, r)
N("UIPadding", {
PaddingTop = UDim.new(0, t or 8),
PaddingBottom = UDim.new(0, b or 8),
PaddingLeft = UDim.new(0, l or 10),
PaddingRight = UDim.new(0, r or 10),
Parent = p,
})
end

local function VList(p, gap)
N("UIListLayout", {
Padding = UDim.new(0, gap or 0),
SortOrder = Enum.SortOrder.LayoutOrder,
FillDirection = Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Left,
Parent = p,
})
end

local function HList(p, gap, ha, va)
N("UIListLayout", {
Padding = UDim.new(0, gap or 0),
SortOrder = Enum.SortOrder.LayoutOrder,
FillDirection = Enum.FillDirection.Horizontal,
HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
VerticalAlignment = va or Enum.VerticalAlignment.Center,
Parent = p,
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

local function Headshot(uid)
local ok, u = pcall(function()
return Players:GetUserThumbnailAsync(
uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
end)
return ok and u or ""
end

local function ResolveAssetId(id)
if id == nil or id == "" then return nil end
if type(id) == "number" then
return "rbxassetid://" .. tostring(id)
end
if type(id) == "string" then
if id:match("^rbxassetid://") or id:match("^http") then
return id
end
if id:match("^%d+$") then
return "rbxassetid://" .. id
end
end
return nil
end
-- SCREEN GUI
-- Remove stale instance from previous loadstring run before creating

local GUI_NAME = "UILibrary_v1"

local function cleanupOldGui()
local old = CoreGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end
local pg = LocalPlayer:FindFirstChild("PlayerGui")
if pg then
local old2 = pg:FindFirstChild(GUI_NAME)
if old2 then old2:Destroy() end
end
end
cleanupOldGui()

local SG
do
local ok = pcall(function()
SG = N("ScreenGui", {
Name = GUI_NAME,
ResetOnSpawn = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
IgnoreGuiInset = true,
Parent = CoreGui,
})
end)
if not ok then
SG = N("ScreenGui", {
Name = GUI_NAME,
ResetOnSpawn = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
IgnoreGuiInset = true,
Parent = LocalPlayer:WaitForChild("PlayerGui"),
})
end
end
-- WINDOW

local W, H = 780, 470
local SIDE = 180
local HEAD = 38
local CORNER = 6
local WIN_POS = UDim2.new(0.5, -W / 2, 0.5, -H / 2)

local winClip = N("Frame", {
Name = "WinClip",
Size = UDim2.new(0, W, 0, H),
Position = WIN_POS,
BackgroundColor3 = C.BgWindow,
BackgroundTransparency = WIN_TRANS,
BorderSizePixel = 0,
ClipsDescendants = true,
Parent = SG,
})
Cor(winClip, CORNER)

N("UIStroke", {
Color = Color3.fromRGB(40, 44, 54),
Thickness = 1,
Transparency = 0.2,
Parent = winClip,
})

local blurBacker = N("Frame", {
Name = "BlurBacker",
Size = UDim2.new(0, W, 0, H),
Position = WIN_POS,
BackgroundTransparency = 1,
BorderSizePixel = 0,
ZIndex = 1,
Parent = SG,
})

RunService.RenderStepped:Connect(function()
blurBacker.Position = winClip.Position
blurBacker.Size = winClip.Size
blurBacker.Visible = winClip.Visible
end)

local win = winClip

local visible = true
UserInputService.InputBegan:Connect(function(i, gpe)
if gpe then return end
if i.KeyCode == Enum.KeyCode.RightAlt then
visible = not visible
win.Visible = visible
end
end)
-- HEADER

local hdrOuter = N("Frame", {
Name = "HdrOuter",
Size = UDim2.new(1, 0, 0, HEAD),
Position = UDim2.new(0, 0, 0, 0),
BackgroundColor3 = C.BgHeader,
BorderSizePixel = 0,
ZIndex = 5,
Parent = win,
})
Cor(hdrOuter, CORNER)

N("Frame", {
Name = "HdrCover",
Size = UDim2.new(1, 0, 0, CORNER),
Position = UDim2.new(0, 0, 1, -CORNER),
BackgroundColor3 = C.BgHeader,
BorderSizePixel = 0,
ZIndex = 6,
Parent = hdrOuter,
})

N("Frame", {
Size = UDim2.new(1, 0, 0, 1),
Position = UDim2.new(0, 0, 1, -1),
BackgroundColor3 = C.White,
BackgroundTransparency = 0.93,
BorderSizePixel = 0,
ZIndex = 7,
Parent = hdrOuter,
})

local hdr = N("Frame", {
Name = "Hdr",
Size = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ZIndex = 7,
Parent = hdrOuter,
})

local titleLbl = N("TextLabel", {
Size = UDim2.new(0.5, 0, 1, 0),
Position = UDim2.new(0, 14, 0, 0),
BackgroundTransparency = 1,
Text = "MyUI",
Font = Enum.Font.GothamBold,
TextSize = 13,
TextColor3 = C.Accent,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 8,
Parent = hdr,
})

local rF = N("Frame", {
Size = UDim2.new(0, 200, 1, 0),
Position = UDim2.new(1, -206, 0, 0),
BackgroundTransparency = 1,
ZIndex = 7,
Parent = hdr,
})
HList(rF, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
Pad(rF, 0, 0, 0, 8)

N("TextLabel", {
Size = UDim2.new(0, 170, 1, 0),
BackgroundTransparency = 1,
Text = LocalPlayer.Name,
Font = Enum.Font.GothamSemibold,
TextSize = 11,
TextColor3 = C.Accent,
TextXAlignment = Enum.TextXAlignment.Right,
LayoutOrder = 1,
ZIndex = 8,
Parent = rF,
})

local avF = N("Frame", {
Size = UDim2.new(0, 20, 0, 20),
BackgroundColor3 = Color3.fromRGB(35, 35, 35),
BorderSizePixel = 0,
LayoutOrder = 2,
ZIndex = 8,
Parent = rF,
})
Cor(avF, 10)
local avI = N("ImageLabel", {
Size = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Image = "",
ZIndex = 9,
Parent = avF,
})
Cor(avI, 10)
task.spawn(function() avI.Image = Headshot(LocalPlayer.UserId) end)

Draggable(win, hdr)
-- BODY

local body = N("Frame", {
Size = UDim2.new(1, 0, 1, -HEAD),
Position = UDim2.new(0, 0, 0, HEAD),
BackgroundTransparency = 1,
ClipsDescendants = false,
Parent = win,
})

local sidebar = N("ScrollingFrame", {
Name = "Sidebar",
Size = UDim2.new(0, SIDE, 1, 0),
BackgroundColor3 = C.BgSidebar,
BackgroundTransparency = SIDE_TRANS,
BorderSizePixel = 0,
ScrollBarThickness = 0,
CanvasSize = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ZIndex = 4,
Parent = body,
})
VList(sidebar, 5)
Pad(sidebar, 10, 10, 10, 10)

N("Frame", {
Size = UDim2.new(0, 1, 1, 0),
Position = UDim2.new(0, SIDE, 0, 0),
BackgroundColor3 = C.White,
BackgroundTransparency = 0.97,
BorderSizePixel = 0,
ZIndex = 5,
Parent = body,
})

local mainW = W - SIDE - 1

local main = N("ScrollingFrame", {
Name = "Main",
Size = UDim2.new(1, -SIDE - 1, 1, 0),
Position = UDim2.new(0, SIDE + 1, 0, 0),
BackgroundColor3 = C.BgMain,
BackgroundTransparency = MAIN_TRANS,
BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollBarImageColor3 = C.BgInput,
CanvasSize = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ClipsDescendants = false,
Parent = body,
})
-- PANEL / TAB SYSTEM

local allPanels = {}
local allSideRows = {}

local function selectPanel(entry)
for _, e in ipairs(allSideRows) do
e.lbl.TextColor3 = C.TextMuted
e.dot.BackgroundTransparency = 1
end
entry.lbl.TextColor3 = C.TextMain
entry.dot.BackgroundTransparency = 0
for _, pf in ipairs(allPanels) do
pf.Visible = false
end
entry.panelFrame.Visible = true
end
-- REGISTRIES

local allCategories = {}
local allDropdowns = {}

local function closeAllDropdowns(except)
for _, dd in ipairs(allDropdowns) do
if dd ~= except and dd.isOpen then dd.close() end
end
end

local popupZ = 100
local function nextPopupZ()
popupZ = popupZ + 2
return popupZ
end
-- PUBLIC API

local catOrder = 0
local UILib = {}
UILib.Theme = C -- expose theme so calling scripts can safely read UILib.Theme.Accent

function UILib.SetTitle(name)
titleLbl.Text = name or "MyUI"
end

function UILib.Destroy()
pcall(function() RunService:UnbindFromRenderStep("UILibraryBlurUpdate") end)
for _, part in pairs(BlurObjects) do
pcall(function() part:Destroy() end)
end
BlurObjects = {}
BlursList = {}
PartsList = {}
pcall(function() BLUR_OBJ:Destroy() end)
pcall(function() SG:Destroy() end)
end
-- ADD CATEGORY

function UILib.AddCategory(cfg)
if type(cfg) == "string" then cfg = {Name = cfg} end
local name = cfg.Name or "Category"
local imageId = ResolveAssetId(cfg.Image)
catOrder = catOrder + 1

text

local catReg = {}

local wrap = N("Frame", {
    Name                   = "Cat_" .. name,
    Size                   = UDim2.new(1, 0, 0, 30),
    BackgroundColor3       = C.BgCard,
    BackgroundTransparency = 0,
    BorderSizePixel        = 0,
    ClipsDescendants       = true,
    LayoutOrder            = catOrder,
    Parent                 = sidebar,
})
Cor(wrap, 4)

local hBtn = N("TextButton", {
    Size                   = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text                   = "",
    AutoButtonColor        = false,
    ZIndex                 = 5,
    Parent                 = wrap,
})

local ICON_SIZE = 14
local ICON_GAP  = 6
local BASE_LEFT = 10
local textLeft  = imageId and (BASE_LEFT + ICON_SIZE + ICON_GAP) or BASE_LEFT

if imageId then
    N("ImageLabel", {
        Name                   = "CatIcon",
        Size                   = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
        Position               = UDim2.new(0, BASE_LEFT, 0.5, -ICON_SIZE / 2),
        BackgroundTransparency = 1,
        Image                  = imageId,
        ZIndex                 = 6,
        Parent                 = hBtn,
    })
end

local catLbl = N("TextLabel", {
    Size                   = UDim2.new(1, -(textLeft + 18), 1, 0),
    Position               = UDim2.new(0, textLeft, 0, 0),
    BackgroundTransparency = 1,
    Text                   = name,
    Font                   = Enum.Font.GothamSemibold,
    TextSize               = 11,
    TextColor3             = C.TextMuted,
    TextXAlignment         = Enum.TextXAlignment.Left,
    ZIndex                 = 6,
    Parent                 = hBtn,
})

local chevF = N("Frame", {
    Size                   = UDim2.new(0, 10, 0, 6),
    Position               = UDim2.new(1, -16, 0.5, -3),
    BackgroundTransparency = 1,
    ZIndex                 = 6,
    Parent                 = hBtn,
})
local cL = N("Frame", {
    Size             = UDim2.new(0, 6, 0, 1.5),
    Position         = UDim2.new(0, 0, 0.5, 0),
    Rotation         = 40,
    BackgroundColor3 = C.TextMuted,
    BorderSizePixel  = 0,
    ZIndex           = 7,
    Parent           = chevF,
}); Cor(cL, 1)
local cR = N("Frame", {
    Size             = UDim2.new(0, 6, 0, 1.5),
    Position         = UDim2.new(1, -6, 0.5, 0),
    Rotation         = -40,
    BackgroundColor3 = C.TextMuted,
    BorderSizePixel  = 0,
    ZIndex           = 7,
    Parent           = chevF,
}); Cor(cR, 1)

local subC = N("Frame", {
    Size                   = UDim2.new(1, 0, 0, 0),
    Position               = UDim2.new(0, 0, 0, 30),
    BackgroundColor3       = Color3.fromRGB(6, 7, 9),
    BackgroundTransparency = 0,
    BorderSizePixel        = 0,
    Parent                 = wrap,
})
VList(subC, 0)
local subLayout = subC:FindFirstChildWhichIsA("UIListLayout")

local isOpen = false

local function setOpen(v)
    isOpen = v
    if v then
        for _, reg in ipairs(allCategories) do
            if reg ~= catReg and reg.getIsOpen() then reg.setOpen(false) end
        end
    end
    local h = v and subLayout.AbsoluteContentSize.Y or 0
    Tw(subC,   {Size       = UDim2.new(1, 0, 0, h)},          0.15, "Quad")
    Tw(wrap,   {Size       = UDim2.new(1, 0, 0, 30 + h)},     0.15, "Quad")
    Tw(catLbl, {TextColor3 = v and C.TextMain or C.TextMuted}, 0.12)
    Tw(cL,     {Rotation   = v and -40 or  40},                0.15)
    Tw(cR,     {Rotation   = v and  40 or -40},                0.15)
end

catReg.setOpen   = setOpen
catReg.getIsOpen = function() return isOpen end
table.insert(allCategories, catReg)

hBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
hBtn.MouseEnter:Connect(function() Tw(catLbl, {TextColor3 = C.TextMain}, 0.1) end)
hBtn.MouseLeave:Connect(function()
    if not isOpen then Tw(catLbl, {TextColor3 = C.TextMuted}, 0.1) end
end)

local subCount = 0
local catAPI   = {}

function catAPI:AddTab(tName)
    subCount = subCount + 1
    local sc = subCount

    local row = N("TextButton", {
        Size                   = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        LayoutOrder            = sc,
        ZIndex                 = 6,
        Parent                 = subC,
    })

    local dot = N("Frame", {
        Size                   = UDim2.new(0, 3, 0, 3),
        Position               = UDim2.new(0, 16, 0.5, -1),
        BackgroundColor3       = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 7,
        Parent                 = row,
    }); Cor(dot, 2)

    local lbl = N("TextLabel", {
        Size                   = UDim2.new(1, -30, 1, 0),
        Position               = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        Text                   = tName,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextColor3             = C.TextMuted,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 7,
        Parent                 = row,
    })

    local panelFrame = N("Frame", {
        Name                   = "Panel_" .. tName,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible                = false,
        LayoutOrder            = #allPanels + 1,
        Parent                 = main,
    })
    Pad(panelFrame, 10, 10, 10, 10)

    local colHolder = N("Frame", {
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent                 = panelFrame,
    })
    HList(colHolder, 10,
        Enum.HorizontalAlignment.Left,
        Enum.VerticalAlignment.Top)

    local colW = math.floor((mainW - 20 - 10) / 2)

    local function makeCol(order)
        local col = N("Frame", {
            Size                   = UDim2.new(0, colW, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder            = order,
            Parent                 = colHolder,
        })
        VList(col, 10)
        return col
    end

    local col1 = makeCol(1)
    local col2 = makeCol(2)

    table.insert(allPanels, panelFrame)
    local entry = {lbl = lbl, dot = dot, panelFrame = panelFrame}
    table.insert(allSideRows, entry)

    if #allPanels == 1 then
        lbl.TextColor3             = C.TextMain
        dot.BackgroundTransparency = 0
        panelFrame.Visible         = true
        setOpen(true)
    end

    row.MouseButton1Click:Connect(function()
        if not isOpen then setOpen(true) end
        selectPanel(entry)
    end)
    row.MouseEnter:Connect(function()
        if lbl.TextColor3 ~= C.TextMain then
            Tw(lbl, {TextColor3 = Color3.fromRGB(150, 156, 166)}, 0.1)
        end
    end)
    row.MouseLeave:Connect(function()
        if lbl.TextColor3 ~= C.TextMain then
            Tw(lbl, {TextColor3 = C.TextMuted}, 0.1)
        end
    end)

    task.spawn(function()
        task.wait()
        if isOpen then
            local h = subLayout.AbsoluteContentSize.Y
            subC.Size = UDim2.new(1, 0, 0, h)
            wrap.Size = UDim2.new(1, 0, 0, 30 + h)
        end
    end)

    local tabAPI = {}

    local function makeCard(colFrame, cardTitle)
        local card = N("Frame", {
            Name                   = "Card_" .. cardTitle,
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundColor3       = C.BgCard,
            BackgroundTransparency = 0,
            BorderSizePixel        = 0,
            ClipsDescendants       = false,
            Parent                 = colFrame,
        })
        Cor(card, 6)
        Stroke(card, Color3.fromRGB(255, 255, 255), 1, 0.99)
        Pad(card, 10, 12, 12, 12)
        VList(card, 9)

        local tRow = N("Frame", {
            Name                   = "TR",
            Size                   = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder            = 0,
            Parent                 = card,
        })
        N("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = cardTitle,
            Font                   = Enum.Font.GothamSemibold,
            TextSize               = 11,
            TextColor3             = C.TextMain,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = tRow,
        })
        N("Frame", {
            Size                   = UDim2.new(1, 0, 0, 1),
            Position               = UDim2.new(0, 0, 1, -1),
            BackgroundColor3       = C.White,
            BackgroundTransparency = 0.97,
            BorderSizePixel        = 0,
            Parent                 = tRow,
        })

        local cAPI = {_card = card, _n = 1}

        local function nextN()
            cAPI._n = cAPI._n + 1
            return cAPI._n
        end

        local function CtrlRow(labelTxt, disabled)
            local row2 = N("Frame", {
                Name                   = "CR_" .. labelTxt,
                Size                   = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                LayoutOrder            = nextN(),
                Parent                 = card,
            })
            N("TextLabel", {
                Size                   = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = labelTxt,
                Font                   = Enum.Font.Gotham,
                TextSize               = 11,
                TextColor3             = disabled and C.TextDis or C.TextMain,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = row2,
            })
            return row2
        end

        ----------------------------------------------------------------
        -- TOGGLE
        ----------------------------------------------------------------
        function cAPI:AddToggle(cfg2)
            cfg2           = cfg2 or {}
            local lbl2     = cfg2.Label    or "Toggle"
            local default  = cfg2.Default  or false
            local disabled = cfg2.Disabled or false
            local cb       = cfg2.Callback or function() end
            local state    = default

            local row2 = CtrlRow(lbl2, disabled)

            local PW, PH = 24, 12
            local TD     = 8
            local pill   = N("Frame", {
                Size                   = UDim2.new(0, PW, 0, PH),
                Position               = UDim2.new(1, -PW, 0.5, -PH / 2),
                BackgroundColor3       = Color3.fromRGB(30, 34, 42),
                BorderSizePixel        = 0,
                BackgroundTransparency = disabled and 0.5 or 0,
                ZIndex                 = 5,
                Parent                 = row2,
            })
            Cor(pill, math.floor(PH / 2))

            local thumb = N("Frame", {
                Size                   = UDim2.new(0, TD, 0, TD),
                Position               = UDim2.new(0, 2, 0.5, -TD / 2),
                BackgroundColor3       = Color3.fromRGB(75, 82, 96),
                BorderSizePixel        = 0,
                BackgroundTransparency = disabled and 0.5 or 0,
                ZIndex                 = 6,
                Parent                 = pill,
            })
            Cor(thumb, math.floor(TD / 2))

            local function setT(v, anim)
                state     = v
                local bg  = v and C.Accent or Color3.fromRGB(30, 34, 42)
                local tc  = v and C.White  or Color3.fromRGB(75, 82, 96)
                local pos = v
                    and UDim2.new(0, PW - TD - 2, 0.5, -TD / 2)
                    or  UDim2.new(0, 2, 0.5, -TD / 2)
                if anim then
                    Tw(pill,  {BackgroundColor3 = bg},                0.15)
                    Tw(thumb, {BackgroundColor3 = tc, Position = pos}, 0.15)
                else
                    pill.BackgroundColor3  = bg
                    thumb.BackgroundColor3 = tc
                    thumb.Position         = pos
                end
            end
            setT(default, false)

            if not disabled then
                local hit = N("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    ZIndex                 = 7,
                    Parent                 = row2,
                })
                hit.MouseButton1Click:Connect(function()
                    setT(not state, true); cb(state)
                end)
            end

            local api = {}
            function api:Set(v) setT(v, true); cb(state) end
            function api:Get() return state end
            return api
        end

        ----------------------------------------------------------------
        -- SLIDER
        ----------------------------------------------------------------
        function cAPI:AddSlider(cfg2)
            cfg2       = cfg2 or {}
            local lbl2 = cfg2.Label    or "Slider"
            local mn   = cfg2.Min      or 0
            local mx   = cfg2.Max      or 1
            local def  = cfg2.Default  or mn
            local dec  = cfg2.Decimals or 3
            local suf  = cfg2.Suffix   or ""
            local cb   = cfg2.Callback or function() end
            local val  = math.clamp(def, mn, mx)

            local block = N("Frame", {
                Name                   = "Sld_" .. lbl2,
                Size                   = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder            = nextN(),
                Parent                 = card,
            })

            local hr = N("Frame", {
                Size                   = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Parent                 = block,
            })
            N("TextLabel", {
                Size                   = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = lbl2,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 11,
                TextColor3             = C.TextMain,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = hr,
            })
            local vLbl = N("TextLabel", {
                Size                   = UDim2.new(0.4, 0, 1, 0),
                Position               = UDim2.new(0.6, 0, 0, 0),
                BackgroundTransparency = 1,
                Text                   = string.format("%." .. dec .. "f%s", val, suf),
                Font                   = Enum.Font.Code,
                TextSize               = 11,
                TextColor3             = C.TextMuted,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = hr,
            })

            local TH = 10

            local trackBg = N("Frame", {
                Size             = UDim2.new(1, 0, 0, TH),
                Position         = UDim2.new(0, 0, 0, 22),
                BackgroundColor3 = Color3.fromRGB(28, 34, 38),
                BorderSizePixel  = 0,
                ZIndex           = 2,
                Parent           = block,
            })
            Cor(trackBg, TH / 2)

            local fill = N("Frame", {
                Size             = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
                ZIndex           = 3,
                ClipsDescendants = false,
                Parent           = trackBg,
            })
            Cor(fill, TH / 2)

            local hit = N("TextButton", {
                Size                   = UDim2.new(1, 0, 0, 28),
                Position               = UDim2.new(0, 0, 0.5, -14),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 6,
                Parent                 = trackBg,
            })

            local function setV(raw)
                local f   = 10 ^ dec
                val       = math.clamp(math.floor(raw * f + 0.5) / f, mn, mx)
                local pct = (val - mn) / (mx - mn)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                vLbl.Text = string.format("%." .. dec .. "f%s", val, suf)
                cb(val)
            end
            setV(def)

            local drag2 = false
            hit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag2 = true
                    local abs = trackBg.AbsolutePosition
                    local sz  = trackBg.AbsoluteSize
                    setV(mn + (mx - mn) * math.clamp(
                        (UserInputService:GetMouseLocation().X - abs.X) / sz.X, 0, 1))
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then drag2 = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if drag2 and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local abs = trackBg.AbsolutePosition
                    local sz  = trackBg.AbsoluteSize
                    setV(mn + (mx - mn) * math.clamp(
                        (i.Position.X - abs.X) / sz.X, 0, 1))
                end
            end)

            local api = {}
            function api:Set(v) setV(v) end
            function api:Get() return val end
            return api
        end

        ----------------------------------------------------------------
        -- HOLD KEYBIND
        ----------------------------------------------------------------
        function cAPI:AddHoldKeybind(cfg2)
            cfg2          = cfg2 or {}
            local lbl2    = cfg2.Label    or "Keybind"
            local default = cfg2.Default
            local cb      = cfg2.Callback or function() end
            local bk      = default
            local listen  = false

            local row2 = CtrlRow(lbl2, false)

            local CHIP_W  = 38
            local keyChip = N("TextButton", {
                Size             = UDim2.new(0, CHIP_W, 0, 16),
                Position         = UDim2.new(1, -CHIP_W, 0.5, -8),
                BackgroundColor3 = C.BgInput,
                BorderSizePixel  = 0,
                Text             = bk and bk.Name or "None",
                Font             = Enum.Font.Code,
                TextSize         = 10,
                TextColor3       = C.TextMuted,
                AutoButtonColor  = false,
                ZIndex           = 6,
                Parent           = row2,
            })
            Cor(keyChip, 2)
            Stroke(keyChip, C.White, 1, 0.96)

            keyChip.MouseButton1Click:Connect(function()
                if listen then return end
                listen = true
                keyChip.Text       = "..."
                keyChip.TextColor3 = C.Accent
                local c
                c = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        bk                 = inp.KeyCode
                        keyChip.Text       = inp.KeyCode.Name
                        keyChip.TextColor3 = C.TextMuted
                        listen             = false
                        c:Disconnect()
                        cb(bk, false, false)
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(inp, gpe)
                if listen or gpe then return end
                if bk and inp.KeyCode == bk then cb(bk, true, true) end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if bk and inp.KeyCode == bk then cb(bk, false, false) end
            end)

            local api = {}
            function api:GetKey() return bk end
            return api
        end

        ----------------------------------------------------------------
        -- TOGGLE KEYBIND
        ----------------------------------------------------------------
        function cAPI:AddToggleKeybind(cfg2)
            cfg2          = cfg2 or {}
            local lbl2    = cfg2.Label   or "Toggle"
            local default = cfg2.Default or false
            local defKey  = cfg2.Key
            local cb      = cfg2.Callback or function() end
            local state   = default
            local bk      = defKey
            local listen  = false

            local row2 = N("Frame", {
                Name                   = "TKR_" .. lbl2,
                Size                   = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                LayoutOrder            = nextN(),
                Parent                 = card,
            })

            N("TextLabel", {
                Size                   = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = lbl2,
                Font                   = Enum.Font.Gotham,
                TextSize               = 11,
                TextColor3             = C.TextMain,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row2,
            })

            local CHIP_W  = 38
            local keyChip = N("TextButton", {
                Size             = UDim2.new(0, CHIP_W, 0, 16),
                Position         = UDim2.new(1, -CHIP_W, 0.5, -8),
                BackgroundColor3 = C.BgInput,
                BorderSizePixel  = 0,
                Text             = bk and bk.Name or "None",
                Font             = Enum.Font.Code,
                TextSize         = 10,
                TextColor3       = C.TextMuted,
                AutoButtonColor  = false,
                ZIndex           = 6,
                Parent           = row2,
            })
            Cor(keyChip, 2)
            Stroke(keyChip, C.White, 1, 0.96)

            local PW, PH = 24, 12
            local TD     = 8
            local pill   = N("Frame", {
                Size             = UDim2.new(0, PW, 0, PH),
                Position         = UDim2.new(1, -CHIP_W - PW - 6, 0.5, -PH / 2),
                BackgroundColor3 = Color3.fromRGB(30, 34, 42),
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = row2,
            })
            Cor(pill, math.floor(PH / 2))

            local thumb = N("Frame", {
                Size             = UDim2.new(0, TD, 0, TD),
                Position         = UDim2.new(0, 2, 0.5, -TD / 2),
                BackgroundColor3 = Color3.fromRGB(75, 82, 96),
                BorderSizePixel  = 0,
                ZIndex           = 6,
                Parent           = pill,
            })
            Cor(thumb, math.floor(TD / 2))

            local function setState(v, anim)
                state     = v
                local bg  = v and C.Accent or Color3.fromRGB(30, 34, 42)
                local tc  = v and C.White  or Color3.fromRGB(75, 82, 96)
                local pos = v
                    and UDim2.new(0, PW - TD - 2, 0.5, -TD / 2)
                    or  UDim2.new(0, 2, 0.5, -TD / 2)
                if anim then
                    Tw(pill,  {BackgroundColor3 = bg},                0.15)
                    Tw(thumb, {BackgroundColor3 = tc, Position = pos}, 0.15)
                else
                    pill.BackgroundColor3  = bg
                    thumb.BackgroundColor3 = tc
                    thumb.Position         = pos
                end
            end
            setState(default, false)

            local pillHit = N("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 7,
                Parent                 = pill,
            })
            pillHit.MouseButton1Click:Connect(function()
                setState(not state, true)
                cb(state, bk)
            end)

            keyChip.MouseButton1Click:Connect(function()
                if listen then return end
                listen = true
                keyChip.Text       = "..."
                keyChip.TextColor3 = C.Accent
                local c
                c = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        bk                 = inp.KeyCode
                        keyChip.Text       = inp.KeyCode.Name
                        keyChip.TextColor3 = C.TextMuted
                        listen             = false
                        c:Disconnect()
                        cb(state, bk)
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(inp, gpe)
                if listen or gpe then return end
                if bk and inp.KeyCode == bk then
                    setState(not state, true)
                    cb(state, bk)
                end
            end)

            local api = {}
            function api:Set(v) setState(v, true); cb(state, bk) end
            function api:Get() return state end
            function api:GetKey() return bk end
            return api
        end

        ----------------------------------------------------------------
        -- DROPDOWN
        ----------------------------------------------------------------
        function cAPI:AddDropdown(cfg2)
            cfg2          = cfg2 or {}
            local lbl2    = cfg2.Label    or "Dropdown"
            local opts    = cfg2.Options  or {}
            local default = cfg2.Default  or opts[1]
            local cb      = cfg2.Callback or function() end
            local sel     = default
            local isOpen2 = false
            local posConn = nil

            local row2 = CtrlRow(lbl2, false)

            local CHIP_W = 80
            local chip   = N("TextButton", {
                Size             = UDim2.new(0, CHIP_W, 0, 16),
                Position         = UDim2.new(1, -CHIP_W, 0.5, -8),
                BackgroundColor3 = C.BgInput,
                BorderSizePixel  = 0,
                Text             = sel or "—",
                Font             = Enum.Font.Gotham,
                TextSize         = 11,
                TextColor3       = C.TextMain,
                AutoButtonColor  = false,
                ZIndex           = 8,
                Parent           = row2,
            })
            Cor(chip, 2)

            local chevCont = N("Frame", {
                Size                   = UDim2.new(0, 10, 1, 0),
                Position               = UDim2.new(1, -12, 0, 0),
                BackgroundTransparency = 1,
                ZIndex                 = 9,
                Parent                 = chip,
            })
            local chL = N("Frame", {
                Size             = UDim2.new(0, 5, 0, 1.5),
                Position         = UDim2.new(0, 0, 0.5, 1),
                Rotation         = 40,
                BackgroundColor3 = C.TextMuted,
                BorderSizePixel  = 0,
                ZIndex           = 9,
                Parent           = chevCont,
            }); Cor(chL, 1)
            local chR = N("Frame", {
                Size             = UDim2.new(0, 5, 0, 1.5),
                Position         = UDim2.new(1, -5, 0.5, 1),
                Rotation         = -40,
                BackgroundColor3 = C.TextMuted,
                BorderSizePixel  = 0,
                ZIndex           = 9,
                Parent           = chevCont,
            }); Cor(chR, 1)

            local LIST_W     = CHIP_W + 16
            local BASE_Z     = nextPopupZ()
            local listF      = N("Frame", {
                Size             = UDim2.new(0, LIST_W, 0, 0),
                BackgroundColor3 = C.BgCard,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = BASE_Z,
                Parent           = SG,
            })
            Cor(listF, 4)
            N("UIStroke", {
                Color        = Color3.fromRGB(34, 38, 47),
                Thickness    = 1,
                Transparency = 0,
                Parent       = listF,
            })

            local listScroll = N("ScrollingFrame", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                ScrollBarThickness     = 2,
                ScrollBarImageColor3   = C.BgInput,
                CanvasSize             = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                ZIndex                 = BASE_Z + 1,
                Parent                 = listF,
            })
            VList(listScroll, 2)
            Pad(listScroll, 4, 4, 4, 4)

            local ddReg = {isOpen = false, close = nil}

            local function doClose()
                isOpen2       = false
                ddReg.isOpen  = false
                listF.Visible = false
                if posConn then posConn:Disconnect(); posConn = nil end
                Tw(chL, {Rotation =  40}, 0.13)
                Tw(chR, {Rotation = -40}, 0.13)
            end

            local function doOpen()
                closeAllDropdowns(ddReg)
                isOpen2      = true
                ddReg.isOpen = true
                local nz = nextPopupZ()
                listF.ZIndex      = nz
                listScroll.ZIndex = nz + 1
                local abs  = chip.AbsolutePosition
                local sz   = chip.AbsoluteSize
                local maxH = math.min(#opts * 26 + 8, 120)
                listF.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 3)
                listF.Size     = UDim2.new(0, LIST_W, 0, maxH)
                listF.Visible  = true
                Tw(chL, {Rotation = -40}, 0.13)
                Tw(chR, {Rotation =  40}, 0.13)
                posConn = RunService.RenderStepped:Connect(function()
                    if not isOpen2 then return end
                    local a = chip.AbsolutePosition
                    local s = chip.AbsoluteSize
                    listF.Position = UDim2.new(0, a.X, 0, a.Y + s.Y + 3)
                end)
            end

            ddReg.close = doClose
            table.insert(allDropdowns, ddReg)

            local optBtns = {}
            for i, opt in ipairs(opts) do
                local ob = N("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = C.BgCard,
                    BorderSizePixel  = 0,
                    Text             = opt,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextColor3       = (opt == sel) and C.Accent or C.TextMuted,
                    AutoButtonColor  = false,
                    ZIndex           = BASE_Z + 2,
                    LayoutOrder      = i,
                    Parent           = listScroll,
                })
                Cor(ob, 3)
                ob.MouseEnter:Connect(function()
                    Tw(ob, {BackgroundColor3 = C.BgInput}, 0.08)
                end)
                ob.MouseLeave:Connect(function()
                    Tw(ob, {BackgroundColor3 = C.BgCard}, 0.08)
                end)
                ob.MouseButton1Click:Connect(function()
                    sel = opt; chip.Text = opt
                    for _, b in ipairs(optBtns) do b.TextColor3 = C.TextMuted end
                    ob.TextColor3 = C.Accent
                    doClose(); cb(sel)
                end)
                table.insert(optBtns, ob)
            end

            chip.MouseButton1Click:Connect(function()
                if isOpen2 then doClose() else doOpen() end
            end)
            UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and isOpen2 then
                    task.defer(function() if isOpen2 then doClose() end end)
                end
            end)

            local api = {}
            function api:Set(v)
                sel = v; chip.Text = v
                for _, b in ipairs(optBtns) do
                    b.TextColor3 = (b.Text == v) and C.Accent or C.TextMuted
                end
            end
            function api:Get() return sel end
            return api
        end

        ----------------------------------------------------------------
        -- COLOR PICKER
        ----------------------------------------------------------------
        function cAPI:AddColorPicker(cfg2)
            cfg2          = cfg2 or {}
            local lbl2    = cfg2.Label    or "Color"
            local default = cfg2.Default  or C.Accent
            local cb      = cfg2.Callback or function() end
            local col     = default

            local row2 = CtrlRow(lbl2, false)

            local prev = N("TextButton", {
                Size             = UDim2.new(0, 22, 0, 11),
                Position         = UDim2.new(1, -22, 0.5, -5),
                BackgroundColor3 = col,
                BorderSizePixel  = 0,
                Text             = "",
                AutoButtonColor  = false,
                ZIndex           = 5,
                Parent           = row2,
            })
            Cor(prev, 2)
            Stroke(prev, C.White, 1, 0.82)

            local BASE_Z = nextPopupZ()
            local pop    = N("Frame", {
                Size             = UDim2.new(0, 120, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = C.BgCard,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = BASE_Z,
                Parent           = SG,
            })
            Cor(pop, 4)
            N("UIStroke", {
                Color        = Color3.fromRGB(34, 38, 47),
                Thickness    = 1,
                Transparency = 0,
                Parent       = pop,
            })
            Pad(pop, 6, 6, 6, 6)
            VList(pop, 5)

            local channels = {}

            local function makeColorSlider(cname, initV, lo)
                local sr = N("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    LayoutOrder            = lo,
                    Parent                 = pop,
                })
                VList(sr, 2)
                local tr2 = N("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 11),
                    BackgroundTransparency = 1,
                    Parent                 = sr,
                })
                N("TextLabel", {
                    Size                   = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = cname,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 9,
                    TextColor3             = C.TextMuted,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = BASE_Z + 1,
                    Parent                 = tr2,
                })
                local vl = N("TextLabel", {
                    Size                   = UDim2.new(0.5, 0, 1, 0),
                    Position               = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text                   = tostring(initV),
                    Font                   = Enum.Font.Code,
                    TextSize               = 9,
                    TextColor3             = C.TextMuted,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    ZIndex                 = BASE_Z + 1,
                    Parent                 = tr2,
                })
                local tk = N("Frame", {
                    Size             = UDim2.new(1, 0, 0, 3),
                    BackgroundColor3 = C.BgInput,
                    BorderSizePixel  = 0,
                    ZIndex           = BASE_Z + 1,
                    Parent           = sr,
                })
                Cor(tk, 1)
                local fl = N("Frame", {
                    Size             = UDim2.new(initV / 255, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(75, 82, 96),
                    BorderSizePixel  = 0,
                    ZIndex           = BASE_Z + 2,
                    Parent           = tk,
                })
                Cor(fl, 1)
                N("Frame", {
                    Size             = UDim2.new(0, 6, 0, 6),
                    Position         = UDim2.new(1, -3, 0.5, -3),
                    BackgroundColor3 = C.White,
                    BorderSizePixel  = 0,
                    ZIndex           = BASE_Z + 3,
                    Parent           = fl,
                })
                local ht = N("TextButton", {
                    Size                   = UDim2.new(1, 0, 0, 14),
                    Position               = UDim2.new(0, 0, 0.5, -7),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    ZIndex                 = BASE_Z + 4,
                    Parent                 = tk,
                })
                local cv = initV
                local d3 = false
                ht.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then d3 = true end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then d3 = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if d3 and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = tk.AbsolutePosition
                        local sz  = tk.AbsoluteSize
                        cv = math.clamp(
                            math.floor(255 * ((i.Position.X - abs.X) / sz.X) + 0.5),
                            0, 255)
                        fl.Size = UDim2.new(cv / 255, 0, 1, 0)
                        vl.Text = tostring(cv)
                        col = Color3.fromRGB(channels.R(), channels.G(), channels.B())
                        prev.BackgroundColor3 = col
                        cb(col)
                    end
                end)
                return function() return cv end
            end

            local rG = makeColorSlider("Red",   math.floor(col.R * 255 + 0.5), 1)
            local gG = makeColorSlider("Green", math.floor(col.G * 255 + 0.5), 2)
            local bG = makeColorSlider("Blue",  math.floor(col.B * 255 + 0.5), 3)
            channels = {R = rG, G = gG, B = bG}

            local popOpen = false
            local popConn = nil

            local function closePop()
                popOpen     = false
                pop.Visible = false
                if popConn then popConn:Disconnect(); popConn = nil end
            end

            local function openPop()
                popOpen = true
                local nz = nextPopupZ()
                pop.ZIndex = nz
                local abs = prev.AbsolutePosition
                local sz  = prev.AbsoluteSize
                pop.Position = UDim2.new(0, abs.X + sz.X - 120, 0, abs.Y + sz.Y + 4)
                pop.Visible  = true
                popConn = RunService.RenderStepped:Connect(function()
                    if not popOpen then return end
                    local a = prev.AbsolutePosition
                    local s = prev.AbsoluteSize
                    pop.Position = UDim2.new(0, a.X + s.X - 120, 0, a.Y + s.Y + 4)
                end)
            end

            prev.MouseButton1Click:Connect(function()
                if popOpen then closePop() else openPop() end
            end)
            UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and popOpen then
                    task.defer(function() if popOpen then closePop() end end)
                end
            end)

            local api = {}
            function api:Get() return col end
            return api
        end

        ----------------------------------------------------------------
        -- STATUS BOX
        ----------------------------------------------------------------
        function cAPI:AddStatus(cfg2)
            cfg2      = cfg2 or {}
            local text = cfg2.Text or "Inactive"

            local box = N("Frame", {
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = C.BgInput,
                BorderSizePixel  = 0,
                LayoutOrder      = nextN(),
                Parent           = card,
            })
            Cor(box, 4)

            local lbl3 = N("TextLabel", {
                Size                   = UDim2.new(1, -16, 1, 0),
                Position               = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text                   = text,
                Font                   = Enum.Font.Gotham,
                TextSize               = 10,
                TextColor3             = C.TextMuted,
                ZIndex                 = 5,
                TextXAlignment         = Enum.TextXAlignment.Center,
                Parent                 = box,
            })

            local api = {}
            function api:SetActive(v, msg)
                if v then
                    Tw(box, {BackgroundColor3 = Color3.fromRGB(18, 48, 38)}, 0.15)
                    lbl3.TextColor3 = C.White
                else
                    Tw(box, {BackgroundColor3 = C.BgInput}, 0.15)
                    lbl3.TextColor3 = C.TextMuted
                end
                if msg then lbl3.Text = msg end
            end
            function api:SetText(t) lbl3.Text = t end
            return api
        end

        ----------------------------------------------------------------
        -- SEPARATOR
        ----------------------------------------------------------------
        function cAPI:AddSeparator()
            N("Frame", {
                Size                   = UDim2.new(1, 0, 0, 1),
                BackgroundColor3       = C.White,
                BackgroundTransparency = 0.97,
                BorderSizePixel        = 0,
                LayoutOrder            = nextN(),
                Parent                 = card,
            })
        end

        ----------------------------------------------------------------
        -- LABEL
        ----------------------------------------------------------------
        function cAPI:AddLabel(cfg2)
            cfg2 = cfg2 or {}
            N("TextLabel", {
                Size                   = UDim2.new(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Text                   = cfg2.Text  or "",
                Font                   = Enum.Font.Gotham,
                TextSize               = 10,
                TextColor3             = cfg2.Color or C.TextMuted,
                TextWrapped            = true,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = nextN(),
                Parent                 = card,
            })
        end

        ----------------------------------------------------------------
        -- BUTTON
        ----------------------------------------------------------------
        function cAPI:AddButton(cfg2)
            cfg2       = cfg2 or {}
            local lbl4 = cfg2.Label    or "Button"
            local cb   = cfg2.Callback or function() end

            local btn = N("TextButton", {
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = C.BtnBg,
                BorderSizePixel  = 0,
                Text             = lbl4,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 11,
                TextColor3       = C.Accent,
                AutoButtonColor  = false,
                LayoutOrder      = nextN(),
                Parent           = card,
            })
            Cor(btn, 4)

            btn.MouseEnter:Connect(function()
                Tw(btn, {BackgroundColor3 = C.BtnBgHover}, 0.1)
            end)
            btn.MouseLeave:Connect(function()
                Tw(btn, {BackgroundColor3 = C.BtnBg}, 0.1)
            end)
            btn.MouseButton1Down:Connect(function()
                Tw(btn, {BackgroundColor3 = C.BtnBgDown}, 0.08)
            end)
            btn.MouseButton1Up:Connect(function()
                Tw(btn, {BackgroundColor3 = C.BtnBgHover}, 0.08)
            end)
            btn.MouseButton1Click:Connect(cb)
            return {}
        end

        return cAPI
    end -- makeCard

    function tabAPI:AddCard(colNum, title)
        return makeCard(colNum == 1 and col1 or col2, title)
    end
    function tabAPI:Col1() return col1 end
    function tabAPI:Col2() return col2 end

    return tabAPI
end -- catAPI:AddTab

return catAPI

end -- UILib.AddCategory
-- RETURN (loadstring(...)() receives this table)
-- RETURN (loadstring(...)() receives this table)

task.defer(function()
RunService.Heartbeat:Wait()
RunService.Heartbeat:Wait()
BlurredGui.new(blurBacker, "Rectangle")
end)

return UILib
