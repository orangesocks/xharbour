/**********************************************
* tiputils.c
*
* Class oriented Internet protocol library
*
* (C) 2002 Giancarlo Niccolai
* $Id: tiputils.c,v 1.2 2003/12/01 03:41:03 ronpinkas Exp $
************************************************/

#include "hbapi.h"
#include <time.h>

#if defined _MSC_VER || defined __BORLANDC__
   #include <windows.h>
#endif

/************************************************************
* Useful internet timestamp based on RFC822
*/

HB_FUNC( TIP_TIMESTAMP )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );
   ULONG ulHour = hb_parl(2);
   int nLen;
   char szDate[9];
   struct tm tmTime;

   char *szRet = (char *) hb_xgrab( 180 );

   if ( !ulHour )
   {
      ulHour = 0;
   }

   #if defined( HB_OS_WIN_32 )
   if ( !pDate )
   {
      SYSTEMTIME st;
      GetSystemTime( &st );

      tmTime.tm_year = st.wYear - 1900;
      tmTime.tm_mon = st.wMonth - 1;
      tmTime.tm_mday = st.wDay;
      tmTime.tm_wday = st.wDayOfWeek;
      tmTime.tm_hour = st.wHour;
      tmTime.tm_min = st.wMinute;
      tmTime.tm_sec = st.wSecond;
   }

   /* Signal isdst not available */
   tmTime.tm_isdst = -1;

   #else
   {
      time_t current;

      /* init time structure anyway */
      time( &current );
      localtime_r( &current , &tmTime );
   }
   #endif

   if ( pDate )
   {
      hb_itemGetDS( pDate, szDate );

      tmTime.tm_year = (
         (szDate[0] - '0') * 1000 +
         (szDate[1] - '0') * 100 +
         (szDate[2] - '0') * 10 +
         (szDate[3] - '0') ) -1900;

      tmTime.tm_mon = (
         (szDate[4] - '0') * 10 +
         (szDate[5] - '0') ) -1;

      tmTime.tm_mday =
         (szDate[6] - '0') * 10 +
         (szDate[7] - '0');

      tmTime.tm_hour = ulHour / 3600;
      tmTime.tm_min = (ulHour % 3600) / 60;
      tmTime.tm_sec = (ulHour % 60);
   }

   nLen = strftime( szRet, 180, "%a, %d %b %Y %H:%M:%S %z", &tmTime );
   if ( nLen < 180 )
   {
      szRet = (char *) hb_xrealloc( szRet, nLen + 1 );
   }
   hb_retclenAdoptRaw( szRet, nLen );
}

