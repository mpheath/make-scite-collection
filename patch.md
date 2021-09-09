# Patch file for SciTE Sc1

**This file is read by a script. Read the following information before editing.**

Follows the format of fenced blocks of 3 backticks. 1st fenced block is
the text to find. 2nd fenced block is the replacement. The find and replace
is literal, not regular expression. Limited to 1 replace per pattern.

Processing matches a `module_name: comment` header starting with `####` and then
fenced blocks in pairs so anything before or after the pattern is ignored,
so any other markdown text is allowed outside the pattern.
This makes the patch text easy to read and flexiable.

The initial module name is SciTEGlobal. Use correct case for the module names
as can be used as dictionary keys.

Newlines between the fences are used for text to find.
Newlines at fence lines are not used for text to find.

Pattern searched is like:

> #### module_name: comment
>
> ```
> text to find 
> ```
>
> ```
> replacement text 
> ```

An empty line between comment headers and fenced blocks is strongly recommended.

To disable any patch, start the header text with a minus `-` or tilde `~`.
Example: `#### -module_name: comment` will disable that patch from
being processed.

The colon separates the module name from the comment in the header,
so it is required.

Keep comment headers short and concise. They can be printed to the console
when processed.

Patches should not contain property comments as the embedded properties
of Sc1.exe has no property comments.

Everything from the 1st line header to the dashed horizontal line is
ignored by the processing script.

---

#### SciTEGlobal: Window sizes and visibility

```

tabbar.visible=1
```

```

statusbar.visible=1
tabbar.visible=1
```

#### SciTEGlobal: Enable edge mode

```
edge.column=200
edge.mode=0
edge.colour=#C0DCC0
```

```
edge.column=80
edge.mode=1
edge.colour=#C0DCC0
```

#### SciTEGlobal: Replace bookmark.fore with bookmark.back

@Element styles
Old setting makes the marked line a dark red background if the margin is hidden.
Light blue #F0F5FF is not bright though matches the blue orb.
Light yellow #FFFFCC does stand out.

```

bookmark.fore=#BE0000
```

```

bookmark.back=#FFFFCC
```

#### SciTEGlobal: Change indent size and type

@Indentation

```
tabsize=8
indent.size=8
use.tabs=1
```

```
tabsize=4
indent.size=4
use.tabs=0
```

#### SciTEGlobal: Add calltip.*.use.escapes

@Behaviour

```
eol.auto=1
clear.before.execute=0
```

```
eol.auto=1
calltip.*.use.escapes=1
clear.before.execute=0
```

#### SciTEGlobal: Change statusbar

```
statusbar.number=4
statusbar.text.1=\
li=$(LineNumber) co=$(ColumnNumber) $(OverType) ($(EOLMode)) $(FileAttr)
statusbar.text.2=\
$(BufferLength) chars in $(NbOfLines) lines. Sel: $(SelLength) chars.
statusbar.text.3=\
Now is: Date=$(CurrentDate) Time=$(CurrentTime)
statusbar.text.4=\
$(FileNameExt) : $(FileDate) - $(FileTime) | $(FileAttr)
```

```
statusbar.number=4
statusbar.text.1=\
 1  Line: "$(LineNumber)"   Column: "$(ColumnNumber)"   SelectChars: "$(SelLength)"   SelectLines: "$(SelHeight)"   CodePage: "$(code.page)"   Highlight: "$(highlight.current.word)"   EOL: "$(EOLMode)"
statusbar.text.2=\
 2  "$(BufferLength)" chars in "$(NbOfLines)" lines.   Selected "$(SelLength)" chars.   Insert: "$(OverType)"
statusbar.text.3=\
 3  Date: "$(CurrentDate)"   Time: "$(CurrentTime)"   Session: "$(SessionPath)"
statusbar.text.4=\
 4  FileName: "$(FileNameExt)"   FileDate: "$(FileDate)"   FileTime: "$(FileTime)"   FileAttribute: "$(FileAttr)"   Language: "$(Language)"
```

#### SciTEGlobal: Change SciTEDoc.html to scite.chm if PLAT_WIN

```
if PLAT_WIN
	command.scite.help="file://$(SciteDefaultHome)\SciTEDoc.html"
```

```
if PLAT_WIN
	command.scite.help="file://$(SciteDefaultHome)\scite.chm"
```

#### SciTEGlobal: Change code page to utf8

```

code.page=0
```

```

code.page=65001
```

#### SciTEGlobal: Change imports.exclude

```
imports.exclude=abaqus asl asn1 au3 ave avs baan blitzbasic bullant \
cil cmake cobol coffeescript csound dataflex ecl eiffel erlang escript \
flagship forth freebasic fsharp \
gap haskell hex inno kix latex lot lout \
markdown maxima metapost mmixal modula3 nim nimrod nncrontab nsis \
opal oscript pov powerpro powershell ps purebasic r raku rebol rust \
sas scriptol smalltalk sorcins spice specman \
tacl tal txt2tags verilog vhdl visualprolog
```

```
imports.exclude=abaqus ada asl asm asn1 ave avs baan blitzbasic bullant \
cil cmake cobol coffeescript csound d dataflex ecl eiffel erlang escript \
flagship forth fortran freebasic fsharp \
gap haskell hex kix latex lisp lot lout \
matlab maxima metapost mmixal modula3 nim nimrod nncrontab nsis \
opal oscript pov powerpro ps purebasic r raku rebol ruby rust \
sas scriptol smalltalk sorcins spice specman \
tacl tal tcl tex txt2tags verilog vhdl visualprolog
```

#### cpp: Add javascript api, autocomplete and calltips

```
block.start.$(file.patterns.c.like)=10 {
block.end.$(file.patterns.c.like)=10 }
```

```
block.start.$(file.patterns.c.like)=10 {
block.end.$(file.patterns.c.like)=10 }

api.$(file.patterns.js)=$(SciteDefaultHome)\api\javascript.api
autocomplete.cpp.ignorecase=1
autocomplete.cpp.start.characters=$(chars.alpha)$(chars.numeric)$_@#
calltip.cpp.end.definition=)
calltip.cpp.word.characters=$(chars.alpha)$(chars.numeric)_.
```

#### css: Remove indent settings

Allows the redefined global settings of 4 spaces.
An empty line as replacement as something needs to be specified.

```
indent.size.*.css=4
tab.size.*.css=4
use.tabs.*.css=1
```

```

```

#### css: Add api, autocomplete and calltips

```
block.start.*.css=5 {
block.end.*.css=5 }
```

```
file.patterns.css=*.css
api.$(file.patterns.css)=$(SciteDefaultHome)\api\css.api
autocomplete.css.ignorecase=1
autocomplete.css.start.characters=$(chars.alpha)$(chars.numeric)$_@#
calltip.css.ignorecase=1
calltip.css.parameters.start=:
calltip.css.parameters.separators= 
calltip.css.word.characters=$(chars.alpha)$(chars.numeric)-


block.start.*.css=5 {
block.end.*.css=5 }
```

#### html: Add auto.close.tags, api, autocomplete and calltips

```

fold.html=1
```

```

fold.html=1
xml.auto.close.tags=1

api.*.hta;*.html=$(SciteDefaultHome)\api\html.api
autocomplete.hypertext.ignorecase=1
autocomplete.hypertext.start.characters=$(chars.alpha)$(chars.numeric)<!
calltip.hypertext.end.definition=)
calltip.hypertext.ignorecase=1
calltip.hypertext.word.characters=$(chars.alpha)$(chars.numeric)<!
```

#### lua: Add indenting, api, autocomplete and calltips

```

indent.maintain.$(file.patterns.lua)=1
```

```

api.$(file.patterns.lua)=$(SciteDefaultHome)\api\lua.api
autocomplete.lua.start.characters=$(chars.alpha)$(chars.numeric)$(chars.accented)_%
calltip.lua.end.definition=)
calltip.lua.word.characters=$(chars.alpha)$(chars.numeric)_.%:
block.start.$(file.patterns.lua)=5 do else function repeat then
block.end.$(file.patterns.lua)=5 else elseif end until
```

#### others: Add batch indenting, api, autocomplete and calltips

Add autocomplete, calltips and indenting for compound statement.

```

keywords.$(file.patterns.batch)=$(keywordclass.batch)
```

```

keywords.$(file.patterns.batch)=$(keywordclass.batch)

api.$(file.patterns.batch)=$(SciteDefaultHome)\api\batch.api
autocomplete.batch.start.characters=$(chars.alpha)_
block.start.$(file.patterns.batch)=0 (
block.end.$(file.patterns.batch)=0 )

```

#### others: Add properties api, autocomplete, calltips and use.tabs

```

colour.other.operator=fore:#B06000
```

```
api.*.properties=$(SciteDefaultHome)\api\properties.api
autocomplete.props.start.characters=$(chars.alpha)$(chars.numeric).*
calltip.props.end.definition=)
calltip.props.word.characters=$(chars.alpha)$(chars.numeric).*

use.tabs.*.properties=1

colour.other.operator=fore:#B06000
```

#### powershell: Add api, autocomplete and calltips

```
comment.block.powershell=#~
comment.block.at.line.start.powershell=1
```

```
comment.block.powershell=#~
comment.block.at.line.start.powershell=1

api.$(file.patterns.powershell)=$(SciteDefaultHome)\api\powershell.api
autocomplete.powershell.ignorecase=1
autocomplete.powershell.start.characters=$(chars.alpha)
calltip.powershell.parameters.start= \

calltip.powershell.word.characters=$(chars.alpha)$(chars.numeric)_-@
```

#### python: Add api, autocomplete and calltips

```
statement.indent.$(file.patterns.py)=5 class def elif else except finally \
for if try while with

statement.lookback.$(file.patterns.py)=0
block.start.$(file.patterns.py)=
block.end.$(file.patterns.py)=
```

```
statement.indent.$(file.patterns.py)=5 class def elif else except finally \
for if try while with

statement.lookback.$(file.patterns.py)=0
block.start.$(file.patterns.py)=
block.end.$(file.patterns.py)=

api.$(file.patterns.py)=$(SciteDefaultHome)\api\python3.api
autocomplete.python.fillups=(
autocomplete.python.start.characters=$(chars.alpha)$(chars.numeric)._@
calltip.python.end.definition=)
calltip.python.word.characters=$(chars.alpha)$(chars.numeric)._@
```

#### python: Update keywords

Generated from Python 3.9.5 final win32.

```
keywordclass.python3=False None True and as assert break class continue \
def del elif else except finally for from global if import in is lambda \
nonlocal not or pass raise return try while with yield

keywordclass.python=$(keywordclass.python2)
```

```
keywordclass.python3=\
False None True __peg_parser__ and as assert async \
await break class continue def del elif else except \
finally for from global if import in is lambda nonlocal \
not or pass raise return try while with yield

keywordclass.python=$(keywordclass.python3) $(keywordclass1.python3)
```

#### python: Update builtins and modules

Generated from Python 3.9.5 final win32.

```
substylewords.11.1.$(file.patterns.py)=\
__main__ _dummy_thread _thread abc aifc argparse \
array ast asynchat asyncio asyncore atexit audioop \
base64 bdb binascii binhex bisect builtins bz2 \
calendar cgi cgitb chunk cmath cmd code codecs \
codeop collections colorsys compileall concurrent \
configparser contextlib copy copyreg crypt csv \
ctypes curses datetime dbm decimal difflib dis \
distutils dummy_threading email ensurepip enum \
errno faulthandler fcntl filecmp fileinput fnmatch \
formatter fpectl fractions ftplib functools gc getopt \
getpass gettext glob grp gzip hashlib heapq hmac \
html http http imaplib imghdr importlib inspect io \
ipaddress itertools json keyword linecache locale \
logging lzma macpath mailbox mailcap marshal math \
mimetypes mmap modulefinder msilib msvcrt \
multiprocessing netrc nis nntplib numbers operator \
os os ossaudiodev parser pathlib pdb pickle \
pickletools pipes pkgutil platform plistlib poplib posix \
pprint pty pwd py_compile pyclbr queue quopri \
random re readline reprlib resource rlcompleter runpy \
sched select selectors shelve shlex shutil signal site \
smtpd smtplib sndhdr socket socketserver spwd \
sqlite3 ssl stat statistics string stringprep struct \
subprocess sunau symbol symtable sys sysconfig \
syslog tabnanny tarfile telnetlib tempfile termios \
textwrap threading time timeit tkinter token \
tokenize trace traceback tracemalloc tty turtle \
types unicodedata unittest urllib uu uuid venv warnings \
wave weakref webbrowser winreg winsound wsgiref \
xdrlib xml xmlrpc zipfile zipimport zlib
```

```
keywordclass1.python3=\
ArithmeticError AssertionError AttributeError BaseException \
BlockingIOError BrokenPipeError BufferError BytesWarning \
ChildProcessError ConnectionAbortedError ConnectionError \
ConnectionRefusedError ConnectionResetError DeprecationWarning \
EOFError Ellipsis EnvironmentError Exception FileExistsError \
FileNotFoundError FloatingPointError FutureWarning \
GeneratorExit IOError ImportError ImportWarning IndentationError \
IndexError InterruptedError IsADirectoryError KeyError \
KeyboardInterrupt LookupError MemoryError ModuleNotFoundError \
NameError NotADirectoryError NotImplemented NotImplementedError \
OSError OverflowError PendingDeprecationWarning PermissionError \
ProcessLookupError RecursionError ReferenceError ResourceWarning \
RuntimeError RuntimeWarning StopAsyncIteration StopIteration \
SyntaxError SyntaxWarning SystemError SystemExit TabError \
TimeoutError TypeError UnboundLocalError UnicodeDecodeError \
UnicodeEncodeError UnicodeError UnicodeTranslateError \
UnicodeWarning UserWarning ValueError Warning WindowsError \
ZeroDivisionError abs all any ascii bin bool breakpoint \
bytearray bytes callable chr classmethod compile complex \
copyright credits delattr dict dir divmod enumerate \
eval exec exit filter float format frozenset getattr \
globals hasattr hash help hex id input int isinstance \
issubclass iter len license list locals map max memoryview \
min next object oct open ord pow print property quit \
range repr reversed round set setattr slice sorted \
staticmethod str sum super tuple type vars zip

substylewords.11.1.$(file.patterns.py)=\
abc aifc argparse array ast asynchat asyncio asyncore \
atexit audioop base64 bdb binascii binhex bisect builtins \
bz2 cProfile calendar cgi cgitb chunk cmath cmd code \
codecs codeop collections colorsys compileall concurrent \
configparser contextlib contextvars copy copyreg csv \
ctypes dataclasses datetime dbm decimal difflib dis \
distutils doctest email encodings ensurepip enum errno \
faulthandler filecmp fileinput fnmatch formatter fractions \
ftplib functools gc genericpath getopt getpass gettext \
glob graphlib gzip hashlib heapq hmac html http idlelib \
imaplib imghdr imp importlib inspect io ipaddress itertools \
json keyword lib2to3 linecache locale logging lzma \
mailbox mailcap marshal math mimetypes mmap modulefinder \
msilib msvcrt multiprocessing netrc nntplib nt ntpath \
nturl2path numbers opcode operator optparse os parser \
pathlib pdb pickle pickletools pipes pkgutil platform \
plistlib poplib posixpath pprint profile pstats py_compile \
pyclbr pydoc pyexpat queue quopri random re reprlib \
rlcompleter runpy sched secrets select selectors shelve \
shlex shutil signal site smtpd smtplib sndhdr socket \
socketserver sqlite3 sre_compile sre_constants sre_parse \
ssl stat statistics string stringprep struct subprocess \
sunau symbol symtable sys sysconfig tabnanny tarfile \
telnetlib tempfile textwrap threading time timeit tkinter \
token tokenize trace traceback tracemalloc turtle turtledemo \
types typing unicodedata unittest urllib uu uuid venv \
warnings wave weakref webbrowser winreg winsound wsgiref \
xdrlib xml xmlrpc xxsubtype zipapp zipfile zipimport \
zlib zoneinfo

```

#### sql: Add indenting, api, autocomplete and calltips

```
comment.box.start.sql=/*
comment.box.middle.sql= *
comment.box.end.sql= */
```

```
comment.box.start.sql=/*
comment.box.middle.sql= *
comment.box.end.sql= */

api.$(file.patterns.sql)=$(SciteDefaultHome)\api\sql.api
autocomplete.sql.ignorecase=1
autocomplete.sql.start.characters=$(chars.alpha)$(chars.numeric)$_@#
calltip.sql.ignorecase=1
calltip.sql.word.characters=$(chars.alpha)$(chars.numeric)_
```

#### vb: Add indenting

```

comment.block.vbscript='~
```

```

comment.block.vbscript='~

statement.indent.$(file.patterns.wscript)=3 do then
block.start.$(file.patterns.wscript)=3 else elseif for while with
block.end.$(file.patterns.wscript)=3 else elseif end loop next wend

```
