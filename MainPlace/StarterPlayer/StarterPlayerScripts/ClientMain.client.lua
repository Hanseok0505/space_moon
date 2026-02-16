-- MainPlace/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestCraft = Remotes:WaitForChild("RequestCraft")
local RequestPurchaseShip = Remotes:WaitForChild("RequestPurchaseShip")
local RequestStartQuiz = Remotes:WaitForChild("RequestStartQuiz")
local SubmitQuizAnswer = Remotes:WaitForChild("SubmitQuizAnswer")
local DonateMuseumItem = Remotes:WaitForChild("DonateMuseumItem")
local CollectOre = Remotes:WaitForChild("CollectOre")
local CollectNode = Remotes:WaitForChild("CollectNode")
local RequestTeleportMoon = Remotes:WaitForChild("RequestTeleportMoon")

local function ensureGui()
  local pg=player:WaitForChild("PlayerGui")
  local HUD=pg:FindFirstChild("HUD")
  if not HUD then
    HUD=Instance.new("ScreenGui"); HUD.Name="HUD"; HUD.ResetOnSpawn=false; HUD.Parent=pg
    local b1=Instance.new("TextButton"); b1.Name="QuizButton"; b1.Text="퀴즈"; b1.Size=UDim2.new(0,120,0,40); b1.Position=UDim2.new(0,20,0,20); b1.Parent=HUD
    local b2=Instance.new("TextButton"); b2.Name="ShopButton"; b2.Text="상점/제작"; b2.Size=UDim2.new(0,120,0,40); b2.Position=UDim2.new(0,20,0,70); b2.Parent=HUD
    local b3=Instance.new("TextButton"); b3.Name="InventoryButton"; b3.Text="기부(LunarSample x1)"; b3.Size=UDim2.new(0,200,0,40); b3.Position=UDim2.new(0,20,0,120); b3.Parent=HUD
    local b4=Instance.new("TextButton"); b4.Name="MoonButton"; b4.Text="달로 이동"; b4.Size=UDim2.new(0,120,0,40); b4.Position=UDim2.new(0,20,0,170); b4.Parent=HUD
  end

  local QuizUI=pg:FindFirstChild("QuizUI")
  if not QuizUI then
    QuizUI=Instance.new("ScreenGui"); QuizUI.Name="QuizUI"; QuizUI.Enabled=false; QuizUI.Parent=pg
    local f=Instance.new("Frame"); f.Size=UDim2.new(0,400,0,220); f.Position=UDim2.new(0.5,-200,0.5,-110); f.Parent=QuizUI
    local qt=Instance.new("TextLabel"); qt.Name="QuestionText"; qt.Size=UDim2.new(1,-20,0,60); qt.Position=UDim2.new(0,10,0,10); qt.TextWrapped=true; qt.Parent=f
    local ab=Instance.new("TextBox"); ab.Name="AnswerBox"; ab.Size=UDim2.new(1,-20,0,40); ab.Position=UDim2.new(0,10,0,80); ab.ClearTextOnFocus=false; ab.Parent=f
    local submit=Instance.new("TextButton"); submit.Name="SubmitBtn"; submit.Text="제출"; submit.Size=UDim2.new(0,100,0,40); submit.Position=UDim2.new(0,10,0,130); submit.Parent=f
    local close=Instance.new("TextButton"); close.Name="CloseBtn"; close.Text="닫기"; close.Size=UDim2.new(0,100,0,40); close.Position=UDim2.new(0,120,0,130); close.Parent=f
    local res=Instance.new("TextLabel"); res.Name="ResultText"; res.Size=UDim2.new(1,-20,0,30); res.Position=UDim2.new(0,10,0,180); res.Parent=f
  end

  local ShopUI=pg:FindFirstChild("ShopUI")
  if not ShopUI then
    ShopUI=Instance.new("ScreenGui"); ShopUI.Name="ShopUI"; ShopUI.Enabled=false; ShopUI.Parent=pg
    local f=Instance.new("Frame"); f.Size=UDim2.new(0,360,0,260); f.Position=UDim2.new(0.5,-180,0.5,-130); f.Parent=ShopUI
    local s1=Instance.new("TextButton"); s1.Text="구매: Scout-I"; s1.Size=UDim2.new(1,-20,0,40); s1.Position=UDim2.new(0,10,0,10); s1.Parent=f; s1.Name="BuyScout"
    local s2=Instance.new("TextButton"); s2.Text="구매: Explorer-II"; s2.Size=UDim2.new(1,-20,0,40); s2.Position=UDim2.new(0,10,0,60); s2.Parent=f; s2.Name="BuyExplorer"
    local s3=Instance.new("TextButton"); s3.Text="구매: Voyager-III"; s3.Size=UDim2.new(1,-20,0,40); s3.Position=UDim2.new(0,10,0,110); s3.Parent=f; s3.Name="BuyVoyager"
    local s4=Instance.new("TextButton"); s4.Text="구매: Lunar-Module"; s4.Size=UDim2.new(1,-20,0,40); s4.Position=UDim2.new(0,10,0,160); s4.Parent=f; s4.Name="BuyLunar"
    local c1=Instance.new("TextButton"); c1.Text="제작: BasicEngine"; c1.Size=UDim2.new(1,-20,0,40); c1.Position=UDim2.new(0,10,0,210); c1.Parent=f; c1.Name="CraftEngine"
  end
end
ensureGui()

local pg=player:WaitForChild("PlayerGui")
local HUD=pg:WaitForChild("HUD")
local QuizUI=pg:WaitForChild("QuizUI")
local ShopUI=pg:WaitForChild("ShopUI")

HUD.QuizButton.MouseButton1Click:Connect(function() RequestStartQuiz:FireServer(); QuizUI.Enabled=true end)
HUD.ShopButton.MouseButton1Click:Connect(function() ShopUI.Enabled = not ShopUI.Enabled end)
HUD.InventoryButton.MouseButton1Click:Connect(function() DonateMuseumItem:FireServer("LunarSample", 1) end)
HUD.MoonButton.MouseButton1Click:Connect(function() RequestTeleportMoon:FireServer() end)

RequestStartQuiz.OnClientEvent:Connect(function(qText)
  local qt=QuizUI:WaitForChild("QuestionText"); local ab=QuizUI:WaitForChild("AnswerBox"); local res=QuizUI:WaitForChild("ResultText")
  res.Text=""; ab.Text=""; qt.Text=qText or "문제를 불러오는 중..."
end)
QuizUI.SubmitBtn.MouseButton1Click:Connect(function() SubmitQuizAnswer:FireServer(QuizUI.AnswerBox.Text) end)
SubmitQuizAnswer.OnClientEvent:Connect(function(correct, correctAnswer)
  local res=QuizUI.ResultText
  if correct then res.Text="정답! 보상을 획득했습니다." else res.Text="오답! 정답: "..tostring(correctAnswer) end
end)
QuizUI.CloseBtn.MouseButton1Click:Connect(function() QuizUI.Enabled=false end)

ShopUI.BuyScout.MouseButton1Click:Connect(function() RequestPurchaseShip:FireServer("Scout-I") end)
ShopUI.BuyExplorer.MouseButton1Click:Connect(function() RequestPurchaseShip:FireServer("Explorer-II") end)
ShopUI.BuyVoyager.MouseButton1Click:Connect(function() RequestPurchaseShip:FireServer("Voyager-III") end)
ShopUI.BuyLunar.MouseButton1Click:Connect(function() RequestPurchaseShip:FireServer("Lunar-Module") end)
ShopUI.CraftEngine.MouseButton1Click:Connect(function() RequestCraft:FireServer("BasicEngine") end)
