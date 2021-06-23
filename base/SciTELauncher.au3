#cs Script Header
; About:  Gui Launcher for SciTE
; Author: Michael Heath
; AutoIt: 3.3.10.2 or later
#ce

#pragma compile(Out, 'SciTELauncher.exe')
#pragma compile(Icon, '..\scite\win32\SciBall.ico')
#pragma compile(FileVersion, 3.3.10.2)
#pragma compile(ProductVersion, 1.0.0.0)
#pragma compile(FileDescription, 'SciTE Launcher')
#pragma compile(ProductName, 'SciTE Launcher')
#pragma compile(LegalCopyright, 'GPLv3')

#NoTrayIcon

; Check if help is needed.
If $CMDLINE[0] Then
    Switch $CMDLINE[1]
        Case '-h', '/?'
            MsgBox(0x40000, @ScriptName & ' Help', _
                    'Arguments:' & @CRLF _
                     & @CRLF & '-basic' _
                     & @CRLF & @TAB & 'Open with an empty pane.' _
                     & @CRLF & '-readme' _
                     & @CRLF & @TAB & 'Open existing readme.txt or readme.md file else open panes for both.' _
                     & @CRLF & '-register' _
                     & @CRLF & @TAB & 'Open a Gui to register or unregister entries with the shell.' _
                     & @CRLF & '-sources' _
                     & @CRLF & @TAB & 'Create and open a temporary session file or a SciTE.session file.' _
                     & @CRLF & @CRLF _
                     & 'No arguments implies search for session file in the current directory.')
            Exit
    EndSwitch
EndIf

; If "user" subfolder exist, use SciTE_USERHOME else SciTE_HOME.
EnvSet('SciTE_USERHOME')
EnvSet('SciTE_HOME')

If FileExists(@ScriptDir & "\user") Then
    EnvSet('SciTE_USERHOME', @ScriptDir & '\user')
Else
    EnvSet('SciTE_HOME', @ScriptDir)
EndIf

; Get the fullpath to SciTE.
$sSciTE = _GetSciTE()

; Set default pattern for sources.
$sSources = '*.api *.au3 *.bat *.cmd *.hta *.html ' & _
            '*.iss *.js *.json *.lua *.md ' & _
            '*.pas *.php *.properties ' & _
            '*.ps1 *.py *.pyw *.sql *.vbs *.xml'

; Process commandline arguments.
If $CMDLINE[0] Then
    $sArgs = ''

    Switch $CMDLINE[1]
        Case '-basic'
            Run('"' & $sSciTE & '"', '', @SW_HIDE)

        Case '-readme'
            If FileExists('readme.txt') Then
                $sArgs &= ' readme.txt'
            EndIf

            If FileExists('readme.md') Then
                $sArgs &= ' readme.md'
            EndIf

            If Not $sArgs Then
                $sArgs = ' readme.md readme.txt'
            EndIf

            Run('"' & $sSciTE & '"' & $sArgs, '', @SW_HIDE)

        Case '-register'
            _Register()

            Exit

        Case '-sources'
            $sFilename = _Sources()

            If Not @error Then
                Sleep(500)
                _RunSciTESession($sFilename)

                If StringInStr($sFilename, '\') Then
                    Sleep(10000)
                    FileDelete($sFilename)
                EndIf
            EndIf

        Case Else
            If $CMDLINE[0] > 1 Then
                Run('"' & $sSciTE & '" ' & $CMDLINERAW, '', @SW_HIDE)
                Exit
            EndIf

            $bIsFile = FileExists($CMDLINE[1]) And _
                       StringInStr(FileGetAttrib($CMDLINE[1]), 'D') = 0

            If $bIsFile And StringRight($CMDLINE[1], 8) = '.session' Then
                If $CMDLINE[1] = 'SciTE.session' Then
                    _RunSciTESession($CMDLINE[1])
                ElseIf StringRight($CMDLINE[1], 14) = '\SciTE.session' Then
                    _RunSciTESession($CMDLINE[1])
                Else
                    ; Check content for a string to validate as a session.
                    $sContent = FileRead($CMDLINE[1])

                    If StringRegExp($sContent, '(?m)^buffer\.\d+\.path=.+') Then
                        $iFlag = 0x40023
                    Else
                        $iFlag = 0x40123
                    EndIf

                    $sContent = ''

                    ; Ask to handle as session, as file or to cancel.
                    Switch MsgBox($iFlag, 'SciTE Launcher', _
                        'File: "' & $CMDLINE[1] & '"' & @CRLF & @CRLF & _
                        'Load as a SciTE Session?')

                        Case 6    ; yes
                            _RunSciTESession($CMDLINE[1])

                        Case 7    ; no
                            Run('"' & $sSciTE & '" ' & $CMDLINERAW, '', @SW_HIDE)

                        Case Else ; cancel
                            Exit
                    EndSwitch
                EndIf
            Else
                Run('"' & $sSciTE & '" ' & $CMDLINERAW, '', @SW_HIDE)
            EndIf
    EndSwitch
Else
    ; Without commandline arguments, open session else open with an empty pane.
    If FileExists('SciTE.session') Then
        _RunSciTESession('SciTE.session')
    Else
        Run('"' & $sSciTE & '"', '', @SW_HIDE)
    EndIf
EndIf

Exit


Func _GetSciTE()
    ; Get the fullpath to SciTE.

    Local $hFind, $sFound, $sName
    Local $aNames[3] = ['SciTE.exe', 'SciTE32.exe', 'Sc1.exe']

    For $sName In $aNames
        If FileExists(@ScriptDir & '\' & $sName) Then
            Return @ScriptDir & '\' & $sName
        EndIf
    Next

    $hFind = FileFindFirstFile(@ScriptDir & '\Sc???.exe')

    If $hFind = -1 Then
        Return SetError(1, 0, '')
    EndIf

    $sName = ''

    While 1
        $sFound = FileFindNextFile($hFind)
        If @error Then ExitLoop

        If StringRegExp($sFound, '(?i)^Sc\d{3}\.exe$') Then
            $sName = $sFound
        EndIf
    WEnd

    FileClose($hFind)

    If Not $sName Then
        Return SetError(1, 0, '')
    EndIf

    Return @ScriptDir & '\' & $sName
EndFunc


Func _Register()
    ; Register or UnRegister SciTE Launcher.

    Local Const $GUI_CHECKED = 1
    Local Const $GUI_DISABLE = 128
    Local $bRegistered
    Local $iButtonClose, $iButtonRegister, $iButtonUnRegister, $iGui, $iGuiMsg
    Local $iLabelMachine, $iLabelUser, $iRadioMachine, $iRadioUser
    Local $sRootkey1, $sRootkey2
    Local $aCheck[4]
    Local $aRootkeys[4] = [ _
        'HKCU\Software\Classes\*\shell\SciTE', _
        'HKCU\Software\Classes\Directory\Background\shell\SciTE', _
        'HKLM\Software\Classes\*\shell\SciTE', _
        'HKLM\Software\Classes\Directory\Background\shell\SciTE']

    ; Create the Gui.
    $iGui = GUICreate('SciTE Launcher - Register', 320, 220)
    $iRadioUser = GUICtrlCreateRadio('Current User', 20, 20)
    $iLabelUser = GUICtrlCreateLabel('', 150, 20, 150, 40)
    $iRadioMachine = GUICtrlCreateRadio('Local Machine', 20, 70)
    $iLabelMachine = GUICtrlCreateLabel('', 150, 70, 150, 40)
    $iCheckboxAdmin = GUICtrlCreateCheckbox('Add Run as administrator', 20, 115)
    $iCheckboxSubmenu = GUICtrlCreateCheckbox('Always use submenu for files', 20, 135)
    $iButtonRegister = GUICtrlCreateButton('&Register', 20, 175, 80)
    $iButtonUnRegister = GUICtrlCreateButton('&UnRegister', 120, 175, 80)
    $iButtonClose = GUICtrlCreateButton('&Close', 220, 175, 80)

    GUICtrlSetState($iRadioUser, $GUI_CHECKED)

    If Not IsAdmin() Then
        GUICtrlSetState($iRadioMachine, $GUI_DISABLE)
    EndIf

    GUISetState()

    ; Check status.
    for $i1 = 0 To UBound($aRootkeys) -1
        RegRead($aRootkeys[$i1], '')
        $aCheck[$i1] = @error <= 0
    Next

    GUICtrlSetData($iLabelUser, 'Files: ' & $aCheck[0] & @CRLF & 'Background: ' & $aCheck[1])
    GUICtrlSetData($iLabelMachine, 'Files: ' & $aCheck[2] & @CRLF & 'Background: ' & $aCheck[3])

    ; Get Gui Messages.
    While 1
        $iGuiMsg = GUIGetMsg()

        Switch $iGuiMsg
            Case -3, $iButtonClose
                Exit

            Case $iButtonRegister, $iButtonUnRegister

                ; Set root keys.
                If GUICtrlRead($iRadioUser) = $GUI_CHECKED Then
                    $sRootkey1 = $aRootkeys[0]
                    $sRootkey2 = $aRootkeys[1]
                    $bRegistered = $aCheck[0] Or $aCheck[1]
                Else
                    $sRootkey1 = $aRootkeys[2]
                    $sRootkey2 = $aRootkeys[3]
                    $bRegistered = $aCheck[2] Or $aCheck[3]
                EndIf

                ; UnRegister.
                If $iGuiMsg = $iButtonUnRegister Then
                    RegDelete($sRootkey1)
                    RegDelete($sRootkey2)
                ElseIf $bRegistered Then
                    MsgBox(0x30, 'Warning', 'An entry is True.' & @CRLF & _
                        'UnRegister required before Register!', 0, $iGui)
                Else
                    ; Register Files.
                    If GUICtrlRead($iCheckboxAdmin) = $GUI_CHECKED _
                    Or GUICtrlRead($iCheckboxSubmenu) = $GUI_CHECKED Then

                        RegWrite($sRootkey1, 'MuiVerb', 'REG_SZ', 'SciTE')
                        RegWrite($sRootkey1, 'SubCommands', 'REG_SZ', '')

                        RegWrite($sRootkey1 & '\shell\basic', 'Icon', 'REG_SZ', @ScriptFullPath)
                        RegWrite($sRootkey1 & '\shell\basic', 'MuiVerb', 'REG_SZ', 'Basic')
                        RegWrite($sRootkey1 & '\shell\basic\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" "%1"')

                        If GUICtrlRead($iCheckboxAdmin) = $GUI_CHECKED Then
                            RegWrite($sRootkey1 & '\shell\runas', 'Extended', 'REG_SZ', '')
                            RegWrite($sRootkey1 & '\shell\runas', 'HasLUAShield', 'REG_SZ', '')
                            RegWrite($sRootkey1 & '\shell\runas', 'MuiVerb', 'REG_SZ', 'Run as administrator')
                            RegWrite($sRootkey1 & '\shell\runas\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" "%1"')
                        EndIf
                    Else
                        RegWrite($sRootkey1, 'Icon', 'REG_SZ', @ScriptFullPath)
                        RegWrite($sRootkey1 & '\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" "%1"')
                    EndIf

                    ; Register Background.
                    RegWrite($sRootkey2, 'MuiVerb', 'REG_SZ', 'SciTE')
                    RegWrite($sRootkey2, 'SubCommands', 'REG_SZ', '')

                    RegWrite($sRootkey2 & '\shell\basic', 'Icon', 'REG_SZ', @ScriptFullPath)
                    RegWrite($sRootkey2 & '\shell\basic', 'MuiVerb', 'REG_SZ', 'Basic')
                    RegWrite($sRootkey2 & '\shell\basic\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -basic')

                    RegWrite($sRootkey2 & '\shell\extended', 'Icon', 'REG_SZ', @ScriptFullPath)
                    RegWrite($sRootkey2 & '\shell\extended', 'MuiVerb', 'REG_SZ', 'Extended')
                    RegWrite($sRootkey2 & '\shell\extended\command', '', 'REG_SZ', '"' & @ScriptFullPath & '"')

                    RegWrite($sRootkey2 & '\shell\readme', 'Icon', 'REG_SZ', @ScriptFullPath)
                    RegWrite($sRootkey2 & '\shell\readme', 'MuiVerb', 'REG_SZ', 'Readme')
                    RegWrite($sRootkey2 & '\shell\readme\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -readme')

                    If GUICtrlRead($iCheckboxAdmin) = $GUI_CHECKED Then
                        RegWrite($sRootkey2 & '\shell\runas', 'Extended', 'REG_SZ', '')
                        RegWrite($sRootkey2 & '\shell\runas', 'HasLUAShield', 'REG_SZ', '')
                        RegWrite($sRootkey2 & '\shell\runas', 'MuiVerb', 'REG_SZ', 'Run as administrator')
                        RegWrite($sRootkey2 & '\shell\runas\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -basic')
                    EndIf

                    RegWrite($sRootkey2 & '\shell\sources', 'Icon', 'REG_SZ', @ScriptFullPath)
                    RegWrite($sRootkey2 & '\shell\sources', 'MuiVerb', 'REG_SZ', 'Sources')
                    RegWrite($sRootkey2 & '\shell\sources\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -sources')
                EndIf

                ; Check status.
                for $i1 = 0 To UBound($aRootkeys) -1
                    RegRead($aRootkeys[$i1], '')
                    $aCheck[$i1] = @error <= 0
                Next

                GUICtrlSetData($iLabelUser, 'Files: ' & $aCheck[0] & @CRLF & 'Background: ' & $aCheck[1])
                GUICtrlSetData($iLabelMachine, 'Files: ' & $aCheck[2] & @CRLF & 'Background: ' & $aCheck[3])
        EndSwitch
    WEnd
EndFunc


Func _RunSciTESession($sFilename)
    ; Load the file as a SciTE Session.

    If $sFilename = 'SciTE.session' Then
        Run('"' & $sSciTE & '" -loadsession:SciTE.session', '', @SW_HIDE)
    Else
        $sFilename = StringReplace($sFilename, '\', '\\')
        Run('"' & $sSciTE & '" "-loadsession:' & $sFilename & '"', '', @SW_HIDE)
    EndIf
EndFunc


Func _Sources()
    ; Display a Gui to create a session file.

    Local Const $GUI_CHECKED = 1
    Local Const $GUI_ENABLE  = 64
    Local Const $GUI_DISABLE = 128
    Local $bNoTestFiles, $hWrite
    Local $i1, $iButtonCancel, $iButtonOK, $iCheckboxRecurse, $iComboSession
    Local $iComboSources, $iEditSources, $iGuiLocal, $iPid
    Local $sBinaries, $sCommand, $sData, $sFilename, $sFound, $sPattern
    ; Global $sSources

    $iGuiLocal = GUICreate('SciTE Launcher', 345, 230)

    GUICtrlCreateLabel('Source', 20, 15)
    $iComboSources = GUICtrlCreateCombo('Default', 20, 35, 140, Default, 0x3)

    If FileExists('_FOSSIL_') Then
        If Not StringInStr(FileGetAttrib('_FOSSIL_'), 'D') Then
            GUICtrlSetData(Default, 'Fossil All')
            GUICtrlSetData(Default, 'Fossil Edited')
        EndIf
    EndIf

    If FileExists('.git') Then
        If StringInStr(FileGetAttrib('.git'), 'D') Then
            GUICtrlSetData(Default, 'Git All')
            GUICtrlSetData(Default, 'Git Edited')
        EndIf
    EndIf

    GUICtrlSetData(Default, 'Html|HtmlHelp|Readme|Test Prefixed|Test Skipped|Specify')

    GUICtrlCreateLabel('Session', 180, 15)
    $iComboSession = GUICtrlCreateCombo('Temporary', 180, 35, 140, Default, 0x3)
    GUICtrlSetData(Default, 'SciTE.session')

    $iEditSources = GUICtrlCreateEdit($sSources, 20, 80, 300, 80, 0x0004)
    GUICtrlSetState(Default, $GUI_DISABLE)

    $iCheckboxRecurse = GUICtrlCreateCheckbox('&Recurse', 20, 190)

    $iButtonOK = GUICtrlCreateButton('&OK', 150, 185, 80)
    $iButtonCancel = GUICtrlCreateButton('&Cancel', 240, 185, 80)
    GUISetState()

    While 1
        Switch GUIGetMsg()
            Case -3, $iButtonCancel
                Exit

            Case $iButtonOK

                ; Check overwrite of SciTE.session.
                If GUICtrlRead($iComboSession) = 'SciTE.session' Then
                    If FileExists('SciTE.session') Then
                        Switch MsgBox(0x24, @ScriptName, _
                            'SciTE.session already exist.' & @CRLF & _
                            'This file may have some importance.' & @CRLF & @CRLF & _
                            'Do you want to continue?', 0, $iGuiLocal)

                            Case 7
                                ContinueLoop
                        EndSwitch
                    EndIf
                EndIf

                ; Build the command.
                Switch GUICtrlRead($iComboSources)
                    Case 'Fossil All'
                        $sCommand = 'fossil ls'

                    Case 'Fossil Edited'
                        $sCommand = 'fossil changes --edited'

                    Case 'Git All'
                        $sCommand = 'git ls-files'

                    Case 'Git Edited'
                        $sCommand = 'git ls-files -m'

                    Case Else
                        If GUICtrlRead($iComboSources) = 'Specify' Then
                            $sPattern = GUICtrlRead($iEditSources)
                        ElseIf StringLeft(GUICtrlRead($iComboSources), 4) = 'Html' Then
                            $sPattern = '*.css *.hta *.html *.js *.xhtml'
                        ElseIf GUICtrlRead($iComboSources) = 'Readme' Then
                            $sPattern = 'readme.txt readme.md'
                        Else
                            $sPattern = $sSources
                        EndIf

                        If GUICtrlRead($iComboSources) == 'HtmlHelp' Then
                            Switch MsgBox(0x24, @ScriptName, 'Include Html filetypes?', 0, $iGuiLocal)
                                Case 6
                                    $sPattern &= '*.hhc *.hhk *.hhp'
                                Case 7
                                    $sPattern = '*.hhc *.hhk *.hhp'
                            EndSwitch
                        EndIf

                        $sPattern = StringStripWS($sPattern, 7)

                        If GUICtrlRead($iComboSources) = 'Test Prefixed' Then
                            $sPattern = StringReplace($sPattern, '*.', 'test*.')
                        EndIf

                        If Not $sPattern Then
                            MsgBox(0x40040, @ScriptName, 'No pattern', 0, $iGuiLocal)
                            ContinueLoop
                        EndIf

                        If GUICtrlRead($iCheckboxRecurse) = $GUI_CHECKED Then
                            $sCommand = 'cmd /c dir /a-d /b /s ' & $sPattern
                        Else
                            $sCommand = 'cmd /c dir /a-d /b ' & $sPattern
                        EndIf
                EndSwitch

                ; Run the command and get the paths data.
                $iPid = Run($sCommand, '', @SW_HIDE, 2)
                $sData = ''

                Do
                    Sleep(10)
                    $sData &= StdoutRead($iPid)
                Until @error

                $sData = StringStripWS($sData, 3)

                If Not $sData Then
                    MsgBox(0x40040, @ScriptName, 'No source files found', 0, $iGuiLocal)
                    ContinueLoop
                EndIf

                ; Get the session filename.
                $sFilename = GUICtrlRead($iComboSession)

                If $sFilename = 'Temporary' Then
                    For $i1 = 1000 To 9999
                        If Not FileExists(@TempDir & '\SciTE' & $i1 & '.session') Then
                            $sFilename = @TempDir & '\SciTE' & $i1 & '.session'
                            ExitLoop
                        EndIf
                    Next

                    If $sFilename = 'Temporary' Then
                        MsgBox(0x40030, @ScriptName, 'Failed to get a Temporary name', 0, $iGuiLocal)
                        Exit 1
                    EndIf
                EndIf

                ; Write the paths to a session file.
                $hWrite = FileOpen($sFilename, 2)

                If $hWrite = -1 Then
                    MsgBox(0x40030, @ScriptName, 'Failed to open "' & $sFilename & '" for write', 0, $iGuiLocal)
                    Exit 1
                EndIf

                If StringInStr($sFilename, '\') Then
                    $i1 = 0
                Else
                    $i1 = 1

                    FileWrite($hWrite, _
                        '# SciTE session file generated by ' & @ScriptName & @CRLF & @CRLF & _
                        'buffer.1.path=' & $sFilename & @CRLF)
                EndIf

                $bNoTestFiles = (GUICtrlRead($iComboSources) = 'Test Skipped')

                $sData = StringStripCR($sData)

                $sBinaries = ''

                For $sFound In StringSplit($sData, @LF, 3)
                    If Not $sFound Then
                        ContinueLoop
                    EndIf

                    If $bNoTestFiles And StringLeft($sFound, 4) = 'test' Then
                        ContinueLoop
                    EndIf

                    If StringRegExp($sFound, '\.(?:bmp|chm|db|dll|exe|gif|jpg|png|zip)$') Then
                        $sBinaries &= $sFound & @CRLF
                        ContinueLoop
                    EndIf

                    $i1 += 1
                    $sFound = StringReplace($sFound, '/', '\')
                    FileWrite($hWrite, StringFormat('buffer.%s.path=%s', $i1, $sFound) & @CRLF)
                Next

                FileClose($hWrite)

                If $sBinaries Then
                    $sBinaries = StringStripWS($sBinaries, 3)

                    MsgBox(0x40040, @ScriptName, _
                        'Skipped these binaries based on extension:' & @CRLF & _
                        $sBinaries, 0, $iGuiLocal)
                EndIf

                ; Close Gui.
                GUIDelete($iGuiLocal)

                ; Warn if greater than 100 buffers.
                If $i1 > 100 Then
                    Switch MsgBox(0x40131, 'SciTE Launcher', _
                            'Sources count is ' & $i1 & ' buffers.' & @CRLF & @CRLF & _
                            'SciTE allows a maximum of 100 buffers which ' & _
                            'could be lower if the property named buffers ' & _
                            'is set lower than 100.' & @CRLF & @CRLF & _
                            'Select OK to open the session in SciTE. ' & _
                            'Select Cancel to delete the ' & _
                            'session and exit.')

                        Case 2 ; cancel
                            FileDelete($sFilename)
                            Exit
                    EndSwitch
                EndIf

                Return $sFilename

            Case $iComboSources

                ; Set state of Sources Combobox.
                Switch GUICtrlRead($iComboSources)
                    Case 'Specify'
                        GUICtrlSetState($iEditSources, $GUI_ENABLE)

                    Case Else
                        GUICtrlSetState($iEditSources, $GUI_DISABLE)
                EndSwitch

                ; Set state of Recurse Checkbox.
                Switch GUICtrlRead($iComboSources)
                    Case 'Fossil All', 'Fossil Edited', 'Git All', 'Git Edited'
                        GUICtrlSetState($iCheckboxRecurse, $GUI_DISABLE)

                    Case Else
                        GUICtrlSetState($iCheckboxRecurse, $GUI_ENABLE)
                EndSwitch
        EndSwitch
    WEnd
EndFunc
