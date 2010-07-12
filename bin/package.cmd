set NAME=frozen
del %NAME%.zip
cd ..\..
zip -9 -r %NAME%\bin\%NAME%.zip %NAME%\*.dll %NAME%\*.exe %NAME%\res %NAME%\*.conf kri\engine\shader
pause