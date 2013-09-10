/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// UpDown.prg                                                                                           *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"


//-----------------------------------------------------------------------------------------------

CLASS UpDown INHERIT Control
   PROPERTY Buddy GET __ChkComponent( Self, @::xBuddy, .F. ) SET __SetBuddy
   DATA MinRange         PUBLISHED INIT 0
   DATA MaxRange         PUBLISHED INIT 100
   DATA DisplayThousands PUBLISHED INIT .F.
   DATA ArrowKeys        PUBLISHED INIT .T.
   
   DATA EnumAlignment    EXPORTED INIT {{ "Left", "Right" }, {UDS_ALIGNLEFT, UDS_ALIGNRIGHT} }
   DATA Alignment        PUBLISHED INIT UDS_ALIGNRIGHT

   DATA __lResizeable          EXPORTED INIT {.F.,.F.,.F.,.F.,.F.,.T.,.F.,.F.}
   
   METHOD Init()  CONSTRUCTOR
   METHOD Create()
   METHOD __SetBuddy()
   METHOD SetRange( n, i ) INLINE    ::SendMessage( UDM_SETRANGE, 0, MAKELONG( n, i ) )
ENDCLASS

METHOD Init( oParent ) CLASS UpDown
   ::ClsName := "msctls_updown32"
   DEFAULT ::Style   TO WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | UDS_ALIGNRIGHT | UDS_SETBUDDYINT
   DEFAULT ::__xCtrlName TO "UpDown"
   ::Super:Init( oParent )
   ::Width        := 80
   ::Height       := 22
   ::__lMoveable := .T.
RETURN Self

METHOD Create() CLASS UpDown
   ::SetStyle( UDS_NOTHOUSANDS, ! ::DisplayThousands )
   ::SetStyle( UDS_ARROWKEYS, ::ArrowKeys )
   ::SetStyle( UDS_ALIGNRIGHT, .F. )
   ::SetStyle( UDS_ALIGNLEFT, .F. )
   ::SetStyle( ::Alignment, .T. )
   ::Super:Create()
   ::__SetBuddy()
   ::SetRange( ::MaxRange, ::MinRange )
RETURN Self

METHOD __SetBuddy( oBuddy ) CLASS UpDown
   IF ::IsWindow()
      DEFAULT oBuddy TO ::Buddy
      IF VALTYPE( oBuddy ) != "C"
         ::SendMessage( UDM_SETBUDDY, IIF( oBuddy != NIL, oBuddy:hWnd, NIL ) )
      ENDIF
   ENDIF
RETURN Self
