/*
 * $Id: hbdate.h,v 1.2 2002/10/27 14:41:37 lculik Exp $
 */

/*
 * Harbour Project source code:
 * Header file for the Date API
 *
 * Copyright 1999-2001 Viktor Szakats <viktor.szakats@syenar.hu>
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

#ifndef HB_DATE_H_
#define HB_DATE_H_

#include "hbsetup.h"

#if defined(HB_EXTERN_C)
extern "C" {
#endif

extern double   HB_EXPORT hb_dateSeconds( void );
extern void     HB_EXPORT hb_dateToday( long * plYear, long * plMonth, long * plDay );
extern void     HB_EXPORT hb_dateTimeStr( char * pszTime );
extern char     HB_EXPORT * hb_dateCMonth( int iMonth );
extern char     HB_EXPORT * hb_dateCDOW( int iDay );
extern long     HB_EXPORT hb_dateDOW( long lYear, long lMonth, long lDay );
extern char     HB_EXPORT * hb_dateFormat( const char * szDate, char * szFormattedDate, const char * szDateFormat );
extern long     HB_EXPORT hb_dateEncode( long lYear, long lMonth, long lDay );
extern void     HB_EXPORT hb_dateDecode( long julian, long * plYear, long * plMonth, long * plDay );
extern void     HB_EXPORT hb_dateStrPut( char * szDate, long lYear, long lMonth, long lDay );
extern void     HB_EXPORT hb_dateStrGet( const char * szDate, long * plYear, long * plMonth, long * plDay );
extern char     HB_EXPORT * hb_dateDecStr( char * szDate, long lJulian );
extern long     HB_EXPORT hb_dateEncStr( char * szDate );

#if defined(HB_EXTERN_C)
}
#endif

#endif /* HB_DATE_H_ */
