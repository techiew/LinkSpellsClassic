## LinkSpellsClassic
This World of Warcraft addon lets you link your spells and talents in chat to other players just like you would in retail. For more info click on the CurseForge or WoWInterface links below.

![Chat link preview](https://github.com/techiew/LinkSpellsClassic/blob/master/chat%20link%20preview.png)

![Tooltip preview](https://github.com/techiew/LinkSpellsClassic/blob/master/tooltip%20preview.png)

## Download
[https://www.curseforge.com/wow/addons/linkspellsclassic](CurseForge.com)
[https://www.wowinterface.com/downloads/info25557-LinkSpellsClassic.html](WoWInterface.com)

## Quick code summary

**1. The Tooltips**

The code starts by looking for spellbook and talent tree click events. When a button in either one of these is clicked, information from the tooltip that is displayed at the time of the click is read and saved in the spell cache.

**2. The Spell Cache**

The spell cache stores all information about a spell that was retrieved from the spell tooltip, the spell cache is a lua table where each top level entry is also a table with a name like this: "spell name + rank + clone number". In each child table within the spell cache, the data for that specific spell can be found, such as mana cost, cast time, range, etc. "Clone numbers" are used for when a spell with the same rank and name have been shared by different players, in order to uniquely identify them. That's because there are many factors that can change the stats or description of a spell, even if it is the same spell with the same rank.

**3. Grabbing Spell Data**

When the player shift-clicks on a spell or talent, the spell name or talent name will be pasted into the chat box as a message, but only if the chat box is already open. The pasted message will be formatted like this: !Link\[spell name\]. When the user sends the message with this text in it, the installed addon for every user in the chat channel will automatically filter and edit that part of the text in such a way that it becomes a clickable link. It works like this because you cannot directly send custom clickable links over chat to other players, so the process of changing it to a link needs to happen clientside for each client.

**4. Sharing Spell Data**

At the same time that the user sends the link message in chat, the addon will automatically communicate with other clients with the addon installed in order to give them the spell data required to show the tooltip when clicking the link. The data is stored in each client's spell cache. You can read more about chat links and their formatting here: https://wowwiki.fandom.com/wiki/UI_escape_sequences

## Contributions
Feel free to provide suggestions, code or pull requests.

## More addons
You can find more of my addons in this repo: https://github.com/techiew/WoW-Addons
