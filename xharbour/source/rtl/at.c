/*
 * $Id: at.c,v 1.3 2002/05/08 20:07:07 ronpinkas Exp $
 */

/*
 * Harbour Project source code:
 * AT() function
 *
 * Copyright 1999 Antonio Linares <alinares@fivetech.com>
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
#include "hbapiitm.h"
#include "hbapierr.h"

/* locates a substring in a string */

#ifdef HB_C52_STRICT

    HB_FUNC( AT )
    {
       PHB_ITEM pSub = hb_param( 1, HB_IT_STRING );
       PHB_ITEM pText = hb_param( 2, HB_IT_STRING );

       if( pText && pSub )
       {
          hb_retnl( hb_strAt( pSub->item.asString.value, pSub->item.asString.length, pText->item.asString.value, pText->item.asString.length ) );
       }
       else
       {
          hb_errRT_BASE_SubstR( EG_ARG, 1108, NULL, "AT", 2, hb_paramError( 1 ), hb_paramError( 2 ) );
       }
    }

#else

    HB_FUNC( AT )
    {
       PHB_ITEM pSub = hb_param( 1, HB_IT_STRING );
       PHB_ITEM pText = hb_param( 2, HB_IT_STRING );

       if( pText && pSub )
       {
          ULONG ulLength = pText->item.asString.length;
          ULONG ulStart = ISNUM( 3 ) ? hb_parnl( 3 ) : 1;
          ULONG ulEnd = ISNUM( 4 ) ? hb_parnl( 4 ) : ulLength;
          ULONG ulPos;

          // SANITIZATION
          // JC1: Don't know if it is clipper compliant, but anyway something
          // about that must be done.
          if ( ulStart < 1 )
          {
             ulStart = 1;
          }

          if ( ulStart > pText->item.asString.length )
          {
             ulStart = pText->item.asString.length;
          }

          if ( ulEnd < ulStart )
          {
             ulEnd = ulStart;
          }

          if ( ulEnd > pText->item.asString.length )
          {
             ulEnd = pText->item.asString.length;
          }
          // END OF SANITIZATION

          ulPos = hb_strAt( pSub->item.asString.value, pSub->item.asString.length, pText->item.asString.value + ulStart - 1, ulEnd - ulStart + 1 );

          hb_retnl( ulPos ? ulPos + ( ulStart - 1 ) : 0 );
       }
       else
       {
          hb_errRT_BASE_SubstR( EG_ARG, 1108, NULL, "AT", 2, hb_paramError( 1 ), hb_paramError( 2 ) );
       }
    }

#endif
