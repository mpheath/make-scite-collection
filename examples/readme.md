# Preview With Examples

Some example scripts have been supplied to test the new customized SciTE setup.

A preview of SciTE displaying some of the example scripts with different languages based on filetypes of *.au3*, *.cmd*, *.lua*, *.py* and *.properties*.

![editor]

This is Sc1 x64 5.1.0. Most of the Make SciTE Collection scripts were run and *make_scite_setup.py* made the final setup. No other customization has been done. So, this is what you end up with. Both customized Sc1 and SciTE should reasonably be the same to view and operate.

The dark theme is current default and the light theme can be set by opening *~themes.properties* from the Options menu and changing `theme.dark=1` to `theme.dark=0` at the top of the file. The theme change will be immediate once *~themes.properties* has been saved. The light theme is mostly the original SciTE theme with modest changes to be compatible with the dark theme adjustments... as the dark theme tries to be similar in colors and styles. Keywords in code are still blue, comments about code are still green,... so basic recognition should still be good.

If *Tools -> GlobalTools* is available, try *ToggleDimComments* and view all of the examples. All of the comments should be dimmed in all compatible styled files. Now select *ToggleDimComments* again to revert the behavior.

Many tools exist in GlobalTools, try *OpenHtaFile* and select `lua\about_global_tools.hta` to get a short description about each tool.

SciTELauncher can help with launching SciTE with some features. The launcher can be registered to show in the context menu. Use the command:

```
SciTELauncher -register
```

which shows the window:

![register]

The user can run the command as administrator to enable Local Machine registration. Most users will probably be happy with just Current User registration. Click *Register* to do the registration.

The registration uses branching menus so may need Windows 7 or later. The user could modify *SciTELauncher.au3* if Windows XP or earlier type of registration is possible.

If you open the contextmenu on a background, you may see:

![contextmenu]

 * **Basic** is open SciTE with a blank pane.
 * **Extended** is search for *SciTE.session* in current directory and open the session else open a blank pane.
 * **Readme** is open *readme.txt* or *readme.md* or open both as blank panes.
 * **Run as administrator** exists if *Add Run as administrator* checkbox was checked. This item runs SciTE as administrator with a blank pane. If contextmenu launched from a file, opens the file in SciTE as administrator.
 * **Sources** is open a window to choose sources, session and then open the session in SciTE.

This is the sources window:

![sources]

Several sources are available and can be a temporary session or create a more permanent SciTE.session file in the current directory. A source can also be a fossil or git repository in the current directory and will get the checked-in files for the session. Avoid use on a repository with binaries as some binary types like *.exe* and *.dll* are skipped but not all types, as large binaries may not be good to open in SciTE.

A source can be specified in the edit control. Be careful with the file patterns as it is passed to the Dir command in CMD.

Good luck with making a customized SciTE setup.


<!-- links -->
 [contextmenu]: img/contextmenu.jpg
 [editor]: img/editor.gif
 [register]: img/register.jpg
 [sources]: img/sources.jpg
