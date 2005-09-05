/*
 * $Id: hbmake.prg,v 1.150 2005/08/04 13:00:36 modalsist Exp $
 */

/*
 * xHarbour Project source code:
 * hbmake.prg xHarbour make utility main file
 *
 * Copyright 2000-2005 Luiz Rafael Culik <culikr@uol.com.br>
 * www - http://www.xharbour.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */
#include "fileio.ch"
#include "common.ch"
#include "radios.ch"
//#include "wvtgui.ch"
#define EOL Hb_OsNewLine()
#define CRLF Hb_OsNewLine()
#xtranslate TimeToSec(<x>) => ( ( Val( Substr( <x>, 1, 2 ) ) * 3600 ) +( Val( Substr( <x>, 4, 2 ) ) * 60 ) + ( Val( Substr( <x>, 7, 2 ) ) ) )


#translate DateDiff(<x>,<y>) => (<x>-<y>)

#Define HBM_USE_DEPENDS    // Set this to have section #DEPENDS parsed like RMake, Ath 2004-06
                           // An extra parameter is added to FileIsNewer() to have it check the INCLUDE paths also
                           // Interactive mode asks whether sources should be scanned for dependencies (#include, set procedure to, set proc to

/*
Beginning Static Variables Table
Default Values for core variables are set here
New Core vars should only be added on this section
*/

STATIC s_cHbMakeVersion  := "1.150"
STATIC s_lPrint          := .F.
STATIC s_aDefines        := {}
STATIC s_aBuildOrder     := {}
STATIC s_aCommands       := {}
STATIC s_aMacros         := {}
STATIC s_aPrgs           := {}
STATIC s_aExtLibs        := {}
#IfDef HBM_USE_DEPENDS
STATIC s_aDepends        := {}
#Endif
STATIC s_aCs             := {}
STATIC s_aObjs           := {}
STATIC s_aObjsc          := {}
STATIC s_aSrcPaths       := {}
STATIC s_lEof            := .F.
STATIC s_aResources      := {}
STATIC s_nMakeFileHandle 
STATIC s_cMakeFileName   := "makefile.lnk"
STATIC s_cLinkCommands   := ""
STATIC s_lLinux          := .F.
STATIC s_lOS2            := .F.
STATIC s_lWin32          := .F.
STATIC s_lBcc            := .F.  // Borland C compiler
STATIC s_lPcc            := .F.  // Pelles C compiler
STATIC s_lMSVcc          := .F.  // Microsoft Visual C compiler
STATIC s_lGcc            := .F.  // GNU/MinGW C compiler
STATIC s_lMingw          := .F.  
STATIC s_lForce          := .F.  // "-f" flag
STATIC s_szProject       := ""
STATIC s_lLibrary        := .F.
STATIC s_lIgnoreErrors   := .F.
STATIC s_lExtended       := .T.
STATIC s_lRecursive      := .F.
STATIC s_lCancelRecursive:= .F.
STATIC s_lEditMake       := .F.
STATIC s_lCompress       := .F.
STATIC s_lExternalLib    := .F.
STATIC s_aDir
STATIC s_aLangMessages   := {}
STATIC s_cAppName        := ""
STATIC s_cDefLang
STATIC s_cLog            := ""   // log file name.
STATIC s_cMap            := ""   // map file name. For borland c
STATIC s_cTds            := ""   // state file name. For borland c
STATIC s_lGenPpo         := .F.
STATIC s_nLang           := 2    // default language is english
STATIC s_lMt             := .F.
STATIC s_cUserDefine     := ""
STATIC s_cUserInclude    := ""
STATIC s_lxFwh           := .F.
STATIC s_nFilesToAdd     := 5
STATIC s_nWarningLevel   := 0
STATIC s_AppName         := ""
STATIC s_lAsDll          := .F.
STATIC s_cAlertMsg       := ""
STATIC s_cHbCfgFileName  := "harbour.cfg"   // don't change this file name.
STATIC s_cObjDir         := "obj"
STATIC s_lGui            := .F.

*---------------------------------------------
FUNCTION MAIN( cFile, p1, p2, p3, p4, p5, p6 )
*---------------------------------------------

   LOCAL aFile       := {}
   LOCAL aDef        := {}
   LOCAL cMakeParams := ""
   LOCAL nLang       := GETUSERLANG()
   LOCAL nPos
   LOCAL aPpo

   CLS

   FErase( s_cMakeFileName )

   SET(39,159)

   cMakeParams := ConvertParams( @cFile, aFile, p1, p2, p3, p4, p5, p6 )

   IF !empty( cMakeParams )

      cMakeParams := upper( cMakeParams )

      IF "-LPT" $ cMakeParams
         nLang := 1
      ELSEIF "-LEN" $ cMakeParams
         nLang := 2
      ELSEIF "-LES" $ cMakeParams
         nLang := 3
      ENDIF

   ENDIF

   s_nLang := nLang
   s_cDefLang := IIF( s_nLang == 1, "PT", IIF( s_nLang == 2, "EN", "ES" ) )
   s_aLangMessages := BuildLangArray( s_cDefLang )


   IF PCount() == 0 .or.;
      "/?" IN cMakeParams .or. ;
      "-?" IN cMakeParams .or. ;
      "/h" IN cMakeParams .or. ;
      "-h" IN cMakeParams 
      ShowHelp()
      RETURN NIL
   ENDIF

   IF "credits" IN lower(cMakeParams)
      Hbmake_Credits()
      RETURN NIL
   ENDIF


   IF Empty( GetHarbourDir() )
      IF s_nLang=1
         s_cAlertMsg := "Hbmake necessita do xharbour bin no path."
      ELSEIF s_nLang=3
         s_cAlertMsg := "Hbmake necessita de lo xharbour bin en lo path."
      ELSE
         s_cAlertMsg := "Hbmake need of the xharbour bin in the path."
      ENDIF
      alert( s_cAlertMsg )
      RUN( "PATH" )
      RETURN NIL
   ENDIF

   IF Upper( OS() ) == "WINDOWS XP"
      s_cMakeFileName := "makefile.tmp"
   ENDIF

   IF s_nLang=1
      SET DATE BRITISH
   ELSE
      SET DATE ANSI
   ENDIF

   SET SCORE OFF
   SET CENTURY ON
   SET TRACE ON

   DEFAULT p1 TO ""
   DEFAULT p2 TO ""
   DEFAULT p3 TO ""
   DEFAULT p4 TO ""
   DEFAULT p5 TO ""
   DEFAULT p6 TO ""

   // Assing Default C Compiler upon The OS 

   s_lOS2   := ( "OS/2" IN OS() )
   s_lLinux := ( "LINUX" IN Upper( OS() ) )
   s_lWin32 := ( "WINDOWS" IN Upper( OS() ) )

   IF s_lOS2 .OR. s_lLinux
      s_lGcc   := .T.
      s_lBcc   := .F.
      s_lPcc   := .F.
      s_lMSVcc := .F.
      s_lMingw := .F.
   ELSEIF s_lWin32
      s_lGcc   := .F.
      s_lBcc   := .T.
      s_lPcc   := .F.
      s_lMSVcc := .F.
      s_lMingw := .F.
   ENDIF


   IF Len( aFile ) > 1
      IF s_nLang=1
         s_cAlertMsg :="Arquivo definido mais que uma vez."
      ELSEIF s_nLang=3
         s_cAlertMsg:="Fichero definido m�s que una vez."
      ELSE
         s_cAlertMsg:="File defined more than once."
      ENDIF
      alert( s_cAlertMsg )
      RETURN NIL
   ENDIF

   IF Len( aFile ) > 0
      cFile := aFile[ 1 ]
   ELSE
      cFile := ""
   ENDIF

   IF Empty(cFile)
      IF s_nLang=1
         s_cAlertMsg := "Nome de arquivo inv�lido."
      ELSEIF s_nLang=3
         s_cAlertMsg := "Nombre de fichero invalido."
      ELSE
         s_cAlertMsg := "Invalid file name."
      ENDIF
      alert( s_cAlertMsg )
      RETURN NIL
   ENDIF

   if PCount() > 1
      ProcessParameters( cMakeParams )
   endif

   IF s_lForce .and. !File( cFile )
      IF s_nLang=1
         s_cAlertMsg := "Arquivo <"+cFile+"> n�o encontrado."
      ELSEIF s_nLang=3
         s_cAlertMsg := "Fichero <"+cFile+"> no encontrado."
      ELSE
         s_cAlertMsg := "File <"+cFile+"> not found."
      ENDIF
      alert( s_cAlertMsg )
      RETURN NIL
   ENDIF


   s_AppName := Substr( cFile,1 , AT(".",cFile) -1)
//   s_cLog    := s_AppName + ".out"
   s_cLog    := s_AppName + ".log"

   FErase( (s_AppName+".out") ) // erase old *.out log filename
   FErase( s_cLog )

   if s_lBcc
      /* if you need of these files, comment the lines below. */
      s_cMap    := s_AppName + ".map"
      s_cTds    := s_AppName + ".tds"
      FErase( s_cMap )
      FErase( s_cTds )
   endif

   // Edit/Create MakeFile...

   if !s_lForce .and. PCount() > 1

      IF s_lLibrary
         CreateLibMakeFile( cFile )
      ELSE
         CreateMakeFile( cFile )
      ENDIF

      if !s_lGenppo
         Delete_ppo()
      endif

      RETURN NIL

   endif


   // Compile MakeFile...

   CLS

   // Make file is parsed here

   IF !ParseMakeFile( cFile )

      IF s_nLang = 1      // brazilian portuguese 
         s_cAlertMsg := "<"+cFile+ "> n�o pode ser aberto. FERROR("+Ltrim(Str(FError()))+"). O HbMake ser� fechado."
      ELSEIF s_nLang = 3  // spanish
         s_cAlertMsg := "<"+cFile + "> no pode ser abierto. FERROR("+Ltrim(Str(FError()))+"). Lo HbMake ser� cerrado."
      ELSE                // english
         s_cAlertMsg := "<"+cFile + "> cannot be openned. FERROR("+Ltrim(Str(FError()))+"). The HbMake will be closed."
      ENDIF

      Alert( s_cAlertMsg )

      RETURN NIL

   ENDIF

   IF s_lPrint
      PrintMacros()
   ENDIF

   set cursor off

   IF !IsDirectory( s_cObjDir )
      MakeDir( s_cObjDir )
   ENDIF

   IF s_lForce
      CompileFiles()
   ELSE
      CompileUpdatedFiles()
   ENDIF

   set cursor on
   setpos(9,0)
   Outstd( s_cLinkCommands + CRLF )
   set cursor off
   __RUN( (s_cLinkCommands) )

   IF s_lCompress .AND. !s_lLibrary
      set cursor on
      setpos(9,0)
      __Run( " upx -9 "+ (s_cAppName) )
      set cursor off
   ENDIF

   tracelog( s_lasdll)

   IF s_lasdll .or. lower(right(s_cAppName,3)) == 'dll'
       __Run( Replacemacros("implib $(BHC)\lib\" + left(s_cAppName,at(".",s_cAppName)-1)+".lib " +s_cAppName ))
   ENDIF


   if s_lBcc
      /*
      NOTE: The TDS file is always created by borland linker.
      If you need of this file, comment the lines below and
      remove "-x" flag that is created by hbmake in the
      LFLAGS statment for Borland compiler.
      */
      FErase( s_cMap ) 
      FErase( s_cTds ) 
   endif

   if !s_lGenppo
      Delete_ppo()
   endif

   set cursor on

RETURN NIL

*------------------------------
FUNCTION ParseMakeFile( cFile )
*------------------------------

   LOCAL nPos
   LOCAL cBuffer     := {}
   LOCAL cMacro      := "#BCC"
   LOCAL cDep        := "#DEPENDS"
   LOCAL cOpt        := "#OPTS"
   LOCAL cCom        := "#COMMANDS"
   LOCAL cBuild      := "#BUILD"
   LOCAL cTemp       := ""
   LOCAL cTemp1      := ""
   LOCAL aTemp       := {}
   LOCAL lMacrosec   := .T.
   LOCAL lBuildSec   := .F.
   LOCAL lComSec     := .F.
#IFDEF HBM_USE_DEPENDS
   LOCAL lDepSec     := .F.
#ENDIF
   LOCAL aTemp1      := {}
   LOCAL cCfg        := ""
   LOCAL lCfgFound   := .F.
   LOCAL aTempCFiles := {}
   LOCAL lLinux      :=  'linux' IN  Lower( OS() )
   LOCAL aLib
   LOCAL aLibx
   LOCAL lDjgpp      := "GNU C" in HB_COMPILER()
   LOCAL x           := 1
   LOCAL ct
   LOCAL nFHandle
   local cTrash :=""


   nFHandle := FT_FUSE( cFile, FO_READ )

   IF nFHandle < 0
      RETURN .F.
   ENDIF

   #IFndef __PLATFORM__Windows
      IF !FILE("hbtemp.c")
         CreateLink()
      ENDIF
   #ENDIF

   cBuffer := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

   AAdd( s_aDefines, { "HMAKEDIR", GetHarbourDir() } )

   IF s_lBcc
      AAdd( s_aDefines, { "MAKEDIR", GetBccDir() } )
   ELSEIF s_lGcc
      AAdd( s_aDefines, { "MAKEDIR", GetGccDir() } )
   ELSEIF s_lMSVcc
      AAdd( s_aDefines, { "MAKEDIR", GetVccDir() } )
   ELSEIF s_lPcc
      AAdd( s_aDefines, { "MAKEDIR", GetPccDir() } )
   ENDIF

   WHILE ! s_lEof

      IF cMacro IN  cBuffer
         lMacroSec := .T.
         lBuildSec := .F.
         lComSec   := .F.
#IFDEF HBM_USE_DEPENDS
         lDepSec   := .F.
#Endif
      ELSEIF  cBuild IN cBuffer
         lMacroSec := .F.
         lBuildSec := .T.
         lComSec   := .F.
#IfDef HBM_USE_DEPENDS
         lDepSec   := .F.
#Endif
      ELSEIF  cCom IN  cBuffer
         lBuildSec := .F.
         lComSec   := .T.
         lMacroSec := .F.
#IfDef HBM_USE_DEPENDS
         lDepSec   := .F.
      ELSEIF  cDep IN  cBuffer
         lBuildSec := .F.
         lComSec   := .F.
         lMacroSec := .F.
         lDepSec   := .T.
#Endif
      ELSE
         ? "Invalid Make File"
         FClose( nFHandle )
         RETURN .F.
      ENDIF

      cTemp := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

      IF  "//" IN  cTemp

         WHILE At( "//", cTemp ) > 0

            cTemp := Strtran( cTemp, " //", "" )
            cTemp += Trim( Substr( ReadLN( @s_lEof ), 1 ) )

         ENDDO

         cTemp := Strtran( cTemp, " //", "" )

      ENDIF

      aTemp := ListAsArray2( Alltrim( cTemp ), "=" )

      IF lmacrosec

         IF Alltrim( Left( cTemp, 7 ) ) <> '!ifndef' .AND. Alltrim( Left( cTemp, 6 ) ) <> "!endif" .AND. Alltrim( Left( cTemp, 7 ) ) <> '!IFfile' .AND. Alltrim( Left( cTemp, 7 ) ) <> '!stdout' .AND. Alltrim( Left( cTemp, 6 ) ) <> '!ifdef'

            IF Len( aTemp ) > 1

                IF  "$" IN aTemp[ 2 ]

                  IF s_lGcc .AND. aTemp[ 1 ] = "CFLAG1" .OR. s_lGcc .AND. aTemp[ 1 ] = "CFLAG2"
                      AAdd( s_aMacros, { aTemp[ 1 ], Strtran( Replacemacros( aTemp[ 2 ] ), "\", "/" ) } )

                      x++
                  ELSE

                     IF aTemp[ 1 ] == "MT" .AND. aTemp[ 2 ] == "YES"
                        s_lMt := .T.
                     ENDIF

                     IF aTemp[ 1 ] == "LIBFILES" .AND. ! s_lMt

                        aLib := ListAsArray2( aTemp[ 2 ], ' ' )

                        FOR each aLibx in aLib

                           IF At( 'mt.lib', Lower( aLibx ) ) > 0
                              s_lMt := .T.
                           ENDIF

                           IF "-l" in Lower( aLibx )
                              s_lBcc    := .F.
                              s_lGcc    := .T.
                              s_lMSVcc  := .F.
                              s_lPcc    := .F.
                              s_aDefines[2] := { "MAKEDIR", GetGccDir() }
                           ENDIF

                        NEXT

                     ENDIF

                     IF aTemp[ 1 ] == "ALLOBJ" .AND. ! s_lMt

                     ENDIF

                     AAdd( s_aMacros, { aTemp[ 1 ], Replacemacros( aTemp[ 2 ] ) } )

                  ENDIF

               ELSE

                  IF s_lGcc .AND. aTemp[ 1 ] = "CFLAG1" .OR. s_lGcc .AND. aTemp[ 1 ] = "CFLAG2"
                     AAdd( s_aMacros, { aTemp[ 1 ], Strtran( aTemp[ 2 ], "\", "/" ) } )

                      x++

                  ELSE
                     IF aTemp[ 1 ] == "LIBFILES" .AND. ! s_lMt

                        aLib := ListAsArray2( aTemp[ 2 ], ' ' )

                        FOR each aLibx in aLib

                           IF At( 'mt.lib', Lower( aLibx ) ) > 0
                              s_lMt := .T.
                           ENDIF

                           IF "-l" in Lower( aLibx )
                              s_lBcc    := .F.
                              s_lGcc    := .T.
                              s_lMSVcc  := .F.
                              s_lPcc    := .F.
                              s_aDefines[2] := { "MAKEDIR", GetGccDir() }
                              s_aMacros[2,2] :=  GetGccDir()
                           ENDIF

                        NEXT

                     ENDIF
                        AAdd( s_aMacros, { aTemp[ 1 ], aTemp[ 2 ] } )
                  ENDIF

               ENDIF

            ENDIF


            IF aTemp[ 1 ] == "COMPRESS"
               s_lCompress := "YES" IN aTemp[ 2 ]
            ENDIF

            IF aTemp[ 1 ] == "EXTERNALLIB"
               s_lExternalLib := "YES" IN aTemp[ 2 ]
            ENDIF

            IF aTemp[ 1 ] == "SRC02"  // obj dir
               s_cObjDir := aTemp[ 2 ]
            ENDIF

            IF aTemp[ 1 ] == "PROJECT"

               IF At( '.lib', aTemp[ 2 ] ) > 0 .OR. At( '.a', aTemp[ 2 ] ) > 0
                  s_lLibrary := .T.
               ENDIF

               s_cAppName := SubStr( aTemp[ 2 ], 1, AT( ' ', aTemp[ 2 ] ) -1 )

            ENDIF

            IF aTemp[ 1 ] == "OBJFILES"
               s_aObjs := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
            ENDIF

            IF aTemp[ 1 ] == "OBJCFILES"

               aTemp1 := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )

               IF Len( aTemp1 ) == 1

                  IF ! Empty( aTemp[ 1 ] )
                      s_aObjsC := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
                   ENDIF

               ELSE
                  s_aObjsC := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
               ENDIF

            ENDIF

            IF aTemp[ 1 ] == "PRGFILES"
               s_aPrgs     := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
               s_lExtended := .T.
               lCfgFound := FindHarbourCfg( @cCfg )
            ENDIF

            IF aTemp[ 1 ] == "PRGFILE"
               s_aPrgs := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
            ENDIF

            IF aTemp[ 1 ] == "EXTLIBFILES"
               s_aExtLibs  := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
            ENDIF

            IF aTemp[ 1 ] == "CFILES"

               IF s_lExtended
                  aTempCFiles := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )

                  IF ( Len( aTempCFiles ) == 1 )

                     IF ! Empty( aTempCFiles[ 1 ] )
                        s_aCs := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
                     ENDIF

                  ELSE
                     s_aCs := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
                  ENDIF

               ELSE
                  s_aCs := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
               ENDIF


            ENDIF

            IF aTemp[ 1 ] == "RESFILES"
               s_aResources := ListAsArray2( replacemacros( aTemp[ 2 ] ), " " )
            ENDIF

         ELSE

            IF '!ifndef' IN cTemp
               CheckDefine( cTemp )
            ELSEIF  '!ifdef' IN cTemp
               CheckIFdef( cTemp )
            ELSEIF '!iffile' IN cTemp
               CheckIFFile( cTemp )
            ELSEIF  '!stdout' IN cTemp
               CheckStdOut( cTemp )
            ENDIF

         ENDIF

      ENDIF

      IF lBuildSec

         s_szProject   := cTemp
         s_aBuildOrder := ListAsArray2( cTemp, ":" )

         IF !s_lLibrary
            SetBuild()
         ELSE
            SetLibBuild()
         ENDIF

      ENDIF

      IF lComSec

         IF ! Empty( cTemp )
            Setcommands( cTemp )
         ENDIF

      ENDIF

#IfDef HBM_USE_DEPENDS
      IF lDepSec

         IF ! Empty( cTemp )
            SetDependencies( cTemp )
         ENDIF

      ENDIF
#Endif

      IF cTemp = "#BUILD"
         cBuffer := cTemp
      ELSEIF cTemp == "#COMMANDS"
         cbuffer := cTemp
#IfDef HBM_USE_DEPENDS
      ELSEIF cTemp == "#DEPENDS"
         cbuffer := cTemp
#Endif
      ENDIF

   ENDDO

   FT_FUSE()  // Close the opened file & release memory

   IF s_lExtended .AND. (!lCfgFound .or. s_lForce)

      IF s_lBcc
         BuildBorCfgFile()
      ELSEIF s_lMSVcc
         BuildMscCfgFile()
      ELSEIF s_lPcc
         BuildPellesCfgFile()
      ELSEIF s_lGcc .AND. !lLinux
         BuildGccCfgFile()
      ELSEIF s_lGcc .AND. lLinux
         BuildGccCfgFileL()
      ENDIF

   ENDIF

RETURN .T.

*----------------------------
FUNCTION Checkdefine( cTemp )
*----------------------------

   LOCAL cDef
   LOCAL nPos
   LOCAL cRead
   LOCAL aSet     := {}
   LOCAL nMakePos

   IF cTemp == "!endif"
      RETURN NIL
   ENDIF

   cTemp := Trim( Substr( ReadLN( @s_lEof ), 1 ) )
   cTemp := Strtran( cTemp, "!ifndef ", "" )
   cTemp := Strtran( cTemp, "\..", "" )
   cTemp := Strtran( cTemp, "/..", "" )

   IF  "\.." IN  cTemp
      cTemp := Substr( cTemp, 1, At( "\..", cTemp ) - 1 )
   ELSEIF  "/.." IN  cTemp
      cTemp := Substr( cTemp, 1, At( "/..", cTemp ) - 1 )
   ENDIF

   aSet := ListAsArray2( cTemp, "=" )
   nPos := AScan( s_aDefines, { | x | x[ 1 ] == aSet[ 1 ] } )

   IF nPos = 0
      cRead    := Alltrim( Strtran( aSet[ 2 ], "$(", "" ) )
      cRead    := Strtran( cRead, ")", "" )
      nMakePos := AScan( s_aDefines, { | x | x[ 1 ] == cRead } )

      IF nMakePos > 0
         AAdd( s_aDefines, { aSet[ 1 ], s_aDefines[ nMakePos, 2 ] } )
         AAdd( s_aMacros, { aSet[ 1 ], s_aDefines[ nMakePos, 2 ] } )
      ENDIF

   ENDIF

RETURN NIL

*----------------------------
FUNCTION Setcommands( cTemp )
*----------------------------

   LOCAL cRead        := Alltrim( readln( @s_lEof ) )
   LOCAL nPos
   LOCAL nCount       := 0
   LOCAL aTempMacros  := {}
   LOCAL aLocalMacros := {}

   aTempMacros := ListAsArray2( cREad, " " )

   AEval( aTempMacros, { | xMacro | IIF( At( "$", xMacro ) > 0, ;
                         IIF( At( ";", xMacro ) > 0, ( aLocalMacros := ListAsArray2( xMacro, ";" ), ;
                         AEval( aLocalMacros, { | x | Findmacro( x, @cRead ) } ) ), ;
                         Findmacro( xMacro, @cRead ) ), ) } )
   AAdd( s_aCommands, { cTemp, cRead } )

RETURN NIL

#IfDef HBM_USE_DEPENDS

*--------------------------------
FUNCTION SetDependencies( cTemp )
*--------------------------------

   LOCAL nPos
   LOCAL nCount       := 0
   LOCAL aTempMacros  := {}
   LOCAL aLocalMacros := {}
   LOCAL cTmp         := ""

   aTempMacros := ListAsArray2( ReplaceMacros(cTemp), " " )

   IF Len( aTempMacros ) > 1
      cTmp := aTempMacros[ 1 ]
      IF Right(cTmp,1) == ":"
         cTmp := Left(cTmp,Len(cTmp) - 1)
      ENDIF
      aTempMacros := ADel( aTempMacros , 1)
      ASize(aTempMacros,Len(aTempMacros) - 1)
      AAdd( s_aDepends, { cTmp, AClone( aTempMacros ) } )
   ENDIF

RETURN NIL
#Endif

*----------------------------------
FUNCTION Findmacro( cMacro, cRead )
*----------------------------------

   LOCAL nPos
   LOCAL cTemp
   LOCAL aLocalMacros := {}

   cMacro := Substr( cMacro, 1, At( ")", cMacro ) )

   IF  "-" IN cMacro
      cMacro := Substr( cMacro, 3 )
   ENDIF

   IF  ";" IN cMacro
      cMacro := Substr( cMacro, At( ";", cMacro ) + 1 )
   ENDIF

   nPos := AScan( s_aMacros, { | x | "$(" + Alltrim( x[ 1 ] ) + ")" == cMacro } )

   IF nPos = 0
      cTemp := Strtran( cmacro, "$(", "" )
      cTemp := Strtran( cTemp, ")", "" )

      IF ! Empty( cTemp )
         cRead := Alltrim( Strtran( cRead, cmacro, Gete( cTemp ) ) )
      ENDIF

   ELSE
      cRead := Alltrim( Strtran( cRead, cmacro, s_aMacros[ npos, 2 ] ) )
   ENDIF

RETURN cRead

*--------------------------------
FUNCTION ReplaceMacros( cMacros )
*--------------------------------

   LOCAL nPos
   LOCAL nCount       := 0
   LOCAL aTempMacros  := {}
   LOCAL aLocalMacros := {}
   Local cLibPath := ""
   Local cLibPath1 := ""
   Local cLibPath2:= ""

   IF "/LIBPATH2:" In cMAcros
         cLibPath2 := "/LIBPATH2:"
         cMacros :=strTRan(cMacros,cLibPath2,"cccccccccc ")
   endif

   IF "/LIBPATH1:" In cMAcros
         cLibPath1 := "/LIBPATH1:"
         cMacros :=strTRan(cMacros,cLibPath1,"bbbbbbbbbb ")
   endif

   IF "/LIBPATH:" In cMAcros
         cLibPath := "/LIBPATH:"
         cMacros :=strTRan(cMacros,cLibPath,"aaaaaaaaaa ")
   endif
   aTempMacros := ListAsArray2( cMacros, " " )
   AEval( aTempMacros, { | xMacro | IIF(  "$" IN xMacro , ;
                         IIF(  ";" IN xMacro , ( aLocalMacros := ListAsArray2( xMacro, ";" ), ;
                         AEval( aLocalMacros, { | x | Findmacro( x, @cMacros ) } ) ), ;
                         Findmacro( xMacro, @cMacros ) ), ) } )

  if !empty(cLibPath)
     cMacros:=strtran(cMacros,"aaaaaaaaaa ","/LIBPATH:")

     cMacros:=strtran(cMacros,"bbbbbbbbbb ","/LIBPATH:")

     cMacros:=strtran(cMacros,"cccccccccc ","/LIBPATH:")

  endif
RETURN cmacros

*------------------
FUNCTION SetBuild()
*------------------

   LOCAL cRead
   LOCAL nPos
   LOCAL aMacro
   LOCAL aTemp
   LOCAL nCount
   LOCAL cCurrentRead := ''
   LOCAL cMacro
   Local xInfo
   local xItem

   cRead     := Alltrim( readln( @s_lEof ) )
   s_szProject := cRead
   aMacro    := ListAsArray2( cRead, ":" )

   IF Len( aMacro ) > 1
      aTemp := ListAsArray2( aMacro[ 2 ], " " )
      AEval( aTemp, { | xItem | AAdd( s_aBuildOrder, xItem ) } )
   ENDIF

   AAdd( s_aBuildOrder, aMacro[ 1 ] )
   cRead := Strtran( cRead, "@&&!", "" )

   aMacro := ListAsArray2( cRead, '\' )

   AEval( aMacro, { | xMacro |  IIF(  "$" IN xmacro , Findmacro( xMacro, @cRead ), ) } )

   IF ! s_lLinux .and. !s_lmingw
      s_cLinkCommands   := cRead + "  @" + s_cMakeFileName
      s_nMakeFileHandle := FCreate( s_cMakeFileName )

      if s_nMakeFileHandle = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := "<"+s_cMakeFileName + "> n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := "<"+s_cMakeFileName + "> no pode ser criado."
         ELSE                // english
            s_cAlertMsg := "<"+s_cMakeFileName + "> cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

   ELSE
      s_cLinkCommands := cRead + " "
   ENDIF

   FOR nPos := 1 TO 7

      cRead        := Alltrim( readln( @s_lEof ) )
      cCurrentRead := cRead

      aMacro       := ListAsArray2( cRead, " " )

        FOR EACH cMacro IN aMacro

         IF  "$" IN  cMacro
            Findmacro( cMacro , @cRead )

            IF At( '$(PROJECT)', cCurrentRead ) > 0

               IF ! s_lGcc

                  IF ! s_lLinux
                     if s_lMsVcc
                        cRead := strtran(cRead,",","")
                        cRead := strtran(cRead,"+","")
                        xInfo := " -out:"
                        xInfo += cRead
                        cREad :=xInfo
                     endif
                     FWrite( s_nMakeFileHandle, cRead + CRLF )
                  ENDIF

               ELSEIF s_lGcc .AND. s_lLinux .or. ( s_lGcc .AND. s_lMingw)
                  s_cLinkCommands += "-o " + cRead + " "
               ELSEIF s_lGcc .AND. ! s_lLinux .AND. At( '.exe', cread ) > 0
                  FWrite( s_nMakeFileHandle, "-o " + cRead + CRLF )
               ENDIF

            ELSE

               IF ! s_lLinux  
                  if s_lMsVcc
                  
                  
                     cRead := strtran(cRead,",","")
                     cRead := strtran(cRead,"+","")
//                     cRead := strtran(cRead," ", '"' +CRLF+'"')
                      aTemp := ListAsArray2( cRead, " " )
                      cRead :=""
                      for each xItem in aTemp
                         cRead +=xItem+CRLF
                      NEXT
                      cRead := substr(cRead,1,rat(CRLF,cRead)-1)
                     
                  endif
                  if s_lMingw
                     s_cLinkCommands += cRead + " "
                  else
                  FWrite( s_nMakeFileHandle, cRead + CRLF )
                  endif
                  
               ELSE
                  s_cLinkCommands += cRead + " "
               ENDIF

            ENDIF

         ENDIF

      NEXT

   NEXT

   //IF !s_lLinux .and. s_lMingw
   IF s_lWin32 .or. s_lOS2 .or. s_lMingw
      FClose( s_nMakeFileHandle )
   ENDIF

   if s_lMsVcc
      s_cLinkCommands +=" /nologo " + IIF( s_lGui, "/SUBSYSTEM:WINDOWS"," /SUBSYSTEM:CONSOLE") + " /force:multiple "
   endif

   qqout( HbMake_Id() )
   qout( HbMake_Copyright() )

   if s_lBcc
      qout( version() )
   else
      qout(s_cLinkCommands)
   endif

RETURN NIL

*----------------------
FUNCTION CompileFiles()
*----------------------

   LOCAL cComm
   LOCAL cOld
   LOCAL nPos
   LOCAL nCount
   LOCAL nFiles
   LOCAL cErrText := ""
   LOCAL aOrder   := ListAsArray2( s_aBuildOrder[ 2 ], " " )
   LOCAL lEnd     := .F.
   LOCAL xItem
   LOCAL lLinux   :=  s_lLinux
   LOCAL cPrg     := ''
   LOCAL cOrder   := ""
   LOCAL nFile    := 1
   LOCAL aGauge   := GaugeNew( 5, 5, 7, 40, "W/B", "W+/B", '�' )


   @  4,  5 SAY "Compiling :"

   FOR EACH cOrder in aOrder

      IF ! s_lExtended

         IF cOrder == "$(CFILES)"
            nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.c:" } )

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".PRG.C:" } )

               IF nPos > 0
                  cComm := s_aCommands[ nPos, 2 ]
                  cOld  := cComm
               ENDIF

            ENDIF

            FOR EACH cPrg in s_aPrgs

               xItem := Substr( cPrg, Rat( IIF( s_lGcc, '/', '\' ), ;
                                cPrg ) + 1 )
               nPos := AScan( s_aCs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), ;
                  Left( x, At( ".", x ) ) == Left( xItem, At( ".", xItem ) ) } )

               IF nPos > 0
                  if s_lMSVcc .or. s_lPcc
                     cComm := Strtran( cComm, "-Fo$*", "/Fo" + s_aCs[ nPos ] )
                  else
                     cComm := Strtran( cComm, "o$*", "o" + s_aCs[ nPos ] )
                  endif
                  cComm := Strtran( cComm, "$**", cPrg )
                  cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))
                  Outstd( cComm )
                  Outstd( Hb_OsNewLine() )
                  setpos(9,0)
                  __RUN( (cComm) )
                  cErrText := Memoread( (s_cLog) )
                  lEnd     := 'C2006' $ cErrText .OR. 'No code generated' $ cErrText

                  IF ! s_lIgnoreErrors .AND. lEnd
                     IIF(  s_lLinux, __run( "mcedit " +(s_cLog) ), __run( "Notepad " + (s_cLog) ) )
                     set cursor on
                     QUIT
                  ELSE
                     // Ferase( s_cLog )
                  ENDIF

                  cComm := cOld

               ENDIF

            NEXT

         ENDIF

         IF cOrder == "$(OBJFILES)"

            IF s_lGcc
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.o:" .OR. x[ 1 ] == ".cpp.o:" } )
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.obj:" .OR. x[ 1 ] == ".cpp.obj:" } )
            ENDIF

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE

               IF s_lGcc
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".C.O:" } )

                  IF nPos > 0
                     cComm := s_aCommands[ nPos, 2 ]
                     cOld  := cComm
                  ENDIF

               ELSE
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".C.OBJ:" } )

                  IF nPos > 0
                     cComm := s_aCommands[ nPos, 2 ]
                     cOld  := cComm
                  ENDIF

               ENDIF

            ENDIF

            FOR nFiles := 1 TO Len( s_aCs )

               xItem := Substr( s_aCs[ nFiles ], Rat( IIF( s_lGcc, '/', '\' ), ;
                                s_aCs[ nFiles ] ) + 1 )
               nPos := AScan( s_aObjs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), ;
                  Left( x, At( ".", x ) ) == Left( xItem, At( ".", xItem ) ) } )

               IF nPos > 0

                  IF llinux
                     cComm := Strtran( cComm, "o$*", "o" + s_aObjs[ nPos ] )
                  ELSE
                      if s_lMSVcc .or. s_lPcc
                         cComm := Strtran( cComm, "-Fo$*", "/Fo" + Strtran( s_aObjs[ nPos ], '/', '\' ) )
                      else
                         cComm := Strtran( cComm, "o$*", "o" + Strtran( s_aObjs[ nPos ], '/', '\' ) )
                      endif
                  ENDIF

                  cComm := Strtran( cComm, "$**", s_aCs[ nFiles ] )
                  cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))
                  Outstd( " " )
                  Outstd( cComm )
                  Outstd( Hb_OsNewLine() )
                  setpos(9,0)
                  __RUN( (cComm) )
                  cComm := cOld
               ENDIF

            NEXT

         ENDIF

      ELSE /****** Extended mode *****/

         IF cOrder == "$(CFILES)"

            IF s_lGcc
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.o:" .OR. x[ 1 ] == ".cpp.o:" } )
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.obj:" .OR. x[ 1 ] == ".cpp.obj:" } )
            ENDIF

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".C.OBJ:" } )

               IF nPos > 0
                  cComm := s_aCommands[ nPos, 2 ]
                  cOld  := cComm
               ENDIF

            ENDIF

            IF Len( s_aCs ) > 0
               GaugeDisplay( aGauge )
               nFile := 1

               FOR nFiles := 1 TO Len( s_aCs )
                  @  4, 16 SAY Space( 50 )
                  xItem := Substr( s_aCs[ nFiles ], Rat( IIF( s_lGcc, '/', '\' ), ;
                                   s_aCs[ nFiles ] ) + 1 )
                  nPos := AScan( s_aObjsc, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), ;
                     Left( x, At( ".", x ) ) == Left( xitem, At( ".", xitem ) ) } )

                  IF nPos > 0

                     IF llinux
                        cComm := Strtran( cComm, "o$*", "o" + s_aObjsc[ nPos ] )
                     ELSE
                        if s_lMSVcc .or. s_lPcc
                           cComm := Strtran( cComm, "-Fo$*", "/Fo" + Strtran( s_aObjsc[ nPos ], '/', '\' ) )
                        else
                           cComm := Strtran( cComm, "o$*", "o" + Strtran( s_aObjsc[ nPos ], '/', '\' ) )
                        endif
                     ENDIF

                     cComm := Strtran( cComm, "$**", s_aCs[ nFiles ] )

                     cComm += IIF( s_lLinux ,  " "," >>"+ (s_cLog))

                     @  4, 16 SAY s_aCs[ nFiles ]
                     GaugeUpdate( aGauge, nFile / Len( s_aCs ) )   // Changed s_aPrgs to s_aCs, Ath 2004-06-08
                     nFile ++
                     //Outstd( cComm )
                     setpos(9,0)
                     __RUN( (cComm) )
                     cErrText := Memoread( (s_cLog) )
                     lEnd     := 'Error E' $   cErrText
                     IF ! s_lIgnoreErrors .AND. lEnd
                        IIF(  s_lLinux, __run( "mcedit " + (s_cLog) ), __run( "Notepad " + (s_cLog)) )
                        set cursor on
                        QUIT
                     ELSE
                        // FErase( s_cLog )
                      ENDIF
                     lEnd     := 'Error F' $   cErrText

                     cComm := cOld

                  ENDIF

               NEXT

            ENDIF

         ENDIF

         IF cOrder == "$(OBJFILES)"

            IF s_lGcc
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.o:" } )
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.obj:" } )
            ENDIF

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE

               IF s_lGcc
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".PRG.O:" } )
               ELSE
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".PRG.OBJ:" } )
               ENDIF

            ENDIF

            GaugeDisplay( aGauge )
            nFile := 1

            FOR EACH cPrg In s_aPrgs

               @  4, 16 SAY Space( 50 )
               xItem := Substr( cPrg, Rat( IIF( s_lGcc, '/', '\' ), ;
                                cPrg ) + 1 )
               nPos := AScan( s_aObjs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), ;
                  Left( x, At( ".", x ) ) == Left( xItem, At( ".", xitem ) ) } )

               IF nPos > 0

                  IF llinux
                     cComm := Strtran( cComm, "o$*", "o" + s_aObjs[ nPos ] )
                  ELSE
//                     if s_lMSVcc .or. s_lPcc
  //                      cComm := Strtran( cComm, "-Fo$*", "/Fo" + Strtran( s_aObjs[ nPos ], '/', '\' ) )
    //                 else
                        cComm := Strtran( cComm, "o$*", "o" + Strtran( s_aObjs[ nPos ], '/', '\' ) )
      //               endif
                  ENDIF

                  cComm := Strtran( cComm, "$**", cPrg )
                  cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))

                  @  4, 16 SAY cPrg
                  GaugeUpdate( aGauge, nFile / Len( s_aPrgs ) )
                  // Outstd( Hb_OsNewLine() )
                  nFile ++
                  setpos(9,0)
                  __RUN( (cComm) )
                  cErrText := Memoread( (s_cLog) )
                  lEnd     := 'C2006' $ cErrText .OR. 'No code generated' $ cErrText .or. "Error E" $ cErrText .or. "Error F" $ cErrText

                  IF ! s_lIgnoreErrors .AND. lEnd
                     IIF(  s_lLinux, __run( "mcedit " + (s_cLog) ), __run( "Notepad " + (s_cLog)) )
                     set cursor on
                     QUIT
                  ELSE
                     //FErase( s_cLog )
                  ENDIF

                  cComm := cOld

               ENDIF

            NEXT

         ENDIF

      ENDIF

      IF cOrder == "$(RESDEPEN)"
         nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".rc.res:" } )

         IF nPos > 0
            cComm := s_aCommands[ nPos, 2 ]
            cOld  := cComm
         ENDIF

         FOR nFiles := 1 TO Len( s_aResources )

            IF ! Empty( s_aResources[ nFiles ] )
               cComm := Strtran( cComm, "$<", s_aResources[ nFiles ] )
               outstd( " " )
               ? cComm
               setpos(9,0)
               __RUN( (cComm) )
            ENDIF

            cComm := cOld

         NEXT

      ENDIF

   NEXT

RETURN NIL

*-------------------------------
FUNCTION GetParaDefines( cTemp )
*-------------------------------

   LOCAL nPos
   LOCAL cRead
   LOCAL aSet     := {}
   LOCAL nMakePos

   IF  "\.." IN cTemp
      cTemp := Substr( cTemp, 1, At( "\..", cTemp ) - 1 )
   ELSEIF  "/.." IN cTemp
      cTemp := Substr( cTemp, 1, At( "/..", cTemp ) - 1 )
   ENDIF

   aSet := ListAsArray2( cTemp, "=" )
   nPos := AScan( s_aDefines, { | x | x[ 1 ] == aSet[ 1 ] } )

   IF nPos == 0
      cRead    := Alltrim( Strtran( aSet[ 2 ], "$(", "" ) )
      cRead    := Strtran( cRead, ")", "" )
      nMakePos := AScan( s_aDefines, { | x | x[ 1 ] == cRead } )

      IF nMakePos = 0
         ASet[ 2 ] := Strtran( aSet[ 2 ], ",", " " )
         AAdd( s_aDefines, { aSet[ 1 ], aSet[ 2 ] } )
         AAdd( s_aMacros, { aSet[ 1 ], aSet[ 2 ] } )
      ENDIF

   ENDIF

RETURN NIL

*---------------------
FUNCTION PrintMacros()
*---------------------

   LOCAL nPos

   Outstd( HbMake_Id()+ " "+HbMake_Copyright()+ CRLF )
   Outstd( "" + CRLF )
   Outstd( "Macros:" + CRLF )
   AEval( s_aMacros, { | xItem | Outstd( "     " + xItem[ 1 ] + " = " + xItem[ 2 ] + CRLF ) } )
   Outstd( "Implicit Rules:" + CRLF )
   AEval( s_aCommands, { | xItem | Outstd( "     " + xItem[ 1 ] + Hb_OsNewLine() + "        " + xItem[ 2 ] + CRLF ) } )
   Outstd( "" + CRLF )
   Outstd( "Targets:" )
   Outstd( "    " + s_szProject + ":" + CRLF )
   Outstd( "        " + "Flags :" + CRLF )
   Outstd( "        " + "Dependents :" )
   AEval( s_aCs, { | xItem | Outstd( xitem + " " ) } )
   AEval( s_aObjs, { | xItem | Outstd( xitem + " " ) } )
   Outstd( " " + CRLF )
   Outstd( "        commands:" + s_aBuildOrder[ Len( s_aBuildOrder ) ] )
   Outstd( " " + CRLF )
   Outstd( " " + CRLF )
   Outstd( " " + CRLF )

RETURN NIL

*-------------------------------
FUNCTION CreateMakeFile( cFile )
*-------------------------------

   LOCAL aInFiles     := {}
   LOCAL aOutFiles    := {}
   LOCAL aOutc        := {}
   LOCAL aSrc         := Directory( "*.prg" )
   LOCAL nLenaSrc     := Len( aSrc )

   LOCAL lFwh         := .F.
// LOCAL lxFwh        := .F. 
   LOCAL lC4W         := .F. 
   LOCAL lMiniGui     := .F.
   LOCAL lHwGui       := .F.
   LOCAL lWhoo        := .F.
   LOCAL lWhat32      := .F.
   LOCAL lGtWvt       := .F.
   LOCAL lGtWvw       := .F.
   LOCAL lXwt         := .F.
   LOCAL lxHGtk       := .F.

   LOCAL lRddAds      := .F.
   LOCAL lMediator    := .F.
   LOCAL lApollo      := .F.

// LOCAL lMt          := .F.
   LOCAL cOS          := IIF( s_lLinux, "Linux", iif(s_lOS2,"OS/2","Win32") )
   LOCAL cCompiler    := IIF( s_lLinux .OR. s_lGcc, "GCC",iif(s_lPcc,"POCC",iif(s_lMSVcc,"MSVC","BCC")))

   // External GUI Libs
   LOCAL cFwhPath     := Space( 200 )
   LOCAL cC4WPath     := Space( 200 )
   LOCAL cMiniPath    := Space( 200 )
   LOCAL cHwPath      := Space( 200 )
   LOCAL cxHGPath     := Space( 200 )

   LOCAL cMedPath     := Space( 200 )
   LOCAL cApolloPath  := Space( 200 )

   LOCAL cObjDir      := s_cObjDir + space( 20 )
   LOCAL lAutoMemvar  := .F.
   LOCAL lVarIsMemvar := .F.
   LOCAL lDebug       := .F.
   LOCAL lSupressLine := .F.
   LOCAL nPos
   LOCAL cHarbourFlags  := ""

// LOCAL nWarningLevel :=0

   LOCAL lUseXharbourDll := .F.

   LOCAL lCompMod         := .F.

//   LOCAL lGenppo          := .F.
   LOCAL x
   LOCAL getlist          := {}
   LOCAL cTopFile         := Space( 50 )
   LOCAL cAppName         := s_Appname + Space( 50 )
   LOCAL cDefBccLibs      := "bcc640.lib lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib dbfdbt.lib common.lib gtwin.lib codepage.lib ct.lib tip.lib pcrepos.lib"
   LOCAL cDefGccLibs      := "-lvm -lrtl -lpcrepos -lgtdos -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbffpt -ldbfdbt -lcommon -lcodepage  -lm "
   LOCAL cDefGccLibsw     := "-lvm -lrtl -lpcrepos -lgtwin -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbffpt -ldbfdbt -lcommon -lcodepage -lm"
   LOCAL cGccLibsOs2      := "-lvm -lrtl -lpcrepos -lgtos2 -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbffpt -ldbfdbt -lcommon -lcodepage -lm"
   LOCAL cDefLibGccLibs   := "-lvm -lrtl -lpcrepos -lgtcrs -llang -lrdd -lrtl -lvm -lmacro -lpp -ldbfntx -ldbfcdx -ldbffpt -ldbfdbt -lcommon -lcodepage -lgtnul"
   LOCAL cDefBccLibsMt    := "bcc640mt.lib lang.lib vmmt.lib rtlmt.lib rddmt.lib macromt.lib ppmt.lib dbfntxmt.lib dbfcdxmt.lib  dbffptmt.lib dbfdbtmt.lib common.lib gtwin.lib codepage.lib ctmt.lib tipmt.lib pcrepos"
   LOCAL cDefGccLibsMt    := "-lvmmt -lrtlmt -lpcrepos -lgtdos -llang -lrddmt -lrtlmt -lvmmt -lmacromt -lppmt -ldbfntxmt -ldbfcdxmt -ldbffptmt -ldbfdbtmt -lcommon -lcodepage -lm"
   LOCAL cDefGccLibsMtw    := "-lvmmt -lrtlmt -lpcrepos -lgtwin -llang -lrddmt -lrtlmt -lvmmt -lmacromt -lppmt -ldbfntxmt -ldbfcdxmt -ldbffptmt -ldbfdbtmt -lcommon -lcodepage -lm"
   LOCAL cGccLibsOs2Mt    := "-lvmmt -lrtlmt -lpcrepos -lgtos2 -llang -lrddmt -lrtlmt -lvmmt -lmacromt -lppmt -ldbfntxmt -ldbfcdxmt -ldbffptmt -ldbfdbtmt -lcommon -lcodepage -lm"
   LOCAL cDefLibGccLibsMt := "-lvmmt -lrtlmt -lpcrepos -lgtcrs -llang -lrddmt -lrtlmt -lvmmt -lmacromt -lppmt -ldbfntxmt -ldbfcdxmt -ldbffptmt -ldbfdbtmt -lcommon -lcodepage"
   LOCAL cHarbDll         := "bcc640.lib harbour.lib"
   LOCAL cHARso           := "-lxharbour -lncurses -lgpm -lslang -lpthread -lm"
   LOCAL cSystemLibs      := "-lncurses -lslang -lgpm -lpthread -lm"

   LOCAL cLibs        := ""
   LOCAL citem        := ""
   LOCAL cExt         := ""
   LOCAL cDrive       := ""
   LOCAL cPath        := ""
   LOCAL cTest        := ""
   LOCAL cGuiLib      := "None"
   LOCAL aLibs
   LOCAL aLibsIn      := {}
   LOCAL aLibsOut     := {}
   LOCAL cGt          := ""

   LOCAL cOldLib      := ""
   LOCAL cHtmlLib     := ""
   LOCAL lLinux       := s_lLinux
   LOCAL nWriteFiles  := 0
   LOCAL cResName     := space(200)
   LOCAL aSelFiles

   LOCAL cBuild       := " "
   LOCAL cBuildForced := " "
   LOCAL cBuildParam  := NIL 

   LOCAL aUserDefs
   LOCAL cCurrentDef  := ""
   LOCAL cRdd         := "None"
   LOCAL cCurrentDir  := ""
   LOCAL nOption      
   LOCAL lNew         := .F.
   LOCAL oMake
   LOCAL cAllRes      := ""
   LOCAL cTemp
   LOCAL cExtraLibs   :=""
   LOCAL cTempLibs    := ""
   LOCAL aTempLibs

   #IFdef HBM_USE_DEPENDS
      LOCAL cIncl              := ""
      LOCAL lScanIncludes      := .F.
      // Provisions for recursive scanning
      LOCAL lScanIncRecursive := .F.
      LOCAL cExcludeExts       := PadR(".ch",40)
   #ENDIF

   #ifndef __PLATFORM__Windows
       LOCAL lHashhso := File("/usr/lib/libxharbour.so")
       LOCAL lusexhb := FILE("/usr/bin/xhb-build")
   #ELSE
       LOCAL lusexhb := .F.
   #ENDIF

   LOCAL cHarbourLibDir := GetHarbourDir()+iif(s_lLinux,"/lib","\lib")
   LOCAL lCancelMake := .F.


   s_cUserInclude  := space(200)
   s_cUserDefine   := space(200)


   IF File( cFile )

      CLS

      IF s_nLang == 1 // Portuguese-BR
         nOption := Alert( "O makefile <" + cFile +"> j� existe.",{ "Editar", "Criar Novo" , "Cancelar" } )
      ELSEIF s_nLang == 3 // Spanish
         nOption := Alert( "Lo makefile <" + cFile +"> ya existe.",{ "Editar", "Crear Nuevo" , "Cancelar" } )
      ELSE // English
         nOption := Alert( "The makefile <" + cFile +"> already exist ",{ "Edit" , "Create New" , "Cancel" } )
      ENDIF


      IF nOption = 1 // edit makefile

         // Verify if "cFile" can be openned to write mode.

         s_nMakeFileHandle := FOpen( cFile, FO_WRITE )

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser aberto para edi��o."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser abierto para edici�n."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be openned for edition."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+LTrim(Str(FError()))+")" )

            RETURN NIL
         else
            FClose( s_nMakeFileHandle )
         endif

         oMake :=ThbMake():new()
         oMake:cMakefile:=cFile
         oMake:ReadMakefile(cFile)
         FRename(cFile,cFile+".old")

         IF LEN(oMake:aRes) >0
            FOR EACH cTemp IN oMake:aRes
                cAllRes += cTemp+ " "
            NEXT
         ENDIF

         lAutoMemVar     := oMake:lAutomemvar
         lVarIsMemVar    := oMake:lvarismemvar
         lDebug          := oMake:ldebug
         lSupressline    := oMake:lSupressline
         lCompMod        := oMake:lCompMod
         s_lGenppo       := oMake:lGenppo
         s_lGui          := oMake:lGui 
         cRdd            := IIF( oMake:lRddAds, "RddAds", IIF( oMake:lMediator, "Mediator", "None" ) )
         cGuiLib         := IIF( oMake:lFwh   , "FWH", ;
                            IIF( oMake:lMini  , "MINIGUI", ;
                            IIF( oMake:lWhoo  , "WHOO", ;
                            IIF( oMake:lCw    , "C4W", ;
                            IIF( oMake:lHwGui , "HWGUI", ;
                            IIF( oMake:lGtWvt , "GTWVT", ;
                            IIF( oMake:lGtWvw , "GTWVW", ;
                            IIF( oMake:lXWt   , "XWT", ;
                            IIF( oMake:lWhat32, "WHAT32", ;
                            IIF( oMake:lxHGtk , "XHGTK", "" ) ) ) ) ) ) ) ) ) )
         cFwhpath        := padr(oMake:cFmc,200)
         cApolloPath     := padr(oMake:cFmc,200)
         cC4WPath        := padr(oMake:cFmc,200)
         cMiniPath       := padr(oMake:cFmc,200)
         cHwPath         := padr(oMake:cFmc,200)
         cxHGPath        := padr(oMake:cFmc,200)
         cMedpath        := padr(oMake:cMedpath,200)
         cAppName        := PadR(oMake:cAppLibName,20," ")
         s_cAppName      := oMake:cAppLibName
         s_lCompress     := oMake:lCompress
         s_lExternalLib  := oMake:lExternalLib
         s_cUserInclude  := PadR(oMake:cUserInclude,200," ")
         s_cUserDefine   := PadR(oMake:cUserDef,200," ")
         s_lxFwh         := oMake:lxFwh
         s_nFilesToAdd   := oMake:cFilesToAdd
         s_lMt           := oMake:lMt
         s_nWarningLevel := oMake:cWarningLevel
         cTopFile        := PadR(oMake:cTopModule,50," ")
         cResName        := PadR(oMake:cRes,200)
         s_cObjDir       := oMake:cObj
         cObjDir         := s_cObjDir + space(20)

         if !s_lRecursive
            s_lRecursive := oMake:lRecurse
         endif


         IF nLenaSrc == 0 .and. !s_lRecursive 

            CLS

            IF s_nLang=1 // PT-BR
               s_cAlertMsg := "N�o h� nenhum prg na pasta "+CurDir()+". Use o modo recursivo -r" 
            ELSEIF s_nLang=3 // Spanish
               s_cAlertMsg := "No hay ning�n prg en la carpeta "+CurDir()+". Use lo modo recursivo -r"
            ELSE
               s_cAlertMsg := "Does not have any prg in "+CurDir()+" folder. Use the recursive mode -r"
            ENDIF

            Alert( s_cAlertMsg )

            SetColor("W/N,N/W")
            CLS
            set cursor on
            QUIT

         ENDIF

         if s_lCancelRecursive
            s_lRecursive := .F.
         endif

         // after oMake read, recreate other clean makefile to edit.
         s_nMakeFileHandle := FCreate(cFile)

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser aberto para edi��o."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser abierto para edici�n."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be openned for edition."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

            RETURN NIL

         endif

         WriteMakeFileHeader()

         s_lEditMake := .T.


      ELSEIF nOption = 2 // create a new makefile


         IF nLenaSrc == 0 .and. !s_lRecursive 

            CLS

            IF s_nLang=1 // PT-BR
               s_cAlertMsg := "N�o h� nenhum prg na pasta "+CurDir()+". Use o modo recursivo -r" 
            ELSEIF s_nLang=3 // Spanish
               s_cAlertMsg := "No hay ning�n prg en la carpeta "+CurDir()+". Use lo modo recursivo -r"
            ELSE
               s_cAlertMsg := "Does not have any prg in "+CurDir()+" folder. Use the recursive mode -r"
            ENDIF

            Alert( s_cAlertMsg )
            SetColor("W/N,N/W")
            CLS
            set cursor on
            QUIT

         ENDIF

         s_lEditMake := .F.

         s_nMakeFileHandle := FCreate( cFile )

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser criado."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser criado."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be created."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

            RETURN NIL

         endif


         WriteMakeFileHeader()
         lNew := .T.

      ELSE
         SetColor("W/N,N/W")
         CLS
         set cursor on
         QUIT
      ENDIF

   ELSE

      s_nMakeFileHandle := FCreate( cFile )

      if s_nMakeFileHandle = F_ERROR

         CLS

         IF s_nLang = 1      // brazilian portuguese
            s_cAlertMsg := "<"+cFile + "> n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := "<"+cFile + "> no pode ser criado."
         ELSE                // english
            s_cAlertMsg := "<"+cFile + "> cannot be created."
         ENDIF

         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

         RETURN NIL

      ENDIF

      WriteMakeFileHeader()
      nOption := 2  // create a new makefile
      lNew := .T.

   ENDIF

   CLS
   Setcolor( 'w/b+,b+/w,w+/b,w/b+,w/b,w+/b' )
   @  0,  0, Maxrow(), Maxcol() BOX( Chr( 201 ) + Chr( 205 ) + Chr( 187 ) + Chr( 186 ) + Chr( 188 ) + Chr( 205 ) + Chr( 200 ) + Chr( 186 ) + Space( 1 ) )

   Attention( HbMake_Id() + space(10)+s_aLangMessages[ 27 ], 0 )
//   Attention( s_aLangMessages[ 27 ], 0 )
   Attention( s_aLangMessages[ 47 ], maxrow() )
   @ 01,01       say s_aLangMessages[ 28 ]
   @ 01,16,06,21 get cOS listbox { "Win32", "OS/2", "Linux" } message s_aLangMessages[ 49 ] state OsSpec(getlist,1,@cOS)  DROPDOWN
   @ 01,23       say s_aLangMessages[ 29 ]
// POCC configuration still not ready.
//   @ 01,47,06,52 get cCompiler LISTBOX { "BCC", "MSVC", "GCC", "POCC" } MESSAGE s_aLangMessages[ 50 ] STATE OsSpec(getlist,2,@cCompiler) DROPDOWN
   @ 01,47,06,54 get cCompiler LISTBOX { "BCC", "MSVC", "GCC","MINGW" } MESSAGE s_aLangMessages[ 50 ] STATE OsSpec(getlist,2,@cCompiler) DROPDOWN
   @ 01,56       say s_aLangMessages[ 30 ]
   @ 01,67,10,78 get cGuiLib ListBox { "None","C4W","FWH","GTWVT","GTWVW","HWGUI","MINIGUI","XWT","WHAT32","WHOO","XHGTK"} state OsSpec(getlist,3,@cGuiLib) DROPDOWN  When CheckCompiler(cOS) message s_aLangMessages[ 51 ]
   @ 02,01       say s_aLangMessages[ 48 ]
   @ 02,16,08,26 get cRdd ListBox { "None","RddAds","Mediator","Apollo"}  WHEN cOS == "Win32" .or. cOS == "Linux" DROPDOWN message s_aLangMessages[ 52 ]
   @ 02,30       get s_lCompress CheckBox  caption s_aLangMessages[ 53 ] style "[X ]" message s_aLangMessages[ 54 ]
   @ 02,53       get lUseXharbourDll CheckBox caption "use xHarbour[.dll|.so]" style "[X ]" WHEN cOS == "Win32" .or. cOS == "Linux" message s_aLangMessages[ 55 ]
   @ 03,01       say "Obj Files Dir" GET cObjDir PICT "@s20" message s_aLangMessages[ 56 ]
   @ 04,01       say s_aLangMessages[ 45 ] GET cAppName  pict "@s15"valid !Empty( cAppName ) message s_aLangMessages[ 57 ]
   @ 04,53       get s_lasdll CheckBox  Caption "Create dll" style "[X ]"

   READ MSG AT MaxRow() - 1, 1, MaxCol() - 1

   s_cAppName := alltrim( cAppName )

   IF cOS != "Linux"
      if s_lasdll
         s_cAppName += ".dll"
      else
         s_cAppName += ".exe"
      endif
   ENDIF

   if s_lasdll
      lUseXharbourDll:= .T.
   endif

   lFwh      := "FWH"      IN alltrim(cGuiLib)
   lC4W      := "C4W"      IN alltrim(cGuiLib)
   lMiniGui  := "MINIGUI"  IN alltrim(cGuiLib)
   lHwGui    := "HWGUI"    IN alltrim(cGuiLib)
   lWhoo     := "WHOO"     IN alltrim(cGuiLib)
   lWhat32   := "WHAT32"   IN alltrim(cGuiLib)
   lGtWvt    := "GTWVT"    IN alltrim(cGuiLib)
   lGtWvw    := "GTWVW"    IN alltrim(cGuiLib)   
   lXwt      := "XWT"      IN alltrim(cGuiLib)
   lxHGtk    := "XHGTK"    IN alltrim(cGuiLib)
   s_lGui := lWhoo .or. lFwh .or. lC4W .or. lMinigui .or. lGtWvt .or. lHwGui .or. lXwt .or. lWhat32 .or. lxHGtk .or. lGtWvw

   lRddAds   := "RddAds"   IN cRdd
   lMediator := "Mediator" IN cRdd
   lApollo   := "Apollo"   IN cRdd

   tracelog(lUseXharbourDll)

   IF lUseXharbourDll
      cDefLibGccLibs   := cHARso
      cDefBccLibs      := cHarbDll
   ENDIF

   IF lFwh
      @  3, 40 SAY "FWH path" GET cFwhPath PICT "@s25"
   ELSEIF lC4W
      @  3, 40 SAY "C4W path" GET cC4WPath PICT "@s25"
   ELSEIF lMiniGui
      @  3, 40 SAY "MiniGui path" GET cMiniPath PICT "@s25"
   ELSEIF lHwGui
      @  3, 40 SAY "HwGUI path" GET cHwPath PICT "@s25"
   ELSEIF lxHGtk
      @  3, 40 SAY "xHGtk path" GET cxHGPath PICT "@s25"
   ENDIF

   IF lMediator
      @  3, 40 SAY "Mediator path" GET cMedPath PICT "@s25"
   ENDIF

   IF lApollo
      @  3, 40 SAY "Apollo path" GET cApolloPath PICT "@s25"
   ENDIF

   IF nOption = 2 // create a new makefile
      cResName := PadR(alltrim(cResName)+iIF(!empty(cResName)," ","")+alltrim(cAllRes),200 )
   ENDIF

//   @  3, 40 SAY "Obj Files Dir" GET cObjDir PICT "@s15"
//   @  4, 1  SAY  s_aLangMessages[ 45 ] GET cAppName VALID ! Empty( cAppName )
   Attention( s_aLangMessages[ 31 ], 5 )


   @ 06, 01 GET lAutoMemVar  checkbox caption s_aLangMessages[ 32 ] style "[X ]"
   @ 06, 40 GET lVarIsMemVar checkbox caption s_aLangMessages[ 33 ] style "[X ]"
   @ 07, 01 GET lDebug       checkbox caption s_aLangMessages[ 34 ] style "[X ]"
   @ 07, 40 GET lSupressLine checkbox caption s_aLangMessages[ 35 ] style "[X ]"
   @ 08, 01 GET s_lGenppo    checkbox caption s_aLangMessages[ 36 ] style "[X ]"
   @ 08, 40 GET lCompMod     checkbox caption s_aLangMessages[ 37 ] style "[X ]"
   @ 09, 01 SAY s_aLangMessages[ 38 ] GET s_cUserDefine PICT "@s23"
   @ 09, 40 SAY s_aLangMessages[ 39 ] GET s_cUserInclude PICT "@s18"
   @ 10, 01 GET s_lExternalLib checkbox caption s_aLangMessages[ 40 ] style "[X ]"
   @ 10, 40 GET s_lxFwh        checkbox caption "xHarbour FWH" style "[X ]"
   @ 11, 01 SAY "Resource file Name: " GET cResName pict "@s55"
   @ 12, 01 SAY s_aLangMessages[ 43 ] GET s_nFilestoAdd PICT "99" VALID s_nFilestoAdd > 0
   @ 13, 01 GET s_lMt checkbox caption s_aLangMessages[ 44 ] style "[X ]"
   @ 13, 40 SAY s_aLangMessages[ 46 ] GET s_nWarningLevel Pict "9" VALID s_nWarningLevel>=0 .AND. s_nWarningLevel <= 4
// READ
   READ msg at maxrow()-1,1,maxcol()-1

   IF ! Empty( s_cUserDefine )
      aUserDefs := ListasArray2(Alltrim( s_cUserDefine ), ";")

      FOR EACH cCurrentDef in aUserDefs
         cHarbourFlags += " -D" + Alltrim( cCurrentDef ) + " "
      NEXT
   ENDIF

   IF ! Empty( s_cUserInclude )
      cHarbourFlags += " -I" + Alltrim( s_cUserInclude ) + " "
   ENDIF

   s_lBcc   := "BCC"  IN cCompiler
   s_lMSVcc := "MSVC" IN cCompiler
   s_lGcc   := "GCC"  IN cCompiler
   s_lPcc   := "POCC" IN cCompiler
   s_lMingw := "MINGW" IN cCompiler
   if s_lMingw
      s_lGcc := .T.
   endif

   cObjDir  := Alltrim( cObjDir )

   IF "Linux" in cOS
       cCurrentDir := "/"+CurDir()
   ELSE
       cCurrentDir := CurDrive()+":\"+CurDir()
   ENDIF

   IF ! Empty( cObjDir )

      IF !IsDirectory( cObjDir )
         MakeDir( cObjDir )
      ENDIF

   ENDIF

   s_aMacros := GetSourceDirMacros( s_lGcc, cOS )

   IF lLinux
      cObjDir := Alltrim( cObjDir )

      IF ! Empty( cObjDir )
         cObjDir += '/'
      ENDIF

      cTest := cObjDir
   ELSE
      cObjDir := Alltrim( cObjDir )

      IF ! Empty( cObjDir )
         cObjDir += '\'
      ENDIF

      cTest := Upper( cObjDir ) + '\'
   ENDIF

   AEval( s_aMacros, { | x, y | cItem := Substr( x[ 2 ], 1, Len( x[ 2 ] ) ), IIF( At( citem, cTest ) > 0, ( s_aMacros[ y, 1 ] := 'OBJ', s_aMacros[ y, 2 ] := cObjDir ), ) } )

   IF lAutomemvar
      cHarbourFlags += " -a "
   ENDIF

   IF lvarismemvar
      cHarbourFlags += " -v "
   ENDIF


   IF lDebug
      cHarbourFlags    += " -b "
      cDefBccLibs      += " debug.lib "
      cDefGccLibs      += " -ldebug "
      cDefGccLibsw      += " -ldebug "
      cGccLibsOs2      += " -ldebug "
      cDefLibGccLibs   += " -ldebug "
      cDefBccLibsMt    += " debug.lib "
      cDefGccLibsMt    += " -ldebug "
      cDefGccLibsMtw    += " -ldebug "
      cGccLibsOs2Mt    += " -ldebug "
      cDefLibGccLibsMt += " -ldebug "
   ENDIF

   IF lSupressline
      cHarbourFlags += " -l "
   ENDIF

   IF s_lGenppo
      cHarbourFlags += " -p "
   ENDIF

   IF lCompmod
      cHarbourFlags += " -m "
   ENDIF


   IF s_nWarningLevel >= 0
      cHarbourFlags += " -w" + Str(s_nWarningLevel,1)
   ENDIF


   IF s_lBcc

      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\BIN\bcc32 $(CFLAG1) $(CFLAG2) -o$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\BIN\bcc32 -I$(BHC)\include $(CFLAG1) $(CFLAG2) -o$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -D__EXPORT__ -n"+if(s_lasdll,"1","")+" -go -I$(BHC)\include $(HARBOURFLAGS)" + IIF( lFwh, " -I$(FWH)\include", IIF( lMinigui, " -I$(MINIGUI)\include",IIF( lHwgui, " -I$(HWGUI)\include","" ) ) )+IIF( lWhoo," -I$(WHOO)\include ","")+  IIF( lMediator," -I$(MEDIATOR)\include ","")+" -o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS)" + IIF( lFwh, " -I$(FWH)\include", IIF( lMinigui, " -I$(MINIGUI)\include",IIF( lHwgui, " -I$(HWGUI)\include","" ) )) + " -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\BIN\brcc32 $(RFLAGS) $<" } )

   ELSEIF s_lGcc

        IF  "linux" IN Lower(Getenv( "HB_ARCHITECTURE" ) )  .OR. cOS == "Linux"
         AAdd( s_aCommands, { ".cpp.o:", "gcc $(CFLAG1) $(CFLAG2) -o$* $**" } )
         AAdd( s_aCommands, { ".c.o:", "gcc -I/usr/include/xharbour $(CFLAG1) $(CFLAG2) -I. -g -o$* $**" } )

         IF s_lExtended
            AAdd( s_aCommands, { ".prg.o:", "harbour -D__EXPORT__  -n"+if(s_lasdll,"1","")+"  -go -I/usr/include/xharbour $(HARBOURFLAGS) -I.  -o$* $**" } )
         ELSE
            AAdd( s_aCommands, { ".prg.c:", "harbour -n -I/usr/include/xharbour $(HARBOURFLAGS) -I.  -o$* $**" } )
         ENDIF

      ELSE
         AAdd( s_aCommands, { ".cpp.o:", "$(BCB)\bin\gcc $(CFLAG1) $(CFLAG2) -o$* $**" } )
         AAdd( s_aCommands, { ".c.o:", "$(BCB)\bin\gcc -I$(BHC)/include $(CFLAG1) $(CFLAG2) -I. -o$* $**" } )

         IF s_lExtended
            AAdd( s_aCommands, { ".prg.o:", "$(BHC)\bin\harbour -D__EXPORT__  -n"+if(s_lasdll,"1","")+" -go -I$(BHC)/include $(HARBOURFLAGS)  -o$* $**" } )
         ELSE
            AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)/include $(HARBOURFLAGS)  -o$* $**" } )
         ENDIF

      ENDIF

   ELSEIF s_lMSVcc

      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\bin\cl $(CFLAG1) $(CFLAG2) -Fo$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\bin\cl -I$(BHC)\include $(CFLAG1) $(CFLAG2) -Fo$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -D__EXPORT__  -n -I$(BHC)\include $(HARBOURFLAGS) -go  -I$(C4W)\include" + IIF( lMediator," -I$(MEDIATOR)\include ","")+ "-o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS) -I$(C4W)\include -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\rc $(RFLAGS) $<" } )

   ELSEIF s_lPcc

      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\BIN\pocc $(CFLAG1) $(CFLAG2) -Fo$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\BIN\pocc -I$(BHC)\include $(CFLAG1) $(CFLAG2) -Fo$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -D__EXPORT__ -n"+if(s_lasdll,"1","")+" -go -I$(BHC)\include $(HARBOURFLAGS)" + IIF( lFwh, " -I$(FWH)\include", IIF( lMinigui, " -I$(MINIGUI)\include",IIF( lHwgui, " -I$(HWGUI)\include","" ) ) )+IIF( lWhoo," -I$(WHOO)\include ","")+  IIF( lMediator," -I$(MEDIATOR)\include ","")+" -o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS)" + IIF( lFwh, " -I$(FWH)\include", IIF( lMinigui, " -I$(MINIGUI)\include",IIF( lHwgui, " -I$(HWGUI)\include","" ) )) + " -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\BIN\porc $(RFLAGS) $<" } )

   ENDIF


   // Selecting PRG files.

   aInFiles := GetSourceFiles( s_lRecursive, s_lGcc, cOS )
   nLenaSrc := Len( aInFiles )

   IF nLenaSrc == 0 

      IF s_nLang=1 // PT-BR
         s_cAlertMsg := "Nenhum prg foi encontrado." 
      ELSEIF s_nLang=3 // Spanish
         s_cAlertMsg := "Ning�n prg foi encontrado."
      ELSE
         s_cAlertMsg := "No one prg were found."
      ENDIF

      lCancelMake := .T.

      Alert( s_cAlertMsg )

   ENDIF


   IF "Win32" IN cOS
       AEval( aInFiles, { |x,y| aInFiles[y] := Upper( aInFiles[y] ) } )
   ENDIF

   aOutFiles := AClone( aInFiles )

   if Len( aOutFiles ) > 1

      Attention( s_aLangMessages[ 41 ], 22 )

      if s_nLang=1
         s_cAlertMsg := "Selecione os PRGs a compilar"
      elseif s_nLang=3
         s_cAlertMsg := "Seleccione los PRG a compilar"
      else
         s_cAlertMsg := "Select the PRG files to compile"
      endif


      IF nOption !=2 // not create a makefile
         pickarry( 11, 15, 20, 64, aInFiles, aOutFiles ,ArrayAJoin( { oMake:aPrgs, oMake:aCs } ), .T., s_cAlertMsg )
      ELSE
         pickarry( 11, 15, 20, 64, aInFiles, aOutFiles, {}, .T., s_cAlertMsg )
      ENDIF


      AEval( aOutFiles, { | x, y | aOutFiles[ y ] := Trim( Substr( aOutFiles[ y ], 1, At( ' ', aOutFiles[ y ] ) ) ) } )

      aOutFiles := ASort( aOutFiles )

      @ 22,01 say space(78)

      aSelFiles := GetSelFiles( aInFiles, aOutFiles )

      ASort( aSelFiles )

   else
       AEval( aOutFiles, { | x, y | aOutFiles[ y ] := Trim( Substr( aOutFiles[ y ], 1, At( ' ', aOutFiles[ y ] ) ) ) } )
       aSelFiles := aOutFiles
   endif


   if Len( aSelFiles ) = 1

      cTopFile := aSelFiles[1]
      cTopFile := PadR( Left(cTopfile,At(Upper(".prg"),Upper(cTopFile))+4 ), 50)

   elseif Len( aSelFiles ) = 0

      cTopFile := ""

      IF s_nLang=1 // PT
         s_cAlertMsg := "Nenhum PRG foi selecionado."
      ELSEIF s_nLang=3
         s_cAlertMsg := "Ning�m PRG foi seleccionado."
      ELSE
         s_cAlertMsg := "No one PRG were selected."
      ENDIF

      Alert( s_cAlertMsg )

   endif


   WHILE Len( aSelFiles ) > 1

      IF s_nLang=1 // PT
         s_cAlertMsg := "Informe o PRG principal da sua aplica��o:"
      ELSEIF s_nLang=3
         s_cAlertMsg := "Informe o PRG principale de su aplicacion:"
      ELSE
         s_cAlertMsg := "Inform the main PRG of your application:"
      ENDIF

      @ 15,01 say s_cAlertMsg Get cTopFile pict "@S35" valid !empty(cTopFile)
      READ

      if LastKey()=27
         Exit
      endif

      IF "Win32" IN cOS
         cTopFile := Upper( cTopFile )
      ENDIF


      IF !File( alltrim(cTopFile) )
         IF s_nLang=1 // PT
            s_cAlertMsg := "Arquivo "+alltrim(cTopFile)+" n�o encontrado."+iif(s_lRecursive," O flag -r est� ativo. Informe o subdir tamb�m se o PRG principal estiver dentro dele.","")
         ELSEIF s_nLang=3
            s_cAlertMsg := "Fichero "+alltrim(cTopFile)+" no encontrado."+iif(s_lRecursive," Lo flag -r esta activado. Informe lo subdir tambi�n si lo PRG principale est�s dentro dele.","")
         ELSE
            s_cAlertMsg := "File "+alltrim(cTopFile)+" not found."+iif(s_lRecursive," The flag -r is active. Inform the subdir also if the main PRG is within it.","")
         ENDIF
         Alert( s_cAlertMsg )
      ELSE
         EXIT
      ENDIF

   END


   // Selecting External Libs.
   IF s_lExternalLib

//    aLibs := GetLibs( s_lGcc, GetMakeDir() + '\lib' )
//    aLibs := GetLibs( s_lGcc, GetHarbourDir() + '\lib' )
      aLibs := GetLibs( s_lGcc, cHarbourLibDir )

      if len(aLibs)=0
         alert("aLibs is empty")
      endif

      IF s_nLang == 1 // PT
         s_cAlertMsg := '<Espa�o> para selecionar. <Enter> para continuar o processo.'
      ELSEIF s_nLang == 2
         s_cAlertMsg := '<Spacebar> to select. <Enter> to continue process'
      ELSEIF s_nLang == 3
         s_cAlertMsg := '<Espacio> para seleccionar. <Enter> para continuar o proceso.'
      ENDIF

      Attention( s_cAlertMsg, 22 )

      AEval( aLibs, { | x | AAdd( aLibsIn, x[ 1 ] ) } )
      AEval( aLibs, { | x | AAdd( aLibsOut, x[ 2 ] ) } )

      if s_nLang=1
         s_cAlertMsg := "Selecione as LIBs externas a compilar"
      elseif s_nLang=3
         s_cAlertMsg := "Seleccione las LIB externas a compilar"
      else
         s_cAlertMsg := "Select the external LIBs to compile"
      endif


      IF nOption != 2 // not create makefile
         pickarry( 11, 15, 20, 64, aLibsIn, aLibsOut ,oMake:aExtLibs, .T. , s_cAlertMsg, .T. )
      ELSE
         pickarry( 11, 15, 20, 64, aLibsIn, aLibsOut ,{}, .T., s_cAlertMsg, .T. )
      ENDIF

   ENDIF

#IFDEF HBM_USE_DEPENDS
   clear typeahead
   Attention( "HbMake options", 16 )
   @ 17, 01 GET lScanIncludes checkbox     caption "Create #DEPENDS from #include" style "[X ]"
   // Provisions for recursive scanning
   @ 17, 40 GET lScanIncRecursive checkbox caption "Scan recursive" style "[X ]" //when lScanIncludes
   @ 18, 01 SAY "Excluding these extensions :" GET cExcludeExts WHEN lScanIncludes
   READ
#ENDIF


   AEval( aOutFiles, { | xItem | IIF(  '.c'IN xItem  .OR.  '.C' IN xItem , AAdd( aOutc, xItem ), ) } )
   AEval( aOutc, { | x, z | cItem := x, z := AScan( aOutFiles, { | t | t = cItem } ), IIF( z > 0, aSize( aDel( aOutFiles, z ), Len( aOutFiles ) - 1 ), ) } )

   @ 22,01 say space(78)

   aOutFiles  := ASort( aOutFiles )
   s_aPrgs    := AClone( aOutFiles )
   s_aObjs    := AClone( aOutFiles )

   s_aExtLibs := AClone( aLibsOut )

   // searching for main prg file into obj array.
   x := AScan( s_aObjs, { | x | Lower( x ) in Lower( alltrim(cTopFile) ) } )

   // putting main prg in the top
   IF x > 0
      ADel( s_aObjs, x )
      ASize( s_aObjs, Len( s_aObjs ) - 1 )
      ASize( s_aObjs, Len( s_aObjs ) + 1 )
      AIns( s_aObjs, 1 )
      s_aObjs[ 1 ] := AllTrim( cTopFile )
   ENDIF

   // searching for main prg file into prg array.
   x := AScan( s_aPrgs, { | x | Lower( x ) in Lower( alltrim(cTopFile) ) } )

   // putting main prg in the top
   IF x > 0
      ADel( s_aPrgs, x )
      ASize( s_aPrgs, Len( s_aPrgs ) - 1 )
      ASize( s_aPrgs, Len( s_aPrgs ) + 1 )
      AIns( s_aPrgs, 1 )
      s_aPrgs[ 1 ] :=  AllTrim( cTopFile )
   ENDIF

   AEval( s_aObjs, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, s_aObjs[ x ] := cObjDir + cTest + "." + Exte( cExt, 2 ), s_aObjs[ x ] := cObjDir + cTest + "." + Exte( cExt, 3 ) ) } )
   s_aCs := aClone( aOutc )

   IF ! s_lExtended
      AEval( aOutc, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, AAdd( s_aObjs, cObjDir + cTest + "." + Exten( cExt, 2 ) ), AAdd( s_aObjs, cObjDir + cTest + "." + Exten( cExt, 1 ) ) ) } )
      AEval( aOutFiles, { | xItem | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cExt := Substr( cExt, 2 ), AAdd( s_aCs, cObjDir + cTest + "." + Exte( cExt, 1 ) ) } )
   ELSE
      s_aObjsc := aClone( aOutc )
      AEval( aOutc, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, s_aObjsc[ x ] := IIF( ! Empty( cObjDir ), cObjDir, '' ) + cTest + "." + Exten( cExt, 2 ), s_aObjsc[ x ] := IIF( ! Empty( cObjDir ), cObjDir, '' ) + cTest + "." + Exten( cExt, 1 ) ) } )
   ENDIF

   FWrite( s_nMakeFileHandle, "RECURSE=" + IIF( s_lRecursive, " YES ", " NO " ) + CRLF )
   FWrite( s_nMakeFileHandle, " " + CRLF )

   FWrite( s_nMakeFileHandle, "COMPRESS = " + IIF( s_lCompress, "YES", "NO" ) + CRLF )

   FWrite( s_nMakeFileHandle, "EXTERNALLIB = " + IIF( s_lExternalLib, "YES", "NO" ) + CRLF )

   FWrite( s_nMakeFileHandle, "XFWH = " + IIF( s_lxFwh, "YES", "NO" ) + CRLF )

   FWrite( s_nMakeFileHandle, "FILESTOADD = " + Str( s_nFilesToAdd, 2 ) + CRLF )

   FWrite( s_nMakeFileHandle, "WARNINGLEVEL = " + Str(s_nWarningLevel, 2) + CRLF )

   FWrite( s_nMakeFileHandle, "USERDEFINE = " + alltrim(s_cUserDefine) + CRLF )

   FWrite( s_nMakeFileHandle, "USERINCLUDE = " + alltrim(s_cUserInclude) + CRLF )

   IF lFwh
      FWrite( s_nMakeFileHandle, "FWH = " + alltrim(cFwhPath) + CRLF )
   ELSEIF lC4W
      FWrite( s_nMakeFileHandle, "C4W = " + alltrim(cC4WPath) + CRLF )
   ELSEIF lMiniGui
      FWrite( s_nMakeFileHandle, "MINIGUI = " + alltrim(cMiniPath) + CRLF )
   ELSEIF lHwGui
      FWrite( s_nMakeFileHandle, "HWGUI = " + alltrim(cHwPath) + CRLF )
   ELSEIF lGtwvt
      FWrite( s_nMakeFileHandle, "GTWVT = " + CRLF )
   ELSEIF lGtwvw
      FWrite( s_nMakeFileHandle, "GTWVW = " + CRLF )
   ELSEIF lXwt
      FWrite( s_nMakeFileHandle, "XWT = " + CRLF )
   ELSEIF lWhoo
      FWrite( s_nMakeFileHandle, "WHOO = " + CRLF )
   ELSEIF lWhat32
      FWrite( s_nMakeFileHandle, "WHAT32 = " + CRLF )
   ELSEIF lxHGtk
      FWrite( s_nMakeFileHandle, "XHGTK = " + CRLF )
   ENDIF

   IF lMediator
      FWrite( s_nMakeFileHandle, "MEDIATOR = " + alltrim(cMedPath) + CRLF )
   ENDIF

   IF lApollo
      FWrite( s_nMakeFileHandle, "APOLLO = " + alltrim(cApolloPath) + CRLF )
   ENDIF

   FWrite( s_nMakeFileHandle, "GUI = " + iif(lWhoo .or. lFwh .or. lC4W .or. lMinigui .or. lGtWvt .or. lHwGui .or. lXwt .or. lWhat32 .or. lxHGtk .or. lGtWvw , "YES", "NO" ) + CRLF )
   FWrite( s_nMakeFileHandle, "MT = " + IIF( s_lMt, "YES", "NO" ) + CRLF )

   FOR x := 1 TO Len( s_aMacros )

      IF ! Empty( s_aMacros[ x, 2 ] )

         cItem := s_aMacros[ x, 2 ]
         nPos  := AScan( s_aPrgs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0
            AEval( s_aPrgs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aPrgs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ')/', ')\' ) ), ) } )

            IF ! s_aMacros[ x, 3 ]
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
               s_aMacros[ x, 3 ] := .T.
            ENDIF

         ENDIF

         nPos := AScan( s_aCs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0

            IF ! s_aMacros[ x, 3 ]
               AEval( s_aCs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aCs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
               s_aMacros[ x, 3 ] := .T.
            ENDIF

         ENDIF

         nPos := AScan( s_aObjs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0

            IF ! Empty( cObjDir )
               AEval( s_aObjs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aObjs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
            ENDIF

         ENDIF

         IF s_lExtended
            nPos := AScan( s_aObjsc, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

            IF nPos > 0

               IF ! Empty( cObjDir )
                  AEval( s_aObjsc, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aObjsc[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )
               ENDIF

            ENDIF

         ENDIF

      ENDIF

   NEXT

   IF s_lGcc
      IF "linux" IN Lower( Getenv( "HB_ARCHITECTURE" ) )  .OR. cOS == "Linux"
         FWrite( s_nMakeFileHandle, "PROJECT = " + Alltrim( Lower( cAppName ) ) + " $(PR) " + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "PROJECT = " + Alltrim( Lower( cAppName ) ) + ".exe"   + " $(PR) " + CRLF )
      ENDIF
   ELSE
      FWrite( s_nMakeFileHandle, "PROJECT = " + Alltrim( Lower( cAppName ) ) + if(s_lasdll,".dll",".exe" ) + " $(PR) " + CRLF )
   ENDIF


   IF ! s_lExtended

      FWrite( s_nMakeFileHandle, "OBJFILES = " )

      IF Len( s_aObjs ) < 1
         FWrite( s_nMakeFileHandle, + " $(OB) " + CRLF )
      ELSE
         AEval( s_aObjs, { | x, i | IIF( ( i <> Len( s_aObjs ) .AND. x <> alltrim(cTopfile)  ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) ), FWrite( s_nMakeFileHandle, " " + " " + Alltrim( x ) + " $(OB) " + CRLF ) ) } )
      ENDIF

      FWrite( s_nMakeFileHandle, "CFILES =" )

      IF Len( s_aCs ) < 1
         FWrite( s_nMakeFileHandle, + " $(CF)" + CRLF )
      ELSE
         AEval( s_aCs, { | x, i | IIF( ( i <> Len( s_aCs ) .AND. x <> alltrim(cTopfile)  ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(CF) " + CRLF ) ) } )
      ENDIF

      FWrite( s_nMakeFileHandle, "PRGFILE =" )

      IF Len( s_aPrgs ) < 1
         FWrite( s_nMakeFileHandle, + " $(PS)" + CRLF )
      ELSE
         AEval( s_aPrgs, { | x, i | IIF( i <> Len( s_aPrgs) .AND. x <> alltrim(cTopfile) , FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(PS) " + CRLF ) ) } )
      ENDIF

   ELSE

      FWrite( s_nMakeFileHandle, "OBJFILES =" )

      IF Len( s_aObjs ) < 1
         FWrite( s_nMakeFileHandle, + " $(OB) " + CRLF )
      ELSE
         AEval( s_aObjs, { | x, i | nWriteFiles ++, IIF( ( i <> Len( s_aObjs ) .AND. x <> alltrim(cTopfile)  ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % s_nFilestoAdd == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OB) " + CRLF ) ) } )
      ENDIF

      nWriteFiles := 0
      FWrite( s_nMakeFileHandle, "PRGFILES =" )

      IF Len( s_aPrgs ) < 1
         FWrite( s_nMakeFileHandle, + " $(PS)" + CRLF )
      ELSE
         AEval( s_aPrgs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aPrgs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % s_nFilestoAdd == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(PS) " + CRLF ) ) } )
      ENDIF

      nWriteFiles := 0
      FWrite( s_nMakeFileHandle, "OBJCFILES =" )

      IF Len( s_aObjsc ) < 1
         FWrite( s_nMakeFileHandle, + " $(OBC) " + CRLF )
      ELSE
         AEval( s_aObjsc, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aObjsc ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % s_nFilestoAdd == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OBC) " + CRLF ) ) } )
      ENDIF

      nWriteFiles := 0
      FWrite( s_nMakeFileHandle, "CFILES =" )

      IF Len( s_aCs ) < 1
         FWrite( s_nMakeFileHandle, + " $(CF)" + CRLF )
      ELSE
         AEval( s_aCs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aCs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % s_nFilestoAdd == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OB) " + CRLF ) ) } )
      ENDIF


   ENDIF

   cResName := Lower( alltrim(cResName) )
   FWrite( s_nMakeFileHandle, "RESFILES = " + cResName + CRLF )
   FWrite( s_nMakeFileHandle, "RESDEPEN = " + StrTran( cResName, ".rc", ".res" ) + CRLF )
   FWrite( s_nMakeFileHandle, "TOPMODULE = " + alltrim(cTopFile) + CRLF )

   IF lRddads
      cDefBccLibs      += " rddads.lib ace32.lib"
      cDefLibGccLibs   += " -lrddads -ladsloc "
      cDefBccLibsMt    += " rddads.lib ace32.lib"
      cDefLibGccLibsMt += " -lrddads -ladsloc "
      cExtraLibs += " -lrddads -ladsloc "
   ENDIF


//   if !file(GetHarbourDir()+"\lib\ct.lib")
   if !file(cHarbourLibDir+"\ct.lib")
      cDefBccLibs   := StrTran( cDefBccLibs  , "ct.lib","hbct.lib")
      cDefBccLibsMt := StrTran( cDefBccLibsMt, "ctmt.lib","hbctmt.lib")
   endif

// if !file(GetHarbourDir()+"\lib\tip.lib")
   if !file(cHarbourLibDir+"\tip.lib")
      cDefBccLibs   := StrTran( cDefBccLibs  , "tip.lib","hbtip.lib")
      cDefBccLibsMt := StrTran( cDefBccLibsMt, "tipmt.lib","hbtipmt.lib")
   endif


   IF s_lMSVcc .or. s_lPcc // remove bcc640.lib form MSVC/Pelles
      cDefBccLibs   := StrTran( cDefBccLibs, "bcc640.lib ", "")
      cDefBccLibsMt := StrTran( cDefBccLibsMt, "bcc640mt.lib ", "")
   ENDIF

   // if external libs was selected...
   IF Len( aLibsOut ) > 0 .AND. s_lExternalLib

      IF s_lMSVcc .OR. s_lBcc .OR. s_lPcc

         IF ! s_lMt
            cOldLib := cDefBccLibs
         ELSE
            cOldLib := cDefBccLibsMt
         ENDIF

         // searching for html lib...
         nPos := AScan( aLibsOut, { | z | At( "html", Lower( z ) ) > 0 } )

         IF nPos > 0
            cHtmlLib += aLibsOut[ nPos ]
            aDel( aLibsOut, nPos )
            aSize( aLibsOut, Len( aLibsOut ) - 1 )
            cOldLib := StrTran( cOldLib, "gtwin" , "gtcgi" )
         ENDIF

         // searching for mysql lib...
         AEval( aLibsOut, { | cLib | cLibs += " " + cLib } )
         nPos := AScan( aLibsOut, { | z | At( "mysql", Lower( z ) ) > 0 } )

         IF nPos >0
            cLibs += " libmysql.lib"
         ENDIF

         // searching for postgre lib...
         nPos := AScan( aLibsOut, { | z | At( "hbpg", Lower( z ) ) > 0 } )
         IF nPos >0
            cLibs += " libpq.lib"
            cLibs := strtran(cLibs,"hbpg","hbpg")
         ENDIF

         IF ! s_lMt
            cDefBccLibs := cHtmlLib + " " + cOldLib + " " + cLibs
         ELSE
            cDefBccLibsMt := cHtmlLib + " " + cOldLib + " " + cLibs
         ENDIF

      ENDIF

      IF s_lGcc

         nPos := AScan( aLibsOut, { | z | At( "html", Lower( z ) ) > 0 } )

         IF nPos > 0
            cHtmlLib += "-l" + Strtran( aLibsOut[ nPos ], '.a', "" )
            aDel( aLibsOut, nPos )
            aSize( aLibsOut, Len( aLibsOut ) - 1 )
         ENDIF

         AEval( aLibsOut, { | cLib | iif( Len(aTempLibs :=ListAsArray2( cLib, " ") )> 0 ,cLibs += SetthisLibs(AtempLibs) ,cLibs += " -l" + Strtran( cLib, '.a', "" ))} )

         nPos := AScan( aLibsOut, { | z | At( "mysql", Lower( z ) ) > 0 } )

         if nPos >0
            cLibs += " -lmysqlclient"
         endif
         nPos := AScan( aLibsOut, { | z | At( "hbpg", Lower( z ) ) > 0 } )

         if nPos >0
            cLibs += " -lpq"
         endif

         cExtraLibs := cLibs

         IF cOS == "Linux"

            IF ! s_lMt
               cOldLib        := " " + cDefLibGccLibs
               cDefLibGccLibs := cHtmlLib + " " + cOldLib + " " + cLibs

               IF "html" IN cDefLibGccLibs
                   cDefLibGccLibs := StrTran( cDefLibGccLibs, "gtcrs" , "gtcgi" )
                   cDefLibGccLibs := StrTran( cDefLibGccLibs, "ncurses" , "" )
               ENDIF

            ELSE

               cOldLib          := " " + cDefLibGccLibsMt
               cDefLibGccLibsMt := cHtmlLib + " " + cOldLib + " " + cLibs

               IF "html" IN cDefLibGccLibsMt
                   cDefLibGccLibsMt := StrTran( cDefLibGccLibsMt, "gtcrs" , "gtcgi" )
                   cDefLibGccLibsMt := StrTran( cDefLibGccLibsMt, "ncurses" , "" )
               ENDIF

           ENDIF

         ELSEIF cOS == "OS/2"

            IF ! s_lMt
               cOldLib     := " " + cGccLibsOs2
               cGccLibsOs2 := cHtmlLib + " " + cOldLib + " " + cLibs

               IF "html" IN cGccLibsOs2
                   cGccLibsOs2 := StrTran( cGccLibsOs2, "gtos2" , "gtcgi" )
               ENDIF

            ELSE
               cOldLib       := " " + cGccLibsOs2Mt
               cGccLibsOs2Mt := cHtmlLib + " " + cOldLib + " " + cLibs
               IF "html" IN cGccLibsOs2Mt
                   cGccLibsOs2Mt := StrTran( cGccLibsOs2Mt, "gtos2" , "gtcgi" )
               ENDIF

            ENDIF

         ELSE

            IF s_lMt
               cOldLib       := " " + cDefGccLibsMt
               cDefGccLibsMt := cHtmlLib + " " + cOldLib + " " + cLibs
            ENDIF

        ENDIF

      ENDIF

   ENDIF


   IF s_lBcc .OR. s_lMSVcc .OR. s_lPcc

      IF lFwh
         IF s_lxFwh
            FWrite( s_nMakeFileHandle, "LIBFILES = $(FWH)\lib\fivehx.lib $(FWH)\lib\fivehc.lib optgui"+ IIF( ! s_lMt, "", "mt" ) +".lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
         ELSE
            FWrite( s_nMakeFileHandle, "LIBFILES = $(FWH)\lib\fiveh.lib $(FWH)\lib\fivehc.lib optgui"+ IIF( ! s_lMt, "", "mt" ) +".lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
         ENDIF
      ELSEIF lMiniGui
         FWrite( s_nMakeFileHandle, "LIBFILES = minigui.lib optgui.lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ELSEIF lWhoo
         FWrite( s_nMakeFileHandle, "LIBFILES = whoo.lib what32.lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ELSEIF lWhat32
         FWrite( s_nMakeFileHandle, "LIBFILES = what32.lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ELSEIF lHwGui
         FWrite( s_nMakeFileHandle, "LIBFILES = hwgui.lib procmisc.lib hwg_qhtm.lib " + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ELSEIF lC4W
         FWrite( s_nMakeFileHandle, "LIBFILES = $(C4W)\c4wclass.lib $(C4W)\wbrowset.lib $(C4W)\otabt.lib $(C4W)\clip4win.lib optgui.lib "  + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ELSE
         if lGtwvt
            cDefBccLibs   := strtran(cDefBccLibs,"gtwin","gtwvt")
            cDefBccLibsMt := strtran(cDefBccLibsMt,"gtwin","gtwvt")
         endif
         if lGtwvw
            cDefBccLibs   := strtran(cDefBccLibs,"gtwin","gtwvw")
            cDefBccLibsMt := strtran(cDefBccLibsMt,"gtwin","gtwvw")
         endif

         FWrite( s_nMakeFileHandle, "LIBFILES = " + iif( lGTWVT,"optgui.lib ",iif(!s_lasdll,"optcon.lib ","")) + iif( !s_lMt, "", "mt" )  + IIF( ! s_lMt, cDefBccLibs, cDefBccLibsMt ) + CRLF )
      ENDIF

   ELSEIF s_lGcc

      IF cOS == "Linux"
         FWrite( s_nMakeFileHandle, "LIBFILES = " + IIF(lusexhb, cExtraLibs , "-Wl,--start-group " + IIF( ! s_lMt, cDefLibGccLibs, cDefLibGccLibsMt ) + " -Wl,--end-group " + cSystemLibs ) + CRLF )
      ELSEIF cOS == "OS/2"
         FWrite( s_nMakeFileHandle, "LIBFILES = " + IIF( ! s_lMt, cGccLibsOs2, cGccLibsOs2Mt ) + CRLF )
      ELSEIF  "MINGW" IN cCompiler
         FWrite( s_nMakeFileHandle, "LIBFILES = " + "-Wl,--start-group " + IIF( ! s_lMt, cDefGccLibsw, cDefGccLibsMtw ) + " -Wl,--end-group " + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "LIBFILES = " + IIF( ! s_lMt, cDefGccLibs, cDefGccLibs ) + CRLF )
      ENDIF

   ENDIF

   nWriteFiles := 0
   FWrite( s_nMakeFileHandle, "EXTLIBFILES =" )

   if Len(s_aExtLibs) < 1
      FWrite( s_nMakeFileHandle, CRLF ) 
   else
      AEval( s_aExtLibs, { | x, i | nWriteFiles ++, FWrite( s_nMakeFileHandle, " " + Alltrim( x )  ) } )
      FWrite( s_nMakeFileHandle, CRLF ) 
   endif

   FWrite( s_nMakeFileHandle, "DEFFILE = " + CRLF )
   FWrite( s_nMakeFileHandle, "HARBOURFLAGS = " + cHarbourFlags + CRLF )


   IF s_lBcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -OS $(CFLAGS) -d -L$(BHC)\lib"+iif(lFwh,";$(FWH)\lib -c","")+iif(!empty(s_cUserInclude)," -I" + alltrim( s_cUserInclude ),"") + " " +CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 =  -I$(BHC)\include;$(BCB)\include" + iif( s_lMt, "-DHB_THREAD_SUPPORT" , "" ) + CRLF )

      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
/* added "-x" flag to LFLAGS statment to suppress creation of map file and speed up link. */
      FWrite( s_nMakeFileHandle, "LFLAGS = -L$(BCB)\lib\obj;$(BCB)\lib;$(BHC)\lib -Gn -M -m -s -Tp"+ if(s_lasdll,"d","e") + " -x" + IIF( lFWH .or. lMiniGui .or. lWhoo .or. lHwgui .or. lGtWvt .or. lGtWvw ," -aa"," -ap") + IIF( lMinigui, " -L$(MINIGUI)\lib",IIF( lFwh, " -L$(FWH)\lib",IIF( lHwgui, " -L$(HWGUI)\lib","" ))) + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = ilink32" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = " + IIF( ( lWhoo .OR. lWhat32 .OR. lFwh .OR. lMinigui .OR. lHwgui .or. lGtWvt .or. lXwt .or. lxHGtk ), "c0w32.obj", if(s_lAsDll,"c0d32.obj","c0x32.obj" )) + " $(OBJFILES)" + IIF( s_lExtended, " $(OBJCFILES)", " " ) + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = $(LIBFILES) import32.lib " + IIF( s_lMt,"cw32mt.lib", "cw32.lib" )+ CRLF )
      FWrite( s_nMakeFileHandle, ".autodepend" + CRLF )

   ELSEIF s_lMSVcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -I$(INCLUDE_DIR) -TP -W3 -nologo $(C_USR) $(CFLAGS)" +IIF( s_lMt, "-DHB_THREAD_SUPPORT" , "" ) + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 =  -c" +" -I" + alltrim( s_cUserInclude ) + " " + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = /LIBPATH:$(BCB)\lib /LIBPATH1:$(BHC)\lib /LIBPATH2:$(C4W)\lib"  +IIF(s_lMt, " /Nodefaultlib:LIBC "," /Nodefaultlib:LIBCMT " ) + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = link" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = " + IIF( lC4W, "$(C4W)\initc.obj", "" ) + "$(OBJFILES)" + IIF( s_lExtended, " $(OBJCFILES)", " " ) + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = $(LIBFILES) kernel32.lib user32.lib gdi32.lib winspool.lib comctl32.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib mpr.lib vfw32.lib winmm.lib " + CRLF )

   ELSEIF s_lPcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -I$(INCLUDE_DIR) -Tx86-coff -W1 $(C_USR) $(CFLAGS)" +IIF( s_lMt, "-DHB_THREAD_SUPPORT" , "" ) + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 = " + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = /LIBPATH:$(BCB)\lib /LIBPATH:$(BHC)\lib\win /SUBSYSTEM:CONSOLE" +IIF(s_lMt, " /Nodefaultlib:LIBC "," /Nodefaultlib:LIBCMT " ) + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = polink" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = " + IIF( lC4W, "$(C4W)\initc.obj", "" ) + "$(OBJFILES)" + IIF( s_lExtended, " $(OBJCFILES)", " " ) + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = $(LIBFILES) crt.lib kernel32.lib winspool.lib user32.lib ole32.lib uuid.lib oleaut32.lib" + CRLF )

   ELSEIF s_lGcc

      FWrite( s_nMakeFileHandle, "CFLAG1 = " +IIF( !EMPTY(s_cUserInclude ) ," -I" + Alltrim( s_cUserInclude ),"")        + IIF(  "Linux" IN cOS, "-I/usr/include/xharbour", " -I$(BHC)/include" ) + " -c -Wall" + IIF( s_lMt, "-DHB_THREAD_SUPPORT" , "" ) + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 = " + IIF(  "Linux" IN cOS, "-L$(HB_LIB_INSTALL)", " -L$(BHC)/lib  -L$(BCB)/lib" )  + CRLF )

      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS =" + IIF(lUseXhb ,IIF(lUseXharbourDll,"","-static ") + if(lXwt,"-gtcgi " , "-gtcrs "), "$(CFLAG2)") + iif(lXwt,"`pkg-config --libs gtk+-2.0` -lxwt -lxwt_gtk -lxwt","") + iif( lxHGtk, "`pkg-config --libs gtk+-2.0 libglade-2.0` -lxhgtk ","") + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = "+ IIF(lusexhb,"xhblnk","gcc") + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = $(OBJFILES) " + IIF( s_lExtended, " $(OBJCFILES)", " " ) + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN) " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = $(LIBFILES) " +if(s_lMingw," -luser32 -lwinspool -lgdi32 -lcomctl32 -lcomdlg32 -lole32 -loleaut32 -luuid -lmpr -lwsock32 -lws2_32 -lmapi32","") + CRLF )
      FWrite( s_nMakeFileHandle, ".autodepend" + CRLF )

   ENDIF

#IFdef HBM_USE_DEPENDS

   FWrite( s_nMakeFileHandle, " " + CRLF )
   FWrite( s_nMakeFileHandle, "#DEPENDS" + CRLF )

   IF lScanIncludes
      // Clipper/(x)Harbour sources: .prg
      IF Len( s_aPrgs ) = Len( s_aObjs )
         Attention("Scanning .PRG sources...",19)
         FOR nPos := 1 to Len(s_aPrgs)
            cIncl := ScanInclude( s_aPrgs[ nPos ], lScanIncRecursive, cExcludeExts )
            // Only add in list if dependencies exist
            IF ! Empty(cIncl)
               FWrite( s_nMakeFileHandle, s_aObjs[ nPos ] + ': ' + Alltrim( cIncl ) + CRLF, "" )
            ENDIF
         NEXT
      ENDIF

      // C-sources: .c
      IF Len( s_aCs ) = Len( s_aObjsc )
         Attention("Scanning .C sources...",19)
         FOR nPos := 1 to Len(s_aCs)
            cIncl := ScanInclude( s_aCs[ nPos ], lScanIncRecursive, cExcludeExts )
            // Only add in list if dependencies exist
            IF ! Empty(cIncl)
               FWrite( s_nMakeFileHandle, s_aObjsc[ nPos ] + ': ' + Alltrim( cIncl ) + CRLF, "" )
            ENDIF
         NEXT
      ENDIF

      // Cleanup message
      @ 19, 1 say Space(MaxCol() - 2)
   ENDIF

#ENDIF

   FWrite( s_nMakeFileHandle, " " + CRLF )
   FWrite( s_nMakeFileHandle, "#COMMANDS" + CRLF )

   AEval( s_aCommands, { | xItem | FWrite( s_nMakeFileHandle, xitem[ 1 ] + CRLF ), FWrite( s_nMakeFileHandle, xitem[ 2 ] + CRLF ), FWrite( s_nMakeFileHandle, " " + CRLF ) } )

   IF s_lBcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&!  " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(LFLAGS) +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(PROJECT),, +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLLIB), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(DEFFILE), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLRES) " + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ELSEIF s_lMSVcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, "" + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&! " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(LFLAGS) +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(PROJECT),, +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLLIB), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(DEFFILE), +" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLRES) " + CRLF )
      FWrite( s_nMakeFileHandle, "! " + CRLF )

   ELSEIF s_lPcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, "" + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&! " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(LFLAGS)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ) " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(PROJECT)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(PROJECTMAP)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLLIB) " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(DEFFILE) " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLRES) " + CRLF )
      FWrite( s_nMakeFileHandle, "! " + CRLF )

   ELSEIF s_lGcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)" + CRLF )

      IF 'Linux' IN cOS
         FWrite( s_nMakeFileHandle, "    $(LINKER) @&&!" + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "    $(BCB)\bin\$(LINKER) @&&!" + CRLF )
      ENDIF

      FWrite( s_nMakeFileHandle, "    $(PROJECT) " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ)  " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(LFLAGS)  " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLLIB)  " + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ENDIF

   FClose( s_nMakeFileHandle )

   IF !lCancelMake

      IF s_nLang == 1 .OR. s_nLang == 3
         s_cAlertMsg := "Compilar app ? (S/N) "
      ELSE // English
         s_cAlertMsg := "Build app ? (Y/N) "
      ENDIF

      @ 20,5 Say s_cAlertMsg Get cBuild PICT "!" Valid cBuild $ iif(s_nLang=2,"YN","SN")
      READ

      IF ( cBuild == "S" .or. cBuild == "Y" )

         IF lNew  .or. Len(aSelFiles)=1
            cBuildForced := "Y"
         ELSE

            IF s_nLang == 1
               s_cAlertMsg := "For�ar recompila��o para todos PRGs </f> ? (S/N) "
            ELSEIF s_nLang == 3 // Spanish
               s_cAlertMsg := "Forzar recompilaci�n para todos los PRGs </f> ? (S/N) "
            ELSE // English
               s_cAlertMsg := "Force recompiling for all PRGs </f> ? (Y/N) "
            ENDIF

            @ 21,5 Say s_cAlertMsg Get cBuildForced PICT "!" Valid cBuildForced $ iif(s_nLang=2,"YN","SN")
            READ

         ENDIF

         IF cBuildForced == "S" .or. cBuildForced == "Y"
            cBuildParam := " -f " + iif(s_nLang=1,"-lPT",iif(s_nLang=3,"-lES","-lEN"))
         ENDIF

      ENDIF


      IF cBuild == "S" .OR. cBuild == "Y"
         ResetInternalVars()
         SetColor("W/N,N/W")
         Clear
         SetPos(9,0)
//       Main( cFile, " -f "+iif(s_nLang=1,"-lPT",iif(s_nLang=3,"-lES","-lEN")) )
         if cBuildParam != NIL
            Main( cFile, cBuildParam )
         else
            Main( cFile )
         endif
      ELSE
         set cursor on
         setcolor("W/N,N/W")
         clear
      ENDIF

   ELSE
      set cursor on
      setcolor("W/N,N/W")
      clear
   ENDIF

RETURN NIL

#IfDef HBM_USE_DEPENDS

*------------------------------------------------------------
FUNCTION ScanInclude( cFile, lRecursive, cExclExtent, aFiles)
*------------------------------------------------------------
// Search for #Include & Set Procedure To & Set Proc To

   LOCAL cFileList := ""
   LOCAL nHandle   := -1
   LOCAL lEof      := .F.
   LOCAL cTemp     := ""
   LOCAL cBuffer   := ""
   LOCAL aQuotes   := {{'"','"'},{"'","'"},{"[","]"},{"<",">"}}
   LOCAL cQuote    := ""
   LOCAL cQuoteA   := ""
   LOCAL cInclude  := ""
   LOCAL lPrg      := .F.
   Local lC        := .F.
   LOCAL lCh       := .F.
   LOCAL cPath     := ""
   LOCAL cFnam     := ""
   LOCAL cExt      := ""
   LOCAL cDrive    := ""
   LOCAL cContinue := ""

   DEFAULT lRecursive  TO .F.
   DEFAULT cExclExtent TO ""    // specify extensions to exclude like ".ch.def" etc., including the dot
   DEFAULT aFiles      TO {}

   IF File(cFile)

       HB_FNAMESPLIT( cFile, @cPath, @cFnam, @cExt, @cDrive )

       lPrg := (Lower(cExt) == ".prg")
       lC := (Lower(cExt) == ".c")
       lCh := (Lower(cExt) == ".ch")
       cContinue := IIF(lPrg,";",IIF(lC,"\",""))

       nHandle := FOpen(cFile)

       IF nHandle != F_ERROR

           // Provisions for recursive scanning
           // Add current file to list, making it by default the first in the list

           IF s_lWin32
               IF AScan(aFiles, {| x | Lower( x ) == Lower( cFnam + cExt ) } ) = 0       // Case IN-sensitive!
                   AAdd(aFiles,  cFnam + cExt)
               ENDIF
           ELSE
               IF AScan(aFiles, cFnam + cExt ) = 0       // Case Sensitive!
                   AAdd(aFiles,  cFnam + cExt)
               ENDIF
           ENDIF

           lEof := (HB_FReadLine(nHandle,@cTemp,{chr(13)+chr(10), chr(10)}) = -1)
           cTemp := LTrim( cTemp )
           // Loop reading file
           WHILE !lEof
               IF lPrg .OR. lC      // Check for line-continuation
                   WHILE Right(cTemp, 1 ) == cContinue

                       cTemp := Left( cTemp , Len( cTemp ) - 1)
                       IF !lEof
                          lEof := (HB_FReadLine(nHandle,@cBuffer,{chr(13)+chr(10), chr(10)}) = -1)
                          cTemp += LTrim( cBuffer)
                       ENDIF

                   ENDDO
               ENDIF
               // Dependencies
               IF Upper(Left( cTemp ,8)) == "#INCLUDE"
                   cTemp := AllTrim(SubStr( cTemp, 9))
               Else
                   IF lPrg .and. Upper(Left( cTemp, 16)) == "SET PROCEDURE TO"
                       cTemp := AllTrim(SubStr( cTemp, 17))
                   ELSE
                       IF lPrg .and. Upper(Left( cTemp, 11)) == "SET PROC TO"  // Alternative
                           cTemp := AllTrim(SubStr( cTemp, 12))
                       ELSE
                           cTemp := ""
                       ENDIF
                   ENDIF
               Endif
               // Something Ok?
               IF Len(cTemp) > 0
                  cQuote := Left( cTemp, 1)
                  cQuoteA := ""
                  AEval(aQuotes,{| x |Iif(x[1] == cQuote,cQuoteA := x[2],)})     // Determine closing quote
                  IF cQuoteA == ""
                      cInclude := AllTrim(Left(cTemp, At(" ", cTemp + " ") - 1)) // Handle set procedure to, not using quotes
                  ELSE
                      cTemp := SubStr(cTemp, 2)
                      cInclude := AllTrim(Left(cTemp, At(cQuoteA, cTemp) - 1))   // Find closing quote
                  ENDIF
                  IF Len(cInclude) > 0 .and. Len(Alltrim(cExclExtent)) > 0
                      HB_FNAMESPLIT( cInclude, @cPath, @cFnam, @cExt, @cDrive )
                      IF lPrg .AND. Len(cExt) = 0
                          cInclude := cInclude + ".prg"        // Handle set procedure to, using default extension
                      ENDIF
                      IF AT(Lower(cExt), Lower(cExclExtent)) > 0
                          cInclude := ""
                      ENDIF
                  ENDIF
                  IF Len(cInclude) > 0
                      // Still Ok, add to list?
                      IF s_lWin32
                          IF AScan(aFiles, {| x | Lower( x ) == Lower( cInclude ) } ) = 0       // Case IN-sensitive!
                              AAdd(aFiles, (cInclude) )
                              // recursive scanning
                              IF lRecursive
                                  ScanInclude(FileInIncludePath(cInclude), lRecursive, cExclExtent, aFiles )
                              ENDIF
                          ENDIF
                      ELSE
                          IF AScan(aFiles, cInclude ) = 0       // Case Sensitive!
                              AAdd(aFiles, (cInclude) )
                              // recursive scanning
                              IF lRecursive
                                  ScanInclude(FileInIncludePath(cInclude), lRecursive, cExclExtent, aFiles )
                              ENDIF
                          ENDIF
                      ENDIF
                  ENDIF
               ENDIF
               IF !lEof
                   lEof := (HB_FReadLine(nHandle,@cTemp,{chr(13)+chr(10), chr(10)}) = -1)
                   cTemp := LTrim( cTemp)
               ENDIF
           ENDDO

         FClose( nHandle )
       ENDIF

   ENDIF
   // Return results, a space-separated list of filenames, unsorted
   IF Len(aFiles) > 1   // Skip generation of list if only main source (1) was added, caller knows what to do
       AEval(aFiles,{| x | cFileList := cFileList + " " + x } )
   ENDIF

RETURN cFileList
#Endif

*-----------------------------
FUNCTION CompileUpdatedFiles()
*-----------------------------

   LOCAL cComm
   LOCAL cOld
   LOCAL nPos
   LOCAL nCount

   LOCAL aCtocompile := {}
   LOCAL aOrder      := ListAsArray2( s_aBuildOrder[ 2 ], " " )
   LOCAL lEnd
   LOCAL cErrText    := ""
   LOCAL xItem
   LOCAL nObjPos
   LOCAL cOrder      := ""
   LOCAL cPrg        := ""
   LOCAL nFiles
   LOCAL nFile       := 1
   LOCAL lNewer      := .F.
#IfDef HBM_USE_DEPENDS
   LOCAL nPos1       := 0
   LOCAL cDepSrc     := ""
#Endif
   LOCAL aGauge      := GaugeNew( 5, 5, 7, 40, "W/B", "W+/B", '�' )

   @ 4,5 SAY "Compiling :"

   FOR EACH cOrder in aOrder
      IF ! s_lExtended

         IF cOrder == "$(CFILES)"
            nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.c:" } )

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ENDIF

            FOR nFiles := 1 TO Len( s_aPrgs )
               xItem   := Substr( s_aPrgs[ nFiles ], Rat( IIF( s_lGcc, '/', '\' ), s_aPrgs[ nFiles ] ) + 1 )
               nPos    := AScan( s_aCs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), Left( x, At( ".", x ) ) == Left( xItem, At( ".", xItem ) ) } )
               nObjPos := AScan( s_aObjs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), Left( x, At( ".", x ) ) == Left( xItem, At( ".", xItem ) ) } )

#IfDef HBM_USE_DEPENDS
               lNewer := .F.
               nPos1 := AScan( s_aDepends, { | x |lower(x[1]) == lower( s_aObjs[ npos ] )})
               IF nPos1 > 0
                  FOR EACH cDepSrc in s_aDepends[ nPos1 , 2 ]
                      lNewer := lNewer .OR. Fileisnewer( cDepSrc, s_aObjs[ npos ], .T. )
                  NEXT
               ENDIF
#Endif

               IF lNewer .or. FileIsNewer( s_aPrgs[ nFiles ], s_aObjs[ nObjPos ] )

                  IF nPos > 0
                     AAdd( aCtocompile, s_aCs[ nPos ] )
                     if s_lMSVcc .or. s_lPcc
                        cComm := Strtran( cComm, "-Fo$*", "/Fo" + s_aCs[ nPos ] )
                     else
                        cComm := Strtran( cComm, "o$*", "o" + s_aCs[ nPos ] )
                     endif
                     cComm := Strtran( cComm, "$**", s_aPrgs[ nFiles ] )
                     cComm += IIF( s_lLinux , " > "+ (s_cLog)," >>"+ (s_cLog))

                     //                   Outstd( cComm )
                     //                   Outstd( Hb_OsNewLine() )
                     setpos(9,0)
                     __RUN( (cComm) )
                     cErrText := Memoread( (s_cLog) )
                     lEnd     := 'C2006' $ cErrText .OR. 'No code generated' $ cErrText

                     IF ! s_lIgnoreErrors .AND. lEnd
                        IIF(  s_lLinux , __run( "mcedit " + (s_cLog) ), __run( "Notepad " + (s_cLog) ) )
                        set cursor on
                        QUIT
                     ELSE
                        // FErase( s_cLog )
                     ENDIF

                     cComm := cOld

                  ENDIF

               ENDIF

            NEXT

         ENDIF

         IF cOrder == "$(OBJFILES)"

            IF s_lGcc
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.o:" .OR. x[ 1 ] == ".cpp.o:" } )
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.obj:" .OR. x[ 1 ] == ".cpp.obj:" } )
            ENDIF

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ENDIF

            IF Len( aCtoCompile ) >= 1

               FOR nFiles := 1 TO Len( s_aCs )
                  nPos := AScan( s_aCs, { | x | Left( x, At( ".", x ) ) == Left( aCtoCompile[ nfiles ], At( ".", aCtoCompile[ nfiles ] ) ) } )

                  IF nPos == 0
                     AAdd( aCtoCompile, s_aCs[ nFiles ] )
                  ENDIF

               NEXT

            ENDIF

            FOR nFiles := 1 TO Len( aCtocompile )
               xItem := Substr( aCtocompile[ nFiles ], Rat( IIF( s_lGcc, '/', '\' ), aCtocompile[ nFiles ] ) + 1 )
               nPos  := AScan( s_aObjs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), Left( x, At( ".", x ) ) == Left( aCtocompile[ nFiles ], At( ".", xItem ) ) } )

               IF nPos > 0
                  if s_lMSVcc .or. s_lPcc
                     cComm := Strtran( cComm, "-Fo$*", "/Fo" + s_aObjs[ nPos ] )
                  else
                     cComm := Strtran( cComm, "o$*", "o" + s_aObjs[ nPos ] )
                  endif
                  cComm := Strtran( cComm, "$**", aCtocompile[ nFiles ] )
                  cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))
                  Outstd( " " )

                  Outstd( cComm )
                  Outstd( Hb_OsNewLine() )
                  setpos(9,0)
                  __RUN( (cComm) )
                  cComm := cOld
               ENDIF

            NEXT

         ENDIF

      ELSE /**************Extended mode ******/             ////

         IF cOrder == "$(CFILES)"
            nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".c.obj:" .OR. x[ 1 ] == ".cpp.obj:" .or. x[ 1 ] == ".cpp.o:" .or. x[ 1 ] == ".c.o:"  } )

            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".C.OBJ:" } )

               IF nPos > 0
                  cComm := s_aCommands[ nPos, 2 ]
                  cOld  := cComm
               ENDIF

            ENDIF

            GaugeDisplay( aGauge )

            FOR nFiles := 1 TO Len( s_aCs )
               @  4, 16 SAY Space( 50 )
               xItem := Substr( s_aCs[ nFiles ], Rat( IIF( s_lGcc, '/', '\' ), s_aCs[ nFiles ] ) + 1 )
               nPos  := AScan( s_aObjsc, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), Left( x, At( ".", x ) ) == Left( xitem, At( ".", xitem ) ) } )

#IfDef HBM_USE_DEPENDS
               lNewer := .F.
               nPos1 := AScan( s_aDepends, { | x |lower(x[1]) == lower( s_aObjs[ npos ] )})
               IF nPos1 > 0
                  FOR EACH cDepSrc in s_aDepends[ nPos1 , 2 ]
                      lNewer := lNewer .OR. Fileisnewer( cDepSrc, s_aObjs[ npos ], .T. )
                  NEXT
               ENDIF
#Endif
               IF lNewer .or. Fileisnewer( s_aCs[ nFiles ], s_aObjsc[ nPos ] )

                  IF nPos > 0
                     if s_lMSVcc .or. s_lPcc
                        cComm := Strtran( cComm, "-Fo$*", "/Fo" + s_aObjsc[ nPos ] )
                     else
                        cComm := Strtran( cComm, "o$*", "o" + s_aObjsc[ nPos ] )
                     endif
                     cComm := Strtran( cComm, "$**", s_aCs[ nFiles ] )
                     cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))
                     @  4, 16 SAY s_aCs[ nFiles ]
                     GaugeUpdate( aGauge, nFile / Len( s_aCs ) )  // changed s_aPrgs to s_aCs Ath 2004-06-08
                     nFile ++
                     //                            Outstd( cComm )
                     //                            Outstd( Hb_OsNewLine() )
                     setpos(9,0)
                     __RUN( (cComm) )
                     cErrText := Memoread( (s_cLog) )
                     lEnd     := 'Error E' $ cErrText

                     IF ! s_lIgnoreErrors .AND. lEnd
                        IIF(  s_lLinux , __run( "mcedit "  + (s_cLog)), __run( "Notepad " + (s_cLog) ) )
                        set cursor on
                        QUIT
                     ELSE
                        // FErase( s_cLog )
                     ENDIF

                     cComm := cOld

                  ENDIF

               ENDIF

            NEXT
            //nFile++
         ENDIF
         GaugeDisplay( aGauge )

         IF cOrder == "$(OBJFILES)"

            IF s_lGcc
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.o:" } )
            ELSE
               nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".prg.obj:" } )
            ENDIF
            IF nPos > 0
               cComm := s_aCommands[ nPos, 2 ]
               cOld  := cComm
            ELSE

               IF s_lGcc
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".PRG.O:" } )
               ELSE
                  nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".PRG.OBJ:" } )
               ENDIF

            ENDIF

            nFile := 1

            FOR EACH cPrg IN s_aPrgs
               @  4, 16 SAY Space( 50 )
               xItem := Substr( cPrg, Rat( IIF( s_lGcc, '/', '\' ), cPrg ) + 1 )
               nPos  := AScan( s_aObjs, { | x | x := Substr( x, Rat( IIF( s_lGcc, '/', '\' ), x ) + 1 ), Left( x, At( ".", x ) ) == Left( xItem, At( ".", xitem ) ) } )

#IfDef HBM_USE_DEPENDS
               lNewer := .F.
               nPos1 := AScan( s_aDepends, { | x |lower(x[1]) == lower( s_aObjs[ npos ] )})
               IF nPos1 > 0
                  FOR EACH cDepSrc in s_aDepends[ nPos1 , 2 ]
                      lNewer := lNewer .OR. Fileisnewer( cDepSrc, s_aObjs[ npos ], .T. )
                  NEXT
               ENDIF
#Endif

               IF !empty( cPrg ) .AND. (lNewer .OR. Fileisnewer( cPrg, s_aObjs[ npos ] ))

                  IF nPos > 0
                     if s_lMSVcc .or. s_lPcc
                        cComm := Strtran( cComm, "-Fo$*", "/Fo" + s_aObjs[ nPos ] )
                     else
                        cComm := Strtran( cComm, "o$*", "o" + s_aObjs[ nPos ] )
                     endif
                     cComm := Strtran( cComm, "$**", cPrg )
                     cComm += IIF( s_lLinux ,  " > "+ (s_cLog)," >>"+ (s_cLog))
                     @  4, 16 SAY cPrg
                     GaugeUpdate( aGauge, nFile / Len( s_aPrgs ) )
                     nFile ++     // moved from outside 'FOR EACH', Ath 2004-06-08

                     setpos(9,0)
                     __RUN( (cComm) )
                     cErrText := Memoread( (s_cLog) )
                     lEnd     := 'C2006' $ cErrText .OR. 'No code generated' $ cErrText .or. "Error E" $ cErrText .or. "Error F" $ cErrText

                     IF ! s_lIgnoreErrors .AND. lEnd
                        IIF( s_lLinux , __run( "mcedit " + (s_cLog) ), __run( "Notepad "  + (s_cLog) ) )
                        set cursor on
                        QUIT
                     ELSE
                        // FErase( s_cLog )
                     ENDIF

                     cComm := cOld

                  ENDIF

               ENDIF

            NEXT

            // nFile ++    // removed, useless, Ath 2004-06-08

         ENDIF

      ENDIF

      IF cOrder == "$(RESDEPEN)"
         nPos := AScan( s_aCommands, { | x | x[ 1 ] == ".rc.res:" } )

         IF nPos > 0
            cComm := s_aCommands[ nPos, 2 ]
            cOld  := cComm
         ENDIF

         FOR nFiles := 1 TO Len( s_aResources )

            IF ! Empty( s_aResources[ nFiles ] )
               cComm := Strtran( cComm, "$<", s_aResources[ nFiles ] )
               outstd( " " )
               setpos(9,0)
               __RUN( (cComm) )
            ENDIF

            cComm := cOld

         NEXT

      ENDIF

   NEXT

RETURN NIL

*------------------------------------------
FUNCTION FileIsNewer( cFile, as, lInclude )
*------------------------------------------

   LOCAL nCount    := 0
   LOCAL cSrcPath  := ""

   DEFAULT lInclude TO .F.

   // Check all paths in INCLUDE environment variable, if requested
   IF lInclude
       cFile := FileInIncludePath(cFile)
   ENDIF

   IF ! s_lExtended

      FOR nCount := 1 TO Len( s_aPrgs )
         s_aDir := { cFile,, Hbmake_Filedate( cFile ), hbmake_filetime( cFile ), ;
                   as[ nCount ], Hbmake_Filedate( as[ nCount ] ), hbmake_filetime( as[ nCount ] ) }

         IF Empty( s_aDir[ 7 ] )
            s_aDir[ 2 ] := .T.
         ELSE
            s_aDir[ 2 ] := td2jul( s_aDir[ 4 ], s_aDir[ 3 ] ) > td2jul( s_aDir[ 7 ], s_aDir[ 6 ] )
         ENDIF

      NEXT

   ELSE
      s_aDir := { cFile,, Hbmake_Filedate( cFile ), hbmake_filetime( cFile ), ;
                as, Hbmake_Filedate( as ), hbmake_filetime( as ) }

      IF Empty( s_aDir[ 7 ] )
         s_aDir[ 2 ] := .T.
      ELSE
         s_aDir[ 2 ] := td2jul( s_aDir[ 4 ], s_aDir[ 3 ] ) > td2jul( s_aDir[ 7 ], s_aDir[ 6 ] )
      ENDIF

   ENDIF

RETURN s_aDir[ 2 ]

*--------------------------------
FUNCTION FileInIncludePath(cFile)
*--------------------------------

 LOCAL cFilePath := ""
 LOCAL cSrcPath  := ""

    IF Len(s_aSrcPaths) = 0
        s_aSrcPaths := ListAsArray2( GetEnv( "INCLUDE" ) , HB_OSPATHLISTSEPARATOR() )
    ENDIF
    IF ! File(cFile)
        FOR EACH cSrcPath IN s_aSrcPaths
            IF Len(cSrcPath) > 0 .and. Right(cSrcPath,1) <> HB_OSPATHSEPARATOR()
                cSrcPath := cSrcPath + HB_OSPATHSEPARATOR()
            ENDIF
            IF File(cSrcPath + cFile)
                cFile := cSrcPath + cFile
                EXIT
            ENDIF
        NEXT
    ENDIF

RETURN cFile

*----------------------------------
FUNCTION CreateLibMakeFile( cFile )
*----------------------------------

   LOCAL aInFiles  := {}
   LOCAL aOutFiles := {}
   LOCAL aSrc      := Directory( "*.prg" )
   LOCAL nLenaSrc  := Len( aSrc )

   LOCAL aOutC     := {}
   LOCAL aSrcC     := Directory( "*.c" )
   LOCAL cOS       := IIF( s_lLinux, "Linux", "Win32")
   LOCAL cCompiler := IIF( s_lLinux, "GCC","BCC")
   LOCAL cLibName  := Padr( Left( cFile, At( '.', cFile ) - 1 ) ,40)

   LOCAL lAutomemvar     := .F.
   LOCAL lVarIsMemvar    := .F.
   LOCAL lDebug          := .F.
   LOCAL lSupressline    := .F.
   LOCAL cHarbourFlags   := ""
   LOCAL cObjDir         := s_cObjDir + space( 20 )
   LOCAL lCompMod        := .F.
   LOCAL lInstallLib     := .F.
   LOCAL x
   LOCAL y
   LOCAL nPos
//   LOCAL lGenppo         := .F.
   LOCAL GetList         := {}
   LOCAL cItem           := ""
   LOCAL cExt            := ""
   LOCAL cDrive          := ""
   LOCAL cPath           := ""
   LOCAL cTest           := ""
   LOCAL cLast           := ''
   LOCAL nWriteFiles     := 0
   LOCAL aUserDefs
   LOCAL cCurrentDef     := ""
   LOCAL cBuild          := " "
   LOCAL lCancelMake     := .F.
   LOCAL nOption      
   LOCAL lNew            := .F.
   LOCAL oMake
   LOCAL cAllRes         := ""
   LOCAL cTemp

   IF nLenaSrc == 0 .AND. !s_lRecursive
      IF s_nLang == 1 // Portuguese-BR
         s_cAlertMsg := "N�o h� prg na pasta "+curdir()
      ELSEIF s_nLang == 3 // Spanish
         s_cAlertMsg := "No hay ning�n prg en la carpeta "+curdir()
      ELSE
         s_cAlertMsg := "Have not any prg in "+curdir()+" folder."
      ENDIF
      Alert( s_cAlertMsg )
      RETURN NIL
   ENDIF


   IF File( cFile )

      CLS

      IF s_nLang == 1 // Portuguese-BR
         nOption := Alert( "O makefile <" + cFile +"> j� existe.",{ "Editar", "Criar Novo" , "Cancelar" } )
      ELSEIF s_nLang == 3 // Spanish
         nOption := Alert( "Lo makefile <" + cFile +"> ya existe.",{ "Editar", "Crear Nuevo" , "Cancelar" } )
      ELSE // English
         nOption := Alert( "The makefile <" + cFile +"> already exist ",{ "Edit" , "Create New" , "Cancel" } )
      ENDIF


      IF nOption = 1 // edit makefile


         // Verify if "cFile" can be openned to write mode.

         s_nMakeFileHandle := FOpen( cFile, FO_WRITE )

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser aberto para edi��o."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser abierto para edici�n."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be openned for edition."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+LTrim(Str(FError()))+")" )

            RETURN NIL
         else
            FClose( s_nMakeFileHandle )
         endif

         oMake :=ThbMake():new()
         oMake:cMakefile:=cFile
         oMake:ReadMakefile(cFile)
         FRename(cFile,cFile+".old")

         IF LEN(oMake:aRes) >0
            FOR EACH cTemp IN oMake:aRes
                cAllRes += cTemp+ " "
            NEXT
         ENDIF

         lAutoMemVar     := oMake:lAutomemvar
         lVarIsMemVar    := oMake:lVarIsMemvar
         lDebug          := oMake:ldebug
         lSupressline    := oMake:lSupressline
         lCompMod        := oMake:lCompMod
         s_lGenppo       := oMake:lGenppo
         lInstallLib     := oMake:lInstallLib
         s_cUserInclude  := PadR(oMake:cUserInclude,200," ")
         s_cUserDefine      := PadR(oMake:cUserDef,200," ")
         if !empty(oMake:cFmc)
             cLibName    := PadR(oMake:cFmc,200)
         endif


         if !s_lRecursive
            s_lRecursive := oMake:lRecurse
         endif


         IF nLenaSrc == 0 .and. !s_lRecursive 

            CLS

            IF s_nLang=1 // PT-BR
               s_cAlertMsg := "N�o h� nenhum prg na pasta "+CurDir()+". Use o modo recursivo -r" 
            ELSEIF s_nLang=3 // Spanish
               s_cAlertMsg := "No hay ning�n prg en la carpeta "+CurDir()+". Use lo modo recursivo -r"
            ELSE
               s_cAlertMsg := "Does not have any prg in "+CurDir()+" folder. Use the recursive mode -r"
            ENDIF

            Alert( s_cAlertMsg )

            SetColor("W/N,N/W")
            CLS
            set cursor on
            QUIT

         ENDIF

         if s_lCancelRecursive
            s_lRecursive := .F.
         endif

         // after oMake read, recreate other clean makefile to edit.
         s_nMakeFileHandle := FCreate(cFile)

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser aberto para edi��o."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser abierto para edici�n."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be openned for edition."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

            RETURN NIL

         endif

         WriteMakeFileHeader()

         s_lEditMake := .T.


      ELSEIF nOption = 2 // create a new makefile


         IF nLenaSrc == 0 .and. !s_lRecursive 

            CLS

            IF s_nLang=1 // PT-BR
               s_cAlertMsg := "N�o h� nenhum prg na pasta "+CurDir()+". Use o modo recursivo -r" 
            ELSEIF s_nLang=3 // Spanish
               s_cAlertMsg := "No hay ning�n prg en la carpeta "+CurDir()+". Use lo modo recursivo -r"
            ELSE
               s_cAlertMsg := "Does not have any prg in "+CurDir()+" folder. Use the recursive mode -r"
            ENDIF

            Alert( s_cAlertMsg )
            SetColor("W/N,N/W")
            CLS
            set cursor on
            QUIT

         ENDIF

         s_lEditMake := .F.

         s_nMakeFileHandle := FCreate( cFile )

         if s_nMakeFileHandle = F_ERROR

            CLS

            IF s_nLang = 1      // brazilian portuguese
               s_cAlertMsg := "<"+cFile + "> n�o pode ser criado."
            ELSEIF s_nLang = 3  // spanish
               s_cAlertMsg := "<"+cFile + "> no pode ser criado."
            ELSE                // english
               s_cAlertMsg := "<"+cFile + "> cannot be created."
            ENDIF

            Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

            RETURN NIL

         endif

         WriteMakeFileHeader()
         lNew := .T.

      ELSE
         SetColor("W/N,N/W")
         CLS
         set cursor on
         QUIT
      ENDIF

   ELSE

      s_nMakeFileHandle := FCreate( cFile )

      if s_nMakeFileHandle = F_ERROR

         CLS

         IF s_nLang = 1      // brazilian portuguese
            s_cAlertMsg := "<"+cFile + "> n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := "<"+cFile + "> no pode ser criado."
         ELSE                // english
            s_cAlertMsg := "<"+cFile + "> cannot be created."
         ENDIF

         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )

         RETURN NIL

      ENDIF

      WriteMakeFileHeader()
      nOption := 2  // create a new makefile
      lNew := .T.

   ENDIF

   CLS
   Setcolor( 'w/b+,b+/w,w+/b,w/b+,w/b,w+/b' )
   @  0,  0, Maxrow(), Maxcol() BOX( Chr( 201 ) + Chr( 205 ) + Chr( 187 ) + Chr( 186 ) + Chr( 188 ) + Chr( 205 ) + Chr( 200 ) + Chr( 186 ) + Space( 1 ) )
//   Attention( s_aLangMessages[ 27 ], 0 )
   Attention( HbMake_Id() + space(10)+s_aLangMessages[ 27 ], 0 )

   SET CURSOR OFF

   @ 01,01 SAY s_aLangMessages[ 28 ]
   @ 01,17,06,24 get cOS listbox { "Win32", "OS/2", "Linux" } message s_aLangMessages[ 49 ] state OsSpec(getlist,1,@cOS)  DROPDOWN
   @ 01,30 SAY s_aLangMessages[ 29 ]
   @ 01,54,06,59 get cCompiler listbox { "BCC", "MSVC", "GCC","MINGW" }  message s_aLangMessages[ 50 ] state OsSpec(getlist,2,@cCompiler) DROPDOWN

   @ 03,01 SAY s_aLangMessages[ 59 ] GET cLibName PICT "@s15" message s_aLangMessages[ 58 ]
   @ 03,35 SAY s_aLangMessages[ 60 ] GET cObjDir  PICT "@s15"

   Attention( "xHarbour Options", 5 )

   @ 06,01 GET lAutoMemvar   checkbox caption s_aLangMessages[ 32 ] style "[X ]"
   @ 06,40 GET lVarIsMemvar  checkbox caption s_aLangMessages[ 33 ] style "[X ]"
   @ 07,01 GET lDebug        checkbox caption s_aLangMessages[ 34 ] style "[X ]"
   @ 07,40 GET lSupressLine  checkbox caption s_aLangMessages[ 35 ] style "[X ]"
   @ 08,01 GET s_lGenppo     checkbox caption s_aLangMessages[ 36 ] style "[X ]"
   @ 08,40 GET lCompMod      checkbox caption s_aLangMessages[ 37 ] style "[X ]"
   @ 09,01 SAY s_aLangMessages[ 38 ] GET s_cUserDefine PICT "@s23"
   @ 09,40 SAY s_aLangMessages[ 39 ] GET s_cUserInclude PICT "@s18"
   @ 10,01 GET lInstallLib   checkbox caption s_aLangMessages[ 61 ] style "[X ]"

   READ MSG AT MaxRow() - 1, 1, MaxCol() - 1

// SET CURSOR ON

   IF ! Empty( s_cUserDefine )
      aUserDefs := ListasArray2(Alltrim( s_cUserDefine ), ";")

      FOR EACH cCurrentDef in aUserDefs
         cHarbourFlags += " -D" + Alltrim( cCurrentDef ) + " "
      NEXT
   ENDIF

   IF ! Empty( s_cUserInclude )
      cHarbourFlags += " -I" + Alltrim( s_cUserInclude ) + " "
   ENDIF

   s_lBcc   :=  "BCC"  IN cCompiler
   s_lMSVcc :=  "MSVC" IN cCompiler
   s_lGcc   :=  "GCC"  IN cCompiler
   s_lPcc   :=  "POCC" IN cCompiler
   s_lMingw :=  "MINGW" IN cCompiler
   if s_lMingw
   s_lGcc := .T.
   endif
   cObjDir := Alltrim( cObjDir )

   IF ! Empty( cObjDir )

      IF !IsDirectory( cObjDir )
         MakeDir( cObjDir )
      ENDIF

   ENDIF

   s_aMacros := GetSourceDirMacros( s_lGcc, cOS )

   IF s_lGcc
      cObjDir := Alltrim( cObjDir )

      IF ! Empty( cObjDir )
         cObjDir += '/'
      ENDIF

      cTest := cObjDir + '/'
   ELSE
      cObjDir := Alltrim( cObjDir )

      IF ! Empty( cObjDir )
         cObjDir += '\'
      ENDIF

      cTest := cObjDir + '\'
   ENDIF

   AEval( s_aMacros, { | x, y | cItem := Substr( x[ 2 ], 1, Len( x[ 2 ] ) ), IIF( At( citem, cTest ) > 0, ( s_aMacros[ y, 1 ] := 'OBJ', s_aMacros[ y, 2 ] := cObjDir ), ) } )

   IF lAutoMemvar
      cHarbourFlags += " -a "
   ENDIF

   IF lVarIsMemvar
      cHarbourFlags += " -v "
   ENDIF

   IF lDebug
      cHarbourFlags += " -b "
   ENDIF

   IF lSupressline
      cHarbourFlags += " -l "
   ENDIF

   IF s_lGenppo
      cHarbourFlags += " -p "
   ENDIF

   IF lCompmod
      cHarbourFlags += " -m "
   ENDIF

   IF s_lBcc
      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\BIN\bcc32 $(CFLAG1) $(CFLAG2) -o$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\BIN\bcc32 -I$(BHC)\include $(CFLAG1) $(CFLAG2) -o$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -n -go -I$(BHC)\include $(HARBOURFLAGS) -I$(FWH)\include -o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS) -I$(FWH)\include -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\BIN\brcc32 $(RFLAGS) $<" } )

   ELSEIF s_lGcc

      IF  "linux" IN Lower( Getenv( "HB_ARCHITECTURE" ) )  .OR. cOS == "Linux"
         AAdd( s_aCommands, { ".cpp.o:", "gcc $(CFLAG1) $(CFLAG2) -o$* $**" } )
         AAdd( s_aCommands, { ".c.o:", "gcc -I/usr/include/xharbour $(CFLAG1) $(CFLAG2) -I. -o$* $**" } )

         IF s_lExtended
            AAdd( s_aCommands, { ".prg.o:", "harbour -n $(HARBOURFLAGS) -I/usr/include/xharbour -I. -go  -o$* $**" } )
         ELSE
            AAdd( s_aCommands, { ".prg.c:", "harbour -n $(HARBOURFLAGS) -I/usr/include/xharbour -I.  -o$* $**" } )
         ENDIF

      ELSE
         AAdd( s_aCommands, { ".cpp.o:", "$(BCB)\bin\gcc $(CFLAG1) $(CFLAG2) -o$* $**" } )
         AAdd( s_aCommands, { ".c.o:", "$(BCB)\bin\gcc -I$(BHC)/include $(CFLAG1) $(CFLAG2) -I. -o$* $**" } )

         IF s_lExtended
            AAdd( s_aCommands, { ".prg.o:", "$(BHC)\bin\harbour -n -go -I$(BHC)/include $(HARBOURFLAGS)  -o$* $**" } )
         ELSE
            AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)/include $(HARBOURFLAGS)  -o$* $**" } )
         ENDIF

      ENDIF

   ELSEIF s_lMSVcc
      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\bin\cl $(CFLAG1) $(CFLAG2) -Fo$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\bin\cl -I$(BHC)\include $(CFLAG1) $(CFLAG2) -Fo$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -go -n -I$(BHC)\include $(HARBOURFLAGS) -I$(C4W)\include -o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS) -I$(C4W)\include -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\BIN\rc $(RFLAGS) $<" } )

   ELSEIF s_lPcc
      AAdd( s_aCommands, { ".cpp.obj:", "$(BCB)\BIN\pocc $(CFLAG1) $(CFLAG2) -Fo$* $**" } )
      AAdd( s_aCommands, { ".c.obj:", "$(BCB)\BIN\pocc -I$(BHC)\include $(CFLAG1) $(CFLAG2) -Fo$* $**" } )

      IF s_lExtended
         AAdd( s_aCommands, { ".prg.obj:", "$(BHC)\bin\harbour -n -go -I$(BHC)\include $(HARBOURFLAGS) -I$(FWH)\include -o$* $**" } )
      ELSE
         AAdd( s_aCommands, { ".prg.c:", "$(BHC)\bin\harbour -n -I$(BHC)\include $(HARBOURFLAGS) -I$(FWH)\include -o$* $**" } )
      ENDIF

      AAdd( s_aCommands, { ".rc.res:", "$(BCB)\BIN\brcc32 $(RFLAGS) $<" } )

   ENDIF


   if s_nLang=1
      s_cAlertMsg := "Selecione os PRGs a compilar"
   elseif s_nLang=3
      s_cAlertMsg := "Seleccione los PRG a compilar"
   else
      s_cAlertMsg := "Select the PRG files to compile"
   endif

   aInFiles := GetSourceFiles( s_lRecursive, s_lGcc, cOS )

   nLenaSrc := Len( aInFiles )

   aOutFiles := aClone( aInFiles )


   IF nOption !=2 // not create a makefile
      pickarry( 10, 15, 19, 64, aInFiles, aOutFiles, ArrayAJoin( { oMake:aPrgs, oMake:aCs } ), .T., s_cAlertMsg )
   ELSE
      pickarry( 10, 15, 19, 64, aInFiles, aOutFiles, {}, .T., s_cAlertMsg )
   ENDIF


   AEval( aOutFiles, { | x, y | aOutFiles[ y ] := Trim( Substr( aOutFiles[ y ], 1, At( ' ', aOutFiles[ y ] ) ) ) } )
   AEval( aOutFiles, { | xItem | IIF( At( '.c', xItem ) > 0 .OR. At( '.C', xItem ) > 0 .OR. At( '.cpp', xItem ) > 0 .OR. At( '.CPP', xItem ) > 0, AAdd( aOutc, xitem ), ) } )
   AEval( aOutc, { | x, z | citem := x, z := AScan( aOutFiles, { | t | t = citem } ), IIF( z > 0, aSize( aDel( aOutFiles, z ), Len( aOutFiles ) - 1 ), ) } )

   aOutFiles  := aSort( aOutFiles )
   s_aPrgs := aClone( aOutFiles )

   s_aObjs := aClone( aOutFiles )
   AEval( s_aObjs, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, s_aObjs[ x ] := cObjDir + cTest + "." + Exte( cExt, 2 ), s_aObjs[ x ] := cObjDir + cTest + "." + Exte( cExt, 3 ) ) } )
   s_aCs := aClone( aOutc )

   IF ! s_lExtended
      AEval( aOutc, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, AAdd( s_aObjs, cObjDir + cTest + "." + Exten( cExt, 2 ) ), AAdd( s_aObjs, cObjDir + cTest + "." + Exten( cExt, 1 ) ) ) } )
      AEval( aOutFiles, { | xItem | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cExt := Substr( cExt, 2 ), AAdd( s_aCs, cObjDir + cTest + "." + Exte( cExt, 1 ) ) } )
   ELSE
      s_aObjsc := aClone( aOutc )
      AEval( aOutc, { | xItem, x | hb_FNAMESPLIT( xiTem, @cPath, @cTest, @cExt, @cDrive ), cext := Substr( cExt, 2 ), IIF( ! s_lGcc, s_aObjsc[ x ] := cObjDir + cTest + "." + Exten( cExt, 2 ), s_aObjsc[ x ] := cObjDir + cTest + "." + Exten( cExt, 1 ) ) } )
   ENDIF

   FOR x := 1 TO Len( s_aMacros )

      IF ! Empty( s_aMacros[ x, 2 ] )
         cItem := s_aMacros[ x, 2 ]
         nPos  := AScan( s_aPrgs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0
            AEval( s_aPrgs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aPrgs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )

            IF ! s_aMacros[ x, 3 ]
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
               s_aMacros[ x, 3 ] := .T.
            ENDIF

         ENDIF

         nPos := AScan( s_aCs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0
            AEval( s_aCs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aCs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )

            IF ! s_aMacros[ x, 3 ]
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
               s_aMacros[ x, 3 ] := .T.
            ENDIF

         ENDIF

         nPos := AScan( s_aObjs, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

         IF nPos > 0

            IF ! Empty( cObjDir )
               AEval( s_aObjs, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aObjs[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )
               FWrite( s_nMakeFileHandle, s_aMacros[ x, 1 ] + ' = ' + Left( s_aMacros[ x, 2 ], Len( s_aMacros[ x, 2 ] ) - 1 ) + " " + CRLF )
            ENDIF

         ENDIF

         IF s_lExtended
            nPos := AScan( s_aObjsc, { | z | hb_FNAMESPLIT( z, @cPath, @cTest, @cExt, @cDrive ), cPath == citem } )

            IF nPos > 0

               IF ! Empty( cObjDir )
                  AEval( s_aObjsc, { | a, b | hb_FNAMESPLIT( a, @cPath, @cTest, @cExt, @cDrive ), IIF( cPath == citem, s_aObjsc[ b ] := Strtran( a, cPath, "$(" + s_aMacros[ x, 1 ] + IIF( s_lGcc, ")/", ')\' ) ), ) } )
               ENDIF

            ENDIF

         ENDIF

      ENDIF

   NEXT

   IF s_lGcc

      IF  "linux" IN Lower( Getenv( "HB_ARCHITECTURE" ) ) .OR. cOS == "Linux"
         FWrite( s_nMakeFileHandle, "PROJECT = " + IIF( lInstallLib, "$(BHC)/lib/", "" ) + Alltrim( cLibName ) + ".a " + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "PROJECT = " + IIF( lInstallLib, "$(BHC)\lib\", "" ) + Alltrim( Lower( cLibName ) ) + ".a " + CRLF )
      ENDIF

   ELSE
      FWrite( s_nMakeFileHandle, "PROJECT = " + IIF( lInstallLib, "$(BHC)\lib\", "" ) + Alltrim( Lower( cLibName ) ) + ".lib " + CRLF )
   ENDIF

   IF ! s_lExtended
      nWriteFiles := 0
      FWrite( s_nMakeFileHandle, "OBJFILES =" )

      IF Len( s_aObjs ) < 1
         FWrite( s_nMakeFileHandle, + " $(OB) " + CRLF )
      ELSE
         nWriteFiles := 0
         AEval( s_aObjs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aObjs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OB) " + CRLF ) ) } )
      ENDIF

      nWriteFiles := 0
      FWrite( s_nMakeFileHandle, "CFILES =" )

      IF Len( s_aCs ) < 1
         FWrite( s_nMakeFileHandle, + " $(CF)" + CRLF )
      ELSE
         AEval( s_aCs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aCs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(CF) " + CRLF ) ) } )
      ENDIF

      FWrite( s_nMakeFileHandle, "PRGFILE =" )
      nWriteFiles := 0

      IF Len( s_aPrgs ) < 1
         FWrite( s_nMakeFileHandle, + " $(PS)" + CRLF )
      ELSE
         AEval( s_aPrgs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aPrgs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(PS) " + CRLF ) ) } )
      ENDIF

   ELSE /****extended moded ****/
      FWrite( s_nMakeFileHandle, "OBJFILES =" )
      nWriteFiles := 0

      IF Len( s_aObjs ) < 1
         FWrite( s_nMakeFileHandle, + " $(OB) " + CRLF )
      ELSE
         AEval( s_aObjs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aObjs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OB) " + CRLF ) ) } )
      ENDIF

      FWrite( s_nMakeFileHandle, "PRGFILES =" )
      nWriteFiles := 0

      IF Len( s_aPrgs ) < 1
         FWrite( s_nMakeFileHandle, + " $(PS)" + CRLF )
      ELSE
         AEval( s_aPrgs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aPrgs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(PS) " + CRLF ) ) } )
      ENDIF

      nWriteFiles := 0

      IF Len( s_aObjsc ) > 0
         FWrite( s_nMakeFileHandle, "OBJCFILES =" )

         IF Len( s_aObjsc ) < 1
            FWrite( s_nMakeFileHandle, + " $(OBC) " + CRLF )
         ELSE
            AEval( s_aObjsc, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aObjsc ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(OBC) " + CRLF ) ) } )
         ENDIF

      ENDIF

      nWriteFiles := 0

      IF Len( s_aCs ) > 0
         FWrite( s_nMakeFileHandle, "CFILES =" )

         IF Len( s_aCs ) < 1
            FWrite( s_nMakeFileHandle, + " $(CF)" + CRLF )
         ELSE
            AEval( s_aCs, { | x, i | nWriteFiles ++, IIF( i <> Len( s_aCs ), FWrite( s_nMakeFileHandle, ' ' + Alltrim( x ) + IIF( nWriteFiles % 10 == 0, " //" + CRLF, "" ) ), FWrite( s_nMakeFileHandle, " " + Alltrim( x ) + " $(CF) " + CRLF ) ) } )
         ENDIF

      ENDIF

   ENDIF

   FWrite( s_nMakeFileHandle, "RESFILES =" + CRLF )
   FWrite( s_nMakeFileHandle, "RESDEPEN = $(RESFILES)" + CRLF )
   FWrite( s_nMakeFileHandle, "DEFFILE = " + CRLF )
   FWrite( s_nMakeFileHandle, "HARBOURFLAGS = " + cHarbourFlags + CRLF )
   FWrite( s_nMakeFileHandle, "INSTALLLIB = " + IIF( lInstallLib, "YES","NO" ) + CRLF )
   FWrite( s_nMakeFileHandle, "USERDEFINE = " + alltrim(s_cUserDefine) + CRLF )
   FWrite( s_nMakeFileHandle, "USERINCLUDE = " + alltrim(s_cUserInclude) + CRLF )

   IF s_lBcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -OS $(CFLAGS) -d -L$(BHC)\lib;$(FWH)\lib -c" + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 =  -I$(BHC)\include -I$(BCB)\include -I" + Alltrim( s_cUserInclude ) + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = /P32 /0" + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = tlib $(LFLAGS) $(PROJECT)" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ =  $(OBJFILES) $(OBJCFILES)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = " + CRLF )
      FWrite( s_nMakeFileHandle, ".autodepend" + CRLF )

   ELSEIF s_lMSVcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -I$(INCLUDE_DIR) -TP -W3 -nologo $(C_USR) $(CFLAGS)" + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 =  -c -I" + Alltrim( s_cUserInclude ) + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = lib $(PROJECT)" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = $(OBJFILES) $(OBJCFILES) " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = " + CRLF )

   ELSEIF s_lPcc

      FWrite( s_nMakeFileHandle, "CFLAG1 =  -I$(INCLUDE_DIR) -Tx86-coff -W1 $(C_USR) $(CFLAGS)" + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 = " + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LINKER = lib $(PROJECT)" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = $(OBJFILES) $(OBJCFILES) " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN)" + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = " + CRLF )

   ELSEIF s_lGcc

      FWrite( s_nMakeFileHandle, "CFLAG1 = " + IIF( s_lLinux , "-I/usr/include/xharbour", " -I$(BHC)/include" ) + " -c -Wall" + CRLF )
      FWrite( s_nMakeFileHandle, "CFLAG2 = " + IIF( s_lLinux , "-L /usr/lib/xharbour", " -L $(BHC)/lib" ) + CRLF )
      FWrite( s_nMakeFileHandle, "RFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "LFLAGS = " + CRLF )
      FWrite( s_nMakeFileHandle, "IFLAGS = " + CRLF )

      IF "linux" IN Lower( Getenv( "HB_ARCHITECTURE" ) )  .OR. cOS == "Linux" .OR. s_lLinux
         FWrite( s_nMakeFileHandle, "LINKER = ar -M " + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "LINKER = ar -M " + CRLF )
      ENDIF

      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLOBJ = $(OBJFILES) $(OBJCFILES) " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLRES = $(RESDEPEN) " + CRLF )
      FWrite( s_nMakeFileHandle, "ALLLIB = $(LIBFILES) " + CRLF )
      FWrite( s_nMakeFileHandle, ".autodepend" + CRLF )

   ENDIF

   FWrite( s_nMakeFileHandle, " " + CRLF )
   FWrite( s_nMakeFileHandle, "#COMMANDS" + CRLF )
   AEval( s_aCommands, { | xItem | FWrite( s_nMakeFileHandle, xitem[ 1 ] + CRLF ), FWrite( s_nMakeFileHandle, xitem[ 2 ] + CRLF ), FWrite( s_nMakeFileHandle, " " + CRLF ) } )

   IF s_lBcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&!" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ)" + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ELSEIF s_lMSVcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, "" + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&!" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ) " + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ELSEIF s_lPcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, "" + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES)" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(BCB)\BIN\$(LINKER) @&&!" + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ) " + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ELSEIF s_lGcc

      FWrite( s_nMakeFileHandle, "#BUILD" + CRLF )
      FWrite( s_nMakeFileHandle, " " + CRLF )
      FWrite( s_nMakeFileHandle, "$(PROJECT): $(CFILES) $(OBJFILES) " + CRLF )

      IF  "linux" IN Lower( Getenv( "HB_ARCHITECTURE" ) )  .OR. cOS == "Linux"
         FWrite( s_nMakeFileHandle, "    $(LINKER) @&&!" + CRLF )
      ELSE
         FWrite( s_nMakeFileHandle, "    $(BCB)\bin\$(LINKER) @&&!" + CRLF )
      ENDIF

      FWrite( s_nMakeFileHandle, "    $(PROJECT) " + CRLF )
      FWrite( s_nMakeFileHandle, "    $(ALLOBJ)  " + CRLF )
      FWrite( s_nMakeFileHandle, "!" + CRLF )

   ENDIF

   FClose( s_nMakeFileHandle  )

   IF !lCancelMake

      IF s_nLang == 1 .OR. s_nLang == 3
        s_cAlertMsg := "Compilar lib ? (S/N) "
      ELSE // English
        s_cAlertMsg := "Build lib ? (Y/N) "
      ENDIF

      @ 20,5 Say s_cAlertMsg Get cBuild PICT "!" Valid cBuild $ iif(s_nLang=2,"YN","SN")
      READ

      IF cBuild == "S" .OR. cBuild == "Y"
         ResetInternalVars()
         SetColor("W/N,N/W")
         Clear
         SetPos(9,0)
         Main( cFile, " -f "+iif(s_nLang=1,"-lPT",iif(s_nLang=3,"-lES","-lEN")) )
      ELSE
         set cursor on
         SetColor("W/N,N/W")
         Clear
      ENDIF

   ELSE
      set cursor on
      SetColor("W/N,N/W")
      Clear
   ENDIF

RETURN NIL

*---------------------
FUNCTION SetLibBuild()
*---------------------

   LOCAL cRead as String
   LOCAL nPos as Numeric
   LOCAL aMacro as Array
   LOCAL aTemp as Array
   LOCAL nCount as Numeric
   LOCAL aCurobjs as Array
   LOCAL nObjPos as Numeric
   LOCAL cLib

   cRead := Alltrim( readln( @s_lEof ) )
   s_nMakeFileHandle := FCreate( s_cMakeFileName )

   if s_nMakeFileHandle = F_ERROR
      IF s_nLang = 1      // brazilian portuguese 
         s_cAlertMsg := "<"+s_cMakeFileName + "> n�o pode ser criado."
      ELSEIF s_nLang = 3  // spanish
         s_cAlertMsg := "<"+s_cMakeFileName + "> no pode ser criado."
      ELSE                // english
         s_cAlertMsg := "<"+s_cMakeFileName + "> cannot be created."
      ENDIF
      Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
      RETURN NIL
   endif

   s_szProject   := cRead
   aMacro      := ListAsArray2( cRead, ":" )

   IF Len( aMacro ) > 1
      aTemp := ListAsArray2( aMacro[ 2 ], " " )
      AEval( aTemp, { | xItem | AAdd( s_aBuildOrder, xItem ) } )
   ENDIF

   AAdd( s_aBuildOrder, aMacro[ 1 ] )
   cRead  := Strtran( cRead, "@&&!", "" )
   aMacro := ListAsArray2( cRead, '\' )
   AEval( aMacro, { | xMacro | Findmacro( xMacro, @cRead ) } )

   IF s_lBcc .OR. s_lMSVcc .OR. s_lPcc
      s_cLinkCommands := cRead + "  @" + s_cMakeFileName
   ELSE
      s_cLinkCommands := cRead + " < " + s_cMakeFileName
   ENDIF

   FOR nPos := 1 TO 7
      cRead  := Alltrim( readln( @s_lEof ) )
      aMacro := ListAsArray2( cRead, " " )

      FOR ncount := 1 TO Len( aMacro )

         IF  "$" IN aMacro[ nCount ]

            IF ( aMacro[ nCount ] = "$(PROJECT)" ) .AND. s_lGcc

               Findmacro( aMacro[ nCount ], @cRead )
               FWrite( s_nMakeFileHandle, "CREATE " + " lib" + cRead + CRLF )
               cLib := "lib" + cRead

            ELSEIF ( aMacro[ nCount ] == "$(ALLOBJ)" )

               Findmacro( aMacro[ nCount ], @cRead )
               aCurObjs := ListAsArray2( cRead, " " )

               FOR nObjPos := 1 TO Len( aCurObjs )

                  IF s_lGcc
                     FWrite( s_nMakeFileHandle, "ADDMOD " + aCurObjs[ nObjPos ] + CRLF )
                  ENDIF

                  IF s_lBcc .OR. s_lMSVcc .OR. s_lPcc

                     IF nObjPos < Len( aCurObjs )
                        FWrite( s_nMakeFileHandle, "+-" + aCurObjs[ nObjPos ] + " &" + CRLF )
                     ELSE
                        FWrite( s_nMakeFileHandle, "+-" + aCurObjs[ nObjPos ] + CRLF )
                     ENDIF

                  ENDIF

               NEXT

            ENDIF

         ENDIF

      NEXT

   NEXT

   IF s_lGcc
      FWrite( s_nMakeFileHandle, "SAVE" + CRLF )
      FWrite( s_nMakeFileHandle, "END " + CRLF )
   ENDIF

   FClose( s_nMakeFileHandle )

   IF s_lLinux
      s_cLinkCommands += " || rm -f " + cLib
   ENDIF

RETURN NIL

*---------------------------------
FUNCTION FindCfile( citem, aSrcc )
*---------------------------------
 LOCAL nReturnPos := 0

 nReturnPos := AScan( aSrcc, { | x | Lower( x[ 1 ] ) == cItem } )

RETURN nReturnPos

/*
#IFNDEF __HARBOUR__
FUNCTION Hb_OsNewLine()
   RETURN Chr( 13 ) + Chr( 10 )
#ENDIF
*/

*----------------------------
FUNCTION CheckIFfile( cFile )
*----------------------------

   LOCAL cNextLine := ''
   LOCAL cCommand  := ''
   LOCAL cTemp

   cTemp := Substr( cFile, At( " ", cFile ) + 1 )

   IF File( cTemp )
      cNextLine := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

      IF  "!" IN  cNextLine
         cCommand := Substr( cNextLine, At( ' ', cNextLine ) + 1 )
         RUN( cCommand )
      ENDIF

      RETURN .T.

   ENDIF

RETURN .F.

*----------------------------
FUNCTION Checkstdout( cText )
*----------------------------

   cText := Strtran( cText, "!stdout", "" )
   Outstd( cText )

RETURN NIL

*---------------------------
FUNCTION CheckIFdef( cTemp )
*---------------------------

   LOCAL nPos
   LOCAL cRead    := ""
   LOCAL aSet     := {}
   LOCAL nMakePos

   IF cTemp == "!endif"
      RETURN NIL
   ENDIF

   WHILE At( "!endif", cRead ) == 0
      cRead := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

      IF  "!endif" IN cRead
         FT_FSKIP( - 1 )
         EXIT
      ENDIF

      cTemp := Strtran( cTemp, "!ifdef ", "" )

        IF  '=' IN cRead

         IF  "\.." IN cRead
            cRead := Substr( cRead, 1, At( "\..", cRead ) - 1 )
         ELSEIF  "/.." IN cRead
            cRead := Substr( cRead, 1, At( "/..", cRead ) - 1 )
         ENDIF

         aSet := ListAsArray2( cRead, "=" )
         nPos := AScan( s_aDefines, { | x | x[ 1 ] == cTemp } )

         IF nPos > 0
            cRead    := Alltrim( Strtran( aSet[ 1 ], "$(", "" ) )
            cRead    := Strtran( cRead, ")", "" )
            nMakePos := AScan( s_aMacros, { | x | x[ 1 ] == cRead } )

            IF nMakePos == 0
               AAdd( s_aMacros, { aSet[ 1 ], aSet[ 2 ] } )
            ENDIF

         ELSE /* Locate For !ELSE    */

            WHILE At( "!endif", cRead ) == 0
               cRead := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

               IF  "!ELSE" IN cRead

                  WHILE At( "!endif", cRead ) == 0
                     cRead := Trim( Substr( ReadLN( @s_lEof ), 1 ) )

                     IF  "!endif" IN cRead
                        FT_FSKIP( - 1 )
                        EXIT
                     ENDIF

                     aSet := ListAsArray2( cRead, "=" )
                     AAdd( s_aMacros, { aSet[ 1 ], aSet[ 2 ] } )
                   ENDDO

               ENDIF

            ENDDO

         ENDIF

      ELSEIF '!stdout' IN cRead
         Checkstdout( cRead )
      ENDIF

   ENDDO

RETURN NIL

*-------------------------
FUNCTION BuildBorCfgFile()
*-------------------------
LOCAL cCfg := GetHarbourDir() + '\bin\'+s_cHbCfgFileName
LOCAL nCfg

   IF !File( cCfg ) .or. s_lForce 

      nCfg := FCreate( cCfg )

      if nCfg = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := cCfg + " n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := cCfg + " no pode ser criado."
         ELSE                // english
            s_cAlertMsg := cCfg + " cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

      FWrite( nCfg, "CC=BCC32" + CRLF )
//    FWrite( nCfg, "CFLAGS= -c " + Replacemacros( "-I$(BHC)\include -OS $(CFLAGS) -d -L$(BHC)\lib" ) + CRLF )
      FWrite( nCfg, "CFLAGS= -c -D__EXPORT__ " + Replacemacros( "-I$(BHC)\include $(CFLAGS) -d -L$(BHC)\lib" ) + CRLF )
      FWrite( nCfg, "VERBOSE=YES" + CRLF )
      FWrite( nCfg, "DELTMP=YES" + CRLF )
      FClose( nCfg )
   ENDIF

RETURN NIL

*-------------------------
FUNCTION BuildMscCfgFile()
*-------------------------
   LOCAL cCfg := GetHarbourDir() + '\bin\'+s_cHbCfgFileName
   LOCAL nCfg

   IF !File( cCfg )  .or. s_lForce

      nCfg := FCreate( cCfg )

      if nCfg = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := cCfg + " n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := cCfg + " no pode ser criado."
         ELSE                // english
            s_cAlertMsg := cCfg + " cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

      FWrite( nCfg, "CC=cl" + CRLF )
      FWrite( nCfg, "CFLAGS= -c -D__EXPORT__" + Replacemacros( "-I$(INCLUDE_DIR) -TP -W3 -nologo $(C_USR) $(CFLAGS)" ) + CRLF )
      FWrite( nCfg, "VERBOSE=YES" + CRLF )
      FWrite( nCfg, "DELTMP=YES" + CRLF )
      FClose( nCfg )
   ENDIF

RETURN NIL


*----------------------------
FUNCTION BuildPellesCfgFile()
*----------------------------
   LOCAL cCfg := GetHarbourDir() + '\bin\'+s_cHbCfgFileName
   LOCAL nCfg

   IF !File( cCfg )  .or. s_lForce

      nCfg := FCreate( cCfg )

      if nCfg = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := cCfg + " n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := cCfg + " no pode ser criado."
         ELSE                // english
            s_cAlertMsg := cCfg + " cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

      FWrite( nCfg, "CC=POCC" + CRLF )
      FWrite( nCfg, "CFLAGS= " + ReplaceMacros( "-I$(INCLUDE_DIR) -Tx86-coff -W1 $(C_USR) $(CFLAGS)" ) + CRLF )
      FWrite( nCfg, "VERBOSE=YES" + CRLF )
      FWrite( nCfg, "DELTMP=YES" + CRLF )
      FClose( nCfg )
   ENDIF

RETURN NIL



*-------------------------
FUNCTION BuildGccCfgFile()
*-------------------------
   LOCAL cCfg 
   LOCAL nCfg
   LOCAL cDir := GetHarbourDir()
   LOCAL cBhc := Alltrim( Strtran( replacemacros( '$(BHC)' ), '\', '/' ) )

   cDir := Strtran( cDir, '/', '\' )

   cCfg := cDir + '\bin\'+s_cHbCfgFileName

   IF !File( cCfg ) .or. s_lForce

      nCfg := FCreate( cCfg )

      if nCfg = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := cCfg + " n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := cCfg + " no pode ser criado."
         ELSE                // english
            s_cAlertMsg := cCfg + " cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

      FWrite( nCfg, "CC=gcc" + CRLF )
      FWrite( nCfg, "CFLAGS= -c -D__EXPORT__ " + Replacemacros( "-I" + cBhc + "/include $(C_USR)  -L" + cBhc + "/lib" ) + CRLF )
      FWrite( nCfg, "VERBOSE=YES" + CRLF )
      FWrite( nCfg, "DELTMP=YES" + CRLF )
      FClose( nCfg )
   ENDIF

RETURN NIL

*--------------------------
FUNCTION BuildGccCfgFileL()
*--------------------------
   LOCAL cCfg := '/etc/'+s_cHbCfgFileName
   LOCAL nCfg

   IF !File( cCfg )  .or. s_lForce

      nCfg := FCreate( cCfg )

      if nCfg = F_ERROR
         IF s_nLang = 1      // brazilian portuguese 
            s_cAlertMsg := cCfg + " n�o pode ser criado."
         ELSEIF s_nLang = 3  // spanish
            s_cAlertMsg := cCfg + " no pode ser criado."
         ELSE                // english
            s_cAlertMsg := cCfg + " cannot be created."
         ENDIF
         Alert( s_cAlertMsg+" FERROR ("+Ltrim(Str(FError()))+")" )
         RETURN NIL
      endif

      FWrite( nCfg, "CC=gcc" + CRLF )
      FWrite( nCfg, "CFLAGS= -c -I/usr/include/xharbour" + CRLF )
      FWrite( nCfg, "VERBOSE=YES" + CRLF )
      FWrite( nCfg, "DELTMP=YES" + CRLF )
      FClose( nCfg )
   ENDIF

RETURN NIL

*------------------------------
FUNCTION FindHarbourCfg( cCfg )
*------------------------------

   LOCAL cPath AS STRING := ''
   LOCAL lFound AS LOGICAL := .F.
   LOCAL cEnv AS STRING
   LOCAL aEnv as Array of String
   LOCAL lLinux :=  s_lLinux
   LOCAL nPos

   IF ! lLinux .OR. s_lOs2
      cEnv := Gete( "PATH" ) + ";" + Curdir()
      aEnv := ListAsArray2( cEnv, ";" )

      FOR nPos := 1 TO Len( aEnv )

         IF File( aEnv[ nPos ] + '\'+s_cHbCfgFileName )
            cPath  := aEnv[ nPos ]
            lFound := .T.
            EXIT
         ENDIF

      NEXT

   ELSE

      IF File( '/etc/'+s_cHbCfgFileName )
         lFound := .T.
         cPath  := '/etc/'+s_cHbCfgFileName
      ENDIF

      IF !lFound

         IF File( '/usr/local/etc/'+s_cHbCfgFileName )
            lFound := .T.
            cPath  := '/usr/local/etc/'+s_cHbCfgFileName
         ENDIF

      ENDIF

   ENDIF

   cCfg := cPath

RETURN lFound

*---------------------------
FUNCTION TestforPrg( cFile )
*---------------------------

   LOCAL aFiles AS ARRAY  := {}
   LOCAL cPath AS STRING  := ''
   LOCAL cTest AS STRING  := ""
   LOCAL cDrive AS STRING := ""
   LOCAL cExt AS STRING   := ""
   LOCAL cItem AS STRING  := ""
   LOCAL aDir AS ARRAY
   LOCAL nPos AS NUMERIC
   LOCAL nFiles AS NUMERIC

   hb_FNAMESPLIT( cFile, @cPath, @cTest, @cExt, @cDrive )

   cExt := Substr( cExt, 2 )
   aDir := Directory( cTest + '.*' )

   FOR nPos := 1 TO 7
      cItem := cTest + "." + Extenprg( cExt, nPos )
      AAdd( aFiles, cItem )
   NEXT

   FOR nFiles := 1 TO Len( aFiles )
      nPos := AScan( aDir, { | a | a[ 1 ] == aFiles[ nFiles ] } )

      IF nPos > 0
         AAdd( s_aPrgs, aFiles[ nFiles ] )
      ENDIF

   NEXT

RETURN NIL

*-------------------
FUNCTION GetGccDir()
*-------------------

   LOCAL cPath AS STRING := ''
   LOCAL cEnv AS STRING
   LOCAL aEnv AS Array of string
   LOCAL nPos as Numeric

   IF s_lLinux
      cPath := "."
   ELSE
      cEnv := Gete( "PATH" )
      aEnv := ListAsArray2( cEnv, ";" )

      FOR nPos := 1 TO Len( aEnv )

         IF File( aEnv[ nPos ] + '\gcc.exe' ) .OR. File( Upper( aEnv[ nPos ] ) + '\GCC.EXE' )
            cPath := aEnv[ nPos ]
            cPath := Left( cPath, Rat( '\', cPath ) - 1 )
            EXIT
         ENDIF

      NEXT

   ENDIF

RETURN cPath

*-------------------------------------------------------------
FUNCTION ConvertParams( cFile, aFile, p1, p2, p3, p4, p5, p6 )
*-------------------------------------------------------------

   LOCAL cParam := ""

   IF ! Empty( cFile )

      IF Left( cFile, 1 ) $ "- /?" .or. "credits" IN cFile
         cParam += cFile+" "
      ELSE
         cFile := cFile
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   IF ! Empty( p1 )

      IF Left( p1, 1 ) $ "- /?" .or. "credits" IN p1
         cParam += p1+" "
      ELSE
         cFile := p1
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   IF ! Empty( p2 )

      IF Left( p2, 1 ) $ "- /"
         cParam += p2+" "
      ELSE
         cFile := p2
         AAdd( aFile, cFile )
       ENDIF

   ENDIF

   IF ! Empty( p3 )

      IF Left( p3, 1 ) $ "- /"
         cParam += p3+" "
      ELSE
         cFile := p3
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   IF ! Empty( p4 )

      IF Left( p4, 1 ) $ "- /"
         cParam += p4+" "
      ELSE
         cFile := p4
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   IF ! Empty( p5 )

      IF Left( p5, 1 ) $ "- /"
         cParam += p5+" "
      ELSE
         cFile := p5
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   IF ! Empty( p6 )

      IF Left( p6, 1 ) $ "- /"
         cParam += p6+" "
      ELSE
         cFile := p6
         AAdd( aFile, cFile )
      ENDIF

   ENDIF

   cParam := Strtran( cParam, "/", "-" )
   cParam := Strtran( cParam, "-elx", "-ELX" )
   cParam := Strtran( cParam, "-el", "-ELX" )
   cParam := Strtran( cParam, "-ex", "-EX" )
   cParam := Strtran( cParam, "-e", "-EX" )
   cParam := Strtran( cParam, "-i", "-I" )
   cParam := Strtran( cParam, "-p", "-P" )
   cParam := Strtran( cParam, "-b", "-B" )
   cParam := Strtran( cParam, "-gl", "-GL" )
   cParam := Strtran( cParam, "-g", "-G" )
   cParam := Strtran( cParam, "-v", "-V" )
   cParam := Strtran( cParam, "-m", "-M" )
   cParam := Strtran( cParam, "-pc", "-PC" )
   cParam := Strtran( cParam, "-f", "-F" )
   cParam := Strtran( cParam, "-r", "-R" )
   cParam := Strtran( cParam, "-nr", "-NR" ) // cancel recursive search
   cParam := Strtran( cParam, "-l", "-L" )

   IF "-EX" IN cParam .OR. "-ELX" IN cParam
      IF "-ELX" IN cParam
         s_lLibrary := .T.
      ENDIF
   ENDIF

   IF "-L" IN cParam
      s_cDefLang := Substr( cParam, At( "-L", cParam ) + 2, 2 )
   ENDIF

RETURN cParam


*------------------------------------
FUNCTION ProcessParameters( cParams )
*------------------------------------

   LOCAL aDef
   
   // Force to recompile all sources
   IF "-F" IN cParams
      s_lForce := .T.
      cParams  := StrTran( cParams, "-F", "" )
   ENDIF


   // Recursive source search
   IF "-R" IN cParams
      s_lRecursive := .T.
      cParams      := StrTran( cParams, "-R", "" )
   ENDIF

   // cancel -R
   IF "-NR" IN cParams
      s_lRecursive := .F.
      s_lCancelRecursive := .T.
      cParams := StrTran( cParams, "-NR", "" )
   ENDIF

   // Use BCC like default C/C++
   IF "-B" IN cParams
      s_lBcc   := .T.
      s_lGcc   := .F.
      s_lMSVcc := .F.
      s_lPcc   := .F.
      s_lMingw := .F.
      cParams  := Strtran( cParams, "-B", "" )
   ENDIF

   // Use GCC like default C/C++ at Linux
   IF "-GL" IN cParams
      s_lBcc   := .F.
      s_lGcc   := .T.
      s_lMSVcc := .F.
      s_lPcc   := .F.
      s_lLinux := .T.
      s_lMingw := .F.
      cParams  := Strtran( cParams, "-GL", "" )
   ENDIF

   // Use GCC like default C/C++ at Windows
   IF "-G" IN cParams
      s_lBcc   := .F.
      s_lGcc   := .T.
      s_lMSVcc := .F.
      s_lPcc   := .F.
      s_lMingw := .F.
      cParams  := Strtran( cParams, "-G", "" )
   ENDIF

   // Use MS-VC like default C/C++
   IF "-V" IN cParams
      s_lBcc   := .F.
      s_lGcc   := .F.
      s_lMSVcc := .T.
      s_lPcc   := .F.
      cParams  := Strtran( cParams, "-V", "" )
   ENDIF

   // Use Pelles C like default C/C++
   IF "-PC" IN cParams
      s_lBcc   := .F.
      s_lGcc   := .F.
      s_lMSVcc := .F.
      s_lPcc   := .T.
      s_lMingw := .F.
      cParams  := Strtran( cParams, "-PC", "" )
   ENDIF
   IF "-M" IN cParams
      s_lBcc   := .F.
      s_lGcc   := .T.
      s_lMSVcc := .F.
      s_lPcc   := .F.
      s_lMingw := .T.
      cParams  := Strtran( cParams, "-M", "" )
   ENDIF

   // Ignore warnings
   IF "-I" IN cParams
      s_lIgnoreErrors := .T.
      cParams         := Strtran( cParams, "-I", "" )
   ENDIF

   // Print all commands and dependencies
   IF "-P" IN cParams
      s_lPrint := .T.
      cParams  := Strtran( cParams, "-P", "" )
   ENDIF

   // Define a macro.
   IF "-D" IN cParams
      cParams := "-D" + Strtran( cParams, "-D", ";" )
      cParams := Strtran( cParams, "-D;", "-D" )
      aDef    := ListAsArray2( Alltrim( Substr( cParams, 3 ) ), ";" )
      AEval( aDef, { | xDef | IIF( At( '=', xDef ) > 0, GetParaDefines( xDef ), ) } )
   ENDIF

   // Build a Library
   IF "-EL" IN cParams  .OR.  "-ELX" IN cParams

      IF At( "-ELX", cParams ) > 0
         cParams := Strtran( cParams, "-ELX", "" )
      ELSE
         cParams := Strtran( cParams, "-EL", "" )
      ENDIF

      s_lExtended := .T.
      s_lLibrary  := .T.
      s_cMakeFileName := "makelib.lnk"

   ENDIF

   // Build an application
   IF "-E" IN cParams .OR. "-EX" IN cParams

      IF "-EX" IN cParams
         cParams := Strtran( cParams, "-EX", "" )
      ELSE
         cParams := Strtran( cParams, "-E", "" )
      ENDIF

      s_lExtended := .T.

   ENDIF

RETURN NIL

*-----------------------------
FUNCTION WriteMakeFileHeader()
*-----------------------------

   FWrite( s_nMakeFileHandle, "#BCC" + CRLF )
   FWrite( s_nMakeFileHandle, "VERSION=BCB.01" + CRLF )
   FWrite( s_nMakeFileHandle, "!ifndef BCB" + CRLF )
   FWrite( s_nMakeFileHandle, "BCB = $(MAKEDIR)" + CRLF )
   FWrite( s_nMakeFileHandle, "!endif" + CRLF )
   FWrite( s_nMakeFileHandle, CRLF )
   FWrite( s_nMakeFileHandle, "!ifndef BHC" + CRLF )
   FWrite( s_nMakeFileHandle, "BHC = $(HMAKEDIR)" + CRLF )
   FWrite( s_nMakeFileHandle, "!endif" + CRLF )
   FWrite( s_nMakeFileHandle, " " + CRLF )
// FWrite( s_nMakeFileHandle, "RECURSE=" + IIF( s_lRecursive, " YES ", " NO " ) + CRLF )
// FWrite( s_nMakeFileHandle, " " + CRLF )

RETURN NIL

*-------------------------------
FUNCTION BuildLangArray( cLang )
*-------------------------------
LOCAL aLang := {}

   DEFAULT cLang TO "EN"

   AAdd( aLang, HbMake_Id() )

   IF cLang == "EN"

      AAdd( alang, "Syntax:  hbmake <cFile>.bc [options] - Example: hbmake hello.bc /ex")
      AAdd( aLang, "Options:  /e[x]   Create a new Makefile. If /ex is used it create a" )
      AAdd( aLang, "                  new make file in extended mode." )
      AAdd( aLang, "          /el[x]  Create a new Makefile. If /elx is used it create a")
      AAdd( aLang, "                  new make file to build a LIB in extended mode." )
      AAdd( aLang, "          /D      Define a macro." )
      AAdd( aLang, "          /p      Print all commands and depedencies." )
      AAdd( aLang, "          /b      Use BCC as C compiler" )
      AAdd( aLang, "          /g+     Use GCC as C compiler" )
      AAdd( aLang, "          /b+     Use BCC as C compiler" )
      AAdd( aLang, "          /g      Use GCC as C compiler" )
      AAdd( aLang, "          /gl     Use GCC as C compiler in Linux" )
      AAdd( aLang, "          /gl+    Use GCC as C compiler in Linux" )
      AAdd( aLang, "          /v      Use MSVC as C compiler" )
      AAdd( aLang, "          /f      Force recompiltion of all files" )
      AAdd( aLang, "          /i      Ignore errors returned by command" )
      AAdd( aLang, "          /r /nr  Activate recursive mode. /nr Deactivate recursive mode." )
      AAdd( aLang, "                  Note: /p and /D can be used together" )
      AAdd( aLang, "                        /r and /e[x]/el[x] can be used together")
      AAdd( aLang, "                  Options with + are the default values" )
      AAdd( aLang, "                  -D switch can accept multiple macros on the same line")
      AAdd( aLang, "                  or use one macro per -D switch" )
      AAdd( aLang, "                  /l[LANGID] Specify the language to be used on hbmake")
      AAdd( aLang, "                  LANGID= (EN/PT/ES). On Windows, the default will be the S.O.")
      AAdd( aLang, "                  language. On OS/2, FreeBSD and LINUX will be English." )
      AAdd( aLang, "Enviroment options" )
      AAdd( aLang, "Select the OS" )
      AAdd( aLang, "Select the C Compiler" )
      AAdd( aLang, "Graph Lib" )
      AAdd( aLang, "xHarbour Options" )
      AAdd( aLang, "Automatic memvar declaration /a" )
      AAdd( aLang, "Variables are assumed M-> /v" )
      AAdd( aLang, "Debug info /b" )
      AAdd( aLang, "Suppress line number information /l" )
      AAdd( aLang, "Generate pre-processed output /p" )
      AAdd( aLang, "compile module only /m" )
      AAdd( aLang, "User Defines " )
      AAdd( aLang, "User include Path" )
      AAdd( aLang, "Use External Libs" )
      AAdd( aLang, "<Spacebar>-Select <Enter>-Continue process <F5> Sel/Unsel All" )
      AAdd( aLang, "Warning level /w" )
      AAdd( aLang, "Numbers of source files per line on makefile" )
      AAdd( aLang, "Use Multi Thread Library" )
      AAdd( aLang, "Executable file name" )
      AAdd( aLang, "Warning Level /w" )
      AAdd( aLang, "<Tab>-Next <Sh-Tab>-Prev <Enter>-Sel <"+chr(24)+chr(25)+">-Change Sel <Spacebar>-Open Box")
      /* Messages Start Here */
      AAdd( aLang, "3rd Party Rdd")
      AAdd( aLang, "What OS you Use")
      AAdd( aLang, "What C compiler  you has")
      AAdd( aLang, "This app use Graphical libraries")
      AAdd( aLang, "Do you use 3rd Party Rdd")
      AAdd( aLang, "Compress this app")
      AAdd( aLang, "Compress the app after Linked(use upx)")
      AAdd( aLang, "Your app will be linked to user harbour.dll")
      AAdd( aLang, "Where the .obj/.o files will be generates")
      AAdd( aLang, "Inform executable name (without .exe extention)" )
      /* More messages for LIB build */
      AAdd( aLang, "Inform the lib name (without extension)")
      /* More xHarbour options for LIB build */
      AAdd( aLang, "Lib name:" )
      AAdd( aLang, "Obj dir files:" )
      AAdd( aLang, "Install the lib at the xHarbour lib folder" )
//      AAdd( aLang, "          /pc     Use POCC as C compiler" )
      AAdd( aLang, "          /m      use GCC(mingw) as C compiler" )
      AAdd( aLang, "          /credits") 

   ELSEIF cLang == "ES"

      AAdd( aLang, "Sintaxe:  hbmake <cArchivo>.bc [opciones] - Exemplo: hbmake hello.bc /ex")
      AAdd( aLang, "Opciones: /e[x]   Crea un Makefile nuevo. Si se usa /ex se crea un nuevo" )
      AAdd( aLang, "                  makefile en modo extendido." )
      AAdd( aLang, "          /el[x]  Crea un Makefile nuevo. Si se usa /elx se crea un nuevo" )
      AAdd( aLang, "                  makefile para construir una LIB en modo extendido." )
      AAdd( aLang, "          /D      Define una macro." )
      AAdd( aLang, "          /p      Imprime todos los comandos y dependencias." )
      AAdd( aLang, "          /b      Usar BCC como compilador C" )
      AAdd( aLang, "          /g+     Usar GCC como compilador C" )
      AAdd( aLang, "          /b+     Usar BCC como compilador C" )
      AAdd( aLang, "          /g      Usar GCC como compilador C" )
      AAdd( aLang, "          /gl     Usar GCC como compilador C en Linux" )
      AAdd( aLang, "          /gl+    Usar GCC como compilador C en Linux" )
      AAdd( aLang, "          /v      Usar MSVC como compilador C" )
      AAdd( aLang, "          /f      Forzar la recompilaci�n de todos los archivos" )
      AAdd( aLang, "          /i      Ignorar los errores devueltos por el comando" )
      AAdd( aLang, "          /r /nr  Activar modo recursivo.  /nr Desactivar modo recursivo." )
      AAdd( aLang, "                  Nota: /p y /D pueden ser usados juntos" )
      AAdd( aLang, "                        /r y /e[x]/el[x] pueden ser usados juntos" )
      AAdd( aLang, "                  Las opciones con + son los valores por omisi�n" )
      AAdd( aLang, "                  El parametro -D puede aceptar multiplas macros en la misma" )
      AAdd( aLang, "                  linea ou use una macro por parametro -D" )
      AAdd( aLang, "                  /l[LANGID] especifica una linguagem a ser utilizada por")
      AAdd( aLang, "                   hbmake. LANGID = (EN/PT/ES). En sistemas Windows, Lo padr�n")
      AAdd( aLang, "                   es la linguagem de SO. En OS/2, FreeBSD y LINUX ser�n Ingl�s.")
      AAdd( aLang, "Opciones de Ambiente" )
      AAdd( aLang, "Seleccione SO" )
      AAdd( aLang, "Seleccione Compilador C" )
      AAdd( aLang, "Lib Grafica" )
      AAdd( aLang, "Opciones de lo xHarbour" )
      AAdd( aLang, "Declaraci�n automatica de memvar /a" )
      AAdd( aLang, "Variables ser�n assumidas M-> /v " )
      AAdd( aLang, "Info. Debug /b" )
      AAdd( aLang, "Suprime info del n�mero de linea /l" )
      AAdd( aLang, "Gera salida pre-processada /p" )
      AAdd( aLang, "Compila solamente lo modulo /m" )
      AAdd( aLang, "Define del usuarios:" )
      AAdd( aLang, "Path includes del usuario:" )
      AAdd( aLang, "Usar libs externas" )
      AAdd( aLang, "<Espacio>-Seleccionar <Enter>-Continuar proceso <F5> Selec/Deselec todo." )
      AAdd( aLang, "Nivel del aviso de lo compilador /w" )
      AAdd( aLang, "Cuantos PRGs por linea no makefile:" )
      AAdd( aLang, "Usar la libreria Multi Thread" )
      AAdd( aLang, "Nombre del ejecutable" )
      AAdd( aLang, "Nivel de Avisos /w" )
      AAdd( aLang, "<Tab>-Avanzar <Sh-Tab>-Volver <Enter>-Selec <"+chr(24)+chr(25)+">-Mudar Selec <Espacio>-Caja")
      /* Messages Start Here */
      AAdd( aLang, "Rdd Terceros")
      AAdd( aLang, "Cual OS usted usa")
      AAdd( aLang, "Cual compilador C usted usa")
      AAdd( aLang, "Esta App usa Lib Grafica o No")
      AAdd( aLang, "Usted usa Rdd de terceros")
      AAdd( aLang, "Comprimir app")
      AAdd( aLang, "Prensar la App despu�s de enlazada (usar upx)")
      AAdd( aLang, "Su aplicacion ser� ligada para usar la harbour.dll")
      AAdd( aLang, "Donde los ficheros *.obj ser�n generados")
      AAdd( aLang, "Informe lo nombre de lo executable (sin la extension .exe)")
      /* More messages for LIB build */
      AAdd( aLang, "Informe lo nombre de la lib (sin la extension)")
      /* More xHarbour options for LIB build */
      AAdd( aLang, "Nombre de la Lib:" )
      AAdd( aLang, "Direct�rio de los Obj:" )
      AAdd( aLang, "Alojar la lib en el direct�rio lib de xHarbour" )
//      AAdd( aLang, "          /pc     Usar POCC como compilador C" )
      AAdd( aLang, "          /m      Usar GCC(mingw) como compilador C" )
      AAdd( aLang, "          /credits") 

   ELSEIF cLang == "PT"

      AAdd( aLang, "Sintaxe:  hbmake <arquivo>.bc [op��es] -  Exemplo: hbmake hello.bc /ex")
      AAdd( aLang, "Op��es:  /e[x]  Cria um Makefile novo. Se for usado /ex cria um makefile" )
      AAdd( aLang, "                em modo extendido." )
      AAdd( aLang, "         /el[x] Cria um Makefile novo. Se for usado /elx cria um makefile" )
      AAdd( aLang, "                para construir uma LIB, em modo extendido." )
      AAdd( aLang, "         /D     Define uma macro." )
      AAdd( aLang, "         /p     Imprime todos os comandos e depend�ncias." )
      AAdd( aLang, "         /b     Usar BCC como compilador C" )
      AAdd( aLang, "         /g+    Usar GCC como compilador C" )
      AAdd( aLang, "         /b+    Usar BCC como compilador C" )
      AAdd( aLang, "         /g     Usar GCC como compilador C" )
      AAdd( aLang, "         /gl    Usar GCC como compilador C no Linux" )
      AAdd( aLang, "         /gl+   Usar GCC como compilador C no Linux" )
      AAdd( aLang, "         /v     Usar MSVC como compilador C" )
      AAdd( aLang, "         /f     For�ar a recompila��o de todos os arquivos." )
      AAdd( aLang, "         /i     Ignora os erros devolvidos pelo comando." )
      AAdd( aLang, "         /r /nr Ativar modo recursivo. /nr Desativar modo recursivo." )
      AAdd( aLang, "                Nota:  /p e /D podem ser usados juntos" )
      AAdd( aLang, "                       /r e /e[x]/el[x] podem ser usados juntos" )
      AAdd( aLang, "                As op��es com + s�o os valores padr�o." )
      AAdd( aLang, "                O par�metro -D pode aceitar m�ltiplas macros na mesma linha")
      AAdd( aLang, "                ou use uma macro por par�metro -D" )
      AAdd( aLang, "                /l[LANGID] especifica a linguagem a ser utilizada pelo hbmake,")
      AAdd( aLang, "                LANGID = (EN/PT/ES). Em Windows, o padr�o ser� a linguagem")
      AAdd( aLang, "                definida no S.O. Em OS/2, FreeBSD e LINUX o padr�o ser� Ingl�s.")
      AAdd( aLang, "Op��es de Ambiente" )
      AAdd( aLang, "Selecione o SO" )
      AAdd( aLang, "Selecione Compilador C" )
      AAdd( aLang, "Lib Gr�f." )
      AAdd( aLang, "Op��es do xHarbour" )
      AAdd( aLang, "Declara��o Autom�tica de Memvar /a" )
      AAdd( aLang, "Vari�veis s�o assumidas M-> /v" )
      AAdd( aLang, "Info. Debug /b" )
      AAdd( aLang, "Suprime info de n�mero da linha /l" )
      AAdd( aLang, "Gera sa�da pr�-processada /p" )
      AAdd( aLang, "Compila apenas o m�dulo /m" )
      AAdd( aLang, "User Defines:" )
      AAdd( aLang, "User Include Path:" )
      AAdd( aLang, "Usa Libs Externas ?" )
      AAdd( aLang, "<Espa�o>-Seleciona <Enter> p/ continuar processo <F5>-Sel/DeSel. tudo." )
      AAdd( aLang, "N�vel de aviso do compilador /w" )
      AAdd( aLang, "Qtd de PRGs por linha, no makefile: " )
      AAdd( aLang, "Usar a biblioteca Multi Thread ?" )
      AAdd( aLang, "Nome Execut�vel:" )
      AAdd( aLang, "N�vel de Warnings /w" )
      AAdd( aLang, "<Tab>-Avan�a <Sh-Tab>-Volta <Enter>-Sel. <"+chr(24)+chr(25)+">-Muda Sel. <Espc>-Abre Box")
      /* Messages Start Here */
      AAdd( aLang, "Rdd Terceiros")
      AAdd( aLang, "Selecione o Sistema Operacional")
      AAdd( aLang, "Selecione o compilador C/C++")
      AAdd( aLang, "Esta aplica��o vai usar Lib Grafica ? Qual ?")
      AAdd( aLang, "Esta aplica��o vai usar Rdd de terceiros ? Qual ?")
      AAdd( aLang, "Comprimir App ?")
      AAdd( aLang, "Comprimir a aplica��o ap�s linkada (usar UPX) ?")
      AAdd( aLang, "Sua aplica��o ser� linkada para usar a harbour.dll ?")
      AAdd( aLang, "Informe a pasta onde os arquivos *.obj ser�o gerados")
      AAdd( aLang, "Informe o nome do execut�vel (sem a extens�o .exe)")
      /* More messages for LIB build */
      AAdd( aLang, "Informe o nome da lib (sem a extens�o)")
      /* More xHarbour options for LIB build */
      AAdd( aLang, "Nome da Lib:" )
      AAdd( aLang, "Diret�rio dos Obj:" )
      AAdd( aLang, "Instalar a lib no diret�rio lib do xHarbour" )
//      AAdd( aLang, "         /pc    Usar POCC como compilador C" )
      AAdd( aLang, "         /m     Usar GCC(mingw) como compilador C" )
      AAdd( aLang, "         /credits") 

   ENDIF

RETURN aLang

*------------------------------------------
FUNCTION GetSelFiles( aInFiles, aOutFiles )
*------------------------------------------

   LOCAL aRet  := {}
   LOCAL cItem
   LOCAL nPos

   FOR EACH cItem IN aInFiles

      nPos := AScan( aOutFiles, { | x, y | x == Left( cItem, At( ' ', citem ) - 1 ) } )

      IF nPos > 0
         AAdd( aRet, cItem )
      ENDIF

   NEXT

RETURN aRet

*---------------------------
FUNCTION ResetInternalVars()
*---------------------------

   s_lPrint        := .F.
   s_aDefines      := {}
   s_aBuildOrder   := {}
   s_aCommands     := {}
   s_aMacros       := {}
   s_aPrgs         := {}
   s_aExtLibs      := {}
   s_aCs           := {}
   s_aObjs         := {}
   s_aObjsc        := {}
   s_lEof          := .F.
   s_aResources    := {}
// s_cMakeFileName := "makefile.lnk"
   s_cLinkCommands := ""
   if s_lBcc
   s_lBcc          := .T.
   s_lGcc          := .F.
   s_lMSVcc        := .F.
   s_lPcc          := .F.
   elseif s_lMSVcc
   s_lBcc          := .F.
   s_lGcc          := .F.
   s_lMSVcc        := .T.
   s_lPcc          := .F.
   elseif s_lPcc
   s_lBcc          := .F.
   s_lGcc          := .F.
   s_lMSVcc        := .F.
   s_lPcc          := .T.

   endif
   s_lForce        := .F.
   s_lLinux        := .F.
   s_szProject     := ""
   s_lLibrary      := .F.
   s_lIgnoreErrors := .F.
   s_lExtended     := .T.
   s_lOs2          := .F.
   s_lRecursive    := .F.
   s_lEditMake     := .F.
   s_aDir          := {}
   s_aLangMessages := {}

RETURN NIL

*----------------------------------
FUNCTION OsSpec(GetList,nPos,cSpec)
*----------------------------------
   local oGet := GetList[nPos]
   local oControl
   oControl := oGet:Control
   IF oControl != NIL
      cSpec := oControl:GetData( oControl:Value )
//   keyboard chr(9)
   ENDIF

RETURN .T.

*--------------------------
FUNCTION CheckCompiler(cOS)
*--------------------------
RETURN ( ("Win32" IN cOS) .or. ("Linux" In cOS) )

*------------------------------
FUNCTION SetThisLibs(aTempLibs)
*------------------------------

Local c := ""
Local n

for Each n In aTempLibs
     c += "-l"
     c += StrTran( n, '.a', "" )
     c+= " "
next

RETURN c

*----------------
FUNCTION AsDll(x)
*----------------
Local y := x
 x := !y
RETURN .T.

*--------------------
FUNCTION Delete_ppo()
*--------------------
LOCAL nPos,aFiles

 if valtype(s_lGenppo)=="L" .AND. !s_lGenppo

    aFiles := directory( "*.ppo" )

    for nPos := 1 to Len( aFiles )
        FErase( aFiles[nPos,1] )
    next

 endif

RETURN NIL

*------------------
FUNCTION ShowHelp()
*------------------

   LOCAL cOS := Upper( Os() )

   CLS

   OutStd( s_aLangMessages[ 1 ] + HB_OsNewLine() )
   OutStd( HbMake_Copyright()  + HB_OsNewLine() )
   OutStd( HB_OsNewLine() )
   OutStd( s_aLangMessages[ 2 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 3 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 4 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 5 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 6 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 7 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 8 ] + HB_OsNewLine() )

   IF  "OS/2" IN cOS
      OutStd( s_aLangMessages[ 9 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 10 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 13 ] + HB_OsNewLine() )
   ELSEIF  'LINUX' IN  cOS
      OutStd( s_aLangMessages[ 9 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 12 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 14 ] + HB_OsNewLine() )
   ELSE
      OutStd( s_aLangMessages[ 11 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 12 ] + HB_OsNewLine() )
      OutStd( s_aLangMessages[ 13 ] + HB_OsNewLine() )
   ENDIF

   OutStd( s_aLangMessages[ 15 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 62 ] + HB_OsNewLine() ) // pocc syntax
   OutStd( s_aLangMessages[ 16 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 17 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 18 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 19 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 20 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 21 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 22 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 23 ] + HB_OsNewLine() )

   setpos(maxrow()-1,0)
   WAIT
   setpos(maxrow(),0)

   OutStd( s_aLangMessages[ 24 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 25 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 26 ] + HB_OsNewLine() )
   OutStd( s_aLangMessages[ 63 ] + HB_OsNewLine() )

RETURN NIL

*-------------------
FUNCTION HbMake_ID()
*-------------------
RETURN ( "HbMake v"+s_cHbMakeVersion+" - xHarbour Make Utility")

*--------------------------
FUNCTION HbMake_Copyright()
*--------------------------
RETURN ( "Copyright (C) 2000-2005 xHarbour project - http://www.xharbour.org")

*------------------------
FUNCTION HbMake_Credits()
*------------------------
local i,aCredits := {}

 CLS

 aadd( aCredits,"Credits:" )
 aadd( aCredits," " )
 aadd( aCredits,"Luiz Rafael Culik <culikr@uol.com.br>" )

 qqout( HbMake_Id() )
 qout( HbMake_copyright() )
 qout( " ")

 for i := 1 to Len( aCredits )
     qout( aCredits[i] )
 next

 qout(" ")

RETURN NIL
