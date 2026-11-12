--@ title: Character: a new gear set
--@ roots: PolestarModal
-- New set: the name field and the icon picker, the worn items' icons first.
PolestarUI.Show("character")
PolestarUI.CharacterEditSet(nil)
assert(PolestarModal:IsShown(), "no dialog")
