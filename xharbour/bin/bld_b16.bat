@echo off
rem
rem $Id: bld_b16.bat,v 1.10 2001/11/04 12:57:43 vszakats Exp $
rem

rem ---------------------------------------------------------------
rem This is a generic template file, if it doesn't fit your own needs 
rem please DON'T MODIFY IT.
rem
rem Instead, make a local copy and modify that one, or make a call to 
rem this batch file from your customized one. [vszakats]
rem ---------------------------------------------------------------

set HB_ARCHITECTURE=dos
set HB_COMPILER=bcc16

call bld.bat %1 %2 %3 %4 %5 %6 %7 %8 %9

