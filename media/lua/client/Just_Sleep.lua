local originalSleepOption = ISWorldObjectContextMenu.doSleepOption

function ISWorldObjectContextMenu.doSleepOption(context, bed, player, playerObj)
	-- Avoid player sleeping inside a car from the context menu, new radial menu does that now
	if(playerObj:getVehicle() ~= nil) then return end
	if(bed and bed:getSquare():getRoom() ~= playerObj:getSquare():getRoom()) then return end
    local text = getText(bed and "ContextMenu_Sleep" or "ContextMenu_SleepOnGround")
    local sleepOption = context:addOption(text, bed, ISWorldObjectContextMenu.onSleep, player);
    -- Not tired enough
    -- MOD CHANGE START --
    --local sleepNeeded = not isClient() or getServerOptions():getBoolean("SleepNeeded")
    --if sleepNeeded and playerObj:getStats():getFatigue() <= 0.3 then
    --    sleepOption.notAvailable = true;
    --    tooltipText = getText("IGUI_Sleep_NotTiredEnough");
--[[
    --Player outside.
    elseif bed and (playerObj:isOutside()) and RainManager:isRaining() then
        local square = getCell():getGridSquare(bed:getX(), bed:getY(), bed:getZ() + 1);
        if square == nil or square:getFloor() == nil then
            if bed:getName() ~= "Tent" then
                sleepOption.notAvailable = true;
                local tooltip = ISWorldObjectContextMenu.addToolTip();
                tooltip:setName(getText("ContextMenu_Sleeping"));
                tooltip.description = getText("IGUI_Sleep_OutsideRain");
                sleepOption.toolTip = tooltip;
            end
        end
--]]
--    end

    -- Sleeping pills counter those sleeping problems
    --if playerObj:getSleepingTabletEffect() < 2000 then
        -- In pain, can still sleep if really tired
        --if playerObj:getMoodles():getMoodleLevel(MoodleType.Pain) > 2 and playerObj:getStats():getFatigue() <= 0.85 then
        --    sleepOption.notAvailable = true;
        --    tooltipText = getText("ContextMenu_PainNoSleep");
        -- In panic
        --elseif playerObj:getMoodles():getMoodleLevel(MoodleType.Panic) >= 1 then
        --    sleepOption.notAvailable = true;
        --    tooltipText = getText("ContextMenu_PanicNoSleep");
        -- tried to sleep not so long ago
        --elseif sleepNeeded and (playerObj:getHoursSurvived() - playerObj:getLastHourSleeped()) <= 1 then
        --    sleepOption.notAvailable = true;
        --    tooltipText = getText("ContextMenu_NoSleepTooEarly");
        --end
    --end
    -- MOD CHANGE END --

    if bed then
        local bedType = bed:getProperties():Val("BedType") or "averageBed";
        local bedTypeXln = getTextOrNull("Tooltip_BedType_" .. bedType)
        if bedTypeXln then
            tooltipText = getText("Tooltip_BedType", bedTypeXln)
        end
    end

    if tooltipText then
        local sleepTooltip = ISWorldObjectContextMenu.addToolTip();
        sleepTooltip:setName(getText("ContextMenu_Sleeping"));
        sleepTooltip.description = tooltipText;
        sleepOption.toolTip = sleepTooltip;
    end
end

local originalSleepWalkToComplete = ISWorldObjectContextMenu.onSleepWalkToComplete

function ISWorldObjectContextMenu.onSleepWalkToComplete(player, bed)
    local playerObj = getSpecificPlayer(player)
    -- MOD CHANGE START --
    --if playerObj:getMoodles():getMoodleLevel(MoodleType.Panic) >= 1 then
    --    playerObj:Say(getText("ContextMenu_PanicNoSleep"))
    --    return
    --end
    -- MOD CHANGE END --
    ISTimedActionQueue.clear(playerObj)
    local bedType = "badBed";
    if bed then
        bedType = bed:getProperties():Val("BedType") or "averageBed";
    elseif playerObj:getVehicle() then
        bedType = "averageBed";
    else
        bedType = "floor";
    end
    if isClient() and getServerOptions():getBoolean("SleepAllowed") then
        playerObj:setAsleepTime(0.0)
        playerObj:setAsleep(true)
        UIManager.setFadeBeforeUI(player, true)
        UIManager.FadeOut(player, 1)
        return
    end

    playerObj:setBed(bed);
    playerObj:setBedType(bedType);
    local modal = nil;
    local sleepFor = ZombRand(playerObj:getStats():getFatigue() * 10, playerObj:getStats():getFatigue() * 13) + 1;

    if bedType == "goodBed" then
        sleepFor = sleepFor -1;
    end
    if bedType == "badBed" then
        sleepFor = sleepFor +1;
    end
    if bedType == "floor" then
        sleepFor = sleepFor * 0.7;
    end
    if playerObj:HasTrait("Insomniac") then
        sleepFor = sleepFor * 0.5;
    end
    if playerObj:HasTrait("NeedsLessSleep") then
        sleepFor = sleepFor * 0.75;
    end
    if playerObj:HasTrait("NeedsMoreSleep") then
        sleepFor = sleepFor * 1.18;
    end

    if sleepFor > 16 then sleepFor = 16; end
    if sleepFor < 3 then sleepFor = 3; end
    --print("GONNA SLEEP " .. sleepFor .. " HOURS" .. " AND ITS " .. GameTime.getInstance():getTimeOfDay())
    local sleepHours = sleepFor + GameTime.getInstance():getTimeOfDay()
    if sleepHours >= 24 then
        sleepHours = sleepHours - 24
    end
    -- MOD CHANGE START --
    -- Only setForceWakeUpTime when playing in singleplayer
    if not(isServer()) then
        playerObj:setForceWakeUpTime(tonumber(sleepHours))
    else
        -- Circumvents the ForceWakeUpTime == 0 check, but is still caught by the SleepTime >= 16 hours check
        playerObj:setForceWakeUpTime(-1.0)
    end
    -- MOD CHANGE END --
    playerObj:setAsleepTime(0.0)
    playerObj:setAsleep(true)
    getSleepingEvent():setPlayerFallAsleep(playerObj, sleepFor);

    UIManager.setFadeBeforeUI(playerObj:getPlayerNum(), true)
    UIManager.FadeOut(playerObj:getPlayerNum(), 1)

    if IsoPlayer.allPlayersAsleep() then
        UIManager.getSpeedControls():SetCurrentGameSpeed(3)
        save(true)
    end
end


function fatigueReduction()
    -- By how much additional Percentage Points the fatigue will be reduced every 10 in-game minutes asleep

    local fatigueReductionValue = sandboxOptions.fatigueReduction / 100
    for playerIndex = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerIndex)

        if player:isAsleep() then
            player:getStats():setFatigue(player:getStats():getFatigue() - fatigueReductionValue)
        end
    end
end

--if sandboxOptions.enableFatigueReduction:
--    Events.EveryTenMinutes.Add(additionalFatigueReduction)