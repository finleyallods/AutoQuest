function getRewardScore(itemId)
    return itemLib.GetBonus(itemId).innateStats[ENUM_InnateStats_Lifesteal].base
end

function getBestReward(alternativeItems)
    local bestReward
    local bestRewardScore = 0
    for i, itemId in pairs(alternativeItems) do
        local rewardScore = getRewardScore(itemId)
        if rewardScore > bestRewardScore then
            bestReward = itemId
            bestRewardScore = rewardScore
        end
    end

    return bestReward
end

function returnQuest(questId)
    local alternativeItems = avatar.GetQuestReward(questId).alternativeItems
    if #alternativeItems == 0 then
        avatar.ReturnQuest(questId, nil)
    else
        local bestReward = getBestReward(alternativeItems)
        if bestReward then
            avatar.ReturnQuest(questId, nil)
        end
    end
end

function returnQuests()
    local retQuestList = avatar.GetReturnableQuests()
    if retQuestList then
        for i, questId in pairs(retQuestList) do
            returnQuest(questId)
        end
    end
end

function acceptNewQuests()
    local availableQuestList = avatar.GetAvailableQuests()
    if availableQuestList then
        for i, questId in pairs(availableQuestList) do
            local questInfo = avatar.GetQuestInfo(questId)
            if not questInfo.isLowPriority and not questInfo.isRepeatable and questInfo.type < 2 then
                avatar.AcceptQuest(questId)
            end
        end
    end
end

function onInteractionStarted(params)
    if params and avatar.IsTalking() then
        returnQuests()
        acceptNewQuests()
    end
end

function onQuestReceived(params)
    local questId = params.questId
    local questInfo = avatar.GetQuestInfo(questId)

    if questId then
        if questInfo.canBeSkipped and skipFactor * avatar.GetSkipQuestCost(questId) <= avatar.GetDestinyPoints().total then
            avatar.SkipQuest(questId)
        end
        if avatar.IsTalking() then
            onInteractionStarted()
        end
    end
end

function getImprovementIndex(itemId, compatibleSlots)
    local myId = avatar.GetId()
    local improvementIndex = -1

    for i, slotId in pairs(compatibleSlots) do
        local equipmentItemId = unit.GetEquipmentItemId( myId, slotId, ITEM_CONT_EQUIPMENT  )
        if itemLib.GetGearScore(itemId) > itemLib.GetGearScore(equipmentItemId) then
            improvementIndex = improvementIndex + 1
        end
    end

    return improvementIndex
end

function onInventorySlotChanged(params)
    local itemId = params.itemId
    local itemInfo = itemLib.GetItemInfo(itemId)
    local compatibleSlots = itemLib.GetCompatibleSlots(itemId)

    if params.tabIndex > 1 then
        return
    end

     debugMessage("Slot index: " .. tostring(params.slotIndex) .. " Item id: " .. tostring(itemId))
     debugMessage("Compatible slots[" .. tostring(#compatibleSlots) .. "]:" .. table.concat(compatibleSlots, "-"))

    if itemInfo.isDressable and compatibleSlots and #compatibleSlots > 0 then
        local improvementIndex = getImprovementIndex(itemId, compatibleSlots)
        if improvementIndex > 0 then
            avatar.EquipItemToSlot(params.slotIndex, compatibleSlots[improvementIndex])
        end
    end
end

function init()
    common.RegisterEventHandler(onQuestReceived, "EVENT_QUEST_RECEIVED")
    common.RegisterEventHandler(onInteractionStarted, "EVENT_INTERACTION_STARTED")
    common.RegisterEventHandler(onInventorySlotChanged, "EVENT_INVENTORY_SLOT_CHANGED")
end

if (avatar.IsExist()) then
    init()
else
    common.RegisterEventHandler(init, "EVENT_AVATAR_CREATED")
end

