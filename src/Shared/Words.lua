local Dictionary = {}

-- US-5.1: Dynamic WordPacks added
local Packs = {
    Standard = {
        "AFRICA", "AGENT", "AIR", "ALIEN", "ALPS", "AMAZON", "AMBULANCE", "AMERICA",
        "ANGEL", "ANTARCTICA", "APPLE", "ARM", "ATLANTIS", "AUSTRALIA", "AZTEC",
        "BACK", "BALL", "BAND", "BANK", "BAR", "BARK", "BAT", "BATTERY", "BEACH",
        "BEAR", "BEAT", "BED", "BEIJING", "BELL", "BELT", "BERLIN", "BERMUDA",
        "BERRY", "BILL", "BLOCK", "BOARD", "BOLT", "BOMB", "BOND", "BOOM", "BOOT",
        "BOTTLE", "BOW", "BOX", "BRIDGE", "BRUSH", "BUCK", "BUFFALO", "BUG", "BUGLE"
    },
    Roblox = {
        "NOOB", "ROBUX", "AVATAR", "OBBY", "TYCOON", "GUEST", "BACON", "ADMIN",
        "BAN", "SERVER", "CHAT", "BLOXBURG", "JAILBREAK", "ADOPT", "TRADE",
        "SCAM", "GLITCH", "LAG", "PING", "UPDATE", "STUDIO", "SCRIPT", "PART",
        "SPAWN", "BASEPLATE", "VIP", "PREMIUM", "CATALOG", "ITEM", "LIMITED",
        "FACE", "GEAR", "HAT", "SHIRT", "PANTS", "GROUP", "CLAN", "GAME",
        "PLAY", "BUILD", "DESTROY", "CREATE", "EVENT", "BADGE", "TIX", "SWORD",
        "FORCEFIELD", "ROCKET", "TOOL", "BACKPACK"
    }
}

-- US-2.1 / US-2.2
-- US-5.1: Updated PackName
function Dictionary:Get_Random_Words(count, packName)
    local pack = Packs[packName] or Packs.Standard
    local shuffled = table.clone(pack)
    
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    local selectedWords = {}
    for i = 1, count do
        table.insert(selectedWords, shuffled[i])
    end
    return selectedWords
end

return Dictionary