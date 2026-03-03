-- MainPlace/ServerScriptService/MainServer.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestCraft = Remotes:WaitForChild("RequestCraft")
local RequestPurchaseShip = Remotes:WaitForChild("RequestPurchaseShip")
local RequestStartQuiz = Remotes:WaitForChild("RequestStartQuiz")
local SubmitQuizAnswer = Remotes:WaitForChild("SubmitQuizAnswer")
local DonateMuseumItem = Remotes:WaitForChild("DonateMuseumItem")
local CollectOre = Remotes:WaitForChild("CollectOre")
local CollectNode = Remotes:WaitForChild("CollectNode")
local RequestTeleportMoon = Remotes:WaitForChild("RequestTeleportMoon")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local RecipesConfig = require(Shared:WaitForChild("RecipesConfig"))
local ShipsConfig = require(Shared:WaitForChild("ShipsConfig"))
local QuizzesConfig = require(Shared:WaitForChild("QuizzesConfig"))
local DropRates = require(Shared:WaitForChild("DropRatesConfig"))

local PROFILE_KEY = "SpaceGameProfile_V1"
local WEEKLY_LEADERBOARD = "QuizWeekly_Leaderboard_V1"
local MOON_PLACE_ID = 0 -- set Moon sub-place ID here

local function resolveMoonPlaceId()
  local attrId = game:GetAttribute("MoonPlaceId")
  if typeof(attrId) == "number" and attrId > 0 then
    return math.floor(attrId)
  end
  return MOON_PLACE_ID
end

local store = DataStoreService:GetDataStore(PROFILE_KEY)
local orderedWeekly = DataStoreService:GetOrderedDataStore(WEEKLY_LEADERBOARD)
local function currentWeekNumber() return math.floor(os.time() / 604800) end

local function newProfile()
  return { Cash=250, Inventory={IronOre=10,TitaniumOre=0,FuelCell=0,EngineCore=0,HullPlate=0,LunarSample=0},
    OwnedShips={}, BestQuizScore=0, WeeklyQuizScore=0, LastWeekNumber=currentWeekNumber(), EquippedShip=nil, CanGoMoon=false, LastWeeklyRewardAt=0 }
end

local function getLeaderstats(player)
  local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
  local cash=Instance.new("IntValue"); cash.Name=ItemsConfig.CURRENCY_NAME; cash.Parent=ls
  local score=Instance.new("IntValue"); score.Name="QuizScore"; score.Parent=ls
  local wscore=Instance.new("IntValue"); wscore.Name="WeeklyQuiz"; wscore.Parent=ls
  return ls
end

local Profiles = {}

local function createWorldPart(name, color, size, position, material)
  local part = Instance.new("Part")
  part.Name = name
  part.Anchored = true
  part.CanCollide = true
  part.Size = size
  part.Position = position
  part.Color = color
  part.Material = material or Enum.Material.SmoothPlastic
  part.Parent = Workspace
  return part
end

local function ensureMainScene()
  if Workspace:FindFirstChild("MainSceneBuilt") then
    return
  end

  local flag = Instance.new("BoolValue")
  flag.Name = "MainSceneBuilt"
  flag.Parent = Workspace

  createWorldPart(
    "EarthGround",
    Color3.fromRGB(70, 125, 80),
    Vector3.new(600, 6, 600),
    Vector3.new(0, -3, 0),
    Enum.Material.Grass
  )

  if not Workspace:FindFirstChildWhichIsA("SpawnLocation") then
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 4, 0)
    spawn.Parent = Workspace
  end

  local museumPad = createWorldPart(
    "MuseumPad",
    Color3.fromRGB(222, 208, 176),
    Vector3.new(100, 2, 80),
    Vector3.new(0, 1, 95),
    Enum.Material.Sandstone
  )
  museumPad.CanTouch = true
end

local function savePlayer(plr)
  local p=Profiles[plr.UserId]; if not p then return end
  pcall(function() store:SetAsync(tostring(plr.UserId), p) end)
  pcall(function() orderedWeekly:SetAsync(tostring(plr.UserId), p.WeeklyQuizScore or 0) end)
end

local function grantWeeklyReward(profile)
  local s=profile.WeeklyQuizScore or 0; local cash=0
  if s>=50 then cash=3000 elseif s>=25 then cash=1200 elseif s>=10 then cash=400 elseif s>=1 then cash=100 end
  profile.Cash=(profile.Cash or 0)+cash; profile.LastWeeklyRewardAt=currentWeekNumber(); profile.WeeklyQuizScore=0
end
local function rolloverWeek(profile)
  local now=currentWeekNumber()
  if (profile.LastWeekNumber or now)~=now then
    if (profile.LastWeeklyRewardAt or -1) < now then grantWeeklyReward(profile) end
    profile.LastWeekNumber=now
  end
end

local function loadPlayer(plr)
  local data; pcall(function() data=store:GetAsync(tostring(plr.UserId)) end)
  data=data or newProfile(); Profiles[plr.UserId]=data; rolloverWeek(data)
  local ls=getLeaderstats(plr); ls[ItemsConfig.CURRENCY_NAME].Value=data.Cash or 0; ls.QuizScore.Value=data.BestQuizScore or 0; ls.WeeklyQuiz.Value=data.WeeklyQuizScore or 0
end

Players.PlayerAdded:Connect(loadPlayer)
Players.PlayerRemoving:Connect(function(plr) savePlayer(plr); Profiles[plr.UserId]=nil end)
game:BindToClose(function() for _,plr in ipairs(Players:GetPlayers()) do savePlayer(plr) end end)

local function has(inv, req) for k,v in pairs(req) do if (inv[k] or 0) < v then return false end end return true end
local function take(inv, req) for k,v in pairs(req) do inv[k]=(inv[k] or 0)-v end end

RequestCraft.OnServerEvent:Connect(function(plr, id)
  local p=Profiles[plr.UserId]; if not p then return end
  local r=RecipesConfig[id]; if not r then return end
  if r.cashCost and p.Cash<r.cashCost then return end
  if not has(p.Inventory, r.cost) then return end
  if r.cashCost then p.Cash-=r.cashCost end; take(p.Inventory, r.cost)
  for it,amt in pairs(r.gives) do p.Inventory[it]=(p.Inventory[it] or 0)+amt end
  plr.leaderstats[ItemsConfig.CURRENCY_NAME].Value=p.Cash
end)

RequestPurchaseShip.OnServerEvent:Connect(function(plr, id)
  local p=Profiles[plr.UserId]; if not p then return end
  local target; for _,s in ipairs(ShipsConfig.Tiers) do if s.id==id then target=s break end end; if not target then return end
  if p.Cash<target.price then return end
  if target.need and not has(p.Inventory, target.need) then return end
  p.Cash-=target.price; if target.need then take(p.Inventory,target.need) end
  table.insert(p.OwnedShips, target.id); p.EquippedShip=target.id; if target.canGoMoon then p.CanGoMoon=true end
  plr.leaderstats[ItemsConfig.CURRENCY_NAME].Value=p.Cash
end)

local ActiveQuiz={}
RequestStartQuiz.OnServerEvent:Connect(function(plr)
  local idx=math.random(1,#QuizzesConfig.Pool); ActiveQuiz[plr.UserId]=idx
  Remotes.RequestStartQuiz:FireClient(plr, QuizzesConfig.Pool[idx].q)
end)

SubmitQuizAnswer.OnServerEvent:Connect(function(plr, ans)
  local p=Profiles[plr.UserId]; if not p then return end
  local idx=ActiveQuiz[plr.UserId]; if not idx then return end
  local q=QuizzesConfig.Pool[idx]; ActiveQuiz[plr.UserId]=nil
  local function norm(s) return string.lower((s or ""):gsub("%s+","")) end
  local ok=(norm(ans)==norm(q.a))
  if ok then
    p.Cash=(p.Cash or 0)+(q.rewardCash or 100); plr.leaderstats[ItemsConfig.CURRENCY_NAME].Value=p.Cash
    if q.rewardItem then p.Inventory[q.rewardItem]=(p.Inventory[q.rewardItem] or 0)+1 end
    p.BestQuizScore=(p.BestQuizScore or 0)+1; plr.leaderstats.QuizScore.Value=p.BestQuizScore
    p.WeeklyQuizScore=(p.WeeklyQuizScore or 0)+1; plr.leaderstats.WeeklyQuiz.Value=p.WeeklyQuizScore
    pcall(function() orderedWeekly:SetAsync(tostring(plr.UserId), p.WeeklyQuizScore) end)
  end
  Remotes.SubmitQuizAnswer:FireClient(plr, ok, q.a)
end)

local BadgeService=game:GetService("BadgeService")
local LUNAR_BADGE_ID=0
DonateMuseumItem.OnServerEvent:Connect(function(plr, item, amount)
  local p=Profiles[plr.UserId]; if not p then return end
  amount=math.clamp(tonumber(amount) or 0,1,99)
  if (p.Inventory[item] or 0) < amount then return end
  p.Inventory[item]=(p.Inventory[item] or 0)-amount
  local mat=(ItemsConfig.Materials[item] or {value=50})
  p.Cash=(p.Cash or 0)+((mat.value or 50)*amount*2); plr.leaderstats[ItemsConfig.CURRENCY_NAME].Value=p.Cash
  if item=="LunarSample" and LUNAR_BADGE_ID~=0 then pcall(function() if not BadgeService:UserHasBadgeAsync(plr.UserId,LUNAR_BADGE_ID) then BadgeService:AwardBadge(plr.UserId,LUNAR_BADGE_ID) end end) end
end)

CollectOre.OnServerEvent:Connect(function(plr, item)
  local p=Profiles[plr.UserId]; if not p then return end
  if not ItemsConfig.Materials[item] then return end
  p.Inventory[item]=(p.Inventory[item] or 0)+1
end)

local function rr(a,b) return math.random(a,b) end
local function grantDropsToPlayer(profile, nodeKey)
  local pool = DropRates[nodeKey]
  if not pool then
    return
  end
  for _,e in ipairs(pool) do
    if math.random() < (e.chance or 0) then
      local amt = rr(e.amount.min, e.amount.max)
      if ItemsConfig.Materials[e.item] then
        profile.Inventory[e.item] = (profile.Inventory[e.item] or 0) + amt
      end
    end
  end
end

local function buildMainResourceNodes()
  if Workspace:FindFirstChild("MainResourceNodesBuilt") then
    return
  end

  local flag = Instance.new("BoolValue")
  flag.Name = "MainResourceNodesBuilt"
  flag.Parent = Workspace

  local configs = {
    {name = "IronNode_A", key = "IronNode", pos = Vector3.new(-35, 4, 25), color = Color3.fromRGB(125, 125, 125)},
    {name = "IronNode_B", key = "IronNode", pos = Vector3.new(-55, 4, 5), color = Color3.fromRGB(125, 125, 125)},
    {name = "TitaniumNode_A", key = "TitaniumNode", pos = Vector3.new(35, 4, 30), color = Color3.fromRGB(145, 160, 175)},
  }

  for _,cfg in ipairs(configs) do
    local node = createWorldPart(cfg.name, cfg.color, Vector3.new(7, 7, 7), cfg.pos, Enum.Material.Rock)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "채집"
    prompt.ObjectText = cfg.name
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.Parent = node
    prompt.Triggered:Connect(function(plr)
      local profile = Profiles[plr.UserId]
      if not profile then
        return
      end
      grantDropsToPlayer(profile, cfg.key)
      prompt.Enabled = false
      task.delay(1.5, function()
        if prompt.Parent then
          prompt.Enabled = true
        end
      end)
    end)
  end
end

ensureMainScene()
buildMainResourceNodes()

CollectNode.OnServerEvent:Connect(function(plr, key)
  local p=Profiles[plr.UserId]; if not p then return end
  grantDropsToPlayer(p, key)
end)

RequestTeleportMoon.OnServerEvent:Connect(function(plr)
  local p=Profiles[plr.UserId]; if not p then return end
  if not p.CanGoMoon then return end
  local moonPlaceId = resolveMoonPlaceId()
  if moonPlaceId == 0 then return end
  pcall(function() TeleportService:TeleportAsync(moonPlaceId, {plr}) end)
end)
