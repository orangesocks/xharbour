@echo off
rem 
rem $Id: makallvc.bat,v 1.9 2004/01/16 16:54:37 paultucker Exp $
rem 

echo creating system files
call make_vc %1

echo harbour.dll
call dll_vc %1
if errorlevel 1 goto end

:firebird
echo firebird
echo Uncomment this section if you have firebird installed
rem cd contrib\firebird
rem if exist make_vc.bat call make_vc.bat %1
rem cd ..\..
rem if errorlevel 1 goto end

:hbzlib
echo hbzip
cd contrib\hbzlib
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:htmllib
echo htmllib
cd contrib\htmllib
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:internet
echo internet
cd contrib\internet
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:libct
echo libct
cd contrib\libct
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:libmisc
echo libmisc
cd contrib\libmisc
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:libnf
echo libnf
cd contrib\libnf
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:mysql
echo mysql
echo Uncomment this section if you have mysql installed
rem cd contrib\mysql
rem if exist make_vc.bat call make_vc.bat %1
rem cd ..\..
rem if errorlevel 1 goto end

:pgsql
echo pgsql
echo Uncomment this section if you have pgsql installed
rem cd contrib\pgsql
rem if exist make_vc.bat call make_vc.bat %1
rem cd ..\..
rem if errorlevel 1 goto end

:rdd_ads
echo rdd_ads
cd contrib\rdd_ads
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:tip
echo tip
cd contrib\tip
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:unicode
echo unicode
cd contrib\unicode
if exist make_vc.bat call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:what32
echo what32
cd contrib\what32
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:whoo
echo whoo
cd contrib\Whoo
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:woopgui
echo WoopGui
cd contrib\WoopGUI
call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:xhwgui
echo xhwgui
cd contrib\xhwgui
if exist make_vc.bat call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:xVisual
echo xVisual
cd contrib\xVisual
if exist make_vc.bat call make_vc.bat %1
cd ..\..
if errorlevel 1 goto end

:xwt
echo xwt
cd contrib\xwt
call make_vc.bat %1
cd ..\..
:end
