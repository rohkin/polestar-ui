-- The client calls the Character window reads (tests/lua/wow_stub.lua has
-- UnitName only); the values are the preview's sample character.
function UnitLevel(unit) return 24 end
function UnitRace(unit) return "Human", "Human" end
function UnitClass(unit) return "Warrior", "WARRIOR", 1 end
function UnitPVPName(unit) return "Testchar" end
function ToggleCharacter(tab, onlyShow) end
