/*
 * $Id: debugger.prg,v 1.65 2005/10/30 14:45:49 druzus Exp $
 */

/*
 * Harbour Project source code:
 * The Debugger
 *
 * Copyright 1999 Antonio Linares <alinares@fivetechsoft.com>
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
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

/* NOTE: Don't use SAY/DevOut()/DevPos() for screen output, otherwise
         the debugger output may interfere with the applications output
         redirection, and is also slower. [vszakats] */

//#pragma -es0


#pragma BEGINDUMP

#include "hbapigt.h"

#pragma ENDDUMP


#include "hbclass.ch"
#include "hbmemvar.ch"
#include "box.ch"
#include "inkey.ch"
#include "common.ch"
#include "set.ch"
#include "setcurs.ch"
#include "hbdebug.ch"   // for "nMode" of __dbgEntry


#define  NTRIM(x)    (ALLTRIM(STR(x)))


/* A macro to compare filenames on different platforms. */
#ifdef __PLATFORM__DOS
#define FILENAME_EQUAL(s1, s2) ( Lower( s1 ) == Lower( s2 ) )
#else
#ifdef __PLATFORM__OS2
#define FILENAME_EQUAL(s1, s2) ( Lower( s1 ) == Lower( s2 ) )
#else
#ifdef __PLATFORM__Windows
#define FILENAME_EQUAL(s1, s2) ( Lower( s1 ) == Lower( s2 ) )
#else
#define FILENAME_EQUAL(s1, s2) ( s1 == s2 )
#endif
#endif
#endif


/* Information structure stored in DATA aCallStack */
#define CSTACK_MODULE      1  //module name (.PRG file)
#define CSTACK_FUNCTION    2  //function name
#define CSTACK_LINE        3  //start line
#define CSTACK_LEVEL       4  //eval stack level of the function
#define CSTACK_LOCALS      5  //an array with local variables
#define CSTACK_STATICS     6  //an array with static variables

/* Information structure stored in aCallStack[n][ CSTACK_LOCALS ]
   { cLocalName, nLocalIndex, "Local", ProcName( 1 ), nLevel } */
#define VAR_NAME        1
#define VAR_POS         2
#define VAR_TYPE        3
#define VAR_LEVEL       4  //eval stack level of the function

/* Information structure stored in ::aWatch (watchpoints) */
#define WP_TYPE      1  //wp = watchpoint, tr = tracepoint
#define WP_EXPR      2  //source of an expression


static s_oDebugger


procedure __dbgAltDEntry()
   /* do not activate the debugger imediatelly because the module
      where ALTD() was called can have no debugger info - stop
      on first LINE with debugged info
    */
   HB_DBG_INVOKEDEBUG( SET( _SET_DEBUG ) )
return


procedure __dbgEntry( nMode, uParam1, uParam2, uParam3, uParam4, uParam5 )  // debugger entry point
  LOCAL bStartup := .F.
  
  DO CASE
    CASE nMode == HB_DBG_GETENTRY
      HB_INLINE()
      {
         hb_vm_pFunDbgEntry = hb_dbgEntry;
      }

    CASE nMode == HB_DBG_ACTIVATE
      IF s_oDebugger == NIL
        bStartup := .T.
        s_oDebugger := TDebugger():New()
        s_oDebugger:pInfo := uParam1
      ENDIF
      s_oDebugger:nProcLevel := uParam2
      s_oDebugger:aCallStack := uParam3
      s_oDebugger:aStaticModules := uParam4
      s_oDebugger:aBreakPoints := uParam5
      IF bStartup
        IF s_oDebugger:lRunAtStartup
          HB_INLINE( uParam1 )
          {
            hb_dbgSetGo( hb_parptr( 1 ) );
          }
          RETURN
        ENDIF
      ENDIF
      s_oDebugger:lGo := .F.
      s_oDebugger:Activate()
  ENDCASE

return


CLASS TDebugger
   DATA   pInfo
   DATA   aWindows, nCurrentWindow
   DATA   oPullDown
   DATA   oWndCode, oWndCommand, oWndStack, oWndVars
   DATA   oBar, oBrwText, cPrgName, oBrwStack, oBrwVars, aVars
   DATA   cImage
   DATA   cAppImage, nAppRow, nAppCol, cAppColors, nAppCursor, nAppDispCount
   DATA   nAppLastKey, bAppInkeyAfter, bAppInkeyBefore, bAppClassScope
   DATA   nAppCTWindow, nAppDirCase, nAppFileCase, oAppGetList, nAppTypeAhead
   DATA   nMaxRow, nMaxCol
   DATA   aBreakPoints
   DATA   aCallStack    //stack of procedures with debug info
   DATA   aProcStack    //stack of all procedures
   DATA   nProcLevel    //procedure level where the debugger is currently
   DATA   aStaticModules // array of modules with static variables
   DATA   aColors
   DATA   aWatch
   DATA   aLastCommands, nCommand, oGetListCommand
   DATA   lAnimate, lEnd, lCaseSensitive, lMonoDisplay, lSortVars
   DATA   cSearchString, cPathForFiles, cSettingsFileName, aPathDirs
   DATA   nTabWidth, nSpeed
   DATA   lShowPublics, lShowPrivates, lShowStatics, lShowLocals, lAll
   DATA   lShowCallStack
   DATA   lGo           //stores if GO was requested
   DATA   lActive INIT .F.
   DATA   lCBTrace INIT .T.   //stores if codeblock tracing is allowed
   DATA   oBrwPnt, oWndPnt
   DATA   lPPO INIT .F.
   DATA   lRunAtStartup
   DATA   lLineNumbers INIT .T.

   METHOD New()
   METHOD Activate()

   METHOD All()

   METHOD Animate() INLINE If( ::lAnimate, ::Step(), nil )

   METHOD BarDisplay()
   METHOD BuildCommandWindow()
   METHOD BuildBrowseStack()

   METHOD CallStackProcessKey( nKey )
   METHOD ClrModal() INLINE iif( ::lMonoDisplay, "N/W, W+/W, W/N, W+/N",;
                                "N/W, R/W, N/BG, R/BG" )

   METHOD CodeblockTrace()
   METHOD CodeWindowProcessKey( nKey )
   METHOD Colors()
   METHOD CommandWindowProcessKey( nKey )
   METHOD DoCommand( cCommand )
   METHOD DoScript( cFileName )
   METHOD EditColor( nColor, oBrwColors )
   METHOD EditSet( nSet, oBrwSets )
   METHOD EditVar( nVar )
   METHOD Exit() INLINE ::lEnd := .t.
   METHOD FindNext()
   METHOD FindPrevious()
   METHOD GetExprValue( xExpr, lValid )
   METHOD Go()
   METHOD GoToLine( nLine )
   METHOD HandleEvent()
   METHOD Hide()
   METHOD HideCallStack()
   METHOD HideVars()
   METHOD InputBox( cMsg, uValue, bValid, lEditable )
   METHOD Inspect( uValue, cValueName )
   METHOD LoadColors()
   METHOD LoadSettings()
   METHOD LoadVars()
   METHOD LoadCallStack()

   METHOD Local()

   METHOD Locate( nMode, cValue )

   METHOD MonoDisplay()
   METHOD NextWindow()
   METHOD Open()
   METHOD OpenPPO()
   METHOD Resume() INLINE ::ShowCodeLine( 1 )
   METHOD OSShell()
   METHOD PathForFiles( cPathForFiles )

   METHOD PrevWindow()
   METHOD Private()
   METHOD Public()
   METHOD Quit()
   METHOD RefreshVars()
   METHOD RestoreAppScreen()
   METHOD RestoreAppState()
   METHOD RestoreSettings()
   METHOD RunAtStartup() INLINE ::lRunAtStartup := ::oPullDown:GetItemByIdent( "ALTD" ):checked := !::lRunAtStartup
   METHOD SaveAppScreen( lRestore )
   METHOD SaveAppState()
   METHOD SaveSettings()
   METHOD Show()
   METHOD ShowAppScreen()
   METHOD ShowCallStack()
   METHOD ShowCodeLine( nProc )
   METHOD ShowHelp( nTopic )
   METHOD ShowVars()
   METHOD RedisplayBreakpoints()
   METHOD LocatePrgPath( cPrgName )
   METHOD Sort() INLINE ASort( ::aVars,,, {|x,y| x[1] < y[1] } ),;
                        ::lSortVars := .t.,;
                        iif( ::oBrwVars != nil, ::oBrwVars:RefreshAll(), nil ),;
          iif( ::oWndVars != nil .and. ::oWndVars:lVisible, iif(!::lGo,::oBrwVars:ForceStable(),),)

   METHOD Speed() INLINE ;
          ::nSpeed := ::InputBox( "Step delay (in tenths of a second)",;
                                  ::nSpeed )

   METHOD Stack()
   METHOD Static()

   METHOD Step()

   METHOD TabWidth() INLINE ;
          ::nTabWidth := ::InputBox( "Tab width", ::nTabWidth )

   METHOD ToggleBreakPoint()

   METHOD Trace()

   METHOD ToCursor()
   METHOD NextRoutine()
   METHOD ViewSets()
   METHOD WndVarsLButtonDown( nMRow, nMCol )
   METHOD LineNumbers( lLineNumbers ) // Toggles numbering of source code lines
   METHOD RemoveWindow()
   METHOD SearchLine()
   METHOD ToggleAnimate() INLINE ::oPullDown:GetItemByIdent( "ANIMATE" ):checked := ::lAnimate := ! ::lAnimate
   METHOD ToggleCaseSensitive() INLINE ::oPullDown:GetItemByIdent( "CASE" ):checked := ::lCaseSensitive := ! ::lCaseSensitive
   METHOD ShowWorkAreas() INLINE __dbgShowWorkAreas( Self )

   METHOD TracepointAdd( cExpr )
   METHOD WatchpointAdd( cExpr )
   METHOD WatchpointDel( nPos )
   METHOD WatchpointsShow()
   METHOD WatchpointsHide()
   METHOD WatchpointEdit( nVar )
   METHOD WatchpointInspect( nPos )
   METHOD WatchGetInfo( nWatch )

   METHOD VarGetInfo( aVar )
   METHOD VarGetValue( aVar )
   METHOD VarSetValue( aVar, uValue )

   METHOD ResizeWindows( oWindow )
   METHOD NotSupported() INLINE Alert( "Not implemented yet!" )

ENDCLASS


METHOD New() CLASS TDebugger

   s_oDebugger := Self

   ::aColors := {"W+/BG","N/BG","R/BG","N+/BG","W+/B","GR+/B","W/B","N/W","R/W","N/BG","R/BG"}
   ::lMonoDisplay      := .f.
   ::aWindows          := {}
   ::nCurrentWindow    := 1
   ::lAnimate          := .f.
   ::lEnd              := .f.
   ::aBreakPoints      := {}
   ::aWatch            := {}
   ::aCallStack        := {}
   ::aStaticModules    := {}
   ::aProcStack        := {}
   ::aVars             := {}
   ::lCaseSensitive    := .f.
   ::cSearchString     := ""

   // default the search path for files to the current directory
   // that way if the source is in the same directory it will still be found even if the application
   // changes the current directory with the SET DEFAULT command
   ::cPathForFiles     := getenv( "HB_DBG_PATH" )
   if empty( ::cPathForFiles )
      ::cPathForFiles     := getenv( "PATH" )
   endif
   ::aPathDirs := PathToArray( ::cPathForFiles )

   ::nTabWidth         := 4
   ::nSpeed            := 0
   ::lShowCallStack    := .f.
   ::lShowPublics      := .f.
   ::lShowPrivates     := .f.
   ::lShowStatics      := .f.
   ::lShowLocals       := .f.
   ::lAll              := .f.
   ::lSortVars         := .f.
   ::cSettingsFileName := "init.cld"
   ::lRunAtStartup     := .t. //Clipper compatible
   ::lGo               := ::lRunAtStartup

   /* Store the initial screen dimensions for now */
   ::nMaxRow := MaxRow()
   ::nMaxCol := MaxCol()

   ::oPullDown      := __dbgBuildMenu( Self )

   ::oWndCode       := TDbWindow():New( 1, 0, ::nMaxRow - 6, ::nMaxCol )
   ::oWndCode:Cargo       := { ::oWndCode:nTop, ::oWndCode:nLeft }
   ::oWndCode:bKeyPressed := { | nKey | ::CodeWindowProcessKey( nKey ) }
   ::oWndCode:bGotFocus   := { || ::oGetListCommand:SetFocus(), SetCursor( SC_SPECIAL1 ), ;
                              SetPos( ::oWndCode:Cargo[1],::oWndCode:Cargo[2] ) }
   ::oWndCode:bLostFocus  := { || ::oWndCode:Cargo[1] := Row(), ::oWndCode:Cargo[2] := Col(), ;
                              SetCursor( SC_NONE ) }

   AAdd( ::aWindows, ::oWndCode )

   ::BuildCommandWindow()
   ::BuildBrowseStack()

   if File( ::cSettingsFileName )
      ::LoadSettings()
   endif
   ::lGo := ::lRunAtStartup
return Self


METHOD Activate() CLASS TDebugger

  ::LoadCallStack()
  ::SaveAppState()
  IF ! ::lActive
    ::lActive := .T.
    ::Show()
    if ::lShowCallStack
      ::ShowCallStack()
    endif
  ELSE
    ::SaveAppScreen()
  ENDIF
  ::loadVars()
  ::ShowVars()
  IF( ::oWndPnt != NIL )
    ::WatchpointsShow()
  ENDIF
  // show the topmost procedure
  ::ShowCodeLine( 1 ) //::aCallStack[1][ CSTACK_LINE ], ::aCallStack[1][ CSTACK_MODULE ] )
  ::HandleEvent()

return nil

METHOD All() CLASS TDebugger

   ::lShowPublics := ::lShowPrivates := ::lShowStatics := ;
   ::lShowLocals := ::lAll := ! ::lAll

   ::RefreshVars()

return nil

METHOD BarDisplay() CLASS TDebugger

   local cClrItem   := __DbgColors()[ 8 ]
   local cClrHotKey := __DbgColors()[ 9 ]

   DispBegin()
   SetColor( cClrItem )
   @ ::nMaxRow, 0 CLEAR TO ::nMaxRow, ::nMaxCol

   DispOutAt( ::nMaxRow,  0,;
   "F1-Help F2-Zoom F3-Repeat F4-User F5-Go F6-WA F7-Here F8-Step F9-BkPt F10-Trace",;
   cClrItem )
   DispOutAt( ::nMaxRow,  0, "F1", cClrHotKey )
   DispOutAt( ::nMaxRow,  8, "F2", cClrHotKey )
   DispOutAt( ::nMaxRow, 16, "F3", cClrHotKey )
   DispOutAt( ::nMaxRow, 26, "F4", cClrHotKey )
   DispOutAt( ::nMaxRow, 34, "F5", cClrHotKey )
   DispOutAt( ::nMaxRow, 40, "F6", cClrHotKey )
   DispOutAt( ::nMaxRow, 46, "F7", cClrHotKey )
   DispOutAt( ::nMaxRow, 54, "F8", cClrHotKey )
   DispOutAt( ::nMaxRow, 62, "F9", cClrHotKey )
   DispOutAt( ::nMaxRow, 70, "F10", cClrHotKey )
   DispEnd()

return nil


METHOD BuildBrowseStack() CLASS TDebugger

   if ::oBrwStack == nil
      ::oBrwStack := TBrowseNew( 2, ::nMaxCol - 14, ::nMaxRow - 7, ::nMaxCol - 1 )
      ::oBrwStack:ColorSpec := ::aColors[ 3 ] + "," + ::aColors[ 4 ] + "," + ::aColors[ 5 ]
      ::oBrwStack:GoTopBlock := { || ::oBrwStack:Cargo := 1 }
      ::oBrwStack:GoBottomBlock := { || ::oBrwStack:Cargo := Len( ::aProcStack ) }
      ::oBrwStack:SkipBlock = { | nSkip, nOld | nOld := ::oBrwStack:Cargo,;
                              ::oBrwStack:Cargo += nSkip,;
                              ::oBrwStack:Cargo := Min( Max( ::oBrwStack:Cargo, 1 ),;
                              Len( ::aProcStack ) ), ::oBrwStack:Cargo - nOld }

      ::oBrwStack:Cargo := 1 // Actual highligthed row

      ::oBrwStack:AddColumn( TBColumnNew( "", { || If( Len( ::aProcStack ) > 0,;
            PadC( ::aProcStack[ ::oBrwStack:Cargo ][ CSTACK_FUNCTION ], 14 ), Space( 14 ) ) } ) )
   endif

return nil


METHOD BuildCommandWindow() CLASS TDebugger

   local GetList := {}, oGet
   local cCommand

   ::oWndCommand := TDbWindow():New( ::nMaxRow - 5, 0, ::nMaxRow - 1, ::nMaxCol,;
                                    "Command" )

   ::oWndCommand:bGotFocus   := { || ::oGetListCommand:SetFocus(), SetCursor( SC_NORMAL ) }
   ::oWndCommand:bLostFocus  := { || SetCursor( SC_NONE ) }
   ::oWndCommand:bKeyPressed := { | nKey | ::CommandWindowProcessKey( nKey ) }
   ::oWndCommand:bPainted    := { || DispOutAt( ::oWndCommand:nBottom - 1,;
                             ::oWndCommand:nLeft + 1, "> ", __DbgColors()[ 2 ] ),;
                        oGet:ColorDisp( Replicate( __DbgColors()[ 2 ] + ",", 5 ) ),;
                        hb_ClrArea( ::oWndCommand:nTop + 1, ::oWndCommand:nLeft + 1,;
                        ::oWndCommand:nBottom - 2, ::oWndCommand:nRight - 1,;
                        iif( ::lMonoDisplay, 15, HB_ColorToN( __DbgColors()[ 2 ] ) ) ) }
   AAdd( ::aWindows, ::oWndCommand )

   ::aLastCommands := { "" }
   ::nCommand := 1

   cCommand := Space( ::oWndCommand:nRight - ::oWndCommand:nLeft - 3 )
   // We don't use the GET command here to avoid the painting of the GET
   AAdd( GetList, oGet := Get():New( ::oWndCommand:nBottom - 1, ::oWndCommand:nLeft + 3,;
         { | u | iif( PCount() > 0, cCommand := u, cCommand ) }, "cCommand" ) )
   oGet:ColorSpec := Replicate( __DbgColors()[ 2 ] + ",", 5 )
   ::oGetListCommand := HBGetList():New( GetList )

return nil


METHOD CallStackProcessKey( nKey ) CLASS TDebugger

   local n, nSkip, lUpdate := .f.

   do case
      case nKey == K_HOME
           if ::oBrwStack:Cargo > 1
              ::oBrwStack:GoTop()
              ::oBrwStack:ForceStable()
              lUpdate = .t.
           endif

      case nKey == K_END
           if ::oBrwStack:Cargo < Len( ::aProcStack )
              ::oBrwStack:GoBottom()
              ::oBrwStack:ForceStable()
              lUpdate = .t.
           endif

      case nKey == K_UP
           if ::oBrwStack:Cargo > 1
              ::oBrwStack:Up()
              ::oBrwStack:ForceStable()
              lUpdate = .t.
           endif

      case nKey == K_DOWN
           if ::oBrwStack:Cargo < Len( ::aProcStack )
              ::oBrwStack:Down()
              ::oBrwStack:ForceStable()
              lUpdate = .t.
           endif

      case nKey == K_PGUP
           ::oBrwStack:PageUp()
           ::oBrwStack:ForceStable()
           lUpdate = .t.

      case nKey == K_PGDN
           ::oBrwStack:PageDown()
           ::oBrwStack:ForceStable()
           lUpdate = .t.

      case nKey == K_LBUTTONDOWN
           if ( nSkip := MRow() - ::oWndStack:nTop - ::oBrwStack:RowPos ) != 0
              if nSkip > 0
                 for n = 1 to nSkip
                    ::oBrwStack:Down()
                    ::oBrwStack:Stabilize()
                 next
              else
                 for n = 1 to nSkip + 2 step -1
                    ::oBrwStack:Up()
                    ::oBrwStack:Stabilize()
                 next
              endif
              ::oBrwStack:ForceStable()
           endif
           lUpdate = .t.
   endcase

   if lUpdate
      if ::oWndVars != nil .AND. ::oWndVars:lVisible
         ::LoadVars()
         ::ShowVars()
      endif

      // jump to source line for a function
      /*if ::aCallStack[ ::oBrwStack:Cargo ][ CSTACK_LINE ] != nil
         ::ShowCodeLine( ::aCallStack[ ::oBrwStack:Cargo ][ CSTACK_LINE ], ::aCallStack[ ::oBrwStack:Cargo ][ CSTACK_MODULE ] )
      else
         ::GotoLine( 1 )
      endif*/
      ::ShowCodeLine( ::oBrwStack:Cargo )
   endif

return nil


METHOD CodeblockTrace()
  ::oPullDown:GetItemByIdent( "CODEBLOCK" ):checked := ::lCBTrace := ! ::lCBTrace
  HB_INLINE( ::pInfo, ::lCBTrace )
  {
    hb_dbgSetCBTrace( hb_parptr( 1 ), hb_parl( 2 ) );
  }
RETURN NIL


METHOD CodeWindowProcessKey( nKey ) CLASS TDebugger

   do case
      case nKey == K_HOME
           ::oBrwText:GoTop()
           if ::oWndCode:lFocused
              SetCursor( SC_SPECIAL1 )
           endif

      case nKey == K_END
           ::oBrwText:GoBottom()
           ::oBrwText:nCol = ::oWndCode:nLeft + 1
           ::oBrwText:nFirstCol = ::oWndCode:nLeft + 1
           SetPos( Row(), ::oWndCode:nLeft + 1 )
           if ::oWndCode:lFocused
              SetCursor( SC_SPECIAL1 )
           endif

      case nKey == K_LEFT
           ::oBrwText:Left()

      case nKey == K_RIGHT
           ::oBrwText:Right()

      case nKey == K_UP
           ::oBrwText:Up()

      case nKey == K_DOWN
           ::oBrwText:Down()

      case nKey == K_PGUP
           ::oBrwText:PageUp()

      case nKey == K_PGDN
           ::oBrwText:PageDown()

   endcase

return nil


METHOD Colors() CLASS TDebugger

   local oWndColors := TDbWindow():New( 4, 5, 16, ::nMaxCol - 5,;
                                        "Debugger Colors[1..11]", ::ClrModal() )
   local aColors := { "Border", "Text", "Text High", "Text PPO", "Text Selected",;
                      "Text High Sel.", "Text PPO Sel.", "Menu", "Menu High",;
                      "Menu Selected", "Menu High Sel." }

   local oBrwColors := TBrowseNew( oWndColors:nTop + 1, oWndColors:nLeft + 1,;
                                 oWndColors:nBottom - 1, oWndColors:nRight - 1 )
   local nWidth := oWndColors:nRight - oWndColors:nLeft - 1
   local oCol

   if ::lMonoDisplay
      Alert( "Monochrome display" )
      return nil
   endif
   oBrwColors:Cargo :={ 1,{}} // Actual highligthed row
   oBrwColors:ColorSpec := ::ClrModal()
   oBrwColors:GOTOPBLOCK := { || oBrwColors:cargo[ 1 ]:= 1 }
   oBrwColors:GoBottomBlock := { || oBrwColors:cargo[ 1 ]:= Len(oBrwColors:cargo[ 2 ][ 1 ])}
   oBrwColors:SkipBlock := { |nPos| ( nPos:= ArrayBrowseSkip(nPos, oBrwColors), oBrwColors:cargo[ 1 ]:= ;
   oBrwColors:cargo[ 1 ] + nPos,nPos ) }

   oBrwColors:AddColumn( ocol := TBColumnNew( "", { || PadR( aColors[ oBrwColors:Cargo[1] ], 14 ) } ) )
   oCol:DefColor:={1,2}
   aadd(oBrwColors:Cargo[2],acolors)
   oBrwColors:AddColumn( oCol := TBColumnNew( "",;
                       { || PadR( '"' + ::aColors[ oBrwColors:Cargo[1] ] + '"', nWidth - 15 ) } ) )
   aadd(oBrwColors:Cargo[2],acolors)
   oCol:DefColor:={1,3}
   ocol:width:=50
   oBrwColors:autolite:=.f.

   oWndColors:bPainted    := { || oBrwColors:ForceStable(),RefreshVarsS(oBrwColors)}

   oWndColors:bKeyPressed := { | nKey | SetsKeyPressed( nKey, oBrwColors,;
                               Len( aColors ), oWndColors, "Debugger Colors",;
                               { || ::EditColor( oBrwColors:Cargo[1], oBrwColors ) } ) }
   oWndColors:ShowModal()

   ::LoadColors()

RETURN NIL


METHOD CommandWindowProcessKey( nKey ) CLASS TDebugger

   local cCommand, cResult, oE
   local bLastHandler
   local lDisplay
   local n, nWidth := ::oWndCommand:nRight - ::oWndCommand:nLeft - 3

   do case
      case nKey == K_UP .OR. nKey == K_F3
           if ::nCommand > 1
              ::oGetListCommand:oGet:Assign()
              ::aLastCommands[ ::nCommand ] := Trim( ::oGetListCommand:oGet:VarGet() )
              ::nCommand--
              cCommand := PadR( ::aLastCommands[ ::nCommand ], nWidth )
              ::oGetListCommand:oGet:VarPut( cCommand )
              ::oGetListCommand:oGet:Buffer := cCommand
              ::oGetListCommand:oGet:Pos := Len( ::aLastCommands[ ::nCommand ] ) + 1
              ::oGetListCommand:oGet:Display()
           endif

      case nKey == K_DOWN
           if ::nCommand < Len( ::aLastCommands )
              ::oGetListCommand:oGet:Assign()
              ::aLastCommands[ ::nCommand ] := Trim( ::oGetListCommand:oGet:VarGet() )
              ::nCommand++
              cCommand := PadR( ::aLastCommands[ ::nCommand ], nWidth )
              ::oGetListCommand:oGet:VarPut( cCommand )
              ::oGetListCommand:oGet:Buffer := cCommand
              ::oGetListCommand:oGet:Pos := Len( ::aLastCommands[ ::nCommand ] ) + 1
              ::oGetListCommand:oGet:Display()
           endif

      case nKey == K_ENTER
           /* We must call :Assign() before :VarGet(), because it's no longer
            * called on every change */
           ::oGetListCommand:oGet:Assign()
           cCommand := Trim( ::oGetListCommand:oGet:VarGet() )

           if ! Empty( cCommand )
              IF ( n := AScan( ::aLastCommands, cCommand ) ) > 0 .AND. n < Len( ::aLastCommands )
                 ADel( ::aLastCommands, n, .T. )
              ENDIF
              ::nCommand := Len( ::aLastCommands )
              ::aLastCommands[ ::nCommand ] := cCommand
              AAdd( ::aLastCommands, "" )
              ::nCommand := Len( ::aLastCommands )
              ::oWndCommand:ScrollUp( 1 )
              ::DoCommand( cCommand )
           endif

           DispOutAt( ::oWndCommand:nBottom - 1, ::oWndCommand:nLeft + 1, "> ",;
              __DbgColors()[ 2 ] )
           cCommand := Space( nWidth )
           ::oGetListCommand:oGet:VarPut( cCommand )
           ::oGetListCommand:oGet:Buffer := cCommand
           ::oGetListCommand:oGet:Pos := 1
           ::oGetListCommand:oGet:Display()

      otherwise
           ::oGetListCommand:GetApplyKey( nKey )
   endcase

return nil


/*
 * ?? <expr>
 *      displays inspect window with value or display nothing on error
 * ? <expr>
 *      displays either result or error description in command window
 */
METHOD DoCommand( cCommand ) CLASS TDebugger
   LOCAL aCmnd
   LOCAL cParam, cParam1 := ""
   LOCAL cResult
   LOCAL lValid
   LOCAL n

   cCommand := ALLTRIM( cCommand )
   aCmnd := { NIL, NIL, NIL }

   DO CASE
      CASE Empty( cCommand )
         RETURN ""

      CASE starts( cCommand, "??" )
         cParam := AllTrim( SUBSTR( cCommand, 3 ) )
         cCommand := "??"

      CASE starts( cCommand, "?" )
         cParam := SUBSTR( cCommand, 2 )
         cCommand := "?"

      OTHERWISE
         IF ( n := At( " ", cCommand ) ) > 0
            cParam := AllTrim( SubStr( cCommand, n + 1 ) )
            cCommand := Left( cCommand, n - 1 )
         ENDIF
         cCommand := Upper( cCommand )

   ENDCASE

   DO CASE
      CASE cCommand == "??" .OR. cCommand == "?"
         aCmnd[WP_TYPE] := cCommand
         aCmnd[WP_EXPR] := cParam
         
         ::RestoreAppState()
         cResult := ::GetExprValue( cParam, @lValid )
         ::SaveAppState()
         
         IF( aCmnd[WP_TYPE] == "??" )
            IF( lValid )
               ::Inspect( aCmnd[WP_EXPR], cResult )
            ENDIF
            cResult := ''  //discard result
         ELSE
            IF( lValid )
               cResult := ValToStr( cResult )
            ENDIF
         ENDIF

     CASE starts( "ANIMATE", cCommand )
        IF ::lActive
           ::lAnimate = .t.
           ::Animate()
           SetCursor( SC_NORMAL )
        ENDIF

     CASE starts( "BP", cCommand )
        /* TODO: Support BP <cFuncName> */
        IF !Empty( cParam )
           IF ( n := At( " ", cParam ) ) > 0
              cParam1 := AllTrim( SubStr( cParam, n + 1 ) )
              cParam := Left( cParam, n - 1 )
           ELSE
              cParam1 := ::cPrgName
           ENDIF
           ::ToggleBreakPoint( Val( cParam ), strip_path( cParam1 ) )
        ELSE
           ::ToggleBreakPoint()
        ENDIF

     CASE starts( "CALLSTACK", cCommand )
        ::Stack( Upper( cParam ) == "ON" )

     /* TODO: Support DELETE ALL [TP|BP|WP], DELETE WP|TP|BP <nNumber> */

     CASE starts( "DOS", cCommand )
        ::OsShell()
        SetCursor( SC_NORMAL )

     CASE starts( "FIND", cCommand )
        ::Locate( 0, cParam )

     CASE starts( "GO", cCommand )
        ::Go()

     CASE starts( "GOTO", cCommand ) .AND. Val( cParam ) > 0
        ::GoToLine( Val( cParam ) )

     CASE starts( "HELP", cCommand )
        ::ShowHelp()

     CASE starts( "INPUT", cCommand ) .AND. !Empty( cParam )
        ::DoScript( cParam )

     /* TODO: Support LIST BP|WP|TP */

     CASE starts( "MONITOR", cCommand )
        cParam := Upper( cParam )
        DO CASE
           CASE starts( "LOCAL", cParam )
              ::Local()
           CASE starts( "PRIVATE", cParam )
              ::Private()
           CASE starts( "PUBLIC", cParam )
              ::Public()
           CASE starts( "SORT", cParam )
              ::Sort()
           CASE starts( "STATIC", cParam )
              ::Static()
           OTHERWISE
              cResult := "Command error"
         ENDCASE

      CASE starts( "NEXT", cCommand )
         ::FindNext()

      CASE starts( "NUM", cCommand )
         IF Upper( cParam ) == "OFF"
            ::LineNumbers( .F. )
         ELSEIF Upper( cParam ) == "ON"
            ::LineNumbers( .T. )
         ELSE
            cResult := "Command error"
         ENDIF

      CASE starts( "OPTIONS", cCommand )
         IF ( n := At( " ", cParam ) ) > 0
            cParam1 := AllTrim( SubStr( cParam, n + 1 ) )
            cParam := Left( cParam, n - 1 )
         ENDIF
         cParam := Upper( cParam )
         DO CASE
            CASE starts( "COLORS", cParam )
               IF Empty( cParam1 )
                  ::Colors()
               ELSE
                  cParam1 := SubStr( cParam1, At( "{", cParam1 ) + 1 )
                  FOR n := 1 TO 11
                     IF At( ",", cParam1 ) != 0
                        ::aColors[ n ] := ;
                           StrTran( Left( cParam1, At( ",", cParam1 ) - 1 ), '"', "" )
                        cParam1 := SubStr( cParam1, At( ",", cParam1 ) + 1 )
                     ELSE
                        ::aColors[ n ] := ;
                           StrTran( Left( cParam1, At( "}", cParam1 ) - 1 ), '"', "" )
                     ENDIF
                  NEXT
                  ::LoadColors()
               ENDIF
            CASE starts( "NORUNATSTARTUP", cParam )
               ::lRunAtStartup := .f.
            CASE starts( "PATH", cParam )
               ::PathForFiles( AllTrim( cParam1 ) )
            CASE starts( "TAB", cParam )
               ::nTabWidth = Val( Left( cParam1, 3 ) )
            OTHERWISE
               cResult := "Command error"
         ENDCASE

      CASE starts( "OUTPUT", cCommand )
         SetCursor( SC_NONE )
         ::ShowAppScreen()
         SetCursor( SC_NORMAL )

      CASE starts( "PREV", cCommand )
         ::FindPrevious()

      CASE starts( "QUIT", cCommand )
         ::Quit()

      /* TODO: Support RESTART */

      CASE starts( "RESUME", cCommand )
         ::Resume()

      CASE starts( "SPEED", cCommand )
         ::nSpeed := Val( cParam )

      CASE starts( "STEP", cCommand )
         ::Step()

      CASE starts( "TP", cCommand )
         ::TracepointAdd( cParam )

      CASE starts( "VIEW", cCommand )
         IF !Empty( cParam ) .AND. starts( "CALLSTACK", Upper( cParam ) )
            ::Stack()
         ELSE
            cResult := "Command error"
         ENDIF

      CASE starts( "WINDOW", cCommand )
         IF ( n := At( " ", cParam ) ) > 0
            cParam1 := AllTrim( SubStr( cParam, n + 1 ) )
            cParam := Left( cParam, n - 1 )
         ENDIF
         DO CASE
            CASE starts( "MOVE", cParam )
               WITH OBJECT ::aWindows[ ::nCurrentWindow ]
                  n := At( " ", cParam1 )
                  IF n > 0
                    n := Val( SubStr( cParam1, n ) )
                  ENDIF
                  :Resize( Val( cParam1 ), n, ;
                           :nBottom + Val( cParam1 ) - :nTop, :nRight + n - :nLeft )
               END
            CASE starts( "NEXT", cParam )
               ::NextWindow()
            CASE starts( "SIZE", cParam )
               WITH OBJECT ::aWindows[ ::nCurrentWindow ]
                  n := At( " ", cParam1 )
                  IF Val( cParam1 ) >= 2 .AND. n > 0 .AND. Val( SubStr( cParam1, n ) ) > 0
                     :Resize( :nTop, :nLeft, Val( cParam1 ) - 1 + :nTop, ;
                              Val( SubStr( cParam1, n ) ) - 1 + :nLeft )
                  ENDIF
               END
          ENDCASE

      CASE starts( "WP", cCommand )
         ::WatchpointAdd( cParam )

      OTHERWISE
         cResult := "Command error"

   ENDCASE

   IF ::lActive
      DispOutAt( ::oWndCommand:nBottom - 1, ::oWndCommand:nLeft + 1, ;
                 Space( ::oWndCommand:nRight - ::oWndCommand:nLeft - 1 ), ;
                 __DbgColors()[ 2 ] )
      IF !Empty( cResult )
         DispOutAt( ::oWndCommand:nBottom - 1, ::oWndCommand:nLeft + 3, ;
                     cResult, __DbgColors()[ 2 ] )
         ::oWndCommand:ScrollUp( 1 )
      ENDIF
   ENDIF

RETURN cResult


METHOD DoScript( cFileName ) CLASS TDebugger

   local cInfo
   local n, cLine, nLen

   IF File( cFileName )
      cInfo := MemoRead( cFileName )
      nLen := MLCount( cInfo, , , .F. )
      for n := 1 to nLen
         cLine := MemoLine( cInfo, 16384, n, , .F., .T. )
         ::DoCommand( cLine )
      next
   ENDIF

RETURN NIL


METHOD EditColor( nColor, oBrwColors ) CLASS TDebugger

   local GetList    := {}
   local lPrevScore := Set( _SET_SCOREBOARD, .f. )
   local lPrevExit  := Set( _SET_EXIT, .t. )
   local cColor     := PadR( '"' + ::aColors[ nColor ] + '"',;
                             oBrwColors:getColumn(2):Width )

   oBrwColors:RefreshCurrent()
   oBrwColors:ForceStable()

#ifndef HB_NO_READDBG
   SetCursor( SC_NORMAL )
   @ Row(), Col() + 15 GET cColor COLOR SubStr( ::ClrModal(), 5 ) ;
      VALID iif( Type( cColor ) != "C", ( Alert( "Must be string" ), .f. ), .t. )

   READ
   SetCursor( SC_NONE )
#else
   cColor := getdbginput( Row(), Col() + 15, cColor,  { |cColor| iif( Type( cColor ) != "C", ( Alert( "Must be string" ), .f. ), .t. ) }, SubStr( ::ClrModal(), 5 ) )
#endif

   Set( _SET_SCOREBOARD, lPrevScore )
   Set( _SET_EXIT, lPrevExit )

   if LastKey() != K_ESC
      ::aColors[ nColor ] := &cColor
   endif

   oBrwColors:RefreshCurrent()
   oBrwColors:ForceStable()

return nil

METHOD EditSet( nSet, oBrwSets ) CLASS TDebugger

   local GetList    := {}
   local lPrevScore := Set( _SET_SCOREBOARD, .f. )
   local lPrevExit  := Set( _SET_EXIT, .t. )
   local cSet       := PadR( ValToStr( Set( nSet ) ), oBrwSets:getColumn(2):Width )
   local cType      := VALTYPE(SET(nSet))

   oBrwSets:RefreshCurrent()
   oBrwSets:ForceStable()

#ifndef HB_NO_READDBG
   SetCursor( SC_NORMAL )
   @ Row(), Col()+13 GET cSet COLOR SubStr( ::ClrModal(), 5 ) ;
     VALID iif( Type(cSet) != cType, (Alert( "Must be of type '"+cType+"'" ), .f. ), .t. )

   READ
   SetCursor( SC_NONE )
#else
   cSet := getdbginput( Row(), Col()+13, cSet, { |cSet| iif( Type(cSet) != cType, (Alert( "Must be of type '"+cType+"'" ), .f. ), .t. ) }, SubStr( ::ClrModal(), 5 ) )
#endif

   Set( _SET_SCOREBOARD, lPrevScore )
   Set( _SET_EXIT, lPrevExit )

   if LastKey() != K_ESC
      Set( nSet, &cSet )
   endif

   oBrwSets:RefreshCurrent()
   oBrwSets:ForceStable()

return nil


METHOD EditVar( nVar ) CLASS TDebugger

   local cVarName   := ::aVars[ nVar ][ 1 ]
   local uVarValue  := ::aVars[ nVar ][ 2 ]
   local cVarType   := ::aVars[ nVar ][ 3 ]
   local aArray
   local cVarStr

   uVarValue := ::VarGetValue( ::aVars[ nVar ] )

   do case
      case ValType( uVarValue ) == "A"
           ::InputBox( cVarName, uVarValue,, .f. )

      case ValType( uVarValue ) == "O"
           ::InputBox( cVarName, uVarValue,, .f. )

      otherwise
           cVarStr := ::InputBox( cVarName, ValToStr( uVarValue ),;
       { | u | If( Type( u ) == "UE", ( Alert( "Expression error" ), .f. ), .t. ) } )
   endcase

   if LastKey() != K_ESC
      do case
         case cVarStr == "{ ... }"
            //aArray := ::VarGetValue( ::aVars[ nVar ] )
            if Len( uVarValue ) > 0
               __DbgArrays( uVarValue, cVarName )
            else
               Alert( "Array is empty" )
            endif

         case Upper( SubStr( cVarStr, 1, 5 ) ) == "CLASS"
            __DbgObject( uVarValue, cVarName )

         otherwise
            ::VarSetValue( ::aVars[ nVar ], &cVarStr )
      endcase
   endif

   ::oBrwVars:RefreshCurrent()
   ::oBrwVars:ForceStable()

return nil


METHOD FindNext() CLASS TDebugger
RETURN ::Locate( 1, ::cSearchString )


METHOD FindPrevious() CLASS TDebugger
RETURN ::Locate( 2, ::cSearchString )


METHOD GetExprValue( xExpr, lValid ) CLASS TDebugger
  LOCAL xResult, oErr, bOldErrorBlock

  lValid := .F.
  bOldErrorBlock := ErrorBlock( {|oErr| Break( oErr ) } )
  BEGIN SEQUENCE
    xResult := HB_INLINE( ::pInfo, xExpr, @lValid )
    {
      PHB_ITEM item;
      
      if ( ISCHAR( 2 ) )
      {
        item = hb_dbgGetExpressionValue( hb_parptr( 1 ), hb_parc( 2 ) );
      }
      else
      {
        item = hb_dbgGetWatchValue( hb_parptr( 1 ), hb_parni( 2 ) - 1 );
      }

      if ( item )
      {
        hb_itemRelease( hb_itemReturn( item ) );
        hb_storl( TRUE, 3 );
      }
      else
      {
        hb_storl( FALSE, 3 );
        hb_ret();
      }
    }
    IF !lValid
      xResult := "Syntax error"
    ENDIF
  RECOVER USING oErr
    xResult := oErr:operation + ": " + oErr:description
    IF ValType( oErr:args ) == 'A'
      xResult += "; arguments:"
      AEval( oErr:args, {|x| xResult += " " + AllTrim( CStr( x ) ) } )
    ENDIF
    lValid := .F.
  END SEQUENCE
  ErrorBlock( bOldErrorBlock )
RETURN xResult


METHOD Go() CLASS TDebugger
  // we are starting to run again so reset to the deepest call if
  // displaying stack
  IF ! ::oBrwStack == NIL
    ::oBrwStack:GoTop()
  ENDIF
  ::RestoreAppScreen()
  ::RestoreAppState()
  HB_INLINE( ::pInfo )
  {
    hb_dbgSetGo( hb_parptr( 1 ) );
  }
  ::Exit()
RETURN NIL


METHOD GotoLine( nLine ) CLASS TDebugger

   local nRow, nCol

   /*if ::oBrwVars != nil
      ::ShowVars()
   endif*/

   ::oBrwText:GotoLine( nLine )
   nRow = Row()
   nCol = Col()

   // no source code line stored yet
   /*if ::oBrwStack != nil .and. Len( ::aCallStack ) > 0 .and. ;
      ::aCallStack[ ::oBrwStack:Cargo ][ CSTACK_LINE ] == nil
      ::aCallStack[ ::oBrwStack:Cargo ][ CSTACK_LINE ] = nLine
   endif*/

   if ::oWndStack != nil .and. ! ::oBrwStack:Stable
      ::oBrwStack:ForceStable()
   endif

   if ::oWndCode:lFocused .and. SetCursor() != SC_SPECIAL1
      SetPos( nRow, nCol )
      SetCursor( SC_SPECIAL1 )
   endif
   SetPos( nRow, nCol )

   // Store cursor position to be restored by ::oWndCode:bGotFocus
   ::oWndCode:cargo[ 1 ] := nRow
   ::oWndCode:cargo[ 2 ] := nCol

return nil


METHOD HandleEvent() CLASS TDebugger

   local nPopup, oWnd
   local nKey, nMRow, nMCol, n

   if ::lAnimate
      if ::nSpeed != 0
         Inkey( ::nSpeed / 10 )
      endif
      if HB_DBG_INVOKEDEBUG()  //NextKey() == K_ALT_D
         ::lAnimate := .f.
      else
         ::Step()
         RETURN nil
      endif
   endif

   ::lEnd := .f.

   while ! ::lEnd

      nKey := InKey( 0, INKEY_ALL )

      do case
         case nKey == K_ALT_X
              s_oDebugger:Quit()

         case ::oPullDown:IsOpen()
              ::oPullDown:ProcessKey( nKey )
              if ::oPullDown:nOpenPopup == 0 // Closed
                 ::aWindows[ ::nCurrentWindow ]:SetFocus( .t. )
              endif

         case nKey == K_LDBLCLK
              if MRow() == 0

              elseif MRow() == ::nMaxRow

              else
                 nMRow := MRow()
                 nMCol := MCol()
                 for n := 1 to Len( ::aWindows )
                    if ::aWindows[ n ]:IsOver( nMRow, nMCol )
                       if ! ::aWindows[ n ]:lFocused
                          ::aWindows[ ::nCurrentWindow ]:SetFocus( .f. )
                          ::nCurrentWindow := n
                          ::aWindows[ n ]:SetFocus( .t. )
                       endif
                       ::aWindows[ n ]:LDblClick( nMRow, nMCol )
                       exit
                    endif
                 next
              endif

         case nKey == K_LBUTTONDOWN
              if MRow() == 0
                 if ( nPopup := ::oPullDown:GetItemOrdByCoors( 0, MCol() ) ) != 0
                    if ! ::oPullDown:IsOpen()
                       if ::oWndCode:lFocused
                          Eval( ::oWndCode:bLostFocus )
                       endif
                       SetCursor( SC_NONE )
                    endif
                    ::oPullDown:ShowPopup( nPopup )
                 endif

              elseif MRow() == ::nMaxRow

              else
                 nMRow := MRow()
                 nMCol := MCol()
                 for n := 1 to Len( ::aWindows )
                    if ::aWindows[ n ]:IsOver( nMRow, nMCol )
                       if ! ::aWindows[ n ]:lFocused
                          ::aWindows[ ::nCurrentWindow ]:SetFocus( .f. )
                          ::nCurrentWindow := n
                          ::aWindows[ n ]:SetFocus( .t. )
                       endif
                       ::aWindows[ n ]:LButtonDown( nMRow, nMCol )
                       exit
                    endif
                 next
              endif

         case nKey == K_RBUTTONDOWN

         /*case nKey == K_ESC
              ::RestoreAppStatus()
              s_oDebugger := nil
              s_lExit := .T.
              DispEnd()
              ::Exit()*/

         case nKey == K_UP .or. nKey == K_DOWN .or. nKey == K_HOME .or. ;
              nKey == K_END .or. nKey == K_ENTER .or. nKey == K_PGDN .or. ;
              nKey == K_PGUP .or. nKey == K_DEL .or. nKey == K_LEFT .or. ;
              nKey == K_RIGHT .or. nKey == K_CTRL_ENTER
              oWnd := ::aWindows[ ::nCurrentWindow ]
              oWnd:KeyPressed( nKey )

         case nKey == K_F1
              ::ShowHelp()

         case nKey == K_F4
              ::ShowAppScreen()

         case nKey == K_F5
              ::Go()

         case nKey == K_CTRL_F5
              ::NextRoutine()

         case nKey == K_F6
              ::ShowWorkAreas()

         case nKey == K_F7
              ::ToCursor()

         case nKey == K_F8
              ::Step()

         case nKey == K_F9
              ::ToggleBreakPoint()

         case nKey == K_F10
              ::Trace()

         case nKey == K_TAB
              ::NextWindow()

         case nKey == K_SH_TAB
              ::PrevWindow()

         case ::oWndCommand:lFocused .and. nKey < 272 // Alt
              ::oWndCommand:KeyPressed( nKey )

         otherwise
              if ( nPopup := ::oPullDown:GetHotKeyPos( __dbgAltToKey( nKey ) ) ) != 0
                 if ::oPullDown:nOpenPopup != nPopup
                    if ::oWndCode:lFocused
                       Eval( ::oWndCode:bLostFocus )
                    endif
                    SetCursor( SC_NONE )
                    ::oPullDown:ShowPopup( nPopup )
                 endif
              endif
      endcase
   end

return nil

METHOD Hide() CLASS TDebugger

   RestScreen( ,,,, ::cAppImage )
   ::cAppImage := nil
   SetColor( ::cAppColors )
   SetCursor( ::nAppCursor )

return nil


METHOD HideCallStack() CLASS TDebugger

   ::lShowCallStack = .f.

   if ::oWndStack != nil
      DispBegin()
      ::oWndStack:Hide()
      if ::aWindows[ ::nCurrentWindow ] == ::oWndStack
        ::NextWindow()
      endif
      ::RemoveWindow( ::oWndStack )
      ::oWndStack = nil

      ::oWndCode:Resize(,,, ::oWndCode:nRight + 16 )
      if ::oWndVars != nil
         ::oWndVars:Resize(,,, ::oWndVars:nRight + 16 )
      endif
      if ::oWndPnt != nil
         ::oWndPnt:Resize(,,, ::oWndPnt:nRight + 16 )
      endif
      DispEnd()
   endif

return nil


METHOD HideVars() CLASS TDebugger

   ::oWndVars:Hide()
   ::oWndCode:nTop := 1
   ::oBrwText:Resize( ::oWndCode:nTop+1 )
   IF ::oWndCode:lFocused
      ::oWndCode:cargo[ 1 ] := Row()
      ::oWndCode:cargo[ 2 ] := Col()
   ENDIF

   if ::aWindows[ ::nCurrentWindow ] == ::oWndVars
      ::NextWindow()
   ENDIF

return nil


METHOD InputBox( cMsg, uValue, bValid, lEditable ) CLASS TDebugger

   local nTop    := ( ::nMaxRow / 2 ) - 5
   local nLeft   := ( ::nMaxCol / 2 ) - 25
   local nBottom := ( ::nMaxRow / 2 ) - 3
   local nRight  := ( ::nMaxCol / 2 ) + 25
   local cType   := ValType( uValue )
   local uTemp   := PadR( uValue, nRight - nLeft - 1 )
   local GetList := {}
   local nOldCursor
   local lScoreBoard := Set( _SET_SCOREBOARD, .f. )
   local lExit
   local oWndInput := TDbWindow():New( nTop, nLeft, nBottom, nRight, cMsg,;
                                       ::oPullDown:cClrPopup )

   DEFAULT lEditable TO .t.

   oWndInput:lShadow := .t.
   oWndInput:Show()

   if lEditable
#ifndef HB_NO_READDBG
      if bValid == nil
         @ nTop + 1, nLeft + 1 GET uTemp COLOR "," + __DbgColors()[ 5 ]
      else
          @ nTop + 1, nLeft + 1 GET uTemp VALID Eval( bValid, uTemp ) ;
           COLOR "," + __DbgColors()[ 5 ]
      endif

      nOldCursor := SetCursor( SC_NORMAL )
      READ
      SetCursor( nOldCursor )
#else
      uTemp := getdbginput( nTop + 1, nLeft + 1, uTemp, bValid, __DbgColors()[ 5 ] )
#endif
   else
      @ nTop + 1, nLeft + 1 SAY ValToStr( uValue ) COLOR "," + __DbgColors()[ 5 ]
      SetPos( nTop + 1, nLeft + 1 )
      nOldCursor := SetCursor( SC_NONE )

      lExit = .f.

      while ! lExit
         Inkey( 0 )

         do case
            case LastKey() == K_ESC
               lExit = .t.

            case LastKey() == K_ENTER
               if cType == "A"
                  if Len( uValue ) == 0
                     Alert( "Array is empty" )
                  else
                     __DbgArrays( uValue, cMsg )
                  endif

               elseif cType == "O"
                  __DbgObject( uValue, cMsg )

               else
                  Alert( "Value cannot be edited" )
               endif

            otherwise
               Alert( "Value cannot be edited" )
         endcase
      end

      SetCursor( nOldCursor )
   endif

#ifndef HB_NO_READDBG
   nOldCursor := SetCursor( SC_NORMAL )
   READ
   SetCursor( nOldCursor )
#endif

   oWndInput:Hide()
   Set( _SET_SCOREBOARD, lScoreBoard )

   do case
      case cType == "C"
           uTemp := AllTrim( uTemp )

      case cType == "D"
           uTemp := CToD( uTemp )

      case cType == "N"
           uTemp := Val( uTemp )

   endcase

return iif( LastKey() != K_ESC, uTemp, uValue )


METHOD Inspect( uValue, cValueName ) CLASS TDebugger

   uValue = ::InputBox( uValue, cValueName,, .f. )

return nil


METHOD LineNumbers( lLineNumbers ) CLASS TDebugger

   If( lLineNumbers == NIL, lLineNumbers := !::lLineNumbers, )
   ::lLineNumbers := lLineNumbers
   ::oPulldown:GetItemByIdent( "LINE" ):checked := ::lLineNumbers
   IF ::oBrwText != NIL
      ::oBrwText:lLineNumbers := lLineNumbers
      ::oBrwText:RefreshAll()
   ENDIF

return Self


METHOD LoadCallStack() CLASS TDebugger
  LOCAL i
  LOCAL nDebugLevel
  LOCAL nCurrLevel
  LOCAL nlevel, nPos

  ::aProcStack := ARRAY( ::nProcLevel )
  nCurrLevel := hb_dbg_ProcLevel() - 1
  nDebugLevel := nCurrLevel - ::nProcLevel + 1
  FOR i := nDebugLevel TO nCurrLevel
    nLevel := nCurrLevel - i + 1
    nPos := ASCAN( ::aCallStack, {|a| a[CSTACK_LEVEL] == nLevel} )
    IF ( nPos > 0 )
      //a procedure with debug info
      ::aProcStack[i-nDebugLevel+1] := ::aCallStack[ nPos ]
    ELSE
      ::aProcStack[i-nDebugLevel+1] := { , PROCNAME( i )+"("+NTRIM(PROCLINE(i))+")", , nLevel, , }
    ENDIF
  NEXT
RETURN NIL


METHOD LoadColors() CLASS TDebugger

   LOCAL n

   ::oPullDown:LoadColors()
   IF ::lActive
      ::oPullDown:Refresh()
      ::BarDisplay()
   ENDIF
   for n := 1 to Len( ::aWindows )
      ::aWindows[ n ]:LoadColors()
      IF ::lActive
         ::aWindows[ n ]:Refresh()
      ENDIF
   next

RETURN NIL


METHOD LoadSettings() CLASS TDebugger
   ::DoScript( ::cSettingsFileName )
return nil


METHOD LoadVars() CLASS TDebugger // updates monitored variables

   local nCount, n, m, xValue, cName
   local cStaticName, nStaticIndex, nStaticsBase
   LOCAL aVars
   LOCAL aBVars

   aBVars := {}

   if ::lShowPublics
      nCount := __mvDbgInfo( HB_MV_PUBLIC )
      for n := nCount to 1 step -1
         xValue := __mvDbgInfo( HB_MV_PUBLIC, n, @cName )
         //if cName != "__DBGSTATICS"  // reserved public used by the debugger
            AAdd( aBVars, { cName, xValue, "Public" } )
         //endif
      next
   endif

   if ::lShowPrivates
      nCount := __mvDbgInfo( HB_MV_PRIVATE )
      for n := nCount to 1 step -1
         xValue := __mvDbgInfo( HB_MV_PRIVATE, n, @cName )
         AAdd( aBVars, { cName, xValue, "Private" } )
      next
   endif

   IF ::aProcStack[ ::oBrwStack:Cargo ][ CSTACK_LINE ] != nil
      if ::lShowStatics
         cName := ::aProcStack[ ::oBrwStack:Cargo ][ CSTACK_MODULE ]
         n := ASCAN( ::aStaticModules, {|a| FILENAME_EQUAL( a[1], cName ) } )
         IF ( n > 0 )
            aVars := ::aStaticModules[ n ][ 2 ]
            for m := 1 to Len( aVars )
               AAdd( aBVars, aVars[ m ] )
            next
         ENDIF
         aVars := ::aProcStack[ ::oBrwStack:Cargo ][ CSTACK_STATICS ]
         for n := 1 to Len( aVars )
            AAdd( aBVars, aVars[ n ] )
         next
      endif

      if ::lShowLocals
         aVars := ::aProcStack[ ::oBrwStack:Cargo ][ CSTACK_LOCALS ]
         for n := 1 to Len( aVars )
            cName := aVars[ n ][ VAR_NAME ]
            m := AScan( aBVars,; // Is there another var with this name ?
                        { | aVar | aVar[ VAR_NAME ] == cName .AND. Left( aVar[ VAR_TYPE ], 1 ) == 'S' } )
            IF ( m > 0 )
               aBVars[ m ] := aVars[ n ]
            ELSE
               AAdd( aBVars, aVars[ n ] )
            ENDIF
         next
      endif
   ENDIF

   IF( ::oBrwVars != NIL .AND. ::oBrwVars:cargo[1] > LEN(aBVars) )
     ::oBrwVars:gotop()
   ENDIF
   ::aVars := aBVars
   if ::lSortVars
      ::Sort()
   endif

return nil


METHOD Local() CLASS TDebugger
   ::lShowLocals := ! ::lShowLocals
   ::RefreshVars()
return nil


METHOD Locate( nMode, cValue ) CLASS TDebugger
  LOCAL lFound

  DEFAULT nMode TO 0

  IF Empty( cValue )
    cValue := ::InputBox( "Search string", ::cSearchString )
    IF Empty( cValue )
      RETURN NIL
    ENDIF
  ENDIF

  ::cSearchString := cValue

  lFound := ::oBrwText:Search( ::cSearchString, ::lCaseSensitive, nMode )

  // Save cursor position to be restored by ::oWndCode:bGotFocus
  ::oWndCode:cargo[ 1 ] := Row()
  ::oWndCode:cargo[ 2 ] := Col()
RETURN lFound


METHOD LocatePrgPath( cPrgName ) CLASS TDebugger

   local i
   local iMax
   local aPaths
   local cRetPrgName
   local cSep

   cSep := HB_OsPathSeparator()

   aPaths := ::aPathDirs

   iMax := len( aPaths )

   for i := 1 to iMax
       cRetPrgName := aPaths[i] + cSep + cPrgName
       if file( cRetPrgName )
          exit
       else
          cRetPrgName := nil
       endif
   next i

return cRetPrgName


METHOD MonoDisplay() CLASS TDebugger

   ::lMonoDisplay := ! ::lMonoDisplay
   ::oPullDown:GetItemByIdent( "MONO" ):checked := ::lMonoDisplay
   ::LoadColors()

return nil


METHOD NextRoutine() CLASS TDebugger
  ::RestoreAppScreen()
  ::RestoreAppState()
  HB_INLINE( ::pInfo )
  {
    hb_dbgSetNextRoutine( hb_parptr( 1 ) );
  }
  ::Exit()
RETURN self


METHOD NextWindow() CLASS TDebugger

   local oWnd

   if Len( ::aWindows ) > 0
      oWnd := ::aWindows[ ::nCurrentWindow++ ]
      oWnd:SetFocus( .f. )
      if ::nCurrentWindow > Len( ::aWindows )
         ::nCurrentWindow := 1
      endif
      while ! ::aWindows[ ::nCurrentWindow ]:lVisible
         ::nCurrentWindow++
         if ::nCurrentWindow > Len( ::aWindows )
            ::nCurrentWindow := 1
         endif
      end
      oWnd := ::aWindows[ ::nCurrentWindow ]
      oWnd:SetFocus( .t. )
   endif

return nil


METHOD Open() CLASS TDebugger
   LOCAL cFileName := ::InputBox( "Please enter the filename", Space( 255 ) )
   LOCAL cPrgName

   cFileName:= ALLTRIM( cFileName )

   IF ( !Empty( cFileName ) ;
        .AND. ( ValType( ::cPrgName ) == 'U' .OR. !FILENAME_EQUAL( cFileName, ::cPrgName ) ) )
      if ! File( cFileName ) .and. ! Empty( ::cPathForFiles )
         cFileName := ::LocatePrgPath( cFileName )
         if Empty( cFileName )
           Alert( "File not found!" )
           return NIL
         endif
      endif
      ::cPrgName := cFileName
      ::lppo := RAT(".PPO", UPPER(cFileName)) > 0
      ::oPulldown:GetItemByIdent( "PPO" ):Checked := ::lppo
      ::oBrwText := nil
      ::oBrwText := TBrwText():New( ::oWndCode:nTop + 1, ::oWndCode:nLeft + 1,;
                   ::oWndCode:nBottom - 1, ::oWndCode:nRight - 1, cFileName,;
                   __DbgColors()[ 2 ] + "," + __DbgColors()[ 5 ] + "," + ;
                   __DbgColors()[ 3 ] + "," + __DbgColors()[ 6 ], ;
                   ::lLineNumbers )
      ::oWndCode:Browser := ::oBrwText
      ::RedisplayBreakpoints()               // check for breakpoints in this file and display them
      ::oWndCode:SetCaption( ::cPrgName )
      ::oWndCode:Refresh()       // to force the window caption to update
   endif
return nil


METHOD OpenPPO() CLASS TDebugger
   LOCAL nPos
   LOCAL lSuccess:=.F.

   IF Empty( ::cPrgName )
      RETURN .F.
   ENDIF

   nPos := RAT(".PPO", UPPER(::cPrgName))
   IF( nPos == 0 )
      nPos := RAT(".PRG", UPPER(::cPrgName))
      IF( nPos > 0 )
         ::cPrgName := LEFT(::cPrgName,nPos-1) + ".ppo"
      ELSE
         ::cPrgName += ".ppo"
      ENDIF
      lSuccess := FILE(::cPrgName)
      ::lppo := lSuccess
   ELSE
      ::cPrgName := LEFT(::cPrgName,nPos-1) + ".prg"
      lSuccess := FILE( ::cPrgName )
      ::lppo := !lSuccess
   ENDIF

   IF( lSuccess )
      ::oBrwText := nil
      ::oBrwText := TBrwText():New( ::oWndCode:nTop + 1, ::oWndCode:nLeft + 1,;
        ::oWndCode:nBottom - 1, ::oWndCode:nRight - 1, ::cPrgName,;
        __DbgColors()[ 2 ] + "," + __DbgColors()[ 5 ] + "," + ;
        __DbgColors()[ 3 ] + "," + __DbgColors()[ 6 ], ::lLineNumbers )
      ::oWndCode:Browser := ::oBrwText
      ::RedisplayBreakpoints()               // check for breakpoints in this file and display them
      ::oWndCode:SetCaption( ::cPrgName )
      ::oWndCode:Refresh()// to force the window caption to update
   endif

   ::oPullDown:GetItemByIdent( "PPO" ):checked := ::lPPO

return lSuccess


METHOD OSShell() CLASS TDebugger

   local cImage := SaveScreen()
   local cColors := SetColor()
   local cOs    := Upper( OS() )
   local cShell
   local bLastHandler := ErrorBlock({ |objErr| BREAK (objErr) })
   local oE

   SET COLOR TO "W/N"
   CLS
   ? "Type 'exit' to return to the Debugger"
   SetCursor( SC_NORMAL )

   begin sequence
      if At("WINDOWS", cOs) != 0 .OR. At("DOS", cOs) != 0 .OR. At("OS/2", cOs) != 0
         cShell := GetEnv("COMSPEC")
         RUN ( cShell )
      elseif At("LINUX", cOs) != 0 .OR. At( "BSD", cOs ) != 0 .OR. At( "DARWIN", cOs ) != 0
         cShell := GetEnv("SHELL")
         RUN ( cShell )
      else
         Alert( "Not implemented yet!" )
      endif

   recover using oE
      Alert("Error: " + oE:description)

   end sequence

   ErrorBlock(bLastHandler)

   SetCursor( SC_NONE )
   RestScreen( ,,,, cImage )
   SetColor( cColors )

return nil


METHOD Quit() CLASS TDebugger
  ::Exit()
  ::Hide()
  HB_INLINE( ::pInfo )
  {
    hb_dbgSetQuit( hb_parptr( 1 ) );
  }
  s_oDebugger := NIL
  __QUIT()
RETURN NIL


METHOD PathForFiles( cPathForFiles ) CLASS TDebugger

   IF cPathForFiles == NIL
      cPathForFiles := ::InputBox( "Search path for source files:", ::cPathForFiles )
   ENDIF
   ::cPathForFiles := cPathForFiles
   ::aPathDirs := PathToArray( ::cPathForFiles )

   ::Resume()
RETURN Self


METHOD PrevWindow() CLASS TDebugger

   local oWnd

   if Len( ::aWindows ) > 0
      oWnd := ::aWindows[ ::nCurrentWindow-- ]
      oWnd:SetFocus( .f. )
      if ::nCurrentWindow < 1
         ::nCurrentWindow := Len( ::aWindows )
      endif
      while ! ::aWindows[ ::nCurrentWindow ]:lVisible
         ::nCurrentWindow--
         if ::nCurrentWindow < 1
            ::nCurrentWindow := Len( ::aWindows )
         endif
      end
      oWnd := ::aWindows[ ::nCurrentWindow ]
      oWnd:SetFocus( .t. )
   endif

return nil


METHOD Private() CLASS TDebugger
   ::lShowPrivates := ! ::lShowPrivates
   ::RefreshVars()
return nil


METHOD Public() CLASS TDebugger
   ::lShowPublics := ! ::lShowPublics
   ::RefreshVars()
return nil


// check for breakpoints in the current file and display them
METHOD RedisplayBreakPoints() CLASS TDebugger
  LOCAL n
  
  FOR n := 1 TO Len( ::aBreakpoints )
    IF FILENAME_EQUAL( ::aBreakpoints[ n ][ 2 ], strip_path( ::cPrgName ) )
      ::oBrwText:ToggleBreakPoint(::aBreakpoints[ n ][ 1 ], .T.)
    ENDIF
  NEXT
RETURN NIL


METHOD RefreshVars() CLASS TDebugger
   ::oPulldown:GetItemByIdent( "LOCAL" ):checked := ::lShowLocals
   ::oPulldown:GetItemByIdent( "PRIVATE" ):checked := ::lShowPrivates
   ::oPulldown:GetItemByIdent( "PUBLIC" ):checked := ::lShowPublics
   ::oPulldown:GetItemByIdent( "STATIC" ):checked := ::lShowStatics
   ::oPulldown:GetItemByIdent( "ALL" ):checked := ::lAll
   IF ::lActive
      if ::lShowPublics .or. ::lShowPrivates .or. ::lShowStatics .or. ::lShowLocals
         ::LoadVars()
         ::ShowVars()
      else
         ::HideVars()
      endif
   ENDIF
RETURN NIL


METHOD RemoveWindow( oWnd ) CLASS TDebugger

  local n := AScan( ::aWindows, { | o | o == oWnd } )

  if n != 0
     ::aWindows = ADel ( ::aWindows, n )
     ::aWindows = ASize( ::aWindows, Len( ::aWindows ) - 1 )
  endif

  ::nCurrentWindow = 1

return nil


METHOD ResizeWindows( oWindow ) CLASS TDebugger
  LOCAL oWindow2, nTop, i

  IF oWindow == ::oWndVars
    oWindow2 := ::oWndPnt
  ELSEIF oWindow == ::oWndPnt
    oWindow2 := ::oWndVars
  ENDIF

  DispBegin()
  IF oWindow2 == NIL
    nTop := oWindow:nBottom +1
  ELSE
    IF oWindow2:lVisible
      IF oWindow:nTop < oWindow2:nTop
        nTop := oWindow2:nBottom - oWindow2:nTop + 1
        oWindow2:Resize( oWindow:nBottom+1,, oWindow:nBottom+nTop)
      ELSE
        nTop := oWindow:nBottom - oWindow:nTop + 1
        oWindow:Resize( oWindow2:nBottom+1,, oWindow2:nBottom+nTop)
      ENDIF
      nTop := MAX( oWindow:nBottom, oWindow2:nBottom ) + 1
    ELSE
      IF oWindow:nTop > 1
        nTop := oWindow:nBottom - oWindow:nTop + 1
        oWindow:Resize( 1, , nTop )
      ENDIF
      nTop := oWindow:nBottom + 1
    ENDIF
  ENDIF

  oWindow:hide()
  IF oWindow2 != NIL
    oWindow2:hide()
  ENDIF

  ::oWndCode:Resize( nTop )
  IF ::oWndCode:lFocused
    ::oWndCode:cargo[ 1 ] := Row()
    ::oWndCode:cargo[ 2 ] := Col()
  ENDIF

  IF oWindow2 != NIL
    oWindow2:show()
  ENDIF
  oWindow:show()
  DispEnd()

RETURN self


METHOD RestoreAppScreen() CLASS TDebugger
  LOCAL i
  
  ::cImage := SaveScreen()
  DispBegin()
  RestScreen( 0, 0, ::nMaxRow, ::nMaxCol, ::cAppImage )
  IF !Empty( ::nAppCTWindow )
    /* Don't link libct automatically... */
    HB_INLINE( ::nAppCTWindow )
    {
       hb_ctWSelect( hb_parni( 1 ) );
    }
  ENDIF
  SetPos( ::nAppRow, ::nAppCol )
  SetColor( ::cAppColors )
  SetCursor( ::nAppCursor )
  DispEnd()
  FOR i := 1 TO ::nAppDispCount
    DispBegin()
  NEXT
return nil


METHOD RestoreAppState() CLASS TDebugger
  Set( _SET_DIRCASE, ::nAppDirCase )
  Set( _SET_FILECASE, ::nAppFileCase )
  Set( _SET_TYPEAHEAD, ::nAppTypeAhead )
  SetLastKey( ::nAppLastKey )
  SetInkeyAfterBlock( ::bAppInkeyAfter )
  SetInkeyBeforeBlock( ::bAppInkeyBefore )
  __SetClassScope( ::bAppClassScope )
  __GetListSetActive( ::oAppGetList )
RETURN NIL


METHOD RestoreSettings() CLASS TDebugger

   local n

   ::cSettingsFileName := ::InputBox( "File name", ::cSettingsFileName )

   if LastKey() != K_ESC
      ::LoadSettings()
      ::ShowVars()
   endif

return nil


METHOD SaveAppScreen( lRestore ) CLASS TDebugger
  LOCAL nRight, nTop, i
  
  IF lRestore == NIL
    lRestore := .T.
  ENDIF

  ::nAppDispCount := DispCount()
  FOR i := 1 TO ::nAppDispCount
    DispEnd()
  NEXT
  
  DispBegin()
 
  /* Get cursor coordinates INSIDE ct window */
  ::nAppRow    := Row()
  ::nAppCol    := Col()
  ::cAppColors := SetColor()

  /* We don't want to auto-link libct... */
  ::nAppCTWindow := HB_INLINE()
  {
     hb_retni( hb_ctWSelect( -1 ) );
     hb_ctWSelect( 0 );
  }
  
  ::cAppImage  := SaveScreen()
  ::nAppCursor := SetCursor( SC_NONE )
  IF lRestore
    RestScreen( 0, 0, ::nMaxRow, ::nMaxCol, ::cImage )
  ENDIF
  IF ::nMaxRow != MaxRow() .OR. ::nMaxCol != MaxCol()
    ::nMaxRow := MaxRow()
    ::nMaxCol := MaxCol()
    nTop := 1
    nRight := ::nMaxCol
    ::oWndCommand:Resize( ::nMaxRow - 5, 0, ::nMaxRow - 1, ::nMaxCol )
    ::oGetListCommand:oGet:Row := ::oWndCommand:nBottom - 1
    ::oGetListCommand:oGet:Col := ::oWndCommand:nLeft + 3
    ::oBrwStack:nRight := ::nMaxCol - 1
    ::oBrwStack:nBottom := ::nMaxRow - 7
    ::oBrwStack:nLeft := ::nMaxCol - 14
    ::oBrwStack:nTop := 2
    IF ::oWndStack != NIL
      nRight -= 16
      ::oWndStack:Resize( , nRight + 1, ::nMaxRow - 6, ::nMaxCol )
    ENDIF
    IF ::oWndVars != NIL
      ::oWndVars:Resize( , , , nRight )
      nTop := Max( nTop, ::oWndVars:nBottom + 1 )
    ENDIF
    IF ::oWndPnt != NIL
      ::oWndPnt:Resize( , , , nRight )
      nTop := Max( nTop, ::oWndPnt:nBottom + 1 )
    ENDIF
    ::oWndCode:Resize( nTop, 0, ::nMaxRow - 6, nRight )
    ::oPullDown:Refresh()
    ::BarDisplay()
  ENDIF
  DispEnd()
return nil


METHOD SaveAppState() CLASS TDebugger
  ::nAppDirCase := Set( _SET_DIRCASE, 0 )
  ::nAppFileCase := Set( _SET_FILECASE, 0 )
  ::nAppTypeAhead := Set( _SET_TYPEAHEAD, 16 )
  ::nAppLastKey := LastKey()
  ::bAppInkeyAfter := SetInkeyAfterBlock( NIL )
  ::bAppInkeyBefore := SetInkeyBeforeBlock( NIL )
  ::bAppClassScope := __SetClassScope( .F. )
  ::oAppGetList := __GetListActive()
RETURN NIL


METHOD SaveSettings() CLASS TDebugger

   local cInfo := "", n, oWnd

   ::cSettingsFileName := ::InputBox( "File name", ::cSettingsFileName )

   if LastKey() != K_ESC

      if ! Empty( ::cPathForFiles )
         cInfo += "Options Path " + ::cPathForFiles + HB_OsNewLine()
      endif

      cInfo += "Options Colors {"
      for n := 1 to Len( ::aColors )
         cInfo += '"' + ::aColors[ n ] + '"'
         if n < Len( ::aColors )
            cInfo += ","
         endif
      next
      cInfo += "}" + HB_OsNewLine()

      if ::lMonoDisplay
         cInfo += "Options mono " + HB_OsNewLine()
      endif

      if !::lRunAtStartup
         cInfo += "Options NoRunAtStartup " + HB_OsNewLine()
      endif

      if ::nSpeed != 0
         cInfo += "Run Speed " + AllTrim( Str( ::nSpeed ) ) + HB_OsNewLine()
      endif

      if ::nTabWidth != 4
         cInfo += "Options Tab " + AllTrim( Str( ::nTabWidth ) ) + HB_OsNewLine()
      endif

      if ::lShowStatics
         cInfo += "Monitor Static" + HB_OsNewLine()
      endif

      if ::lShowPublics
         cInfo += "Monitor Public" + HB_OsNewLine()
      endif

      if ::lShowLocals
         cInfo += "Monitor Local" + HB_OsNewLine()
      endif

      if ::lShowPrivates
         cInfo += "Monitor Private" + HB_OsNewLine()
      endif

      if ::lSortVars
         cInfo += "Monitor Sort" + HB_OsNewLine()
      endif

      if ::lShowCallStack
         cInfo += "View CallStack" + HB_OsNewLine()
      endif

      if ! ::lLineNumbers
         cInfo += "Num Off" + HB_OsNewLine()
      endif

      if ! Empty( ::aBreakPoints )
         for n := 1 to Len( ::aBreakPoints )
            cInfo += "BP " + AllTrim( Str( ::aBreakPoints[ n ][ 1 ] ) ) + " " + ;
                     AllTrim( ::aBreakPoints[ n ][ 2 ] ) + HB_OsNewLine()
         next
      endif

      /* This part of the script must be executed after all windows are created */
      for n := 1 to Len( ::aWindows )
         oWnd := ::aWindows[ n ]
         cInfo += "Window Size " + AllTrim( Str( oWnd:nBottom - oWnd:nTop + 1 ) ) + " "
         cInfo += AllTrim( Str( oWnd:nRight - oWnd:nLeft + 1 ) ) + HB_OsNewLine()
         cInfo += "Window Move " + AllTrim( Str( oWnd:nTop ) ) + " "
         cInfo += AllTrim( Str( oWnd:nLeft ) ) + HB_OsNewLine()
         cInfo += "Window Next" + HB_OsNewLine()
      next

      MemoWrit( ::cSettingsFileName, cInfo )
   endif

return nil


METHOD SearchLine() CLASS TDebugger

   local cLine

   cLine := ::InputBox( "Line number", "1" )

   if Val( cLine ) > 0
      ::GotoLine ( Val( cLine ) )
   endif

return nil


METHOD Show() CLASS TDebugger

   ::SaveAppScreen( .F. )

   ::oPullDown:Display()
   ::oWndCode:Show( .t. )
   ::oWndCommand:Show()
   DispOutAt( ::oWndCommand:nBottom - 1, ::oWndCommand:nLeft + 1, ">" )

   ::BarDisplay()

return nil


METHOD ShowAppScreen() CLASS TDebugger

   ::cImage := SaveScreen()
   RestScreen( 0, 0, ::nMaxRow, ::nMaxCol, ::cAppImage )

   if LastKey() == K_LBUTTONDOWN
      InKey( 0, INKEY_ALL )
      InKey( 0, INKEY_ALL )
   else
      InKey( 0, INKEY_ALL )
   endif

   while LastKey() == K_MOUSEMOVE
      InKey( 0, INKEY_ALL )
   end
   RestScreen( 0, 0, ::nMaxRow, ::nMaxCol, ::cImage )

return nil


METHOD ShowCallStack() CLASS TDebugger

   local n := 1
   local oCol

   ::lShowCallStack = .t.

   if ::oWndStack == nil

      SetCursor( SC_NONE )

      DispBegin()
      // Resize code window
      ::oWndCode:Resize(,,, ::oWndCode:nRight - 16 )
      // Resize vars window
      if ::oWndVars != nil
         ::oWndVars:Resize(,,, ::oWndVars:nRight - 16 )
      endif
      // Resize watchpoints window
      if ::oWndPnt != nil
         ::oWndPnt:Resize(,,, ::oWndPnt:nRight - 16)
      endif
      DispEnd()

      if ::aWindows[ ::nCurrentWindow ]:lFocused
         ::aWindows[ ::nCurrentWindow ]:SetFocus( .f. )
      endif

      ::oWndStack := TDbWindow():New( 1, ::nMaxCol - 15, ::nMaxRow - 6, ::nMaxCol,;
                                     "Calls" )
      ::oWndStack:bKeyPressed  := { | nKey | ::CallStackProcessKey( nKey ) }
      ::oWndStack:bLButtonDown := { | nKey | ::CallStackProcessKey( K_LBUTTONDOWN ) }

      AAdd( ::aWindows, ::oWndStack )
      //::nCurrentWindow = Len( ::aWindows )

      if ::oBrwStack == nil
         ::BuildBrowseStack()
      endif

      ::oWndStack:bPainted := { || ::oBrwStack:ColorSpec := __DbgColors()[ 2 ] + "," + ;
                                  __DbgColors()[ 5 ] + "," + __DbgColors()[ 4 ],;
                                  ::oBrwStack:RefreshAll(), ::oBrwStack:ForceStable() }
      ::oWndStack:bGotFocus = { || SetCursor( SC_NONE ) }

      ::oWndStack:Show( .f. )
   endif

return nil


METHOD ShowCodeLine( nProc ) CLASS TDebugger
   LOCAL nPos, nLevel
   LOCAL nLine, cPrgName
   LOCAL xVal, oErr

   // we only update the stack window and up a new browse
   // to view the code if we have just broken execution
   if !::lGo
      if ::oWndStack != nil
         ::oBrwStack:RefreshAll()
      endif

      nLine := ::aProcStack[ nProc ][ CSTACK_LINE ]
      cPrgName := ::aProcStack[ nProc ][ CSTACK_MODULE ]
      IF ( nLine == NIL )
         ::oBrwText := nil
         ::oWndCode:Browser := nil
         ::oWndCode:SetCaption( ::aProcStack[ nProc ][ CSTACK_FUNCTION ] +;
                                ": Code not available" )
         ::oWndCode:Refresh()// to force the window caption to update
         RETURN nil
      ENDIF

      if( ::lppo )
         nPos :=RAT(".PRG", UPPER(cPrgName) )
         IF( nPos > 0 )
            cPrgName := LEFT( cPrgName, nPos-1 ) + ".ppo"
         ELSE
            cPrgName += cPrgName +".ppo"
         ENDIF
      endif

      if ! empty( cPrgName )

         if ( !FILENAME_EQUAL( strip_path( cPrgName ), strip_path( ::cPrgName ) ) ;
              .OR. ::oBrwText == NIL )

            if ! File( cPrgName ) .and. !Empty( ::cPathForFiles )
               cPrgName := ::LocatePrgPath( cPrgName )
            endif

            ::cPrgName := cPrgName

            IF !File( cPrgName )
               ::oBrwText := NIL
               ::oWndCode:Browser := NIL
               ::oWndCode:SetCaption( ::aProcStack[ nProc ][ CSTACK_MODULE ] + ;
                                     "  File not found" )
               ::oWndCode:Refresh()
               RETURN NIL
            ENDIF

            if ::oBrwText == nil
               ::oBrwText := TBrwText():New( ::oWndCode:nTop + 1, ::oWndCode:nLeft + 1,;
                                             ::oWndCode:nBottom - 1, ::oWndCode:nRight - 1, cPrgName,;
                                             __DbgColors()[ 2 ] + "," + __DbgColors()[ 5 ] + "," + ;
                                             __DbgColors()[ 3 ] + "," + __DbgColors()[ 6 ], ;
                                             ::lLineNumbers )

               ::oWndCode:Browser := ::oBrwText

            else
               ::oBrwText:LoadFile(cPrgName)
            endif

            ::oWndCode:bPainted := {|| IIF( ::oBrwText != nil, ::oBrwText:RefreshAll():ForceStable(), ::oWndCode:Clear() ) }
            ::RedisplayBreakpoints()               // check for breakpoints in this file and display them
            ::oWndCode:SetCaption( ::cPrgName )
            ::oWndCode:Refresh()       // to force the window caption to update
         endif
         ::oBrwText:SetActiveLine( nLine )
         ::GotoLine( nLine )
      endif

   endif

return nil


METHOD ShowHelp( nTopic ) CLASS TDebugger

   local nCursor := SetCursor( SC_NONE )

   __dbgHelp( nTopic )
   SetCursor( nCursor )

return nil


METHOD ShowVars() CLASS TDebugger

   local nWidth, n := 1
   Local oCol
   local lRepaint := .f.
   local nTop

   if ::lGo
      return nil
   endif

   if ! ( ::lShowLocals .or. ::lShowStatics .or. ::lShowPrivates .or. ;
          ::lShowPublics )
      return nil
   endif

   if ::oWndVars == nil

      nTop := IIF(::oWndPnt!=NIL .AND. ::oWndPnt:lVisible,::oWndPnt:nBottom+1,1)

      ::oWndVars := TDbWindow():New( nTop, 0, nTop+Min( 5, Len( ::aVars )+1 ),;
         ::nMaxCol - iif( ::oWndStack != nil, ::oWndStack:nWidth(), 0 ),;
         "Monitor:" + iif( ::lShowLocals, " Local", "" ) + ;
         iif( ::lShowStatics, " Static", "" ) + iif( ::lShowPrivates, " Private", "" ) + ;
         iif( ::lShowPublics, " Public", "" ) )

      ::oWndVars:bLButtonDown := { | nMRow, nMCol | ::WndVarsLButtonDown( nMRow, nMCol ) }
      ::oWndVars:bLDblClick   := { | nMRow, nMCol | ::EditVar( ::oBrwVars:Cargo[ 1 ] ) }

      ::oBrwVars := TDbgBrowser():New( nTop+1, 1, ::oWndVars:nBottom - 1, ::nMaxCol - iif( ::oWndStack != nil,;
                               ::oWndStack:nWidth(), 0 ) - 1 )

      ::oWndVars:Browser := ::oBrwVars

      ::oBrwVars:Cargo :={ 1,{}} // Actual highligthed row
      ::oBrwVars:ColorSpec := ::aColors[ 2 ] + "," + ::aColors[ 5 ] + "," + ::aColors[ 3 ]
      ::oBrwVars:GOTOPBLOCK := { || ::oBrwVars:cargo[ 1 ] := Min( 1, Len( ::aVars ) ) }
      ::oBrwVars:GoBottomBlock := { || ::oBrwVars:cargo[ 1 ] := Max( 1, Len( ::aVars ) ) }
      ::oBrwVars:SkipBlock = { | nSkip, nOld | nOld := ::oBrwVars:Cargo[ 1 ],;
                               ::oBrwVars:Cargo[ 1 ] += nSkip,;
                               ::oBrwVars:Cargo[ 1 ] := Min( Max( ::oBrwVars:Cargo[ 1 ], 1 ),;
                                                             Len( ::aVars ) ),;
                               If( Len( ::aVars ) > 0, ::oBrwVars:Cargo[ 1 ] - nOld, 0 ) }

      nWidth := ::oWndVars:nWidth() - 1
      oCol := TBColumnNew( "", ;
        { || PadR( If( Len( ::aVars ) > 0, ;
                       AllTrim( Str( ::oBrwVars:Cargo[1] -1 ) ) + ") " + ;
                         ::VarGetInfo( ::aVars[ Max( ::oBrwVars:Cargo[1], 1 ) ] ), ;
                       " " ), ;
                   ::oWndVars:nWidth() - 2 ) } )
      ::oBrwVars:AddColumn( oCol )
      AAdd( ::oBrwVars:Cargo[2], ::aVars )
      oCol:DefColor:={1,2}
      if Len( ::aVars ) > 0
         ::oBrwVars:ForceStable()
      endif

      ::oWndVars:bPainted     := { || if(Len( ::aVars ) > 0, ( ::obrwVars:RefreshAll():ForceStable(),RefreshVarsS(::oBrwVars) ),) }

      ::oWndVars:bKeyPressed := { | nKey | ( iif( nKey == K_DOWN ;
      , ::oBrwVars:Down(), nil ), iif( nKey == K_UP, ::oBrwVars:Up(), nil ) ;
      , iif( nKey == K_PGDN, ::oBrwVars:PageDown(), nil ) ;
      , iif( nKey == K_PGUP, ::oBrwVars:PageUp(), nil ) ;
      , iif( nKey == K_HOME, ::oBrwVars:GoTop(), nil ) ;
      , iif( nKey == K_END, ::oBrwVars:GoBottom(), nil ) ;
      , iif( nKey == K_ENTER, ::EditVar( ::oBrwVars:Cargo[1] ), nil ), IIF(LEN(::aVars)>0, ::oBrwVars:ForceStable(), nil) ) }

      AAdd( ::aWindows, ::oWndVars )
      ::oWndVars:Show()
      ::ResizeWindows( ::oWndVars )

   else

      ::oWndVars:cCaption := "Monitor:" + ;
      iif( ::lShowLocals, " Local", "" ) + ;
      iif( ::lShowStatics, " Static", "" ) + ;
      iif( ::lShowPrivates, " Private", "" ) + ;
      iif( ::lShowPublics, " Public", "" )

      DispBegin()
      if ::oBrwVars:cargo[1] <= 0
         ::oBrwVars:cargo[1] := 1
      endif

      if Len( ::aVars ) == 0
         if ::oWndVars:nBottom - ::oWndVars:nTop > 1
            ::oWndVars:Resize( ,, ::oWndVars:nTop + 1 )
            lRepaint := .t.
         else
            /* We still need to redraw window caption, it could have changed */
            ::oWndVars:Refresh()
         endif
      elseif Len( ::aVars ) > ::oWndVars:nBottom - ::oWndVars:nTop - 1
         ::oWndVars:Resize( ,, ::oWndVars:nTop + Min( Len( ::aVars ) + 1, 7 ) )
         lRepaint := .t.
      elseif Len( ::aVars ) < ::oWndVars:nBottom - ::oWndVars:nTop - 1
         ::oWndVars:Resize( ,, ::oWndVars:nTop + Len( ::aVars ) + 1 )
         lRepaint := .t.
      else
         ::oBrwVars:RefreshAll():ForceStable()
         ::oWndVars:Refresh()
      endif
      if ! ::oWndVars:lVisible .OR. lRepaint
         ::ResizeWindows( ::oWndVars )
      endif
      DispEnd()
   endif

return nil


METHOD Stack() CLASS TDebugger

   ::lShowCallStack := ! ::lShowCallStack
   ::oPulldown:GetItemByIdent( "CALLSTACK" ):checked := ::lShowCallStack
   if ::lActive
      if ::lShowCallStack
         ::ShowCallStack()
      else
         ::HideCallStack()
      endif
   endif

return nil


METHOD Static() CLASS TDebugger

   ::lShowStatics := ! ::lShowStatics
   ::RefreshVars()

return nil


METHOD Step() CLASS TDebugger
  // we are starting to run again so reset to the deepest call if
  // displaying stack
  if ! ::oBrwStack == nil
    ::oBrwStack:GoTop()
  endif
  ::RestoreAppScreen()
  ::RestoreAppState()
  ::Exit()
RETURN nil


METHOD ToCursor() CLASS TDebugger
  LOCAL cLine

  cLine := ::oBrwText:GetLine( ::oBrwText:nRow )
  IF ::oBrwText:lLineNumbers
    cLine := SUBSTR( cLine, AT(":",cLine)+1 )
  ENDIF
  IF IsValidStopLine( cLine )
    HB_INLINE( ::pInfo, strip_path( ::cPrgName ), ::oBrwText:nRow )
    {
      hb_dbgSetToCursor( hb_parptr( 1 ), hb_parc( 2 ), hb_parni( 3 ) );
    }
    ::RestoreAppScreen()
    ::RestoreAppState()
    ::Exit()
  ENDIF
RETURN self


// Toggle a breakpoint at the cursor position in the currently viewed file
// which may be different from the file in which execution was broken
METHOD ToggleBreakPoint( nLine, cFileName ) CLASS TDebugger
  // look for a breakpoint which matches both line number and program name
  local nAt
  LOCAL cLine

  IF !::lActive
    RETURN NIL
  ENDIF

  IF nLine == NIL
    cLine := ::oBrwText:GetLine( ::oBrwText:nRow )
    IF ::oBrwText:lLineNumbers
      cLine := SUBSTR( cLine, AT(":",cLine)+1 )
    ENDIF
    IF IsValidStopLine( cLine )
      cFileName := strip_path( ::cPrgName )
      nLine := ::oBrwText:nRow
    ELSE
      RETURN NIL
    ENDIF
  ENDIF

  nAt := AScan( ::aBreakPoints, { | aBreak | aBreak[ 1 ] == nLine ;
                                    .AND. FILENAME_EQUAL( aBreak[ 2 ], cFileName ) } )

  if nAt == 0
    AAdd( ::aBreakPoints, { nLine, cFileName } )     // it was nLine
    HB_INLINE( ::pInfo, cFileName, nLine )
    {
       hb_dbgAddBreak( hb_parptr( 1 ), hb_parc( 2 ), hb_parni( 3 ), NULL );
    }
    IF FILENAME_EQUAL( cFileName, strip_path( ::cPrgName ) )
      ::oBrwText:ToggleBreakPoint( nLine, .T. )
    ENDIF
  else
    ADel( ::aBreakPoints, nAt )
    ASize( ::aBreakPoints, Len( ::aBreakPoints ) - 1 )
    HB_INLINE( ::pInfo, nAt - 1 )
    {
       hb_dbgDelBreak( hb_parptr( 1 ), hb_parni( 2 ) );
    }
    IF FILENAME_EQUAL( cFileName, strip_path( ::cPrgName ) )
      ::oBrwText:ToggleBreakPoint( nLine, .F. )
    ENDIF
  endif

  ::oBrwText:RefreshCurrent()

return nil


METHOD Trace() CLASS TDebugger
  HB_INLINE( ::pInfo )
  {
    hb_dbgSetTrace( hb_parptr( 1 ) );
  }
  ::Step() //forces a Step()
RETURN Self


METHOD TracepointAdd( cExpr ) CLASS TDebugger
   LOCAL cErr
   LOCAL aWatch
   LOCAL lSuccess
   LOCAL uValue

   IF( cExpr == NIL )
      cExpr:=SPACE(255)
      cExpr := ALLTRIM( ::InputBox( "Enter Tracepoint", cExpr ) )
      IF( LASTKEY() == K_ESC )
         RETURN self
      ENDIF
   ENDIF
   cExpr := ALLTRIM( cExpr )
   IF( EMPTY(cExpr) )
      RETURN self
   ENDIF
   aWatch := {"tp", cExpr, NIL}
   ::RestoreAppState()
   HB_INLINE( ::pInfo, cExpr )
   {
     hb_dbgAddWatch( hb_parptr( 1 ), hb_parc( 2 ), TRUE );
   }
   ::SaveAppState()
   AADD( ::aWatch, aWatch )
   ::WatchpointsShow()

RETURN self


METHOD VarGetInfo( aVar ) CLASS TDebugger
  LOCAL uValue
  LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )

  uValue := ::VarGetValue( aVar )
  do case
    case cType == "L"
      return aVar[ VAR_NAME ] + " <Local, " + ;
       ValType( uValue ) + ;
       ">: " + ValToStr( uValue )

    case cType == "S"
      return aVar[ VAR_NAME ] + " <Static, " + ;
       ValType( uValue ) + ;
       ">: " + ValToStr( uValue )

    OTHERWISE
      return aVar[ VAR_NAME ] + " <" + aVar[ VAR_TYPE ] + ", " + ;
       ValType( uValue ) + ;
       ">: " + ValToStr( uValue )
  endcase
return ""


METHOD VarGetValue( aVar ) CLASS TDebugger
  LOCAL nProcLevel, uValue
  LOCAL cProc
  LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )

  IF( cType == "L" )
    nProcLevel := hb_dbg_procLevel() - aVar[ VAR_LEVEL ]
    uValue := hb_dbg_vmVarLGet( nProcLevel, aVar[ VAR_POS ] )

  ELSEIF( cType == "S" )
    uValue := hb_dbg_vmVarSGet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ] )

  ELSE
    //Public or Private
    uValue := aVar[ VAR_POS ]
  ENDIF

RETURN uValue


METHOD VarSetValue( aVar, uValue ) CLASS TDebugger
  LOCAL nProcLevel
  LOCAL cProc
  LOCAL cType := Left( aVar[ VAR_TYPE ], 1 )

  IF( cType == "L" )
    nProcLevel := hb_dbg_procLevel() - aVar[VAR_LEVEL]   //skip debugger stack
    hb_dbg_vmVarLSet( nProcLevel, aVar[ VAR_POS ], uValue )

  ELSEIF( cType == "S" )
    hb_dbg_vmVarSSet( aVar[ VAR_LEVEL ], aVar[ VAR_POS ], uValue )

  ELSE
    //Public or Private
    aVar[ VAR_POS ] := uValue
    &( aVar[ VAR_NAME ] ) := uValue

  ENDIF

RETURN self


METHOD ViewSets() CLASS TDebugger

   local oWndSets := TDbWindow():New( 1, 8, ::nMaxRow - 2, ::nMaxCol - 8,;
                                      "System Settings[1..47]", ::ClrModal() )
   local aSets := { "Exact", "Fixed", "Decimals", "DateFormat", "Epoch", "Path",;
                    "Default", "Exclusive", "SoftSeek", "Unique", "Deleted",;
                    "Cancel", "Debug", "TypeAhead", "Color", "Cursor", "Console",;
                    "Alternate", "AltFile", "Device", "Extra", "ExtraFile",;
                    "Printer", "PrintFile", "Margin", "Bell", "Confirm", "Escape",;
                    "Insert", "Exit", "Intensity", "ScoreBoard", "Delimeters",;
                    "DelimChars", "Wrap", "Message", "MCenter", "ScrollBreak",;
                    "EventMask", "VideoMode", "MBlockSize", "MFileExt",;
                    "StrictRead", "Optimize", "Autopen", "Autorder", "AutoShare" }

   local oBrwSets := TBrowseNew( oWndSets:nTop + 1, oWndSets:nLeft + 1,;
                                 oWndSets:nBottom - 1, oWndSets:nRight - 1 )
   local n := 1
   local nWidth := oWndSets:nRight - oWndSets:nLeft - 1
   local oCol
   oBrwSets:Cargo :={ 1,{}} // Actual highlighted row
   oBrwSets:autolite:=.f.
   oBrwSets:ColorSpec := ::ClrModal()
   oBrwSets:GOTOPBLOCK := { || oBrwSets:cargo[ 1 ]:= 1 }
   oBrwSets:GoBottomBlock := { || oBrwSets:cargo[ 1 ]:= Len(oBrwSets:cargo[ 2 ][ 1 ])}
   oBrwSets:SKIPBLOCK := { |nPos| ( nPos:= ArrayBrowseSkip(nPos, oBrwSets), oBrwSets:cargo[ 1 ]:= ;
   oBrwSets:cargo[ 1 ] + nPos,nPos ) }
   oBrwSets:AddColumn( ocol := TBColumnNew( "", { || PadR( aSets[ oBrwSets:cargo[ 1 ] ], 12 ) } ) )
   aadd(oBrwSets:Cargo[2],asets)
   ocol:defcolor:={1,2}
   oBrwSets:AddColumn( oCol := TBColumnNew( "",;
                       { || PadR( ValToStr( Set( oBrwSets:cargo[ 1 ]  ) ), nWidth - 13 ) } ) )
   ocol:defcolor:={1,3}
   ocol:width:=40
   oWndSets:bPainted    := { || oBrwSets:ForceStable(),RefreshVarsS(oBrwSets)}
   oWndSets:bKeyPressed := { | nKey | SetsKeyPressed( nKey, oBrwSets, Len( aSets ),;
                            oWndSets, "System Settings",;
                            { || ::EditSet( oBrwSets:Cargo[1], oBrwSets ) } ) }

   SetCursor( SC_NONE )
   oWndSets:ShowModal()

return nil


METHOD WatchGetInfo( nWatch ) CLASS TDebugger
   LOCAL xVal
   LOCAL ctype
   LOCAL lValid
   LOCAL aWatch := ::aWatch[ nWatch ]

   ::RestoreAppState()
   xVal := ::GetExprValue( nWatch, @lValid )
   ::SaveAppState()
   IF( lValid )
      cType := VALTYPE( xVal )
      xVal  := ValToStr( xVal )
   ELSE
      //xVal contains error description
      cType := 'U'
      //xVal  := "Undefined"
   ENDIF

RETURN aWatch[WP_EXPR]+" <"+aWatch[WP_TYPE]+", " +cType+">: " +xVal


METHOD WatchpointAdd( cExpr ) CLASS TDebugger
   LOCAL cErr
   LOCAL aWatch

   IF( cExpr == NIL )
      cExpr:=SPACE(255)
      cExpr := ALLTRIM( ::InputBox( "Enter Watchpoint", cExpr ) )
      IF( LASTKEY() == K_ESC )
         RETURN self
      ENDIF
   ENDIF
   cExpr := ALLTRIM( cExpr )
   IF( EMPTY(cExpr) )
      RETURN self
   ENDIF
   aWatch := { "wp", cExpr }
   HB_INLINE( ::pInfo, cExpr )
   {
      hb_dbgAddWatch( hb_parptr( 1 ), hb_parc( 2 ), FALSE );
   }
   AADD( ::aWatch, aWatch )
   ::WatchpointsShow()

RETURN self


METHOD WatchpointDel( nPos ) CLASS TDebugger
   LOCAL nIdx

   IF( ::oWndPnt != NIL .AND. ::oWndPnt:lVisible )
      IF( nPos == NIL )
         //called from the menu
         nPos := ::InputBox( "Enter item number to delete", ::oBrwPnt:cargo[1]-1 )
      ELSE
         nPos--
      ENDIF
      IF( LastKey() != K_ESC )
         IF( nPos >=0 .AND. nPos < LEN(::aWatch) )
            ::oBrwPnt:gotop()
            HB_INLINE( ::pInfo, nPos )
            {
               hb_dbgDelWatch( hb_parptr( 1 ), hb_parni( 2 ) );
            }
            ADEL( ::aWatch, nPos+1 )
            ASIZE( ::aWatch, LEN(::aWatch)-1 )
            IF( LEN(::aWatch) == 0 )
               ::WatchpointsHide()
            ELSE
               ::WatchpointsShow()
            ENDIF
         ENDIF
      ENDIF
   ENDIF

RETURN self


METHOD WatchpointEdit( nPos ) CLASS TDebugger
   LOCAL cExpr
   LOCAL aWatch
   LOCAL cErr

   cExpr:=PADR( ::aWatch[nPos][WP_EXPR], 255 )
   cExpr := ALLTRIM( ::InputBox( "Enter Watchpoint", cExpr ) )
   IF( LASTKEY() == K_ESC )
      RETURN self
   ENDIF
   cExpr := ALLTRIM( cExpr )
   IF( EMPTY(cExpr) )
      RETURN self
   ENDIF
   aWatch := { "wp", cExpr }
   HB_INLINE( ::pInfo, nPos - 1, cExpr )
   {
      hb_dbgSetWatch( hb_parptr( 1 ), hb_parni( 2 ), hb_parc( 3 ), FALSE );
   }
   ::aWatch[ nPos ] := aWatch
   ::WatchpointsShow()

RETURN self


METHOD WatchpointInspect( nPos ) CLASS TDebugger
  LOCAL xValue, lValid

  ::RestoreAppState()
  xValue := ::GetExprValue( ::aWatch[ nPos ][ WP_EXPR ], @lValid )
  ::SaveAppState()
  
  ::InputBox( ::aWatch[ nPos ][ WP_EXPR ], xValue, , .F. )
RETURN Self


METHOD WatchpointsHide() CLASS TDebugger

   ::oWndPnt:Hide()
   ::oWndCode:nTop := IIF(::oWndVars!=NIL .AND. ::oWndVars:lVisible, ::oWndVars:nBottom+1,1)
   ::oBrwText:Resize( ::oWndCode:nTop+1 )
   if ::aWindows[ ::nCurrentWindow ] == ::oWndPnt
      ::NextWindow()
   ENDIF

return nil


METHOD WatchpointsShow() CLASS TDebugger

   local nWidth, n := 1
   Local oCol
   local lRepaint := .f.
   local nTop
   LOCAL lFocused

   if ::lGo
      return nil
   endif

   if LEN(::aWatch) == 0
      return nil
   endif

   if ::oWndPnt == nil
      nTop := IIF(::oWndVars!=NIL .AND. ::oWndVars:lVisible,::oWndVars:nBottom,0) + 1
      ::oWndPnt := TDbWindow():New( nTop,;
         0, ;
         nTop +Min( 4, Len( ::aWatch ) ) + 1,;
         ::nMaxCol - iif( ::oWndStack != nil, ::oWndStack:nWidth(), 0 ),;
         "Watch" )

      //::oBrwText:Resize( ::oWndPnt:nBottom + 1 )
      //::oWndCode:nTop := ::oWndPnt:nBottom + 1
      //::oBrwText:Resize( ::oWndCode:nTop + 1 )
      //::oBrwText:RefreshAll()
      //::oWndCode:SetFocus( .t. )

//      ::oWndPnt:bLButtonDown := { | nMRow, nMCol | ::WndVarsLButtonDown( nMRow, nMCol ) }
//      ::oWndPnt:bLDblClick   := { | nMRow, nMCol | ::EditVar( ::oBrwPnt:Cargo[ 1 ] ) }

      ::oBrwPnt := TDbgBrowser():New( nTop+1, 1, ::oWndPnt:nBottom - 1, ::nMaxCol - iif( ::oWndStack != nil,;
                               ::oWndStack:nWidth(), 0 ) - 1 )

      ::oWndPnt:Browser := ::oBrwPnt

      ::oBrwPnt:Cargo :={ 1,{}} // Actual highligthed row
      ::oBrwPnt:ColorSpec := ::aColors[ 2 ] + "," + ::aColors[ 5 ] + "," + ::aColors[ 3 ]
      ::oBrwPnt:GOTOPBLOCK := { || ::oBrwPnt:cargo[ 1 ] := Min( 1, Len(::aWatch) ) }
      ::oBrwPnt:GoBottomBlock := { || ::oBrwPnt:cargo[ 1 ] := Len( ::aWatch ) }
      ::oBrwPnt:SkipBlock = { | nSkip, nOld | nOld := ::oBrwPnt:Cargo[ 1 ],;
                               ::oBrwPnt:Cargo[ 1 ] += nSkip,;
                               ::oBrwPnt:Cargo[ 1 ] := Min( Max( ::oBrwPnt:Cargo[ 1 ], 1 ),;
                                                             Len( ::aWatch ) ),;
                               IIF( LEN(::aWatch) > 0, ::oBrwPnt:Cargo[ 1 ] - nOld, 0 ) }

      nWidth := ::oWndPnt:nWidth() - 1
      oCol := TBColumnNew( "", ;
         { || PadR( IIF( LEN( ::aWatch ) > 0, ;
                       AllTrim( Str( ::oBrwPnt:Cargo[1] -1 ) ) + ") " + ;
                       ::WatchGetInfo( Max( ::oBrwPnt:Cargo[1], 1 ) ), ;
                       " " ), ;
                   ::oWndPnt:nWidth() - 2 ) } )
      ::oBrwPnt:AddColumn( oCol )
      AAdd(::oBrwPnt:Cargo[2], ::aWatch)
      oCol:DefColor:={1,2}

      ::oWndPnt:bPainted := { || if(Len(::aWatch) > 0, ( ::oBrwPnt:RefreshAll():ForceStable(),RefreshVarsS(::oBrwPnt) ),) }

      ::oWndPnt:bKeyPressed := { | nKey | ;
      ( iif( nKey == K_DOWN, ::oBrwPnt:Down(), nil ) ;
      , iif( nKey == K_UP, ::oBrwPnt:Up(), nil ) ;
      , iif( nKey == K_PGDN, ::oBrwPnt:PageDown(), nil ) ;
      , iif( nKey == K_PGUP, ::oBrwPnt:PageUp(), nil ) ;
      , iif( nKey == K_HOME, ::oBrwPnt:GoTop(), nil ) ;
      , iif( nKey == K_END, ::oBrwPnt:GoBottom(), nil ) ;
      , iif( nKey == K_DEL, ::WatchpointDel( ::oBrwPnt:Cargo[1] ), nil ) ;
      , iif( nKey == K_ENTER, ::WatchpointEdit( ::oBrwPnt:Cargo[1] ), nil ) ;
      , iif( nKey == K_CTRL_ENTER, ::WatchpointInspect( ::oBrwPnt:Cargo[ 1 ] ), nil ) ;
      , ::oBrwPnt:ForceStable() ) }

      AAdd( ::aWindows, ::oWndPnt )
      ::oWndPnt:Show()
      ::ResizeWindows( ::oWndPnt )
   else
      if( ::oBrwPnt:cargo[1] <= 0 )
         ::oBrwPnt:cargo[1] := 1
      endif
      DispBegin()
      if Len( ::aWatch ) > ::oWndPnt:nBottom - ::oWndPnt:nTop - 1
         //Resize( top, left, bottom, right )
         ::oWndPnt:Resize( ,, ::oWndPnt:nTop + Min( Len( ::aWatch ) + 1, 4 ) )
         lRepaint := .t.
      elseif Len( ::aWatch ) < ::oWndPnt:nBottom - ::oWndPnt:nTop - 1
         ::oWndPnt:Resize( ,, ::oWndPnt:nTop + Len( ::aWatch ) + 1 )
         lRepaint := .t.
      else
         ::oBrwPnt:RefreshAll():ForceStable()
      endif
      if ! ::oWndPnt:lVisible .OR. lRepaint
         ::ResizeWindows( ::oWndPnt )
      endif
   endif
   DispEnd()
return nil


METHOD WndVarsLButtonDown( nMRow, nMCol ) CLASS TDebugger

   if nMRow > ::oWndVars:nTop .and. ;
      nMRow < ::oWndVars:nBottom .and. ;
      nMCol > ::oWndVars:nLeft .and. ;
      nMCol < ::oWndVars:nRight
      if nMRow - ::oWndVars:nTop >= 1 .and. ;
         nMRow - ::oWndVars:nTop <= Len( ::aVars )
         while ::oBrwVars:RowPos > nMRow - ::oWndVars:nTop
            ::oBrwVars:Up()
            ::oBrwVars:ForceStable()
         end
         while ::oBrwVars:RowPos < nMRow - ::oWndVars:nTop
            ::oBrwVars:Down()
            ::oBrwVars:ForceStable()
         end
      endif
   endif

return nil


static procedure SetsKeyPressed( nKey, oBrwSets, nSets, oWnd, cCaption, bEdit )

   local nSet := oBrwSets:cargo[1]
   local cTemp:=str(nSet,4)

   Local nRectoMove
   do case
      case nKey == K_UP
              oBrwSets:Up()
      case nKey == K_DOWN
              oBrwSets:Down()
      case nKey == K_HOME .or. (nKey == K_CTRL_PGUP) .or. (nKey == K_CTRL_HOME)
              oBrwSets:GoTop()
      case nKey == K_END .or. (nkey == K_CTRL_PGDN) .or. (nkey == K_CTRL_END )
              oBrwSets:GoBottom()
      Case nKey == K_PGDN
              oBrwSets:pageDown()
      Case nKey == K_PGUP
              OBrwSets:PageUp()

      case nKey == K_ENTER
           if bEdit != nil
              Eval( bEdit )
           endif
           if LastKey() == K_ENTER
              KEYBOARD Chr( K_DOWN )
           endif

   endcase
      RefreshVarsS(oBrwSets)

      oWnd:SetCaption( cCaption + "[" + AllTrim( Str( oBrwSets:Cargo[1] ) ) + ;
                       ".." + AllTrim( Str( nSets ) ) + "]" )

return

static procedure SetsKeyVarPressed( nKey, oBrwSets, nSets, oWnd, bEdit )
   Local nRectoMove
   local nSet := oBrwSets:Cargo[1]
   do case
      case nKey == K_UP
              oBrwSets:Up()

      case nKey == K_DOWN
              oBrwSets:Down()

      case nKey == K_HOME .or. (nKey == K_CTRL_PGUP) .or. (nKey == K_CTRL_HOME)
              oBrwSets:GoTop()
      case nKey == K_END .or. (nkey == K_CTRL_PGDN) .or. (nkey == K_CTRL_END )
              oBrwSets:GoBottom()

      Case nKey == K_PGDN
              oBrwSets:pageDown()
      Case nKey == K_PGUP
              OBrwSets:PageUp()

      case nKey == K_ENTER
           if bEdit != nil
              Eval( bEdit )
           endif
           if LastKey() == K_ENTER
              KEYBOARD Chr( K_DOWN )
           endif

   endcase

return

static function ValToStr( uVal )

   local cType := ValType( uVal )
   local cResult := "U"

   do case
      case uVal == nil
           cResult := "NIL"

      case cType == "A"
           cResult := "{ ... }"

      Case cType  =="B"
         cResult:= "{ || ... }"

      case cType $ "CM"
           cResult := '"' + uVal + '"'

      case cType == "L"
           cResult := iif( uVal, ".T.", ".F." )

      case cType == "D"
           cResult := DToC( uVal )

      case cType == "N"
           cResult := AllTrim( Str( uVal ) )

      case cType == "O"
           cResult := "Class " + uVal:ClassName() + " object"
   endcase

return cResult


STATIC PROCEDURE StripUntil( pcLine, i, cChar )
  LOCAL j, n
  LOCAL nLen:=LEN(pcLine)

  n := LEN(cChar)
  j := i+n
  DO WHILE j<=nLen .AND. SUBSTR(pcLine, j, n) != cChar
    j++
  ENDDO
  IF j <= nLen
    pcLine := LEFT( pcLine, i-1 ) + SUBSTR(pcLine, j+n)
  ENDIF

RETURN


STATIC FUNCTION IsValidStopLine( cLine )
  LOCAL i, c, c2

  cLine := UPPER( ALLTRIM( cLine ) )
  i := 1
  DO WHILE i <= LEN(cLine)
    c := SUBSTR( cLine, i, 1 )
    c2 := SUBSTR( cLine, i, 2 )
    DO CASE
      CASE c == '"'
        StripUntil( @cLine, i, c )

      CASE c == "'"
        StripUntil( @cLine, i, c )

      CASE c == "["
        StripUntil( @cLine, i, "]" )

      CASE c2 == "//"
        cLine := LEFT( cLine, i-1 )

      CASE c2 == "/*"
        StripUntil( @cLine, i, "*/" )

      OTHERWISE
        i++
    ENDCASE
  ENDDO

  cLine := ALLTRIM( cLine )
  IF EMPTY(cLine)
    RETURN .F.
  ENDIF

  c := Left( cLine, 4 )
  IF ( Left( c, 3 ) == 'END' .OR.;
       c == 'FUNC' .OR.;
       c == 'PROC' .OR.;
       c == 'NEXT' .OR.;
       c == 'ELSE' .OR.;
       c == 'LOCA' .OR.;
       c == 'STAT' .OR.;
       c == 'MEMV' )

    RETURN .F.
  ENDIF

RETURN .T.


function __DbgColors()

return iif( ! s_oDebugger:lMonoDisplay, s_oDebugger:aColors,;
           { "W+/N", "W+/N", "N/W", "N/W", "N/W", "N/W", "W+/N",;
             "N/W", "W+/W", "W/N", "W+/N" } )


function __Dbg()

return s_oDebugger


static function myColors( oBrowse, aColColors )
   local i
   local nColPos := oBrowse:colpos

   for i := 1 to len( aColColors )
      oBrowse:colpos := aColColors[i]
      oBrowse:hilite()
   next

   oBrowse:colpos := nColPos

return nil


static procedure RefreshVarsS( oBrowse )

   local nLen := oBrowse:ColCount

   if ( nLen == 2 )
      oBrowse:dehilite():colpos:=2
   endif
   oBrowse:dehilite():forcestable()
   if ( nLen == 2 )
      oBrowse:hilite():colpos:=1
   endif
   oBrowse:hilite()

return


static function ArrayBrowseSkip( nPos, oBrwSets, n )

return iif( oBrwSets:cargo[ 1 ] + nPos < 1, 0 - oBrwSets:cargo[ 1 ] + 1 , ;
       iif( oBrwSets:cargo[ 1 ] + nPos > Len(oBrwSets:cargo[ 2 ][ 1 ]), ;
       Len(oBrwSets:cargo[ 2 ][ 1 ]) - oBrwSets:cargo[ 1 ], nPos ) )


static function PathToArray( cList )
   local nPos
   local aList := {}
   local cSep, cDirSep, cDir

   cSep := HB_OsPathListSeparator()
   cDirSep := HB_OsPathDelimiters()

   if ( cList <> NIL )

      do while ( nPos := at( cSep, cList ) ) <> 0
         aadd( aList, substr( cList, 1, nPos - 1 ) )        // Add a new element
         cList := substr( cList, nPos + 1 )
      enddo

      aadd( aList, cList )              // Add final element

      /* Strip ending delimiters */
      AEval(aList, {|x, i| if( x[-1] $ cDirSep,  aList[ i ] := Left( x, Len( x ) - 1 ), ) } )
   endif

return aList


/* Check if a string starts with another string */
STATIC FUNCTION starts( cLine, cStart )
RETURN ( cStart == Left( cLine, Len( cStart ) ) )


/* Strip path from filename */
STATIC FUNCTION strip_path( cFileName )
  LOCAL cName := "", cExt := ""
  DEFAULT cFileName TO ""

  HB_FNAMESPLIT( cFileName, NIL, @cName, @cExt )
RETURN cName + cExt


#ifdef HB_NO_READDBG
STATIC FUNCTION getdbginput( nTop, nLeft, uValue, bValid, cColor )

  LOCAL nOldCursor
  LOCAL uTemp

  nOldCursor := SetCursor( SC_NORMAL )

  if cColor != nil
     setcolor( cColor )
  endif

  uTemp := uValue

  do while .t.
     @ nTop, nLeft say space( len( uTemp ) )
     @ nTop, nLeft say ""
     accept to uTemp
     if bValid != nil .and. !eval( bValid, uTemp )
        uTemp := uValue
     else
        exit
     endif
  enddo

  setCursor( nOldCursor )

RETURN uTemp
#endif

