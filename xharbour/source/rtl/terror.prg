/*
 * $Id: terror.prg,v 1.18 2006/01/31 21:47:56 ronpinkas Exp $
 */

/*
 * Harbour Project source code:
 * Error Class
 *
 * Copyright 1999 Antonio Linares <alinares@fivetech.com>
 * www - http://www.harbour-project.org
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

/* Error Class. We are keeping Clipper compatibility here, instead of using
   TError():New() style and also avoiding hungarian notation. */

#include "error.ch"

#ifndef HB_THREAD_SUPPORT
   static s_aErrHandlers := {}
#endif

FUNCTION ErrorNew( SubSystem, GenCode, SubCode, Operation, Description, Args, ModuleName, ProcName, ProcLine )

   STATIC lInErr := .F., s_oClass
   LOCAL oErr
   LOCAL nLevel, aaStack

   //TraceLog( SubSystem, GenCode, SubCode, Operation, Description, Args, ModuleName, ProcName, ProcLine )

   // Avoid RECURSIVE Errors.
   IF lInErr
      RETURN NIL
   ELSE
      lInErr := .T.
   ENDIF

   IF s_oClass == NIL
      s_oClass := HBClass():New( "ERROR" )

      s_oClass:AddData( "Args"         ,  )
      s_oClass:AddData( "CanDefault"   , .F. )
      s_oClass:AddData( "CanRetry"     , .F. )
      s_oClass:AddData( "CanSubstitute", .F. )
      s_oClass:AddData( "Cargo" )
      s_oClass:AddData( "Description"  , "" )
      s_oClass:AddData( "FileName"     , "" )
      s_oClass:AddData( "GenCode"      , 0 )
      s_oClass:AddData( "Operation"    , "" )
      s_oClass:AddData( "OsCode"       , 0 )
      s_oClass:AddData( "Severity"     , ES_ERROR )
      s_oClass:AddData( "SubCode"      , 0 )
      s_oClass:AddData( "SubSystem"    , "" )
      s_oClass:AddData( "Tries"        , 0 )

      s_oClass:AddData( "ProcName"     ,  )
      s_oClass:AddData( "ProcLine"     ,  )

      #ifdef HB_THREAD_SUPPORT
         s_oClass:AddData( "RunningThreads" ,  )
         s_oClass:AddData( "OsThreadId"     ,  )
         s_oClass:AddData( "VMThreadId"     ,  )
      #endif

      s_oClass:AddData( "ModuleName"   , "" )

      s_oClass:AddData( "aaStack"      , {} )

      s_oClass:AddInline( "New", {|Self| Self } )

      s_oClass:Create()
   ENDIF

   oErr := s_oClass:Instance()

   IF SubSystem != NIL
      oErr:SubSystem := SubSystem
   ENDIF
   IF GenCode != NIL
      oErr:GenCode := GenCode
   ENDIF
   IF SubCode != NIL
      oErr:SubCode := SubCode
   ENDIF
   IF Operation != NIL
      oErr:Operation := Operation
   ENDIF
   IF Description != NIL
      oErr:Description := Description
   ENDIF
   IF Args != NIL
      oErr:Args := Args
   ENDIF

   IF ModuleName == NIL
      oErr:ModuleName := ProcFile( 1 )
   ELSE
      oErr:ModuleName := ModuleName
   ENDIF
   IF ProcName == NIL
      oErr:ProcName := ProcName(1)
   ELSE
      oErr:ProcName := ProcName
   ENDIF
   IF ProcLine == NIL
      oErr:ProcLine := ProcLine(1)
   ELSE
      oErr:ProcLine := ProcLine
   ENDIF

   nLevel := 1
   aaStack := oErr:aaStack
   WHILE ! Empty( ProcName( nLevel ) )
      aAdd( aaStack, { ProcFile( nLevel ), ProcName( nLevel ), ProcLine( nLevel ) } )
      nLevel++
   ENDDO

   #ifdef HB_THREAD_SUPPORT
      oErr:RunningThreads := HB_ThreadCountStacks()
      oErr:OsThreadId     := ThreadGetCurrent()
      oErr:VMThreadId     := ThreadGetCurrentInternal()
   #endif

   lInErr := .F.

RETURN oErr

FUNCTION __eInstVar53( oVar, cMethod, xValue, cType, nSubCode, bValid )

   LOCAL oError

   IF !( VALTYPE( xValue ) == cType ) .OR. ;
      ( bValid != NIL .AND. !EVAL( bValid, oVar, xValue ) )
      oError := ErrorNew()
      oError:description := HB_LANGERRMSG( 1 )
      oError:gencode := 1
      oError:severity := 2
      oError:cansubstitute := .T.
      oError:subsystem := oVar:className
#ifdef HB_C52_STRICT
      HB_SYMBOL_UNUSED( cMethod )
#else
      oError:operation := cMethod
#endif
      oError:subcode := nSubCode
      oError:args := { xValue }
      xValue := EVAL( ERRORBLOCK(), oError )
      IF !( VALTYPE( xValue ) == cType )
         __errInHandler()
      ENDIF
   ENDIF

   RETURN xValue
