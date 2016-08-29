-- X-Wing Automatic Movement - Hera Verito (Jstek), March 2016
-- X-Wing Arch and Range Ruler - Flolania, March 2016
-- X-Wing Auto Dial Integration - Flolania, March 2016
-- X-Wing Auto Tokens - Hera Verito (Jstek), March 2016
-- X-Wing Auto Bump Rewrite of Movement Code - Flolania, May 2016

-- August 2016:
-- - Disabled printing "This dial was not saved" since it was triggered by ANYTHING
-- - Changed autolock feature (setlock) to nudge ship down instead of triggering in-air
-- - Added shuffle-on-load to damage decks (external script)
-- - Changed ruler to more accurate version (to be tested)
-- TO_DO:
-- - Change all GUID handling to object reference handling
-- - Separate "Auto Dial" functionality from movement functionality
-- - Change big base ship detection to more structured one
-- - Change thousand-if-else trees into a nice extensible table holding cases and responses
-- - Figure out how to shift most functionality OUT of update() called each frame....
-- - Finally, make this a contained enitity with proper API, event calls etc.

--UndoData
UndoInfo = {}

--NameInfo
namelist1 = {}

--Auto Dials
dialpositions = {}

--Auto Token Movement
tokenInfo = {}

--Collider Infomation
BigShipList = {'https://paste.ee/r/LIxnJ','https://paste.ee/r/v9OYL','https://paste.ee/r/XoXqn','https://paste.ee/r/oOjRN','https://paste.ee/r/v8OYL','https://paste.ee/r/xBpMo','https://paste.ee/r/k4DLM','https://paste.ee/r/JavTd','http://pastebin.com/Tg5hdRTM'}

-- Auto Actions
--enemy_target_locks = nil
freshLock = nil
focus = nil --'beca0f'
evade = nil --'4a352e'
stress = nil --'a25e12'
target = nil --'c81580'


function onload(save_string)
    if save_string ~= "" then
        local data = JSON.decode(save_string)
        for i, card in pairs(data) do
            local cardtable = {}
            local obj = getObjectFromGUID(card["GUID"])
            if obj ~= nil then
                cardtable["GUID"] = card["GUID"]
                cardtable["Position"] = {card["Positionx"],card["Positiony"],card["Positionz"]}
                cardtable["Rotation"] = {card["Rotationx"],card["Rotationy"],card["Rotationz"]}
                cardtable["ShipGUID"] = card["ShipGUID"]
                cardtable["ShipName"] = card["ShipName"]
                cardtable["BoostDisplayed"] = card["BoostDisplayed"]
                cardtable["BarrelRollDisplayed"] = card["BarrelRollDisplayed"]
                cardtable["RangeDisplayed"] = card["RangeDisplayed"]
                cardtable["RulerObject"] = card["RulerObject"]
                cardtable["Color"] = nil
                cardtable["ActionState"] = 0
                ---DELETE ME x2
                cardtable["LeftZone"] = false
                cardtable["HasButtons"] = false
                obj.Unlock()
                obj.clearButtons()
                obj.setPosition ({card["Positionx"],card["Positiony"],card["Positionz"]})
                obj.setRotation ({card["Rotationx"],card["Rotationy"],card["Rotationz"]})
                obj.setVar('Lock',false)
                obj.setName( card["ShipName"])
                getObjectFromGUID(card["ShipGUID"]).setVar('HasDial',false)
                dialpositions[#dialpositions +1] = cardtable
            else
                printToAll('ERROR - Missing dial for ' .. card["ShipName"] .. '. Continue to rewind or redo storedial command.',{0.2,0.2,0.8})
            end
        end
    end

--    enemy_target_locks = findObjectByNameAndType("Enemy Target Locks", "Infinite").getGUID()
    focus = findObjectByNameAndType("Focus", "Infinite").getGUID()
    evade = findObjectByNameAndType("Evade", "Infinite").getGUID()
    stress = findObjectByNameAndType("Stress", "Infinite").getGUID()
    target = findObjectByNameAndType("Target Locks", "Infinite").getGUID()
end

function onSave()
    local save = {}
    for i, card in ipairs(dialpositions) do
        local data = {}
        data["GUID"] = card["GUID"]
        data["Positionx"] = card["Position"][1]
        data["Positiony"] = card["Position"][2]
        data["Positionz"] = card["Position"][3]
        data["Rotationx"] = card["Rotation"][1]
        data["Rotationy"] = card["Rotation"][2]
        data["Rotationz"] = card["Rotation"][3]
        data["ShipGUID"] = card["ShipGUID"]
        data["ShipName"] = card["ShipName"]
        data["BoostDisplayed"] = card["BoostDisplayed"]
        data["BarrelRollDisplayed"] = card["BarrelRollDisplayed"]
        data["RangeDisplayed"] = card["RangeDisplayed"]
        data["RulerObject"] = card["RulerObject"]
        data["Color"] = card["Color"]
        data["LeftZone"] = card["LeftZone"]
        data["HasButtons"] = card["HasButtons"]
        save[card["GUID"]] = data
    end
    local save_string = JSON.encode_pretty(save)
    return save_string
end

function onObjectLeaveScriptingZone(zone, object)
    if object.tag == 'Card' and object.getDescription() ~= '' then
        local CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            local obj = getObjectFromGUID(CardData["ShipGUID"])
            if obj.getVar('HasDial') == true then
                ---DELETE ME (if statement) but keep the print
                if CardData["HasButtons"] == false then
                    printToColor(CardData["ShipName"] .. ' already has a dial.', object.held_by_color, {0.2,0.2,0.8})
                else
                    CardData["LeftZone"] = true
                end
            else
                obj.setVar('HasDial', true)
                CardData["Color"] = object.held_by_color
                CardData["LeftZone"] = true
                CardData["HasButtons"] = true
                local flipbutton = {['click_function'] = 'CardFlipButton', ['label'] = 'Flip', ['position'] = {0, -1, 1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
        		object.createButton(flipbutton)
                local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {0, -1, -1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(deletebutton)
                object.setVar('Lock',true)
            end
    	else
            --printToColor('That dial was not saved.', object.held_by_color, {0.2,0.2,0.8})
        end
    end
end


function onObjectEnterScriptingZone(zone, object)
    ---DELETE ME ALL OF ME HERE
    if dialpositions[1] ~= nil then
        local CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            CardData["LeftZone"] = false
        end
    end
end

--is the owners hand within 2 units of this object?
function PlayerCheck(Color, GUID)
    local PC = false
    if getPlayer(Color) ~= nil then
        local HandPos = getPlayer(Color).getPointerPosition()
        local DialPos = getObjectFromGUID(GUID).getPosition()
        ---DELETE ME
        local CardData = dialpositions[CardInArray(GUID)]
        -----
        if distance(HandPos['x'],HandPos['z'],DialPos['x'],DialPos['z']) < 2 then
            ----DELETE ME THE IF KEEP THE PC=TRUE
            if CardData["LeftZone"] == true then
                PC = true
            else
                printToColor('Cannot use buttons down here. Unlock. Drag to main play area and click buttons there.', CardData["Color"], {0.4,0.6,0.2})
            end
        end
    end
    return PC
end

function CardInArray(GUID)
    local CIAPos = nil
    for i, card in ipairs(dialpositions) do
        if GUID == card["GUID"] then
            CIAPos = i
        end
    end
    return CIAPos
end


function CardFlipButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        object.setRotation({0,CardData["Rotation"][2],0})
        object.clearButtons()
        local movebutton = {['click_function'] = 'CardMoveButton', ['label'] = 'Move', ['position'] = {-0.32, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 530, ['font_size'] = 250}
        object.createButton(movebutton)
        local actionbuttonbefore = {['click_function'] = 'CardActionButtonBefore', ['label'] = 'A', ['position'] = {-0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(actionbuttonbefore)
    end
end

function CardMoveButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],object.getDescription())
        object.clearButtons()
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
        local actionbuttonafter = {['click_function'] = 'CardActionButtonAfter', ['label'] = 'A', ['position'] = {-0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(actionbuttonafter)
        local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {-0.32, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 530, ['font_size'] = 250}
        object.createButton(deletebutton)
        CallActionButton(object, true, 0)
    end
end

function CallActionButton(object, fseu, state)
    -- fseu = true = show false = noshow
    -- state type of buttns.. 0 = nothing 1 = normal action
    if fseu == true then
        local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(focusbutton)
        local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(stressbutton)
        local Evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {0.9, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(Evadebutton)
        local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'Q', ['position'] = {-0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(undobutton)
    end
    if state == 1 then
        local BoostLeft = {['click_function'] = 'CardBoostLeft', ['label'] = 'BL', ['position'] = {-0.75, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostLeft)
        local BoostCenter = {['click_function'] = 'CardBoostCenter', ['label'] = 'B', ['position'] = {0, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostCenter)
        local BoostRight = {['click_function'] = 'CardBoostRight', ['label'] = 'BR', ['position'] = {0.75, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostRight)
        local BRLeftTop = {['click_function'] = 'CardBRLeftTop', ['label'] = 'XF', ['position'] = {-1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftTop)
        local BRLeftCenter = {['click_function'] = 'CardBRLeftCenter', ['label'] = 'XL', ['position'] = {-1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftCenter)
        local BRLeftBack = {['click_function'] = 'CardBRLeftBack', ['label'] = 'XB', ['position'] = {-1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftBack)
        local BRRightTop = {['click_function'] = 'CardBRRightTop', ['label'] = 'XF', ['position'] = {1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightTop)
        local BRRightCenter = {['click_function'] = 'CardRightCenter', ['label'] = 'XR', ['position'] = {1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightCenter)
        local BRRightBack = {['click_function'] = 'CardRightBack', ['label'] = 'XB', ['position'] = {1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightBack)
        local TargetLock = {['click_function'] = 'CardTargetLock', ['label'] = 'TL', ['position'] = {-0.75, 1, 2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(TargetLock)
        local rangebutton = {['click_function'] = 'CardRangeButton', ['label'] = 'R', ['position'] = {0.75, 1, 2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(rangebutton)
    end
end

function DeleteActionButton(object,fseu,state)
    --fseu true = delete, false = nodelete
    --state = 1 deletenormal
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if fseu == true then
        object.removeButton(2)
        object.removeButton(3)
        object.removeButton(4)
        object.removeButton(5)
    end
    if state == 1 then
        for i=6,16,1 do
            object.removeButton(i)
        end
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
    end
end

function CardActionButtonBefore(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["ActionState"] == 0 then
            CallActionButton(object, true, 1)
            CardData["ActionState"] = 1
        elseif CardData["ActionState"] == 1 then
            DeleteActionButton(object,true,1)
            CardData["ActionState"] = 0
        end
    end
end

function CardActionButtonAfter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["ActionState"] == 0 then
            CallActionButton(object, false, 1)
            CardData["ActionState"] = 1
        elseif CardData["ActionState"] == 1 then
            DeleteActionButton(object,false,1)
            CardData["ActionState"] = 0
        end
    end
end

function CardRangeButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["RangeDisplayed"] == false then
            CardData["RangeDisplayed"] = true
            CardData["RulerObject"] = ruler(CardData["ShipGUID"],2)
        else
            CardData["RangeDisplayed"] = false
            actionButton(CardData["RulerObject"])
        end
    end
end

function CardBoostLeft(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'bl1')
        end
    end
end
function CardBoostCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'s1')
        end
    end
end
function CardBoostRight(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'br1')
        end
    end
end
function CardBRLeftTop(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xlf')
        end
    end
end
function CardBRLeftCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xl')
        end
    end
end
function CardBRLeftBack(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xlb')
        end
    end
end
function CardBRRightTop(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xrf')
        end
    end
end
function CardRightCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xr')
        end
    end
end
function CardRightBack(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xrb')
        end
    end
end

function CardTargetLock(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(target, CardData["ShipGUID"],0.5,1,-0.5,true,CardData["Color"],CardData["ShipName"])
        notify(CardData["ShipGUID"],'action','acquires a target lock')
    end
end

function CardFocusButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(focus, CardData["ShipGUID"],-0.5,1,-0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes a focus token')
    end
end

function CardStressButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(stress, CardData["ShipGUID"],0.5,1,0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes stress')
    end
end

function CardEvadeButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(evade, CardData["ShipGUID"],-0.5,1,0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes an evade token')
    end
end

function CardUndoButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
        check(CardData["ShipGUID"],'undo')
    end
end


function CardDeleteButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        getObjectFromGUID(CardData["ShipGUID"]).setVar('HasDial',false)
        object.Unlock()
        object.clearButtons()
        DeleteMoveButtons(getObjectFromGUID(CardData["ShipGUID"]))
        object.setPosition (CardData["Position"])
        object.setRotation (CardData["Rotation"])
        object.setVar('Lock',false)
        CardData["Color"] = nil
        ---DELETE ME x2
        CardData["HasButtons"] = false
        CardData["LeftZone"] = false
    end
end

function resetdials(guid,notice)
    local obj = getObjectFromGUID(guid)
    local index = {}
    for i, card in ipairs(dialpositions) do
        if guid == card["ShipGUID"] then
            index[#index + 1] = i
        end
    end
    obj.setVar('HasDial',false)
    if notice == 1 then
        printToAll(#index .. ' dials removed for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
    end
    for i=#index,1,-1 do
        table.remove(dialpositions, index[i])
    end
    setpending(guid)
end

function checkdials(guid)
    resetdials(guid,0)
    local obj = getObjectFromGUID(guid)
    local count = 0
    local display = false
    local error = false
    local deckerror = false
    for i,card in ipairs(getAllObjects()) do
        local cardpos = card.getPosition()
        local objpos = obj.getPosition()
        if distance(cardpos[1],cardpos[3],objpos[1],objpos[3]) < 5.5 then
            if cardpos[3] >= 18 or cardpos[3] <= -18 then
                if card.tag == 'Card' and card.getDescription() ~= '' then
                    local CardData = dialpositions[CardInArray(card.getGUID())]
                    if CardData == nil then
                        count = count + 1
                        local cardtable = {}
                        cardtable["GUID"] = card.getGUID()
                        cardtable["Position"] = card.getPosition()
                        cardtable["Rotation"] = card.getRotation()
                        cardtable["ShipGUID"] = obj.getGUID()
                        cardtable["ShipName"] = obj.getName()
                        cardtable["ActionState"] = 0
                        cardtable["BoostDisplayed"] = false
                        cardtable["BarrelRollDisplayed"] = false
                        cardtable["RangeDisplayed"] = false
                        cardtable["RulerObject"] = nil
                        cardtable["Color"] = nil
                        ---DELETE ME
                        cardtable["LeftZone"] = false
                        cardtable["HasButtons"] = false
                        --------END DELETE ME
                        obj.setVar('HasDial',false)
                        dialpositions[#dialpositions +1] = cardtable
                        card.setName(obj.getName())
                    else
                        display = true
                    end
                end
                if card.tag == 'Deck' then
                    deckerror = true
                end
            else
                error = true
            end
        end
    end
    if display == true then
        printToAll('Error: ' .. obj.getName() .. ' attempted to save dials already saved to another ship. Use rd on old ship first.',{0.2,0.2,0.8})
    end
    if deckerror == true then
        printToAll('Error: Cannot save dials in deck format.',{0.2,0.2,0.8})
    end
    if error == true then
        printToAll('Caution: Cannot save dials in main play area.',{0.2,0.2,0.8})
    end
    if count <= 20 then
        printToAll(count .. ' dials saved for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
    else
        resetdials(guid,0)
        printToAll('Error: Tried to save to many dials for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
    end
    setpending(guid)
end

function SpawnDialGuide(guid)
    local shipobject = getObjectFromGUID(guid)
    local world = shipobject.getPosition()
    local direction = shipobject.getRotation()
    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.15, world[3]}
    obj_parameters.rotation = { 0, direction[2], 0 }
    local DialGuide = spawnObject(obj_parameters)
    local custom = {}
    custom.mesh = 'http://pastebin.com/raw/qPcTJZyP'
    custom.collider = 'http://pastebin.com/raw.php?i=UK3Urmw1'

    DialGuide.setCustomObject(custom)
    DialGuide.lock()
    DialGuide.scale({'.4','.4','.4'})

    local button = {['click_function'] = 'GuideButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 270, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 250}
    DialGuide.createButton(button)
    shipobject.setDescription('Pending')
    checkdials(guid)
end

function GuideButton(object)
    object.destruct()
end

function SpawnMove(guid)
    local obj = getObjectFromGUID(guid)
    local MoveForward = {['click_function'] = 'MoveForward', ['label'] = 'Front', ['position'] = {0, 0.2, -0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 350, ['font_size'] = 250}
    obj.createButton(MoveForward)
    local MoveBackward = {['click_function'] = 'MoveBackward', ['label'] = 'Back', ['position'] = {0, 0.2, 0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 350, ['font_size'] = 250}
    obj.createButton(MoveBackward)
end

function MoveForward(object)
    MiscMovement(object.getGUID(),0.362,4,2,'tinyfoward',nil)
    object.clearButtons()
end

function MoveBackward(object)
    MiscMovement(object.getGUID(),-0.362,4,3,'tinybackward',nil)
    object.clearButtons()
end

function DeleteMoveButtons(object)
    --would do --clearbuttons, but ai script plus first real ship buttons
    if object.getButtons() ~= nil then
        for i, button in pairs(object.getButtons()) do
            if button.label == 'Front' or button.label == 'Back' then
                object.removeButton(button.index)
            end
        end
    end

end

function update ()
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' then
            local shipguid = ship.getGUID()
            local shipname = ship.getName()
            local shipdesc = ship.getDescription()
            checkname(shipguid,shipdesc,shipname)
            check(shipguid,shipdesc)
        end
        if ship.getVar('Lock') == true and ship.held_by_color == nil and ship.resting == true then
            if ship.getPosition()['y'] <= 1.5 then
                ship.setVar('Lock',false)
                ship.lock()
            else
                ship.setPositionSmooth({ship.getPosition()['x'], ship.getPosition()['y']-0.1, ship.getPosition()['z']})
            end
        end
        if ship.getVar('Token') == true and ship.held_by_color == nil and ship.resting == true then
            ship.setVar('Token',false)
            tokens(ship.getGUID(),2)
        end
    end
end

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function take(parent, guid, xoff, yoff, zoff, TL, color, name)
    local obj = getObjectFromGUID(guid)
    local objp = getObjectFromGUID(parent)
    local world = obj.getPosition()

    --VALADIAN Rotate Take to be relative position
    local offset = RotateVector({xoff, yoff, zoff}, obj.getRotation()[2])

    local params = {}
    params.position = {world[1]+offset[1], world[2]+offset[2], world[3]+offset[3]}
    if TL == true then
        local callback_params = {}
        callback_params['player_color'] = color
        callback_params['ship_name'] = name
        params.callback = 'setNewLock'
        params.callback_owner = Global
        params.params = callback_params
    end
    freshLock = objp.takeObject(params)
end

function setNewLock(object, params)
    freshLock.call('manualSet', {params['player_color'], params['ship_name']})
end

function RotateVector(direction, yRotation)
    local rotval = round(yRotation)
    local radrotval = math.rad(rotval)
    local xDistance = math.cos(radrotval) * direction[1] + math.sin(radrotval) * direction[3]
    local zDistance = math.sin(radrotval) * direction[1] * -1 + math.cos(radrotval) * direction[3]
    return {xDistance, direction[2], zDistance}
end

function findObjectByNameAndType(name, type)
    for i,obj in ipairs(getAllObjects()) do
        if obj.getName()==name and obj.tag == type then return obj end
    end
end

function distance(x,y,a,b)
    x = (x-a)*(x-a)
    y = (y-b)*(y-b)
    return math.sqrt(math.abs((x+y)))
end

function undo(guid,redo)
    --guid object
    --redo = true for redo and false for undo
    local obj = getObjectFromGUID(guid)
    --would do --clearbuttons, but ai script plus first real ship buttons
    DeleteMoveButtons(obj)

    for i, ship in pairs(UndoInfo) do
        if ship["Position"][1] ~= nil then
            if i == guid then
                if ship["Location"] == 0 then
                    if redo == false then
                        printToAll(obj.getName() .. ' cannot undo any further.', {0.5, 0, 1})
                        break
                    end
                elseif ship["Location"] + 1 >= #ship["Position"] then
                    if redo == true then
                        printToAll(obj.getName() .. ' cannot redo any further.', {0.5, 0, 1})
                        break
                    end
                end
                tokens(guid, 1)
                if redo == true then
                    ship["Location"] = ship["Location"] + 1
                    notify(guid,'redo',ship["Move"][ship["Location"]])
                end
                if redo == false then
                    ship["Location"] = ship["Location"] - 1
                    notify(guid,'undo',ship["Move"][ship["Location"] + 1])
                end
                obj.setPosition(ship["Position"][ship["Location"] + 1])
                obj.setRotation(ship["Rotation"][ship["Location"] + 1])
            end
        end
    end
    setpending(guid)
end

function storeundo(guid,move)
    --guid of object
    --move = move string
    local obj = getObjectFromGUID(guid)
    if UndoInfo[guid] == nil then
        local undotable = {}
        local postable = {}
        local rottable = {}
        local movetable = {}
        postable[1] = obj.getPosition()
        rottable[1] = obj.getRotation()
        movetable[1] = move
        undotable["Position"] = postable
        undotable["Rotation"] = rottable
        undotable["Move"] = movetable
        undotable["Location"] = 1
        UndoInfo[guid] = undotable
    else
        for i, ship in pairs(UndoInfo) do
            table.insert(ship["Position"],ship["Location"] + 1,obj.getPosition())
            table.insert(ship["Rotation"],ship["Location"] + 1,obj.getRotation())
            table.insert(ship["Move"],ship["Location"] + 1,move)
            ship["Location"] = ship["Location"] + 1
        end
    end

end

function registername(guid)
    local obj = getObjectFromGUID(guid)
    local name = obj.getName()
    namelist1[guid] = name
    setlock(guid)
end

function checkname(guid,move,name)
    if move == 'Pending' then
        if namelist1[guid] == nil then
            namelist1[guid] = name
        end
    end
end

function fixname(guid)
    if namelist1[guid] ~= nil then
        local obj = getObjectFromGUID(guid)
        obj.setName(namelist1[guid])
    end
end

function setpending(guid)
    fixname(guid)
    local obj = getObjectFromGUID(guid)
    obj.setDescription('Pending')
end

function setlock(guid)
    fixname(guid)
    local obj = getObjectFromGUID(guid)
    obj.setVar('Lock',true)
    setpending(guid)
end

function checkpos(guid)
    setpending(guid)
    local obj = getObjectFromGUID(guid)
    local world = obj.getPosition()
    for i, v in ipairs(world) do
        print(v)
    end
end

function checkrot(guid)
    setpending(guid)
    local obj = getObjectFromGUID(guid)
    local world = obj.getRotation()
    for i, v in ipairs(world) do
        print(v)
    end
end



function CloakMoves(toCheck)
    --stupid buttons on objects
    if toCheck[2] == 1000 then
        DeleteMoveButtons(toCheck[1])
    else
        check(toCheck[1],toCheck[2])
    end
end

function ruler_old(guid,action)
    -- action for 1 for display button 2 for not
    local shipobject = getObjectFromGUID(guid)
    local shipname = shipobject.getName()
    local direction = shipobject.getRotation()
    local world = shipobject.getPosition()
    local scale = shipobject.getScale()

    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.28, world[3]}
    obj_parameters.rotation = { 0, direction[2] +180, 0 }
    local newruler = spawnObject(obj_parameters)
    local custom = {}
    if isBigShip(guid) == true then
        custom.mesh = 'http://pastebin.com/raw/3AU6BBjZ'
        custom.collider = 'https://paste.ee/r/JavTd'
    else
        custom.mesh = 'http://pastebin.com/raw/wkfqqnwX'
        custom.collider = 'https://paste.ee/r/6jn13'
    end
    newruler.setCustomObject(custom)
    newruler.lock()
    newruler.scale(scale)
    setpending(guid)
    if action == 2 then
        return newruler
    else
        local button = {['click_function'] = 'actionButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1300, ['height'] = 1300, ['font_size'] = 250}
        newruler.createButton(button)
    end
    notify(guid,'r')
end

function ruler(guid,action)
    -- action for 1 for display button 2 for not
    local shipobject = getObjectFromGUID(guid)
    local shipname = shipobject.getName()
    local direction = shipobject.getRotation()
    local world = shipobject.getPosition()
    local scale = shipobject.getScale()

    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.06, world[3]}
    obj_parameters.rotation = { 0, direction[2] +180, 0 }
    local newruler = spawnObject(obj_parameters)
    local custom = {}
    if isBigShip(guid) == true then
        --custom.mesh = 'http://pastebin.com/raw/3AU6BBjZ'
        custom.mesh = 'https://paste.ee/r/9uhlG'
        custom.diffuse = 'http://i.imgur.com/8YupgGf.png'
        --custom.collider = 'https://paste.ee/r/JavTd'
        custom.collider = 'https://paste.ee/r/DQ1ip'
    else
        --custom.mesh = 'http://pastebin.com/raw/wkfqqnwX'
        custom.mesh = 'https://paste.ee/r/9uhlG'
        custom.diffuse = 'http://i.imgur.com/MAtF9s9.png'
        --custom.collider = 'https://paste.ee/r/6jn13'
        custom.collider = 'https://paste.ee/r/DQ1ip'
    end
    newruler.setCustomObject(custom)
    newruler.lock()
    newruler.scale(scale)
    setpending(guid)
    if action == 2 then
        return newruler
    else
        local button = {['click_function'] = 'actionButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1300, ['height'] = 1300, ['font_size'] = 250}
        newruler.createButton(button)
    end
    notify(guid,'r')
end

function actionButton(object)
    object.destruct()
end

function BumpButton(guid)
    local obj = getObjectFromGUID(guid)
    local button = {}
    if isBigShip(guid) == true then
        button = {['click_function'] = 'deletebump', ['label'] = 'BUMPED', ['position'] = {0, 0.2, 2}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 350, ['font_size'] = 250}
    else
        button = {['click_function'] = 'deletebump', ['label'] = 'BUMPED', ['position'] = {0, 0.3, 0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 350, ['font_size'] = 250}
    end
    obj.createButton(button)
end

function deletebump(object)
    object.removeButton(0)
end

function isBigShip(guid)
    local obj = getObjectFromGUID(guid)
    local Properties = obj.getCustomObject()
    for i,ship in pairs(BigShipList) do
        if Properties.collider == ship then
            return true
        end
    end
    return false
end

function notify(guid,move,text,ship)
    if text == nil then
        text = ''
    end
    local obj = getObjectFromGUID(guid)
    local name = obj.getName()
    if move == 'undo' then
        printToAll(name .. ' performed an undo of ' .. text .. '.', {0, 1, 0})
    elseif move == 'redo' then
        printToAll(name .. ' performed a redo of ' .. text .. '.', {0, 1, 0})
    elseif move == 'set' then
        printToAll(name .. ' set name.', {0, 1, 1})
    elseif move == 'r' then
        printToAll(name .. ' spawned a ruler.', {0, 0, 1})
    elseif move == 'action' then
        printToAll(name .. ' ' .. text .. '.', {0.959999978542328 , 0.439000010490417 , 0.806999981403351})
    elseif move == 'keep' then
        printToAll(name .. ' stored his position.', {0.5, 0, 1})
    elseif move == 'decloak' then
        printToAll(name .. ' cannot decloak.', {0.5, 1, 0.9})
    else
        if ship ~= nil then
            printToAll(name .. ' attemped a (' .. move .. ') but is now touching ' .. ship .. '.', {0.9, 0.5, 0})
        else
            printToAll(name .. ' ' .. text ..' (' .. move .. ').', {1, 0, 0})
        end
    end
end

function check(guid,move)
    -- --test function for when I test something
    -- if move == 'a' then
    --     setpending(guid)
    -- end

        -- Ruler Commands
    if move == 'r' or move == 'ruler' then
        ruler(guid,1)
    elseif move == 'rr' then
        ruler_old(guid,1)

        -- Auto Dial Commands
    elseif move == 'sd' or move == 'storedial' or move == 'storedials' then
        if move == 'sd' then
          checkdials(guid)
        else
          SpawnDialGuide(guid)
        end
    elseif move == 'rd' or move == 'removedial' or move == 'removedials' then
        resetdials(guid, 1)

        -- Straight Commands
    elseif move == 's0' then
        notify(guid,move,'is stationary')
        storeundo(guid,move)
        setpending(guid)
    elseif move == 's1' then
        straight(guid,2.9,false,move,'flew straight 1')
    elseif move == 's2' then
        straight(guid,4.35,false,move,'flew straight 2')
    elseif move == 's3' then
        straight(guid,5.79,false,move,'flew straight 3')
    elseif move == 's4' then
        straight(guid,7.25,false,move,'flew straight 4')
    elseif move == 's5' then
        straight(guid,8.68,false,move,'flew straight 5')

        -- Bank Commands
    elseif move == 'br1' then
        turnShip(guid,3.689526061,1,0,false,move,'banked right 1')
    elseif move == 'br2' then
        turnShip(guid,5.490753857,1,0,false,move,'banked right 2')
    elseif move == 'br3' then
        turnShip(guid,7.363015996,1,0,false,move,'banked right 3')
    elseif move == 'bl1' or move == 'be1' then
        turnShip(guid,3.689526061,0,0,false,move,'banked left 1')
    elseif move == 'bl2' or move == 'be2' then
        turnShip(guid,5.490753857,0,0,false,move,'banked left 2')
    elseif move == 'bl3' or move == 'be3' then
        turnShip(guid,7.363015996,0,0,false,move,'banked left 3')

        -- Turn Commands
    elseif move == 'tr1' then
        turnShip(guid,2,1,1,false,move,'turned right 1')
    elseif move == 'tr2' then
        turnShip(guid,3,1,1,false,move,'turned right 2')
    elseif move == 'tr3' then
        turnShip(guid,4,1,1,false,move,'turned right 3')
    elseif move == 'tl1' or move == 'te1' then
        turnShip(guid,2,0,1,false,move,'turned left 1')
    elseif move == 'tl2' or move == 'te2' then
        turnShip(guid,3,0,1,false,move,'turned left 2')
    elseif move == 'tl3' or move == 'te3' then
        turnShip(guid,4,0,1,false,move,'turned left 3')

        -- Koiogran Turn Commands
    elseif move == 'k2' then
        straight(guid,4.35,true,move,'koiogran turned 2')
    elseif move == 'k3' then
        straight(guid,5.79,true,move,'koiogran turned 3')
    elseif move == 'k4' then
        straight(guid,7.25,true,move,'koiogran turned 4')
    elseif move == 'k5' then
        straight(guid,8.68,true,move,'koiogran turned 5')

        -- Segnor's Loop Commands
    elseif move == 'bl2s' or move == 'be2s' then
        turnShip(guid,5.490753857,0,0,true,move,'segnors looped left 2')
    elseif move == 'bl3s' or move == 'be3s' then
        turnShip(guid,7.363015996,0,0,true,move,'segnors looped left 3')
    elseif move == 'br2s' then
        turnShip(guid,5.490753857,1,0,true,move,'segnors looped right 2')
    elseif move == 'br3s' then
        turnShip(guid,7.363015996,1,0,true,move,'segnors looped right 3')

        --Talon Roll Commmands
    elseif move == 'tl3t' or move == 'te3t' then
        turnShip(guid,4,0,1,true,move,'tallon rolled left 3')
    elseif move == 'tr3t' then
        turnShip(guid,4,1,1,true,move,'tallon rolled right 3')
    elseif move == 'tl2t' or move == 'te2t' then
        turnShip(guid,3,0,1,true,move,'tallon rolled left 2')
    elseif move == 'tr2t' then
        turnShip(guid,3,1,1,true,move,'tallon rolled right 2')

        -- Barrel Roll Commands
    elseif move == 'xl' or move == 'xe' then
        MiscMovement(guid,0,1,0,move,'barrel rolled left')
    elseif move == 'xlf' or move == 'xef' or move == 'rolllf' or move == 'rollet' then
        MiscMovement(guid,0.73999404907227,1,0,move,'barrel rolled forward left')
    elseif move == 'xlb' or move == 'xeb' or move == 'rolllb'  or move == 'rolleb' then
        MiscMovement(guid,-0.73999404907227,1,0,move,'barrel rolled backwards left')
    elseif move == 'xr' or move == 'rollr'then
        MiscMovement(guid,0,1,1,move,'barrel rolled right')
    elseif move == 'xrf' or move == 'rollrf' then
        MiscMovement(guid,0.73999404907227,1,1,move,'barrel rolled forward right')
    elseif move == 'xrb' or move == 'rollrb' then
        MiscMovement(guid,-0.73999404907227,1,1,move,'barrel rolled backwards right')

        -- Decloak Commands
    elseif move == 'cs' or move == 'cf' then
        MiscMovement(guid,4.35,2,2,move,'decloaked straight')
    elseif move == 'cl' or move == 'ce' then
        MiscMovement(guid,0,2,0,move,'decloaked left')
    elseif move == 'clf' or move == 'cef' then
        MiscMovement(guid,0.73999404907227,2,0,move,'decloaked forward left')
    elseif move == 'clb' or move == 'ceb' then
        MiscMovement(guid,-0.73999404907227,2,0,move,'decloaked backwards left')
    elseif move == 'cr' then
        MiscMovement(guid,0,2,1,move,'decloaked right')
    elseif move == 'crf' then
        MiscMovement(guid,0.73999404907227,2,1,move,'decloaked forward right')
    elseif move == 'crb' then
        MiscMovement(guid,-0.73999404907227,2,1,move,'decloak backwards right')

        -- Echo Decloak
    elseif move == 'cefr' then
        MiscMovement(guid,4.59,3,1,move,'decloak forward right')
    elseif move == 'cefl' then
        MiscMovement(guid,4.59,3,0,move,'decloak forward left')
    elseif move == 'celff' then
        MiscMovement(guid,2.33,3,0,move,'decloak left forward forward')
    elseif move == 'celbb' then
        MiscMovement(guid,-2.33,3,0,move,'decloak left back back')
    elseif move == 'cerff' then
        MiscMovement(guid,2.33,3,1,move,'decloak right forward forward')
    elseif move == 'cerbb' then
        MiscMovement(guid,-2.33,3,1,move,'decloak right back back')

    elseif move == 'celfb' then
        MiscMovement(guid,1.55,3,0,move,'decloak left forward back')
    elseif move == 'celbf' then
        MiscMovement(guid,-1.55,3,0,move,'decloak left back forward')
    elseif move == 'cerfb' then
        MiscMovement(guid,1.55,3,1,move,'decloak right forward back')
    elseif move == 'cerbf' then
        MiscMovement(guid,-1.55,3,1,move,'decloak right back forward')



        -- MISC Commands
    elseif move == 'checkpos' then
        checkpos(guid)
    elseif move == 'checkrot' then
        checkrot(guid)
    elseif move == 'keep' then
        storeundo(guid,'keep')
        notify(guid,move)
        setpending(guid)
    elseif move == 'set' then
        registername(guid)
        notify(guid,move)
    elseif move == 'undo' or move == 'q' then
        undo(guid,false)
    elseif move == 'redo' or move == 'z' then
        undo(guid,true)
    end
end

function tokens(guid, state)
    -- guid of the ship with Tokens
    -- state = 1 = save 2 = move
    local obj = getObjectFromGUID(guid)
    local pos = obj.getPosition()
    local rot = obj.getRotation()
    if state == 1 then
        if tokenInfo ~= nil then
            local index = {}
            for i, token in ipairs(tokenInfo) do
                if guid == token["ShipGUID"] then
                    index[#index + 1] = i
                end
            end
            for i=#index,1,-1 do
                table.remove(tokenInfo, index[i])
            end
        end
        for i, token in ipairs(getAllObjects()) do
            local dist = distance(pos[1],pos[3],token.getPosition()[1],token.getPosition()[3])
            if isBigShip(guid) == true then
                dist = dist - 0.6
            end
            if token.tag == 'Chip' and dist < 1 then
                local tokentable = {}
                tokentable["GUID"] = token.getGUID()
                tokentable["ShipGUID"] = guid
                tokentable["Position"] = token.getPosition()
                tokentable["Vector"] = {token.getPosition()[1]-pos[1],token.getPosition()[2]-pos[2],token.getPosition()[3]-pos[3]}
                tokenInfo[#tokenInfo +1] = tokentable
            end
        end
        obj.setVar('Token',true)
    end
    if state == 2 then
        for i, token in ipairs(tokenInfo) do
            if guid == token["ShipGUID"] then
                local object = getObjectFromGUID(token["GUID"])
                object.setPosition({pos[1] + token["Vector"][1], token["Position"][2],pos[3] + token["Vector"][3]})
            end
        end
    end
end

function MiscMovement(guid,forwardDistance,type,direction,move,text)
    --guid = ship moving
    --type 1 = barrel roll 2 = decloak 3 = decloak echo 4 = talon roll
    --direction = 0 left 1 right  2 forward 3 backwards
    --forwardDistance = distance to be traveled
    storeundo(guid,move)
    tokens(guid, 1)
    local obj = getObjectFromGUID(guid)
    obj.unlock()
    local sidewaysDistance = 0
    if type == 1 then
        --barrel roll
        sidewaysDistance = 2.8863945007324
    elseif type == 2 then
        --decloak
        if direction == 2 then
            sidewaysDistance = 0
        else
            sidewaysDistance = 4.3295917510986
        end
    end
    if isBigShip(guid) == true then
        --barrelroll
        if type == 1 then
            --barrel roll
            sidewaysDistance = 3.6147861480713
            forwardDistance = forwardDistance*2
        elseif type == 2 then
            --nocloak big ships
            move = 'decloak'
            forwardDistance = 0
            sidewaysDistance = 0
        end
    end
    if type == 3 then
        --echo decloack
        if move == 'cefr' or move == 'cefl' then
            sidewaysDistance = 1.89
        else
            sidewaysDistance = 4.575
        end
    end
    local rot = obj.getRotation()
    local world = obj.getPosition()
    local radrotval = math.rad(rot[2])
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    --left is - and + is right
    if direction == 0 then
        radrotval = radrotval - math.rad(90)
    elseif direction == 1 then
        radrotval = radrotval + math.rad(90)
    end
    xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    local rotate = 0
    if type == 3 then
        --echo decloak rotation
        if move == 'cefr' then
            rotate = rotate + 45
        elseif move == 'cefl' then
            rotate = rotate - 45
        else
            if direction == 0 then
                if forwardDistance > 0 then
                    rotate = rotate + 45
                elseif forwardDistance < 0 then
                    rotate = rotate - 45
                end
            elseif direction == 1 then
                if forwardDistance > 0 then
                    rotate = rotate - 45
                elseif forwardDistance < 0 then
                    rotate = rotate + 45
                end
            end
            SpawnMove(guid)
        end
    end
    obj.Rotate({0, rotate, 0})
    if text ~= nil then
        notify(guid,move,text)
    end
    setlock(guid)
end

function turnShip(guid,radius,direction,type,kturn,move,text)
    --radius = turn radius
    --direction = 0  - left  1 - right
    --type = 0 - 45 deg   1 - 90 deg
    --kturn = true false
    --guid = ship moving
    -- move and text for notify
    storeundo(guid,move)
    tokens(guid, 1)
    local obj = getObjectFromGUID(guid)
    obj.unlock()
    local rot = obj.getRotation()
    local pos = obj.getPosition()
    local degree = {}
    if type == 0 then
        degree = 45
    elseif type == 1 then
        degree = 90
    end
    local BumpingObjects = posbumps(guid, direction)
    local Bumped = {false, nil}
    local coords,theta = turncoords(guid,radius,direction,degree,type)
    if BumpingObjects ~= nil then
        for k=#BumpingObjects ,1,-1 do
            local doescollide = collide(pos[1]+coords[1],pos[3]+coords[2],rot[2]+theta,guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
            if doescollide == true then
                forwardDistance = 0.734
                if isBigShip(guid) == true then
                    forwardDistance = forwardDistance * 2
                end
                for e2=1, 100, 1 do
                    local checkdistance = forwardDistance*(e2/100)
                    xDistance = math.sin(math.rad(rot[2]+theta)) * checkdistance * -1
                    zDistance = math.cos(math.rad(rot[2]+theta)) * checkdistance * -1
                    local doescollide2 = collide(pos[1]+coords[1]-xDistance,pos[3]+coords[2]-zDistance,rot[2]+theta,guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
                    if doescollide2 == false then
                        forwardDistance = 0
                        Bumped = {true, k}
                        break
                    end
                end
                if forwardDistance ~= 0 then
                    for e2=degree, 1, -1 do
                        local checkdegree = e2
                        coords,theta = turncoords(guid,radius,direction,checkdegree,type)
                        local doescollide3 = collide(pos[1]+coords[1],pos[3]+coords[2],rot[2]+theta,guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
                        if doescollide3 == false then
                            degree = checkdegree
                            Bumped = {true, k}
                            break
                        end
                    end
                end
            end
        end
    end
    if forwardDistance == 0 then
        obj.setPosition({pos[1] + coords[1]-xDistance, 2, pos[3] + coords[2]-zDistance})
    else
        obj.setPosition({pos[1] + coords[1], 2, pos[3] + coords[2]})
    end

    if kturn == true and Bumped[1] == false then
        if type == 0 then
            theta = theta - 180
        else
            if direction == 0 then
                theta = theta - 90
            else
                theta = theta + 90
            end
            SpawnMove(guid)
        end
    end
    obj.Rotate({0, theta, 0})
    if Bumped[1] == true then
        BumpButton(guid)
        notify(guid,move,text,BumpingObjects[Bumped[2]]["ShipName"])
    else
        notify(guid,move,text)
    end
    setlock(guid)
end

function straight(guid,forwardDistance,kturn,move,text)
    -- guid = ship moving
    -- forwardDistance = amount to move forwardDistance
    -- kturn true or false
    -- move and text for notify
    storeundo(guid,move)
    tokens(guid, 1)
    local obj = getObjectFromGUID(guid)
    obj.unlock()
    local pos = obj.getPosition()
    local rot = obj.getRotation()
    if isBigShip(guid) == true then
        forwardDistance = 1.468 + forwardDistance
    end
    local Bumped = {false , nil}
    local BumpingObjects = posbumps(guid, 2)
    local xDistance = math.sin(math.rad(rot[2])) * forwardDistance * -1
    local zDistance = math.cos(math.rad(rot[2])) * forwardDistance * -1
    if BumpingObjects ~= nil then
        for k=#BumpingObjects ,1,-1 do
            local doescollide = collide(pos[1]+xDistance,pos[3]+zDistance,rot[2],guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
            if doescollide == true then
                for e2=100, 1, -1 do
                    local checkdistance = forwardDistance*(e2/100)
                    xDistance = math.sin(math.rad(rot[2])) * checkdistance * -1
                    zDistance = math.cos(math.rad(rot[2])) * checkdistance * -1
                    local doescollide2 = collide(pos[1]+xDistance,pos[3]+zDistance,rot[2],guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
                    if doescollide2 == false then
                        forwardDistance = checkdistance
                        Bumped = {true, k}
                        break
                    end
                end
            end
        end
    end
    obj.setPosition({pos[1]+xDistance, pos[2]+2, pos[3]+zDistance})
    if kturn == true and Bumped[1] == false then
        obj.Rotate({0, 180, 0})
    else
        obj.Rotate({0, 0, 0})
    end
    if Bumped[1] == true then
        BumpButton(guid)
        notify(guid,move,text,BumpingObjects[Bumped[2]]["ShipName"])
    else
        notify(guid,move,text)
    end
    setlock(guid)
end



function turncoords(guid,radius,direction,theta,type)
    -- DO NOT CALL THIS USE TURN
    -- guid = ship moving
    -- radius of turn
    -- direction 0 left    1 right
    -- theta = 0 to 90
    -- type = 0 for 45 or 1 for 90
    -- This can be condensed alot by another function
    -- to lazy atm
    local scale = 0.734
    radius = (math.sqrt((radius - scale) * (radius - scale) * 2))/2

    if isBigShip(guid) == true then
        scale = scale * 2
    end

    local obj = getObjectFromGUID(guid)
    local rot = obj.getRotation()
    local pos = obj.getPosition()
    local xLeftDistance = pos[1] + radius * math.sin(math.rad(rot[2] + 135 - theta)) - radius * math.cos(math.rad(rot[2] + 135 - theta))
    local yLeftDistance = pos[3] + radius * math.cos(math.rad(rot[2] + 135 - theta)) + radius * math.sin(math.rad(rot[2] + 135 - theta))
    local xRightDistance = pos[1] + radius * math.sin(math.rad(rot[2] - 45 + theta)) - radius * math.cos(math.rad(rot[2] - 45 + theta))
    local yRightDistance = pos[3] + radius * math.cos(math.rad(rot[2] - 45 + theta)) + radius * math.sin(math.rad(rot[2] - 45 + theta))

    local rvector = {pos[1] + radius * math.sin(math.rad(rot[2]-45)) - radius * math.cos(math.rad(rot[2]-45)), pos[3] + radius * math.cos(math.rad(rot[2]-45)) + radius * math.sin(math.rad(rot[2]-45))}
    local rnvector = {math.sin(math.rad(rot[2] +90))* -1, math.cos(math.rad(rot[2]+90))* -1}
    rnvector = getNormal(rnvector[1],rnvector[2])
    rnvector = {rnvector[1]*scale,rnvector[2]*scale}

    local lvector = {pos[1] + radius * math.sin(math.rad(rot[2]+135)) - radius * math.cos(math.rad(rot[2]+135)), pos[3] + radius * math.cos(math.rad(rot[2]+135)) + radius * math.sin(math.rad(rot[2]+135))}
    local lnvector = {math.sin(math.rad(rot[2] -90))* -1,  math.cos(math.rad(rot[2]-90))* -1}
    lnvector = getNormal(lnvector[1],lnvector[2])
    lnvector = {lnvector[1]*scale,lnvector[2]*scale}

    local fvector = {pos[1] + radius * math.sin(math.rad(rot[2]-135)) - radius * math.cos(math.rad(rot[2]-135)), pos[3] + radius * math.cos(math.rad(rot[2]-135)) + radius * math.sin(math.rad(rot[2]-135))}
    local fnvector = {math.sin(math.rad(rot[2])) * -1, math.cos(math.rad(rot[2])) * -1}
    fnvector = getNormal(fnvector[1],fnvector[2])
    fnvector = {fnvector[1]*scale,fnvector[2]*scale}

    local fnhalfrvector = {math.sin(math.rad(rot[2]+45)) * -1, math.cos(math.rad(rot[2]+45)) * -1}
    fnhalfrvector = getNormal(fnhalfrvector[1],fnhalfrvector[2])
    fnhalfrvector = {fnhalfrvector[1]*scale,fnhalfrvector[2]*scale}

    local fnhalflvector = {math.sin(math.rad(rot[2]-45)) * -1, math.cos(math.rad(rot[2]-45)) * -1}
    fnhalflvector = getNormal(fnhalflvector[1],fnhalflvector[2])
    fnhalflvector = {fnhalflvector[1]*scale,fnhalflvector[2]*scale}

    local newleftturnvector = {lvector[1]-xLeftDistance+ fnvector[1],lvector[2]-yLeftDistance+ fnvector[2]}
    local newrightturnvector = {rvector[1]-xRightDistance+ fnvector[1],rvector[2]-yRightDistance+ fnvector[2]}

    if type == 1 then
        if theta == 90 then
            newleftturnvector = {newleftturnvector[1]+lnvector[1] ,newleftturnvector[2]+lnvector[2]}
            newrightturnvector = {newrightturnvector[1]+rnvector[1],newrightturnvector[2]+rnvector[2]}
        end
    elseif type == 0 then
        if theta == 45 then
            newleftturnvector = {newleftturnvector[1]+fnhalflvector[1] ,newleftturnvector[2]+fnhalflvector[2]}
            newrightturnvector = {newrightturnvector[1]+fnhalfrvector[1],newrightturnvector[2]+fnhalfrvector[2]}
        end
    end

    if direction == 0 then
        return {newleftturnvector[1],newleftturnvector[2]}, 360 - theta
    else
        return {newrightturnvector[1],newrightturnvector[2]}, theta
    end
end

function posbumps(guid, direction)
    --direction 0 = left 1 = right 2 = forward
    --direction of bump check
    local obj = getObjectFromGUID(guid)
    local pos = obj.getPosition()
    local rot = obj.getRotation()
    local rv,cv,lv,fv

    local scale = 0.734
    if isBigShip(guid) == true then
        scale = scale * 2
    end
    if direction == 1 then
        rv = {math.sin(math.rad(rot[2]+45))* -1, math.cos(math.rad(rot[2]+45)) * -1}
        cv = getNormal(rv[1],rv[2])
    elseif direction == 0 then
        lv = {math.sin(math.rad(rot[2]-45))* -1, math.cos(math.rad(rot[2]-45))* -1}
        cv = getNormal(lv[1],lv[2])
    elseif direction == 2 then
        fv = {math.sin(math.rad(rot[2]))* -1, math.cos(math.rad(rot[2]))* -1}
        cv = getNormal(fv[1],fv[2])
    end

    local Objects = {}
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' and ship.getGUID() ~= guid then
            local shippos = ship.getPosition()
            local shiprot = ship.getRotation()
            local sfv = {shippos[1]-pos[1],shippos[3]-pos[3]}
            local scv = getNormal(sfv[1],sfv[2])
            local dot = dot2d({cv[1],cv[2]},{scv[1],scv[2]})
            if dot > 0 then
                local circledist = distance(pos[1],pos[3],shippos[1],shippos[3])
                if circledist < 12 then
                    local perp = calcPerpendicular({pos[1],pos[3]},{cv[1]+pos[1],cv[2]+pos[3]},{shippos[1],shippos[3]})
                    if perp < 3.3 then
                        local BumpTable = {}
                        BumpTable["Position"] = ship.getPosition()
                        BumpTable["Rotation"] = ship.getRotation()
                        BumpTable["ShipGUID"] = ship.getGUID()
                        BumpTable["ShipName"] = ship.getName()
                        BumpTable.MaxDistance = circledist
                        Objects[#Objects +1] = BumpTable
                    end
                end
            end
        end
    end
    table.sort(Objects, function(a,b) return a.MaxDistance < b.MaxDistance end)
    return Objects
end

function calcPerpendicular(a, b, c)
    -- a b c vectors x,y
    -- a b are points on the line
    -- c is the point to find distance to
    local slope1 = (b[2]-a[2])/(b[1]-a[1])
    local yint1 = a[2]-slope1*a[1]
    local slope2 = -(b[1]-a[1])/(b[2]-a[2])
    local yint2 = c[2]-slope2*c[1]
    local x = (yint2-yint1)/(slope1-slope2)
    local y = slope2*x+yint2
    return distance(x,y,c[1],c[2])
end

function getCorners(f,g,rotation,guid)
    local corners = {}
    local scale = 0.734
    if isBigShip(guid) == true then
        scale = scale * 2
    end
    local world_coords = {}
    world_coords[1] = {f - scale, g + scale}
    world_coords[2] = {f + scale, g + scale}
    world_coords[3] = {f + scale, g - scale}
    world_coords[4] = {f - scale, g - scale}
    for r, corr in ipairs(world_coords) do
        local xcoord = f + ((corr[1] - f) * math.sin(math.rad(rotation))) - ((corr[2] - g) * math.cos(math.rad(rotation)))
        local ycoord = g + ((corr[1] - f) * math.cos(math.rad(rotation))) + ((corr[2] - g) * math.sin(math.rad(rotation)))
        corners[r] = {xcoord,ycoord}
    end
    return corners
end

function getNormal(x,y)
    local len = math.sqrt((x*x)+(y*y))
    return {x/len,y/len}
end

function getAxis(c1,c2)
    local axis = {}
    axis[1] = {c1[2][1]-c1[1][1],c1[2][2]-c1[1][2]}
    axis[2] = {c1[4][1]-c1[1][1],c1[4][2]-c1[1][2]}
    axis[3] = {c2[2][1]-c2[1][1],c2[2][2]-c2[1][2]}
    axis[4] = {c2[4][1]-c2[1][1],c2[4][2]-c2[1][2]}
    return axis
end

function dot2d(p,o)
    return p[1] * o[1] + p[2] * o[2]
end

function collide(x1, y1, r1, guid1, x2, y2, r2, guid2)
    local c2 = getCorners(x2, y2, r2, guid2)
    local c1 = getCorners(x1, y1, r1, guid1)
    local axis = getAxis(c1,c2)
    local scalars = {}
    for i1 = 1, #axis do
        for i2, set in pairs({c1,c2}) do
            scalars[i2] = {}
            for i3, point in pairs(set) do
                table.insert(scalars[i2],dot2d(point,axis[i1]))
            end
        end
        local s1max = math.max(unpack(scalars[1]))
        local s1min = math.min(unpack(scalars[1]))
        local s2max = math.max(unpack(scalars[2]))
        local s2min = math.min(unpack(scalars[2]))
        if s2min > s1max or s2max < s1min then
            return false
        end
    end
    return true
end
