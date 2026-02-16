-- MoonPlace/ServerScriptService/MoonServer.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestTeleportBack = Remotes:WaitForChild("RequestTeleportBack")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared:WaitForChild("ItemsConfig"))
local DropRates = require(Shared:WaitForChild("DropRatesConfig"))

local PROFILE_KEY = "SpaceGameProfile_V1"
local ROOT_PLACE_ID = 0 -- set Main place ID here

local store = DataStoreService:GetDataStore(PROFILE_KEY)
local Profiles = {}

local function newLeaderstats(plr)
  local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=plr
  local cash=Instance.new("IntValue"); cash.Name=ItemsConfig.CURRENCY_NAME; cash.Parent=ls
  return ls
end

local function loadProfile(plr)
  local data; pcall(function() data=store:GetAsync(tostring(plr.UserId)) end)
  data=data or {Cash=0, Inventory={}}
  Profiles[plr.UserId]=data
  local ls=newLeaderstats(plr); ls[ItemsConfig.CURRENCY_NAME].Value=data.Cash or 0
end
local function saveProfile(plr) local p=Profiles[plr.UserId]; if not p then return end; pcall(function() store:SetAsync(tostring(plr.UserId), p) end) end

Players.PlayerAdded:Connect(loadProfile)
Players.PlayerRemoving:Connect(function(plr) saveProfile(plr); Profiles[plr.UserId]=nil end)
game:BindToClose(function() for _,plr in ipairs(Players:GetPlayers()) do saveProfile(plr) end end)

local function rr(a,b) return math.random(a,b) end
local function chooseDrops(nodeKey)
  local pool=DropRates[nodeKey]; if not pool then return {} end
  local out={}
  for _,e in ipairs(pool) do
    if math.random()<(e.chance or 0) then table.insert(out, {item=e.item, amount=rr(e.amount.min, e.amount.max)}) end
  end
  return out
end

-- Build a simple moon scene with a return portal and 3 nodes
local function createPart(name, c, size, pos)
  local p=Instance.new("Part"); p.Name=name; p.Anchored=true; p.CanCollide=true; p.Size=size; p.Color=c; p.Position=pos; p.Parent=Workspace; return p
end

local function ensureScene()
  if Workspace:FindFirstChild("MoonSceneBuilt") then return end
  local flag=Instance.new("BoolValue"); flag.Name="MoonSceneBuilt"; flag.Parent=Workspace
  local base=createPart("MoonBase", Color3.fromRGB(200,200,200), Vector3.new(200,2,200), Vector3.new(0,0,0))
  local portal=createPart("ReturnPortal", Color3.fromRGB(0,170,255), Vector3.new(8,10,1), Vector3.new(0,6,-80)); portal.Material=Enum.Material.Neon
  local pp=Instance.new("ProximityPrompt"); pp.ActionText="귀환(메인)"; pp.ObjectText="포털"; pp.HoldDuration=0; pp.Parent=portal
  pp.Triggered:Connect(function(plr) if ROOT_PLACE_ID~=0 then pcall(function() TeleportService:TeleportAsync(ROOT_PLACE_ID,{plr}) end) end end)
  local posList={Vector3.new(-40,2,30), Vector3.new(20,2,40), Vector3.new(60,2,-10)}
  for i,pos in ipairs(posList) do
    local node=createPart("LunarNode_"..i, Color3.fromRGB(240,240,240), Vector3.new(6,6,6), pos); node.Material=Enum.Material.Slate
    local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="채집"; prompt.ObjectText="월면 광물"; prompt.HoldDuration=0; prompt.Parent=node
    prompt.Triggered:Connect(function(plr)
      local prof=Profiles[plr.UserId]; if not prof then return end
      for _,d in ipairs(chooseDrops("LunarNode")) do
        if ItemsConfig.Materials[d.item] then prof.Inventory[d.item]=(prof.Inventory[d.item] or 0)+d.amount end
      end
      prompt.Enabled=false; task.delay(2,function() prompt.Enabled=true end)
    end)
  end
end
ensureScene()

-- Return button support
RequestTeleportBack.OnServerEvent:Connect(function(plr)
  if ROOT_PLACE_ID==0 then return end
  pcall(function() TeleportService:TeleportAsync(ROOT_PLACE_ID, {plr}) end)
end)
