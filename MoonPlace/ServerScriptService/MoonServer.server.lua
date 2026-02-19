local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

-- RemoteEvents setup
local remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remotesFolder then
  remotesFolder = Instance.new("Folder")
  remotesFolder.Name = "RemoteEvents"
  remotesFolder.Parent = ReplicatedStorage
end

if not remotesFolder:FindFirstChild("RequestTeleportBack") then
  local remote = Instance.new("RemoteEvent")
  remote.Name = "RequestTeleportBack"
  remote.Parent = remotesFolder
end
if not remotesFolder:FindFirstChild("RequestState") then
  local remote = Instance.new("RemoteEvent")
  remote.Name = "RequestState"
  remote.Parent = remotesFolder
end

local Remotes = remotesFolder
local RequestTeleportBack = Remotes:WaitForChild("RequestTeleportBack")
local RequestState = Remotes:WaitForChild("RequestState")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local DropRatesConfig = require(Shared:WaitForChild("DropRatesConfig"))
local PlaceConfigModule = Shared:FindFirstChild("PlaceConfig")

local PROFILE_KEY = "SpaceGameProfile_V1"
local DEFAULT_SHIP_ID = "Scout-I"

local function resolveRootPlaceId()
  local attrRoot = tonumber(game:GetAttribute("ROOT_PLACE_ID"))
  if attrRoot and attrRoot > 0 then
    return attrRoot
  end
  local attrReplicated = tonumber(ReplicatedStorage:GetAttribute("ROOT_PLACE_ID"))
  if attrReplicated and attrReplicated > 0 then
    return attrReplicated
  end
  if PlaceConfigModule and PlaceConfigModule:IsA("ModuleScript") then
    local ok, cfg = pcall(require, PlaceConfigModule)
    if ok and type(cfg) == "table" then
      return tonumber(cfg.ROOT_PLACE_ID) or 0
    end
  end
  return 0
end

local ROOT_PLACE_ID = resolveRootPlaceId()

local FALLBACK_SPAWN_NAME = "MoonSpawnPoint"
local FALLBACK_SPAWN_SIZE = Vector3.new(10, 1, 10)
local FALLBACK_SPAWN_POS = Vector3.new(0, 2, -65)

local SYNC_INTERVAL = 6
local NODE_COOLDOWN_SECONDS = 3

local store = DataStoreService:GetDataStore(PROFILE_KEY)
local Profiles = {}
local nodeCooldowns = {}

local function cloneTable(source)
  local out = {}
  for k, v in pairs(source or {}) do
    out[k] = v
  end
  return out
end

local function normalizeInventory(raw)
  local inventory = {}
  for materialName, _ in pairs(ItemsConfig.Materials) do
    local value = raw and raw[materialName] or 0
    inventory[materialName] = math.max(0, math.floor(tonumber(value) or 0))
  end
  return inventory
end

local function getShipConfig(shipId)
  if shipId ~= DEFAULT_SHIP_ID then
    -- Keep profile backward compatible even when ship configs are not yet present in memory.
    local moonModule = ReplicatedStorage:FindFirstChild("Shared")
    if moonModule then
      local shipsMod = moonModule:FindFirstChild("ShipsConfig")
      if shipsMod then
        local ok, shipsCfg = pcall(require, shipsMod)
        if ok and type(shipsCfg) == "table" then
          for _, ship in ipairs(shipsCfg.Tiers or {}) do
            if ship.id == shipId then
              return ship
            end
          end
        end
      end
    end
  else
    return { id = DEFAULT_SHIP_ID, canGoMoon = false }
  end
  return nil
end

local function sanitizeProfile(data)
  data = (type(data) == "table") and data or {}
  local owned = {}
  if type(data.OwnedShips) == "table" then
    for _, ship in ipairs(data.OwnedShips) do
      if type(ship) == "string" and (ship == DEFAULT_SHIP_ID or getShipConfig(ship)) then
        table.insert(owned, ship)
      end
    end
  end
  if #owned == 0 then
    table.insert(owned, DEFAULT_SHIP_ID)
  end

  local equipped = data.EquippedShip
  if type(equipped) ~= "string" or not table.find(owned, equipped) then
    equipped = owned[1]
  end

  return {
    Cash = math.max(0, math.floor(tonumber(data.Cash) or 250)),
    Inventory = normalizeInventory(data.Inventory),
    OwnedShips = owned,
    BestQuizScore = math.max(0, math.floor(tonumber(data.BestQuizScore) or 0)),
    WeeklyQuizScore = math.max(0, math.floor(tonumber(data.WeeklyQuizScore) or 0)),
    LastWeekNumber = tonumber(data.LastWeekNumber) or 0,
    EquippedShip = equipped,
    CanGoMoon = data.CanGoMoon == true,
    NextMoonLaunchAt = tonumber(data.NextMoonLaunchAt) or 0,
  }
end

local function playerForClient(profile)
  return {
    cash = profile.Cash,
    canGoMoon = profile.CanGoMoon == true,
    inventory = cloneTable(profile.Inventory),
    ownedShips = cloneTable(profile.OwnedShips),
    equippedShip = profile.EquippedShip,
    nextMoonLaunchAt = profile.NextMoonLaunchAt or 0,
    serverTime = os.time(),
  }
end

local function saveProfile(player)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  pcall(function()
    store:SetAsync(tostring(player.UserId), profile)
  end)
end

local function sendState(player, warning)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end

  local payload = playerForClient(profile)
  if warning and warning ~= "" then
    payload.warning = warning
  end
  RequestState:FireClient(player, payload)
end

local function createPart(name, color, size, position)
  local p = Instance.new("Part")
  p.Name = name
  p.Anchored = true
  p.CanCollide = true
  p.Size = size
  p.Color = color
  p.Position = position
  p.Material = Enum.Material.Slate
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p.Parent = Workspace
  return p
end

local function pickDrops(poolName)
  local pool = DropRatesConfig[poolName]
  if not pool then
    return {}
  end

  local drops = {}
  for _, entry in ipairs(pool) do
    if math.random() < (entry.chance or 0) then
      local amount = math.random(math.floor((entry.amount and entry.amount.min) or 1), math.floor((entry.amount and entry.amount.max) or 1))
      if amount > 0 and ItemsConfig.Materials[entry.item] then
        table.insert(drops, {
          item = entry.item,
          amount = amount,
        })
      end
    end
  end
  return drops
end

local function ensureMoonSpawnPoint()
  local existing = Workspace:FindFirstChild(FALLBACK_SPAWN_NAME)
  if existing and existing:IsA("SpawnLocation") then
    return existing
  end

  local spawn = Instance.new("SpawnLocation")
  spawn.Name = FALLBACK_SPAWN_NAME
  spawn.Size = FALLBACK_SPAWN_SIZE
  spawn.CFrame = CFrame.new(FALLBACK_SPAWN_POS)
  spawn.Anchored = true
  spawn.CanCollide = true
  spawn.CanTouch = false
  spawn.Transparency = 1
  spawn.Neutral = true
  spawn.Enabled = true
  spawn.Archivable = false
  spawn.Parent = Workspace

  return spawn
end

local function applyCharacterGrounding(character)
  if not character then
    return
  end

  local spawnPoint = ensureMoonSpawnPoint()
  local hrp = character:WaitForChild("HumanoidRootPart", 3)
  if not hrp then
    return
  end

  local targetY = spawnPoint.Position.Y + (spawnPoint.Size.Y / 2) + 2
  local targetCFrame = CFrame.new(spawnPoint.Position.X, targetY, spawnPoint.Position.Z)

  pcall(function()
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
  end)
  pcall(function()
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
  end)

  hrp.CFrame = targetCFrame
end

local function bindCharacterAdded(player)
  player.CharacterAdded:Connect(function(character)
    task.defer(function()
      applyCharacterGrounding(character)
    end)
  end)
end

local function ensureScene()
  if Workspace:FindFirstChild("MoonSceneBuilt") then
    return
  end

  local flag = Instance.new("BoolValue")
  flag.Name = "MoonSceneBuilt"
  flag.Parent = Workspace

  local base = createPart("MoonBase", Color3.fromRGB(177, 183, 195), Vector3.new(220, 2, 220), Vector3.new(0, 0, 0))
  local dock = createPart("MoonDock", Color3.fromRGB(115, 124, 133), Vector3.new(30, 2, 30), Vector3.new(0, 2, -65))
  dock.Material = Enum.Material.Neon

  local returnPortal = createPart("ReturnPortal", Color3.fromRGB(0, 122, 255), Vector3.new(8, 10, 2), Vector3.new(0, 6, -78))
  returnPortal.Material = Enum.Material.Neon
  local returnPrompt = Instance.new("ProximityPrompt")
  returnPrompt.Name = "ReturnPrompt"
  returnPrompt.ActionText = "Return to Earth"
  returnPrompt.ObjectText = "Moon Return Portal"
  returnPrompt.HoldDuration = 0
  returnPrompt.Parent = returnPortal
  returnPrompt.Triggered:Connect(function(player)
    if ROOT_PLACE_ID == 0 then
      sendState(player, "Set ROOT_PLACE_ID in MoonPlace/ReplicatedStorage/Shared/PlaceConfig.lua")
      return
    end

    local data = Profiles[player.UserId]
    if not data then
      return
    end
    saveProfile(player)
    local ok, err = pcall(function()
      TeleportService:TeleportAsync(ROOT_PLACE_ID, { player })
    end)
    if not ok then
      sendState(player, "Return failed: " .. tostring(err))
    end
  end)

  local nodes = {
    { position = Vector3.new(-40, 3, 30), name = "LunarNodeNorth" },
    { position = Vector3.new(20, 3, 35), name = "LunarNodeEast" },
    { position = Vector3.new(55, 3, -12), name = "LunarNodeWest" },
  }
  for _, data in ipairs(nodes) do
    local node = createPart(data.name, Color3.fromRGB(138, 147, 157), Vector3.new(6, 6, 6), data.position)
    node.Name = data.name
    node.Material = Enum.Material.Slate
    node.TopSurface = Enum.SurfaceType.Smooth
    node.BottomSurface = Enum.SurfaceType.Smooth

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectNode"
    prompt.ActionText = "Collect Samples"
    prompt.ObjectText = "Lunar Rock"
    prompt.HoldDuration = 0
    prompt.Parent = node

    prompt.Triggered:Connect(function(player)
      local profile = Profiles[player.UserId]
      if not profile then
        return
      end
      nodeCooldowns[player.UserId] = nodeCooldowns[player.UserId] or {}
      local playerNodes = nodeCooldowns[player.UserId]
      local now = os.time()
      local nextAt = playerNodes[data.name] or 0
      if nextAt > now then
        local remain = math.ceil(nextAt - now)
        sendState(player, "Node is cooling down. Wait " .. tostring(remain) .. " second(s).")
        return
      end

      local drops = pickDrops("LunarNode")
      for _, drop in ipairs(drops) do
        profile.Inventory[drop.item] = (profile.Inventory[drop.item] or 0) + drop.amount
      end
      playerNodes[data.name] = now + NODE_COOLDOWN_SECONDS

      saveProfile(player)
      sendState(player)
      prompt.Enabled = false
      task.delay(1.2, function()
        if prompt.Parent then
          prompt.Enabled = true
        end
      end)
    end)
  end
end

local function playerLoad(player)
  local data = nil
  pcall(function()
    data = store:GetAsync(tostring(player.UserId))
  end)
  Profiles[player.UserId] = sanitizeProfile(data)
  sendState(player)
end

local function playerRemove(player)
  saveProfile(player)
  Profiles[player.UserId] = nil
  nodeCooldowns[player.UserId] = nil
end

ensureScene()

local spawnPad = ensureMoonSpawnPoint()
Players.RespawnLocation = spawnPad

Players.PlayerAdded:Connect(function(player)
  playerLoad(player)
  bindCharacterAdded(player)
end)
Players.PlayerRemoving:Connect(playerRemove)

task.spawn(function()
  while true do
    task.wait(SYNC_INTERVAL)
    for _, player in ipairs(Players:GetPlayers()) do
      sendState(player)
    end
  end
end)

RequestState.OnServerEvent:Connect(function(player)
  sendState(player)
end)

RequestTeleportBack.OnServerEvent:Connect(function(player)
  if ROOT_PLACE_ID == 0 then
    sendState(player, "Set ROOT_PLACE_ID in MoonPlace/ReplicatedStorage/Shared/PlaceConfig.lua")
    return
  end

  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  saveProfile(player)
  local ok, err = pcall(function()
    TeleportService:TeleportAsync(ROOT_PLACE_ID, { player })
  end)
  if not ok then
    sendState(player, "Return failed: " .. tostring(err))
  end
end)

game:BindToClose(function()
  for _, player in ipairs(Players:GetPlayers()) do
    playerRemove(player)
  end
end)
