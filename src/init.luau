-- luau-quest: Quest/mission system for Roblox games
-- Teaches real math through gameplay

local Quest = {}
Quest.__index = Quest

-- Objective types
local ObjectiveTypes = {
    BuildStructure = "BuildStructure",       -- {name: string, minBlocks: number}
    ObserveRoom = "ObserveRoom",             -- {roomId: string, minReadings: number}
    ConservationChallenge = "Conservation",  -- {targetError: number, topology: string}
    TeachAgent = "TeachAgent",               -- {agentId: string, targetAccuracy: number}
    ExploreBiome = "ExploreBiome",           -- {count: number}
    CollaborateWith = "CollaborateWith",     -- {count: number}
    CollectResource = "CollectResource",     -- {resource: string, amount: number}
}

ObjectiveTypes.__index = ObjectiveTypes
setmetatable(ObjectiveTypes, ObjectiveTypes)

function ObjectiveTypes.BuildStructure(params: {name: string, minBlocks: number})
    return {
        type = "BuildStructure",
        name = params.name,
        minBlocks = params.minBlocks,
        progress = 0,
        completed = false,
    }
end

function ObjectiveTypes.ObserveRoom(params: {roomId: string, minReadings: number})
    return {
        type = "ObserveRoom",
        roomId = params.roomId,
        minReadings = params.minReadings,
        progress = 0,
        completed = false,
    }
end

function ObjectiveTypes.ConservationChallenge(params: {targetError: number, topology: string})
    return {
        type = "ConservationChallenge",
        targetError = params.targetError,
        topology = params.topology,
        progress = 0,
        completed = false,
    }
end

function ObjectiveTypes.ExploreBiome(params: {count: number})
    return {
        type = "ExploreBiome",
        count = params.count,
        visitedBiomes = {},
        completed = false,
    }
end

function ObjectiveTypes.CollectResource(params: {resource: string, amount: number})
    return {
        type = "CollectResource",
        resource = params.resource,
        amount = params.amount,
        collected = 0,
        completed = false,
    }
end

-- Reward types
export type Reward = 
    {type: "Badge", name: string} |
    {type: "UnlockBiome", biome: string} |
    {type: "Points", amount: number} |
    {type: "UnlockAgent", ability: string}

-- Quest definition
export type QuestDefinition = {
    id: string,
    title: string,
    description: string,
    objectives: {any},
    rewards: {Reward},
    prerequisite: string?,  -- quest ID that must be completed first
    repeatable: boolean?,
}

function Quest.new(def: QuestDefinition)
    local self = setmetatable({}, Quest)
    self.id = def.id
    self.title = def.title
    self.description = def.description
    self.objectives = def.objectives
    self.rewards = def.rewards
    self.prerequisite = def.prerequisite
    self.repeatable = def.repeatable or false
    self.state = "Available"  -- Available, Active, Complete
    return self
end

function Quest:isComplete(): boolean
    for _, obj in ipairs(self.objectives) do
        if not obj.completed then
            return false
        end
    end
    return true
end

function Quest:progress(): (number, number)
    local done = 0
    local total = #self.objectives
    for _, obj in ipairs(self.objectives) do
        if obj.completed then
            done = done + 1
        end
    end
    return done, total
end

-- QuestTracker
local QuestTracker = {}
QuestTracker.__index = QuestTracker

function QuestTracker.new()
    local self = setmetatable({}, QuestTracker)
    self.quests = {}        -- id → Quest
    self.completed = {}     -- set of completed quest IDs
    return self
end

function QuestTracker:register(quest: Quest)
    self.quests[quest.id] = quest
end

function QuestTracker:start(questId: string): boolean
    local quest = self.quests[questId]
    if not quest then return false end
    
    -- Check prerequisite
    if quest.prerequisite and not self.completed[quest.prerequisite] then
        return false
    end
    
    quest.state = "Active"
    return true
end

-- Game events that can advance quest progress
function QuestTracker:onEvent(event: {type: string, [string]: any})
    for _, quest in pairs(self.quests) do
        if quest.state == "Active" then
            self:_processEvent(quest, event)
        end
    end
end

function QuestTracker:_processEvent(quest: Quest, event: {type: string, [string]: any})
    for _, obj in ipairs(quest.objectives) do
        if not obj.completed then
            self:_checkObjective(quest, obj, event)
        end
    end
    
    if quest:isComplete() then
        quest.state = "Complete"
        self.completed[quest.id] = true
    end
end

function QuestTracker:_checkObjective(quest: Quest, obj: any, event: {type: string, [string]: any})
    if obj.type == "BuildStructure" and event.type == "StructureBuilt" then
        if event.name == obj.name then
            obj.completed = true
        end
    elseif obj.type == "ObserveRoom" and event.type == "RoomVisited" then
        if event.roomId == obj.roomId then
            obj.progress = (obj.progress or 0) + 1
            if obj.progress >= obj.minReadings then
                obj.completed = true
            end
        end
    elseif obj.type == "ConservationChallenge" and event.type == "ConservationChecked" then
        if event.topology == obj.topology and event.error <= obj.targetError then
            obj.completed = true
        end
    elseif obj.type == "ExploreBiome" and event.type == "BiomeExplored" then
        if not obj.visitedBiomes[event.biome] then
            obj.visitedBiomes[event.biome] = true
            local count = 0
            for _ in pairs(obj.visitedBiomes) do count = count + 1 end
            if count >= obj.count then
                obj.completed = true
            end
        end
    elseif obj.type == "CollectResource" and event.type == "ResourceCollected" then
        if event.resource == obj.resource then
            obj.collected = (obj.collected or 0) + event.amount
            if obj.collected >= obj.amount then
                obj.completed = true
            end
        end
    elseif obj.type == "TeachAgent" and event.type == "AgentTrained" then
        if event.agentId == obj.agentId and event.accuracy >= obj.targetAccuracy then
            obj.completed = true
        end
    end
end

function QuestTracker:available(): {Quest}
    local result = {}
    for _, quest in pairs(self.quests) do
        if quest.state == "Available" then
            if not quest.prerequisite or self.completed[quest.prerequisite] then
                table.insert(result, quest)
            end
        end
    end
    return result
end

function QuestTracker:active(): {Quest}
    local result = {}
    for _, quest in pairs(self.quests) do
        if quest.state == "Active" then
            table.insert(result, quest)
        end
    end
    return result
end

function QuestTracker:completedQuests(): {Quest}
    local result = {}
    for id, _ in pairs(self.completed) do
        local quest = self.quests[id]
        if quest then
            table.insert(result, quest)
        end
    end
    return result
end

function QuestTracker:getStatus(questId: string): {state: string, progress: (number, number), rewards: {Reward}}?
    local quest = self.quests[questId]
    if not quest then return nil end
    local done, total = quest:progress()
    return {
        state = quest.state,
        progress = (done, total),
        rewards = quest.rewards,
    }
end

return {
    Quest = Quest,
    QuestTracker = QuestTracker,
    ObjectiveTypes = ObjectiveTypes,
}
