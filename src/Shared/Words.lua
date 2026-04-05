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
        
        Gaming = {
            "FORTNITE", "MINECRAFT", "DISCORD", "VALORANT", "ZELDA", "CHIEF", "VBUCKS", "TWITCH", 
            "STREAM", "CONTROLLER", "CONSOLE", "QUEST", "BOSS", "LEVEL", "SKIN", "EMOTE",
            "CLUTCH", "CAMPING", "LOOT", "GUILD", "LOBBY", "PICKAXE", "REVIVE", "ZONE", "LAG"
        },

        Food = {
            "SUSHI", "RAMEN", "BOBA", "MATCHA", "TACO", "BURGER", "PIZZA", "PASTA",
            "MOCHI", "CHIPS", "GUAC", "SPICY", "CAKE", "COOKIE", "COFFEE", "LATTE", 
            "BREAD", "FRY", "STEAK", "WINGS", "NUGGET", "SAUCE", "CHEF", "MENU", "BAKE"
        },

        Movies = {
            "MARVEL", "STARK", "SPIDER", "BATMAN", "JOKER", "POTTER", "WIZARD", "JEDI",
            "FORCE", "AVATAR", "TITANIC", "OSCAR", "SCENE", "ACTOR", "DIRECTOR", "SCRIPT",
            "HORROR", "ACTION", "COMEDY", "GRIFFIN", "SIMPSON", "DISNEY", "PIXAR", "STUNT", "FAME"
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