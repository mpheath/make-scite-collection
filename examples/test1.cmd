:: About: Uncallable calltips. Some autocomplete and calltips done by lua extension script.

:: Enter a space to see calltip of setlocal arguments.
setlocal

:: Can enter ( to see (-) based calltip.
:: Can enter space to have labels in autocomplete. Enter space after label to see arguments.
call

:: Command goto is similar. Does not show arguments after the label as goto does not support arguments.
goto

:: Uncallable calltips allows to see arguments for commands like these.
:: Enter a ( character to show the calltip.
find
findstr
mode
ping
shutdown
xcopy


:the_end
exit /b 0

:label1 apple, banana, cherry [, orange [, pepsi]]
exit /b 0

:label2 argumentA, argumentB, argumentC
exit /b 0

:label3 argument1, argument2, argument3
exit /b 0
