/*
 * $Id: xide.prg,v 1.143 2003/01/30 08:40:07 what32 Exp $
 */

/*
 * xHarbour Project source code:
 *
 * xIDE Main Module
 *
 * Copyright 2002 Augusto Infante [august213@sbcglobal.net] Andy Wos [andrwos@aust1.net] Ron Pinkas [ron@ronpinkas.com]
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
 */

#include "winuser.ch"
#include "wingdi.ch"
#include "common.ch"
#include "hbclass.ch"
#include "debug.ch"
#include "what32.ch"
#Include "commctrl.ch"
#include "wintypes.ch"
#include "cstruct.ch"

GLOBAL EXTERNAL Application
GLOBAL MainForm
GLOBAL FormEdit

GLOBAL ObjTree
GLOBAL ObjInspect
GLOBAL ObjEdit

//-------------------------------------------------------------------------------------------

FUNCTION Main
   local oSplash
 
   
   Application():Initialize()

   // splash screen
   oSplash := TSplash():Create( Application, "visualxharbour.bmp", 3000 )

   WITH OBJECT Application
      WITH OBJECT :CreateForm( MainForm(), @MainForm )
         :OnCloseQuery := {|o| IIF( o:MsgBox( 'Quitting xIDE ?','Exit', MB_YESNO ) == IDYES, NIL, 0 ) }

         :SetStyle( WS_THICKFRAME, .F. )
         :SetStyle( WS_MAXIMIZEBOX, .F. )

         :MainMenu()
         :MainToolBar()
         :MainStatusBar()

//         LockWindowUpdate()

         // add the object windows
         ObjTree    := ObjTree():Create( MainForm )
         ObjInspect := ObjInspect():Create( MainForm )
         ObjEdit    := ObjEdit():Create( MainForm )
         // focus to main Frame
         :SetFocus()
      END
      
      MainForm:Update()

      :Run()
  END
  
RETURN NIL

//----------------------------------------------------------------------------------------------

CLASS MainForm FROM TForm

   METHOD Create( oOwner ) INLINE  ::Super:Create( oOwner ),;
                                   ::FCaption  := "xHarbour xIde",;
                                   ::FLeft     := 0,;
                                   ::FTop      := 0,;
                                   ::FWidth    := GetWindowRect( GetDesktopWindow() )[3],;
                                   ::FHeight   := 131,;
                                   ::Icon      := LoadIcon( hInstance(), 'IDE' ),;
                                   Self
   METHOD MainMenu()
   METHOD MainToolBar()
   METHOD MainStatusBar()
//   METHOD WMCreate() INLINE LockWindowUpdate( ::FHandle )

ENDCLASS

//----------------------------------------------------------------------------------------------

METHOD MainMenu() CLASS MainForm

   LOCAL oItem, oSubItem, oMenu

   oMenu := TMainMenu():Create( Self )

      oItem := TMenuItem():Create( oMenu )
      oItem:Caption := "File"
      oItem:AppendTo( oMenu:Handle )
   
         oSubItem := TMenuItem():Create( oItem )
         oSubItem:Caption := "Open"
         oSubItem:Action  := {||OpenProject():Create()}
         oSubItem:AppendTo( oItem:Handle )

         oSubItem := TMenuItem():Create( oItem )
         oSubItem:Caption := "-"
         oSubItem:AppendTo( oItem:Handle )

         oSubItem := TMenuItem():Create( oItem )
         oSubItem:Caption := "Exit"
         oSubItem:Action  := {|| MainForm:Close() }
         oSubItem:AppendTo( oItem:Handle )

   ::SetMenu( oMenu )

RETURN Self

//----------------------------------------------------------------------------------------------

METHOD MainToolBar() CLASS MainForm

   LOCAL n, oTool, oSplash, oPage, oBand1, oBand2
   LOCAL hImg1,hImg2,hImg3,hBmp,aStdTab, oTb, oCB, oCoolBar, oBand

   // Add the main CoolBar
   oCB := TCoolBar():Create( MainForm )
   oCB:SetParent( MainForm )

   // Add the bands
   oBand1 := TCoolBand():Create( oCB )
   oBand1:MinWidth  := 190
   oBand1:MinHeight := 54
   
   oBand2 := TCoolBand():Create( oCB )
   oBand2:MinWidth  := ::Width - 250
   oBand2:MinHeight := 56

    // add the xmake toolbar
   WITH OBJECT ( oTool := TToolBar():Create( MainForm ) )
      :SetParent( MainForm )
      oBand1:SetChild( oTool )

      oTb := ToolButton():Create( oTool )
      oTb:Hint := "New Project"
      oTb:OnClick := {|| FormEdit := TFormEdit():Create( MainForm ) }
//      oTb:OnClick := {|| Application:CreateForm( TFormEdit(), @FormEdit ) }
      
      ToolButton():Create( oTool ):Hint := "Open Project"
      ToolButton():Create( oTool ):Hint := "Properties"
      ToolButton():Create( oTool ):Hint := "Build Application"
      ToolButton():Create( oTool ):Hint := "Build and Launch Application"
      ToolButton():Create( oTool ):Hint := "Re-Build Application"
      ToolButton():Create( oTool ):Hint := "Re-Build and Launch Application"
      ToolButton():Create( oTool ):Hint := "Launch Application"
      ToolButton():Create( oTool ):Hint := "Compile Single Source"
      ToolButton():Create( oTool ):Hint := "Compile All Sources"
      ToolButton():Create( oTool ):Hint := "Link Only"
      ToolButton():Create( oTool ):Hint := "Compile to PPO"
      ToolButton():Create( oTool ):Hint := "View"
      ToolButton():Create( oTool ):Hint := "Files"

      :RowCount := 2

      // ----------------------------------------------------   set imagelist
      hImg1:= ImageList_Create( 20, 20, ILC_COLORDDB+ILC_MASK )
      hBmp := LoadImage( hInstance(), "XMAKE", IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT )
      ImageList_AddMasked( hImg1, hBmp, RGB( 0, 255, 255 ) )
      DeleteObject(hBmp)
      SendMessage( :handle, TB_SETIMAGELIST, 0, hImg1 )
      //---------------------------------------------------------------------
   END


   // add the TabControl on the Rebarband

   WITH OBJECT ToolTabs():Create( MainForm )
      :SetParent( MainForm )
      oBand2:SetChild( ::ToolTabs )

      oPage := TabPage():Create( MainForm:ToolTabs )
      oPage:Name    := "StdTab"
      oPage:Caption := "Standard"
      oPage:SetParent( MainForm:ToolTabs )
      
      oPage := TabPage():Create( MainForm:ToolTabs )
      oPage:Name    := "Win32"
      oPage:Caption := "Win32"
      oPage:SetParent( MainForm:ToolTabs )

   END


   // sets the controls toolbar on the TabControl
   With Object ::ToolTabs:StdTab
      oCoolBar := TCoolBar():Create( MainForm:ToolTabs:StdTab )
      oCoolBar:SetParent( MainForm:ToolTabs:StdTab )
      oCoolBar:SetStyle( WS_BORDER, .F. )

      oBand := TCoolBand():Create( oCoolBar )
      oBand:MinWidth  := 190
      oBand:MinHeight := 54
      oBand:Grippers  := .F.
      
      With Object StdTools():Create( MainForm:ToolTabs:StdTab )
         :SetParent( MainForm:ToolTabs:StdTab )
         :SetStyle( TBSTYLE_CHECKGROUP )
         oBand:SetChild( MainForm:ToolTabs:StdTab:StdTools )

         aStdTab := { '', 'Frames', 'MainMenu', 'PopupMenu', 'Label', 'Edit', 'Memo', 'Button', ;
                          'CheckBox', 'RadioButton', 'ListBox', 'ComboBox', 'ScrollBar', 'GroupBox', ;
                          'RadioGroup', 'Panel', 'ActionList' }
         FOR n :=0 TO 16
             oTool := ToolButton():Create( MainForm:ToolTabs:StdTab:StdTools )
             oTool:OnClick:= {|oItem| FormEdit:OnMenuCommand( oItem ) }
             oTool:Style  := TBSTYLE_BUTTON + TBSTYLE_CHECKGROUP
             oTool:Hint   := aStdTab[ n +1 ]
         NEXT

         // ----------------------------------------------------   set imagelist

         hImg2:= ImageList_Create( 24, 24, ILC_COLORDDB+ILC_MASK )
         hBmp := LoadImage( hInstance(), "STDTAB", IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT )
         ImageList_AddMasked( hImg2, hBmp, RGB( 0, 255, 255 ) )
         DeleteObject( hBmp )
         SendMessage( :handle, TB_SETIMAGELIST, 0, hImg2 )
         //---------------------------------------------------------------------
      End
      :StdTools:Disable()
   End


//----------------------------------------------------------------------------------------------
   With Object ::ToolTabs:Win32
      oCoolBar := TCoolBar():Create( MainForm:ToolTabs:Win32 )
      oCoolBar:SetParent( MainForm:ToolTabs:Win32 )
      oCoolBar:SetStyle( WS_BORDER, .F. )
      
      oBand := TCoolBand():Create( oCoolBar )
      oBand:MinWidth  := 190
      oBand:MinHeight := 54
      oBand:Grippers  := .F.
      
      With Object WinTools():Create( ::ToolTabs:Win32 )
         :SetParent( MainForm:ToolTabs:Win32 )
         :SetStyle( TBSTYLE_CHECKGROUP )
         oBand:SetChild( MainForm:ToolTabs:Win32:WinTools )

         aStdTab := { '', 'TabControl', 'TreeView', '', 'StatusBar', 'ProgressBar', 'ToolBar', 'CoolBar', ;
                      '', '' }
         for n:=0 to 9
             oTool := ToolButton():Create( ::ToolTabs:Win32:WinTools )
             oTool:OnClick:= {|oItem| FormEdit:OnMenuCommand(oItem) }
             oTool:Style  := TBSTYLE_BUTTON + TBSTYLE_CHECKGROUP
             oTool:Hint   := aStdTab[ n +1 ]
         next

         // ----------------------------------------------------   set imagelist

         hImg2:= ImageList_Create( 24, 24, ILC_COLORDDB+ILC_MASK )
         hBmp := LoadImage( hInstance(), "WIN32", IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT )
         ImageList_AddMasked( hImg2, hBmp, RGB( 0, 255, 255 ) )
         DeleteObject(hBmp)
         SendMessage( :handle, TB_SETIMAGELIST, 0, hImg2 )

         //---------------------------------------------------------------------

      End
      :WinTools:Disable()
   End

   //--------- sets a QUICK access to the control
   ::ToolTabs:StdTab:StdTools:Name := "StdBar"
   ::SetLink( ::ToolTabs:StdTab:StdTools)

   ::ToolTabs:Win32:WinTools:Name := "Win32Bar"
   ::SetLink( ::ToolTabs:Win32:WinTools )


RETURN Self

//----------------------------------------------------------------------------------------------

METHOD MainStatusBar() CLASS MainForm

   TStatusBar():Create( Self )

   ::StatusBar1:Caption := 'StatusBar'
   ::StatusBar1:SetPanels( { 150,380,480,580,-1 } )
   ::StatusBar1:SetPanelText( 0, "Visual xHarbour" )

RETURN Self

//----------------------------------------------------------------------------------------------

CLASS ToolTabs FROM TTabControl
   DATA Name INIT "ToolTabs"
ENDCLASS

//----------------------------------------------------------------------------------------------

CLASS StdTools FROM TToolBar
   DATA Name INIT "StdTools"
ENDCLASS

//----------------------------------------------------------------------------------------------

CLASS WinTools FROM TToolBar
   DATA Name INIT "WinTools"
ENDCLASS

//----------------------------------------------------------------------------------------------

CLASS OpenProject FROM TOpenDialog
   METHOD Create() INLINE ::Filter     := { {"xIde Files (*.prg)","*.prg"} },;
                          ::Title      := "Open Project",;
                          ::InitialDir := GetModuleFileName(),;
                          ::FileName   := space( 255 ),;
                          ::Execute(),;
                          XFMOpen( ::FileName )
ENDCLASS

//--------------------------------------------------------------------------//
#pragma BEGINDUMP

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include <windows.h>

#include "hbapi.h"
#include "hbstack.h"
#include "hbapierr.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbfast.h"

#define SKIP_SPACE(p) { while( *p == ' ' || *p == '\t' ) p++; }
#define SKIP_EOL() { while( *sText == '\n' || *sText == '\r' ) sText++; }

#define XFM_MAX_EXP 1024

int XFMParse( char *sText );

HB_FUNC( XFMOPEN )
{
   PHB_ITEM pXFM = hb_param( 1, HB_IT_STRING );
   FILE *fh;
   long lSize ;
   char *sXFM;
   int  iErr;

   if( pXFM )
   {
      fh = fopen( pXFM->item.asString.value, "r" );
   }
   else
   {
      fh = NULL;
   }

   if( fh )
   {
      fseek( fh, 0, SEEK_END );
      if( ( iErr = ferror( fh ) ) != 0 )
      {
         OutputDebugString( "I/O Error\n" );
         hb_retl( 0 );
         fclose( fh );
         return;
      }

      lSize = ftell( fh );

      if( lSize > 0 )
      {
         sXFM = malloc( lSize + 1 );

         fseek( fh, 0, SEEK_SET );
         if( ( iErr = ferror( fh ) ) != 0 )
         {
            OutputDebugString( "I/O Error\n" );
            hb_retl( 0 );
            fclose( fh );
            free( sXFM );
            return;
         }

         fread( sXFM, 1, lSize, fh );
         if( ( iErr = ferror( fh ) ) != 0 )
         {
            OutputDebugString( "I/O Error\n" );
            hb_retl( 0 );
            fclose( fh );
            free( sXFM );
            return;
         }

         //OutputDebugString( "Parse:\n" );
         //OutputDebugString( sXFM );
         iErr = XFMParse( sXFM );
         //OutputDebugString( "Parsed\n" );

         hb_retl( iErr );
         //OutputDebugString( "Set Return\n" );

         fclose( fh );
         //OutputDebugString( "Closed.\n" );
         free( sXFM );
         //OutputDebugString( "Freed.\n" );
         return;
      }
   }

   hb_retl( 0 );
}

int XFMParse( char *sText )
{
   char sClass[64], sFromClass[64], sVar[64], sExp[XFM_MAX_EXP], *pTemp, *pTerm, *pEnd[16], sAssign[64], sTemp[256];
   int i, iEnd = 0, iLen;
   static PHB_DYNS pCreateForm = NULL;
   static PHB_DYNS pTFormEdit = NULL;
   PHB_DYNS pClassSym;
   HB_ITEM Exp, Control, Object, Name, Element;
   PHB_ITEM pForm;
   MSG msg ;

   Exp.type = HB_IT_NIL;
   Control.type = HB_IT_NIL;
   Object.type = HB_IT_NIL;
   Name.type = HB_IT_NIL;
   Element.type = HB_IT_NIL;

   if( pCreateForm == NULL )
   {
      pCreateForm = hb_dynsymFind( "CREATEFORM" );
   }

   if( pTFormEdit == NULL )
   {
      pTFormEdit = hb_dynsymFind( "TFORMEDIT" );
   }

   //OutputDebugString( sText );

   sText = strstr( sText, "// ! AUTO_GENERATED !" );
   if( ! sText )
   {
      return 0;
   }
   sText += 21;

   sText = strstr( sText, "CLASS" );
   if( ! *sText )
   {
      return 0;
   }
   sText += 5;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sClass[i++] = *sText++;
   }
   sClass[i] = '\0';

   OutputDebugString( "Class: " );
   OutputDebugString( (char *) sClass );

   SKIP_SPACE( sText );

   if( strncmp( sText, "FROM", 4 ) )
   {
      return 0;
   }
   sText += 4;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sFromClass[i++] = *sText++;
   }
   sFromClass[i] = '\0';

   OutputDebugString( " From: " );
   OutputDebugString( sFromClass );
   OutputDebugString( "\n" );

   //TFormEdit()
   hb_vmPushSymbol( pTFormEdit->pSymbol );
   hb_vmPushNil();
   hb_vmDo( 0 );

   OutputDebugString( "Done, FormEdit()\n" );

   // Save result into pForm - we will use it multiple times below.
   hb_itemForwardValue( pForm, &hb_stack.Return );

   //Application:CreateForm( @FormEdit, TFormEdit(), MainForm )
   hb_vmPushSymbol( pCreateForm->pSymbol );
   hb_vmPush( &APPLICATION );
   // See below alternative to pushing REF.
   //memcpy( ( * hb_stack.pPos ), &FORMEDIT, sizeof( HB_ITEM ) );
   //hb_stackPush();
   hb_vmPushNil();
   hb_vmPush( pForm );
   hb_vmPush( &MAINFORM );
   hb_vmSend( 3 );

   // Instead of pushing @FormEdit
   hb_itemForwardValue( &FORMEDIT, &hb_stack.Return );

   OutputDebugString( "Done CreateForm()\n" );

   // Do events.
   while( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
   {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
   }

   pEnd[ iEnd ] = strstr( sText, "END CLASS" );
   if( pEnd[ iEnd ] == NULL )
   {
      return 0;
   }
   pEnd[ iEnd++ ][0] = '\0';

   SKIP_SPACE( sText );

   SKIP_EOL();

   SKIP_SPACE( sText );

 Vars:

   if( strncmp( sText, "DATA", 4 ) )
   {
      goto Controls;
   }
   sText += 4;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sVar[i++] = *sText++;
   }
   sVar[i] = '\0';

   OutputDebugString( "Var: " );
   OutputDebugString( (char *) sVar );

   SKIP_SPACE( sText )

   if( strncmp( sText, "INIT", 4 ) )
   {
      return 0;
   }
   sText += 4;

   SKIP_SPACE( sText );

   i = 0;
   while( i < XFM_MAX_EXP && *sText && *sText != '\n' )
   {
     sExp[i++] = *sText++;
   }
   sExp[i] = '\0';

   if( *sText != '\n' )
   {
      return 0;
   }

   OutputDebugString( " = " );
   OutputDebugString( (char *) sExp );
   OutputDebugString( "\n" );

   switch( sExp[0] )
   {
      case '.' :
        Exp.type = HB_IT_LOGICAL;
        Exp.item.asLogical.value = sExp[1] == 'T' ? TRUE : FALSE;
        break;

      case '"' :
        sExp[ strlen( sExp ) - 1 ] = '\0';
        hb_itemPutC( &Exp, (char *) sExp + 1 );
        break;

      case '{' :
        hb_arrayNew( &Exp, 0 );
        pTemp = (char *) sExp + 1;

        SKIP_SPACE( pTemp );

        while( *pTemp && *pTemp != '}' )
        {
           switch( pTemp[0] )
           {
              case '.' :
                Element.type = HB_IT_LOGICAL;
                Element.item.asLogical.value = pTemp[1] == 'T' ? TRUE : FALSE;
                pTemp += 3;
                break;

              case '"' :
                pTemp++;
                pTerm = strchr( pTemp, '"' );

                if( pTerm )
                {
                   pTerm[0] = '\0';
                   hb_itemPutC( &Element, pTemp );
                   pTemp = pTerm + 1;
                }
                else
                {
                   return 0;
                }

                break;

              default :
                pTerm = strpbrk( pTemp, ", " );
                if( pTerm )
                {
                   if( pTerm[0] == ',' )
                   {
                      pTerm[0] = '\0';

                      Element.type = HB_IT_LONG;
                      Element.item.asLong.value = atol( pTemp );

                      pTerm[0] = ',';
                   }
                   else
                   {
                      pTerm[0] = '\0';

                      Element.type = HB_IT_LONG;
                      Element.item.asLong.value = atol( pTemp );
                   }

                   pTemp = pTerm;
                }
                else
                {
                   return 0;
                }

                break;
           }

           SKIP_SPACE( pTemp );

           if( pTemp[0] == ',' )
           {
              pTemp++;
              SKIP_SPACE( pTemp );
           }
           else if( pTemp[0] != '}' )
           {
              return 0;
           }

           hb_arrayAddForward( &Exp, &Element );
           SKIP_SPACE( pTemp );
        }

        break;

      default :
        Exp.type = HB_IT_LONG;
        Exp.item.asLong.value = atol( sExp );
        break;
   }

   sAssign[0] = '_';
   sAssign[1] = '\0';

   iLen = strlen( sVar );
   sVar[ iLen ] = ';';
   sVar[ iLen + 1 ] = '\0';

   if( strstr( "CAPTION;TOP;LEFT;HEIGHT;WIDTH;", sVar ) )
   {
      sVar[ iLen ] = '\0';
      strcat( (char *) sAssign, (char *) "XX" );
   }
   else
   {
      sVar[ iLen ] = '\0';
   }

   strcat( (char *) sAssign, (char *) sVar );

   OutputDebugString( "Assign: " );
   OutputDebugString( sAssign );
   OutputDebugString( " Type: " );

   sprintf( (char *) sTemp, "%i\n", Exp.type );
   OutputDebugString( sTemp );

   hb_objSendMsg( &FORMEDIT, sAssign, 1, &Exp );
   hb_stack.Return.type = HB_IT_NIL;

   SKIP_EOL();

   SKIP_SPACE( sText );

   goto Vars;

 Controls:

   if( strncmp( sText, "CONTROL", 6 ) )
   {
      return 0;
   }
   sText += 7;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sClass[i++] = *sText++;
   }
   sClass[i] = '\0';

   OutputDebugString( "Control: " );
   OutputDebugString( (char *) sClass );

   SKIP_SPACE( sText );

   if( strncmp( sText, "FROM", 4 ) )
   {
      return 0;
   }
   sText += 4;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sFromClass[i++] = *sText++;
   }
   sFromClass[i] = '\0';

   OutputDebugString( " From: " );
   OutputDebugString( (char *) sFromClass );
   OutputDebugString( "\n" );

   pClassSym = hb_dynsymFind( sFromClass );
   if( pClassSym )
   {
      hb_vmPushSymbol( pClassSym->pSymbol );
      hb_vmPushNil();
      hb_vmDo( 0 );

      hb_itemForwardValue( &Control, &hb_stack.Return );

      hb_itemPutC( &Name, sClass );
      hb_objSendMsg( &Control, "_NAME", 1, &Name );
      hb_stack.Return.type = HB_IT_NIL;
   }
   else
   {
      return 0;
   }

   pEnd[ iEnd ] = strstr( sText, "END CONTROL" );
   if( pEnd[ iEnd ] == NULL )
   {
      return 0;
   }
   pEnd[ iEnd++ ][0] = '\0';

   SKIP_SPACE( sText );

   SKIP_EOL();

   SKIP_SPACE( sText );

 Properties:

   if( *sText != ':' )
   {
      if( strncmp( sText, "OBJECT", 6 ) )
      {
         if( *sText == '\0' )
         {
            if( Object.type == HB_IT_NIL )
            {
               OutputDebugString( "END CONTROL\n" );

               hb_objSendMsg( &FORMEDIT, "ADD", 1, &Control );
               hb_stack.Return.type = HB_IT_NIL;

               OutputDebugString( "Done Add()" );

               while( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
               {
                  TranslateMessage(&msg);
                  DispatchMessage(&msg);
               }

               hb_objSendMsg( &FORMEDIT, "SETCONTROL", 1, &Control );
               hb_stack.Return.type = HB_IT_NIL;

               OutputDebugString( "Done SetControl()" );

               while( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
               {
                  TranslateMessage(&msg);
                  DispatchMessage(&msg);
               }
            }
            else
            {
               OutputDebugString( "END OBJECT\n" );

               sAssign[0] = '_';
               sAssign[1] = '\0';
               strcat( (char *) sAssign, (char *) sClass );

               OutputDebugString( "Property: " );
               OutputDebugString( sAssign );
               OutputDebugString( "\n" );

               hb_objSendMsg( &Control, sAssign, 1, &Object );
               hb_stack.Return.type = HB_IT_NIL;

               hb_itemClear( &Object );
            }

            sText = pEnd[ --iEnd ] + 11;

            OutputDebugString( "Continue with: " );
            OutputDebugString( sText );

            sText = strchr( sText, '\n' );
            if( sText == NULL )
            {
               return 0;
            }

            SKIP_EOL();

            SKIP_SPACE( sText );
         }

         if( *sText == ':' )
         {
            goto Properties;
         }

         if( *sText )
         {
            goto Vars;
         }
         else
         {
            OutputDebugString( "Done.\n" );
            return 1;
         }
      }

      sText += 6;

      SKIP_SPACE( sText );

      i = 0;
      while( isalnum( *sText ) )
      {
        sClass[i++] = *sText++;
      }
      sClass[i] = '\0';

      OutputDebugString( "Object: " );
      OutputDebugString( (char *) sClass );

      SKIP_SPACE( sText );

      if( strncmp( sText, "IS", 2 ) )
      {
         return 0;
      }
      sText += 2;

      SKIP_SPACE( sText );

      i = 0;
      while( isalnum( *sText ) )
      {
        sFromClass[i++] = *sText++;
      }
      sFromClass[i] = '\0';

      OutputDebugString( " IS: " );
      OutputDebugString( (char *) sFromClass );
      OutputDebugString( "\n" );

      pClassSym = hb_dynsymFind( sFromClass );
      if( pClassSym )
      {
         hb_vmPushSymbol( pClassSym->pSymbol );
         hb_vmPushNil();
         hb_vmDo( 0 );

         hb_itemForwardValue( &Object, &hb_stack.Return );
      }
      else
      {
         return 0;
      }

      pEnd[ iEnd ] = strstr( sText, "END OBJECT" );
      if( pEnd[ iEnd ] == NULL )
      {
         return 0;
      }

      pEnd[ iEnd++ ][0] = '\0';

      SKIP_SPACE( sText );

      SKIP_EOL();

      SKIP_SPACE( sText );

      goto Properties;
   }

   sText += 1;

   SKIP_SPACE( sText );

   i = 0;
   while( isalnum( *sText ) )
   {
     sVar[i++] = *sText++;
   }
   sVar[i] = '\0';

   if( i == 0 )
   {
      return 1;
   }

   SKIP_SPACE( sText );

   if( strncmp( sText, ":=", 2 ) )
   {
      if( strncmp( sVar, "SetMethod", 9 ) == 0 && *sText == '(' )
      {
         sText++;

         SKIP_SPACE( sText );

         if( *sText == '"' )
         {
            sText++;

            i = 0;
            while( isalnum( *sText ) )
            {
              sVar[i++] = *sText++;
            }
            sVar[i] = '\0';

            sText++;

            OutputDebugString( "Event: " );
            OutputDebugString( (char *) sVar );

            SKIP_SPACE( sText );

            if( *sText != ',' )
            {
               return 0;
            }
            sText++;

            SKIP_SPACE( sText )

            if( strncmp( sText, "{ ||", 4 ) )
            {
               return 0;
            }
            sText += 4;

            SKIP_SPACE( sText );

            i = 0;
            while( isalnum( *sText ) || *sText == '_' )
            {
              sExp[i++] = *sText++;
            }
            sExp[i] = '\0';

            OutputDebugString( " = " );
            OutputDebugString( (char *) sExp );
            OutputDebugString( "\n" );

            sText = strchr( sText, '\n' );
            if( sText == NULL )
            {
               return 0;
            }

            SKIP_EOL();

            SKIP_SPACE( sText );

            goto Properties;
         }
      }
      return 0;
   }

   OutputDebugString( "Var: " );
   OutputDebugString( (char *) sVar );

   sText += 2;

   SKIP_SPACE( sText )

   i = 0;
   while( i < XFM_MAX_EXP && *sText && *sText != '\n' )
   {
     sExp[i++] = *sText++;
   }
   sExp[i] = '\0';

   if( *sText != '\n' )
   {
      return 0;
   }

   OutputDebugString( " = " );
   OutputDebugString( (char *) sExp );
   OutputDebugString( "\n" );

   switch( sExp[0] )
   {
      case '.' :
        Exp.type = HB_IT_LOGICAL;
        Exp.item.asLogical.value = sExp[1] == 'T' ? TRUE : FALSE;
        break;

      case '"' :
        sExp[ strlen( sExp ) - 1 ] = '\0';
        hb_itemPutC( &Exp, (char *) sExp + 1 );
        break;

      case '{' :
        hb_arrayNew( &Exp, 0 );

        pTemp = (char *) sExp + 1;

        SKIP_SPACE( pTemp );

        while( *pTemp && *pTemp != '}' )
        {
           switch( pTemp[0] )
           {
              case '.' :
                Element.type = HB_IT_LOGICAL;
                Element.item.asLogical.value = pTemp[1] == 'T' ? TRUE : FALSE;
                pTemp += 3;
                break;

              case '"' :
                pTemp++;
                pTerm = strchr( pTemp, '"' );

                if( pTerm )
                {
                   pTerm[0] = '\0';
                   hb_itemPutC( &Element, pTemp );
                   pTemp = pTerm + 1;
                }
                else
                {
                   return 0;
                }

                break;

              default :
                pTerm = strpbrk( pTemp, ", " );

                if( pTerm )
                {
                   if( pTerm[0] == ',' )
                   {
                      pTerm[0] = '\0';

                      Element.type = HB_IT_LONG;
                      Element.item.asLong.value = atol( pTemp );

                      pTerm[0] = ',';
                   }
                   else
                   {
                      pTerm[0] = '\0';

                      Element.type = HB_IT_LONG;
                      Element.item.asLong.value = atol( pTemp );
                   }

                   pTemp = pTerm;
                }
                else
                {
                   return 0;
                }

                break;
           }

           SKIP_SPACE( pTemp );

           if( pTemp[0] == ',' )
           {
              pTemp++;
              SKIP_SPACE( pTemp );
           }
           else if( pTemp[0] != '}' )
           {
              return 0;
           }

           hb_arrayAddForward( &Exp, &Element );
           SKIP_SPACE( pTemp );
        }

        break;

      default :
        Exp.type = HB_IT_LONG;
        Exp.item.asLong.value = atol( sExp );
        break;
   }

   sAssign[0] = '_';
   sAssign[1] = '\0';

   iLen = strlen( sVar );
   sVar[ iLen ] = ';';
   sVar[ iLen + 1 ] = '\0';

   if( strstr( "CAPTION;TOP;LEFT;HEIGHT;WIDTH;", sVar ) )
   {
      sVar[ iLen ] = '\0';
      strcat( (char *) sAssign, (char *) "XX" );
   }
   else
   {
      sVar[ iLen ] = '\0';
   }

   strcat( (char *) sAssign, (char *) sVar );

   OutputDebugString( "Assign: " );
   OutputDebugString( sAssign );
   OutputDebugString( " Type: " );

   sprintf( (char *) sTemp, "%i\n", Exp.type );
   OutputDebugString( sTemp );

   hb_objSendMsg( Object.type == HB_IT_NIL ? &Control : &Object, sAssign, 1, &Exp );
   hb_stack.Return.type = HB_IT_NIL;

   SKIP_EOL();

   SKIP_SPACE( sText );

   goto Properties;
}

#pragma ENDDUMP
