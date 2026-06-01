# luau-quest

> Quests that teach mathematics through Roblox gameplay. Build structures, explore biomes, check conservation laws — and learn real math without knowing it.

## What This Does

Quest/mission system for Roblox games. Define quests with objectives, track progress through game events, unlock rewards. Built for educational games where every quest teaches a mathematical concept.

## Install

### Wally
```toml
[dependencies]
Quest = "superinstance/luau-quest@0.1.0"
```

### Manual
Copy `src/` into ReplicatedStorage as ModuleScripts.

## Quick Start

```lua
local QuestModule = require(path.to["luau-quest"])
local Quest, QuestTracker, ObjectiveTypes = QuestModule.Quest, QuestModule.QuestTracker, QuestModule.ObjectiveTypes

-- Define a quest
local conservationQuest = Quest.new({
    id = "first-conservation",
    title = "The Conservationist",
    description = "Check if your world's energy is conserved!",
    objectives = {
        ObjectiveTypes.ConservationChallenge({targetError = 0.01, topology = "simple-graph"}),
        ObjectiveTypes.BuildStructure({name = "energy-meter", minBlocks = 10}),
    },
    rewards = {
        {type = "Badge", name = "conservation-novice"},
        {type = "UnlockBiome", biome = "CrystalCaves"},
    },
})

-- Track it
local tracker = QuestTracker.new()
tracker:register(conservationQuest)
tracker:start("first-conservation")

-- Game events advance progress
tracker:onEvent({type = "ConservationChecked", topology = "simple-graph", error = 0.005})
tracker:onEvent({type = "StructureBuilt", name = "energy-meter"})

-- Check completion
local done, total = conservationQuest:progress()
print(string.format("Progress: %d/%d", done, total))
-- → Progress: 2/2

print(conservationQuest.state) -- → "Complete"
```

## Objective Types

| Type | Event | Teaches |
|------|-------|---------|
| `BuildStructure` | `StructureBuilt` | Spatial reasoning |
| `ObserveRoom` | `RoomVisited` | Data collection |
| `ConservationChallenge` | `ConservationChecked` | Conservation laws |
| `TeachAgent` | `AgentTrained` | Machine learning |
| `ExploreBiome` | `BiomeExplored` | Diversity, topology |
| `CollectResource` | `ResourceCollected` | Arithmetic, ratios |

## API Reference

### Quest.new(definition)
Creates a quest from: id, title, description, objectives, rewards, prerequisite, repeatable.

### QuestTracker
| Method | Description |
|--------|-------------|
| `:register(quest)` | Add quest to tracker |
| `:start(questId)` | Activate quest (checks prerequisites) |
| `:onEvent(event)` | Process game event (advances objectives) |
| `:available()` | Quests ready to start |
| `:active()` | Currently in-progress |
| `:completedQuests()` | Finished quests |

### ObjectiveTypes
| Factory | Parameters |
|---------|-----------|
| `.BuildStructure({name, minBlocks})` | Build something |
| `.ObserveRoom({roomId, minReadings})` | Visit and collect data |
| `.ConservationChallenge({targetError, topology})` | Verify math |
| `.ExploreBiome({count})` | Visit different biomes |
| `.CollectResource({resource, amount})` | Gather materials |
| `.TeachAgent({agentId, targetAccuracy})` | Train an AI |

## License

MIT
