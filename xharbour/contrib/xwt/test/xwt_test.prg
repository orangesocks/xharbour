#include "xwt.ch"

GLOBAL oFileSel
GLOBAL oOtherBox

#xcommand ? <data,...> => OutStd( <data>, HB_OSNewLine() )

PROCEDURE MAIN()
   LOCAL oWindow, oButton, oMenuItem, oMenu, oMenuHelp
   LOCAL oMenuSec, oTextbox, oLabel, oViewPort, oPane
   LOCAL oImg, oHlay, oVLay, oVlay2, oFrame, oSplit
   LOCAL oGrid, obtnStatus
   LOCAL oList, oCheck

   XwtInit()

   /*** Window creation ****/
   oWindow:= XwtFrameWindow():New("Hola Mundo. Thefull desde Linux")
   oWindow:AddEventListener( XWT_E_DESTROY_REQ, @XwtQuit() )

   /*** Splitter panes layout( our new main widget) ***/
   DEFINE LAYOUT oVLay  MODE XWT_LM_VERT PADDING 5 BORDER 2
   DEFINE LAYOUT oVLay2 MODE XWT_LM_VERT PADDING 5 BORDER 2

   /* oVLay := XwtLayout():New( XWT_LM_VERT )
   oVLay:SetPadding( 5 )
   oVLay:SetBorder( 2 )

   oVLay2 := XwtLayout():New( XWT_LM_VERT )
   oVLay2:SetPadding( 5 )
   oVLay2:SetBorder( 2 )
   */

   oSplit := XwtSplitter():New( XWT_LM_HORIZ, oVLay, oVLay2 )
   oSplit:SetShrinkFirst( .F. )

   oWindow:Add( oSplit )

   // inside an horiz. layout
   DEFINE LAYOUT oHLay  MODE XWT_LM_HORIZ

   /*** Text And Button ***/
   DEFINE LABEL oLabel TEXT "Text: " OF oHlay

   oHLay:SetFill( .T. )
   oHLay:SetExpand( .T. )

   DEFINE BUTTON oButton TEXT "Hello" OF oHLay
   oButton:AddListener( @DumpEvent() )

   oHLay:SetBox( .T.,"Horiz Box" )

   oVlay:Add( oHLay )

   /* A couple of Textboxes in a pane, inside a scrollable */
   DEFINE PANE oPane BOX TITLE "A Fixed Pane" OF oVLay

   @ 10,10 TEXTBOX oTextBox VAR "A Text" OF oPane
   oTextbox:AddEventListener(XWT_E_UPDATED, @BoxModified())

   @ 10,40  TEXTBOX oOtherBox VAR "Another box" OF oPane
   @ 10,75  CHECKBOX        TEXT "CkBox 1" VAR .T. OF oPane
   @ 110,75 CHECKBOX oCheck TEXT "CkBox 2" VAR .F. OF oPane
   @ 010,105 TOGGLEBUTTON   TEXT "Button Toggle 1" VAR .T. OF oPane
   @ 120,105 TOGGLEBUTTON   TEXT "Button Toggle 2" VAR .F. OF oPane

   // add a button to query the status.
   @10,135 BUTTON oButton TEXT "Click to Query pane status"  OF oPane
   oButton:AddEventListener( XWT_E_CLICKED, @PaneStatus() )


   /* A beautiful GRID */

   oGrid := XwtGrid():New(2,3)

   oLabel := XwtLabel():New("Field label")

   oGrid:setPadding( 2, 10 )
   oGrid:SetFill( .T. )

   oGrid:Attach( oLabel, 1, 2 )
   oGrid:Attach( XwtLabel():New("Field 2"), 2, 2 )

   oGrid:SetExpand( .T. )
   oGrid:Attach( XwtTextBox():New("Data 1"), 1, 3 )
   oGrid:Attach( XwtTextBox():New("Data 2"), 2, 3 )

   oGrid:SetBox( .T.,"A Grid " )

   oVLay2:Add( oGrid )

   /*** IMAGE ***/
   oImg := XwtImage():New( "icon.png" )
   oImg:SetSensible()
   oVLay2:add( oImg )

   /*** An input mask ***/
   aInputs := {;
      { "Variable 1", "Default value"}, ;
      { "Variable 2", "Default value 2"}, ;
      { "Variable 3", "Default value 3"} ;
   }
   oInput := XWTInputMask():New( aInputs )
   oInput:AddEventListener( XWT_E_CHANGED, @InputChanged() )

   oFrame := XwtLayout():New( XWT_LM_VERT )
   oViewPort := XwtViewPort():new(75, 50)
   oFrame:add( oViewPort )
   oViewPort:SetContent( oInput )
   oFrame:SetBox( .T., "Inside a scrollable..." )
   oVLay2:Add( oFrame )


   /***  Radio buttons ***/
   oRadioPanel := XWTLayout():New( XWT_LM_VERT )
   oRadioPanel:add( XWTRadioButton():New( "Option 1" ) )
   oRadioPanel:add( XWTRadioButton():New( "Option 2" ) )
   oRadioPanel:add( XWTRadioButton():New( "Option 3" ) )

   oVLay2:Add( oRadioPanel )
   /***** A list **********/
   oList := XWTTreeList():New(;
         { {"uno", 2, 3.12, "fir"}, ;
           {"dos",3,4,5} },;  //the table
         { "C1", "C2", "C3", "C4" } ; // the titles
         )
   oList:SetColumnEditable( 0 )
   oVLay:Add( oList )
   /***** MENU design *****/
   oMenu := XwtMenu():New( "File" )

   oMenuItem := XwtMenuItem():New( "Op_en", 1 , @FileEvent())
   oMenuItem:SetIcon( "valley.png" )

   oMenu:Add( oMenuItem )
   oMenu:Add( XwtMenuItem():New( "Close", 2 , @FileEvent()))
   oMenu:Add( XwtMenuItem():New( "QUIT", 3 , @FileEvent()))

   oMenuSec := XwtMenu():New( "Submenu" )
   oMenuSec:Add( XwtMenuItem():New( "Opt1", 10 , @FileEvent()))
   oMenuSec:Add( XwtMenuItem():New( "Opt2", 11 , @FileEvent()))
   oMenu:Add( oMenuSec )

   oMenuHelp := XwtMenu():New( "Help" )
   oMenuHelp:Add( XwtMenuItem():New( "About", 5 , @FileEvent()) )
   oMenuHelp:Add( XwtMenuItem():New( "Help", 6 , @FileEvent()) )

   oWindow:SetMenuBar( { oMenu, oMenuHelp } )
   /*** Showing window ***/
   oWindow:Resize( 200, 200 )
   oWindow:Show()
   oWindow:AddListener( @WindowReceive() )

   /*** Main LOOP ***/
   XwtMainLoop()

   /*** Going to terminate */
   //oButton:Destroy()  // the button might or might not be deteached from window
   oWindow:Destroy()

RETURN 



FUNCTION WindowReceive( oEvent )
?  "Received event at top level ", oEvent:nType, " from ", oEvent:oSender:GetText()
RETURN .F.

FUNCTION DumpEvent( oEvent )
?  "Event type: ", oEvent:nType, " from ", oEvent:oSender:GetText()
?   Len ( oEvent:aParams )
   IF Len ( oEvent:aParams ) == 1
?  "Parameter ", oEvent:aParams[1]
   ELSE
      IF Len( oEvent:aParams ) == 2
?  "Parameters ", oEvent:aParams[1], " ", oEvent:aParams[2]
      ENDIF
   ENDIF
   IF oEvent:nType == XWT_E_CLICKED
      IF XWT_MsgBox( "Are you really, really, sure?", ;
         XWT_MSGBOX_YES + XWT_MSGBOX_NO, XWT_MSGBOX_QUESTION) == XWT_MSGBOX_YES
            oEvent:oSender:Hide()
      ENDIF
   ENDIF
RETURN .F.

FUNCTION FileEvent( oEvent )
   //Filesel can't be local!
   //Local oFileSel

?  "Menu activated: ", oEvent:oSender:nId
   IF oEvent:oSender:nId == 1
      oFileSel := XWTFileSel():New( "Open file" )
      oFileSel:SetFile( "test.file" )

      // Notice: after a "do_modal", the object will not exist anymore
      cFileName := oFileSel:DoModal()
      IF cFileName == ""
?  "Canceled!"
      ELSE
?  "FILENAME: ", cFileName
      ENDIF
   ENDIF
RETURN .F.

FUNCTION BoxModified( oEvent )
?  "Text entered in box: ", oEvent:oSender:getText()
   oEvent:oSender:SetText( "Reset" )
   oOtherBox:SetFocus()
RETURN .F.


FUNCTION InputChanged( oEvent )
   Local aField
?  "Input has been set:"

   FOR EACH aField IN oEvent:oSender:aInputFields
?  aField[1], ": ", aField[2]
   NEXT

?  ""
RETURN .F.


FUNCTION PaneStatus( oEvent )
   LOCAL oObj

   ? "Clicked QUERY PANE STATUS Button"
   FOR EACH oObj in oEvent:oSender:oOwner:aChildren
      IF oObj:GetType() == XWT_TYPE_CHECKBOX .or. oObj:GetType() == XWT_TYPE_TOGGLEBUTTON
         ? oObj:GetText(), IIF( oObj:GetStatus(), "(Active)", "(NOT Active)" )
      ELSE
         ? oObj:GetText()
      ENDIF
   NEXT
   ? ""
RETURN .T.
