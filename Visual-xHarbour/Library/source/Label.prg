/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Label.prg                                                                                            *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"

//-----------------------------------------------------------------------------------------------

CLASS Label INHERIT Control
   DATA EnumAlignment    EXPORTED INIT { { "Left", "Center", "Right" }, { DT_LEFT, DT_CENTER, DT_RIGHT } }
   PROPERTY Alignment    SET Redraw  DEFAULT DT_LEFT PROTECTED

   DATA EnumBorder       EXPORTED INIT { { "None", "Flat", "Sunken", "Risen" }, { 0, -1, BDR_SUNKENINNER, BDR_RAISEDINNER } }
   PROPERTY Border       SET Redraw  DEFAULT 0       PROTECTED

   PROPERTY Transparent  READ xTransparent WRITE __SetTransp DEFAULT .F.

   PROPERTY NoPrefix     SET Redraw  DEFAULT .F.     PROTECTED
   PROPERTY VertCenter   SET Redraw  DEFAULT .F.     PROTECTED

   PROPERTY TextShadowColor READ xTextShadowColor WRITE InvalidateRect
   PROPERTY BlinkColor      READ xBlinkColor      WRITE __SetBlinkColor

   // Backward compatibility
   ACCESS CenterText    INLINE ::Alignment == DT_CENTER
   ASSIGN CenterText(l) INLINE ::Alignment := IIF( l, DT_CENTER, DT_LEFT )

   ACCESS RightAlign    INLINE ::Alignment == DT_RIGHT
   ASSIGN RightAlign(l) INLINE ::Alignment := IIF( l, DT_RIGHT, DT_LEFT )

   ACCESS Sunken        INLINE ::Border == BDR_SUNKENINNER
   ASSIGN Sunken(l)     INLINE ::Border := IIF( l, BDR_SUNKENINNER, 0 )

   ASSIGN SunkenText(l)  INLINE IIF( l, ::xTextShadowColor := RGB( 255, 255, 255 ),)

   DATA ClientEdge     EXPORTED INIT .F.
   DATA StaticEdge     EXPORTED INIT .F.

   DATA __CurColor     PROTECTED

   METHOD Init()  CONSTRUCTOR
   METHOD Create()
   METHOD SetParent( oParent ) INLINE IIF( ::__hBrush != NIL, ( DeleteObject( ::__hBrush ), ::__hBrush := NIL ), ), ::Super:SetParent( oParent ), ::RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW )
   METHOD OnEraseBkGnd()       INLINE 1
   METHOD OnPaint()
   METHOD SetWindowText(cText) INLINE Super:SetWindowText(cText), ::InvalidateRect()
   METHOD __SetTransp(lSet)    INLINE IIF( lSet, ::Parent:__RegisterTransparentControl( Self ), ::Parent:__UnregisterTransparentControl( Self ) )
   METHOD __SetBlinkColor()
   METHOD OnSize(w,l)          INLINE Super:OnSize( w, l ), ::InvalidateRect(, .F. ), NIL
   METHOD OnLButtonUp()
   METHOD OnTimer()
   METHOD SetForeColor()
ENDCLASS

//-----------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS Label
   DEFAULT ::__xCtrlName TO "Label"
   ::Style := WS_CHILD | WS_VISIBLE | BS_OWNERDRAW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
   ::ClsName := "Label"
   ::Super:Init( oParent )
   ::__IsStandard := .F.
   ::xWidth      := 80
   ::xHeight     := 16
   ::Events     := ;
          { ;
            {"Command",     {;
                            { "OnClick"            , "", "" } } },;
            {"Layout",      { ;
                            { "OnEnterSizeMove"    , "", "" },;
                            { "OnExitSizeMove"     , "", "" },;
                            { "OnMove"             , "", "" },;
                            { "OnSize"             , "", "" } } },;
            {"Mouse",       {;
                            { "OnLButtonDblClk"    , "", "" },;
                            { "OnLButtonDown"      , "", "" },;
                            { "OnLButtonUp"        , "", "" },;
                            { "OnMButtonDown"      , "", "" },;
                            { "OnMButtonUp"        , "", "" },;
                            { "OnMouseHover"       , "", "" },;
                            { "OnMouseLeave"       , "", "" },;
                            { "OnMouseMove"        , "", "" },;
                            { "OnRButtonDown"      , "", "" },;
                            { "OnRButtonUp"        , "", "" } } },;
            {"Control",     {;
                            { "OnCreate"           , "", "" },;
                            { "OnDestroy"          , "", "" },;
                            { "OnEnable"           , "", "" },;
                            { "OnSetText"          , "", "" } } } }
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD Create()  CLASS Label
   IF ::Parent:__xCtrlName IN {"TabPage","GroupBox"} .AND. ! ::xTransparent .AND. ::BackColor == ::BackSysColor
      ::__SetTransp(.T.)
   ENDIF
   Super:Create()
   ::__SetBlinkColor()
RETURN Self
//-----------------------------------------------------------------------------------------------

METHOD SetForeColor( nColor, lRepaint ) CLASS Label
   DEFAULT lRepaint TO .T.
   ::xForeColor := nColor
   ::__CurColor := nColor
   IF lRepaint .AND. ::IsWindowVisible()
      ::Refresh()
   ENDIF
   IF ::IsWindowVisible()
      ::InValidateRect()
   ENDIF
RETURN SELF

//-----------------------------------------------------------------------------------------------
METHOD __SetBlinkColor() CLASS Label
   IF ::__ClassInst == NIL
      IF ::BlinkColor != NIL
         ::SetTimer( 512, 500 )
       ELSE
         ::KillTimer( 512 )
         ::__CurColor := ::ForeColor
         ::RedrawWindow( , , RDW_INTERNALPAINT | RDW_UPDATENOW | RDW_INVALIDATE )
      ENDIF
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD OnTimer( nID ) CLASS Label
   IF nID == 512
      ::KillTimer( 512 )
      DEFAULT ::__CurColor TO ::ForeColor
      IF ::__CurColor == ::ForeColor
         ::__CurColor := ::BlinkColor
      ELSE
         ::__CurColor := ::ForeColor
      ENDIF
      ::RedrawWindow( , , RDW_INTERNALPAINT | RDW_UPDATENOW | RDW_INVALIDATE )
      ::SetTimer( 512, 500 )
   ENDIF
RETURN 0

//-----------------------------------------------------------------------------------------------
METHOD OnLButtonUp() CLASS Label
   LOCAL nRet
   nRet := __Evaluate( ::Action, Self,,, nRet )
   ExecuteEvent( "OnClick", Self )
RETURN nRet

//-----------------------------------------------------------------------------------------------
METHOD OnPaint() CLASS Label
   LOCAL nFlags, cText, hDC, hBrush, hFont, aText, hBkGnd := ::GetBkBrush(), aRect := {0,0,::xWidth,::xHeight}

   hDC := ::BeginPaint()

   DEFAULT ::__CurColor TO ::ForeColor

   DEFAULT hBkGnd TO GetSysColorBrush( COLOR_BTNFACE )
   _FillRect( hDC, aRect, hBkGnd )

   IF VALTYPE( ::Border ) == "L"
      ::Border := -1
   ENDIF
   IF ::Border <> 0
      IF ::Border == -1
         hBrush := SelectObject( hDC, GetStockObject( NULL_BRUSH ) )
         Rectangle( hDC, aRect[1], aRect[2], aRect[3], aRect[4] )
         SelectObject( hDC, hBrush )
       ELSE
         _DrawEdge( hDC, aRect, ::Border, BF_RECT )
      ENDIF
      aRect := {1,1,::xWidth-1,::xHeight-1}
   ENDIF

   SetBkMode( hDC, TRANSPARENT )
   hFont  := SelectObject( hDC, ::Font:Handle )
   nFlags := ::Alignment | DT_WORDBREAK

   IF ::NoPrefix
      nFlags := nFlags | DT_NOPREFIX
   ENDIF

   IF ::VertCenter
      nFlags := nFlags | DT_VCENTER
      aText  := ACLONE( aRect )
      _DrawText( hDC, ::xText, @aText, nFlags | DT_CALCRECT )
      aRect[2] := ( aRect[4]-aText[4] ) / 2
      aRect[4] := aRect[2] + aText[4]
   ENDIF
   
   cText := ::xText
   DEFAULT cText TO ""

   IF ::xTextShadowColor != NIL
      aRect[1] += 1
      aRect[2] += 1
      aRect[3] += 1
      aRect[4] += 1
      SetTextColor( hDC, ::xTextShadowColor )
      _DrawText( hDC, cText, aRect, nFlags )
      aRect[1] -= 1
      aRect[2] -= 1
      aRect[3] -= 1
      aRect[4] -= 1
   ENDIF
   SetTextColor( hDC, ::__CurColor )
   _DrawText( hDC, cText, aRect, nFlags )
   SelectObject( hDC, hFont )
   
   ::EndPaint()
RETURN 0



CLASS Line INHERIT CONTROL
   PROPERTY Lenght         READ xLenght   WRITE __SetLenght   DEFAULT 150 INVERT
   PROPERTY Sunken         READ xSunken   WRITE __SetSunken   DEFAULT .T. INVERT
   PROPERTY Vertical       READ xVertical WRITE __SetVertical DEFAULT .F.

   ACCESS Width            INLINE ::xWidth
   ACCESS Height           INLINE ::xHeight

   DATA xText              EXPORTED  INIT ""
   DATA Text               EXPORTED  INIT ""

   DATA Weight             EXPORTED  INIT 2
   DATA Border             EXPORTED
   DATA IndexOrder         EXPORTED  INIT 0

   DATA Font               EXPORTED
   DATA TabStop            EXPORTED
   DATA BackColor          EXPORTED
   DATA ForeColor          EXPORTED
   DATA AllowClose         EXPORTED
   DATA AllowUndock        EXPORTED
   DATA ClientEdge         EXPORTED
   DATA ClipChildren       EXPORTED
   DATA ClipSiblings       EXPORTED
   DATA OwnerDraw          EXPORTED  INIT .F.
   DATA StaticEdge         EXPORTED
   DATA Transparent        EXPORTED

   DATA AcceptFiles        EXPORTED  INIT .F.
   DATA AnimationStyle     EXPORTED  INIT 0
   DATA ContextMenu        EXPORTED
   DATA AllowMaximize      EXPORTED  INIT .F.
   DATA Enabled            EXPORTED  INIT .T.
   DATA TabOrder           EXPORTED  INIT 0  
   DATA NoActivate         EXPORTED  INIT .F.
   DATA Theming            EXPORTED  INIT .F.

   DATA Color              PUBLISHED INIT GetSysColor( COLOR_BTNSHADOW )

   METHOD Init() CONSTRUCTOR
   METHOD Create()

   METHOD OnEraseBkGnd()
   METHOD OnSize()

   METHOD __SetVertical()
   METHOD __SetSunken()
   METHOD __SetLenght()
ENDCLASS

METHOD Init( oParent ) CLASS Line
   DEFAULT ::__xCtrlName TO "Line"
   ::ClsName       := "VxhLine"
   ::Style         := WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
   ::__lResizeable := {.F.,.T.,.F.,.F.,.F.,.T.,.F.,.F.}
   ::Super:Init( oParent )
   ::__IsStandard  := .F.
   ::Width         := ::Lenght
   ::Height        := ::Weight
   ::Events        := ;
          { ;
            {"Layout",      { ;
                            { "OnEnterSizeMove"    , "", "" },;
                            { "OnExitSizeMove"     , "", "" },;
                            { "OnMove"             , "", "" },;
                            { "OnSize"             , "", "" } } },;
            {"Control",     {;
                            { "OnCreate"           , "", "" },;
                            { "OnDestroy"          , "", "" },;
                            { "OnEnable"           , "", "" } } } }
RETURN Self

METHOD Create() CLASS Line
   Super:Create()
RETURN Self

METHOD __SetVertical( lSet ) CLASS Line
   ::__lResizeable := {.F.,!lSet,.F.,lSet,.F.,!lSet,.F.,lSet}
   IF lSet
      ::xHeight := ::xLenght
      ::xWidth  := ::Weight
    ELSE
      ::xWidth  := ::xLenght
      ::xHeight := ::Weight
   ENDIF
   IF ::hWnd != NIL
      ::MoveWindow()
   ENDIF
RETURN NIL

METHOD __SetSunken( lSet ) CLASS Line
   IF ::xSunken != lSet
      ::Weight := IIF( lSet, 2, 1 )
      IF ::xVertical
         ::xWidth := ::Weight
       ELSE
         ::xHeight := ::Weight
      ENDIF
   ENDIF
   IF ::hWnd != NIL
      ::MoveWindow()
   ENDIF
RETURN NIL

METHOD __SetLenght( nLen ) CLASS Line
   IF ::xLenght != nLen
      IF ::xVertical
         ::xHeight := nLen
       ELSE
         ::xWidth  := nLen
      ENDIF
      IF ::hWnd != NIL
         ::MoveWindow()
      ENDIF
   ENDIF
RETURN NIL

METHOD OnSize( nwParam, nlParam ) CLASS Line
   Super:OnSize( nwParam, nlParam )
   IF ::__ClassInst != NIL
      ::xLenght := IIF( ::xVertical, ::Height, ::Width )
   ENDIF
RETURN NIL
   
METHOD OnEraseBkGnd( hDC ) CLASS Line
   LOCAL lVert := ::xVertical, hBrush := CreateSolidBrush( ::Color )
   _FillRect( hDC, { 0, 0, IIF( lVert, 1, ::Width ), IIF( lVert, ::Height, 1 ) }, hBrush )
   DeleteObject( hBrush )
   IF ::Sunken
      _FillRect( hDC, { IIF( lVert, 1, 0 ), IIF( lVert, 0, 1 ), IIF( lVert, 2, ::Width ), IIF( lVert, ::Height, 2 ) }, GetStockObject( WHITE_BRUSH ) )
   ENDIF
RETURN 1
