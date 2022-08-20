--- Copyright 2022 Konijima, Klean
--- 
--- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
--- to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
--- and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
--- 
--- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--- 
--- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
--- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
--- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local ISReadABook_checkMultiplier = ISReadABook.checkMultiplier
function ISReadABook:checkMultiplier(...)
    if not SandboxVars.BookConsumer.disabled and SandboxVars.BookConsumer.skillBookXp then
        local trainedStuff = SkillBook[self.item:getSkillTrained()];
        if trainedStuff then
            local readPercent = (self.item:getAlreadyReadPages() / self.item:getNumberOfPages()) * 100;
            if readPercent > 100 then readPercent = 100; end

            local itemFullType = self.item:getFullType();
            self.characterModData.BookConsumer = self.characterModData.BookConsumer or {};
            self.characterModData.BookConsumer[itemFullType] = self.characterModData.BookConsumer[itemFullType] or 0;

            local previousPercent = self.characterModData.BookConsumer[itemFullType]; -- get previous read percent
            self.characterModData.BookConsumer[itemFullType] = readPercent; -- update current read percent

            local diffPercent = readPercent - previousPercent;
            self.character:getXp():AddXP(trainedStuff.perk, self.item:getLvlSkillTrained() * SandboxVars.BookConsumer.skillBookXpMultiplier * diffPercent);
        end
    else
        return ISReadABook_checkMultiplier(self, ...);
    end
end

local ISReadABook_start = ISReadABook.start
function ISReadABook:start()
    ISReadABook_start(self);

    if not SandboxVars.BookConsumer.disabled then
        if self.character:getAlreadyReadBook():contains(self.item:getFullType()) then
            self.character:Say(getText("IGUI_PlayerText_KnowSkill"));
            self:stop();
            self:forceStop()
            return;
        end

        if SkillBook[self.item:getSkillTrained()] and self.preCompleted then
            self.character:Say(getText("IGUI_PlayerText_BookObsolete"));
            self:stop();
            self:forceStop()
            return;
        end
    end
end

local ISReadABook_perform = ISReadABook.perform;
function ISReadABook:perform()
    ISReadABook_perform(self);

    -- Remove any literature if completed
    if not SandboxVars.BookConsumer.disabled and SandboxVars.BookConsumer.consumeLiterature then
        if self.item:getReplaceOnUse() then
            self.item = self.character:getInventory():getItemFromType(self.item:getReplaceOnUse());
        end
        if not SkillBook[self.item:getSkillTrained()] or SkillBook[self.item:getSkillTrained()] and not self.preCompleted then
            self.character:removeFromHands(self.item);
            if self.item:getContainer() then
                self.item:getContainer():Remove(self.item);
            else
                self.character:getInventory():Remove(self.item);
            end
        end
    end
end

local ISReadABook_new = ISReadABook.new;
function ISReadABook:new(character, item, ...)
    local o = ISReadABook_new(self, character, item, ...);
    o.stopOnWalk = not SandboxVars.BookConsumer.allowReadWalking; -- allow read and walk
    if SandboxVars.BookConsumer.disabled then o.stopOnWalk = true; end -- disable read and walk if mod is disabled
    o.characterModData = character:getModData(); -- grab the character modData
    o.preCompleted = item:getAlreadyReadPages() >= item:getNumberOfPages(); -- get if the book is already readed
    return o;
end
