local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestCraft = Remotes:WaitForChild("RequestCraft")
local RequestPurchaseShip = Remotes:WaitForChild("RequestPurchaseShip")
local RequestEquipShip = Remotes:WaitForChild("RequestEquipShip")
local RequestStartQuiz = Remotes:WaitForChild("RequestStartQuiz")
local SubmitQuizAnswer = Remotes:WaitForChild("SubmitQuizAnswer")
local DonateMuseumItem = Remotes:WaitForChild("DonateMuseumItem")
local RequestTeleportMoon = Remotes:WaitForChild("RequestTeleportMoon")
local GetPlayerState = Remotes:WaitForChild("GetPlayerState")
local RequestMuseumData = Remotes:WaitForChild("RequestMuseumData")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local RecipesConfig = require(Shared:WaitForChild("RecipesConfig"))
local ShipsConfig = require(Shared:WaitForChild("ShipsConfig"))

local THEME = {
  panel = Color3.fromRGB(19, 23, 36),
  panelSoft = Color3.fromRGB(32, 40, 58),
  accent = Color3.fromRGB(90, 167, 255),
  accentStrong = Color3.fromRGB(255, 190, 90),
  accentGood = Color3.fromRGB(129, 233, 160),
  text = Color3.fromRGB(238, 244, 255),
  danger = Color3.fromRGB(255, 120, 120),
}

local state = {
  cash = 0,
  bestQuizScore = 0,
  weeklyQuizScore = 0,
  canGoMoon = false,
  inventory = {},
  ownedShips = {},
  equippedShip = "",
  nextMoonLaunchAt = 0,
  serverTime = 0,
  shipCooldowns = {},
  allShips = ShipsConfig.Tiers,
}

local function stylePanel(panel, color)
  panel.BackgroundColor3 = color
  panel.BorderSizePixel = 0
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 12)
  corner.Parent = panel
  local stroke = Instance.new("UIStroke")
  stroke.Color = Color3.fromRGB(255, 255, 255)
  stroke.Transparency = 0.8
  stroke.Thickness = 1
  stroke.Parent = panel
end

local function styleButton(button, color)
  button.AutoButtonColor = false
  button.BorderSizePixel = 0
  button.BackgroundColor3 = color
  button.TextColor3 = THEME.text
  button.Font = Enum.Font.GothamBold
  button.TextSize = 14
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 8)
  corner.Parent = button

  local enteredColor = Color3.new(
    math.clamp(color.R + 0.14, 0, 1),
    math.clamp(color.G + 0.14, 0, 1),
    math.clamp(color.B + 0.14, 0, 1)
  )
  button.MouseEnter:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { BackgroundColor3 = enteredColor }):Play()
  end)
  button.MouseLeave:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { BackgroundColor3 = color }):Play()
  end)
end

local function createPopup(name, titleText, sizeX, sizeY)
  local rootGui = Instance.new("ScreenGui")
  rootGui.Name = name
  rootGui.ResetOnSpawn = false
  rootGui.IgnoreGuiInset = true
  rootGui.Enabled = false
  rootGui.Parent = playerGui

  local panel = Instance.new("Frame")
  panel.Name = "Root"
  panel.Size = UDim2.new(0, sizeX, 0, sizeY)
  panel.Position = UDim2.new(0.5, -(sizeX / 2), 0.5, -(sizeY / 2))
  panel.Visible = false
  stylePanel(panel, THEME.panelSoft)
  panel.Parent = rootGui

  local grad = Instance.new("UIGradient")
  grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.panelSoft),
    ColorSequenceKeypoint.new(1, THEME.panel),
  })
  grad.Rotation = 90
  grad.Parent = panel

  local title = Instance.new("TextLabel")
  title.Name = "Title"
  title.Size = UDim2.new(1, -20, 0, 30)
  title.Position = UDim2.new(0, 10, 0, 8)
  title.BackgroundTransparency = 1
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.Font = Enum.Font.GothamBold
  title.TextSize = 17
  title.TextColor3 = THEME.text
  title.Text = titleText
  title.Parent = panel

  local close = Instance.new("TextButton")
  close.Name = "CloseBtn"
  close.Text = "X"
  close.Size = UDim2.new(0, 24, 0, 24)
  close.Position = UDim2.new(1, -30, 0, 8)
  close.BackgroundColor3 = THEME.accent
  styleButton(close, THEME.accent)
  close.Parent = panel

  local content = Instance.new("Frame")
  content.Name = "Content"
  content.Size = UDim2.new(1, -20, 1, -56)
  content.Position = UDim2.new(0, 10, 0, 44)
  content.BackgroundTransparency = 1
  content.Parent = panel

  return rootGui, panel, close, content
end

local function ensureGui()
  local hud = playerGui:FindFirstChild("MainHUD")
  if hud then
    return hud
  end

  hud = Instance.new("ScreenGui")
  hud.Name = "MainHUD"
  hud.ResetOnSpawn = false
  hud.IgnoreGuiInset = true
  hud.Parent = playerGui

  local base = Instance.new("Frame")
  base.Name = "Base"
  base.Size = UDim2.new(0, 360, 0, 275)
  base.Position = UDim2.new(0, 14, 0, 14)
  base.BorderSizePixel = 0
  stylePanel(base, THEME.panel)
  base.Parent = hud

  local grad = Instance.new("UIGradient")
  grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.panel),
    ColorSequenceKeypoint.new(1, THEME.panelSoft),
  })
  grad.Rotation = 90
  grad.Parent = base

  local title = Instance.new("TextLabel")
  title.Name = "Title"
  title.Size = UDim2.new(1, -20, 0, 30)
  title.Position = UDim2.new(0, 10, 0, 8)
  title.BackgroundTransparency = 1
  title.Font = Enum.Font.GothamBold
  title.TextSize = 19
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.Text = "Space Moon - Earth Control"
  title.TextColor3 = THEME.text
  title.Parent = base

  local cash = Instance.new("TextLabel")
  cash.Name = "Cash"
  cash.Text = "Cash: 0"
  cash.BackgroundTransparency = 1
  cash.TextXAlignment = Enum.TextXAlignment.Left
  cash.Font = Enum.Font.Gotham
  cash.TextSize = 14
  cash.TextColor3 = THEME.text
  cash.Size = UDim2.new(1, -20, 0, 20)
  cash.Position = UDim2.new(0, 10, 0, 44)
  cash.Parent = base

  local quiz = Instance.new("TextLabel")
  quiz.Name = "Quiz"
  quiz.Text = "Quiz: 0 / Week: 0"
  quiz.BackgroundTransparency = 1
  quiz.TextXAlignment = Enum.TextXAlignment.Left
  quiz.Font = Enum.Font.Gotham
  quiz.TextSize = 14
  quiz.TextColor3 = THEME.text
  quiz.Size = UDim2.new(1, -20, 0, 20)
  quiz.Position = UDim2.new(0, 10, 0, 64)
  quiz.Parent = base

  local ship = Instance.new("TextLabel")
  ship.Name = "Ship"
  ship.Text = "Ship: -"
  ship.BackgroundTransparency = 1
  ship.TextXAlignment = Enum.TextXAlignment.Left
  ship.Font = Enum.Font.Gotham
  ship.TextSize = 14
  ship.TextColor3 = THEME.text
  ship.Size = UDim2.new(1, -20, 0, 20)
  ship.Position = UDim2.new(0, 10, 0, 84)
  ship.Parent = base

  local moon = Instance.new("TextLabel")
  moon.Name = "Moon"
  moon.Text = "Moon: Not unlocked"
  moon.BackgroundTransparency = 1
  moon.TextXAlignment = Enum.TextXAlignment.Left
  moon.Font = Enum.Font.Gotham
  moon.TextSize = 14
  moon.TextColor3 = THEME.text
  moon.Size = UDim2.new(1, -20, 0, 20)
  moon.Position = UDim2.new(0, 10, 0, 104)
  moon.Parent = base

  local inv = Instance.new("TextLabel")
  inv.Name = "Inventory"
  inv.Text = "Inventory: empty"
  inv.BackgroundTransparency = 1
  inv.TextWrapped = true
  inv.TextXAlignment = Enum.TextXAlignment.Left
  inv.TextYAlignment = Enum.TextYAlignment.Top
  inv.Font = Enum.Font.Gotham
  inv.TextSize = 13
  inv.TextColor3 = THEME.text
  inv.Size = UDim2.new(1, -20, 0, 52)
  inv.Position = UDim2.new(0, 10, 0, 124)
  inv.Parent = base

  local actions = Instance.new("Frame")
  actions.Name = "Actions"
  actions.Size = UDim2.new(1, -20, 0, 72)
  actions.Position = UDim2.new(0, 10, 1, -74)
  actions.BackgroundTransparency = 1
  actions.Parent = base
  local layout = Instance.new("UIGridLayout")
  layout.CellPadding = UDim2.new(0, 8, 0, 8)
  layout.CellSize = UDim2.new(0.5, -4, 0, 30)
  layout.FillDirection = Enum.FillDirection.Horizontal
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Parent = actions

  local quizBtn = Instance.new("TextButton")
  quizBtn.Name = "QuizButton"
  quizBtn.Text = "Quiz"
  quizBtn.LayoutOrder = 1
  styleButton(quizBtn, THEME.accent)
  quizBtn.Parent = actions

  local shopBtn = Instance.new("TextButton")
  shopBtn.Name = "ShopButton"
  shopBtn.Text = "Shop/Fleet"
  shopBtn.LayoutOrder = 2
  styleButton(shopBtn, THEME.accent)
  shopBtn.Parent = actions

  local museumBtn = Instance.new("TextButton")
  museumBtn.Name = "MuseumButton"
  museumBtn.Text = "Museum"
  museumBtn.LayoutOrder = 3
  styleButton(museumBtn, THEME.accentGood)
  museumBtn.Parent = actions

  local moonBtn = Instance.new("TextButton")
  moonBtn.Name = "MoonButton"
  moonBtn.Text = "Go to Moon"
  moonBtn.LayoutOrder = 4
  styleButton(moonBtn, THEME.accentStrong)
  moonBtn.Parent = actions

  local toast = Instance.new("TextLabel")
  toast.Name = "Toast"
  toast.Text = ""
  toast.BackgroundTransparency = 1
  toast.TextXAlignment = Enum.TextXAlignment.Left
  toast.TextWrapped = true
  toast.Font = Enum.Font.Gotham
  toast.TextSize = 12
  toast.TextColor3 = THEME.text
  toast.Size = UDim2.new(1, -20, 0, 18)
  toast.Position = UDim2.new(0, 10, 0, 252)
  toast.Parent = base

  local quizPanel, quizRoot, quizClose, quizContent = createPopup("QuizUI", "Quiz", 420, 190)
  local qText = Instance.new("TextLabel")
  qText.Name = "Question"
  qText.BackgroundTransparency = 1
  qText.TextWrapped = true
  qText.TextXAlignment = Enum.TextXAlignment.Left
  qText.Text = ""
  qText.Font = Enum.Font.Gotham
  qText.TextSize = 16
  qText.TextColor3 = THEME.text
  qText.Size = UDim2.new(1, 0, 0, 52)
  qText.Parent = quizContent
  local qAnswer = Instance.new("TextBox")
  qAnswer.Name = "Answer"
  qAnswer.PlaceholderText = "Type answer"
  qAnswer.Size = UDim2.new(1, 0, 0, 34)
  qAnswer.Position = UDim2.new(0, 0, 0, 62)
  qAnswer.BackgroundColor3 = THEME.panel
  qAnswer.BorderSizePixel = 0
  qAnswer.Font = Enum.Font.Gotham
  qAnswer.TextColor3 = THEME.text
  qAnswer.TextSize = 16
  stylePanel(qAnswer, THEME.panel)
  qAnswer.Parent = quizContent
  local qSubmit = Instance.new("TextButton")
  qSubmit.Name = "Submit"
  qSubmit.Text = "Submit"
  qSubmit.Size = UDim2.new(0, 90, 0, 34)
  qSubmit.Position = UDim2.new(0, 0, 0, 102)
  styleButton(qSubmit, THEME.accent)
  qSubmit.Parent = quizContent
  local qResult = Instance.new("TextLabel")
  qResult.Name = "Result"
  qResult.BackgroundTransparency = 1
  qResult.TextXAlignment = Enum.TextXAlignment.Left
  qResult.TextWrapped = true
  qResult.Size = UDim2.new(1, 0, 0, 36)
  qResult.Position = UDim2.new(0, 0, 0, 144)
  qResult.Font = Enum.Font.Gotham
  qResult.TextSize = 14
  qResult.TextColor3 = THEME.text
  qResult.Text = ""
  qResult.Parent = quizContent

  local shopPanel, shopRoot, shopClose, shopContent = createPopup("ShopUI", "Ship Shop", 420, 380)
  local shipListHeader = Instance.new("TextLabel")
  shipListHeader.Name = "ShipHeader"
  shipListHeader.BackgroundTransparency = 1
  shipListHeader.TextXAlignment = Enum.TextXAlignment.Left
  shipListHeader.Font = Enum.Font.GothamBold
  shipListHeader.TextSize = 14
  shipListHeader.TextColor3 = THEME.text
  shipListHeader.Text = "Fleet"
  shipListHeader.Size = UDim2.new(1, 0, 0, 22)
  shipListHeader.Parent = shopContent
  local shipSection = Instance.new("ScrollingFrame")
  shipSection.Name = "ShipsSection"
  shipSection.ScrollBarThickness = 0
  shipSection.BackgroundTransparency = 1
  shipSection.Size = UDim2.new(1, 0, 0, 140)
  shipSection.Position = UDim2.new(0, 0, 0, 22)
  shipSection.CanvasSize = UDim2.new(0, 0, 0, 0)
  shipSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
  shipSection.Parent = shopContent
  local shipSectionLayout = Instance.new("UIListLayout")
  shipSectionLayout.Padding = UDim2.new(0, 6)
  shipSectionLayout.FillDirection = Enum.FillDirection.Vertical
  shipSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
  shipSectionLayout.Parent = shipSection

  local recipeHeader = Instance.new("TextLabel")
  recipeHeader.Name = "RecipeHeader"
  recipeHeader.BackgroundTransparency = 1
  recipeHeader.TextXAlignment = Enum.TextXAlignment.Left
  recipeHeader.Font = Enum.Font.GothamBold
  recipeHeader.TextSize = 14
  recipeHeader.TextColor3 = THEME.text
  recipeHeader.Text = "Crafting"
  recipeHeader.Position = UDim2.new(0, 0, 0, 164)
  recipeHeader.Size = UDim2.new(1, 0, 0, 22)
  recipeHeader.Parent = shopContent
  local recipeSection = Instance.new("ScrollingFrame")
  recipeSection.Name = "RecipesSection"
  recipeSection.ScrollBarThickness = 0
  recipeSection.BackgroundTransparency = 1
  recipeSection.Size = UDim2.new(1, 0, 1, -186)
  recipeSection.Position = UDim2.new(0, 0, 0, 184)
  recipeSection.CanvasSize = UDim2.new(0, 0, 0, 0)
  recipeSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
  recipeSection.Parent = shopContent
  local recipeSectionLayout = Instance.new("UIListLayout")
  recipeSectionLayout.Padding = UDim2.new(0, 6)
  recipeSectionLayout.FillDirection = Enum.FillDirection.Vertical
  recipeSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
  recipeSectionLayout.Parent = recipeSection

  local museumPanel, museumRoot, museumClose, museumContent = createPopup("MuseumUI", "Museum", 420, 320)
  local museumList = Instance.new("TextLabel")
  museumList.Name = "Exhibit"
  museumList.Text = "No exhibit yet."
  museumList.BackgroundTransparency = 1
  museumList.TextXAlignment = Enum.TextXAlignment.Left
  museumList.TextYAlignment = Enum.TextYAlignment.Top
  museumList.TextWrapped = true
  museumList.Font = Enum.Font.Gotham
  museumList.TextSize = 14
  museumList.TextColor3 = THEME.text
  museumList.Size = UDim2.new(1, 0, 0, 150)
  museumList.Parent = museumContent
  local museumBtns = Instance.new("Frame")
  museumBtns.Name = "DonateButtons"
  museumBtns.BackgroundTransparency = 1
  museumBtns.Position = UDim2.new(0, 0, 0, 160)
  museumBtns.Size = UDim2.new(1, 0, 0, 130)
  museumBtns.Parent = museumContent
  local museumGrid = Instance.new("UIGridLayout")
  museumGrid.CellPadding = UDim2.new(0, 8, 0, 8)
  museumGrid.CellSize = UDim2.new(0.5, -8, 0, 32)
  museumGrid.FillDirection = Enum.FillDirection.Horizontal
  museumGrid.SortOrder = Enum.SortOrder.LayoutOrder
  museumGrid.Parent = museumBtns

  local donateLunar = Instance.new("TextButton")
  donateLunar.Name = "DonateLunar"
  donateLunar.Text = "Donate Lunar Sample x1"
  styleButton(donateLunar, THEME.accentStrong)
  donateLunar.Parent = museumBtns
  local donateTitanium = Instance.new("TextButton")
  donateTitanium.Name = "DonateTitanium"
  donateTitanium.Text = "Donate Titanium Ore x1"
  styleButton(donateTitanium, THEME.accentStrong)
  donateTitanium.Parent = museumBtns

  return {
    hud = hud,
    base = base,
    toast = toast,
    labels = {
      cash = cash,
      quiz = quiz,
      ship = ship,
      moon = moon,
      inventory = inv,
    },
    actions = {
      quiz = quizBtn,
      shop = shopBtn,
      museum = museumBtn,
      moon = moonBtn,
    },
    quiz = {
      gui = quizPanel,
      root = quizRoot,
      close = quizClose,
      question = qText,
      answer = qAnswer,
      submit = qSubmit,
      result = qResult,
    },
    shop = {
      gui = shopPanel,
      root = shopRoot,
      close = shopClose,
      shipSection = shipSection,
      recipeSection = recipeSection,
      shipListHeader = shipListHeader,
      recipeHeader = recipeHeader,
    },
    museum = {
      gui = museumPanel,
      root = museumRoot,
      close = museumClose,
      list = museumList,
      donateLunar = donateLunar,
      donateTitanium = donateTitanium,
    },
  }
end

local ui = ensureGui()

local function requestState()
  GetPlayerState:FireServer()
end

local function formatInventory(invTable)
  local lines = {}
  for name, amount in pairs(invTable or {}) do
    if amount > 0 then
      local display = ItemsConfig.Materials[name] and ItemsConfig.Materials[name].displayName or name
      table.insert(lines, display .. " x" .. tostring(amount))
    end
  end
  if #lines == 0 then
    return "Inventory: empty"
  end
  return "Inventory: " .. table.concat(lines, ", ")
end

local function ownShip(profileState, shipId)
  return table.find(profileState.ownedShips or {}, shipId) ~= nil
end

local function getShipConfigById(shipId)
  for _, ship in ipairs(state.allShips) do
    if ship.id == shipId then
      return ship
    end
  end
  return nil
end

local function formatCooldown(seconds)
  seconds = tonumber(seconds) or 0
  if seconds <= 0 then
    return 0
  end
  return math.ceil(seconds)
end

local function getPadCooldownLeft(shipId)
  local padReadyAt = tonumber(state.shipCooldowns[shipId]) or 0
  local remain = padReadyAt - (state.serverTime or os.time())
  return formatCooldown(remain)
end

local function getCooldownLeft(shipId)
  local personalRemain = (state.nextMoonLaunchAt or 0) - (state.serverTime or os.time())
  if shipId then
    local padRemain = getPadCooldownLeft(shipId)
    personalRemain = math.max(personalRemain, padRemain)
  end
  if personalRemain > 0 then
    return math.max(0, math.ceil(personalRemain))
  end
  return 0
end

local toastToken = 0
local function toast(text, isError)
  ui.toast.Text = text or ""
  ui.toast.TextColor3 = isError and THEME.danger or THEME.accentGood
  toastToken += 1
  local token = toastToken
  if text and text ~= "" then
    task.delay(4, function()
      if token == toastToken then
        ui.toast.Text = ""
      end
    end)
  end
end

local function prettyServerError(code)
  local map = {
    NEED_MORE_CASH = "Need more cash.",
    NEED_ITEMS = "Required materials are not enough.",
    NOT_FOUND = "Ship was not found.",
    NOT_OWNED = "You don't own this ship.",
    INVALID_SHIP = "Invalid ship.",
    INVALID_SHIP_ID = "Invalid ship selection.",
  }
  return map[code] or tostring(code)
end

local function openPanel(panel, open)
  panel.gui.Enabled = open
  panel.root.Visible = open
  if not open then
    return
  end
  panel.root.Visible = true
  panel.root.Size = UDim2.new(0, panel.root.Size.X.Offset, 0, panel.root.Size.Y.Offset)
  TweenService:Create(
    panel.root,
    TweenInfo.new(0.12, Enum.EasingStyle.Quad),
    { Size = panel.root.Size }
  ):Play()
end

local function clearSection(frame)
  for _, child in ipairs(frame:GetChildren()) do
    if child:IsA("UIListLayout") then
      continue
    end
    child:Destroy()
  end
end

local function addShipRow(ship, layoutOrder)
  local row = Instance.new("Frame")
  row.Name = "ShipRow_" .. ship.id
  row.Size = UDim2.new(1, 0, 0, 34)
  row.LayoutOrder = layoutOrder
  row.BackgroundTransparency = 1
  row.Parent = ui.shop.shipSection

  local padRemain = getPadCooldownLeft(ship.id)
  local stateText = ship.canGoMoon and "Moon access" or "Earth only"
  if padRemain > 0 then
    stateText = "Dock busy " .. tostring(padRemain) .. "s"
  end

  local info = Instance.new("TextLabel")
  info.BackgroundTransparency = 1
  info.TextXAlignment = Enum.TextXAlignment.Left
  info.Font = Enum.Font.Gotham
  info.TextSize = 13
  info.TextColor3 = THEME.text
  info.Text = string.format("%s | speed %s | cargo %s | %s", ship.id, tostring(ship.speed or 0), tostring(ship.cargo or 0), stateText)
  info.Size = UDim2.new(0.62, 0, 1, 0)
  info.Parent = row

  local button = Instance.new("TextButton")
  button.Size = UDim2.new(0.36, 0, 1, 0)
  button.Position = UDim2.new(0.64, 0, 0, 0)
  button.Parent = row

  if ownShip(state, ship.id) then
    button.Text = state.equippedShip == ship.id and "Equipped" or "Equip"
    styleButton(button, THEME.accentGood)
    if state.equippedShip == ship.id then
      button.Active = false
    else
      button.MouseButton1Click:Connect(function()
        RequestEquipShip:FireServer(ship.id)
      end)
    end
  else
    local canBuy = true
    local need = ship.need or {}
    for itemName, amount in pairs(need) do
      if (state.inventory[itemName] or 0) < (amount or 0) then
        canBuy = false
        break
      end
    end
    local price = tonumber(ship.price) or 0
    if state.cash < price then
      canBuy = false
    end

    if canBuy then
      button.Text = "Buy " .. tostring(price)
      styleButton(button, THEME.accent)
    else
      button.Text = "Need items/cash"
      styleButton(button, Color3.fromRGB(102, 110, 126))
      button.Active = false
    end
    button.MouseButton1Click:Connect(function()
      if not canBuy then
        toast("Not enough materials or cash for " .. ship.id, true)
        return
      end
      RequestPurchaseShip:FireServer(ship.id)
    end)
  end
end

local function addRecipeRow(recipeName, recipe, layoutOrder)
  local row = Instance.new("Frame")
  row.Name = "RecipeRow_" .. recipeName
  row.Size = UDim2.new(1, 0, 0, 38)
  row.LayoutOrder = layoutOrder
  row.BackgroundTransparency = 1
  row.Parent = ui.shop.recipeSection

  local text = Instance.new("TextLabel")
  text.BackgroundTransparency = 1
  text.TextXAlignment = Enum.TextXAlignment.Left
  text.TextWrapped = true
  text.Font = Enum.Font.Gotham
  text.TextSize = 13
  text.TextColor3 = THEME.text
  text.Size = UDim2.new(0.66, 0, 1, 0)
  local gives = {}
  for item, amount in pairs(recipe.gives or {}) do
    table.insert(gives, item .. " +" .. tostring(amount))
  end
  local need = {}
  for item, amount in pairs(recipe.cost or {}) do
    table.insert(need, item .. " " .. tostring(amount))
  end
  text.Text = string.format("%s", recipeName) .. "\nNeed: " .. (next(need) and table.concat(need, ", ") or "none") .. " / Gain: " .. (next(gives) and table.concat(gives, ", ") or "none")
  text.Parent = row

  local button = Instance.new("TextButton")
  button.Size = UDim2.new(0.32, 0, 1, 0)
  button.Position = UDim2.new(0.68, 0, 0, 0)
  button.Text = "Craft (" .. tostring(recipe.cashCost or 0) .. ")"
  styleButton(button, THEME.accent)
  button.Parent = row
  button.MouseButton1Click:Connect(function()
    RequestCraft:FireServer(recipeName)
  end)
end

local function renderShop()
  clearSection(ui.shop.shipSection)
  clearSection(ui.shop.recipeSection)
  for idx, ship in ipairs(ShipsConfig.Tiers) do
    addShipRow(ship, idx)
  end
  local rIdx = 1
  for recipeName, recipe in pairs(RecipesConfig) do
    addRecipeRow(recipeName, recipe, rIdx)
    rIdx += 1
  end
end

local function renderState(payload)
  payload = payload or {}
  state = {
    cash = tonumber(payload.cash) or state.cash,
    bestQuizScore = tonumber(payload.bestQuizScore) or state.bestQuizScore,
    weeklyQuizScore = tonumber(payload.weeklyQuizScore) or state.weeklyQuizScore,
    canGoMoon = payload.canGoMoon == true,
    inventory = payload.inventory or state.inventory,
    ownedShips = payload.ownedShips or state.ownedShips,
    equippedShip = payload.equippedShip or state.equippedShip,
    nextMoonLaunchAt = tonumber(payload.nextMoonLaunchAt) or 0,
    serverTime = tonumber(payload.serverTime) or os.time(),
    allShips = payload.allShips or state.allShips,
    shipCooldowns = payload.shipCooldowns or state.shipCooldowns,
  }

  ui.labels.cash.Text = "Cash: " .. tostring(state.cash)
  ui.labels.quiz.Text = "Quiz: " .. tostring(state.bestQuizScore) .. " / Week: " .. tostring(state.weeklyQuizScore)
  ui.labels.ship.Text = "Ship: " .. (state.equippedShip ~= "" and state.equippedShip or "none")
  ui.labels.moon.Text = "Moon: " .. (state.canGoMoon and "Unlocked" or "Not unlocked")
  ui.labels.inventory.Text = formatInventory(state.inventory)

  local selectedShipCfg = getShipConfigById(state.equippedShip)
  local canLaunch = selectedShipCfg and selectedShipCfg.canGoMoon == true
  local cooldown = getCooldownLeft(state.equippedShip)
  if not canLaunch then
    ui.actions.moon.Text = "Go to Moon (Select moon ship)"
    ui.actions.moon.Active = false
  elseif cooldown > 0 then
    ui.actions.moon.Active = false
    ui.actions.moon.Text = "Go to Moon (wait " .. tostring(cooldown) .. "s)"
  else
    ui.actions.moon.Active = true
    ui.actions.moon.Text = "Go to Moon"
  end

  if payload.warning then
    toast(payload.warning, true)
  end

  renderShop()
end

GetPlayerState.OnClientEvent:Connect(function(payload)
  renderState(payload or {})
end)

RequestMuseumData.OnClientEvent:Connect(function(exhibits)
  local entries = {}
  for item, amount in pairs(exhibits or {}) do
    local label = ItemsConfig.Materials[item] and ItemsConfig.Materials[item].displayName or item
    table.insert(entries, label .. " x" .. tostring(amount))
  end
  ui.museum.list.Text = (#entries == 0 and "No exhibit yet." or table.concat(entries, "\n"))
end)

RequestStartQuiz.OnClientEvent:Connect(function(question)
  ui.quiz.question.Text = question or "No quiz available."
  ui.quiz.result.Text = ""
end)

SubmitQuizAnswer.OnClientEvent:Connect(function(correct, answer)
  ui.quiz.result.Text = correct and "Correct!" or ("Wrong. Correct: " .. tostring(answer))
  ui.quiz.result.TextColor3 = correct and THEME.accentGood or THEME.danger
  requestState()
end)

RequestTeleportMoon.OnClientEvent:Connect(function(success, message)
  if message and message ~= "" then
    toast(message, not success)
  end
end)

RequestPurchaseShip.OnClientEvent:Connect(function(success, shipId)
  if success then
    toast("Purchased: " .. tostring(shipId), false)
    requestState()
  else
    toast("Purchase failed: " .. prettyServerError(shipId), true)
  end
end)

RequestEquipShip.OnClientEvent:Connect(function(success, shipId)
  if success then
    toast("Equipped: " .. tostring(shipId), false)
    requestState()
  else
    toast("Equip failed: " .. prettyServerError(shipId), true)
  end
end)

ui.actions.quiz.MouseButton1Click:Connect(function()
  openPanel(ui.quiz, true)
  RequestStartQuiz:FireServer()
end)

ui.actions.shop.MouseButton1Click:Connect(function()
  renderShop()
  openPanel(ui.shop, true)
end)

ui.actions.museum.MouseButton1Click:Connect(function()
  RequestMuseumData:FireServer()
  openPanel(ui.museum, true)
end)

ui.actions.moon.MouseButton1Click:Connect(function()
  if not ui.actions.moon.Active then
    toast("Cannot launch now. Select moon-capable ship and wait for cooldown.", true)
    return
  end
  if getCooldownLeft(state.equippedShip) > 0 then
    toast("Launch cooldown is active.", true)
    return
  end
  RequestTeleportMoon:FireServer(state.equippedShip)
end)

ui.quiz.close.MouseButton1Click:Connect(function()
  openPanel(ui.quiz, false)
end)
ui.shop.close.MouseButton1Click:Connect(function()
  openPanel(ui.shop, false)
end)
ui.museum.close.MouseButton1Click:Connect(function()
  openPanel(ui.museum, false)
end)

ui.quiz.submit.MouseButton1Click:Connect(function()
  SubmitQuizAnswer:FireServer(ui.quiz.answer.Text or "")
end)

ui.museum.donateLunar.MouseButton1Click:Connect(function()
  DonateMuseumItem:FireServer("LunarSample", 1)
end)
ui.museum.donateTitanium.MouseButton1Click:Connect(function()
  DonateMuseumItem:FireServer("TitaniumOre", 1)
end)

task.spawn(function()
  while player.Parent do
    requestState()
    task.wait(4)
  end
end)
task.defer(function()
  requestState()
  renderShop()
end)
