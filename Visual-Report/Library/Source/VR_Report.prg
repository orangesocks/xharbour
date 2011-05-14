/*
 * $Id$
 */

//-----------------------------------------------------------------------------------------------
// Copyright   WinFakt! / SOCS BVBA  http://www.WinFakt.com
//
// This source file is an intellectual property of SOCS bvba.
// You may NOT forward or share this file under any conditions!
//-----------------------------------------------------------------------------------------------

#include "debug.ch"
#include "vxh.ch"

//-----------------------------------------------------------------------------------------------
#define PIX_PER_INCH   1440

#define  acFileSaveDefault     -1
#define  acFileSaveAll          0
#define  acFileSaveView         1
#define  acFileSaveDesign       2

#define  acScaleVertical        2
#define  acCommandToolZoomIn           53541
#define  acCommandToolZoomOut          53542
#define  acCommandToolPageHome         53773

CLASS VrReport INHERIT VrObject
   DATA PrintHeader    EXPORTED  INIT .T.
   DATA PrintRepHeader EXPORTED  INIT .T.
   DATA PrintFooter    EXPORTED  INIT .T.
   DATA PrintRepFooter EXPORTED  INIT .T.

   DATA ClsName        EXPORTED  INIT "Report"
   DATA Name           EXPORTED  INIT "Report"

   DATA nImage         EXPORTED  INIT 0
   DATA nText          EXPORTED  INIT 0
   DATA nLine          EXPORTED  INIT 0
   DATA nBox           EXPORTED  INIT 0
   
   DATA FileName       EXPORTED  INIT "Preview"
   DATA Orientation    EXPORTED
   DATA PaperSize      EXPORTED  INIT DMPAPER_LETTER
   
   DATA LeftMargin     EXPORTED  INIT 1000
   DATA TopMargin      EXPORTED  INIT 1000
   DATA RightMargin    EXPORTED  INIT 1000
   DATA BottomMargin   EXPORTED  INIT 1000
   
   DATA oPDF           EXPORTED
   DATA PreviewCaption EXPORTED  INIT "Visual Report - Print Preview"
   DATA nPage          EXPORTED  INIT 0
   DATA nRow           EXPORTED  INIT 0
   DATA DataSource     EXPORTED
   DATA Button         EXPORTED
   DATA lUI            EXPORTED  INIT .F.

   DATA HeaderHeight   EXPORTED  INIT 0
   DATA FooterHeight   EXPORTED  INIT 0

   DATA aHeader        EXPORTED  INIT {}
   DATA aBody          EXPORTED  INIT {}
   DATA aFooter        EXPORTED  INIT {}
   DATA aExtraPage     EXPORTED  INIT {}
   
   DATA hData          EXPORTED
   DATA hProps         EXPORTED
   DATA hExtra         EXPORTED
   
   DATA aSubtotals     EXPORTED  INIT {}
   DATA aTotals        EXPORTED  INIT {}
   DATA aFormulas      EXPORTED  INIT {}

   ACCESS Application  INLINE __GetApplication()

   METHOD Init()       CONSTRUCTOR
   METHOD Create()
   METHOD Preview()
   METHOD End()
   METHOD StartPage()
   METHOD EndPage()
   METHOD Run()
   METHOD CreateControl()
   METHOD CreateColumns()
   METHOD CreateHeader()
   METHOD CreateFooter()
   METHOD CreateExtraPage()
   METHOD CreateSubtotals()
   METHOD PrepareArrays()
   METHOD Load()
   METHOD InitPDF()
   METHOD Save() INLINE ::oPDF:Save( ::FileName + ".pdf", acFileSaveView )
   METHOD GetSubtotalHeight()
   METHOD GetTotalHeight()
ENDCLASS

//-----------------------------------------------------------------------------------------------
METHOD Init() CLASS VrReport
   ::aProperties := {}
   ::Orientation := __GetSystem():PageSetup:Portrait
   AADD( ::aProperties, { "Name",           "Object" } )
   AADD( ::aProperties, { "DataSource",     "Data"   } )
   AADD( ::aProperties, { "PrintHeader",    "Print"  } )
   AADD( ::aProperties, { "PrintRepHeader", "Print"  } )
   AADD( ::aProperties, { "PrintFooter",    "Print"  } )
   AADD( ::aProperties, { "PrintRepFooter", "Print"  } )

   ::InitPDF()
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD InitPDF() CLASS VrReport
   IF ::oPDF == NIL
      ::oPDF := ActiveX( ::Application:MainForm )
      ::oPDF:SetChildren := .F.

      ::oPDF:ProgID := "PDFCreactiveX.PDFCreactiveX"
      ::oPDF:Width  := 0
      ::oPDF:Height := 0
      ::oPDF:Create()

      IF ::oPDF == NIL
         MessageBox( 0, "Error loading report generator" )
         RETURN NIL
      ENDIF

      ::oPDF:SetLicenseKey( "WinFakt", "07EFCDAB010001008C5BD0102426F725C273B3A7C1B30B61521A8890359D83AE6FD68732DDAE4AC7E85003CDB8ED4F70678BF1EDF05F" )
      ::oPDF:ObjectAttributeSTR( "Document", "UseSystemFonts", "1" )
      ::oPDF:ObjectAttributeSTR( "Document", "UnicodeFonts"  , "0" )
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD Create() CLASS VrReport
   ::InitPDF()
   ::nPage := 0
   FERASE( GetTempPath() + "\vr.tmp" )
   ::oPDF:StartSave( GetTempPath() + "\vr.tmp", acFileSaveView )
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD End() CLASS VrReport
   ::oPDF:EndSave()
RETURN NIL

//-----------------------------------------------------------------------------------------------
METHOD StartPage() CLASS VrReport
   ::nRow := 0
   IF ::nPage > 0
      ::oPDF:AddPage( ::nPage )
   ENDIF
   ::nPage++
   ::oPDF:ObjectAttribute( "Pages["+ALLTRIM(STR(::nPage))+"]", "PaperSize", ::PaperSize )
   ::oPDF:ObjectAttribute( "Pages["+ALLTRIM(STR(::nPage))+"]", "Landscape", ::Orientation == __GetSystem():PageSetup:Landscape )
RETURN NIL

//-----------------------------------------------------------------------------------------------
METHOD EndPage() CLASS VrReport
   ::oPDF:SavePage( ::oPDF:CurrentPage )
   ::oPDF:ClearPage( ::oPDF:CurrentPage )
RETURN NIL

//-----------------------------------------------------------------------------------------------
METHOD Preview() CLASS VrReport
   LOCAL oPv := VrPreview( Self )
   oPv:Create()
   ::oPDF:Destroy()
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD CreateControl( hCtrl, nHeight, oPanel, hDC, nVal ) CLASS VrReport
   LOCAL aCtrl, oControl, x := 0, y := 0, n, cProp, xValue, xVar

   x := VAL( hCtrl:Left )
   y := VAL( hCtrl:Top )

   IF oPanel == NIL
      oControl := hb_ExecFromArray( hCtrl:ClsName, {,.F.} )
      oControl:Parent := Self
      oControl:Left := x
      oControl:Top  := y

      FOR EACH cProp IN hCtrl:Keys
          IF UPPER( cProp ) != "FONT"
             xVar := __objSendMsg( oControl, cProp )
             xValue := hCtrl[ cProp ]
             IF VALTYPE( xVar ) != VALTYPE( xValue )
                DO CASE
                   CASE VALTYPE( xVar ) == "N"
                        xValue := VAL( xValue )

                   CASE VALTYPE( xVar ) == "D"
                        xValue := DTOC( xValue )

                   CASE VALTYPE( xVar ) == "L"
                        xValue := xValue == "True"
                ENDCASE
             ENDIF
             __objSendMsg( oControl, "_" + cProp, xValue )
          ENDIF
      NEXT

    ELSE
      oControl := oPanel:CreateControl( hCtrl, x, y )
   ENDIF
   IF HGetPos( hCtrl, "Font" ) > 0 
      DEFAULT oControl:Font TO Font()
      oControl:Font:FaceName  := hCtrl:Font:FaceName
      oControl:Font:PointSize := VAL( hCtrl:Font:PointSize )
      oControl:Font:Italic    := hCtrl:Font:Italic == "True"
      oControl:Font:Underline := hCtrl:Font:Underline == "True"
      oControl:Font:Weight    := VAL( hCtrl:Font:Weight )
   ENDIF
   IF ! Empty( nVal )
      oControl:Caption := ALLTRIM( STR( nVal ) )
   ENDIF

   IF oPanel == NIL
      oControl:Draw( hDC )
      TRY
         IF oControl:ClsName != "Image" .OR. ! oControl:OnePerPage
            nHeight := MAX( oControl:PDFCtrl:Attribute( 'Bottom' )-oControl:PDFCtrl:Attribute( 'Top' ), nHeight )
         ENDIF
      CATCH
      END
    ELSE
      oControl:Configure()
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD GetTotalHeight( hDC ) CLASS VrReport
RETURN 0

//-----------------------------------------------------------------------------------------------
METHOD GetSubtotalHeight( hDC ) CLASS VrReport
RETURN 0

//-----------------------------------------------------------------------------------------------
METHOD CreateSubtotals( hDC ) CLASS VrReport
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD CreateColumns( hDC ) CLASS VrReport
   LOCAL hCtrl, nHeight := 0
   FOR EACH hCtrl IN ::aBody
       IF ( UPPER( hCtrl:ClsName ) IN { "VRLABEL", "VRIMAGE" } )
          ::CreateControl( hCtrl, @nHeight,, hDC )
       ENDIF
   NEXT
   ::nRow += nHeight
RETURN nHeight

//-----------------------------------------------------------------------------------------------
METHOD CreateHeader( hDC ) CLASS VrReport
   LOCAL aCtrl, nHeight := 0
   IF ::PrintHeader
      FOR EACH aCtrl IN ::aHeader
          ::CreateControl( aCtrl, @nHeight,, hDC )
      NEXT
      ::nRow := ::HeaderHeight
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD CreateFooter( hDC ) CLASS VrReport
   LOCAL aCtrl, nHeight := 0
   IF ::PrintFooter
      ::nRow := ::oPDF:PageLength - ::FooterHeight
      FOR EACH aCtrl IN ::aFooter
          ::CreateControl( aCtrl, @nHeight,, hDC )
      NEXT
   ENDIF
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD CreateExtraPage( hDC ) CLASS VrReport
   LOCAL aCtrl, nHeight := 0
   ::nRow := 0
   FOR EACH aCtrl IN ::aExtraPage
       ::CreateControl( aCtrl, @nHeight,, hDC )
   NEXT
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD PrepareArrays( oDoc ) CLASS VrReport
   LOCAL oPrev, oNode, cData, n, aControl, cParent, hDC, hControl

   ::hData  := {=>}
   ::hProps := {=>}
   ::hExtra := {=>}
   HSetCaseMatch( ::hData, .F. )
   HSetCaseMatch( ::hProps, .F. )
   HSetCaseMatch( ::hExtra, .F. )

   oNode := oDoc:FindFirstRegEx( "Report" )

   WHILE oNode != NIL
      DO CASE
         CASE oNode:oParent:cName == "DataSource" .AND. oNode:oParent:oParent:cName == "Report"
              DEFAULT oNode:cData TO ""
              ::hData[ oNode:cName ] := oNode:cData

         CASE oNode:oParent:cName == "Properties" .AND. oNode:oParent:oParent:cName == "Report"
              DEFAULT oNode:cData TO ""
              ::hProps[ oNode:cName ] := oNode:cData

         CASE oNode:oParent:cName == "ExtraPage" .AND. oNode:oParent:oParent:cName == "Report" .AND. oNode:cName != "Control"
              DEFAULT oNode:cData TO ""
              ::hExtra[ oNode:cName ] := oNode:cData

         CASE oNode:cName == "Control" 
              IF !EMPTY( hControl )
                 AADD( ::&cParent, hControl )
              ENDIF
              cParent := "a" + oNode:oParent:cName
              hControl := {=>}
              HSetCaseMatch( hControl, .F. )

         CASE oNode:cName == "Font" 
              hControl[ oNode:cName ] := {=>}
              HSetCaseMatch( hControl[ oNode:cName ], .F. )

         CASE oNode:oParent:cName == "Control"
              DEFAULT oNode:cData TO ""
              hControl[ oNode:cName ] := oNode:cData
              
         CASE oNode:oParent:cName == "Font"
              DEFAULT oNode:cData TO ""
              hControl[ oNode:oParent:cName ][ oNode:cName ] := oNode:cData

      ENDCASE
      oNode := oDoc:Next()
   ENDDO
   IF !EMPTY( aControl )
      AADD( ::&cParent, aControl )
   ENDIF
   n := ::Application:Props[ "Header" ]:Height - ::Application:Props[ "Header" ]:ClientHeight
        ::Application:Props[ "Header" ]:Height := VAL( ::hProps:HeaderHeight )+n
   n := ::Application:Props[ "Footer" ]:Height - ::Application:Props[ "Footer" ]:ClientHeight
        ::Application:Props[ "Footer" ]:Height := VAL( ::hProps:FooterHeight )+n
        ::Application:Props[ "Footer" ]:Dockit()
        ::Application:Props[ "Body" ]:Dockit()
   TRY
      ::Orientation  := VAL( ::hProps:Orientation )
   CATCH
   END
   TRY
      ::PaperSize   := VAL( ::hProps:PaperSize )

      ::LeftMargin  := VAL( ::hProps:LeftMargin )
      ::TopMargin   := VAL( ::hProps:TopMargin )
      ::RightMargin := VAL( ::hProps:RightMargin )
      ::BottomMargin:= VAL( ::hProps:BottomMargin )
   CATCH
   END

   hDC := GetDC(0)
   ::HeaderHeight := VAL( ::hProps:HeaderHeight ) * PIX_PER_INCH / GetDeviceCaps( hDC, LOGPIXELSY )
   ::FooterHeight := VAL( ::hProps:FooterHeight ) * PIX_PER_INCH / GetDeviceCaps( hDC, LOGPIXELSY )
   ReleaseDC(0, hDC)
RETURN Self

//-----------------------------------------------------------------------------------------------
METHOD Load( cReport ) CLASS VrReport
   LOCAL hCtrl, oDoc := TXmlDocument():New( cReport )

   ::PrepareArrays( oDoc )
   
   IF !EMPTY( ::hData ) .AND. !EMPTY( ::hData:FileName )
      WITH OBJECT ::DataSource := ::Application:Props:Body:CreateControl( ::hData )
         :FileName := ::hData:FileName
         :Alias    := ::hData:Alias
         :bFilter  := ::hData:bFilter
      END
      ::Application:Props:PropEditor:ResetProperties( {{ ::DataSource }} )
   ENDIF
   ::PrintHeader    := ::hProps:PrintHeader    == "1"
   ::PrintRepHeader := ::hProps:PrintRepHeader == "1"
   ::PrintFooter    := ::hProps:PrintFooter    == "1"
   ::PrintRepFooter := ::hProps:PrintRepFooter == "1"

   FOR EACH hCtrl IN ::aHeader
       ::CreateControl( hCtrl,, ::Application:Props:Header )
   NEXT
   FOR EACH hCtrl IN ::aBody
       ::CreateControl( hCtrl,, ::Application:Props:Body )
   NEXT
   FOR EACH hCtrl IN ::aFooter
       ::CreateControl( hCtrl,, ::Application:Props:Footer )
   NEXT
   TRY
      ::Application:Props:ExtraPage:PagePosition := VAL( ::hExtra:PagePosition )
   CATCH
   END
   FOR EACH hCtrl IN ::aExtraPage
       ::CreateControl( hCtrl,, ::Application:Props:ExtraPage )
   NEXT
RETURN oDoc

//-----------------------------------------------------------------------------------------------
METHOD Run( oDoc, oWait ) CLASS VrReport
   LOCAL nHeight, hDC, nSubHeight, nTotHeight, nCount, nPer, nPos, nRow

   ::Create()

   IF oDoc != NIL
      ::PrepareArrays( oDoc )
   ENDIF

   ::PrintHeader    := ::hProps:PrintHeader    == "1"
   ::PrintRepHeader := ::hProps:PrintRepHeader == "1"
   ::PrintFooter    := ::hProps:PrintFooter    == "1"
   ::PrintRepFooter := ::hProps:PrintRepFooter == "1"

   ::StartPage()
   hDC := GetDC(0)

   IF ::Application:Props:ExtraPage:PagePosition != NIL .AND. ::Application:Props:ExtraPage:PagePosition == -1
      ::CreateExtraPage( hDC )
      ::EndPage()
      ::StartPage()
   ENDIF
   
   IF !EMPTY( ::hData ) .AND. !EMPTY( ::hData:FileName )
      ::DataSource := hb_ExecFromArray( ::hData:ClsName )
      ::DataSource:FileName := ::hData:FileName
      ::DataSource:Alias    := ::hData:Alias
      ::DataSource:bFilter  := ::hData:bFilter
      ::DataSource:Create()
      nCount := ::DataSource:EditCtrl:RecCount()
   ENDIF

   ::CreateHeader( hDC )

//-----------------------------------------------------------------------
// Now start printing Labels
/*
   IF ::DataSource != NIL .AND. ! EMPTY( ::DataSource:FileName )
      ::DataSource:EditCtrl:Select()
      ::DataSource:EditCtrl:GoTop()
      AEVAL( ::aSubtotals, {|a| a[2] := 0} )
      AEVAL( ::aTotals,    {|a| a[2] := 0} )
      
      nSubHeight := ::GetSubtotalHeight( hDC )
      nTotHeight := ::GetTotalHeight( hDC )
      nPos := 0
      WHILE ! ::DataSource:EditCtrl:Eof()
         nHeight := ::CreateColumns( hDC )
         IF ::nRow + nHeight + IIF( ::PrintFooter, ::FooterHeight, 0 ) + nSubHeight > ::oPDF:PageLength
            ::CreateSubtotals( hDC )
            IF ::Application:Props:ExtraPage:PagePosition != NIL .AND. ::Application:Props:ExtraPage:PagePosition == 0
               ::CreateExtraPage( hDC )
            ENDIF
            ::CreateFooter( hDC )
            ::EndPage()
            ::StartPage()
            ::CreateHeader( hDC )
         ENDIF
         oWait:Position := Int( (nPos/nCount)*100 )
         nPos ++
         ::DataSource:EditCtrl:Skip()
      ENDDO
      ::CreateSubtotals( hDC )
      IF ::nRow >= ( ::oPDF:PageLength - IIF( ::PrintFooter, ::FooterHeight, 0 ) - nHeight - nTotHeight )
         ::CreateFooter( hDC )
         ::EndPage()
         ::StartPage()
         ::CreateHeader( hDC )
      ENDIF
      //::CreateTotals( hDC )
    ELSE
      ::CreateColumns( hDC )
   ENDIF
*/
   ::CreateFooter( hDC )
   IF ::Application:Props:ExtraPage:PagePosition != NIL .AND. ::Application:Props:ExtraPage:PagePosition == 0
      ::CreateExtraPage( hDC )
   ENDIF

   ReleaseDC(0, hDC)

   ::EndPage()
   ::End()
   hb_gcall(.t.)
   IF ::DataSource != NIL .AND. ! EMPTY( ::DataSource:FileName )
      IF ::DataSource:EditCtrl:IsOpen
         ::DataSource:EditCtrl:Close()
      ENDIF
   ENDIF
RETURN Self

FUNCTION S2R( hDC, cSize ); RETURN VAL(cSize)*PIX_PER_INCH/GetDeviceCaps( hDC, LOGPIXELSY )
//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------

CLASS VrPreview INHERIT Dialog
   DATA Report EXPORTED
   DATA oPDF   EXPORTED
   METHOD Init() CONSTRUCTOR
   METHOD OnInitDialog()
ENDCLASS

//------------------------------------------------------------------------------------------

METHOD Init( oReport ) CLASS VrPreview
   ::Report := oReport
   ::Super:Init( __GetApplication():MainForm )
   ::Modal      := .T.
   ::Top        := 300
   ::Width      := 800
   ::Height     := 900
//   ::Style      := WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
   ::DlgModalFrame := .T.
RETURN Self

//------------------------------------------------------------------------------------------

METHOD OnInitDialog() CLASS VrPreview
   LOCAL oItem, oSub, nZoom
   ::Caption := ::Report:PreviewCaption

   WITH OBJECT ToolStrip( Self )
      :ShowChevron := .F.
      :ShowGrip    := .F.
      :ImageList   := ImageList( :this, 32, 32 ):Create()
      :Height      := 38
      :ImageList:AddImage( "ICO_ZOOMIN" )
      :ImageList:AddImage( "ICO_ZOOMOUT" )
      :ImageList:AddImage( "ICO_PRINT" )
      :Create()
      WITH OBJECT ToolStripButton( :this )
         :Caption           := "Zoom-In"
         :ImageIndex        := 1
         :Action            := {|o| ::Report:oPDF:DoCommandTool( acCommandToolZoomIn )}
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :Caption           := "Zoom-Out"
         :ImageIndex        := 2
         :Action            := {|o| ::Report:oPDF:DoCommandTool( acCommandToolZoomOut )}
         :Create()
      END
      WITH OBJECT ToolStripButton( :this )
         :Caption           := "Print"
         :Begingroup        := .T.
         :ImageIndex        := 3
         :Action            := <|o| 
                                TRY
                                  ::Report:oPDF:Print( "", .T. )
                                CATCH
                                END
                                >
         :Create()
      END
   END
   
   WITH OBJECT StatusBar( Self )
      StatusBarPanel( ::StatusBar1, , 120 )
      StatusBarPanel( ::StatusBar1, ,  -1 )
      StatusBarPanel( ::StatusBar1, , 250 )
      :Create()
      :DockIt()
   END

   WITH OBJECT ::Report:oPDF
      :SetParent( Self )
      :Dock:Left   := Self
      :Dock:Top    := ::ToolStrip1
      :Dock:Right  := Self
      :Dock:Bottom := ::StatusBar1
      :DockIt()
      :Width       := 300
      :Height      := 300
      :RulerSize   := 0
      :MinimumGap  := 5
      :DoCommandTool( acCommandToolPageHome )
      nZoom        := ::Application:IniFile:Read( "Preview", "ZoomFactor", 0 )
      IF nZoom > 0
         :ZoomFactor := nZoom
       ELSE
         :ScaleToWindow( acScaleVertical )
      ENDIF
      :Show()
   END

   ::CenterWindow( .T. )
RETURN Self

