local EnemySpawnManager = {}
EnemySpawnManager.__index = EnemySpawnManager

function EnemySpawnManager.new()
	local self = setmetatable({}, EnemySpawnManager)
	self.EnemyFolder = game.ReplicatedFirst:WaitForChild("Main_RS"):WaitForChild("Zombies")
	self.StagesFolder = workspace:WaitForChild("Stages")
	self.EnemySpawnPoints = workspace:WaitForChild("EnemySpawnPoints"):GetChildren()
	self.EnemySpawnRate = 1
	self.EnemySpawnDelay = 1
	self.EnemySpawnedTable = {}
	self:StartAutoReset()
	return self
end

local StageProbabilities = {
	Stage1 = {Normal = 0.9, Master = 0.1, Boss = 0},
	Stage2 = {Normal = 0.5, Master = 0.5, Boss = 0},
	Stage3 = {Normal = 0.495, Master = 0.495, Boss = 0.01}
}

-- checks target
function EnemySpawnManager:IsTargetAttackable(root, targetRoot)
	if not root or not targetRoot then return false end

	local targetHumanoid = targetRoot.Parent:FindFirstChild("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return false end

	local distance = (targetRoot.Position - root.Position).Magnitude
	if distance > 50 then return false end

	local ray = Ray.new(
		root.Position,
		(targetRoot.Position - root.Position).Unit * distance
	)

	local part = workspace:FindPartOnRayWithIgnoreList(ray, {
		targetRoot.Parent,
		root.Parent
	}, false, true)

	if part then
		return false
	end

	return true
end

-- handles auto reset
function EnemySpawnManager:StartAutoReset()
	task.spawn(function()
		while true do
			task.wait(900)
			self:ResetEnemies()
		end
	end)
end

-- resets all enemies
function EnemySpawnManager:ResetEnemies()
	local stagesToRespawn = {}

	for _, enemy in ipairs(self.EnemySpawnedTable) do
		if enemy and enemy.Parent then
			table.insert(stagesToRespawn, enemy.Parent)
		end
		if enemy then
			enemy:Destroy()
		end
	end

	table.clear(self.EnemySpawnedTable)
	for _, stageFolder in ipairs(stagesToRespawn) do
		self:SpawnEnemy(stageFolder)
	end
end

-- spawns new enemy
function EnemySpawnManager:SpawnEnemy(stageFolder)
	if not stageFolder then return end
	local stageName = stageFolder.Name
	local probabilities = StageProbabilities[stageName]
	if not probabilities then return end

	local randomValue = math.random()
	local EnemyType = "Normal"
	if randomValue <= probabilities.Normal then
		EnemyType = "Normal"
	elseif randomValue <= probabilities.Normal + probabilities.Master then
		EnemyType = "Master"
	elseif probabilities.Boss > 0 then
		EnemyType = "Boss"
	end

	local EnemyModel
	if EnemyType == "Normal" then
		EnemyModel = self.EnemyFolder.Normal.NormalZombie:Clone()
	elseif EnemyType == "Master" then
		EnemyModel = self.EnemyFolder.Master.MasterZombie:Clone()
	elseif EnemyType == "Boss" then
		EnemyModel = self.EnemyFolder.Boss.BossZombie:Clone()
	end

	local spawnPoint = self.EnemySpawnPoints[math.random(#self.EnemySpawnPoints)]
	EnemyModel:SetPrimaryPartCFrame(spawnPoint.CFrame)
	EnemyModel.Parent = stageFolder
	table.insert(self.EnemySpawnedTable, EnemyModel)
	self:EnemyAI(EnemyModel)
end

local AttackFunctions = {}

-- normal zombie attack
function AttackFunctions.Normal(model, targetHumanoid)
	if not targetHumanoid then return end
	targetHumanoid:TakeDamage(10)
end

-- master zombie attack
function AttackFunctions.Master(model, targetHumanoid)
	if not targetHumanoid then return end
	targetHumanoid:TakeDamage(25)
end

-- boss zombie attack
function AttackFunctions.Boss(model, targetHumanoid)
	if not targetHumanoid then return end
	targetHumanoid:TakeDamage(50)
end

-- handles attack state
function EnemySpawnManager:AttackState(model, humanoid, targetRoot)
	if not targetRoot then return end
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- create hitbox
	local hitPart = Instance.new("Part")
	hitPart.Size = Vector3.new(5, 3, 5)
	hitPart.Transparency = 1
	hitPart.CanCollide = false
	hitPart.Anchored = true
	hitPart.CFrame = root.CFrame * CFrame.new(0, -1, -3)
	hitPart.Parent = workspace

	local touchingParts = hitPart:GetTouchingParts()
	hitPart:Destroy()

	local attackedHumanoids = {}
	for _, part in pairs(touchingParts) do
		local character = part:FindFirstAncestorOfClass("Model")
		if character and character ~= model then
			local targetHumanoid = character:FindFirstChild("Humanoid")
			if targetHumanoid and targetHumanoid.Health > 0 then
				if not attackedHumanoids[targetHumanoid] then
					attackedHumanoids[targetHumanoid] = true

					local folderName = model.Parent.Name

					if folderName == "Normal" then
						AttackFunctions.Normal(model, targetHumanoid)
					elseif folderName == "Master" then
						AttackFunctions.Master(model, targetHumanoid)
					elseif folderName == "Boss" then
						AttackFunctions.Boss(model, targetHumanoid)
					end
				end
			end
		end
	end
end

-- handles move state
function EnemySpawnManager:MoveState(root, humanoid, targetRoot, PathfindingService, lastPathTime, RepathCooldown)
	if not targetRoot then return lastPathTime end

	if tick() - lastPathTime >= RepathCooldown then
		local pathParams = {
			AgentCanJump = true,
			AgentRadius = 3,
			AgentHeight = 6,
			Costs = {
				Water = 20,
				DangerZone = math.huge,
				Neon = 10,
				Door = 5
			}
		}

		local path = PathfindingService:CreatePath(pathParams)
		local success, errorMessage = pcall(function()
			path:ComputeAsync(root.Position, targetRoot.Position)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			local nextWaypoint = waypoints[2] or waypoints[1]
			if nextWaypoint then
				humanoid:MoveTo(nextWaypoint.Position)
			end
		end
		lastPathTime = tick()
	end
	return lastPathTime
end

-- handles animation states
function EnemySpawnManager:AnimationState(model, humanoid, state)
	if not model or not humanoid then return end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local currentState = model:GetAttribute("CurrentAnimationState")
	if currentState == state then return end

	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local animationsFolder = model:FindFirstChild("Animations")
	if animationsFolder then
		local animObject = animationsFolder:FindFirstChild(state)
		if animObject and animObject:IsA("Animation") then
			local track = animator:LoadAnimation(animObject)
			track:Play()
		end
	end
	model:SetAttribute("CurrentAnimationState", state)
end

-- handles ai logic
function EnemySpawnManager:EnemyAI(EnemyModel)
	local humanoid = EnemyModel:FindFirstChild("Humanoid")
	local root = EnemyModel:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	local Players = game:GetService("Players")
	local PathfindingService = game:GetService("PathfindingService")
	local RepathCooldown = 0.5
	local lastPathTime = 0

	task.spawn(function()
		while EnemyModel.Parent do
			task.wait(0.2)
			local nearestPlayer = nil
			local shortestDistance = math.huge
			local targetRoot = nil

			for _, player in pairs(Players:GetPlayers()) do
				local char = player.Character
				if char then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local humanoidTarget = char:FindFirstChild("Humanoid")
					if hrp and humanoidTarget and humanoidTarget.Health > 0 then
						if not self:IsTargetAttackable(root, hrp) then
							continue
						end

						local distance = (hrp.Position - root.Position).Magnitude
						if distance < shortestDistance then
							shortestDistance = distance
							nearestPlayer = player
							targetRoot = hrp
						end
					end
				end
			end

			local state = "Idle"
			if targetRoot then
				state = (shortestDistance < 5) and "Attack" or "Move"
			end

			self:AnimationState(EnemyModel, humanoid, state)

			if state == "Attack" then
				self:AttackState(EnemyModel, humanoid, targetRoot)
			elseif state == "Move" then
				lastPathTime = self:MoveState(root, humanoid, targetRoot, PathfindingService, lastPathTime, RepathCooldown)
			end
		end
	end)
end
--i wanna >>>!!!!! the scripter role! <:)> ! <:)> ! <:)>
return EnemySpawnManager
