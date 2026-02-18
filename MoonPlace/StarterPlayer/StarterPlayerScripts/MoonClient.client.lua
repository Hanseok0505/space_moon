local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestTeleportBack = Remotes:WaitForChild("RequestTeleportBack")
local RequestState = Remotes:WaitForChild("RequestState")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))

local THEME = {
  panel = Color3.fromRGB(18, 24, 36),
  accent = Color3.fromRGB(90, 167, 255),
  accentStrong = Color3.fromRGB(255, 190, 90),
  accentGood = Color3.fromRGB(129, 233, 160),
  text = Color3.fromRGB(235, 244, 255),
  warn = Color3.fromRGB(255, 110, 110),
}

local state = {
  cash = 0,
  inventory = {},
  canGoMoon = false,
  equippedShip = "",
  warning = "",
  serverTime = 0,
}

local function stylePanel(panel, color)
  panel.BackgroundColor3 = color
  panel.BorderSizePixel = 0
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 12)
  corner.Parent = panel
  local stroke = Instance.new("UIStroke")
  stroke.Color = Color3.fromRGB(255, 255, 255)
  stroke.Thickness = 1
  stroke.Transparency = 0.75
  stroke.Parent = panel
end

local function styleButton(button, color)
  button.AutoButtonColor = false
  button.BorderSizePixel = 0
  button.BackgroundColor3 = color
  button.TextColor3 = THEME.text
  button.Font = Enum.Font.GothamBold
  button.TextSize = 16
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 8)
  corner.Parent = button
end

local function press(button)
  local fromSize = button.Size
  local down = TweenService:Create(button, TweenInfo.new(0.06), { Size = fromSize - UDim2.new(0, 0, 0, 2) })
  down:Play()
  down.Completed:Wait()
  TweenService:Create(button, TweenInfo.new(0.06), { Size = fromSize }):Play()
end

local function ensureGui()
  local hud = playerGui:FindFirstChild("MoonHUD")
  if hud then
    return hud
  end

  hud = Instance.new("ScreenGui")
  hud.Name = "MoonHUD"
  hud.ResetOnSpawn = false
  hud.IgnoreGuiInset = true
  hud.Parent = playerGui

  local base = Instance.new("Frame")
  base.Name = "Base"
  base.Size = UDim2.new(0, 320, 0, 220)
  base.Position = UDim2.new(0, 14, 0, 14)
  stylePanel(base, THEME.panel)
  base.Parent = hud

  local title = Instance.new("TextLabel")
  title.Name = "Title"
  title.BackgroundTransparency = 1
  title.Size = UDim2.new(1, -16, 0, 32)
  title.Position = UDim2.new(0, 8, 0, 8)
  title.Font = Enum.Font.GothamBold
  title.TextSize = 18
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.TextColor3 = THEME.text
  title.Text = "Lunar Base"
  title.Parent = base

  local cash = Instance.new("TextLabel")
  cash.Name = "Cash"
  cash.BackgroundTransparency = 1
  cash.Size = UDim2.new(1, -16, 0, 20)
  cash.Position = UDim2.new(0, 8, 0, 42)
  cash.TextXAlignment = Enum.TextXAlignment.Left
  cash.Font = Enum.Font.Gotham
  cash.TextSize = 14
  cash.TextColor3 = THEME.text
  cash.Parent = base

  local ship = Instance.new("TextLabel")
  ship.Name = "Ship"
  ship.BackgroundTransparency = 1
  ship.Size = UDim2.new(1, -16, 0, 20)
  ship.Position = UDim2.new(0, 8, 0, 62)
  ship.TextXAlignment = Enum.TextXAlignment.Left
  ship.Font = Enum.Font.Gotham
  ship.TextSize = 14
  ship.TextColor3 = Color3.fromRGB(190, 210, 230)
  ship.Parent = base

  local stateText = Instance.new("TextLabel")
  stateText.Name = "State"
  stateText.BackgroundTransparency = 1
  stateText.Size = UDim2.new(1, -16, 0, 20)
  stateText.Position = UDim2.new(0, 8, 0, 82)
  stateText.TextXAlignment = Enum.TextXAlignment.Left
  stateText.Font = Enum.Font.Gotham
  stateText.TextSize = 14
  stateText.TextColor3 = THEME.text
  stateText.Parent = base

  local inv = Instance.new("TextLabel")
  inv.Name = "Inventory"
  inv.BackgroundTransparency = 1
  inv.Size = UDim2.new(1, -16, 0, 56)
  inv.Position = UDim2.new(0, 8, 0, 104)
  inv.TextXAlignment = Enum.TextXAlignment.Left
  inv.TextYAlignment = Enum.TextYAlignment.Top
  inv.TextWrapped = true
  inv.Font = Enum.Font.Gotham
  inv.TextSize = 13
  inv.TextColor3 = THEME.text
  inv.Text = "Inventory: empty"
  inv.Parent = base

  local returnButton = Instance.new("TextButton")
  returnButton.Name = "ReturnButton"
  returnButton.Text = "Return to Earth"
  returnButton.Size = UDim2.new(0, 140, 0, 34)
  returnButton.Position = UDim2.new(0, 8, 1, -80)
  styleButton(returnButton, THEME.accent)
  returnButton.Parent = base

  local refreshButton = Instance.new("TextButton")
  refreshButton.Name = "RefreshButton"
  refreshButton.Text = "Refresh"
  refreshButton.Size = UDim2.new(0, 130, 0, 34)
  refreshButton.Position = UDim2.new(0, 154, 1, -80)
  styleButton(refreshButton, THEME.accentGood)
  refreshButton.Parent = base

  local warning = Instance.new("TextLabel")
  warning.Name = "Warning"
  warning.BackgroundTransparency = 1
  warning.Size = UDim2.new(1, -16, 0, 32)
  warning.Position = UDim2.new(0, 8, 1, -44)
  warning.Font = Enum.Font.Gotham
  warning.TextSize = 12
  warning.TextWrapped = true
  warning.TextXAlignment = Enum.TextXAlignment.Left
  warning.TextColor3 = THEME.warn
  warning.Text = ""
  warning.Parent = base

  return hud
end

local ui = ensureGui()
local base = ui.Base
local cashLabel = base.Cash
local shipLabel = base.Ship
local stateLabel = base.State
local inventoryLabel = base.Inventory
local warningLabel = base.Warning
local returnButton = base.ReturnButton
local refreshButton = base.RefreshButton

local function formatInventory(invTable)
  local lines = {}
  for name, amount in pairs(invTable or {}) do
    if amount > 0 then
      local label = ItemsConfig.Materials[name] and ItemsConfig.Materials[name].displayName or name
      table.insert(lines, label .. " x" .. tostring(amount))
    end
  end
  if #lines == 0 then
    return "Inventory: empty"
  end
  return "Inventory: " .. table.concat(lines, ", ")
end

local function setWarning(text)
  warningLabel.Text = text or ""
  if text ~= "" then
    local current = text
    task.delay(4, function()
      if warningLabel.Text == current then
        warningLabel.Text = ""
      end
    end)
  end
end

local function renderState(payload)
  payload = payload or {}
  state = {
    cash = tonumber(payload.cash) or state.cash,
    inventory = payload.inventory or state.inventory,
    canGoMoon = payload.canGoMoon == true,
    equippedShip = payload.equippedShip or state.equippedShip,
    warning = payload.warning or "",
    serverTime = tonumber(payload.serverTime) or state.serverTime,
  }

  cashLabel.Text = "Cash: " .. tostring(state.cash)
  shipLabel.Text = "Ship: " .. (state.equippedShip ~= "" and state.equippedShip or "-")
  stateLabel.Text = "Moon Access: " .. (state.canGoMoon and "enabled" or "not enabled")
  inventoryLabel.Text = formatInventory(state.inventory)
  if state.warning and state.warning ~= "" then
    setWarning(state.warning)
  end
end

local function requestState()
  RequestState:FireServer()
end

returnButton.MouseButton1Click:Connect(function()
  press(returnButton)
  setWarning("Requesting return...")
  RequestTeleportBack:FireServer()
end)

refreshButton.MouseButton1Click:Connect(function()
  press(refreshButton)
  requestState()
end)

RequestState.OnClientEvent:Connect(renderState)

task.spawn(function()
  while player.Parent do
    requestState()
    task.wait(6)
  end
end)

task.defer(requestState)
