/*
 * $Id$
 */

#include "vxh.ch"
#include "debug.ch"
#define FILTERCTRLPERLINE      10

//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------

CLASS FilterUI INHERIT Dialog
   DATA cFilter    EXPORTED INIT ""
   DATA aFilter    EXPORTED INIT {}
   DATA oDataTable EXPORTED
   DATA aCond_C    EXPORTED INIT {}
   DATA aCond_N    EXPORTED INIT {}
   DATA aCond_D    EXPORTED INIT {}
   DATA aCond_L    EXPORTED INIT {}
   DATA aCondVal   EXPORTED INIT {}
   METHOD Init() CONSTRUCTOR
   METHOD OnInitDialog()

   METHOD ConditionComboBox_OnCBNSelEndOk()
   METHOD FieldComboBox_OnCBNSelEndOk()
   METHOD RemoveConditionButton_OnClick()
   METHOD AddConditionButton_OnClick()
   METHOD MoreConditionButton_OnClick()
   METHOD FilterBrowse_OnClick()
   METHOD LoadFieldList()
   METHOD AddButtons()
   METHOD BuildFilterExp()
   METHOD OK_OnClick()
   METHOD Cancel_OnClick()
ENDCLASS

//------------------------------------------------------------------------------------------

METHOD Init( oDataTable ) CLASS FilterUI
   LOCAL lProp
   IF EMPTY( oDataTable:Alias )
      ::Application:MainForm:MessageBox( "The Alias property cannot be empty", "DataTable" )
      RETURN NIL
   ENDIF
   ::oDataTable  := oDataTable
   DEFAULT ::__xCtrlName  TO "FilterUI"

   ::Super:Init( ::Application:MainForm )

   ::aCond_C := { "Contains",;
                   "Does not contain",;
                   "begins with",;
                   "Does not begin with",;
                   "Is empty",;
                   "Is not empty",;
                   "Is in the range" }

   ::aCond_N := {  "Equals to",;
                   "Is not equal to",;
                   "greater than or equal",;
                   "less than or equal",;
                   "between",;
                   "is in the range" }

   ::aCond_D := {  "Equals",;
                   "Is not equal",;
                   "Is greater or the same as",;
                   "Is lesser or teh same as",;
                   "Between",;
                   "per quarter",;
                   "is in the last",;
                   "is not in the last",;
                   "is in the range" }

   ::aCond_L := {  "True",;
                   "False" }

   ::Modal      := .T.
   ::Create()
RETURN Self

//------------------------------------------------------------------------------------------

METHOD OnInitDialog() CLASS FilterUI

   ::Left    := 190
   ::Top     := 20
   ::Width   := 634
   ::Height  := 375
   ::Caption := "Create Filter Expression"
   WITH OBJECT ( GROUPBOX( Self ) )
      WITH OBJECT :Dock
         :Left                 := Self
         :Top                  := Self
         :Right                := Self
         :Margins              := "20,15,20,0"
      END
      :Left                 := 20
      :Top                  := 15
      :Width                := 590
      :Height               := 62
      :Caption              := "Setting"
      :ForeColor            := 0
      :Create()
      WITH OBJECT ( RADIOBUTTON( :this ) )
         :Name                 := "ANDRadioButton"
         :Left                 := 24
         :Top                  := 27
         :Width                := 289
         :Height               := 15
         :Caption              := "Match ALL of the conditions"
         :InitialState         := 1
         :Create()
      END //RADIOBUTTON

      WITH OBJECT ( RADIOBUTTON( :this ) )
         :Name                 := "ORRadioButton"
         :Left                 := 325
         :Top                  := 27
         :Width                := 259
         :Height               := 15
         :Caption              := "Match ANY of the conditions"
         :Create()
      END
   END

   WITH OBJECT ( GROUPBOX( Self ) )
      :Name                 := "ConditionGroupBox"
      :Dock:Margins         := "20,86,20,40"
      :Left                 := 20
      :Top                  := 86
      :Width                := 590
      :Height               := 224
      :Caption              := "Conditions"
      :ForeColor            := 0
      :Create()
      :DockToParent()
      WITH OBJECT ( PANEL( :this ) )
         :Name                 := "ConditionPanel"
         :Dock:Margins         := "2,14,2,2"
         :VertScroll           := .T.
         :Create()
         :DockToParent()
      END
      //---------------------------
      ::AddConditionButton_OnClick()
      //---------------------------
   END
   WITH OBJECT ( BUTTON( Self ) )
      :Name                 := "FilterBrowse"
      WITH OBJECT :Dock
         :Left              := Self
         :Bottom            := Self
         :Margins           := "20,0,20,10"
      END
      :Left                 := 530
      :Top                  := 315
      :Width                := 80
      :Height               := 25
      :Caption              := "Test Filter"
      :EventHandler[ "OnClick" ] := "FilterBrowse_OnClick"
      :Create()
   END

   WITH OBJECT ( BUTTON( Self ) )
      :Name                 := "Cancel"
      WITH OBJECT :Dock
         :Right                := Self
         :Bottom               := Self
         :Margins              := "0,0,20,10"
      END
      :Left                 := 530
      :Top                  := 315
      :Width                := 80
      :Height               := 25
      :Caption              := "Cancel"
      :EventHandler[ "OnClick" ] := "Cancel_OnClick"
      :Create()
   END
   WITH OBJECT ( BUTTON( Self ) )
      :Name                 := "OK"
      WITH OBJECT :Dock
         :Right                := "Cancel"
         :Bottom               := Self
         :Margins              := "0,0,5,10"
      END
      :Left                 := 530
      :Top                  := 315
      :Width                := 80
      :Height               := 25
      :Caption              := "OK"
      :EventHandler[ "OnClick" ] := "OK_OnClick"
      :Create()
   END

   ::CenterWindow()
RETURN NIL

//----------------------------------------------------------------------------------------------------//
METHOD AddConditionButton_OnClick( Sender ) CLASS FilterUI
   LOCAL cName, n, oLastPanel
   IF LEN( ::ConditionPanel:Children ) > 0
      oLastPanel := ATAIL( ::ConditionPanel:Children )

      oLastPanel:Children[ LEN(oLastPanel:Children)-1 ]:Enabled := .F.
      oLastPanel:Children[ LEN(oLastPanel:Children)-0 ]:Enabled := .F.
   ENDIF
   WITH OBJECT ::ConditionPanel
      WITH OBJECT ( PANEL( :this ) )
         :Left           := 0
         :Top            := 0
         :Width          := 150
         :Height         := 30
         :Dock:Left      := :Parent
         :Dock:Right     := :Parent
         :Dock:Top       := IIF( LEN( ::ConditionPanel:Children ) > 0, ATAIL( ::ConditionPanel:Children ), :Parent )
         :Dock:TopMargin := 4
         :Create()
         :SetRedraw( .F. )

         WITH OBJECT ( COMBOBOX( :this ) )
            :ToolTip:Text         := "Select field"
            :VertScroll           := .T.
            :Left                 := 1
            :Top                  := 0
            :Width                := 150
            :Height               := 200
            :EventHandler[ "OnCBNSelEndOk" ] := "FieldComboBox_OnCBNSelEndOk"
            :Create()

            ::LoadFieldList( :This )

            :Parent:Height := :SelectionHeight() + 7
         END
         :Parent:VertScrollSize := (:Height+4)*LEN( ::ConditionPanel:Children )

         WITH OBJECT ( COMBOBOX( :this ) )
            :ToolTip:Text         := "Select condition"
            :VertScroll           := .T.
            :Left                 := 165
            :Top                  := 0
            :Width                := 150
            :Height               := 200
            :Enabled              := .F.
            :EventHandler[ "OnCBNSelEndOk" ] := "ConditionComboBox_OnCBNSelEndOk"
            :Create()
         END

         WITH OBJECT ( EDITBOX( :this ) )
            :Left                 := 320
            :Top                  := 0
            :Width                := 150
            :Height               := 22
            :AutoHScroll          := .T.
            :Create()
         END

         WITH OBJECT ( EDITBOX( :this ) )
            :Left                 := 394
            :Top                  := 0
            :Width                := 72
            :Height               := 22
            :Visible              := .F.
            :AutoHScroll          := .T.
            :Create()
         END //EDITBOX

         ::AddButtons( :this )
         
         :SetRedraw( .T. )
         :RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_INTERNALPAINT | RDW_ALLCHILDREN )
         :UpdateWindow()
      END
      :PostMessage( WM_VSCROLL, MAKELONG( SB_PAGEDOWN, 0) )
   END
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD AddButtons( oParent ) CLASS FilterUI
   WITH OBJECT ( BUTTON( oParent ) )
      :ToolTip:Text         := "Remove condition"
      :Left                 := 475
      :Top                  := 0
      :Width                := 20
      :Height               := 22
      :Caption              := "-"
      :EventHandler[ "OnClick" ] := "RemoveConditionButton_OnClick"
      :Create()
   END

   WITH OBJECT ( BUTTON( oParent ) )
      :ToolTip:Text         := "Add more condition"
      :Left                 := 500
      :Top                  := 0
      :Width                := 20
      :Height               := 22
      :Caption              := "+"
      :EventHandler[ "OnClick" ] := "AddConditionButton_OnClick"
      :Create()
   END

   WITH OBJECT ( BUTTON( oParent ) )
      :ToolTip:Text         := "More..."
      :Left                 := 525
      :Top                  := 0
      :Width                := 20
      :Height               := 22
      :Caption              := "..."
      :EventHandler[ "OnClick" ] := "MoreConditionButton_OnClick"
      :Create()
   END

RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD FieldComboBox_OnCBNSelEndOk( Sender ) CLASS FilterUI
   LOCAL cType := ::oDataTable:EditCtrl:FieldType( Sender:GetCurSel() )
   IF !Sender:Parent:Children[2]:Enabled
      Sender:Parent:Children[2]:Enabled := .T.
   ENDIF
   Sender:Parent:Children[2]:ResetContent()
   AEVAL( ::aCond_&cType, {|c| Sender:Parent:Children[2]:AddItem(c) } )
   Sender:Parent:Children[2]:SetCurSel(1)
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD ConditionComboBox_OnCBNSelEndOk( Sender ) CLASS FilterUI
   LOCAL oPanel := Sender:Parent

   oPanel:Children[3]:Enabled := .T.
   IF Sender:CurSel == 5
      IF !oPanel:Children[4]:Visible
         oPanel:Children[3]:Width := 72
         oPanel:Children[4]:Visible := .T.
      ENDIF
    ELSE
      IF oPanel:Children[4]:Visible
         oPanel:Children[3]:Width := 150
         oPanel:Children[4]:Caption := ""
         oPanel:Children[4]:Visible := .F.
      ENDIF
      IF Sender:CurSel == 10 .OR. Sender:CurSel == 11
         oPanel:Children[3]:Caption := ""
         oPanel:Children[3]:Enabled := .F.
      ENDIF
   ENDIF
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD RemoveConditionButton_OnClick( Sender ) CLASS FilterUI
   LOCAL oDock, n, oLastPanel
   IF LEN( ::ConditionPanel:Children ) > 1
      oDock := Sender:Parent:Dock:Top
      n := ASCAN( ::ConditionPanel:Children, {|o| o:hWnd == Sender:Parent:hWnd} )
      IF n > 0 .AND. LEN( ::ConditionPanel:Children ) >= n+1
         ::ConditionPanel:Children[n+1]:Dock:Top := oDock
      ENDIF
      Sender:Parent:Destroy()
      IF LEN( ::ConditionPanel:Children ) > 0
         oLastPanel := ATAIL( ::ConditionPanel:Children )
         oLastPanel:Children[ LEN(oLastPanel:Children)-1 ]:Enabled := .T.
         oLastPanel:Children[ LEN(oLastPanel:Children)-0 ]:Enabled := .T.
      ENDIF
   ENDIF
   ::ConditionPanel:VertScrollSize := (ATAIL( ::ConditionPanel:Children ):Height+4)*LEN( ::ConditionPanel:Children )
   ::ConditionPanel:ScrollWindow( 0, -(ATAIL( ::ConditionPanel:Children ):Height+4) )
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD MoreConditionButton_OnClick( Sender ) CLASS FilterUI
   LOCAL cName, n, oLastPanel
   
   IF LEN( ::ConditionPanel:Children ) > 0
      oLastPanel := ATAIL( ::ConditionPanel:Children )
      oLastPanel:Children[ LEN(oLastPanel:Children)-1 ]:Enabled := .F.
      oLastPanel:Children[ LEN(oLastPanel:Children)-0 ]:Enabled := .F.
   ENDIF
   WITH OBJECT ::ConditionPanel
      WITH OBJECT ( PANEL( :this ) )
         :Left           := 0
         :Top            := 0
         :Width          := 150
         :Height         := 30
         :Dock:Left      := :Parent
         :Dock:Right     := :Parent
         :Dock:Top       := IIF( LEN( ::ConditionPanel:Children ) > 0, ATAIL( ::ConditionPanel:Children ), :Parent )
         :Dock:TopMargin := 4
         :Create()
         :SetRedraw( .F. )

         WITH OBJECT ( COMBOBOX( :this ) )
            :VertScroll           := .T.
            :Left                 := 1
            :Top                  := 0
            :Width                := 250
            :Height               := 100
            :Create()

            :AddItem( "Match ALL of the following conditions" )
            :AddItem( "Match ANY of the following conditions" )
            :SetCurSel(1)

            :Parent:Height := :SelectionHeight() + 7
         END
         :Parent:VertScrollSize := (:Height+4)*LEN( ::ConditionPanel:Children )

         ::AddButtons( :this )

         :SetRedraw( .T. )
         :RedrawWindow( , , RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_INTERNALPAINT | RDW_ALLCHILDREN )
         :UpdateWindow()
      END
   END
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD FilterBrowse_OnClick( Sender ) CLASS FilterUI
   LOCAL oDlg
   ::BuildFilterExp()
   WITH OBJECT oDlg := TestFilter( Self )
      :Caption := "Test DataTable Filter"
      :Width   := 600
      :Height  := 400
      :Center  := .T.
      :Create()
   END
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD OK_OnClick() CLASS FilterUI
   ::BuildFilterExp()
   ::Close( IDOK )
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD Cancel_OnClick() CLASS FilterUI
   ::Close( IDCANCEL )
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD BuildFilterExp() CLASS FilterUI
   LOCAL cAndOr, cField, cExp, cExp2, nSel, oPanel, n, cType
   ::cFilter := ""
   cAndOr := IIF( ::ANDRadioButton:Checked, " .AND. ", " .OR. " )
   FOR n := 1 TO LEN( ::ConditionPanel:Children )
       oPanel := ::ConditionPanel:Children[n]
       IF LEN( oPanel:Children ) == 4
          cAndOr := IIF( oPanel:Children[1]:GetCurSel() == 1, " .AND. ", " .OR. " )
        ELSE
        
          nSel  := oPanel:Children[2]:GetCurSel()
          cType := ::oDataTable:EditCtrl:FieldType( oPanel:Children[1]:GetCurSel() )
          cExp  := oPanel:Children[3]:Caption
          cExp2 := oPanel:Children[4]:Caption

          IF cType == "C"
             cField := "TRIM("+::oDataTable:Alias + "->" + oPanel:Children[1]:GetSelString()+")"
           ELSEIF cType == "N"
             cField := ::oDataTable:Alias + "->" + oPanel:Children[1]:GetSelString()
             cExp   := VAL( cExp )
             cExp2  := VAL( cExp2 )
           ELSEIF cType == "D"
             cField := ::oDataTable:Alias + "->" + oPanel:Children[1]:GetSelString()
             cExp   := CTOD( cExp )
             cExp2  := CTOD( cExp2 )
          ENDIF
          cExp  := ValToPrg( cExp  )
          cExp2 := ValToPrg( cExp2 )

          IF n > 1
             ::cFilter += cAndOr
          ENDIF
          DO CASE 
             CASE nSel == 1  //"equals to"
               ::cFilter += cField + "==" + cExp

             CASE nSel == 2  //"is not equal to"
               ::cFilter += "!(" + cField + "==" + cExp + ")"

             CASE nSel == 3  //"greater than"
               ::cFilter += cField + ">" + cExp

             CASE nSel == 4  //"less than"
               ::cFilter += cField + "<" + cExp

             CASE nSel == 5  //"between"
               ::cFilter += "(" + cField + ">= " + cExp + ".AND." + cField +"<=" + cExp2 + ")"

             CASE nSel == 6  //"begins with"
               ::cFilter += cField + "=" + cExp

             CASE nSel == 7  //"does not begin with"
               ::cFilter += cField + "!=" + cExp

             CASE nSel == 8  //"contains"
               ::cFilter += cExp + " $ " + cField

             CASE nSel == 9  //"does not contain"
               ::cFilter += "!(" + cExp + " $ " + cField + ")"

             CASE nSel == 10 //"is empty"
               ::cFilter += "EMPTY(" + cField + ")"

             CASE nSel == 11 //"is not empty"
               ::cFilter += "! EMPTY(" + cField + ")"

             CASE nSel == 12 //"is in the range"
          END
       ENDIF
   NEXT
RETURN Self

//----------------------------------------------------------------------------------------------------//
METHOD LoadFieldList( oComboBox ) CLASS FilterUI
   LOCAL n, i, aFields
   oComboBox:ResetContent()
   aFields := ::oDataTable:EditCtrl:Struct()
   FOR n := 1 TO LEN( aFields )
       oComboBox:AddItem( aFields[n][1] )
   NEXT
RETURN NIL

//-------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------

CLASS TestFilter INHERIT Dialog
   METHOD OnInitDialog()
ENDCLASS

METHOD OnInitDialog() CLASS TestFilter
   LOCAL oGrid, oEdit, oData, oTable := ::Parent:oDataTable
   
   WITH OBJECT oData := DataTable( Self )
      :xFileName := oTable:FileName
      :Driver   := oTable:Driver
      
      IF oTable:Driver != "SQLRDD"
         :Alias := oTable:Alias
         :Create()
         :SetFilter( &("{||"+::Parent:cFilter+"}") )
         IF ! EMPTY( oTable:Order )
            :OrdSetFocus( oTable:Order )
         ENDIF
         :GoTop()
      ENDIF
   END

   WITH OBJECT oEdit := Edit( Self )
      :Left         := 0
      :Top          := 0
      :Width        := 300
      :ReadOnly     := .T.
      :Caption      := ::Parent:cFilter
      :Dock:Left    := Self
      :Dock:Bottom  := Self
      :Dock:Right   := Self
      :Create()
   END

   WITH OBJECT oGrid := DataGrid( Self )
      :Left         := 0
      :Top          := 0
      :Width        := 300
      :Height       := 200
      :DataSource   := oData
      :Dock:Left    := Self
      :Dock:Top     := Self
      :Dock:Right   := Self
      :Dock:Bottom  := oEdit
      :Dock:BottomMargin := 2
      :Create()
      :AutoAddColumns()
   END
RETURN Self
