/*
 * $Id$
 */
//------------------------------------------------------------------------------------------------------*
//                                                                                                      *
// Control.prg                                                                                          *
//                                                                                                      *
// Copyright (C) xHarbour.com Inc. http://www.xHarbour.com                                              *
//                                                                                                      *
//  This source file is an intellectual property of xHarbour.com Inc.                                   *
//  You may NOT forward or share this file under any conditions!                                        *
//------------------------------------------------------------------------------------------------------*

#include "debug.ch"
#include "vxh.ch"

//-----------------------------------------------------------------------------------------------

CLASS Control INHERIT Window

   DATA AllowUnDock       PUBLISHED INIT FALSE
   DATA Dock              PUBLISHED
   DATA Anchor            PUBLISHED
   DATA AllowClose        PUBLISHED INIT FALSE
   DATA MenuArrow         PUBLISHED INIT FALSE
   DATA HighlightCaption  PUBLISHED INIT .T.
   DATA Transparent       EXPORTED INIT .F.

   PROPERTY ContextMenu GET __ChkComponent( Self, ::xContextMenu )

   PROPERTY TabStop INDEX WS_TABSTOP READ xTabStop      WRITE SetStyle          DEFAULT .T. PROTECTED
   PROPERTY SmallCaption             READ xSmallCaption WRITE __SetSmallCaption DEFAULT .F.
   PROPERTY Enabled                  READ xEnabled      WRITE __Enable          DEFAULT .T.

   ACCESS xCaption       INLINE ::xText
   ASSIGN xCaption(c)    INLINE ::xText := c

   ACCESS Caption        INLINE ::Text
   ASSIGN Caption(c)     INLINE ::Text := c

   DATA xText                  EXPORTED  INIT ""
   ACCESS Text                 INLINE    IIF( ! ::IsWindow() .OR. ::__IsInstance, ::xText, _GetWindowText( ::hWnd ) ) PERSISTENT
   ASSIGN Text(c)              INLINE    ::SetWindowText( c ),;
                                         ::xText := c,;
                                         IIF( ::SmallCaption,;
                                             ::RedrawWindow( , , RDW_FRAME | RDW_NOERASE | RDW_NOINTERNALPAINT | RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOCHILDREN ), )

   DATA AllowMaximize     PUBLISHED INIT .F.
   
   DATA FlatBorder        EXPORTED INIT .F.
   DATA IsContainer       EXPORTED INIT .F.
   DATA Value             EXPORTED
   DATA Options           EXPORTED
   DATA Data              EXPORTED
   DATA Action            EXPORTED
   DATA Validating        EXPORTED INIT FALSE
   DATA IsValid           EXPORTED INIT TRUE
   DATA CaptionHeight     EXPORTED INIT 0
   DATA CaptionWidth      EXPORTED
   DATA EmptyLeft         EXPORTED INIT 0
   DATA ToolBarPos        EXPORTED INIT 1
   DATA KeepActiveCaption EXPORTED INIT .F.
   DATA AutoClose         EXPORTED INIT .T.
   DATA DisableParent     EXPORTED INIT .F.
   DATA ShowMode          EXPORTED INIT 1
   DATA Modal             EXPORTED INIT .F.
   DATA __IdeImageIndex   EXPORTED INIT 3
   DATA __BackMargin      EXPORTED INIT 0
   DATA OnWMUnDock        EXPORTED
   DATA OnWMReDock        EXPORTED

   DATA __hParBrush       PROTECTED
   DATA CaptionRect       PROTECTED
   DATA PinPushed         PROTECTED INIT .F.
   DATA PinHover          PROTECTED INIT .F.
   DATA PinRect           PROTECTED
   DATA ClosePushed       PROTECTED INIT .F.
   DATA CloseHover        PROTECTED INIT .F.
   DATA CloseRect         PROTECTED
   DATA ArrowRect         PROTECTED
   DATA BackInfo          PROTECTED
   DATA Center            PROTECTED INIT .F.
   DATA __DockParent      PROTECTED
   Data FlatCaption       EXPORTED INIT .F. //backward compatibility
   DATA __hBorderBtnPen   PROTECTED
   DATA __hSelectBtnBrush PROTECTED
   DATA __hPushedBtnBrush PROTECTED

   ACCESS Child           INLINE ::Style & WS_CHILD != 0
   ACCESS ControlParent   INLINE ::ExStyle & WS_EX_CONTROLPARENT != 0
   ACCESS MdiContainer    INLINE ::xMdiContainer
   ASSIGN MdiContainer(l) INLINE ::xMdiContainer := l

   ACCESS IsDocked        INLINE ::__Docked

   METHOD Init() CONSTRUCTOR
   METHOD Create()

   METHOD OnMouseActivate()
//   METHOD OnNCLButtonDblClk() INLINE IIF( ::AllowMaximize, NIL, 0 )
   METHOD Disable()             INLINE ::Enabled := .F.
   METHOD Enable()              INLINE ::Enabled := .T.
   METHOD OnSize()
   METHOD OnMove()
   METHOD OnNCCalcSize()
   METHOD OnNCPaint()
   METHOD OnNCHitTest()
   METHOD OnNCLButtonDown()
   METHOD OnNCLButtonUp()
   METHOD OnNCMouseleave()
   METHOD OnSysKeyDown()
   METHOD DrawClose()
   METHOD DrawPin()
   METHOD DrawArrow()
   METHOD OnKillFocus()
   METHOD OnSetFocus()
   METHOD Undock()
   METHOD Redock()
   METHOD Redraw() INLINE /*::SetWindowPos(,0,0,0,0,SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER),*/;
                          ::RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_INTERNALPAINT | RDW_ALLCHILDREN ),::UpdateWindow()
   METHOD IsComponent( oComp ) INLINE ::HasMessage( oComp:__xCtrlName ) .AND. &("HB_QSELF():"+oComp:__xCtrlName) == oComp
   METHOD Hide() INLINE IIF( ::__DockParent != NIL, ::__DockParent:Hide(), ::Super:Hide() )
   METHOD Show() INLINE IIF( ::__DockParent != NIL, ::__DockParent:Show(), ::Super:Show( SW_SHOW ) )
   METHOD __Enable( lEnable )
   METHOD __SetSmallCaption()
   METHOD GetBkBrush()
   METHOD OnDestroy()          INLINE IIF( ::__hParBrush != NIL, DeleteObject( ::__hParBrush ),), Super:OnDestroy()
ENDCLASS

METHOD __Enable( lEnable ) CLASS Control
   IF ::hWnd != NIL .AND. ::__xCtrlName != "Button"
      EnableWindow( ::hWnd, lEnable )
      ::InvalidateRect( , .F. )
   ENDIF
RETURN lEnable

//---------------------------------------------------------------------------------------------------

METHOD Init( oParent ) CLASS Control
   DEFAULT ::xSmallCaption TO FALSE
   ::__IsControl  := .T.
   ::__IsStandard := .T.
   ::Super:Init( oParent )
   ::Id := ::Form:GetNextControlId()
   //IF ::__ClassInst != NIL
   //   __AddEvent( ::Events, "Command", "OnArrowClick" )
   //ENDIF
RETURN Self

//---------------------------------------------------------------------------------------------------

METHOD Create( hParent ) CLASS Control
   ::xTop := MAX( ::xTop, ::Parent:TopMargin)

   IF ::IsContainer
      ::__IdeImageIndex := 1
   ENDIF

   IF ::Parent:__xCtrlName == "ToolBar" .AND. ::Parent:IsWindow()
      ::Parent:AddControl( Self, ::ToolBarPos )
   ENDIF

   ::Super:Create( hParent )
   IF ::__OnInitCanceled
      RETURN NIL
   ENDIF

   IF ::__ClassInst != NIL
      ::__ClassInst:Id           := ::Id
      __DeleteEvents( ::Events, { "OnLoad",;
                                  "OnChangeCbChain",;
                                  "OnDrawClipboard",;
                                  "OnCancel",;
                                  "OnCommand",;
                                  "OnOk",;
                                  "OnSysCommand",;
                                  "OnToolTipNotify",;
                                  "OnCtlColorDlg",;
                                  "OnDrawItem",;
                                  "OnChildChar",;
                                  "OnChildGetDlgCode",;
                                  "OnChildKeyDown",;
                                  "OnHotKey",;
                                  "OnGetMinMaxInfo",;
                                  "OnMeasureItem"  ,;
                                  "OnCancelMode",;
                                  "OnEnterMenuLoop",;
                                  "OnExitMenuLoop",;
                                  "OnInitMenuPopup",;
                                  "OnMenuChar",;
                                  "OnMenuCommand",;
                                  "OnMenuSelect",;
                                  "OnNextMenu",;
                                  "OnTimer",;
                                  "OnInitDialog" } )
   ENDIF
   IF ::Parent:ClsName == "StatusBarPanel"
      ::Parent:Parent:SetPanels()
      ::__lResizeable := {.F.,.F.,.F.,.F.,.F.,.F.,.F.,.F.}
      ::__lMoveable   := .F.
   ENDIF

   IF ::Parent:ClsName == "ToolStrip"
      ::Parent:__UpdateWidth()
   ENDIF
   IF ::__xCtrlName != "Button"
      IF !::xEnabled
         EnableWindow( ::hWnd, .F.  )
      ENDIF
   ENDIF
   
RETURN Self

//---------------------------------------------------------------------------------------------------

METHOD OnSize( nwParam, nlParam ) CLASS Control
   LOCAL x, y
   IF ::Super:OnSize( nwParam, nlParam ) == NIL
      x := LOWORD( nlParam )
      y := HIWORD( nlParam )
      IF !EMPTY( ::xText ) .AND. ::Style & WS_CHILD == 0 .AND. ::xSmallCaption
         ::RedrawWindow( , , RDW_FRAME + RDW_INVALIDATE + RDW_UPDATENOW )
      ENDIF
      IF ::LeftSplitter != NIL
         ::LeftSplitter:__OnParentSize( x, y )
      ENDIF
      IF ::TopSplitter != NIL
         ::TopSplitter:__OnParentSize( x, y )
      ENDIF
      IF ::RightSplitter != NIL
         ::RightSplitter:__OnParentSize( x, y )
      ENDIF
      IF ::BottomSplitter != NIL
         ::BottomSplitter:__OnParentSize( x, y )
      ENDIF
   ENDIF
RETURN NIL

METHOD OnMove( x, y ) CLASS Control
   IF ::Super:OnMove( x, y ) == NIL
      IF ::LeftSplitter != NIL
         ::LeftSplitter:OnParentMove( x, y )
      ENDIF
      IF ::TopSplitter != NIL
         ::TopSplitter:OnParentMove( x, y )
      ENDIF
      IF ::RightSplitter != NIL
         ::RightSplitter:OnParentMove( x, y )
      ENDIF
      IF ::BottomSplitter != NIL
         ::BottomSplitter:OnParentMove( x, y )
      ENDIF
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD OnKillFocus() CLASS Control
   IF ::Super:OnKillFocus() == NIL .AND. !EMPTY( ::xText ) .AND. ::xSmallCaption
      ::RedrawWindow( , , RDW_FRAME | RDW_NOERASE | RDW_NOINTERNALPAINT | RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOCHILDREN )
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD __SetSmallCaption() CLASS Control
   IF ::hWnd != NIL
      ::SetWindowPos(,0,0,0,0,SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER)
      ::RedrawWindow( , , RDW_FRAME | RDW_NOERASE | RDW_NOINTERNALPAINT | RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOCHILDREN )
   ENDIF
RETURN Self

METHOD OnSetFocus() CLASS Control
   IF ::Super:OnSetFocus() == NIL .AND. !EMPTY( ::xText ) .AND. ::xSmallCaption
      ::RedrawWindow( , , RDW_FRAME | RDW_NOERASE | RDW_NOINTERNALPAINT | RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOCHILDREN )
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD OnMouseActivate( hWnd, nHit, nMsg ) CLASS Control
   LOCAL oChild
   IF nHit == 1 .AND. LEFT( ::ClsName, 11 ) != "Splitter" .AND. ::ClsName != "OptionBar"
      FOR EACH oChild IN ::Parent:Children
          IF oChild:Active
             oChild:Active := FALSE
             oChild:InvalidateRect( {0,0, oChild:ClientWidth,14}, FALSE )
          ENDIF
      NEXT
   ENDIF
RETURN ::Super:OnMouseActivate( hWnd, nHit, nMsg )

//---------------------------------------------------------------------------------------------------

METHOD OnNCCalcSize( nwParam, nlParam ) CLASS Control
   LOCAL nccs
   (nwParam)
   ::CaptionHeight := 0
   IF ( !EMPTY( ::xText ) .AND. ::xSmallCaption ) .OR. ::FlatBorder
      IF ::Style & WS_DLGFRAME != 0 .AND. ::Style & WS_BORDER != 0
         ::xSmallCaption := FALSE
         RETURN NIL
      ENDIF

      nccs := (struct NCCALCSIZE_PARAMS)
      nccs:Pointer( nlParam )
      
      IF ( !EMPTY( ::xText ) .AND. ::xSmallCaption )
         ::CaptionHeight := IIF( ::Font != NIL, ABS( ::Font:Height ), ABS( ::Form:Font:Height ) ) + 8

         nccs:rgrc[1]:Left += ::EmptyLeft
         nccs:rgrc[1]:Top  += ::CaptionHeight
      ENDIF      
      IF ::FlatBorder .AND. ::__xCtrlName != "ToolBox"
         nccs:rgrc[1]:Left   += 1
         IF ! ( !EMPTY( ::xText ) .AND. ::xSmallCaption )
            nccs:rgrc[1]:Top    += 1
         ENDIF
         nccs:rgrc[1]:Right  -= 1
         nccs:rgrc[1]:Bottom -= 1
      ENDIF
      
      nccs:CopyTo( nlParam )

      ::CaptionWidth := nccs:rgrc[1]:Right
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD OnNCMouseLeave() CLASS Control
   ::Super:OnNCMouseLeave()
   IF !EMPTY( ::xText ) .AND. ::xSmallCaption .AND. ::AllowClose
      ::CloseHover  := .F.
      ::PinHover    := .F.
      ::Redraw()
      RETURN 0
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD OnNCPaint( nwParam, nlParam ) CLASS Control
   LOCAL hOldBrush, hOldPen, hdc, hOldFont, nWidth, hRegion, hBrush, n:=0
   ::CallWindowProc()
   IF ::Super:OnNCPaint( nwParam, nlParam ) == NIL .AND. !EMPTY( ::xText ) .AND. ::xSmallCaption
      ::CaptionWidth := ::xWidth

      //hRegion := CreateRectRgn( 0, 0, ::Width, ::Height )
      hdc := GetWindowDC( ::hWnd ) //GetDCEx( ::hWnd, hRegion, DCX_WINDOW | DCX_PARENTCLIP | DCX_CLIPSIBLINGS | DCX_VALIDATE )

      IF ::ExStyle & WS_EX_CLIENTEDGE == WS_EX_CLIENTEDGE
         n += 2
      ENDIF
      IF ::ExStyle & WS_EX_STATICEDGE == WS_EX_STATICEDGE
         n += 1
      ENDIF
      ::CaptionRect := { n, n, ::CaptionWidth - n, ::CaptionHeight + n + IIF( ::Style & WS_BORDER == WS_BORDER, 1, 0 ) }

      hOldPen   := SelectObject( hDC, ::System:CurrentScheme:Pen:MenuBorder )
      hBrush    := CreateSolidBrush( GetSysColor( IIF( ( ::HasFocus .OR. ::KeepActiveCaption ) .AND. ::HighlightCaption, COLOR_ACTIVECAPTION, COLOR_INACTIVECAPTION ) ) )
      hOldBrush := SelectObject( hDC, hBrush )
      Rectangle( hDC, ::CaptionRect[1], ::CaptionRect[2], ::CaptionRect[3], ::CaptionRect[4] )
      DeleteObject( SelectObject( hDC, hOldBrush ) )
      SelectObject( hDC, hOldPen )
      
      SetTextColor( hDC, GetSysColor( IIF( ( ::HasFocus .OR. ::KeepActiveCaption ) .AND. ::HighlightCaption, COLOR_CAPTIONTEXT, COLOR_INACTIVECAPTIONTEXT) ) )

      hOldFont := SelectObject( hDC, ::Font:handle )
      SetBkMode( hDC, TRANSPARENT )

      n := 0
      IF !::IsChild
         n := 1
      ENDIF

      IF ::MenuArrow
         ::ArrowRect := { 0, ::CaptionRect[2]+n+1, 20, ::CaptionRect[4]-2 }
         ::DrawArrow( hDC, ::ArrowRect )
      ENDIF

      _DrawText( hDC, ::xText, { IIF( ::MenuArrow .AND. ::ArrowRect != NIL, ::ArrowRect[3]+2, ::CaptionRect[1]+5 ), ::CaptionRect[2], ::CaptionRect[3], ::CaptionRect[4] }, DT_LEFT | DT_SINGLELINE | DT_VCENTER | DT_WORD_ELLIPSIS )

      nWidth := 0
      IF ::AllowClose
         ::CloseRect := { ::CaptionRect[3]-::CaptionRect[4]+n+1, ::CaptionRect[2]+n+1, ::CaptionRect[3]-2, ::CaptionRect[4]-2 }
         ::DrawClose( hDC, n )
         nWidth := ::CloseRect[3]-::CloseRect[1]+1
      ENDIF
      IF ::AllowUnDock
         ::PinRect := { (::CaptionRect[3]-::CaptionRect[4])+n-nWidth+1, ::CaptionRect[2]+n+1, ::CaptionRect[3]-2-nWidth, ::CaptionRect[4]-2 }
         ::DrawPin( hDC, n )
      ENDIF
      SelectObject( hDC, hOldFont )
      ReleaseDC(::hWnd, hdc)
      //DeleteObject( hRegion )
   ENDIF

   IF ::FlatBorder
      hRegion := CreateRectRgn( 0, 0, ::Width, ::Height )
      hdc := GetDCEx( ::hWnd, hRegion, DCX_WINDOW + DCX_PARENTCLIP + DCX_CLIPSIBLINGS + DCX_VALIDATE )

      hOldPen   := SelectObject( hDC, ::System:CurrentScheme:Pen:MenuBorder )
      hOldBrush := SelectObject( hDC, GetStockObject( NULL_BRUSH ) )
      Rectangle( hDC, 0, 0, ::Width, ::Height )
      SelectObject( hDC, hOldBrush )
      SelectObject( hDC, hOldPen )

      ReleaseDC(::hWnd, hdc)
      DeleteObject( hRegion )
   ENDIF

RETURN 0

//---------------------------------------------------------------------------------------------------

METHOD OnNCLButtonDown( nwParam ) CLASS Control
   LOCAL hRegion, hdc, aRect, n
   IF nwParam == HTCAPTION
      IF !::HasFocus //.AND. ::ClsName != "PanelBox"
         ::SetFocus()
      ENDIF
      IF ::Style & WS_CHILD == WS_CHILD
         RETURN 0
      ENDIF
   ENDIF
   IF nwParam == HTCLOSE .OR. nwParam == HTBORDER
      IF ::CloseHover .AND. ::CloseRect != NIL
         ::ClosePushed := .T.
         ::PinPushed   := .F.
         aRect := ACLONE( ::CloseRect )
       ELSEIF ::PinHover .AND. ::PinRect != NIL
         ::PinPushed := .T.
         ::ClosePushed := .F.
         aRect := ACLONE( ::PinRect )
      ENDIF
      IF aRect != NIL
         hRegion := CreateRectRgn( aRect[1], aRect[2], aRect[3], aRect[4] )
         hdc := GetDCEx( ::hWnd, hRegion, DCX_WINDOW + DCX_PARENTCLIP + DCX_CLIPSIBLINGS + DCX_VALIDATE )
         n := 0
         IF !::IsChild
            n := 1
         ENDIF
         IF ::CloseHover
            ::DrawClose( hDC, n )
          ELSEIF ::PinHover
            ::DrawPin( hDC, n )
         ENDIF
         ReleaseDC(::hWnd, hdc)
         DeleteObject( hRegion )
         RETURN nwParam
      ENDIF
   ENDIF
RETURN NIL //nwParam

//---------------------------------------------------------------------------------------------------

METHOD OnNCLButtonUp( nwParam, x, y ) CLASS Control
   LOCAL pt, aPt := {x,y}
   IF ::xSmallCaption
      ::CloseHover  := .F.
      ::PinHover    := .F.
      IF nwParam == HTCLOSE .OR. nwParam == HTBORDER .AND. !EMPTY( ::CaptionRect )
         _ScreenToClient( ::hWnd, @aPt )
         aPt[2]+=::CaptionRect[4]
         IF ::ClsName == "DLGEDT"
            aPt[1] += ::RullerWeight
            aPt[2] += ::RullerWeight
         ENDIF
         IF ::CloseRect != NIL .AND. _PtInRect( ::CloseRect, aPt ) .AND. ::ClosePushed
            ::PostMessage( WM_CLOSE )
          ELSEIF ::PinRect != NIL .AND. _PtInRect( ::PinRect, aPt ) .AND. ::PinPushed
            ::Undock()
         ENDIF
       ELSEIF nwParam == HTMENU
         _ScreenToClient( ::hWnd, @aPt )
         aPt[2]+=::CaptionRect[4]
         IF ::ArrowRect != NIL .AND. _PtInRect( ::ArrowRect, aPt )
            IF ::ContextMenu != NIL
               pt := (struct POINT)
               pt:x := ::Left
               pt:y := ::Top+::CaptionHeight
               ClientToScreen( ::Parent:hWnd, @pt )
               ::ContextMenu:Show( pt:x, pt:y )
            // ELSE
            //   RETURN ExecuteEvent( "OnArrowClick", Self )
            ENDIF
         ENDIF
      ENDIF
      ::ClosePushed := .F.
      ::PinPushed := .F.
   ENDIF
RETURN nwParam

//---------------------------------------------------------------------------------------------------

METHOD Redock() CLASS Control
   LOCAL oControl, hDef, o
   IF __Evaluate( ::OnWMRedock,  Self ) == NIL .AND. ::AllowUnDock //.AND. ::Style & WS_CHILD == 0
      ::__Docked := .T.
      ::xSmallCaption := .T.
      //::Style       := ::BackInfo[11]
      //::ExStyle     := ::BackInfo[12]
      //::SetWindowLong( GWL_STYLE, ::Style )
      //::SetWindowLong( GWL_EXSTYLE, ::ExStyle )
      ::Hide()

      SetParent( ::hWnd, ::BackInfo[13] )
      ::xLeft        := ::BackInfo[ 5]
      ::xTop         := ::BackInfo[ 6]
      ::xWidth       := ::BackInfo[ 7]
      ::xHeight      := ::BackInfo[ 8]

      ::ClientWidth := ::BackInfo[ 9]
      ::ClientHeight:= ::BackInfo[10]
      
      IF ::BackInfo[ 1] != NIL
         o := Splitter( ::Parent )
         o:Owner    := Self
         o:Weight   := ::BackInfo[1]:Weight
         o:Position := ::BackInfo[1]:Position
         o:Create()
      ENDIF
      IF ::BackInfo[ 2] != NIL
         o := Splitter( ::Parent )
         o:Owner    := Self
         o:Weight   := ::BackInfo[2]:Weight
         o:Position := ::BackInfo[2]:Position
         o:Create()
      ENDIF
      IF ::BackInfo[ 3] != NIL
         o := Splitter( ::Parent )
         o:Owner    := Self
         o:Weight   := ::BackInfo[3]:Weight
         o:Position := ::BackInfo[3]:Position
         o:Create()
      ENDIF
      IF ::BackInfo[ 4] != NIL
         o := Splitter( ::Parent )
         o:Owner    := Self
         o:Weight   := ::BackInfo[4]:Weight
         o:Position := ::BackInfo[4]:Position
         o:Create()
      ENDIF
      ::SetWindowPos(, ::xLeft, ::xTop, ::xWidth, ::xHeight, SWP_DRAWFRAME | SWP_FRAMECHANGED | SWP_NOSENDCHANGING )

      ::BackInfo := NIL

      IF ! Empty( ::Parent:__aDock )
         hDef := BeginDeferWindowPos( LEN( ::Parent:__aDock ) )
         FOR EACH oControl IN ::Parent:__aDock
             oControl:__OnParentSize( ::Parent:ClientWidth, ::Parent:ClientHeight, @hDef )
             oControl:InvalidateRect()//, .F. )
         NEXT
         EndDeferWindowPos( hDef )
      ENDIF

      ::__DockParent := NIL

      TRY
         IF ::Parent:MDIClient != NIL
            ::Parent:MDIClient:AlignLeft   := ::BackInfo[14][1]
            ::Parent:MDIClient:AlignTop    := ::BackInfo[14][2]
            ::Parent:MDIClient:AlignRight  := ::BackInfo[14][3]
            ::Parent:MDIClient:AlignBottom := ::BackInfo[14][4]
         ENDIF
       CATCH
      END
      ::Show()
      

      ExecuteEvent( "OnRedock", Self )
   ENDIF
RETURN Self

//---------------------------------------------------------------------------------------------------

METHOD Undock() CLASS Control
   LOCAL hDef, oChild, pt
   
   IF __Evaluate( ::OnWMUnDock,  Self ) == NIL .AND. ::AllowUnDock
      ::__Docked := .F.
      ::BackInfo := { ::LeftSplitter, ::TopSplitter, ::RightSplitter, ::BottomSplitter,;
                      ::xLeft, ::xTop, ::xWidth, ::xHeight, ::ClientWidth, ::ClientHeight,;
                      ::Style, ::ExStyle, ::Parent:hWnd,,,,}

      ::xSmallCaption := .F.

      IF ::Parent:MDIContainer .AND. ::Parent:MDIClient != NIL
         ::BackInfo[14] := { ::Parent:MDIClient:AlignLeft, ::Parent:MDIClient:AlignTop, ::Parent:MDIClient:AlignRight, ::Parent:MDIClient:AlignBottom }
         IF ::Parent:MDIClient:AlignLeft == Self
            ::Parent:MDIClient:AlignLeft := ::Dock:Left
         ENDIF
         IF ::Parent:MDIClient:AlignBottom == Self
            ::Parent:MDIClient:AlignBottom := ::Dock:Bottom
         ENDIF
         IF ::Parent:MDIClient:AlignRight == Self
            ::Parent:MDIClient:AlignRight := NIL
         ENDIF
      ENDIF

      IF ::LeftSplitter != NIL
         ::LeftSplitter:Destroy()
         ::LeftSplitter := NIL
      ENDIF
      IF ::TopSplitter != NIL
         ::TopSplitter:Destroy()
         ::TopSplitter := NIL
      ENDIF
      IF ::RightSplitter != NIL
         ::RightSplitter:Destroy()
         ::RightSplitter := NIL
      ENDIF
      IF ::BottomSplitter != NIL
         ::BottomSplitter:Destroy()
         ::BottomSplitter := NIL
      ENDIF

      pt := (struct POINT)
      pt:x := ::left
      pt:y := ::top

      ClientToScreen( ::Form:hWnd, @pt )

      ::__DockParent := WinForm( ::Form )
      ::__DockParent:Cargo      := Self
      ::__DockParent:Caption    := ::xText
      ::__DockParent:Left       := pt:x
      ::__DockParent:Top        := pt:y
      ::__DockParent:Width      := ::Width  + ( GetSystemMetrics( SM_CXFRAME ) + 2 )
      ::__DockParent:Height     := ::Height + ( GetSystemMetrics( SM_CYFRAME ) + 2 ) + GetSystemMetrics( SM_CYSMCAPTION )
      ::__DockParent:ToolWindow := .T.
      ::__DockParent:SysMenu    := ::AllowClose
      ::__DockParent:ThickFrame := .F.
      ::__DockParent:Create()
      SetParent( ::hWnd, ::__DockParent:hWnd )
      MoveWindow( ::hWnd, 0, 0, ::Width, ::Height )
      ::__DockParent:Show()
      ::__DockParent:OnWMClose   := {|| IIF( ::IsDocked, 0, ::Redock() ) }

      IF ! Empty( ::Parent:__aDock )
         hDef := BeginDeferWindowPos( LEN( ::Parent:__aDock ) )
         FOR EACH oChild IN ::Parent:__aDock
             IF oChild:hWnd != ::hWnd .AND. oChild:Dock != NIL .AND. ( oChild:Dock:Left   != NIL .OR.;
                                                                       oChild:Dock:Top    != NIL .OR.;
                                                                       oChild:Dock:Right  != NIL .OR.;
                                                                       oChild:Dock:Bottom != NIL )
                oChild:__OnParentSize( ::Parent:Width, ::Parent:Height,hDef )
             ENDIF
         NEXT
         EndDeferWindowPos( hDef )
      ENDIF
      ExecuteEvent( "OnUndock", Self )
   ENDIF
  
RETURN Self

//---------------------------------------------------------------------------------------------------

METHOD OnNCHitTest( x, y ) CLASS Control
   LOCAL nRes, aPt, hRegion, hdc, n
   IF !EMPTY(::CaptionRect) .AND. !EMPTY( ::xText ) .AND. ::xSmallCaption .AND. ::Super:OnNCHitTest( x, y ) == NIL
      aPt := { x, y }
      _ScreenToClient( ::hWnd, @aPt )
      aPt[2]+=::CaptionRect[4]
      IF ::ClsName == "DLGEDT"
         aPt[1] += ::RullerWeight
         aPt[2] += ::RullerWeight
      ENDIF

      n := 0
      IF !::IsChild
         n := 1
      ENDIF
      IF ::AllowClose
         // Check the close button
         IF _PtInRect( ::CloseRect, aPt )
            nRes := HTCLOSE
            ::CloseHover  := .T.
          ELSE
            ::CloseHover  := .F.
            IF ::ClosePushed
               nRes := HTCLOSE
            ENDIF
         ENDIF
         hRegion := CreateRectRgn( ::CloseRect[1], ::CloseRect[2], ::CloseRect[3], ::CloseRect[4] )
         hdc := GetDCEx( ::hWnd, hRegion, DCX_WINDOW + DCX_PARENTCLIP + DCX_CLIPSIBLINGS + DCX_VALIDATE )
         ::DrawClose( hDC, n )
         ReleaseDC(::hWnd, hdc)
         DeleteObject( hRegion )
      ENDIF
      IF ::AllowUnDock
         // Check the pin button
         IF _PtInRect( ::PinRect, aPt )
            nRes := HTBORDER
            ::PinHover  := .T.
          ELSE
            ::PinHover  := .F.
            IF ::PinPushed
               nRes := HTBORDER
            ENDIF
         ENDIF
         hRegion := CreateRectRgn( ::PinRect[1], ::PinRect[2], ::PinRect[3], ::PinRect[4] )
         hdc := GetDCEx( ::hWnd, hRegion, DCX_WINDOW + DCX_PARENTCLIP + DCX_CLIPSIBLINGS + DCX_VALIDATE )
         ::DrawPin( hDC, n )
         ReleaseDC(::hWnd, hdc)
         DeleteObject( hRegion )
      ENDIF
      IF ::MenuArrow
         IF _PtInRect( ::ArrowRect, aPt )
            nRes := HTMENU
         ENDIF
      ENDIF
      IF !::AllowUnDock .AND. !::AllowClose .AND. !::AllowMaximize .AND. nRes == NIL .AND. _PtInRect( ::CaptionRect, aPt )
         RETURN HTNOWHERE
      ENDIF
      
   ENDIF
RETURN nRes

//---------------------------------------------------------------------------------------------------

METHOD OnSysKeyDown( nwParam, nlParam ) CLASS Control
   LOCAL oCtrl, n
   IF nwParam != 18 .AND. LoWord( nlParam )== MOD_ALT .AND. ::Super:OnSysKeyDown( nwParam, nlParam ) == NIL

//       IF ( n := MapVirtualKey( nwParam, 2 ) ) != nwParam .AND. nwParam >= 96 .AND. nwParam <= 105
//          ::PostMessage( WM_SYSCHAR, n, nlParam )
//          SetWindowLong( ::hWnd, DWL_MSGRESULT, 0 )
//          RETURN 0
//       ENDIF
      FOR EACH oCtrl IN ::Parent:Children
          IF VALTYPE( oCtrl:Caption ) == "C" .AND. AT( "&"+UPPER( CHR( nwParam ) ), UPPER( oCtrl:Caption ) ) > 0
             RETURN NIL
          ENDIF
      NEXT
      IF ::Parent:Parent != NIL .AND. ::Parent:Parent:ClsName == "SysTabControl32"
         ::Parent:Parent:PostMessage( WM_SYSKEYDOWN, nwParam, nlParam )
       ELSE
         IF ( n:=ASCAN( ::Parent:Children, {|o|o:ClsName == "SysTabControl32" } ) ) > 0
            IF ! (::Parent:Children[n] == Self)
               ::Parent:Children[n]:PostMessage( WM_SYSKEYDOWN, nwParam, nlParam )
            ENDIF
         ENDIF
      ENDIF
   ENDIF
RETURN NIL

//---------------------------------------------------------------------------------------------------

METHOD DrawClose( hDC ) CLASS Control
   LOCAL hBrush, hOld
   LOCAL aRect  := ::CloseRect

   hOld := SelectObject( hDC, ::System:CurrentScheme:Pen:MenuItemBorder )
   IF ::CloseHover
      SelectObject( hDC, IIF( !::ClosePushed, ::System:CurrentScheme:Brush:ButtonCheckedGradientEnd, ::System:CurrentScheme:Brush:MenuItemSelected ) )
      Rectangle( hDC, aRect[1], aRect[2], aRect[3], aRect[4] )
    ELSE
      hBrush := CreateSolidBrush( GetSysColor( IIF( ( ::HasFocus .OR. ::KeepActiveCaption ) .AND. ::HighlightCaption, COLOR_ACTIVECAPTION, COLOR_INACTIVECAPTION ) ) )
      _FillRect( hDC, aRect, hBrush )
      DeleteObject( hBrush )
   ENDIF
   SelectObject( hDC, hOld )

   aRect[1]+=4
   aRect[2]+=4
   aRect[3]-=4
   aRect[4]-=4

   MoveTo( hDC, aRect[1],   aRect[2]   )
   LineTo( hDC, aRect[3]-1, aRect[4]   )
   MoveTo( hDC, aRect[1]+1, aRect[2]   )
   LineTo( hDC, aRect[3],   aRect[4]   )

   MoveTo( hDC, aRect[1],   aRect[4]-1 )
   LineTo( hDC, aRect[3]-1, aRect[2]-1 )
   MoveTo( hDC, aRect[1]+1, aRect[4]-1 )
   LineTo( hDC, aRect[3],   aRect[2]-1 )

   aRect[1]-=4
   aRect[2]-=4
   aRect[3]+=4
   aRect[4]+=4

RETURN Self

METHOD DrawArrow( hDC, aRect ) CLASS Control
   LOCAL nShadow, nColor, hPenShadow, hPenLight, hOldPen, z, i, n, x, y, nArrow := 1, nH := 5, nBackColor
   
   nBackColor := GetSysColor( IIF( ( ::HasFocus .OR. ::KeepActiveCaption ) .AND. ::HighlightCaption, COLOR_ACTIVECAPTION, COLOR_BTNFACE ) )

   nColor  := LightenColor( nBackColor, 100 )
   nShadow := DarkenColor( nBackColor, 100 )

   hPenShadow := CreatePen( PS_SOLID, 0, nShadow )
   hPenLight  := CreatePen( PS_SOLID, 0, nColor )

   hOldPen := SelectObject( hDC, hPenLight )
   z := 1
   FOR i := 1 TO 2
       FOR n := 1 TO nH
           x := IIF( nArrow == 1,n,nH-n+1)
           y := (aRect[4]-nH)/2

           MoveTo( hDC, aRect[3] - (15-x), y+n+z )
           LineTo( hDC, aRect[3] - ( 4+x), y+n+z )
       NEXT
       SelectObject( hDC, hPenShadow )
       z := 0
       aRect[3]--
   NEXT
   SelectObject( hDC, hOldPen )
   DeleteObject( hPenShadow )
   DeleteObject( hPenLight )
RETURN Self

METHOD DrawPin( hDC, n ) CLASS Control
   LOCAL hBrush, hOld, nLeft, nRight, nBottom
   LOCAL aRect  := ::PinRect

   hOld := SelectObject( hDC, ::System:CurrentScheme:Pen:MenuItemBorder )
   IF ::PinHover
      SelectObject( hDC, IIF( !::PinPushed, ::System:CurrentScheme:Brush:ButtonCheckedGradientEnd, ::System:CurrentScheme:Brush:MenuItemSelected ) )
      Rectangle( hDC, aRect[1], aRect[2], aRect[3], aRect[4] )
    ELSE
      hBrush := CreateSolidBrush( GetSysColor( IIF( ( ::HasFocus .OR. ::KeepActiveCaption ) .AND. ::HighlightCaption, COLOR_ACTIVECAPTION, COLOR_INACTIVECAPTION ) ) )
      _FillRect( hDC, aRect, hBrush )
      DeleteObject( hBrush )
   ENDIF
   SelectObject( hDC, hOld )
   
   aRect[1] += 4
   aRect[2] += (3-n)
   aRect[3] -= 4
   aRect[4] -= 4

   nLeft   := aRect[1] + ( (aRect[3]-aRect[1])/2 ) - 2
   nRight  := aRect[1] + ( (aRect[3]-aRect[1])/2 ) + 3
   nBottom := aRect[2] + ( (aRect[4]-aRect[2])/2 ) + 2

   Rectangle( hDC, nLeft, aRect[2], nRight, nBottom )
   MoveTo( hDC, nRight-2, aRect[2]+1 )
   LineTo( hDC, nRight-2, nBottom )

   MoveTo( hDC, nLeft-1, nBottom-1 )
   LineTo( hDC, nRight+1, nBottom-1 )

   MoveTo( hDC, nLeft+2, nBottom )
   LineTo( hDC, nLeft+2, aRect[4]+1 )
   aRect[1]-=4
   aRect[2]-=(3-n)
   aRect[3]+=4
   aRect[4]+=4

RETURN Self

METHOD GetBkBrush() CLASS Control
   LOCAL hDC, nColor, hBkGnd := ::__hBrush
   DEFAULT hBkGnd TO ::BkBrush
   DEFAULT hBkGnd TO ::Parent:BkBrush

   IF hBkGnd == NIL
      hDC := GetDC( ::Parent:hWnd )
      nColor := GetPixel( hDC, ::xLeft-1, ::xTop-1 )
      IF nColor > 0
         IF ::__hParBrush != NIL
            DeleteObject( ::__hParBrush )
         ENDIF
         ::__hParBrush := CreateSolidBrush( nColor )
         hBkGnd := ::__hParBrush
      ENDIF
      ReleaseDC( ::Parent:hWnd, hDC )
   ENDIF
RETURN hBkGnd

CLASS CommonControls INHERIT Control
   PROPERTY CCS_Adjustable    INDEX CCS_ADJUSTABLE    READ xCCS_Adjustable    WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_NoDevider     INDEX CCS_NODIVIDER     READ xCCS_NoDevider     WRITE SetProperty DEFAULT .F. PROTECTED

   PROPERTY CCS_Left          INDEX CCS_LEFT          READ xCCS_Left          WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_Top           INDEX CCS_TOP           READ xCCS_Top           WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_Right         INDEX CCS_RIGHT         READ xCCS_Right         WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_Bottom        INDEX CCS_BOTTOM        READ xCCS_Bottom        WRITE SetProperty DEFAULT .F. PROTECTED

   PROPERTY CCS_NoMoveX       INDEX CCS_NOMOVEX       READ xCCS_NoMoveX       WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_NoMoveY       INDEX CCS_NOMOVEY       READ xCCS_NoMoveY       WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_NoResize      INDEX CCS_NORESIZE      READ xCCS_NoResize      WRITE SetProperty DEFAULT .F. PROTECTED
   PROPERTY CCS_NoParentAlign INDEX CCS_NOPARENTALIGN READ xCCS_NoParentAlign WRITE SetProperty DEFAULT .F. PROTECTED

   PROPERTY CCS_Vert          INDEX CCS_VERT          READ xCCS_Vert          WRITE SetProperty DEFAULT .F. PROTECTED

   METHOD SetProperty( nProp, lSet ) INLINE  ::Style := IIF( lSet, ::Style | nProp, ::Style & NOT( nProp ) )

ENDCLASS

CLASS UserControl INHERIT Control
   METHOD Init() CONSTRUCTOR
ENDCLASS

METHOD Init( oParent ) CLASS UserControl
   DEFAULT ::__xCtrlName TO "UserControl"
   DEFAULT ::ClsName     TO "UserControl"
   ::Style        := WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
   DEFAULT ::xLeft   TO 0
   DEFAULT ::xTop    TO 0
   DEFAULT ::xWidth  TO 200
   DEFAULT ::xHeight TO 200
   ::Super:Init( oParent )
   ::__IsStandard := .F.
RETURN Self

