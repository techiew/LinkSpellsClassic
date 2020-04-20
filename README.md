## LinkSpellsClassic
This World of Warcraft addon lets you link your spells and talents in chat to other players just like you would in retail. For more info click on the CurseForge or WoWInterface links below.

![Chat link preview](https://github.com/techiew/LinkSpellsClassic/blob/master/chat%20link%20preview.png)

![Tooltip preview](https://github.com/techiew/LinkSpellsClassic/blob/master/tooltip%20preview.png)

## Quick code summary

**1. The Tooltips**
The code starts by first looking for spellbook and talent tree click events, when a button in either one of these is clicked, the tooltip that is displayed at the time of the click is read and saved in the spell cache.

**2. The Spell Cache**
The spell cache stores all information about a spell that was retrieved from the spell tooltip, the spell cache is a lua table where each top level entry is also a table with a name like this: "spell name + rank + clone number". In each child table within the parent table, the data for that specific spell can be found, such as name, rank, mana cost, cast time, range, etc. Those are simply values within the child table. "Clone numbers" are used for when a spell with the same rank and name have been shared by players, in order to uniquely identify them.

**3. Sharing Spell Data**


## Download
[https://www.curseforge.com/wow/addons/linkspellsclassic](CurseForge.com)
[https://www.wowinterface.com/downloads/info25557-LinkSpellsClassic.html](WoWInterface.com)

## Contributions
Feel free to provide suggestions, code or pull requests.

## More addons
You can find more of my addons in this repo: https://github.com/techiew/WoW-Addons
