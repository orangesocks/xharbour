/**********************************************
* tiputils.c
*
* Class oriented Internet protocol library
*
* (C) 2002 Giancarlo Niccolai
* $Id: tiputils.c,v 1.7 2004/04/14 20:59:09 andijahja Exp $
************************************************/

#include "hbapi.h"
#include "hbdate.h"
#include "hbapifs.h"
#include "hbapierr.h"

#ifndef HB_OS_WIN_32
   #include <time.h>
#else
   #include <windows.h>
#endif

#ifndef TIME_ZONE_ID_INVALID
   #define TIME_ZONE_ID_INVALID (DWORD)0xFFFFFFFF
#endif

/************************************************************
* Useful internet timestamp based on RFC822
*/

/* sadly, many strftime windows implementations are broken */
#ifdef HB_OS_WIN_32

HB_FUNC( TIP_TIMESTAMP )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );
   ULONG ulHour = hb_parl(2);
   int nLen;
   TIME_ZONE_INFORMATION tzInfo;
   long lDate, lYear, lMonth, lDay;
   char *days[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
   char *months[] = {
         "Jan", "Feb", "Mar",
         "Apr", "May", "Jun",
         "Jul", "Aug", "Sep",
         "Oct", "Nov", "Dec" };
   char *szRet = (char *) hb_xgrab( 64 );
   SYSTEMTIME st;


   if ( !ulHour )
   {
      ulHour = 0;
   }

   if ( GetTimeZoneInformation( &tzInfo ) == TIME_ZONE_ID_INVALID )
   {
      tzInfo.Bias = 0;
   }
   else
   {
      tzInfo.Bias -= tzInfo.Bias;
   }

   if ( !pDate )
   {
      GetLocalTime( &st );

      sprintf( szRet, "%s, %d %s %d %02d:%02d:%02d %+03d%02d",
            days[ st.wDayOfWeek ], st.wDay, months[ st.wMonth -1],
            st.wYear,
            st.wHour, st.wMinute, st.wSecond,
            tzInfo.Bias/60,
            tzInfo.Bias % 60 > 0 ? - tzInfo.Bias % 60 : tzInfo.Bias % 60 );
   }
   else
   {
      lDate = hb_itemGetDL( pDate );
      hb_dateDecode( lDate, &lYear, &lMonth, &lDay );

      sprintf( szRet, "%s, %d %s %d %02d:%02d:%02d %+03d%02d",
            days[ hb_dateDOW( lYear, lMonth, lDay ) - 1 ], lDay,
            months[ lMonth -1], lYear,
            ulHour / 3600, (ulHour % 3600) / 60, (ulHour % 60),
            tzInfo.Bias/60,
            tzInfo.Bias % 60 > 0 ? - tzInfo.Bias % 60 : tzInfo.Bias % 60 );
   }


   nLen = strlen( szRet );

   if ( nLen < 64 )
   {
      szRet = (char *) hb_xrealloc( szRet, nLen + 1 );
   }
   hb_retclenAdoptRaw( szRet, nLen );

}

#else

HB_FUNC( TIP_TIMESTAMP )
{
   PHB_ITEM pDate = hb_param( 1, HB_IT_DATE );
   ULONG ulHour = hb_parl(2);
   int nLen;
   char szDate[9];
   struct tm tmTime;
   time_t current;

   char *szRet = (char *) hb_xgrab( 64 );

   if ( !ulHour )
   {
      ulHour = 0;
   }


   /* init time structure anyway */
   time( &current );
   #ifdef HB_OS_OS2
   memcpy((void *)&tmTime, (void *)localtime( &current ), sizeof(tmTime));
   #else
   localtime_r( &current , &tmTime );
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

   nLen = strftime( szRet, 64, "%a, %d %b %Y %H:%M:%S %z", &tmTime );

   if ( nLen < 64 )
   {
      szRet = (char *) hb_xrealloc( szRet, nLen + 1 );
   }
   hb_retclenAdoptRaw( szRet, nLen );
}

#endif

/** Detects the mimetype of a given file */

typedef struct tag_mime 
{
   /* Position in stream from which the match begins */
   int pos;
   /* String to match */
   char *pattern;
   /* Mimetype if complete */
   char *mime_type;
   /* following entry to determine a mimetype, relative to current position (or 0) */
   int next;
   /* alternative entry to determine a mimetype, relative to current position (or 0) */
   int alternate;
   /* flags for confrontation */
   short unsigned int flags;
} MIME_ENTRY;

#define MIME_FLAG_TRIMSPACES    0x0001
#define MIME_FLAG_TRIMTABS      0x0002
#define MIME_FLAG_CASEINSENS    0x0004
#define MIME_FLAG_CONTINUE      0x0008
#define MIME_TABLE_SIZE         67

static MIME_ENTRY s_mimeTable[ MIME_TABLE_SIZE ] =
{
   /* Dos/win executable */
   /*  0*/ { 0, "MZ", "application/x-dosexec", 0, 0, 0 },
   
   /* ELF file */
   /*  1*/ { 0, "\177ELF", NULL, 1, 0, 0 },
   /*  2*/ { 4, "\0", NULL, 3, 1, MIME_FLAG_CONTINUE },
   /*  3*/ { 4, "\1", NULL, 2, 1, MIME_FLAG_CONTINUE },
   /*  4*/ { 4, "\2", NULL, 1, 0, MIME_FLAG_CONTINUE },
   /*  5*/ { 5, "\0", NULL, 2, 1, MIME_FLAG_CONTINUE },
   /*  6*/ { 5, "\1", NULL, 1, 0, MIME_FLAG_CONTINUE },
   /*  7*/ { 16, "\0", "application/x-object", 0, 1, MIME_FLAG_CONTINUE },
   /*  8*/ { 16, "\1", "application/x-object", 0, 1, MIME_FLAG_CONTINUE },
   /*  9*/ { 16, "\2", "application/x-executable", 0, 1, MIME_FLAG_CONTINUE },
   /* 10*/ { 16, "\3", "application/x-sharedlib", 0, 1, MIME_FLAG_CONTINUE },
   /* 11*/ { 16, "\4", "application/x-coredump", 0, 0, MIME_FLAG_CONTINUE },
   
   /* Shell script */
   /* 12*/ { 0, "#!/bin/sh", "application/x-shellscript", 0, 0, 0 },
   /* 13*/ { 0, "#! /bin/sh", "application/x-shellscript", 0, 0, 0 },
   /* 14*/ { 0, "#!/bin/csh", "application/x-shellscript", 0, 0, 0 },
   /* 15*/ { 0, "#! /bin/csh", "application/x-shellscript", 0, 0, 0 },
   /* 16*/ { 0, "#!/bin/ksh", "application/x-shellscript", 0, 0, 0 },
   /* 17*/ { 0, "#! /bin/ksh", "application/x-shellscript", 0, 0, 0 },
   /* 18*/ { 0, "#!/bin/tcsh", "application/x-shellscript", 0, 0, 0 },
   /* 19*/ { 0, "#! /bin/tcsh", "application/x-shellscript", 0, 0, 0 },
   /* 20*/ { 0, "#!/usr/local/bin/tcsh", "application/x-shellscript", 0, 0, 0 },
   /* 21*/ { 0, "#! /usr/local/bin/tcsh", "application/x-shellscript", 0, 0, 0 },
   /* 22*/ { 0, "#!/bin/bash", "application/x-shellscript", 0, 0, 0},
   /* 23*/ { 0, "#! /bin/bash", "application/x-shellscript", 0, 0, 0 },
   /* 24*/ { 0, "#!/usr/local/bin/bash", "application/x-shellscript", 0, 0, 0 },
   /* 25*/ { 0, "#! /usr/local/bin/bash", "application/x-shellscript", 0, 0, 0 },

   /* Java object code*/
   /* 26*/ { 0, "\xca\xfe\xba\xbe", "application/java", 0, 0, 0 },
   
   /* Perl */
   /* 27*/ { 0, "#!/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 28*/ { 0, "#! /bin/perl", "application/x-perl", 0, 0, 0 },
   /* 29*/ { 0, "eval \"exec /bin/perl", "application/x-perl", 0, 0, 0 },
   /* 30*/ { 0, "#!/usr/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 31*/ { 0, "#! /usr/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 32*/ { 0, "eval \"exec /usr/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 33*/ { 0, "#!/usr/local/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 34*/ { 0, "#! /usr/local/bin/perl", "application/x-perl", 0, 0, 0 },
   /* 35*/ { 0, "eval \"exec /usr/local/bin/perl", "application/x-perl", 0, 0, 0 },
  
   /* Python */
   /* 36*/ { 0, "#!/bin/python", "application/x-python", 0, 0, 0 },
   /* 37*/ { 0, "#! /bin/python", "application/x-python", 0, 0, 0 },
   /* 38*/ { 0, "eval \"exec /bin/python", "application/x-python", 0, 0, 0 },
   /* 39*/ { 0, "#!/usr/bin/python", "application/x-python", 0, 0, 0 },
   /* 40*/ { 0, "#! /usr/bin/python", "application/x-python", 0, 0, 0 },
   /* 41*/ { 0, "eval \"exec /usr/bin/python", "application/x-python", 0, 0, 0 },
   /* 42*/ { 0, "#!/usr/local/bin/python", "application/x-python", 0, 0, 0 },
   /* 43*/ { 0, "#! /usr/local/bin/python", "application/x-python", 0, 0, 0 },
   /* 44*/ { 0, "eval \"exec /usr/local/bin/python", "application/x-python", 0, 0, 0 }, 

   /* Unix compress (.Z) */
   /* 45*/ { 0, "\037\235", "application/x-compress", 0, 0, 0 },
   
   /* Unix gzip */
   /* 46*/ { 0, "\037\213", "application/x-gzip", 0, 0, 0 },
   
   /* PKzip */
   /* 47*/ { 0, "PK\003\004", "application/x-zip", 0, 0, 0 },
   
   /* xml */
   /* 48*/ { 0, "<?xml", "text/xml", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   
   /* html */
   /* 49*/ { 0, "<html", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   /* 50*/ { 0, "<title", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   /* 51*/ { 0, "<head", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   /* 52*/ { 0, "<body", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   /* 53*/ { 0, "<!--", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS },
   /* 54*/ { 0, "<h1", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   /* 55*/ { 0, "<!doctype html", "text/html", 0, 0, MIME_FLAG_TRIMSPACES | MIME_FLAG_TRIMTABS | MIME_FLAG_CASEINSENS },
   
   /* Postscript */
   /* 56*/ { 0, "%!", "application/postscript", 0, 0, 0 },
   /* 57*/ { 0, "\004%!", "application/postscript", 0, 0, 0 },

   /* PDF */
   /* 58*/ { 0, "%PDF-", "application/pdf", 0, 0, 0 },

   /* DVI */
   /* 59*/ { 0, "\367\002", "application/dvi", 0, 0, 0 },
  
   /* PNG image */
   /* 60*/ { 0, "\x89PNG", "image/png", 0, 0, 0 },
   
   /* XPM image */
   /* 61*/ { 0, "/* XPM", "image/x-xpm", 0, 0, 0 },
   
   /* TIFF image */
   /* 62*/ { 0, "II", "image/tiff", 0, 0, 0 },
   /* 63*/ { 0, "MM", "image/tiff", 0, 0, 0 },
   
   /* GIF image */
   /* 64*/ { 0, "GIF89z", "image/x-compressed-gif", 0, 0, 0 },
   /* 65*/ { 0, "GIF", "image/gif", 0, 0, 0 },
   
   /* JPEG image */
   /* 66*/ { 0, "\xff\xd8", "image/x-compressed-gif", 0, 0, 0 }
};
   
/* Find mime by extension */

typedef struct tag_mime_ext
{
   /* Extension to match */
   char *pattern;
   /* Mimetype if complete */
   char *mime_type;
   /* flags for confrontation */
   short unsigned int flags;
} EXT_MIME_ENTRY;

#define EXT_MIME_TABLE_SIZE 16

static EXT_MIME_ENTRY s_extMimeTable[EXT_MIME_TABLE_SIZE] =
{
   /* Dos/win executable */
   /*  0*/ { "EXE", "application/x-dosexec", MIME_FLAG_CASEINSENS },
   
   /* HTML file */
   /*  1*/ { "HTM", "text/html", MIME_FLAG_CASEINSENS },
   /*  2*/ { "HTML", "text/html", MIME_FLAG_CASEINSENS },

   /* XML file */
   /*  4*/ { "XML", "text/xml", MIME_FLAG_CASEINSENS },
   
   /* text file */
   /*  5*/ { "TXT", "text/txt", MIME_FLAG_CASEINSENS },
   
   /* PDF file */
   /*  6*/ { "pdf", "application/pdf", MIME_FLAG_CASEINSENS },
   
   /* PS file */
   /*  7*/ { "ps", "application/postscript", MIME_FLAG_CASEINSENS },
   
   /* C source */
   /*  7*/ { "c", "text/x-c", MIME_FLAG_CASEINSENS },
   /*  8*/ { "c++", "text/x-c++", MIME_FLAG_CASEINSENS },
   /*  9*/ { "cpp", "text/x-c++", MIME_FLAG_CASEINSENS },
   /* 10*/ { "cxx", "text/x-c++", MIME_FLAG_CASEINSENS },
   /* 11*/ { "h", "text/x-c-header", MIME_FLAG_CASEINSENS },
   /* 12*/ { "hpp", "text/x-c++-header", MIME_FLAG_CASEINSENS },
   /* 13*/ { "hxx", "text/x-c++-header", MIME_FLAG_CASEINSENS },
   
   /* Java */
   /* 14*/ { "class", "application/java", 0 }, // case sensitive!
   /* 15*/ { "java", "text/java", 0 }
};


static char *s_findExtMimeType( char *cExt)
{
   int iCount;
   
   for ( iCount = 0; iCount < EXT_MIME_TABLE_SIZE; iCount ++ )
   {
      if ( s_extMimeTable[iCount].flags == MIME_FLAG_CASEINSENS )
      {
         if ( hb_stricmp( cExt, s_extMimeTable[iCount].pattern ) == 0)
         {
            return s_extMimeTable[iCount].mime_type;
         }
      }
      else
      {
         if ( strcmp( cExt, s_extMimeTable[iCount].pattern ) == 0)
         {
            return s_extMimeTable[iCount].mime_type;
         }
      }
   }
   
   return NULL;
}



static char *s_findMimeStringInTree( char *cData, int iLen, int iElem )
{
   MIME_ENTRY *elem = s_mimeTable + iElem;
   int iPos = elem->pos;
   int iDataLen = strlen(  elem->pattern );
       
   // allow \0 to be used for matches           
   if ( iDataLen == 0 )
   {
      iDataLen = 1;
   }
   
   // trim spaces if required
   while ( iPos < iLen && 
      ( (( elem->flags & MIME_FLAG_TRIMSPACES ) == MIME_FLAG_TRIMSPACES && cData[iPos] == ' ') ||
         (( elem->flags & MIME_FLAG_TRIMTABS ) == MIME_FLAG_TRIMSPACES && cData[iPos] == '\t') ) ) 
   {
      iPos ++;
   }

   if ( (iPos < iLen) && (iLen - iPos >= iDataLen) )
   {
      if ( (elem->flags & MIME_FLAG_CASEINSENS) == MIME_FLAG_CASEINSENS )
      {
         if ( (*elem->pattern == 0 && cData[iPos] == 0) || hb_strnicmp( cData + iPos, elem->pattern, iDataLen ) == 0)
         {
            // is this the begin of a match tree?
            if ( elem->next != 0 )
            { 
               return s_findMimeStringInTree( cData, iLen, iElem + elem->next );
            }
            else 
            {
               return elem->mime_type;
            }
         }
      }
      else
      {
         if ( (*elem->pattern == 0 && cData[iPos] == 0) || strncmp( cData + iPos, elem->pattern, iDataLen ) == 0)
         {
            if ( elem->next != 0 )
            { 
               return s_findMimeStringInTree( cData, iLen, iElem + elem->next );
            }
            else 
            {
               return elem->mime_type;
            }
         }
      }
   }
   
   // match failed!
   if ( elem->alternate != 0 )
   {
      return s_findMimeStringInTree( cData, iLen, iElem + elem->alternate );
   }

   // total giveup   
   return NULL;
} 


static char *s_findStringMimeType( char *cData, int iLen )
{
   int iCount;
   BOOL bFormFeed;
   
   for ( iCount = 0; iCount < MIME_TABLE_SIZE; iCount ++ )
   {
      MIME_ENTRY *elem = s_mimeTable + iCount;
      int iPos = elem->pos;
      int iDataLen = strlen(  elem->pattern );
            
      if ( (elem->flags & MIME_FLAG_CONTINUE) == MIME_FLAG_CONTINUE )
      {
         continue;
      }
      
      // trim spaces if required
      while ( iPos < iLen && 
         ( (( elem->flags & MIME_FLAG_TRIMSPACES ) == MIME_FLAG_TRIMSPACES && cData[iPos] == ' ') ||
           (( elem->flags & MIME_FLAG_TRIMTABS ) == MIME_FLAG_TRIMSPACES && cData[iPos] == '\t') ) ) 
      {
         iPos ++;
      }

      if ( iPos >= iLen )
      {
         continue;
      }
      
      if ( iLen - iPos < iDataLen )
      {
         continue;
      }
      
      if ( (elem->flags & MIME_FLAG_CASEINSENS) == MIME_FLAG_CASEINSENS )
      {
         if ( (*elem->pattern == 0 && cData[iPos] == 0) || hb_strnicmp( cData + iPos, elem->pattern, iDataLen ) == 0)
         {
            // is this the begin of a match tree?
            if ( elem->next != 0 )
            { 
               return s_findMimeStringInTree( cData, iLen, iCount + elem->next );
            }
            else 
            {
               return elem->mime_type;
            }
         }
      }
      else
      {
         if ( (*elem->pattern == 0 && cData[iPos] == 0) || strncmp( cData + iPos, elem->pattern, iDataLen ) == 0)
         {
            if ( elem->next != 0 )
            { 
               return s_findMimeStringInTree( cData, iLen, iCount + elem->next );
            }
            else 
            {
               return elem->mime_type;
            }
         }
      }
   }
   
   // Failure; let's see if it's a text/plain.
   bFormFeed = FALSE;
   iCount = 0;
   while ( iCount < iLen )
   {
      // form feed?
      if ( cData[ iCount ] == '\x0C' )
      {
         bFormFeed = TRUE;
      }
      // esc sequence?
      else if ( cData[iCount] == '\x1B' )
      {
         bFormFeed = TRUE;
         iCount ++;
         if ( cData[iCount] <= 27 )
         {
            iCount ++;
         }
         if ( cData[iCount] <= 27 )
         {
            iCount ++;
         }
      }
      else if ( 
         (cData[iCount] < 27 && cData[iCount] != '\t' && cData[iCount] != '\n' && cData[iCount] == '\r') || 
            cData[iCount] == '\xFF')
      {
         // not an ASCII file, we surrender
         return NULL;
      }
      
      iCount++;
   }
   
   if ( bFormFeed )
   {
      // we have escape sequences, seems a PRN/terminal file
      return "application/remote-printing";
   }
   
   return "text/plain";
} 


static char *s_findFileMimeType( FHANDLE fileIn )
{
   char buf[512];
   int iLen;
   ULONG ulPos;
   
   ulPos = hb_fsSeek( fileIn, 0, SEEK_CUR );
   hb_fsSeek( fileIn, 0, SEEK_SET );
   iLen = hb_fsRead( fileIn, buf, 512 );
   
   if ( iLen > 0 )
   {
      hb_fsSeek( fileIn, ulPos, SEEK_SET );
      return s_findStringMimeType( buf, iLen );
   }
   
   return NULL;
}



HB_FUNC( TIP_FILEMIMETYPE )
{
   PHB_ITEM pFile = hb_param( 1, HB_IT_STRING | HB_IT_NUMERIC );
   char *ext_type = NULL;
   char *magic_type = NULL;
   FHANDLE fileIn;
   
   
   if ( pFile == NULL )
   {
      hb_errRT_BASE_SubstR( EG_ARG, 0, NULL, "TIP_FILEMIMETYPE", 
         1, hb_paramError( 1 ) );
      return;
   }
   
   if ( HB_IS_STRING( pFile ) )
   {
      // decode the extension
      char *fname = hb_itemGetCPtr( pFile );
      int iPos = strlen( fname )-1;
      
      while ( iPos >= 0 && fname[iPos] != '.' ) 
      {
         iPos--;  
      }
      
      if ( iPos > 0 )
      {
         ext_type = s_findExtMimeType( fname + iPos + 1 );
      }
      
      // try to open the file
      fileIn = hb_fsOpen( fname, FO_READ );
      if ( hb_fsError() == 0 )
      {
         magic_type = s_findFileMimeType( fileIn );
      }    
   }
   else 
   {
      fileIn = (FHANDLE) hb_itemGetNL( pFile );
      magic_type = s_findFileMimeType( fileIn );
   }
      
   if ( magic_type == NULL )
   {
      if ( ext_type != NULL )
      {
         hb_retc( ext_type );
      }
      else
      {
         hb_retc( "unknown" ); // it's a valid MIME type
      }
   }
   else 
   {
      hb_retc( magic_type );
   }     
}


HB_FUNC( TIP_MIMETYPE )
{
   PHB_ITEM pData = hb_param( 1, HB_IT_STRING );
   char *magic_type = NULL;
   char *cData;
   ULONG ulLen;   
   
   if ( pData == NULL )
   {
      hb_errRT_BASE_SubstR( EG_ARG, 0, NULL, "TIP_MIMETYPE", 
         1, hb_paramError( 1 ) );
      return;
   }
   
   ulLen = hb_itemGetCLen( pData );
   cData = hb_itemGetCPtr( pData );
   
   magic_type = s_findStringMimeType( cData, ulLen );
   
   if ( magic_type == NULL )
   {
      hb_retc( "unknown" );
   }     
   else
   {
      hb_retc( magic_type );
   }
}
