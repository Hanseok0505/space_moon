-- MoonPlace/ServerScriptService/MoonServer.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not Remotes then
  Remotes = Instance.new("Folder")
  Remotes.Name = "RemoteEvents"
  Remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
  local remote = Remotes:FindFirstChild(name)
  if remote and remote:IsA("RemoteEvent") then
    return remote
  end

  remote = Instance.new("RemoteEvent")
  remote.Name = name
  remote.Parent = Remotes
  return remote
end

local RequestTeleportBack = ensureRemote("RequestTeleportBack")
local RequestState = ensureRemote("RequestState")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local DropRates = require(Shared:WaitForChild("DropRatesConfig"))

local PROFILE_KEY = "SpaceGameProfile_V1"
local ROOT_PLACE_ID = 0 -- set Main place ID here

local function resolveRootPlaceId()
  local attrId = game:GetAttribute("RootPlaceId")
  if typeof(attrId) == "number" and attrId > 0 then
    return math.floor(attrId)
  end
  return ROOT_PLACE_ID
end

local store = DataStoreService:GetDataStore(PROFILE_KEY)
local Profiles = {}

local function pushState(plr, warning)
  local profile = Profiles[plr.UserId]
  if not profile then
    RequestState:FireClient(plr, {
      warning = warning or "Profile not loaded.",
      serverTime = os.time(),
    })
    return
  end

  RequestState:FireClient(plr, {
    cash = profile.Cash or 0,
    inventory = profile.Inventory or {},
    canGoMoon = profile.CanGoMoon == true,
    equippedShip = profile.EquippedShip or "",
    warning = warning or "",
    serverTime = os.time(),
  })
end

local function newLeaderstats(plr)
  local ls = Instance.new("Folder")
  ls.Name = "leaderstats"
  ls.Parent = plr

  local cash = Instance.new("IntValue")
  cash.Name = ItemsConfig.CURRENCY_NAME
  cash.Parent = ls
  return ls
end

local function loadProfile(plr)
  local data
  pcall(function()
    data = store:GetAsync(tostring(plr.UserId))
  end)

  data = data or {Cash = 0, Inventory = {}}
  data.Inventory = data.Inventory or {}
  Profiles[plr.UserId] = data

  local ls = newLeaderstats(plr)
  ls[ItemsConfig.CURRENCY_NAME].Value = data.Cash or 0
  task.defer(pushState, plr)
end

local function saveProfile(plr)
  local profile = Profiles[plr.UserId]
  if not profile then
    return
  end

  pcall(function()
    store:SetAsync(tostring(plr.UserId), profile)
  end)
end

Players.PlayerAdded:Connect(loadProfile)
Players.PlayerRemoving:Connect(function(plr)
  saveProfile(plr)
  Profiles[plr.UserId] = nil
end)
game:BindToClose(function()
  for _, plr in ipairs(Players:GetPlayers()) do
    saveProfile(plr)
  end
end)

local function rr(a, b)
  return math.random(a, b)
end

local function chooseDrops(nodeKey)
  local pool = DropRates[nodeKey]
  if not pool then
    return {}
  end

  local out = {}
  for _, entry in ipairs(pool) do
    if math.random() < (entry.chance or 0) then
      table.insert(out, {
        item = entry.item,
        amount = rr(entry.amount.min, entry.amount.max),
      })
    end
  end
  return out
end

local function createPart(name, color, size, position)
  local part = Instance.new("Part")
  part.Name = name
  part.Anchored = true
  part.CanCollide = true
  part.Size = size
  part.Color = color
  part.Position = position
  part.Parent = Workspace
  return part
end

local function ensureScene()
  if Workspace:FindFirstChild("MoonSceneBuilt") then
    return
  end

  local flag = Instance.new("BoolValue")
  flag.Name = "MoonSceneBuilt"
  flag.Parent = Workspace

  createPart("MoonBase", Color3.fromRGB(200, 200, 200), Vector3.new(200, 2, 200), Vector3.new(0, 0, 0))

  local portal = createPart("ReturnPortal", Color3.fromRGB(0, 170, 255), Vector3.new(8, 10, 1), Vector3.new(0, 6, -80))
  portal.Material = Enum.Material.Neon

  local portalPrompt = Instance.new("ProximityPrompt")
  portalPrompt.ActionText = "귀환(메인)"
  portalPrompt.ObjectText = "포털"
  portalPrompt.HoldDuration = 0
  portalPrompt.Parent = portal
  portalPrompt.Triggered:Connect(function(plr)
    local rootPlaceId = resolveRootPlaceId()
    if rootPlaceId == 0 then
      pushState(plr, "RootPlaceId is not configured.")
      return
    end

    local ok, err = pcall(function()
      TeleportService:TeleportAsync(rootPlaceId, {plr})
    end)
    if not ok then
      pushState(plr, "Return teleport failed: " .. tostring(err))
    end
  end)

  local posList = {
    Vector3.new(-40, 2, 30),
    Vector3.new(20, 2, 40),
    Vector3.new(60, 2, -10),
  }

  for i, pos in ipairs(posList) do
    local node = createPart("LunarNode_" .. i, Color3.fromRGB(240, 240, 240), Vector3.new(6, 6, 6), pos)
    node.Material = Enum.Material.Slate

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "채집"
    prompt.ObjectText = "월면 광물"
    prompt.HoldDuration = 0
    prompt.Parent = node
    prompt.Triggered:Connect(function(plr)
      local profile = Profiles[plr.UserId]
      if not profile then
        return
      end

      for _, drop in ipairs(chooseDrops("LunarNode")) do
        if ItemsConfig.Materials[drop.item] then
          profile.Inventory[drop.item] = (profile.Inventory[drop.item] or 0) + drop.amount
        end
      end

      pushState(plr, "월면 광물을 수집했습니다.")

      prompt.Enabled = false
      task.delay(2, function()
        if prompt.Parent then
          prompt.Enabled = true
        end
      end)
    end)
  end
end
ensureScene()

RequestState.OnServerEvent:Connect(function(plr)
  pushState(plr)
end)

RequestTeleportBack.OnServerEvent:Connect(function(plr)
  local rootPlaceId = resolveRootPlaceId()
  if rootPlaceId == 0 then
    pushState(plr, "RootPlaceId is not configured.")
    return
  end

  local ok, err = pcall(function()
    TeleportService:TeleportAsync(rootPlaceId, {plr})
  end)
  if not ok then
    pushState(plr, "Return teleport failed: " .. tostring(err))
  end
end)
