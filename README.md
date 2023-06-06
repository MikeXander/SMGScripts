# SMGScripts
A collection of scripts meant to give you quick access to all the info you need while TASing Super Mario Galaxy!

![Sample Image](https://cdn.discordapp.com/attachments/302602573586890754/763243595779014656/Screenshot_2020-10-06_23.37.18.png)


### Running the Scripts
Download [Dolphin 5.0 - Lua Core](https://github.com/SwareJonge/Dolphin-Lua-Core/releases), place the `Lua` folder in the same directory as `Dolphin.exe`, and copy the files in `Scripts` into the `Sys/Scripts/` folder. The emulator file structure should look something like this:
```
Dolphin/
├── Sys/
│   └── Scripts/
│       └── SMG.lua
├── Lua/
│   └── SMG_Core.lua
└── Dolphin.exe
```
Then in Dolphin, open the game, select Tools, then Execute Script, and choose the script you want to run.


### How Do I Hide Info?
If there is too much text on your screen, you don't need to know how to program to fix it:
1. Open the script you want to change in a text editor
2. Look for the line that says `function onScriptUpdate()`
3. Underneath it you will find lines that say `text = text ...`. If you add `--` so that it becomes `--text = text ...` it will no longer display that line of text


### To Do:
- Upgrade `SMG2.lua` to have as much detail as `SMG.lua`
- Make format consistent


### See Also:
- My [Wiimote Input Visualizer](https://github.com/MikeXander/WiimoteInputVisualizer)
- Joselle's [Cheat Engine RAM Watch](https://github.com/JoselleAstrid/ram-watch-cheat-engine)
- SMG TASing [Discord Server](https://discord.gg/h2YSCZm)