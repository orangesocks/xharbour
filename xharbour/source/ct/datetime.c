/*
 * $Id: datetime.c,v 1.1 2005/01/14 20:00:00 ptsarenko Exp $
 */

/*
 * Harbour Project source code:
 *   CT3 Date & Time functions: - BOM() / EOM()
 *                              - BOQ() / EOQ()
 *                              - BOY() / EOY()
 *
 * Copyright 2005 Pavel Tsarenko <tpe2@mail.ru>
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


#include "hbapi.h"
#include "hbdate.h"

HB_FUNC( BOM )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      hb_retd( iYear, iMonth, 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}

HB_FUNC( EOM )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      iMonth ++;
      if( iMonth > 12)
      {
         iMonth = 1;
         iYear ++;
      }
      hb_retdl( hb_dateEncode( iYear, iMonth, 1) - 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}

HB_FUNC( BOQ )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      while ( (iMonth-1) % 3 ) iMonth --;

      hb_retd( iYear, iMonth, 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}

HB_FUNC( EOQ )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      while ( iMonth % 3 ) iMonth ++;
      iMonth ++;
      if( iMonth > 12)
      {
         iMonth = 1;
         iYear ++;
      }
      hb_retdl( hb_dateEncode( iYear, iMonth, 1) - 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}

HB_FUNC( BOY )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      hb_retd( iYear, 1, 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}

HB_FUNC( EOY )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );

   if( pDate && pDate->item.asDate.value)
   {
      int iYear, iMonth, iDay;

      hb_dateDecode( pDate->item.asDate.value, &iYear, &iMonth, &iDay );
      hb_retdl( hb_dateEncode( iYear + 1, 1, 1) - 1);
   }
   else
   {
      hb_retdl( 0 );
   }
}
