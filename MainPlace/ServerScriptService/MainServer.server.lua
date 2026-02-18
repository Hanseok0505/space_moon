local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local BadgeService = game:GetService("BadgeService")

-- RemoteEvents setup
local remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remotesFolder then
  remotesFolder = Instance.new("Folder")
  remotesFolder.Name = "RemoteEvents"
  remotesFolder.Parent = ReplicatedStorage
end

local remoteNames = {
  "RequestCraft",
  "RequestPurchaseShip",
  "RequestEquipShip",
  "RequestStartQuiz",
  "SubmitQuizAnswer",
  "DonateMuseumItem",
  "CollectOre",
  "CollectNode",
  "RequestTeleportMoon",
  "GetPlayerState",
  "RequestMuseumData",
}

for _, name in ipairs(remoteNames) do
  if not remotesFolder:FindFirstChild(name) then
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotesFolder
  end
end

local Remotes = remotesFolder
local RequestCraft = Remotes:WaitForChild("RequestCraft")
local RequestPurchaseShip = Remotes:WaitForChild("RequestPurchaseShip")
local RequestEquipShip = Remotes:WaitForChild("RequestEquipShip")
local RequestStartQuiz = Remotes:WaitForChild("RequestStartQuiz")
local SubmitQuizAnswer = Remotes:WaitForChild("SubmitQuizAnswer")
local DonateMuseumItem = Remotes:WaitForChild("DonateMuseumItem")
local CollectOre = Remotes:WaitForChild("CollectOre")
local CollectNode = Remotes:WaitForChild("CollectNode")
local RequestTeleportMoon = Remotes:WaitForChild("RequestTeleportMoon")
local GetPlayerState = Remotes:WaitForChild("GetPlayerState")
local RequestMuseumData = Remotes:WaitForChild("RequestMuseumData")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local RecipesConfig = require(Shared:WaitForChild("RecipesConfig"))
local ShipsConfig = require(Shared:WaitForChild("ShipsConfig"))
local QuizzesConfig = require(Shared:WaitForChild("QuizzesConfig"))
local DropRatesConfig = require(Shared:WaitForChild("DropRatesConfig"))
local PlaceConfigModule = Shared:FindFirstChild("PlaceConfig")

local PROFILE_KEY = "SpaceGameProfile_V1"
local WEEKLY_LEADERBOARD = "QuizWeekly_Leaderboard_V1"
local MUSEUM_KEY = "SpaceMoonMuseum_v1"
local LUNAR_BADGE_ID = 0

local function resolveMoonPlaceId()
  local attrRoot = tonumber(game:GetAttribute("MOON_PLACE_ID"))
  if attrRoot and attrRoot > 0 then
    return attrRoot
  end
  local attrReplicated = tonumber(ReplicatedStorage:GetAttribute("MOON_PLACE_ID"))
  if attrReplicated and attrReplicated > 0 then
    return attrReplicated
  end
  if PlaceConfigModule and PlaceConfigModule:IsA("ModuleScript") then
    local ok, cfg = pcall(require, PlaceConfigModule)
    if ok and type(cfg) == "table" then
      return tonumber(cfg.MOON_PLACE_ID) or 0
    end
  end
  return 0
end

local MOON_PLACE_ID = resolveMoonPlaceId()

local SYNC_INTERVAL = 5
local DEFAULT_SHIP_ID = "Scout-I"

local store = DataStoreService:GetDataStore(PROFILE_KEY)
local museumStore = DataStoreService:GetDataStore(MUSEUM_KEY)
local orderedWeekly = DataStoreService:GetOrderedDataStore(WEEKLY_LEADERBOARD)

local Profiles = {}
local MuseumExhibits = {}
local ShipCooldownById = {}
local ActionCooldowns = {}

local function currentWeekNumber()
  return math.floor(os.time() / 604800)
end

local function cloneTable(source)
  local out = {}
  for k, v in pairs(source or {}) do
    out[k] = v
  end
  return out
end

local function dedupeArray(source)
  local out = {}
  local seen = {}
  for _, value in ipairs(source) do
    if not seen[value] then
      seen[value] = true
      table.insert(out, value)
    end
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

local function normalizeOwnedShips(raw)
  local owned = {}
  if type(raw) == "table" then
    for _, ship in ipairs(raw) do
      if type(ship) == "string" and getShipConfig(ship) then
        table.insert(owned, ship)
      end
    end
  end
  return dedupeArray(owned)
end

local function getShipConfig(shipId)
  for _, ship in ipairs(ShipsConfig.Tiers) do
    if ship.id == shipId then
      return ship
    end
  end
  return nil
end

local function hasCanGoShip(profile)
  for _, shipId in ipairs(profile.OwnedShips) do
    local cfg = getShipConfig(shipId)
    if cfg and cfg.canGoMoon then
      return true
    end
  end
  return false
end

local function sanitizeProfile(data)
  data = (type(data) == "table") and data or {}
  local owned = normalizeOwnedShips(data.OwnedShips)
  if #owned == 0 then
    table.insert(owned, DEFAULT_SHIP_ID)
  end

  local equipped = data.EquippedShip
  if type(equipped) ~= "string" or not getShipConfig(equipped) then
    equipped = owned[1]
  end
  if not table.find(owned, equipped) then
    equipped = owned[1]
  end

  local profile = {
    Cash = math.max(0, math.floor(tonumber(data.Cash) or 250)),
    Inventory = normalizeInventory(data.Inventory),
    OwnedShips = owned,
    BestQuizScore = math.max(0, math.floor(tonumber(data.BestQuizScore) or 0)),
    WeeklyQuizScore = math.max(0, math.floor(tonumber(data.WeeklyQuizScore) or 0)),
    LastWeekNumber = tonumber(data.LastWeekNumber) or currentWeekNumber(),
    EquippedShip = equipped,
    CanGoMoon = data.CanGoMoon == true,
    LastWeeklyRewardAt = tonumber(data.LastWeeklyRewardAt) or 0,
    NextMoonLaunchAt = tonumber(data.NextMoonLaunchAt) or 0,
  }

  profile.CanGoMoon = hasCanGoShip(profile)

  return profile
end

local function saveMuseum()
  pcall(function()
    museumStore:SetAsync("GLOBAL", MuseumExhibits)
  end)
end

local function loadMuseum()
  local loaded = nil
  pcall(function()
    loaded = museumStore:GetAsync("GLOBAL")
  end)
  if type(loaded) == "table" then
    MuseumExhibits = loaded
  end
end

local function createLeaderstats(player)
  local ls = Instance.new("Folder")
  ls.Name = "leaderstats"
  ls.Parent = player

  local cash = Instance.new("IntValue")
  cash.Name = ItemsConfig.CURRENCY_NAME
  cash.Parent = ls

  local score = Instance.new("IntValue")
  score.Name = "QuizScore"
  score.Parent = ls

  local weekly = Instance.new("IntValue")
  weekly.Name = "WeeklyQuiz"
  weekly.Parent = ls
  return ls
end

local function updateLeaderstats(player, profile)
  local ls = player:FindFirstChild("leaderstats")
  if not ls then
    return
  end

  local cash = ls:FindFirstChild(ItemsConfig.CURRENCY_NAME)
  local score = ls:FindFirstChild("QuizScore")
  local weekly = ls:FindFirstChild("WeeklyQuiz")
  if cash then
    cash.Value = profile.Cash
  end
  if score then
    score.Value = profile.BestQuizScore
  end
  if weekly then
    weekly.Value = profile.WeeklyQuizScore
  end
end

local function syncServerValues(player, profile)
  local canGo = player:FindFirstChild("CanGoMoon")
  if not canGo then
    canGo = Instance.new("BoolValue")
    canGo.Name = "CanGoMoon"
    canGo.Parent = player
  end
  canGo.Value = profile.CanGoMoon == true

  local equipped = player:FindFirstChild("EquippedShip")
  if not equipped then
    equipped = Instance.new("StringValue")
    equipped.Name = "EquippedShip"
    equipped.Parent = player
  end
  equipped.Value = profile.EquippedShip or ""
end

local function playerForClient(profile)
  return {
    canGoMoon = profile.CanGoMoon == true,
    inventory = cloneTable(profile.Inventory),
    cash = profile.Cash,
    bestQuizScore = profile.BestQuizScore,
    weeklyQuizScore = profile.WeeklyQuizScore,
    ownedShips = cloneTable(profile.OwnedShips),
    equippedShip = profile.EquippedShip,
    nextMoonLaunchAt = profile.NextMoonLaunchAt or 0,
    serverTime = os.time(),
    shipCooldowns = getShipCooldownsForClient(),
    allShips = ShipsConfig.Tiers,
  }
end

local function savePlayerProfile(player)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end

  pcall(function()
    store:SetAsync(tostring(player.UserId), profile)
  end)
  pcall(function()
    orderedWeekly:SetAsync(tostring(player.UserId), profile.WeeklyQuizScore or 0)
  end)
end

local function sendPlayerState(player)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  syncServerValues(player, profile)
  updateLeaderstats(player, profile)
  GetPlayerState:FireClient(player, playerForClient(profile))
end

local function sendMuseumData(player)
  RequestMuseumData:FireClient(player, cloneTable(MuseumExhibits))
end

local function grantWeeklyReward(profile)
  local score = profile.WeeklyQuizScore or 0
  local reward = 0
  if score >= 50 then
    reward = 3000
  elseif score >= 25 then
    reward = 1200
  elseif score >= 10 then
    reward = 400
  elseif score >= 1 then
    reward = 100
  end
  profile.Cash = (profile.Cash or 0) + reward
  profile.LastWeeklyRewardAt = currentWeekNumber()
  profile.WeeklyQuizScore = 0
end

local function rolloverWeek(profile)
  local now = currentWeekNumber()
  if (profile.LastWeekNumber or now) ~= now then
    if (profile.LastWeeklyRewardAt or -1) < now then
      grantWeeklyReward(profile)
    end
    profile.LastWeekNumber = now
  end
end

local function hasAllItems(inventory, requirement)
  for itemName, amount in pairs(requirement or {}) do
    if (inventory[itemName] or 0) < amount then
      return false
    end
  end
  return true
end

local function takeItems(inventory, requirement)
  for itemName, amount in pairs(requirement or {}) do
    local nextValue = (inventory[itemName] or 0) - (tonumber(amount) or 0)
    inventory[itemName] = math.max(0, nextValue)
  end
end

local function sanitizeText(value)
  return string.lower(tostring(value or ""):gsub("%s+", ""))
end

local function randBetween(minValue, maxValue)
  return math.random(math.floor(minValue), math.floor(maxValue))
end

local function canPerformAction(player, actionName, cooldownSeconds)
  local now = os.time()
  local actions = ActionCooldowns[player.UserId]
  if not actions then
    actions = {}
    ActionCooldowns[player.UserId] = actions
  end
  local readyAt = actions[actionName] or 0
  if readyAt > now then
    return false, readyAt - now
  end
  actions[actionName] = now + cooldownSeconds
  return true, 0
end

local function hasShipByProfile(profile, shipId)
  return table.find(profile.OwnedShips, shipId) ~= nil
end

local function launchCooldown(shipId)
  local shipCfg = getShipConfig(shipId)
  if shipCfg and shipCfg.launchCooldown then
    return math.max(6, math.floor(shipCfg.launchCooldown))
  end
  return 20
end

local function padCooldown(shipId)
  local shipCfg = getShipConfig(shipId)
  if shipCfg and shipCfg.padCooldown then
    return math.max(3, math.floor(shipCfg.padCooldown))
  end
  return 12
end

local function getShipCooldownsForClient()
  local result = {}
  for _, ship in ipairs(ShipsConfig.Tiers) do
    if ship.id then
      result[ship.id] = ShipCooldownById[ship.id] or 0
    end
  end
  return result
end

local function setEquipped(player, shipId)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  if type(shipId) ~= "string" then
    RequestEquipShip:FireClient(player, false, "INVALID_SHIP")
    return
  end
  local cfg = getShipConfig(shipId)
  if not cfg then
    RequestEquipShip:FireClient(player, false, "NOT_FOUND")
    return
  end
  if not hasShipByProfile(profile, shipId) then
    RequestEquipShip:FireClient(player, false, "NOT_OWNED")
    return
  end

  profile.EquippedShip = shipId
  if cfg.canGoMoon then
    profile.CanGoMoon = true
  end
  savePlayerProfile(player)
  sendPlayerState(player)
  RequestEquipShip:FireClient(player, true, shipId)
end

local function ensureEquipped(profile)
  if #profile.OwnedShips == 0 then
    profile.OwnedShips = { DEFAULT_SHIP_ID }
  end
  if not hasShipByProfile(profile, profile.EquippedShip) then
    profile.EquippedShip = profile.OwnedShips[1]
  end
  profile.CanGoMoon = hasCanGoShip(profile)
end

local function playerLoad(player)
  local data = nil
  pcall(function()
    data = store:GetAsync(tostring(player.UserId))
  end)
  local profile = sanitizeProfile(data)
  ensureEquipped(profile)
  Profiles[player.UserId] = profile
  rolloverWeek(profile)

  if not player:FindFirstChild("leaderstats") then
    createLeaderstats(player)
  end
  updateLeaderstats(player, profile)
  sendPlayerState(player)
end

local function playerSave(player)
  ActionCooldowns[player.UserId] = nil
  savePlayerProfile(player)
  Profiles[player.UserId] = nil
end

local ActiveQuiz = {}

RequestCraft.OnServerEvent:Connect(function(player, recipeId)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end

  local recipe = RecipesConfig[recipeId]
  if type(recipe) ~= "table" then
    return
  end
  if recipe.cashCost and profile.Cash < recipe.cashCost then
    return
  end
  if not hasAllItems(profile.Inventory, recipe.cost) then
    return
  end

  if recipe.cashCost and recipe.cashCost > 0 then
    profile.Cash -= recipe.cashCost
  end
  if recipe.cost then
    takeItems(profile.Inventory, recipe.cost)
  end
  for itemName, amount in pairs(recipe.gives or {}) do
    profile.Inventory[itemName] = (profile.Inventory[itemName] or 0) + (tonumber(amount) or 0)
  end
  savePlayerProfile(player)
  sendPlayerState(player)
end)

RequestPurchaseShip.OnServerEvent:Connect(function(player, shipId)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  if type(shipId) ~= "string" then
    RequestPurchaseShip:FireClient(player, false, "INVALID_SHIP")
    return
  end
  local shipCfg = getShipConfig(shipId)
  if not shipCfg then
    RequestPurchaseShip:FireClient(player, false, "NOT_FOUND")
    return
  end

  if hasShipByProfile(profile, shipId) then
    setEquipped(player, shipId)
    return
  end
  local price = tonumber(shipCfg.price) or 0
  if price > 0 and profile.Cash < price then
    RequestPurchaseShip:FireClient(player, false, "NEED_MORE_CASH")
    return
  end
  if not hasAllItems(profile.Inventory, shipCfg.need) then
    RequestPurchaseShip:FireClient(player, false, "NEED_ITEMS")
    return
  end
  if shipCfg.need then
    takeItems(profile.Inventory, shipCfg.need)
  end
  profile.Cash -= price
  table.insert(profile.OwnedShips, shipId)
  profile.EquippedShip = shipId
  if shipCfg.canGoMoon then
    profile.CanGoMoon = true
  end
  savePlayerProfile(player)
  sendPlayerState(player)
  RequestPurchaseShip:FireClient(player, true, shipId)
end)

RequestEquipShip.OnServerEvent:Connect(function(player, shipId)
  setEquipped(player, shipId)
end)

RequestStartQuiz.OnServerEvent:Connect(function(player)
  local count = #QuizzesConfig.Pool
  if count == 0 then
    return
  end
  ActiveQuiz[player.UserId] = QuizzesConfig.Pool[math.random(1, count)]
  local q = ActiveQuiz[player.UserId]
  if q then
    RequestStartQuiz:FireClient(player, q.q)
  end
end)

SubmitQuizAnswer.OnServerEvent:Connect(function(player, answer)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  local question = ActiveQuiz[player.UserId]
  if not question then
    return
  end
  ActiveQuiz[player.UserId] = nil

  local isCorrect = sanitizeText(answer) == sanitizeText(question.a)
  if isCorrect then
    profile.Cash = (profile.Cash or 0) + (question.rewardCash or 100)
    if question.rewardItem and ItemsConfig.Materials[question.rewardItem] then
      profile.Inventory[question.rewardItem] = (profile.Inventory[question.rewardItem] or 0) + 1
    end
    profile.BestQuizScore = (profile.BestQuizScore or 0) + 1
    profile.WeeklyQuizScore = (profile.WeeklyQuizScore or 0) + 1
    pcall(function()
      orderedWeekly:SetAsync(tostring(player.UserId), profile.WeeklyQuizScore)
    end)
  end
  savePlayerProfile(player)
  sendPlayerState(player)
  SubmitQuizAnswer:FireClient(player, isCorrect, question.a)
end)

DonateMuseumItem.OnServerEvent:Connect(function(player, item, amount)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  if not ItemsConfig.Materials[item] then
    return
  end

  amount = math.clamp(tonumber(amount) or 1, 1, 99)
  if (profile.Inventory[item] or 0) < amount then
    return
  end

  profile.Inventory[item] = (profile.Inventory[item] or 0) - amount
  local value = (ItemsConfig.Materials[item] and ItemsConfig.Materials[item].value) or 50
  profile.Cash = (profile.Cash or 0) + (value * 2 * amount)

  MuseumExhibits[item] = (MuseumExhibits[item] or 0) + amount
  saveMuseum()
  sendMuseumData(player)

  if item == "LunarSample" and LUNAR_BADGE_ID ~= 0 then
    pcall(function()
      if not BadgeService:UserHasBadgeAsync(player.UserId, LUNAR_BADGE_ID) then
        BadgeService:AwardBadge(player.UserId, LUNAR_BADGE_ID)
      end
    end)
  end

  if hasCanGoShip(profile) then
    profile.CanGoMoon = true
  end
  savePlayerProfile(player)
  sendPlayerState(player)
end)

CollectOre.OnServerEvent:Connect(function(player, item)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  local ok = canPerformAction(player, "collectOre", 1.8)
  if not ok then
    return
  end
  if not ItemsConfig.Materials[item] then
    return
  end

  profile.Inventory[item] = (profile.Inventory[item] or 0) + 1
  savePlayerProfile(player)
  sendPlayerState(player)
end)

CollectNode.OnServerEvent:Connect(function(player, nodeKey)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  local ok = canPerformAction(player, "collectNode:" .. tostring(nodeKey), 1.5)
  if not ok then
    return
  end
  local pool = DropRatesConfig[nodeKey]
  if not pool then
    return
  end

  for _, entry in ipairs(pool) do
    if math.random() < (entry.chance or 0) then
      local amount = randBetween((entry.amount and entry.amount.min) or 1, (entry.amount and entry.amount.max) or 1)
      if amount > 0 and ItemsConfig.Materials[entry.item] then
        profile.Inventory[entry.item] = (profile.Inventory[entry.item] or 0) + amount
      end
    end
  end
  savePlayerProfile(player)
  sendPlayerState(player)
end)

RequestTeleportMoon.OnServerEvent:Connect(function(player, requestedShipId)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  if MOON_PLACE_ID == 0 then
    RequestTeleportMoon:FireClient(player, false, "Set Moon place id in MainPlace/ReplicatedStorage/Shared/PlaceConfig.lua")
    return
  end

  ensureEquipped(profile)
  local shipId = requestedShipId and tostring(requestedShipId) or profile.EquippedShip
  if type(shipId) ~= "string" then
    RequestTeleportMoon:FireClient(player, false, "Invalid ship selection.")
    return
  end
  local ship = getShipConfig(shipId)
  if not ship then
    RequestTeleportMoon:FireClient(player, false, "Ship not found.")
    return
  end
  if not hasShipByProfile(profile, shipId) then
    RequestTeleportMoon:FireClient(player, false, "You do not own this ship.")
    return
  end
  if not ship.canGoMoon then
    RequestTeleportMoon:FireClient(player, false, "This ship cannot go to moon yet.")
    return
  end

  local now = os.time()
  local personalReadyAt = profile.NextMoonLaunchAt or 0
  local personalRemain = personalReadyAt - now
  if personalRemain > 0 then
    RequestTeleportMoon:FireClient(player, false, "Ship launch ready in " .. tostring(math.ceil(personalRemain)) .. " second(s).")
    return
  end

  local padReadyAt = ShipCooldownById[shipId] or 0
  local padRemain = padReadyAt - now
  if padRemain > 0 then
    RequestTeleportMoon:FireClient(player, false, "Same ship is busy: " .. tostring(math.ceil(padRemain)) .. " second(s).")
    return
  end

  profile.EquippedShip = shipId
  profile.NextMoonLaunchAt = now + launchCooldown(shipId)
  ShipCooldownById[shipId] = now + padCooldown(shipId)
  savePlayerProfile(player)
  sendPlayerState(player)
  RequestTeleportMoon:FireClient(player, true, "Launching with " .. shipId)

  local ok, err = pcall(function()
    TeleportService:TeleportAsync(MOON_PLACE_ID, { player })
  end)
  if not ok then
    profile.NextMoonLaunchAt = 0
    ShipCooldownById[shipId] = 0
    savePlayerProfile(player)
    sendPlayerState(player)
    RequestTeleportMoon:FireClient(player, false, "Launch failed: " .. tostring(err))
  end
end)

GetPlayerState.OnServerEvent:Connect(function(player)
  local profile = Profiles[player.UserId]
  if not profile then
    return
  end
  ensureEquipped(profile)
  sendPlayerState(player)
end)

RequestMuseumData.OnServerEvent:Connect(function(player)
  sendMuseumData(player)
end)

Players.PlayerAdded:Connect(playerLoad)
Players.PlayerRemoving:Connect(function(player)
  playerSave(player)
end)

game:BindToClose(function()
  for _, player in ipairs(Players:GetPlayers()) do
    playerSave(player)
  end
  saveMuseum()
end)

task.spawn(function()
  while true do
    task.wait(SYNC_INTERVAL)
    for _, player in ipairs(Players:GetPlayers()) do
      sendPlayerState(player)
    end
  end
end)

loadMuseum()
