# Make SciTE Collection

A summary of the scripts, processing and the benefits.

The Python scripts require version 3. I try to avoid later syntax for compatibility so the current version 3.8.2 x64 I use is OK. Older Python versions may work fine.

Many of the scripts depend on *lexilla*, *scintilla* and *scite* source folders to exist in the same directory. The shared module is *common.py* which some of the scripts import.

The scripts may offer to download [AutoIt3]'s *Aut2Exe.exe*, [Resource Hacker]'s *ResourceHacker.exe*,... though [Html Help Workshop] and [WinMerge] need to be in an accessible defined location, like installed into the Program Files directory. See *Final Notes* at the end of the readme for direct links to [Html Help Workshop] executables and paths searched.

Some scripts may work on UNIX platforms, though due to 3rd party programs used, Windows is the only fully supported platform at the moment.

Any source created by this project is licensed as [GPLv3].

[Preview] how a customized SciTE looks.


## Menu

The script *menu.py* is an optional concept to run the scripts. The user can select from a menu instead of typing multiple filenames at a prompt. The menu will loop until nothing or `0` is entered as a value. It shows an entered value log with each loop so knowing what has been done so far is known.

The menu prompts for numbers (plural), so you can enter for example `1 5 6` which would download SciTE, edit properties and compare properties in that order. To save typing, it is allowed to use a range of *number dash number*. Example, `1 3-10` will be expanded to `1 3 4 5 6 7 8 9 10`. `10-3` would be ignored as the number after the dash should be larger. `3-3` would just be `3`.


## Download SciTE

If you do not already have the binaries and source files, then the script *download_scite.py* can download them for you. It can also extract the source files into the current directory for further processing by the other scripts. Optional extraction should create the folders *lexilla*, *scintilla* and *scite* with all the sources files within those folders. Other scripts may access the source files in these source folders.


## Download base tools

Download [Eskil], [Frhed], [Luacheck] and [SQLite] to the base directory used by *make_scite_setup.py*. Frhed is x86 (32 bit) and x64 (64 bit).  Luacheck is x86 (32 bit) and x64 (64 bit) and is a defined tool in the lua.properties override file. Select the bitness to suit the target OS. These tools are optional.

Important reminder, SciTE 64 bit setup uses Frhed in *SciTEStartup.lua*, SciTE 32 bit does not use Eskil and Frhed in *SciTEStartup.lua* as the Lua code is minimal in the latter, due to *rluawfx.dll* being 64 bit.

Eskil is [GPLv2] license. Frhed is [GPLv2] license. Luacheck is [MIT] license. SQLite is [Public domain].


## Download rluawfx.dll

 * *luawfx.cpp*
 * *rluawfx-en.dll*
 * *rluawfx_functions.hta*

This DLL is from [RSciTE] and is useful for the ListBox and several other functions. It is 64 bit only so cannot be used with a 32 bit SciTE executable. This script will also download *luawfx.cpp* so that it can get the function signatures, can build lua code lines for use and will make a file named *rluawfx_functions.hta*.

The *rluawfx.dll* is licensed as LGPL v2.1 or later as the notice in *luawfx.cpp* specifies.

Actual filename of *rluawfx.dll* downloaded is *rluawfx-en.dll*.


## Make SciTE

This is optional to do as the pre-made binaries may be suitable. If you do make SciTE then GCC will be needed. The script *make_scite.py* will make *SciTE.exe*, *Sc1.exe* and the Dynamic Link Libraries (DLLs).

Another item in the menu is Make TestLexers. A compiled TestLexers.exe can run test files to detect if an issue exists in the lexers.

Based on use of *mingw32-make* command of the [nuwen] compiler.


## Edit Properties

Main purpose is to replace fixed style settings to instead use the variable names that are assigned in the properties files. Many properties files were created with example style `fore:#7F007F` instead of `$(colour.string)`. When variable names are used as much as possible, then setting colours for multiple languages is improved.

The script *edit_properties.py* will replace several hundred of these style entries so that setting for example `colour.string` to another value may affect styles where that variable name is specified. Some other style changes and fixes are done to help make the styles work hopefully better in the dictionary named `update`.

Non-standard colours added to include some styles missed in the web 16 colour range. Upstream development seems to work with global variable values in this range and used `7F` instead of `80` as it is probably easier to recognize a `7F` with `00` sequence from a `80` with `00` sequence.

The script can also patch some settings like autocompletion so your changes can be integrated into the existing properties. Personal user changes may be applied in another properties file like *SciTEUser.properties*, as they can change based on needs without requiring these scripts to be run again, just to change a integrated property setting. The file named *patch.md* has these patches. This file can be tricky to create as embedded properties has comments stripped, while the external properties files have comments. So, the patches need to work in between the comment lines so that the same patches can work for both embedded and external properties files.

The script will prompt for processing of embedded and external properties.


## Compare Properties

Checking the changes to the properties files can be difficult to do manually so the script *compare_properties.py* can help to make it a little easier. It uses [WinMerge] to difference the files to see if everything is good.


## Insert Embedded

This only applies to *Sc1.exe* with the embedded properties file as the external properties remain external.

[Resource Hacker] is used to insert *Embedded.properties* in the executable file. This could be done manually with *Resource Hacker*, though the script *insert_embedded.py* does it without needing knowledge of how to do it correct... everytime.

If ResourceHacker.exe is not found, the script may offer to download *resource_hacker.zip* and extract *ResourceHacker.exe* into the bin folder.

**Note**: *Sc1.exe* binary download less than version `4.0` , will be compressed with [UPX]. Decompression will be needed manually before the insertion of the modified embedded properties.


## Make Iface files

 * *iface.api*
 * *iface.hta*
 * *iface.json*

*iface.json* is a temporary file, though if useful, keep it. The *iface.api* is extensive and many functions may not work with lua if added to it's api property setting (see *scitepane.api* for better lua supported functions taken from *PaneAPI.html*). *iface.hta* is useful for names, parameters and descriptions for the iface functions.


## Make Lua Chm File

 * *lua.chm*

Html files such as *manual.html* will be downloaded. Images, css files,... may also be downloaded. The html files will be read and hhc, hhk and hhp files will be created so that [Html Help Workshop] can compile them all into a chm file. *lua.chm* will have an index, so it should work well launched from SciTE, for getting help from a selection or current word that exists in the index.

The script should get the Lua version from *scite\lua\src\lua.h* to be compatible with the embedded Lua system in SciTE.


## Make Lua Api File

 * *lua.api*
 * *lua.json*

*lua.json* may have some use, though *lua.chm* may make it obsolete. *lua.api* is useful for the lua api property setting. This will give the autocomplete and calltips for Lua in general. Best to run *Make Lua Chm File* before this one, so it can use it's downloaded *manual.html* file. If not possible in that order, it will download the html from the manual.


## Make Modules Json

 * *modules.json*

Can be useful for *sc1.exe* as it does not have the external properties files to browse. So some code to read *modules.json*, create a hta file and display it for viewing to help quite a lot with customizing property settings.


## Make SciTE Api Files

 * *sciteconstants.api*
 * *scitemenucommands.api*
 * *scitepane.api*
 * *sciteproperties.api*
 * *scitestyles.api*
 * *scitestyler.api*
 * *scitevariables.api*

Can be several scripts that *menu.py* can glob and run in sequence. Can be useful for the api property settings for Lua and Properties.


## Make SciTE Chm Files

 * *lexilla.chm*
 * *scintilla.chm*
 * *scite.chm*

The script *make_scite_chm_files.py* creates the hhc, hhk and hhp files which can be compiled by [Html Help Workshop]. The chm files created will be *lexilla.chm*, *scintilla.chm* and *scite.chm*. *scite.chm* will have an index of property names and variable names, so it can be useful to use with SciTE with a current word.

The compiler may print some warnings, though the chm file may compile OK. I have silenced the stdout from *Html Help Workshop* to avoid the excessive output. The setting *stdout* in *common.py* can change whether to silence the stdout or not.


## Make SciTE Setup

Created as a basic setup for new users to start with, or to quickly setup for some portable setup of SciTE. Once the setup is done, then the files can be copied to a more permanent location to be customized more and to be put to use. As been mentioned, 32 bit SciTE does not work with *rluawfx.dll*, so it's features will not be available. If using SciTE 32 bit, *SciTEStartup.lua* created may be much smaller.

If [json.lua] is supplied, it's license is [MIT]. *json.lua* can be quite useful for getting data from the json files created by these scripts.

If *SciTELauncher.au3* is supplied, compile with latest [AutoIt3] *Aut2Exe.exe* compiler. The setup script may prompt to download *Aut2Exe.exe* and will do the compile automatically. If you accept to download *Aut2Exe.exe*, you accept the [AutoIt3 License]. The launcher executable can be passed a *-register* argument to open a Gui to register or unregister some registry entries in `HKCU\Software\Classes` or the option of `HKLM\Software\Classes`. Ensure the launcher is in it's correct location before registering. Once registered, look for the item named SciTE in the context menu. The context menu entry will display for any file or directory background.

The default setup may not suit everyones interest, like wanting other languages imported, though it does show how the files created, downloaded or supplied can be combined into a customized SciTE setup.


## Remove Temporary Files

Prompts for removal of files regarded as temporary. The scripts used to do the clean up, though if these files are needed by other scripts, then a separate script to finalize clean up can be useful. This script can be modified by the user, if other files are not needed or if some files are needed.


## Final Notes

Download links for [Html Help Workshop] at Microsoft may not work, so the WayBack Machine has these direct download links which might be useful:

 * [htmlhelp.exe]
 * [helpdocs.zip]

and an another direct download link option:

 * [htmlhelp.exe alt 1]

Another alternative is *chmcmd.exe* in [Free Pascal]. It has been tested with good results. It is a portable executable, though it is within the installer. If to be used, set the compiler path in *common.py*.

Paths searched for programs:

 * AutoIt3 compiler
   * `%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe.exe`
   * `%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe.exe`
   * `%cd%\bin\Aut2exe.exe`
 * Html Help Workshop compiler
   * `%ProgramFiles%\HTML Help Workshop\hhc.exe`
 * Resource Hacker
   * `%ProgramFiles%\Resource Hacker\ResourceHacker.exe`
   * `%ProgramFiles(x86)%\Resource Hacker\ResourceHacker.exe`
   * `%cd%\bin\ResourceHacker.exe`
 * WinMerge
   * `%ProgramFiles%\WinMerge\WinMergeU.exe`


<!-- pages -->
 [Preview]: examples/readme.md

<!-- links -->
 [AutoIt3]: http://www.autoitscript.com/site/autoit/downloads/
 [AutoIt3 License]: https://www.autoitscript.com/autoit3/docs/license.htm
 [Eskil]: http://eskil.tcl-lang.org/index.html/doc/trunk/htdocs/download.html
 [Free Pascal]: https://www.freepascal.org/
 [Frhed]: https://github.com/WinMerge/frhed/releases
 [GPLv2]: https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
 [GPLv3]: https://www.gnu.org/licenses/gpl-3.0.en.html
 [Html Help Workshop]: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/microsoft-html-help-downloads
 [json.lua]: https://github.com/rxi/json.lua
 [Luacheck]: https://github.com/mpeterv/luacheck
 [MIT]: https://opensource.org/licenses/MIT
 [nuwen]: https://nuwen.net/mingw.html
 [Public domain]: http://en.wikipedia.org/wiki/Public_Domain
 [Resource Hacker]: http://www.angusj.com/resourcehacker/
 [RSciTE]: https://github.com/robertorossi73/rscite
 [SQLite]: https://www.sqlite.org/
 [WinMerge]: https://winmerge.org/
 [UPX]: https://upx.github.io/

<!-- direct download links -->
 [htmlhelp.exe]: http://web.archive.org/web/20160201063255/http://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe
 [helpdocs.zip]: http://web.archive.org/web/20160314043751/http://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/helpdocs.zip
 [htmlhelp.exe alt 1]: http://download.microsoft.com/download/OfficeXPProf/Install/4.71.1015.0/W98NT42KMe/EN-US/HTMLHELP.EXE
