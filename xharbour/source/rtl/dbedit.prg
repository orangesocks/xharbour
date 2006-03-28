/*
 * $Id: dbedit.prg,v 1.29 2006/03/28 02:22:39 modalsist Exp $
 */

/*
 * xHarbour Project source code:
 * DBEDIT() function
 *
 * Copyright 2003 Mauricio Abre <maurifull@datafull.com>
 * www - http://www.xharbour.org
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

/*
 * NOTE: This is a total rewrite with all features previous dbedit() had
 *       plus a few more.
 *       It works with or w/o 5.3 extensions
 *       + Using 5.3 extensions gives mouse event handling :)
 *       + Features previous dbedit() had are:
 *         - User func can be a codeblock
 *         - No coords = full screen
 *         - No columns = fill with db structure
 *       + New features in this version:
 *         - Any column can be also a codeblock instead of a string
 *         - Heading/footing separator is single line instead of double line
 *           (see below in the code)
 *         - Columns are movable via K_CTRL_UP / K_CTRL_DOWN
 *         - A column can be an array of 2 items
 *           In this case, the second is the codeblock to do coloring :)
 *         - Userfunc is called with a third parameter, the actual TBRowse object
 *           This is very useful, it increases A LOT the power of dbedit()
 *         - UserFunc is also called once with nMode == -1 (initialization)
 *           Prior to begin browsing
 *         - You can pass pre/post blocks for later using in user func
 *           (combinated with the GET system)
 *
 * DBEdit() is no more deprecated :)
 * Have fun
 *                      Mauricio
 *
 */

#include "dbedit.ch"
#include "inkey.ch"
#include "button.ch"
#include "setcurs.ch"
#include "hbsetup.ch"
#include "common.ch"


FUNCTION DBEdit(nTop,;                //  1�
                nLeft,;               //  2�
                nBottom,;             //  3�
                nRight,;              //  4�
                axColumns,;           //  5�
                xUserFunc,;           //  6�
                acColumnSayPictures,; //  7�
                acColumnHeaders,;     //  8�
                acHeadingSep,;        //  9�
                acColumnSep,;         // 10�
                acFootingSep,;        // 11�
                acColumnFootings,;    // 12�
                bPreBlock,;           // 13� - xHarbour extension
                bPostBlock)           // 14� - idem

LOCAL oTBR,;
      oTBC,;
      i,k,;
      nRet := DE_REFRESH,;
      nKey := Nil,;
      bFun,;
      nCursor,;
      cHdr,;
      nIndex

  // If no database in use we must call Errorsys() with error 2001
  //
  IF !Used()
     Throw( ErrorNew( "DBCMD", 0, 2001, ProcName(), "Workarea not in use" ) )
  END


  DEFAULT nTop TO 0
  DEFAULT nLeft TO 0
  DEFAULT nRight TO MaxCol()
  DEFAULT nBottom TO MaxRow()

  // NOTE: Heading/footing separator is SINGLE line instead of DOUBLE line
  //       this is because most codepages (unicode too) don't have DOUBLE line chars
  //       so the output is ugly with them
  //
  DEFAULT acHeadingSep TO Chr(196) + Chr(194) + Chr(196)
  DEFAULT acColumnSep  TO " " + Chr(179) + " "
  DEFAULT acColumnFootings TO ""


  nTop    := Max(0,nTop)
  nLeft   := Max(0,nLeft)
  nBottom := Min(MaxRow(),nBottom)
  nRight  := Min(MaxCol(),nRight)


  IF Empty(axColumns) .OR. !HB_ISARRAY( axColumns )

    axColumns := Array( FCount() )

    FOR EACH i IN axColumns
      i := FieldName( HB_EnumIndex() )
    NEXT

  END

  // Check parameter types. If any parameter is invalid xHarbour show a
  // message error. This behaviour is xHarbour extension.

  // Check <axColumns>
  //
  FOR EACH k IN axColumns
      IF !HB_IsString(k) .AND. !HB_IsBlock(k) .AND. !HB_IsArray(k)
         Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumns>", "Argument error. String, array or codeblock required" ) )
      ELSEIF Empty(k)
         Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumns>", "Empty argument not allowed" ) )
      ENDIF
  NEXT

  // Check <cUserFunc>
  // In Clipper the <cUserFunc> only can be a string.
  // In xHarbour can be a codeblock also.
  //
  IF !HB_IsNil(xUserFunc) .AND. ( !HB_IsString( xUserFunc ) .AND. !HB_IsBlock(xUserFunc) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<cUserFunction>", "Argument error. String or codeblock required" ) )
  ENDIF

  // Check <acColumnSayPictures|cColumnSayPicture>
  //
  IF !HB_IsNil(acColumnSayPictures) .AND. ( !HB_IsString(acColumnSayPictures) .AND. !HB_IsArray(acColumnSayPictures) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumnSayPictures|cColumnSayPicture>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <acColumnHeaders|cColumnHeader>
  //
  IF !HB_IsNil(acColumnHeaders) .AND. ( !HB_IsString(acColumnHeaders) .AND. !HB_IsArray(acColumnHeaders) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumnHeaders|cColumnHeader>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <acHeadingSeparators|cHeadingSeparator>
  //
  IF !HB_IsNil(acHeadingSep) .AND. ( !HB_IsString(acHeadingSep) .AND. !HB_IsArray(acHeadingSep) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acHeadingSeparators|cHeadingSeparator>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <acColumnSeparators|cColumnSeparator>
  //
  IF !HB_IsNil(acColumnSep) .AND. ( !HB_IsString(acColumnSep) .AND. !HB_IsArray(acColumnSep) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumnSeparators|cColumnSeparator>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <acFootingSeparators|cFootingSeparator>
  //
  IF !HB_IsNil(acFootingSep) .AND. ( !HB_IsString(acFootingSep) .AND. !HB_IsArray(acFootingSep) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acFootingSeparators|cFootingSeparator>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <acColumnFootings|cColumnFooting>
  //
  IF !HB_IsNil(acColumnFootings) .AND. ( !HB_IsString(acColumnFootings) .AND. !HB_IsArray(acColumnFootings) )
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<acColumnFootings|cColumnFooting>", "Argument error. Array or string required" ) )
  ENDIF

  // Check <bPreBlock>.
  //
  IF !HB_IsNil(bPreBlock) .AND. !HB_IsBlock(bPreBlock)
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<bPreBlockBlock>", "Argument error. Codeblock required" ) )
  ENDIF

  // Check <bPostBlock>.
  //
  IF !HB_IsNil(bPostBlock) .AND. !HB_IsBlock(bPostBlock)
     Throw( ErrorNew( "BASE", 0, 1003, Procname()+":<bPostBlockBlock>", "Argument type error. Codeblock required" ) )
  ENDIF


  IF HB_ISBLOCK( bPreBlock )
     i := bPreBlock
     bPreBlock := Array( Len(axColumns) )
     AFill(bPreBlock, i)
  END

  IF HB_ISBLOCK( bPostBlock )
     i := bPostBlock
     bPostBlock := Array( Len(axColumns) )
     aFill(bPostBlock, i)
  END


  iif(HB_ISNIL(acFootingSep) .AND. !Empty(acColumnFootings), acFootingSep := Chr(196) + Chr(193) + Chr(196), .T.)

  oTBR := TBrowseDB(nTop, nLeft, nBottom, nRight)

  IF HB_ISSTRING(acHeadingSep)
     oTBR:headSep := acHeadingSep
  END

  IF HB_ISSTRING(acFootingSep)
     oTBR:footSep := acFootingSep
  END

  IF HB_ISSTRING(acColumnSep)
     oTBR:colSep := acColumnSep
  END

  nCursor := SetCursor(SC_NONE)

#ifdef HB_COMPAT_C53
  // EXTENSION: Move columns inside dbedit :)
  oTBR:setKey(K_CTRL_UP, {|| _MoveCol(oTBR, K_CTRL_UP), 0})
  oTBR:setKey(K_CTRL_DOWN, {|| _MoveCol(oTBR, K_CTRL_DOWN), 0})
#endif

 // Build columns
 //
 FOR EACH i IN axColumns

    IF !Empty( i )

       nIndex := HB_EnumIndex()

       If HB_ISARRAY(i)
          bFun := IIf(HB_ISBLOCK(i[1]), i[1], &("{||" + i[1] + '}'))
       Else
          bFun := IIf(HB_ISBLOCK(i), i, &("{||" + i + '}'))
       End

       If ValType(Eval(bFun)) == 'M'  // HB_ISMEMO() returns .T. for strings :(
          bFun := {|| "  <Memo>  "}
       End

       cHdr := i

       If HB_ISSTRING( acColumnHeaders )
          cHdr := acColumnHeaders
       ElseIf HB_ISARRAY( acColumnHeaders ) .and. Len( acColumnHeaders ) >= nIndex .and. acColumnHeaders[ nIndex ] != NIL // handle empty column headers
          cHdr := acColumnHeaders[ nIndex ]
       End

       If HB_ISBLOCK( cHdr )
          cHdr := "<block>"
       End

       oTBC := TBColumnNew( cHdr, bFun )

       If HB_ISARRAY( i )
          oTBC:colorBlock := i[2]
       End

       If HB_ISARRAY( acColumnSep )
          oTBC:colSep := acColumnSep[ nIndex ]
       End

       If HB_ISARRAY( acHeadingSep )
          oTBC:headSep := acHeadingSep[ nIndex ]
       End

       If HB_ISARRAY( acFootingSep )
          oTBC:footSep := acFootingSep[ nIndex ]
       End

       If HB_ISARRAY( acColumnFootings )
          oTBC:footing := acColumnFootings[ nIndex ]
       ElseIf HB_ISSTRING(acColumnFootings)
          oTBC:footing := acColumnFootings
       End

       If HB_ISARRAY( acColumnSayPictures ) .and. Len( acColumnSayPictures ) >= nIndex
          oTBC:picture := acColumnSayPictures[ nIndex ]
       ElseIf HB_ISSTRING( acColumnSayPictures )
          oTBC:picture := acColumnSayPictures
       End

       If HB_ISARRAY( bPreBlock )

         If HB_ISLOGICAL( bPreBlock[ nIndex ] )
            bPreBlock[ nIndex ] := IIf( bPreBlock[ nIndex ], {|| .T.}, {|| .F.} )
         End

         oTBC:preBlock := bPreBlock[ nIndex ]

       End

       If HB_ISARRAY( bPostBlock )

         If HB_ISLOGICAL( bPostBlock[ nIndex ] )
            bPostBlock[ nIndex ] := IIf( bPostBlock[ nIndex ], {|| .T.}, {|| .F.} )
         End

         oTBC:postBlock := bPostBlock[ nIndex ]

       END

       oTBR:addColumn( oTBC )

    END

 NEXT

 IF Len(axColumns) == 1
    oTBR:setKey(K_LEFT, Nil)
    oTBR:setKey(K_RIGHT, Nil)
 END

 IF Empty(xUserFunc)
   bFun := {|| IIf(HB_ISNUMERIC(nKey) .And. (Chr(LastKey()) $ Chr(K_ESC) + Chr(K_ENTER)), DE_ABORT, DE_CONT)}
 ELSE
   bFun := IIf(HB_ISBLOCK(xUserFunc), xUserFunc, &("{|x, y, z|" + xUserFunc + "(x,y,z)}"))
   oTBR:setKey( K_ESC, nil )
 END

 // xHarbour extension: Initialization call
 //
 _DoUserFunc(bFun, -1, oTBR:colPos, oTBR)

 oTBR:refreshAll()
 oTBR:invalidate()
 oTBR:forceStable()
 oTBR:deHilite()

 i := RecNo()
 dbGoTop()

 IF (Eof() .OR. RecNo() == LastRec() + 1) .AND. Bof()
    nRet := _DoUserFunc(bFun, DE_EMPTY, oTBR:colPos, oTBR)
 END

 dbGoto(i)

 IF nRet != DE_ABORT
    nRet := DE_CONT
 END


 /* --------------------------- */
 /* Go into the processing loop */
 /* --------------------------- */

 WHILE nRet != DE_ABORT

    Switch nRet
      Case DE_REFRESH
        oTBR:invalidate()
        oTBR:refreshAll()
        Exit
      Case DE_CONT
        oTBR:refreshCurrent()
        Exit
    End

    oTBR:forceStable()
    oTBR:deHilite()

    If oTBR:hitTop
       nRet := _DoUserFunc(bFun, DE_HITTOP, oTBR:colPos, oTBR)
    ElseIf oTBR:hitBottom
       nRet := _DoUserFunc(bFun, DE_HITBOTTOM, oTBR:colPos, oTBR)
    End

    If nRet == DE_ABORT
       Exit
    End

    nRet := _DoUserFunc(bFun, DE_IDLE, oTBR:colPos, oTBR)

    If nRet == DE_ABORT
       Exit
    End 

    oTBR:hilite()

    nKey := Inkey(0)

#ifdef HB_COMPAT_C53
    // xHarbour with 5.3 extensions code
    IF ValType(oTBR:SetKey(nKey)) == 'B'
       iif(oTBR:applyKey(nKey) == -1, nRet := 0, .T.)
       LOOP
    END
#endif

    If ValType(SetKey(nKey)) == 'B'
       Eval(SetKey(nKey), ProcName(1), ProcLine(1), "")
       Loop
    End

#ifdef HB_COMPAT_C53

    // got a key exception
    //
    oTBR:refreshCurrent()
    oTBR:stabilize()
    oTBR:hilite()

    nRet := _DoUserFunc(bFun, DE_EXCEPT, oTBR:colPos, oTBR)

    IF nRet == DE_ABORT
       EXIT
    END

#else
    // xHarbour without 5.3 extensions code
    Switch nKey
      Case K_DOWN
        oTBR:down()
        Exit
      Case K_UP
        oTBR:up()
        Exit
      Case K_LEFT
        oTBR:left()
        Exit
      Case K_RIGHT
        oTBR:right()
        Exit
      Case K_PGDN
        oTBR:pageDown()
        Exit
      Case K_PGUP
        oTBR:pageUp()
        Exit
      Case K_CTRL_PGUP
        oTBR:goTop()
        Exit
      Case K_CTRL_PGDN
        oTBR:goBottom()
        Exit
      Case K_HOME
        oTBR:home()
        Exit
      Case K_END
        oTBR:end()
        Exit
      Case K_CTRL_HOME
        oTBR:panHome()
        Exit
      Case K_CTRL_END
        oTBR:panEnd()
        Exit
      Case K_CTRL_LEFT
        oTBR:panLeft()
        Exit
      Case K_CTRL_RIGHT
        oTBR:panRight()
        Exit
      #ifdef HB_COMPAT_C53
      // EXTENSION: Move columns inside dbedit :)
      Case K_CTRL_UP
      Case K_CTRL_DOWN
        _MoveCol(oTBR, nKey)
        Exit
      #endif
      Default
       // got a key exception
       oTBR:refreshCurrent()
       oTBR:stabilize()
       oTBR:hilite()
       nRet := _DoUserFunc(bFun, DE_EXCEPT, oTBR:colPos, oTBR)
    End

    IF nRet == DE_ABORT
       EXIT
    END

#endif

    // userfunc could delete recs...
    i := RecNo()

    dbGoTop()

    If (Eof() .Or. RecNo() == LastRec() + 1) .And. Bof()
       nRet := _DoUserFunc(bFun, DE_EMPTY, oTBR:colPos, oTBR)
    End

    dbGoto(i)

 END

 SetCursor(nCursor)
 SetPos(Row(),0)

RETURN .T.

#ifdef HB_COMPAT_C53
Static Function _MoveCol(oTBR, nKey)
Local oTB1, oTB2

  If nKey == K_CTRL_DOWN .And. oTBR:colPos < oTBR:colCount
    oTB1 := oTBR:getColumn(oTBR:colPos)
    oTB2 := oTBR:getColumn(oTBR:colPos + 1)
    oTBR:setColumn(oTBR:colPos, oTB2)
    oTBR:SetColumn(oTBR:colPos + 1, oTB1)
    oTBR:colPos++
    oTBR:invalidate()
  ElseIf nKey == K_CTRL_UP .And. oTBR:colPos > 1
    oTB1 := oTBR:getColumn(oTBR:colPos)
    oTB2 := oTBR:getColumn(oTBR:colPos - 1)
    oTBR:setColumn(oTBR:colPos, oTB2)
    oTBR:SetColumn(oTBR:colPos - 1, oTB1)
    oTBR:colPos--
    oTBR:invalidate()
  End
Return Nil
#endif

*------------------------------------------------------
STATIC FUNCTION _DoUserFunc(bFun, nMode, nColPos, oTBR)
LOCAL nRet, nRec

  oTBR:RefreshAll():ForceStable()
  nRec := RecNo()

  nRet := Eval(bFun, nMode, nColPos, oTBR)

  IF RecNo() != nRec .And. nRet != DE_ABORT
     nRet := DE_REFRESH
  END

  IF !HB_ISNUMERIC(nRet) .Or. nRet < 0 .Or. nRet > 2
     nRet := DE_CONT
  END

  /*****************************************************************/
  /* This part of code was borrowed from old dbedit code (harbour) */
  /*****************************************************************/

  IF Eof() .AND. !(nRet == DE_EMPTY)
     dbSkip( -1 )
  ENDIF

  IF nRet == DE_REFRESH .OR. nRec != RecNo()

     IF nRet != DE_ABORT

        IF ( Set( _SET_DELETED ) .AND. Deleted() ) .OR. (!Empty( dbFilter() ) .AND. ! &( dbFilter() ) )
           dbSkip( 1 )
        END

        IF Eof()
           dbGoBottom()
        END

        nRec := RecNo()

        oTBR:RefreshAll():forceStable()

        WHILE nRec != RecNo()
           oTBR:Up():forceStable()
        END

     END

  ELSE
    oTBR:RefreshCurrent()
  END

  /******************************************/

RETURN nRet

