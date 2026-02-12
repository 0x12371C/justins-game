local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local config = require(sharedFolder:WaitForChild("EnvironmentCycleConfig"))

local SKY_PROPERTIES = {
	"CelestialBodiesShown",
	"MoonAngularSize",
	"MoonTextureId",
	"SkyboxBk",
	"SkyboxDn",
	"SkyboxFt",
	"SkyboxLf",
	"SkyboxRt",
	"SkyboxUp",
	"StarCount",
	"SunAngularSize",
	"SunTextureId",
}

local function normalizeAlias(raw: any, aliases: { [string]: { string } }): string?
	if typeof(raw) ~= "string" then
		return nil
	end

	local value = string.lower(raw)
	for key, tokens in pairs(aliases) do
		if value == key then
			return key
		end
		for _, token in ipairs(tokens) do
			if value == token then
				return key
			end
		end
	end

	return nil
end

local function findAliasInName(nameLower: string, aliases: { [string]: { string } }): string?
	for key, tokens in pairs(aliases) do
		for _, token in ipairs(tokens) do
			if string.find(nameLower, token, 1, true) then
				return key
			end
		end
	end

	return nil
end

local function buildTemplateList(): { { sky: Sky, phase: string?, weather: string? } }
	local templates = {}

	for _, descendant in ipairs(Lighting:GetDescendants()) do
		if descendant:IsA("Sky") and descendant.Name ~= config.activeSkyName then
			local nameLower = string.lower(descendant.Name)
			local phase = normalizeAlias(descendant:GetAttribute("Phase"), config.phaseAliases)
				or findAliasInName(nameLower, config.phaseAliases)
			local weather = normalizeAlias(descendant:GetAttribute("Weather"), config.weatherAliases)
				or findAliasInName(nameLower, config.weatherAliases)

			table.insert(templates, {
				sky = descendant,
				phase = phase,
				weather = weather,
			})
		end
	end

	return templates
end

local function ensureActiveSky(): Sky
	local existing = Lighting:FindFirstChild(config.activeSkyName)
	if existing and not existing:IsA("Sky") then
		existing:Destroy()
		existing = nil
	end

	if existing and existing:IsA("Sky") then
		return existing
	end

	local activeSky = Instance.new("Sky")
	activeSky.Name = config.activeSkyName
	activeSky.Parent = Lighting
	return activeSky
end

local function applySky(source: Sky, target: Sky)
	for _, property in ipairs(SKY_PROPERTIES) do
		local gotValue, value = pcall(function()
			return (source :: any)[property]
		end)
		if gotValue then
			pcall(function()
				(target :: any)[property] = value
			end)
		end
	end
end

local function resolvePhase(clockTime: number): string
	local dawn = config.phaseStarts.dawn
	local day = config.phaseStarts.day
	local dusk = config.phaseStarts.dusk
	local night = config.phaseStarts.night

	if clockTime >= night or clockTime < dawn then
		return "night"
	end
	if clockTime < day then
		return "dawn"
	end
	if clockTime < dusk then
		return "day"
	end
	return "dusk"
end

local function chooseWeighted(weights: { [string]: number }, previous: string?): string
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end

	if total <= 0 then
		return previous or "clear"
	end

	for attempt = 1, 3 do
		local roll = math.random() * total
		local running = 0

		for state, weight in pairs(weights) do
			running += weight
			if roll <= running then
				if state ~= previous or attempt == 3 then
					return state
				end
				break
			end
		end
	end

	return previous or "clear"
end

local function scoreTemplate(entry: { phase: string?, weather: string? }, phase: string, weather: string): number
	local score = 0

	if entry.phase == phase then
		score += 4
	elseif entry.phase == nil then
		score += 1
	else
		score -= 2
	end

	if entry.weather == weather then
		score += 3
	elseif entry.weather == nil then
		score += 1
	else
		score -= 2
	end

	return score
end

local function selectTemplate(
	templates: { { sky: Sky, phase: string?, weather: string? } },
	phase: string,
	weather: string,
	variantIndex: number
): Sky?
	local candidates: { Sky } = {}
	local bestScore = -math.huge

	for _, entry in ipairs(templates) do
		local score = scoreTemplate(entry, phase, weather)
		if score > bestScore then
			bestScore = score
			candidates = { entry.sky }
		elseif score == bestScore then
			table.insert(candidates, entry.sky)
		end
	end

	if #candidates == 0 then
		return nil
	end

	local index = ((variantIndex - 1) % #candidates) + 1
	return candidates[index]
end

math.randomseed(DateTime.now().UnixTimestampMillis % 2147483647)

local activeSky = ensureActiveSky()
local dayLengthSeconds = math.max(60, config.dayLengthMinutes * 60)
local weatherMin = math.max(10, config.weatherMinSeconds)
local weatherMax = math.max(weatherMin, config.weatherMaxSeconds)

local weather = chooseWeighted(config.weatherWeights, nil)
local weatherSwapAt = os.clock() + math.random(weatherMin, weatherMax)
local startedAt = os.clock()
local lastSky: Sky? = nil
local templates = buildTemplateList()
local nextRescanAt = 0
local lastPhase = resolvePhase(Lighting.ClockTime)
local lastWeather = weather
local variantIndex = 1

while true do
	local now = os.clock()

	if now >= nextRescanAt then
		templates = buildTemplateList()
		nextRescanAt = now + config.templateRescanSeconds
	end

	local dayProgress = ((now - startedAt) % dayLengthSeconds) / dayLengthSeconds
	local clockTime = dayProgress * 24
	Lighting.ClockTime = clockTime

	if now >= weatherSwapAt then
		weather = chooseWeighted(config.weatherWeights, weather)
		weatherSwapAt = now + math.random(weatherMin, weatherMax)
	end

	if #templates > 0 then
		local phase = resolvePhase(clockTime)

		if phase ~= lastPhase or weather ~= lastWeather then
			variantIndex += 1
			lastPhase = phase
			lastWeather = weather
		end

		local nextSky = selectTemplate(templates, phase, weather, variantIndex)
		if nextSky and nextSky ~= lastSky then
			applySky(nextSky, activeSky)
			lastSky = nextSky
		end
	end

	task.wait(config.updateIntervalSeconds)
end
