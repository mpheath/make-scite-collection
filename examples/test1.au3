#cs Script Description
; About:  Test styles and basic calltip only.
#ce

#NoTrayIcon

#pragma compile(Out, 'Test_AutoIt3.exe')
#pragma compile(FileVersion, 3.3.14.5)
#pragma compile(ProductVersion, 1.0.0.0)
#pragma compile(FileDescription, 'Test AutoIt3')
#pragma compile(ProductName, 'Test AutoIt3')
#pragma compile(LegalCopyright, 'GPLv3')

; Get username from environment variable.
$sUsername = EnvGet('USERNAME')

; Add cursor between parentheses and press Shift+Ctrl+Space to display the calltip.
MsgBox(0x40000, 'Title', 'My username is ' & $sUsername)
