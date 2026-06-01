-- Tests for luau-quest
-- Run with: require(path.to["run-tests"])

local QuestModule = require(script.Parent:FindFirstChild("luau-quest") or script.Parent.Parent.src)
local Quest, QuestTracker, ObjectiveTypes = QuestModule.Quest, QuestModule.QuestTracker, QuestModule.ObjectiveTypes

local passed = 0
local failed = 0

local function assert(condition, message)
    if condition then
        passed = passed + 1
    else
        failed = failed + 1
        warn("FAIL: " .. (message or "assertion failed"))
    end
end

-- Test 1: Quest creation
local q = Quest.new({
    id = "test-1",
    title = "Test Quest",
    description = "Testing",
    objectives = {ObjectiveTypes.BuildStructure({name = "tower", minBlocks = 5})},
    rewards = {{type = "Points", amount = 100}},
})
assert(q.id == "test-1", "quest id")
assert(q.state == "Available", "quest available")
assert(q:isComplete() == false, "not complete yet")

-- Test 2: QuestTracker registration
local tracker = QuestTracker.new()
tracker:register(q)
assert(tracker.quests["test-1"] ~= nil, "registered")

-- Test 3: Start quest
tracker:start("test-1")
assert(q.state == "Active", "quest active")

-- Test 4: Event processing
tracker:onEvent({type = "StructureBuilt", name = "tower"})
assert(q:isComplete() == true, "quest complete after event")

-- Test 5: Progress tracking
local done, total = q:progress()
assert(done == 1, "1 objective done")
assert(total == 1, "1 objective total")

-- Test 6: Prerequisites
local q2 = Quest.new({
    id = "test-2",
    title = "Locked Quest",
    description = "Needs test-1",
    objectives = {ObjectiveTypes.ExploreBiome({count = 3})},
    rewards = {},
    prerequisite = "test-1",
})
tracker:register(q2)
-- test-1 already completed, so prerequisite met
assert(tracker:start("test-2") == true, "prerequisite met")

-- Test 7: Conservation objective
local q3 = Quest.new({
    id = "test-3",
    title = "Conservation",
    description = "Test conservation",
    objectives = {ObjectiveTypes.ConservationChallenge({targetError = 0.01, topology = "graph"})},
    rewards = {},
})
local t3 = QuestTracker.new()
t3:register(q3)
t3:start("test-3")
t3:onEvent({type = "ConservationChecked", topology = "graph", error = 0.005})
assert(q3:isComplete() == true, "conservation complete")

-- Test 8: Multiple objectives
local q4 = Quest.new({
    id = "test-4",
    title = "Multi",
    description = "Multi objective",
    objectives = {
        ObjectiveTypes.BuildStructure({name = "a", minBlocks = 1}),
        ObjectiveTypes.CollectResource({resource = "wood", amount = 3}),
        ObjectiveTypes.ExploreBiome({count = 2}),
    },
    rewards = {},
})
local t4 = QuestTracker.new()
t4:register(q4)
t4:start("test-4")
t4:onEvent({type = "StructureBuilt", name = "a"})
assert(q4:isComplete() == false, "1/3 not complete")
t4:onEvent({type = "ResourceCollected", resource = "wood", amount = 3})
assert(q4:isComplete() == false, "2/3 not complete")
t4:onEvent({type = "BiomeExplored", biome = "Forest"})
t4:onEvent({type = "BiomeExplored", biome = "Desert"})
assert(q4:isComplete() == true, "3/3 complete")

-- Test 9: ExploreBiome counts unique
local q5 = Quest.new({
    id = "test-5",
    title = "Unique",
    description = "Unique biomes",
    objectives = {ObjectiveTypes.ExploreBiome({count = 2})},
    rewards = {},
})
local t5 = QuestTracker.new()
t5:register(q5)
t5:start("test-5")
t5:onEvent({type = "BiomeExplored", biome = "Forest"})
t5:onEvent({type = "BiomeExplored", biome = "Forest"}) -- same biome twice
assert(q5:isComplete() == false, "duplicate biome doesn't count")
t5:onEvent({type = "BiomeExplored", biome = "Desert"})
assert(q5:isComplete() == true, "2 unique biomes")

-- Test 10: Available quests filtering
local t10 = QuestTracker.new()
local q10a = Quest.new({id = "a", title = "A", description = "", objectives = {}, rewards = {}})
local q10b = Quest.new({id = "b", title = "B", description = "", objectives = {}, rewards = {}, prerequisite = "a"})
t10:register(q10a)
t10:register(q10b)
local avail = t10:available()
assert(#avail == 1, "only quest without prereq available")

print(string.format("=== luau-quest: %d passed, %d failed ===", passed, failed))
