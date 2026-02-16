-- MoonPlace/StarterPlayer/StarterPlayerScripts/MoonClient.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestTeleportBack = Remotes:WaitForChild("RequestTeleportBack")

local function ensureGui()
  local pg=player:WaitForChild("PlayerGui")
  local HUD=pg:FindFirstChild("MoonHUD")
  if not HUD then
    HUD=Instance.new("ScreenGui"); HUD.Name="MoonHUD"; HUD.ResetOnSpawn=false; HUD.Parent=pg
    local btn=Instance.new("TextButton"); btn.Name="ReturnButton"; btn.Text="메인으로 귀환"; btn.Size=UDim2.new(0,150,0,40); btn.Position=UDim2.new(0,20,0,20); btn.Parent=HUD
    btn.MouseButton1Click:Connect(function() RequestTeleportBack:FireServer() end)
  end
end
ensureGui()
