/*
 * $Id: binnum.c,v 1.5 2004/02/14 01:29:42 andijahja Exp $
 */

/*
 * Harbour Project source code:
 * BIN2W(), BIN2I(), BIN2L(), I2BIN(), L2BIN() functions
 *
 * Copyright 1999 Manuel Ruiz <mrt@joca.es>
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * The exception is that if you link the Harbour Runtime Library (HRL)
 * and/or the Harbour Virtual Machine (HVM) with other files to produce
 * an executable, this does not by itself cause the resulting executable
 * to be covered by the GNU General Public License. Your use of that
 * executable is in no way restricted on account of linking the HRL
 * and/or HVM code into it.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA (or visit
 * their web site at http://www.gnu.org/).
 *
 */

#include "hbapi.h"
#include "hbapiitm.h"

HB_FUNC( BIN2W )
{
   PHB_ITEM pItem = hb_param( 1, HB_IT_STRING );

   if( pItem )
   {
      char * pszString = hb_itemGetCPtr( pItem );
      ULONG ulLen = hb_itemGetCLen( pItem );

      hb_retni( HB_MKUSHORT( ( ulLen >= 1 ) ? ( BYTE ) pszString[ 0 ] : 0,
                             ( ulLen >= 2 ) ? ( BYTE ) pszString[ 1 ] : 0 ) );
   }
   else
      hb_retni( 0 );
}

HB_FUNC( BIN2I )
{
   PHB_ITEM pItem = hb_param( 1, HB_IT_STRING );

   if( pItem )
   {
      char * pszString = hb_itemGetCPtr( pItem );
      ULONG ulLen = hb_itemGetCLen( pItem );

      hb_retni( HB_MKSHORT( ( ulLen >= 1 ) ? ( BYTE ) pszString[ 0 ] : 0,
                            ( ulLen >= 2 ) ? ( BYTE ) pszString[ 1 ] : 0 ) );
   }
   else
      hb_retni( 0 );
}

HB_FUNC( BIN2L )
{
   PHB_ITEM pBin = hb_param( 1, HB_IT_STRING );

   if( pBin )
   {
      //char * pszString = hb_itemGetCPtr( pItem );
      //ULONG ulLen = hb_itemGetCLen( pItem );

      /* Seems more efficent to me, but NOT sure if has any pltaform dependant issues.
       * I fixed them. -- PK. */
      if( pBin->item.asString.length > 2 ) // Ok to take advantage of Termination char 0 :-)
      {
         hb_retnl( HB_ULONG_FROM_LE( *(LONG *) ( pBin->item.asString.value ) ) );

         return;
      }
      else
      {
         BYTE Temp[4];

         Temp[0] = Temp[1] = Temp[2] = Temp[3] = '\0';

         memcpy( (void *) Temp, (void *) pBin->item.asString.value, pBin->item.asString.length );

         hb_retnl( HB_ULONG_FROM_LE( *(LONG *) ( Temp ) ) );

         return;
      }

      /*
      hb_retnl( HB_MKLONG( ( ulLen >= 1 ) ? ( BYTE ) pszString[ 0 ] : 0,
                           ( ulLen >= 2 ) ? ( BYTE ) pszString[ 1 ] : 0,
                           ( ulLen >= 3 ) ? ( BYTE ) pszString[ 2 ] : 0,
                           ( ulLen >= 4 ) ? ( BYTE ) pszString[ 3 ] : 0 ) );
      */
   }


   hb_retnl( 0 );
}

HB_FUNC( I2BIN )
{
   char szString[ 2 ];

   if( ISNUM( 1 ) )
   {
      SHORT iValue = hb_parni( 1 );

      szString[ 0 ] = ( iValue & 0x00FF );
      szString[ 1 ] = ( iValue & 0xFF00 ) >> 8;
   }
   else
   {
      szString[ 0 ] =
      szString[ 1 ] = '\0';
   }

   hb_retclen( szString, 2 );
}

HB_FUNC( L2BIN )
{
   char szString[ 4 ];

   if( ISNUM( 1 ) )
   {
      LONG lValue = hb_parnl( 1 );

      szString[ 0 ] = ( lValue & 0x000000FF );
      szString[ 1 ] = ( lValue & 0x0000FF00 ) >> 8;
      szString[ 2 ] = ( lValue & 0x00FF0000 ) >> 16;
      szString[ 3 ] = ( lValue & 0xFF000000 ) >> 24;
   }
   else
   {
      szString[ 0 ] =
      szString[ 1 ] =
      szString[ 2 ] =
      szString[ 3 ] = '\0';
   }

   hb_retclen( szString, 4 );
}

