/*
 * $Id: ppcore.c,v 1.64 2003/04/22 22:34:32 ronpinkas Exp $
 */

/*
 * Harbour Project source code:
 * Preprocessor core module
 *
 * Copyright 1999 Alexander S.Kresin <alex@belacy.belgorod.su>
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
 * The following parts are Copyright of the individual authors.
 * www - http://www.harbour-project.org
 *
 * Copyright 1999-2001 Viktor Szakats <viktor.szakats@syenar.hu>
 *    __DATE__, __TIME__, __HB_MAIN__ support
 *
 * Copyright 2000 Ron Pinkas <Ron@Profit-Master.com>
 *
 * hb_pp_SetRules() and related code for supportting
 * replaceable rules with -u switch
 *
 * See doc/license.txt for licensing terms.
 *
 */

//#define DEBUG_MARKERS

/*
 * Avoid tracing in preprocessor/compiler.
 */
#if ! defined(HB_TRACE_UTILS)
   #if defined(HB_TRACE_LEVEL)
      #undef HB_TRACE_LEVEL
   #endif
#endif

// For hb_ppPlatform()
#define INCL_DOSMISC

#define HB_OS_WIN_32_USED

#include "hbapi.h"
#include "hbver.h"

#if defined(HB_OS_WIN_32)

   #include <ctype.h>
   #ifndef VER_PLATFORM_WIN32_WINDOWS
      #define VER_PLATFORM_WIN32_WINDOWS 1
   #endif
   #ifndef VER_PLATFORM_WIN32_CE
      #define VER_PLATFORM_WIN32_CE 3
   #endif

#elif defined(HB_OS_UNIX)

   #include <sys/utsname.h>

#endif

#if defined( OS_UNIX_COMPATIBLE )
   #include <sys/timeb.h>
#else
   #include <sys\timeb.h>
#endif

#include <time.h>
#include <errno.h>

#include "hbpp.h"
#include "hbcomp.h"

int hb_pp_ParseDefine( char * );                         /* Process #define directive */

static COMMANDS * AddCommand( char * );                  /* Add new #command to an array  */
static COMMANDS * AddTranslate( char * );                /* Add new #translate to an array  */
static DEFINES *  DefSearch( char *, BOOL * );
static COMMANDS * ComSearch( char *, COMMANDS * );
static COMMANDS * TraSearch( char *, COMMANDS * );

static int    ParseUndef( char * );                        /* Process #undef directive */
static int    ParseIfdef( char *, int );                   /* Process #ifdef directive */
static void   ParseCommand( char *, BOOL, BOOL, BOOL );    /* Process #command or #translate directive */
static void   ConvertPatterns( char *, int, char *, int ); /* Converting result pattern in #command and #translate */
static int    WorkDefine( char **, char *, DEFINES * );    /* Replace fragment of code with a #defined result text */
static int    WorkPseudoF( char **, char *, DEFINES * );   /* Replace pseudofunction with a #defined result text */
static int    WorkCommand( char *, char *, COMMANDS * );
static int    WorkTranslate( char *, char *, COMMANDS *, int * );
static int    CommandStuff( char *, char *, char *, int *, BOOL, BOOL );
static int    RemoveSlash( char * );
static int    WorkMarkers( char **, char **, char *, int *, BOOL );
static int    getExpReal( char *, char **, BOOL, int, BOOL );
static BOOL   isExpres( char *, BOOL );
static BOOL   TestOptional( char *, char * );
static BOOL   CheckOptional( char *, char *, char *, int *, BOOL, BOOL );
static void   SkipOptional( char ** );

static void   SearnRep( char *, char *, int, char *, int * );
static int    ReplacePattern( char, char *, int, char *, int );
static void   pp_rQuotes( char *, char * );
static int    md_strAt( char *, int, char *, BOOL, BOOL, BOOL, BOOL );
static char * PrevSquare( char * , char *, int * );
static int    IsInStr( char, char * );
static int    stroncpy( char *, char *, int );
static int    strincpy( char *, char * );
static BOOL   truncmp( char **, char **, BOOL );
static BOOL   strincmp( char *, char **, BOOL );
static int    strotrim( char *, BOOL ); /* Ron Pinkas 2001-02-14 added 2nd parameter */
static int    NextWord( char **, char *, BOOL );
static int    NextName( char **, char * );
static int    NextParm( char **, char * );
static BOOL   OpenInclude( char *, HB_PATHNAMES *, PHB_FNAME, BOOL bStandardOnly, char * );
static BOOL   IsIdentifier( char *szProspect );
static int    NextStopper( char ** sSource, char * sDest );

int hb_pp_NextToken( char** pLine );

#define ISID( c )  ( isalpha( ( int ) c ) || ( c ) == '_' || ( c ) > 0x7E )
#define ISNAME( c )  ( isalnum( ( int ) c ) || ( c ) == '_' || ( c ) > 0x7E )
#define MAX_NAME     255
#define MAX_EXP      2048
#define PATTERN_SIZE HB_PP_STR_SIZE
#define MAX_CICLES   256

#define IT_EXPR       1
#define IT_ID         2
#define IT_COMMA      3
#define IT_ID_OR_EXPR 4

#define HB_PP_MAX_INCLUDES FOPEN_MAX - 5 - 1

/* Ron Pinkas added 2000-01-24 */
#define IS_2CHAR_OPERATOR( p ) ( p[0] && p[1] && ( strncmp( p, ":=", 2 ) == 0 || \
                                                   strncmp( p, "+=", 2 ) == 0 || \
                                                   strncmp( p, "-=", 2 ) == 0 || \
                                                   strncmp( p, "*=", 2 ) == 0 || \
                                                   strncmp( p, "/=", 2 ) == 0 || \
                                                   strncmp( p, "^=", 2 ) == 0 || \
                                                   strncmp( p, "==", 2 ) == 0 || \
                                                   strncmp( p, "<>", 2 ) == 0 || \
                                                   strncmp( p, "<=", 2 ) == 0 || \
                                                   strncmp( p, ">=", 2 ) == 0 || \
                                                   strncmp( p, "++", 2 ) == 0 || \
                                                   strncmp( p, "--", 2 ) == 0 || \
                                                   strncmp( p, "->", 2 ) == 0      ) )
/* END, Ron Pinkas added 2000-01-24 */


static int  s_kolAddDefs = 0;
static int  s_kolAddComs = 0;
static int  s_kolAddTras = 0;
static int  s_ParseState;
static int  s_maxCondCompile;
static int  s_aIsRepeate[ 5 ];
static int  s_Repeate;
static BOOL s_bReplacePat = TRUE;
static int  s_numBrackets;
static char s_groupchar;
static char s_prevchar;

int *      hb_pp_aCondCompile = NULL;
int        hb_pp_nCondCompile = 0;

char *     hb_pp_STD_CH = NULL;

/* Ron Pinkas added 2000-11-21 */
static BOOL s_bArray = FALSE;

static char s_sToken[2048];

#if defined(__WATCOMC__)
extern BOOL hb_pp_bInline;
extern int hb_pp_LastOutLine;
#endif

/* Table with parse errors */
char * hb_pp_szErrors[] =
{
   "Can\'t open #include file: \'%s\'; %s",
   "#else does not match #ifdef",
   "#endif does not match #ifdef",
   "Bad filename in #include",
   "#define without parameters",
   "Missing => in #translate/#command \'%s\' [%s]'",
   "Error in pattern definition",
   "Cycled #define",
   "Invalid name follows #: \'%s\'",
   "\'%s\'",
   "Memory allocation error",
   "Memory reallocation error",
   "Freeing a NULL memory pointer",
   "Value out of range in #pragma directive",
   "Can\'t open command definitions file: \'%s\'",
   "Invalid command definitions file name: \'%s\'",
   "Too many nested #includes, can\'t open: \'%s\'",
   "Input buffer overflow",
   "Label missing in #define \'%s\'.",
   "Too many match markers in #translate or #command"
};

/* Table with warnings */
char * hb_pp_szWarnings[] =
{
   "1Redefinition or duplicate definition of #define %s",
   "1No directives in command definitions file"
};

void hb_pp_SetRules( HB_INCLUDE_FUNC_PTR hb_compInclude, BOOL hb_comp_bQuiet )
{
   static COMMANDS sC___IIF = { 0, "IF", "([\1A00],[\1B00],[\1C00] )", "IIF(\1A00,\1B00,\1C00 )", NULL };

   HB_TRACE(HB_TR_DEBUG, ("hb_pp_SetRules()"));

   if( hb_pp_STD_CH )
   {
      if( *hb_pp_STD_CH > ' ' )
      {
         hb_comp_pFileName = hb_fsFNameSplit( hb_pp_STD_CH );

         if( hb_comp_pFileName->szName )
         {
            char szFileName[ _POSIX_PATH_MAX ];

            if( ! hb_comp_pFileName->szExtension )
               hb_comp_pFileName->szExtension = ".ch";

            hb_fsFNameMerge( szFileName, hb_comp_pFileName );

            if( (* hb_compInclude)( szFileName, hb_comp_pIncludePath ) )
            {
               //printf( "Loading Standard Rules from: \'%s\'\n", szFileName );

               hb_pp_Init();

               hb_pp_ReadRules();

               /*
               {
                  COMMANDS * stcmd;
                  DEFINES * stdef;

                  stcmd = hb_pp_topCommand;
                  while ( stcmd )
                  {
                      printf( "Command: %s Pattern: %s\n", stcmd->name, stcmd->mpatt );
                      stcmd = stcmd->last;
                  }

                  stcmd = hb_pp_topTranslate;
                  while ( stcmd )
                  {
                      printf( "Translate: %s \nPattern: %s\n", stcmd->name, stcmd->mpatt );
                      stcmd = stcmd->last;
                  }

                  stdef = hb_pp_topDefine;
                  while ( stdef && s_kolAddDefs > 3 )
                  {
                      printf( "Define: %s Value: %s\n", stdef->name, stdef->value );
                      stdef = stdef->last;
                      s_kolAddDefs--;
                  }
               }
               */

               if ( s_kolAddComs || s_kolAddTras || s_kolAddDefs > 3 )
               {
                  if( ! hb_comp_bQuiet )
                  {
                     printf( "Loaded: %i Commands, %i Translates, %i Defines from: %s\n", s_kolAddComs, s_kolAddTras, s_kolAddDefs - 3, szFileName );
                  }
               }
               else
               {
                  hb_compGenWarning( hb_pp_szWarnings, 'I', HB_PP_WARN_NO_DIRECTIVES, NULL /*szFileName*/, NULL );
               }

               fclose( hb_comp_files.pLast->handle );
               hb_xfree( hb_comp_files.pLast->pBuffer );
               hb_xfree( hb_comp_files.pLast );
               hb_comp_files.pLast = NULL;
               hb_comp_files.iFiles = 0;

               hb_xfree( ( void * ) hb_comp_pFileName );
               hb_comp_pFileName = NULL;

               s_kolAddComs = 0;
               s_kolAddTras = 0;
               s_kolAddDefs = 0;
            }
            else
            {
               hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_CANNOT_OPEN_RULES, szFileName, NULL );
            }
         }
         else
         {
            hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_BAD_RULES_FILE_NAME, hb_pp_STD_CH, NULL );
         }
      }
      else
      {
         if( ! hb_comp_bQuiet )
         {
            printf( "Standard command definitions excluded.\n" );
         }

         hb_pp_Init();
      }
   }
   else
   {
      hb_pp_Table();
      hb_pp_Init();
   }

   sC___IIF.last = hb_pp_topCommand;
   hb_pp_topCommand = &sC___IIF;
}

void hb_pp_Free( void )
{
   DEFINES * stdef;
   COMMANDS * stcmd;

   HB_TRACE(HB_TR_DEBUG, ("hb_pp_Free()"));

   while( s_kolAddDefs )
   {
      stdef = hb_pp_topDefine;
      if( stdef->pars ) hb_xfree( stdef->pars );
      if( stdef->value ) hb_xfree( stdef->value );
      if( stdef->name ) hb_xfree( stdef->name );
      hb_pp_topDefine = stdef->last;
      hb_xfree( stdef );
      s_kolAddDefs--;
   }
   while( s_kolAddComs )
   {
      stcmd = hb_pp_topCommand;
      if( stcmd->mpatt ) hb_xfree( stcmd->mpatt );
      if( stcmd->value ) hb_xfree( stcmd->value );
      hb_xfree( stcmd->name );
      hb_pp_topCommand = stcmd->last;
      hb_xfree( stcmd );
      s_kolAddComs--;
   }
   while( s_kolAddTras )
   {
      stcmd = hb_pp_topTranslate;
      if( stcmd->mpatt ) hb_xfree( stcmd->mpatt );
      if( stcmd->value ) hb_xfree( stcmd->value );
      hb_xfree( stcmd->name );
      hb_pp_topTranslate = stcmd->last;
      hb_xfree( stcmd );
      s_kolAddTras--;
   }
}

char * hb_ppPlatform( void )
{
   char * pszPlatform;

   HB_TRACE(HB_TR_DEBUG, ("hb_verPlatform()"));

   /* NOTE: Must be larger than 128, which is the maximum size of
            osVer.szCSDVersion (Win32). [vszakats] */
   pszPlatform = ( char * ) hb_xgrab( 256 );

#if defined(HB_OS_DOS)

   {
      union REGS regs;

      regs.h.ah = 0x30;
      HB_DOS_INT86( 0x21, &regs, &regs );

      sprintf( pszPlatform, "DOS %d.%02d", regs.h.al, regs.h.ah );

      /* Host OS detection: Windows 2.x, 3.x, 95/98 */

      {
         regs.HB_XREGS.ax = 0x1600;
         HB_DOS_INT86( 0x2F, &regs, &regs );

         if( regs.h.al != 0x00 && regs.h.al != 0x80 )
         {
            char szHost[ 128 ];

            if( regs.h.al == 0x01 || regs.h.al == 0xFF )
               sprintf( szHost, " (Windows 2.x)" );
            else
               sprintf( szHost, " (Windows %d.%02d)", regs.h.al, regs.h.ah );

            strcat( pszPlatform, szHost );
         }
      }

      /* Host OS detection: Windows NT/2000 */

      {
         regs.HB_XREGS.ax = 0x3306;
         HB_DOS_INT86( 0x21, &regs, &regs );

         if( regs.HB_XREGS.bx == 0x3205 )
            strcat( pszPlatform, " (Windows NT/2000)" );
      }

      /* Host OS detection: OS/2 */

      {
         regs.h.ah = 0x30;
         HB_DOS_INT86( 0x21, &regs, &regs );

         if( regs.h.al >= 10 )
         {
            char szHost[ 128 ];

            if( regs.h.al == 20 && regs.h.ah > 20 )
               sprintf( szHost, " (OS/2 %d.%02d)", regs.h.ah / 10, regs.h.ah % 10 );
            else
               sprintf( szHost, " (OS/2 %d.%02d)", regs.h.al / 10, regs.h.ah );

            strcat( pszPlatform, szHost );
         }
      }
   }

#elif defined(HB_OS_OS2)

   {
      unsigned long aulQSV[ QSV_MAX ] = { 0 };
      APIRET rc;

      rc = DosQuerySysInfo( 1L, QSV_MAX, ( void * ) aulQSV, sizeof( ULONG ) * QSV_MAX );

      if( rc == 0 )
      {
         /* is this OS/2 2.x ? */
         if( aulQSV[ QSV_VERSION_MINOR - 1 ] < 30 )
         {
            sprintf( pszPlatform, "OS/2 %ld.%02ld",
               aulQSV[ QSV_VERSION_MAJOR - 1 ] / 10,
               aulQSV[ QSV_VERSION_MINOR - 1 ] );
         }
         else
            sprintf( pszPlatform, "OS/2 %2.2f",
               ( float ) aulQSV[ QSV_VERSION_MINOR - 1 ] / 10 );
      }
      else
         sprintf( pszPlatform, "OS/2" );
   }

#elif defined(HB_OS_WIN_32)

   {
      OSVERSIONINFO osVer;

      osVer.dwOSVersionInfoSize = sizeof( osVer );

      if( GetVersionEx( &osVer ) )
      {
         char * pszName = "Windows";

         switch( osVer.dwPlatformId )
         {
            case VER_PLATFORM_WIN32_WINDOWS:

               if( osVer.dwMajorVersion == 4 && osVer.dwMinorVersion < 10 )
                  pszName = "Windows 95";
               else if( osVer.dwMajorVersion == 4 && osVer.dwMinorVersion == 10 )
                  pszName = "Windows 98";
               else
                  pszName = "Windows ME";

               break;

            case VER_PLATFORM_WIN32_NT:

               if( osVer.dwMajorVersion == 5 && osVer.dwMinorVersion == 1 )
                  pszName = "Windows XP";
               else if( osVer.dwMajorVersion == 5 )
                  pszName = "Windows 2000";
               else
                  pszName = "Windows NT";

               break;

            case VER_PLATFORM_WIN32s:
               pszName = "Windows 32s";
               break;

            case VER_PLATFORM_WIN32_CE:
               pszName = "Windows CE";
               break;
         }

         sprintf( pszPlatform, "%s %lu.%02lu.%04d",
            pszName,
            ( ULONG ) osVer.dwMajorVersion,
            ( ULONG ) osVer.dwMinorVersion,
            ( USHORT ) LOWORD( osVer.dwBuildNumber ) );

         /* Add service pack/other info */

         if( osVer.szCSDVersion )
         {
            int i;

            /* Skip the leading spaces (Win95B, Win98) */
            for( i = 0; osVer.szCSDVersion[ i ] != '\0' && isspace( ( int ) osVer.szCSDVersion[ i ] ); i++ );

            if( osVer.szCSDVersion[ i ] != '\0' )
            {
               strcat( pszPlatform, " " );
               strcat( pszPlatform, osVer.szCSDVersion + i );
            }
         }
      }
      else
         sprintf( pszPlatform, "Windows" );
   }

#elif defined(HB_OS_UNIX)

   {
      struct utsname un;

      uname( &un );

      sprintf( pszPlatform, "%s %s", un.sysname, un.release );
   }

#elif defined(HB_OS_MAC)

   {
      strcpy( pszPlatform, "MacOS compatible" );
   }

#else

   {
      strcpy( pszPlatform, "(unknown)" );
   }

#endif

   return pszPlatform;
}

void hb_pp_Init( void )
{
   HB_TRACE(HB_TR_DEBUG, ("hb_pp_Init()"));

   hb_pp_Free();

   s_ParseState = 0;
   s_maxCondCompile = 5;
   s_bReplacePat = TRUE;
   s_prevchar = 'A';

   if( !hb_pp_aCondCompile )
       hb_pp_aCondCompile = ( int * ) hb_xgrab( sizeof( int ) * 5 );

   hb_pp_nCondCompile = 0;

   {
      char sOS[64];
      char sVer[64];
      char * szPlatform = hb_ppPlatform();
      char * pSpace = strchr( szPlatform, ' ' );

      sOS[0] = 0;
      sVer[0] = '"';
      sVer[1] = 0;

      strcat( (char *) sOS, "__PLATFORM__" );

      if( pSpace )
      {
         strncat( (char *) sOS, szPlatform, pSpace - szPlatform );
         strcat( (char *) sVer, pSpace + 1 );
         strcat( (char *) sVer, "\"" );
      }
      else
      {
         strcat( (char *) sOS, szPlatform );
         strcat( (char *) sVer, "\"" );
      }

      hb_pp_AddDefine( (char *) sOS, (char *) sVer );

      hb_xfree( szPlatform );
   }

   {
      char szResult[ 6 ];
      USHORT usHarbour = ( 256 * HB_VER_MAJOR ) + HB_VER_MINOR;

      /*
        This updates __HARBOUR__ on every change of HB_VER_MAJOR / HB_VER_MINOR
        HIBYTE is the HB_VER_MAJOR value and the LOBYTE is the HB_VER_MINOR value.

        The check below is to ensure that __HARBOUR__ gets the
        value of 1 by default
      */
      sprintf( szResult, "%05d", ( usHarbour ? usHarbour : 1 ) );
      hb_pp_AddDefine( "__HARBOUR__", szResult );
      hb_pp_AddDefine( "__XHARBOUR__", szResult );
   }

   {
      char szResult[ 11 ];
      time_t t;
      struct tm * oTime;

      time( &t );
      oTime = localtime( &t );

      sprintf( szResult, "\"%04d%02d%02d\"", oTime->tm_year + 1900, oTime->tm_mon + 1, oTime->tm_mday );
      hb_pp_AddDefine( "__DATE__", szResult );

      sprintf( szResult, "\"%02d:%02d:%02d\"", oTime->tm_hour, oTime->tm_min, oTime->tm_sec );
      hb_pp_AddDefine( "__TIME__", szResult );
   }

#ifdef HARBOUR_START_PROCEDURE
   hb_pp_AddDefine( "__HB_MAIN__", HARBOUR_START_PROCEDURE );
#endif
}

/* Table with parse warnings */
/* NOTE: The first character stores the warning's level that triggers this
 * warning. The warning's level is set by -w<n> command line option.
 */

int hb_pp_ParseDirective( char * sLine )
{
  char sDirective[ MAX_NAME ];
  char szInclude[ _POSIX_PATH_MAX ];
  int i;

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_ParseDirective(%s)", sLine));

  i = NextName( &sLine, sDirective );
  hb_strupr( sDirective );

  HB_SKIPTABSPACES(sLine);

  if( i == 4 && memcmp( sDirective, "ELSE", 4 ) == 0 )
    {     /* ---  #else  --- */
      if( hb_pp_nCondCompile == 0 )
        hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_DIRECTIVE_ELSE, NULL, NULL );
      else if( hb_pp_nCondCompile == 1 || hb_pp_aCondCompile[hb_pp_nCondCompile-2] )
        hb_pp_aCondCompile[hb_pp_nCondCompile-1] = 1 - hb_pp_aCondCompile[hb_pp_nCondCompile-1];
    }

  else if( i >= 4 && i <= 5 && memcmp( sDirective, "ENDIF", i ) == 0 )
    {     /* --- #endif  --- */
      if( hb_pp_nCondCompile == 0 )
        hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_DIRECTIVE_ENDIF, NULL, NULL );
      else hb_pp_nCondCompile--;
    }

  else if( i >= 4 && i <= 5 && memcmp( sDirective, "IFDEF", i ) == 0 )
    ParseIfdef( sLine, TRUE ); /* --- #ifdef  --- */

  else if( i >= 4 && i <= 6 && memcmp( sDirective, "IFNDEF", i ) == 0 )
    ParseIfdef( sLine, FALSE ); /* --- #ifndef  --- */

  else if( hb_pp_nCondCompile==0 || hb_pp_aCondCompile[hb_pp_nCondCompile-1])
    {
      if( i >= 4 && i <= 7 && memcmp( sDirective, "INCLUDE", i ) == 0 )
        {    /* --- #include --- */
          char cDelimChar;

          if( *sLine != '\"' && *sLine != '\'' && *sLine != '<' )
            hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_WRONG_NAME, NULL, NULL );

          cDelimChar = *sLine;
          if( cDelimChar == '<' )
            cDelimChar = '>';
          else if( cDelimChar == '`' )
            cDelimChar = '\'';

          sLine++; i = 0;
          while( *(sLine+i) != '\0' && *(sLine+i) != cDelimChar ) i++;
          if( *(sLine+i) != cDelimChar )
            hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_WRONG_NAME, NULL, NULL );
          *(sLine+i) = '\0';

          if( !OpenInclude( sLine, hb_comp_pIncludePath, hb_comp_pFileName, ( cDelimChar == '>' ), szInclude ) )
          {
            if( errno == 0 || errno == EMFILE )
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_TOO_MANY_INCLUDES, sLine, NULL );
            else
            {
            #if defined(__CYGWIN__) || defined(__IBMCPP__) || defined(__LCC__)
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_CANNOT_OPEN, sLine, "" );
            #else
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_CANNOT_OPEN, sLine, sys_errlist[ errno ] );
            #endif
            }
          }
        }

      else if( i >= 4 && i <= 6 && memcmp( sDirective, "DEFINE", i ) == 0 )
        hb_pp_ParseDefine( sLine );   /* --- #define  --- */

      else if( i >= 4 && i <= 5 && memcmp( sDirective, "UNDEF", i ) == 0 )
        ParseUndef( sLine );    /* --- #undef  --- */

      else if( (i >= 4 && i <= 7 && memcmp( sDirective, "COMMAND", i ) == 0) ||
               (i >= 4 && i <= 8 && memcmp( sDirective, "XCOMMAND", i ) == 0) )
                                /* --- #command  --- */
        ParseCommand( sLine, sDirective[0] == 'X' ? TRUE : FALSE, TRUE, FALSE );

      else if( (i >= 4 && i <= 9 && memcmp( sDirective, "UNCOMMAND", i ) == 0) ||
               (i >= 4 && i <= 10 && memcmp( sDirective, "XUNCOMMAND", i ) == 0) )
                                /* --- #uncommand  --- */
        ParseCommand( sLine, sDirective[0] == 'X' ? TRUE : FALSE, TRUE, TRUE );

      else if( (i >= 4 && i <= 9 && memcmp( sDirective, "TRANSLATE", i ) == 0) ||
               (i >= 4 && i <= 10 && memcmp( sDirective, "XTRANSLATE", i ) == 0) )
                                /* --- #translate  --- */
        ParseCommand( sLine, sDirective[0] == 'X' ? TRUE : FALSE, FALSE, FALSE );

      else if( (i >= 4 && i <= 11 && memcmp( sDirective, "UNTRANSLATE", i ) == 0) ||
               (i >= 4 && i <= 12 && memcmp( sDirective, "XUNTRANSLATE", i ) == 0) )
                                /* --- #untranslate  --- */
        ParseCommand( sLine, sDirective[0] == 'X' ? TRUE : FALSE, FALSE, TRUE );

      else if( i >= 4 && i <= 6 && memcmp( sDirective, "STDOUT", i ) == 0 )
        printf( "%s\n", sLine ); /* --- #stdout  --- */

      else if( i >= 4 && i <= 5 && memcmp( sDirective, "ERROR", i ) == 0 )
        /* --- #error  --- */
        hb_compGenError( hb_pp_szErrors, 'E', HB_PP_ERR_EXPLICIT, sLine, NULL );

      else if( i == 4 && memcmp( sDirective, "LINE", 4 ) == 0 )
        return -1;

      else if( i == 6 && memcmp( sDirective, "PRAGMA", 6 ) == 0 )
        hb_pp_ParsePragma( sLine );   /* --- #pragma  --- */

      else
        hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_WRONG_DIRECTIVE, sDirective, NULL );
    }
  return 0;
}

int hb_pp_ParseDefine( char * sLine )
{
  char defname[ MAX_NAME ];
  char sParams[ 3 * 64 ]; /* 2 for each Marker + 1 for Comma/Null-Terminator. */
  int iParams = -1;
  DEFINES * lastdef;
  char sParam[ MAX_NAME ];
  char sMarker[3];

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_ParseDefine(%s)", sLine));

  HB_SKIPTABSPACES( sLine );

  if( ISID( *sLine ) )
  {
     NextName( &sLine, defname );

     if( *sLine == '(' ) /* If pseudofunction was found */
     {
        int iParamLen, iParamsLen = 0, iLen = strlen( sLine ) ;

        sLine++;
        iParams = 0;

        HB_SKIPTABSPACES( sLine );

        while( *sLine && *sLine != ')' )
        {
           if( ISID( *sLine ) && ( iParamLen = NextName( &sLine, (char *) sParam ) ) > 0 )
           {
              char *pTmp;
              int iPos;

              iParams++;

              sMarker[0] = '\1';
              sMarker[1] = iParams + 64;
              sMarker[2] = '\0';

              pTmp = (char *) sLine;

              while( ( iPos = md_strAt( (char *) sParam, iParamLen, pTmp, TRUE, FALSE, FALSE, FALSE )) > 0 )
              {
                 hb_pp_Stuff( sMarker, pTmp + iPos - 1, 2, iParamLen, iLen );

                 iLen = iLen + 2 - iParamLen;
                 pTmp = pTmp + ( ( iParamLen > 2 ) ? iParamLen - 2 : 2 );
              }

              sParams[iParamsLen++] = '\1';
              sParams[iParamsLen++] = iParams + 64;
              sParams[iParamsLen++] = ',';

              HB_SKIPTABSPACES( sLine );
           }
           else
           {
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_LABEL_MISSING, defname, NULL );
           }

           if( *sLine == ',' )
           {
              sLine++;
              HB_SKIPTABSPACES( sLine );
           }
        }

        if( iParams )
        {
           sParams[iParamsLen - 1] = '\0';
        }

        sLine++;
     }

     HB_SKIPTABSPACES( sLine );

     lastdef = hb_pp_AddDefine( defname, ( *sLine == '\0' ) ? NULL : sLine );
     lastdef->npars = iParams;
     lastdef->pars = ( iParams <= 0 ) ? NULL : hb_strdup( sParams );
  }
  else
  {
     hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_DEFINE_ABSENT, NULL, NULL );
  }

  return 0;
}

DEFINES * hb_pp_AddDefine( char * defname, char * value )
{
  BOOL isNew;
  DEFINES * stdef;

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_AddDefine(%s, %s)", defname, value));

  stdef = DefSearch( defname, &isNew );

  if( stdef != NULL )
  {
    hb_compGenWarning( hb_pp_szWarnings, 'I', HB_PP_WARN_DEFINE_REDEF, defname, NULL );

    if( isNew )
    {
       if( stdef->pars ) hb_xfree( stdef->pars );
       if( stdef->value ) hb_xfree( stdef->value );
    }
  }
  else
  {
    stdef = ( DEFINES * ) hb_xgrab( sizeof( DEFINES ) );
    stdef->last = hb_pp_topDefine;
    hb_pp_topDefine = stdef;
    stdef->name = hb_strdup( defname );
    stdef->npars = -1;

    s_kolAddDefs++;
  }

  if( value )
  {
     char *pTmp;

     stdef->value = ( char *) hb_xgrab( strlen( value ) + 1 );

     pTmp = stdef->value;

     while( *value )
     {
        *pTmp = *value;
        pTmp++; value++;
     }
     --pTmp;
     while( *pTmp == ' ' )
     {
       --pTmp;
     }
     ++pTmp;
     *pTmp = '\0';

     //printf( "Added: >%s<\n", stdef->value );
  }
  else
  {
     stdef->value = NULL;
  }

  stdef->pars = NULL;

  return stdef;
}

static int ParseUndef( char * sLine )
{
  char defname[ MAX_NAME ];
  DEFINES * stdef;
  BOOL isNew;

  HB_TRACE(HB_TR_DEBUG, ("ParseUndef(%s)", sLine));

  NextWord( &sLine, defname, FALSE );

  if( ( stdef = DefSearch(defname, &isNew ) ) != NULL )
  {
    if( isNew )
    {
       if( stdef->pars ) hb_xfree( stdef->pars );
       if( stdef->value ) hb_xfree( stdef->value );
       hb_xfree( stdef->name );
    }
    stdef->pars = NULL;
    stdef->value = NULL;
    stdef->name = NULL;
  }

  return 0;
}

static int ParseIfdef( char * sLine, int usl )
{
  char defname[ MAX_NAME ];
  DEFINES * stdef;

  HB_TRACE(HB_TR_DEBUG, ("ParseIfdef(%s, %d)", sLine, usl));

  if( hb_pp_nCondCompile==0 || hb_pp_aCondCompile[hb_pp_nCondCompile-1])
    {
      NextWord( &sLine, defname, FALSE );
      if( *defname == '\0' )
        hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_DEFINE_ABSENT, NULL, NULL );
    }
  if( hb_pp_nCondCompile == s_maxCondCompile )
    {
      s_maxCondCompile += 5;
      hb_pp_aCondCompile = (int*)hb_xrealloc( hb_pp_aCondCompile, sizeof( int ) * s_maxCondCompile );
    }
  if( hb_pp_nCondCompile==0 || hb_pp_aCondCompile[hb_pp_nCondCompile-1])
    {
      if( ( (stdef = DefSearch(defname,NULL)) != NULL && usl )
           || ( stdef == NULL && !usl ) ) hb_pp_aCondCompile[hb_pp_nCondCompile] = 1;
      else hb_pp_aCondCompile[hb_pp_nCondCompile] = 0;
    }
  else
    hb_pp_aCondCompile[ hb_pp_nCondCompile ] = 0;

  hb_pp_nCondCompile++;

  return 0;
}

static DEFINES * DefSearch( char * defname, BOOL * isNew )
{
  int kol = 0,j;
  DEFINES * stdef = hb_pp_topDefine;

  HB_TRACE(HB_TR_DEBUG, ("DefSearch(%s)", defname));

  while( stdef != NULL )
    {
      kol++;
      if( stdef->name != NULL )
        {
          for( j=0; *(stdef->name+j) == *(defname+j) &&
                  *(stdef->name+j) != '\0'; j++ );
          if( *(stdef->name+j) == *(defname+j) )
            {
              if( isNew ) *isNew = ( s_kolAddDefs >= kol );
              return stdef;
            }
        }
      stdef = stdef->last;
    }
  return NULL;
}

static COMMANDS * ComSearch( char * cmdname, COMMANDS * stcmdStart )
{
   COMMANDS * stcmd = ( stcmdStart ) ? stcmdStart : hb_pp_topCommand;

   HB_TRACE(HB_TR_DEBUG, ("ComSearch(%s, %p)", cmdname, stcmdStart));

   while( stcmd != NULL )
   {
      int j;

      for( j=0; (*(stcmd->name+j)==toupper(*(cmdname+j))) &&
              (*(stcmd->name+j)!='\0') &&
              ((stcmd->com_or_xcom)? 1:(j<4 || ISNAME(*(cmdname+j+1)))); j++ );
      if( (*(stcmd->name+j)==toupper(*(cmdname+j))) ||
           ( !stcmd->com_or_xcom && j >= 4 && *(stcmd->name+j)!='\0'
             && *(cmdname+j) == '\0' ) )
        break;

      stcmd = stcmd->last;
   }

   return stcmd;
}

static COMMANDS * TraSearch( char * cmdname, COMMANDS * sttraStart )
{
  int j;
  COMMANDS *sttra = ( sttraStart ) ? sttraStart : hb_pp_topTranslate;

  HB_TRACE(HB_TR_DEBUG, ("TraSearch(%s, %p)", cmdname, sttraStart));

  while( sttra != NULL )
    {
      for( j=0; *(sttra->name+j)==toupper(*(cmdname+j)) &&
              *(sttra->name+j)!='\0' &&
              ((sttra->com_or_xcom)? 1:(j<4 || ISNAME(*(cmdname+j+1)))); j++ );
      if( *(sttra->name+j)==toupper(*(cmdname+j)) ||
           ( !sttra->com_or_xcom && j >= 4 &&
             *(sttra->name+j)!='\0' && *(cmdname+j) == '\0' ) )
        break;
      sttra = sttra->last;
    }
  return sttra;
}

static void ParseCommand( char * sLine, BOOL com_or_xcom, BOOL com_or_tra, BOOL bRemove )
{
  static char mpatt[ PATTERN_SIZE ];
  static char rpatt[ PATTERN_SIZE ];

  char cmdname[ MAX_NAME ];
  COMMANDS * stcmd;
  int mlen,rlen;
  int ipos;

  /* Ron Pinkas added 2000-12-03 */
  BOOL bOk = FALSE;

  /* Ron Pinkas added 2002-09-20 */
  mpatt[0] = '\0';

  HB_TRACE(HB_TR_DEBUG, ("ParseCommand(%s, %d, %d, %d)", sLine, com_or_xcom, com_or_tra, bRemove));

  HB_SKIPTABSPACES( sLine );

  #if 0
  /* JFL 2000-09-19 */
  /* This was the original line as Alexander wrote it */
  /* while( *sLine != '\0' && *sLine != ' ' && *sLine != '\t' && *sLine != '<' && *sLine != '=' && ( *sLine != '(' || ipos == 0 ) ) */
  /* Now the line #xtranslate = name(.. => will be allowed */
  ipos = 0;

  /* I changed it to the following to allow < and = to be the first char within a translate or xtranslate */
  while( *sLine != '\0' && *sLine != ' ' && *sLine != '\t' && ( *sLine != '<' || ipos == 0 ) && ( *sLine != '=' || ipos == 0 ) && ( *sLine != '(' || ipos == 0 ) )
  {
     /* Ron Pinkas added 2000-01-24 */
     if( ! ISNAME( *sLine ) )
     {
        /* Ron Pinkas added 2002-02-15 */
        if( *sLine == '[' && ipos )
        {
           break;
        }

        if( IS_2CHAR_OPERATOR( sLine ) )
        {
           *(cmdname+ipos++) = *sLine++;
           *(cmdname+ipos++) = *sLine++;
           break;
        }
        else
        {
           *(cmdname+ipos++) = *sLine++;
           break;
        }
     }
     /* END, Ron Pinkas added 2000-01-24 */

     *(cmdname+ipos++) = *sLine++;
  }
  *(cmdname+ipos) = '\0';

  if( !ipos )
  {
     return;
  }
  #else

     ipos = hb_pp_NextToken( &sLine );

     if( ipos == 0 || ipos > MAX_NAME )
     {
        // Error???
        return;
     }

     strcpy( cmdname, s_sToken );
  #endif

  hb_strupr( cmdname );
  HB_SKIPTABSPACES(sLine);

  /* Ron Pinkas added 2000-12-03 */
  ipos = 0;
  while( *sLine )
  {
     mpatt[ipos++] = *sLine;

     if( *sLine == '=' )
     {
        int i = ipos;

        if( ipos && *(sLine - 1) == '\\' )
        {
           ipos--;
           mpatt[ipos - 1] = '=';
           sLine++;
           continue;
        }

        sLine++;
        mpatt[i++] = *sLine;

        while( *sLine && ( *sLine == ' ' || *sLine == '\t' ) )
        {
           sLine++;
           mpatt[i++] = *sLine;
        }

        if( *sLine == '>' )
        {
           ipos = ipos - 2;
           while( mpatt[ipos] == ' ' || mpatt[ipos] == '\t' )
           {
              ipos--;
           }

           mpatt[ipos + 1] = '\0';
           sLine++;
           bOk = TRUE;
           break;
        }

        ipos = i;
     }

     sLine++;
  }
  /* End - Ron Pinkas added 2000-12-03 */

  if( ! bOk )
  {
     mpatt[ipos] = '\0';
  }

  /* Ron Pinkas modified 2000-12-03
  if( (ipos = hb_strAt( "=>", 2, sLine, strlen(sLine) )) > 0 ) */
  if( bOk || bRemove )
  {
    // Ron Pinkas commented 2002-09-23
    //RemoveSlash( mpatt );
    mlen = strotrim( mpatt, TRUE );

    /* Ron Pinkas removed 2000-12-03
    sLine += ipos + 1; */

    HB_SKIPTABSPACES(sLine);
    hb_pp_strocpy( rpatt, sLine );
    rlen = strotrim( rpatt, TRUE );

    ConvertPatterns( mpatt, mlen, rpatt, rlen );

    // Ron Pinkas added 2002-09-23
    RemoveSlash( mpatt );

    if( bRemove )
    {
       COMMANDS *cmd, *cmdPrev = NULL;

       if( com_or_tra )
       {
          cmd = hb_pp_topCommand;
       }
       else
       {
          cmd = hb_pp_topTranslate;
       }

       while ( cmd )
       {
          //printf( "Searching Key X=%i '%s' Rule '%s' in Command: '%s' Rule: '%s'\n", com_or_xcom, cmdname, mpatt, cmd->name, cmd->mpatt );

          if( strcmp( cmd->name, cmdname ) == 0 )
          {
             if( com_or_xcom == FALSE || strcmp( cmd->mpatt, mpatt ) == 0 )
             {
                if( cmdPrev == NULL )
                {
                   if( com_or_tra )
                   {
                      hb_pp_topCommand = cmd->last;
                   }
                   else
                   {
                      hb_pp_topTranslate = cmd->last;
                   }
                }
                else
                {
                   cmdPrev->last = cmd->last;
                }

                //printf( "Found: X:%i cmd->mpatt: '%s' mpatt: '%s'\n", com_or_xcom, cmd->mpatt, mpatt );

                hb_xfree( cmd->name );
                hb_xfree( cmd->mpatt );
                hb_xfree( cmd->value );
                hb_xfree( cmd );

                return;
             }
          }

          cmdPrev = cmd;
          cmd = cmd->last;
       }

       return;
    }
    else
    {
       if( com_or_tra )
       {
          stcmd = AddCommand( cmdname );
       }
       else
       {
          stcmd = AddTranslate( cmdname );
       }
    }

    stcmd->com_or_xcom = com_or_xcom;
    stcmd->mpatt = hb_strdup( mpatt );
    stcmd->value = ( rlen > 0 ) ? hb_strdup( rpatt ) : NULL;

    //printf( "Parsecommand Name: %s Pat: %s Val: %s\n", stcmd->name, stcmd->mpatt, stcmd->value );
  }
  else
  {
     sLine -= ( ipos + 1 );
     hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_COMMAND_DEFINITION, cmdname, sLine );
  }
}

/* ConvertPatterns()
 * Converts result pattern in #command and #translate to inner format
 */

static void ConvertPatterns( char * mpatt, int mlen, char * rpatt, int rlen )
{
  int i = 0, ipos, ifou;
  int explen, rmlen;
  char exppatt[ MAX_NAME ], expreal[ 5 ] = "\1  0";
  char lastchar = '@', exptype;
  char * ptr, * ptrtmp;

  HB_TRACE(HB_TR_DEBUG, ("ConvertPatterns(%s, %d, %s, %d)", mpatt, mlen, rpatt, rlen));

  while( *(mpatt+i) != '\0' )
  {
     if( *(mpatt+i) == '<' && ( i == 0 || *(mpatt+i-1) != '\\' ) )
     {
        if( (unsigned char) lastchar == 255 )
        {
           hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_TOO_MANY_MARKERS, NULL, NULL );
        }

        /* Drag match marker, determine it type */
        explen = 0; ipos = i; i++; exptype = '0';

        while( *(mpatt+i) == ' ' || *(mpatt+i) == '\t' )
        {
           i++;
        }

        if( *(mpatt+i) == '*' )        /* Wild match marker */
        {
           exptype = '3';
           i++;
        }
        else if( *(mpatt+i) == '(' )   /* Extended expression match marker */
        {
           exptype = '4';
           i++;
        }
        else if( *(mpatt+i) == '!' )   /* Minimal expression match marker */
        {
           exptype = '5';
           i++;
        }

        ptr = mpatt + i;

        while( *ptr != '>' )
        {
           if( *ptr == '\0' || *ptr == '<' || *ptr == '[' || *ptr == ']' )
           {
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_PATTERN_DEFINITION, NULL, NULL );
              return;
           }

           ptr++;
        }

        while( *(mpatt+i) != '>' )
        {
           if( *(mpatt+i) == ',' )      /* List match marker */
           {
              exptype = '1';

              while( *(mpatt+i) != '>' )
              {
                 i++;
              }

              break;
           }
           else if( *(mpatt+i) == ':' ) /* Restricted match marker */
           {
              exptype = '2';
              *(mpatt+i--) = ' ';

              break;
           }

           if( *(mpatt+i) != ' ' && *(mpatt+i) != '\t' )
           {
             *(exppatt+explen++) = *(mpatt+i);
           }

           i++;
        }

        if( exptype == '3' )
        {
           if( *(exppatt+explen-1) == '*' )
           {
              explen--;
           }
           else
           {
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_PATTERN_DEFINITION, NULL, NULL );
           }
        }
        else if( exptype == '4' )
        {
           if( *(exppatt+explen-1) == ')' )
           {
              explen--;
           }
           else
           {
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_PATTERN_DEFINITION, NULL, NULL );
           }
        }
        else if( exptype == '5' )
        {
           if( *(exppatt+explen-1) == '!' )
           {
              explen--;
           }
           else
           {
              hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_PATTERN_DEFINITION, NULL, NULL );
           }
        }

        rmlen = i - ipos + 1;

        /* Convert match marker into inner format */
        lastchar = (lastchar == 'Z' ) ? 'a' : ( (char) ( (unsigned char) lastchar + 1 ) );

        expreal[1] = lastchar;
        expreal[2] = exptype;

        hb_pp_Stuff( expreal, mpatt+ipos, 4, rmlen, mlen );

        mlen += 4 - rmlen;
        i += 4 - rmlen;

        /* Look for appropriate result markers */
        ptr = rpatt;

        while( ( ifou = hb_strAt( exppatt, explen, ptr, rlen - ( ptr - rpatt ) ) ) > 0 )
        {
           /* Convert result marker into inner format */
           ifou --;
           ptr += ifou;
           ptrtmp = ptr + 1;
           rmlen = explen;
           exptype = '0';

           do
           {
              ptr--;
              rmlen++;
              ifou--;

              if( *ptr == '<' )
              {
                 continue;
              }
              else if( *ptr == '\"' )
              {
                 exptype = '2';
              }
              else if( *ptr == '(' )
              {
                 exptype = '3';
              }
              else if( *ptr == '{' )
              {
                 exptype = '4';
              }
              else if( *ptr == '.' )
              {
                 exptype = '5';
              }
              else if( *ptr == '-' )
              {
                 exptype = '6';
              }
              else if( *ptr == ' ' || *ptr == '\t' )
              {
                 continue;
              }
              else
              {
                 ifou = -1;
              }
           }

           while( ifou >= 0 && *ptr!='<' && *(ptr-1)!= '\\' );

           if( ifou >=0 && *ptr=='<' )
           {
              ptr += rmlen++;

              while( *ptr != '\0' && *ptr != '>'  && *(ptr-1) != '\\' )
              {
                 if( *ptr != ' ' && *ptr != '\t' && *ptr != '\"' && *ptr != ')' && *ptr != '}' && *ptr != '.' && *ptr != '-' )
                 {
                    ifou = -1;
                    break;
                 }

                 rmlen++;
                 ptr++;
              }

              if( ifou >=0 && *ptr=='>' )
              {
                 ptr -= rmlen;
                 ptr++;

                 if( exptype == '0' && *(ptr-1) == '#' && *(ptr-2) != '\\' )
                 {
                    exptype = '1';
                    ptr--;
                    rmlen++;
                 }

                 expreal[2] = exptype;
                 hb_pp_Stuff( expreal, ptr, 4, rmlen, rlen );
                 rlen += 4 - rmlen;
              }
              else
              {
                 ptr = ptrtmp;
              }
           }
           else
           {
              ptr = ptrtmp;
           }
        }
     }

     i++;
  }
}

static COMMANDS * AddCommand( char * cmdname )
{
  COMMANDS * stcmd;

  HB_TRACE(HB_TR_DEBUG, ("AddCommand(%s)", cmdname));

  stcmd = ( COMMANDS * ) hb_xgrab( sizeof( COMMANDS ) );
  stcmd->last = hb_pp_topCommand;
  hb_pp_topCommand = stcmd;
  stcmd->name = hb_strdup( cmdname );
  s_kolAddComs++;
  return stcmd;
}

static COMMANDS* AddTranslate( char * traname )
{
  COMMANDS * sttra;

  HB_TRACE(HB_TR_DEBUG, ("AddTranslate(%s)", traname));

  sttra = ( COMMANDS * ) hb_xgrab( sizeof( COMMANDS ) );
  sttra->last = hb_pp_topTranslate;
  hb_pp_topTranslate = sttra;
  sttra->name = hb_strdup( traname );
  s_kolAddTras++;
  return sttra;
}

int hb_pp_ParseExpression( char * sLine, char * sOutLine )
{
  char sToken[MAX_NAME];
  char * ptri, * ptro, * ptrb;
  int lenToken, i, ipos, isdvig, lens, iOffset;
  int ifou;
  int kolpass = 0;
  DEFINES * stdef;
  COMMANDS * stcmd;

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_ParseExpression(%s, %s)", sLine, sOutLine));

  strotrim( sLine, FALSE );

  isdvig = 0;

  do
  {
    Top:
     //printf( "  *** Line: >%s<\n", sLine );

     ptro = sOutLine;
     ptri = sLine + isdvig;

     ipos = md_strAt( ";", 1, ptri, TRUE, FALSE, FALSE, FALSE );

     if( ipos > 0 )
     {
        *( ptri + ipos - 1 ) = '\0';
     }

     HB_SKIPTABSPACES( ptri );

     if( *ptri == '\0' )
     {
        if ( ipos == 0 )
        {
           break;
        }

        *ptri = ' ';
        isdvig += ipos;
        goto Top;
     }

     #if 0
        if( ipos > 0 )
        {
           printf( "Holding: >%s<\n", sLine + isdvig + ipos );
        }
        printf( "Processing: >%s<\n", ptri );
     #endif

     if( *ptri == '#' )
     {
        hb_pp_ParseDirective( ptri + 1 );

        if( ipos > 0 )
        {
           *( sLine + isdvig + ipos - 1 ) = ';';
        }

        lens = strlen( ptri );

        //printf( "Len: %i, Digesting: >%s<\n", lens, ptri );

        hb_pp_Stuff( " ", ptri, 0, ipos ? ipos : lens, lens );

        //printf( "ipos: %i, Digested: >%s<\n", ipos, sLine + isdvig );

        if( ipos > 0 && *( sLine + isdvig ) )
        {
           ipos = 1;
        }
     }
     else
     {
       NextName:

        if( kolpass > MAX_CICLES )
        {
           hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_RECURSE, NULL, NULL );
           break;
        }

        if( ( lenToken = NextName( &ptri, sToken ) ) > 0 )
        {
           #if 0
              printf( "Define: >%s< Line: >%s<\n", sToken, ptri );
           #endif

           if( ( stdef = DefSearch( sToken, FALSE ) ) == NULL )
           {
              goto NextName;
           }
           else
           {
              ptrb = ptri - lenToken;

              if( ( i = WorkDefine( &ptri, ptro, stdef ) ) >= 0 )
              {
                 lens = strlen( ptrb );

                 if( ipos > 0 )
                 {
                    *( ptrb + lens ) = ';';
                    lens += strlen( ptrb + lens + 1 );
                 }

                 hb_pp_Stuff( ptro, ptrb, i, ptri - ptrb, lens + 1 );

                 //printf( "Defined: >%s<\n", ptrb );

                 kolpass++;

                 // All the way from top again, check #defines from this same start position.
                 goto Top;
              }
              else
              {
                 //printf( "Failed!\n" );

                 goto NextName;
              }
           }
        }

        #if 0
            printf( "    After #defines: >%s<\n", sLine );
        #endif

        iOffset = 0;

       NextToken:

        stcmd = NULL;
        ptri = sLine + isdvig + iOffset;
        ptrb = ptri;

        if( *ptrb && ( lenToken = hb_pp_NextToken( &ptrb ) ) > 0 )
        {
           #if 0
              printf( "Token: >%s< Line: >%s<\n", s_sToken, ptri );
           #endif

         NextTranslate:

           if( ( stcmd = TraSearch( s_sToken, stcmd ) ) == NULL )
           {
              iOffset += lenToken;
              goto NextToken;
           }
           else
           {
              //printf( "Trying: >%s<\n", ptrb );

              if( ( i = WorkTranslate( ptrb, ptro, stcmd, &lens ) ) >= 0 )
              {
                 lens += lenToken;
                 while( lens > 0 && ( *( ptri + lens - 1 ) == ' ' || *( ptri + lens - 1 )== '\t' ) )
                 {
                    lens--;
                 }

                 if( ipos > 0 )
                 {
                    *( sLine + isdvig + ipos - 1 ) = ';';
                 }

                 hb_pp_Stuff( ptro, ptri, i, lens, strlen( ptri ) );

                 //printf( "Translated: >%s<\n", ptri );

                 kolpass++;

                 // All the way from top again, check #defines from this same start position.
                 goto Top;
              }
              else
              {
                 //printf( "Failed: %s\n", ptrb );

                 stcmd = stcmd->last;

                 if( stcmd )
                 {
                    goto NextTranslate;
                 }
                 else
                 {
                   iOffset += lenToken;
                   goto NextToken;
                 }
              }
           }
        }

        #if 0
            printf( "   After #translate: >%s<\n", sLine );
        #endif

        /* Look for definitions from #command      */
        ptri = sLine + isdvig;

        HB_SKIPTABSPACES( ptri );

        hb_pp_NextToken( &ptri );

        #if 0
           printf( "Command: >%s< Line: >%s<\n", s_sToken, ptri );
        #endif

        stcmd = NULL;

        ptrb = ptri;

      NextCommand:

        if( ( stcmd = ComSearch( s_sToken, stcmd ) ) == NULL )
        {
           if( ipos > 0 )
           {
              *( sLine + isdvig + ipos - 1 ) = ';';
              //printf( "Restored: >%s<\n", sLine );
           }
        }
        else
        {
           //printf( "Trying: >%s<\n", ptri );

           ptro = sOutLine;

           if( ( i = WorkCommand( ptri, ptro, stcmd ) ) >= 0 )
           {
              ptri = sLine + isdvig;

              if( ipos > 0 )
              {
                 *( ptri + ipos - 1 ) = ';';
                 //printf( "Restored: >%s<\n", sLine );
              }

              if( isdvig + ipos > 0 )
              {
                 lens = strlen( sLine + isdvig );

                 hb_pp_Stuff( ptro, ptri, i, (ipos)? ipos - 1 : lens, lens );
              }
              else
              {
                 memcpy( sLine, sOutLine, i+1);
              }

              //printf( "Commanded: >%s<\n", ptro );
              //printf( "Whole: >%s<\n", sLine );

              kolpass++;

              // All the way from top again, check #defines from this same start position.
              goto Top;
           }
           else
           {
              //printf( "Failed!\n" );

              stcmd = stcmd->last;

              if( stcmd )
              {
                 goto NextCommand;
              }
              else
              {
                 if( ipos > 0 )
                 {
                    *( ptri + ipos - 1 ) = ';';
                    //printf( "Restored: >%s<\n", sLine );
                 }
              }
           }
        }
     }

     isdvig += ipos;
  }
  while( ipos > 0 && *( sLine + isdvig ) );

  #if 0
      printf( "Outed: >%s<\n", sLine );
  #endif

  return 0;
}

static int WorkDefine( char ** ptri, char * ptro, DEFINES * stdef )
{
  int npars, lens;
  char * ptr;

  HB_TRACE(HB_TR_DEBUG, ("WorkDefine(%p, %s, %p)", ptri, ptro, stdef));

  if( stdef->npars < 0 )
  {
     lens = hb_pp_strocpy( ptro,stdef->value );
  }
  else
  {
     HB_SKIPTABSPACES( *ptri );

     if( **ptri == '(' )
     {
        npars = 0; ptr = *ptri;

        do
        {
           ptr++;

           if( NextParm( &ptr, NULL ) > 0 )
           {
              npars++;
           }
        }
        while( *ptr != ')' && *ptr != '\0' );

        if( *ptr == ')' && stdef->npars == npars )
        {
           /* Ron Pinkas added 2000-11-21 */
           char *pTmp = ptr + 1;

           while( *pTmp == ' ' || *pTmp == '\t' )
           {
             pTmp++;
           }
           if( *pTmp == '[' )
           {
              s_bArray = TRUE;
           }
           /* END - Ron Pinkas added 2000-11-21 */

           lens = WorkPseudoF( ptri, ptro, stdef );
        }
        else
        {
           return -1;
        }
     }
     else
     {
        return -1;
     }
  }

  return lens;
}

static int WorkPseudoF( char ** ptri, char * ptro, DEFINES * stdef )
{
  char parfict[ MAX_NAME ], * ptrreal;
  char * ptrb;
  int ipos, ifou, ibeg;
  int lenfict, lenreal, lenres;

  HB_TRACE(HB_TR_DEBUG, ("WorkPseudoF(%p, %s, %p)", ptri, ptro, stdef));

  lenres = hb_pp_strocpy( ptro, stdef->value );  /* Copying value of macro to destination string  */

  if( stdef->pars )
  {
     ipos = 0; ibeg = 0;
     do                               /* Parsing through parameters */
     {                                /* in macro definition        */
        if( *(stdef->pars+ipos) == ',' || *(stdef->pars+ipos) == '\0' )
        {
           *(parfict+ipos-ibeg) = '\0';
           lenfict = ipos - ibeg;

           if( **ptri != ')' )
           {
              (*ptri)++;             /* Get next real parameter */
              HB_SKIPTABSPACES( *ptri );
              ptrreal = *ptri;
              lenreal = NextParm( ptri, NULL);

              ptrb = ptro;
              while( (ifou = hb_strAt( parfict, lenfict, ptrb, lenres-(ptrb-ptro) )) > 0 )
              {
                 ptrb = ptrb+ifou-1;
                 if( !ISNAME(*(ptrb-1)) && !ISNAME(*(ptrb+lenfict)) )
                 {
                    hb_pp_Stuff( ptrreal, ptrb, lenreal, lenfict, lenres );
                    lenres += lenreal - lenfict;
                    ptrb += lenreal;
                 }
                 else
                 {
                    ptrb++;
                 }
              }

              ibeg = ipos+1;
           }
        }
        else
        {
           *(parfict+ipos-ibeg) = *(stdef->pars+ipos);
        }

        if( *(stdef->pars+ipos) == '\0' )
        {
           break;
        }

        ipos++;
     }
     while( 1 );
  }
  else
  {
     while( **ptri != ')' )
     {
       (*ptri)++;
     }
  }

  (*ptri)++;

  return lenres;
}

static int WorkCommand( char * ptri, char * ptro, COMMANDS * stcmd )
{
  int rez;
  int lenres;
  char * ptrmp;

  HB_TRACE(HB_TR_DEBUG, ("WorkCommand(%s, %s, %p)", ptri, ptro, stcmd));

  //printf( "Command Key: '%s' MP: '%s' RP: >%s< Against: '%s'\n", stcmd->name, stcmd->mpatt, stcmd->value , ptri );

  lenres = hb_pp_strocpy( ptro, stcmd->value );   /* Copying result pattern */
  ptrmp = stcmd->mpatt;                      /* Pointer to a match pattern */
  s_Repeate = 0;
  s_groupchar = '@';
  rez = CommandStuff( ptrmp, ptri, ptro, &lenres, TRUE, stcmd->com_or_xcom );

  if( rez >= 0 )
  {
     *( ptro + lenres ) = '\0';
     return lenres;
  }

  return -1;
}

static int WorkTranslate( char * ptri, char * ptro, COMMANDS * sttra, int * lens )
{
  int rez;
  int lenres;
  char * ptrmp;

  HB_TRACE(HB_TR_DEBUG, ("WorkTranslate(%s, %s, %p, %p)", ptri, ptro, sttra, lens));

  //printf( "Translate Key: '%s' MP: '%s' RP: >%s< Against: '%s'\n", sttra->name, sttra->mpatt, sttra->value , ptri );

  lenres = hb_pp_strocpy( ptro, sttra->value );
  ptrmp = sttra->mpatt;
  s_Repeate = 0;
  s_groupchar = '@';

  rez = CommandStuff( ptrmp, ptri, ptro, &lenres, FALSE, sttra->com_or_xcom );

  if( rez >= 0 )
  {
     *(ptro+lenres) = '\0';
     *lens = rez;
     return lenres;
  }

  return -1;
}

static int CommandStuff( char * ptrmp, char * inputLine, char * ptro, int * lenres, BOOL com_or_tra, BOOL com_or_xcom )
{
  BOOL endTranslation = FALSE;
  int ipos;
  char * lastopti[ 3 ], * strtopti = NULL, * strtptri = NULL;
  char * ptri = inputLine, * ptr, tmpname[ MAX_NAME ];
  int isWordInside = 0;

  HB_TRACE(HB_TR_DEBUG, ("CommandStuff(%s, %s, %s, %p, %i, %i)", ptrmp, inputLine, ptro, lenres, com_or_tra, com_or_xcom));

  //printf( "MP: >%s< Input: >%s<\n", ptrmp, ptri ) ;

  s_numBrackets = 0;
  HB_SKIPTABSPACES( ptri );

  if( ptrmp == NULL )
  {
     if( *ptri != '\0' )
     {
        return -1;
     }
  }
  else
  {
     while( *ptri != '\0' && !endTranslation )
     {
        HB_SKIPTABSPACES( ptrmp );

        if( *ptrmp == '[' && !s_numBrackets && !strtopti )
        {
           #ifdef DEBUG_OPTIONAL
              printf( "SQUARE: >%s<\n", ptrmp );
           #endif
           strtopti = ptrmp;
        }

        if( !s_numBrackets && strtopti && strtptri != ptri )
        {
           strtptri = ptri;
           ptrmp    = strtopti;

           //printf( "Restored: %s\n", ptrmp );

           ptr      = ptri;
           ipos     = NextStopper( &ptr, tmpname );
           ipos     = md_strAt( tmpname, ipos, strtopti, TRUE, TRUE, TRUE, TRUE );

           #ifdef DEBUG_OPTIONAL
              printf( "At: %i Name: >%s< in >%s<\n", ipos, tmpname, strtopti );

              if( ipos )
              {
                 printf( "TestOptional( >%s<, >%s< )\n", strtopti, strtopti+ipos-2 );
              }
           #endif

           if( ipos && TestOptional( strtopti, strtopti+ipos-2 ) )
           {
              ptr = strtopti+ipos-2;

              ptr = PrevSquare( ptr, strtopti, NULL );

              if( ptr )
              {
                 //printf( "Rewinded: %s\n", ptr );
                 ptrmp = ptr;
              }
           }
        }

        switch( *ptrmp )
        {
        case '[':
          if( !s_numBrackets )
          {
             isWordInside = 0;
          }

          s_numBrackets++;
          s_aIsRepeate[ s_Repeate ] = 0;
          lastopti[s_Repeate++] = ptrmp;
          ptrmp++;

          //printf( "CHECK >%s< in >%s<\n", ptrmp, ptri );

          if( !CheckOptional( ptrmp, ptri, ptro, lenres, com_or_tra, com_or_xcom ) )
          {
             //printf( "SKIP %s\n", ptrmp );
             SkipOptional( &ptrmp );
          }

          break;

        case ']':
          if( s_Repeate )
          {
             s_Repeate--;

             if( s_aIsRepeate[ s_Repeate ] )
             {
                if( ISNAME( *ptri ) )
                {
                   ptr  = ptri;
                   ipos = NextStopper( &ptr, tmpname );
                   ipos = md_strAt( tmpname, ipos, ptrmp, TRUE, TRUE, TRUE, TRUE );

                   //printf( "TestOptional, %s, %i\n", tmpname, ipos );

                   if( ipos && TestOptional( ptrmp+1, ptrmp+ipos-2 ) )
                   {
                      ptr = PrevSquare( ptrmp+ipos-2, ptrmp+1, NULL );

                      //printf( "Rewinded: %s\n", ptr );

                      if( !ptr || CheckOptional( ptrmp+1, ptri, ptro, lenres, com_or_tra, com_or_xcom ) )
                      {
                         ptrmp = lastopti[s_Repeate];
                         ptrmp++;
                         s_Repeate++;
                         SkipOptional( &ptrmp );
                         s_numBrackets++;
                         ptrmp++;
                         strtptri = ptri;
                      }
                      else
                      {
                         ptrmp = lastopti[s_Repeate];
                      }
                   }
                   else
                   {
                      ptrmp = lastopti[s_Repeate];
                   }
                }
                else
                {
                   ptrmp = lastopti[s_Repeate];
                }
             }
             else
             {
                if( !isWordInside )
                {
                   strtopti = NULL;
                }

                ptrmp++;
             }

             s_numBrackets--;
          }
          else
          {
             if( !isWordInside )
             {
                strtopti = NULL;
             }
             s_numBrackets--; ptrmp++;
          }

          break;

        case ',':
          if( s_numBrackets == 1 )
          {
             isWordInside = 1;
          }

          if( !s_numBrackets )
          {
             strtopti = NULL;
          }

          if( *ptri == ',' )
          {
             ptrmp++; ptri++;
          }
          else
          {
             if( s_numBrackets )
             {
                SkipOptional( &ptrmp );
             }
             else
             {
                return -1;
             }
          }

          break;

        case '\1':  /*  Match marker */
          if( !s_numBrackets )
          {
             strtopti = NULL;
          }

          if( s_numBrackets == 1 && *(ptrmp+2) == '2' )
          {
             isWordInside = 1; /*  restricted match marker  */
          }

          //printf( "\nCommandStuff->WorkMarkers: >%s< MP: >%s<\n", ptri, ptrmp );

          if( ! WorkMarkers( &ptrmp, &ptri, ptro, lenres, com_or_xcom ) )
          {
             //printf( "Failed!\n" );

             if( s_numBrackets )
             {
                SkipOptional( &ptrmp );
             }
             else
             {
                return -1;
             }
          }

          //printf( "AFTER Markers MP: %s\nInput: %s\n", ptrmp, ptri ) ;

          break;

        case '\0':
          if( com_or_tra )
          {
             return -1;
          }
          else
          {
             endTranslation = TRUE;
          }

          break;

        default:    /*   Key word    */
          if( s_numBrackets == 1 )
          {
             isWordInside = 1;
          }

          if( !s_numBrackets )
          {
             strtopti = NULL;
          }

          ptr = ptri;

          if( *ptri == ',' || truncmp( &ptri, &ptrmp, !com_or_xcom ) )
          {
             ptri = ptr;

             if( s_numBrackets )
             {
                SkipOptional( &ptrmp );
             }
             else
             {
                return -1;
             }
          }
        }

        HB_SKIPTABSPACES( ptri );
     }
  }

  if( *ptrmp != '\0' )
  {
     if( s_Repeate )
     {
        s_Repeate = 0;
        ptrmp = lastopti[0];
     }

     s_numBrackets = 0;

     do
     {
        HB_SKIPTABSPACES( ptrmp );

        if( *ptrmp != '\0' )
        {
           switch( *ptrmp )
           {
              case '[':
                ptrmp++;
                SkipOptional( &ptrmp );
                ptrmp++;
                break;

              case ']':
                ptrmp++;
                break;

              default:
                return -1;
           }
        }
     }
     while( *ptrmp != '\0' );
  }

  SearnRep( "\1", "", 0, ptro, lenres );
  *(ptro + *lenres) = '\0';

  //printf( "%s\n", ptro );
  strotrim( ptro, ptro[0] == '#' ); // Removing excess spaces.
  *lenres = RemoveSlash( ptro );   /* Removing '\', '[' and ']' from result string */
  //printf( "%s\n", ptro );

  if( com_or_tra )
  {
      return 1;
  }
  else
  {
     return ptri - inputLine;
  }
}

static int RemoveSlash( char * stroka )
{
  char *ptr = stroka;
  int State = STATE_INIT;
  BOOL bDirective = FALSE;
  int lenres = strlen( stroka );
  char cLastChar = '\0';

  HB_TRACE(HB_TR_DEBUG, ("RemoveSlash(%s)", stroka));

  while( *ptr != '\0' )
  {
     switch( State )
     {
        case STATE_INIT:
          if( *ptr != ' ' && *ptr != '\t' ) State = STATE_NORMAL;
          if( *ptr == '#' )  bDirective = TRUE;

        case STATE_NORMAL:
          if( *ptr == '\'' )  State = STATE_QUOTE1;
          else if( *ptr == '\"' )  State = STATE_QUOTE2;
          else if( *ptr == '[' && ( bDirective || ( ( strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) ) ) ) )  State = STATE_QUOTE3;
          else if( *ptr == ';' )
          {
            State = STATE_INIT;
            bDirective = FALSE;
          }
          else //if( !bDirective )
          {
             // Ron Pinkas commented 2002-09-23
             if( *ptr == '\\' /* && ( *(ptr+1) == '[' || *(ptr+1) == ']' ||
                                   *(ptr+1) == '{' || *(ptr+1) == '}' || *(ptr+1) == '<' ||
                                   *(ptr+1) == '>' || *(ptr+1) == '\'' || *(ptr+1) == '\"' || *(ptr+1) == '\\' )*/ )
             {
                hb_pp_Stuff( "", ptr, 0, 1, lenres - (ptr - stroka) );
                lenres--;
             }
          }
          break;

        case STATE_QUOTE1:
          if( *ptr == '\'' )  State = STATE_NORMAL;
          break;

        case STATE_QUOTE2:
          if( *ptr == '\"' )  State = STATE_NORMAL;
          break;

        case STATE_QUOTE3:
          if( *ptr == ']' )  State = STATE_NORMAL;
          break;
     }

     cLastChar = *ptr;
     ptr++;
  }

  return lenres;
}

static int WorkMarkers( char ** ptrmp, char ** ptri, char * ptro, int * lenres, BOOL com_or_xcom )
{
  static char expreal[ MAX_EXP ];

  char exppatt[ MAX_NAME ];
  int lenreal = 0, maxlenreal = HB_PP_STR_SIZE, lenpatt;
  int rezrestr, ipos, nBra;
  char * ptr, * ptrtemp;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("WorkMarkers(%s, %s, %s, %i, %i)", *ptrmp, *ptri, ptro, *lenres, com_or_xcom));

  //printf( "WorkMarkers( '%s', '%s', '%s', %i, %i) %i\n", *ptrmp, *ptri, ptro, *lenres, com_or_xcom, s_numBrackets );

  /* Copying a match pattern to 'exppatt' */
  lenpatt = stroncpy( exppatt, *ptrmp, 4 );
  *ptrmp += 4;

  HB_SKIPTABSPACES( *ptrmp );

  /* JFL removed 12/11/2001 to allow param like (,,3) as allowed by clipper */
  /*
  if( **ptri == ',' )
  {
     if( s_numBrackets )
     {
        return 0;
     }
  }*/

  ptrtemp = *ptrmp;

  if( *(exppatt+2) != '2' && *ptrtemp == ']' )
  {
     ptrtemp++;
     HB_SKIPTABSPACES( ptrtemp );

     while( *ptrtemp == '[' )
     {
        nBra = 0;
        ptrtemp++;

        while( ( *ptrtemp != ']' || nBra ) && *ptrtemp != '\0')
        {
           if( *ptrtemp == '[' )
           {
              nBra++;
           }
           else if( *ptrtemp == ']' )
           {
              nBra --;
           }
           ptrtemp++;
        }
        ptrtemp++;

        HB_SKIPTABSPACES( ptrtemp );
     }
  }

  if( *(exppatt+2) != '2' && *ptrtemp != '\1' && *ptrtemp != ',' && *ptrtemp != '[' && *ptrtemp != ']' && *ptrtemp != '\0' )
  {
     // Stopper for the expression.
     lenreal = strincpy( expreal, ptrtemp );

     //printf( "Stoper: >%.*s<\n", lenreal, expreal );

     if( (ipos = md_strAt( expreal, lenreal, *ptri, TRUE, TRUE, FALSE, TRUE )) > 0 )
     {
        if( ptrtemp > *ptrmp )
        {
           if( ipos == 1 )
           {
              if( s_numBrackets )
              {
                  return 0;
              }
           }
           else
           {
              maxlenreal = ipos - 1;
              lenreal = 0;
           }
        }
        else
        {
           //printf( "\nFound: '%s' Len: %i In: '%s' At: %i \n", expreal, lenreal, *ptri, ipos );

           lenreal = stroncpy( expreal, *ptri, ipos-1 );

           #if 0
              printf( "\nExpr: '%s' ptrtemp: '%s' exppat: '%s'\n", expreal, ptrtemp, exppatt );
           #endif

           if( ipos > 1 )
           {
               if( *(exppatt+2) == '5' )       /*  ----  Minimal match marker  */
               {
                  if( IsIdentifier( expreal ) )
                  {
                     //printf( "Accepted ID: >%s<\n", expreal );
                     *ptri += lenreal;
                  }
               }
               else if( isExpres( expreal, *(exppatt+2) == '1' ) )
               {
                  //printf( "Accepted: >%s<\n", expreal );
                  *ptri += lenreal;
               }
           }
           else
           {
              if( s_numBrackets )
              {
                 return 0;
              }
              else
              {
                 lenreal = 0;
              }
           }
        }
     }
     else
     {
        if( s_numBrackets )
        {
           return 0;
        }
        else
        {
           lenreal = 0;
        }
     }
  }

  if( *(exppatt+2) == '5' )       /*  ----  minimal match marker  */
  {
     /* Copying a real expression to 'expreal' */
     if( !lenreal )
     {
        lenreal = getExpReal( expreal, ptri, FALSE, maxlenreal, FALSE );
     }

     //printf("Len: %i Pat: %s Exp: %s\n", lenreal, exppatt, expreal );

     if( lenreal && IsIdentifier( expreal ) )
     {
        SearnRep( exppatt,expreal,lenreal,ptro,lenres);
     }
     else
     {
        return 0;
     }
  }
  else if( *(exppatt+2) == '4' )       /*  ----  extended match marker  */
  {
     if( !lenreal ) lenreal = getExpReal( expreal, ptri, FALSE, maxlenreal, FALSE );
     {
        SearnRep( exppatt,expreal,lenreal,ptro,lenres);
     }
  }
  else if( *(exppatt+2) == '3' )  /*  ----  wild match marker  */
  {
     lenreal = hb_pp_strocpy( expreal, *ptri );
     *ptri += lenreal;
     SearnRep( exppatt,expreal,lenreal,ptro,lenres);
  }
  else if( *(exppatt+2) == '2' )  /*  ---- restricted match marker  */
  {
     while( **ptrmp != '>' )
     {
         *(exppatt+lenpatt++) = *((*ptrmp)++);
     }
     *(exppatt+lenpatt) = '\0';
     (*ptrmp)++;

     ptr = exppatt + 4;
     rezrestr = 0;
     while( *ptr != '\0' )
     {
        if( *ptr == '&' )
        {
           if( **ptri == '&' )
           {
              rezrestr = 1;
              /*  (*ptri)++; */
              lenreal = getExpReal( expreal, ptri, FALSE, maxlenreal, FALSE );
              SearnRep( exppatt,expreal,lenreal,ptro,lenres);
              break;
           }
           else
           {
              ptr++;
           }
        }
        else
        {
           HB_SKIPTABSPACES( ptr );
           /* Comparing real parameter and restriction value */
           ptrtemp = ptr;
           if( !strincmp( *ptri, &ptr, !com_or_xcom ) )
           {
              lenreal = stroncpy( expreal, *ptri, (ptr-ptrtemp) );
              *ptri += lenreal;
              SearnRep( exppatt,expreal,lenreal,ptro,lenres);
              rezrestr = 1;
              break;
           }
           else
           {
              while( *ptr != ',' && *ptr != '\0' )
              {
                 ptr++;
              }
              if( *ptr == ',' )
              {
                 ptr++;
              }
           }
        }
     }
     if( rezrestr == 0 )
     {
        /* If restricted match marker doesn't correspond to real parameter */
        return 0;
     }
  }
  else if( *(exppatt+2) == '1' )  /*  ---- list match marker  */
  {
     if( !lenreal )
     {
        lenreal = getExpReal( expreal, ptri, TRUE, maxlenreal, FALSE );

        #if 0
           printf( "List Len: %i Exp: %s\n", lenreal, expreal );
        #endif
     }

     if( lenreal )
     {
        SearnRep( exppatt,expreal,lenreal,ptro,lenres);
     }
     else
     {
        return 0;
     }
  }
  else                             /*  ---- regular match marker  */
  {
     /* Copying a real expression to 'expreal' */
     if( ! lenreal )
     {
        //printf( "Getting >%s<\n", *ptri );
        lenreal = getExpReal( expreal, ptri, FALSE, maxlenreal, FALSE );
     }

     //printf("Len: %i Pat: >%s< Exp: >%s<\n", lenreal, exppatt, expreal );

     if( lenreal )
     {
        SearnRep( exppatt, expreal, lenreal, ptro, lenres );
     }
     else
     {
        return 0;
     }
  }

  return 1;
}

static int getExpReal( char * expreal, char ** ptri, BOOL prlist, int maxrez, BOOL bStrict )
{
   int lens = 0;
   char * sZnaki = "+-=><*/$.:#%!^";
   int State;
   int StBr1 = 0, StBr2 = 0, StBr3 = 0;
   BOOL rez = FALSE;

   /* Ron Pinkas added 2000-06-02 */
   BOOL bMacro = FALSE;
   /* Ron Pinkas end 2000-06-02 */

   /* Ron Pinkas added 2000-06-17 */
   char cLastChar = '\0';
   /* Ron Pinkas end 2000-06-17 */

   HB_TRACE(HB_TR_DEBUG, ("getExpReal(%s, %s, %d, %d, %d)", expreal, *ptri, prlist, maxrez, bStrict));

   //printf( "\ngetExpReal( %p, '%s', %d, %d, %d )\n", expreal, *ptri, prlist, maxrez, bStrict );

   HB_SKIPTABSPACES( *ptri );

   if( strchr( "}]),|=*/^%", **ptri ) || ( strchr( ":-+", **ptri ) && *( ( *ptri) + 1 ) == '=' ) )
   {
      return 0;
   }

   State = ( **ptri=='\'' || **ptri=='\"' || **ptri=='[' ) ? STATE_EXPRES: STATE_ID;

   while( **ptri != '\0' && !rez && lens < maxrez )
   {
      /* Added by Ron Pinkas 2000-11-08 ( removed lots of related scattered logic below! */
      if( State == STATE_EXPRES || ( cLastChar && strchr( "({[.|,$!#=<>^%*/+-", cLastChar ) ) ) /* Ron Pinkas added if on State 2001-05-02 to avoid multiple strings concatination. */
      {
         if( **ptri == '"' )
         {
            if( expreal != NULL )
            {
               *expreal++ = **ptri;
            }

            (*ptri)++;
            lens++;

            while( **ptri != '\0' && lens < maxrez )
            {
               if( expreal != NULL )
               {
                  *expreal++ = **ptri;
               }

               if( **ptri == '"' )
               {
                  break;
               }

               (*ptri)++;
               lens++;
            }

            (*ptri)++;
            lens++;

            cLastChar = '"';
            State = ( StBr1==0 && StBr2==0 && StBr3==0 )? STATE_ID_END: STATE_BRACKET;
            continue;
         }
         else if( **ptri == '\'' )
         {
            char *pString;

            if( expreal != NULL )
            {
               *expreal++ = **ptri;
            }

            (*ptri)++;
            lens++;

            pString = expreal;

            while( **ptri != '\0' && lens < maxrez )
            {
               if( expreal != NULL )
               {
                  *expreal++ = **ptri;
               }

               if( **ptri == '\'' )
               {
                  break;
               }

               (*ptri)++;
               lens++;
            }

            if( expreal != NULL )
            {
               *(expreal - 1) = '\0';
               if( strchr( pString, '"' ) == NULL )
               {
                  *(pString - 1) = '"';
                  *(expreal - 1) = '"';
               }
               else
               {
                  *(expreal - 1) = '\'';
               }
            }

            (*ptri)++;
            lens++;

            cLastChar = '\'';
            State = ( StBr1==0 && StBr2==0 && StBr3==0 )? STATE_ID_END: STATE_BRACKET;
            continue;
         }
         else if( **ptri == '[' /* ( see below 5-2-2001 && ( State == STATE_EXPRES || ( strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) ) )*/ )
         {
            char *pString;

            if( expreal != NULL )
            {
               *expreal++ = **ptri;
            }

            (*ptri)++;
            lens++;

            pString = expreal;

            while( **ptri != '\0' && lens < maxrez )
            {
               if( expreal != NULL )
               {
                  *expreal++ = **ptri;
               }

               if( **ptri == ']' )
               {
                  break;
               }

               (*ptri)++;
               lens++;
            }

            if( expreal != NULL )
            {
               *(expreal - 1) = '\0';
               if( strchr( pString, '"' ) == NULL )
               {
                  *(pString - 1) = '"';
                  *(expreal - 1) = '"';
               }
               else if( strchr( pString, '\'' ) == NULL )
               {
                  *(pString - 1) = '\'';
                  *(expreal - 1) = '\'';
               }
               else
               {
                  *(expreal - 1) = ']';
               }
            }

            (*ptri)++;
            lens++;

            cLastChar = ']';
            State = ( StBr1==0 && StBr2==0 && StBr3==0 )? STATE_ID_END: STATE_BRACKET;
            continue;
         }
      /* Added by Ron Pinkas 2001-05-02 ( removed lots of related scattered logic below! */
      }
      else if( strchr( "'\"", **ptri ) ) /* New String, can't belong to extracted expression. */
      {
         break;
      }
      else if( **ptri == '[' && ( strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) ) )  /* New String, can't belong to extracted expression. */
      {
         break;
      }
      /* End - END - Added by Ron Pinkas 2000-11-05 */

      #if 0
         printf( "State: %i Char:%c\n", State, **ptri );
      #endif

      switch( State )
      {
         case STATE_BRACKET:
         {
            if( **ptri == '(' )
            {
               StBr1++;
            }
            else if( **ptri == '[' )
            {
               StBr2++;
            }
            else if( **ptri == '{' )
            {
               StBr3++;
            }
            else if( **ptri == ')' )
            {
               StBr1--;
               if( StBr1==0 && StBr2==0 && StBr3==0 )
               {
                  State = STATE_ID_END;
               }
            }
            else if( **ptri == ']' )
            {
               StBr2--;
               if( StBr1==0 && StBr2==0 && StBr3==0 )
               {
                  State = STATE_ID_END;
               }
            }
            else if( **ptri == '}' )
            {
               StBr3--;
               if( StBr1==0 && StBr2==0 && StBr3==0 )
               {
                  State = STATE_ID_END;
               }
            }

            break;
         }

         case STATE_ID:
         case STATE_ID_END:
         {
            if( ( (ISNAME(**ptri) || **ptri=='\\' || **ptri=='&') && State == STATE_ID_END ) || **ptri==',' )
            {
               if( **ptri == ',' )
               {
                  if( ! prlist )
                  {
                     rez = TRUE;
                  }
                  else
                  {
                     State = STATE_EXPRES;
                  }
               }
               else
               {
                  rez = TRUE;
               }
            }
            else if( IsInStr( **ptri, sZnaki ) )
            {
               /* Ron Pinkas added 2000-06-02 */
               if( **ptri == '.' && bMacro )
               {
                  /* Macro terminator '.' */
                  if( *(*ptri+1) == ' ' )
                  {
                     State = STATE_ID_END;
                  }

                  bMacro = FALSE;

                  /* Ron Pinkas added 2000-05-03 */
                  /* Macro terminator is NOT a coninutation char unlike '.' of logical operators, so we don't want it recorded as cLastChar! */
                  if( expreal != NULL )
                  {
                     *expreal++ = **ptri;
                  }
                  (*ptri)++;
                  lens++;
                  continue;
                  /* END - Ron Pinkas added 2000-05-03 */
               }
               else
               /* Ron Pinkas end 2000-06-02 */
                  State = STATE_EXPRES;
            }
            else if( **ptri == '(' )
            {
               State = STATE_BRACKET;
               StBr1 = 1;
            }
            else if( **ptri == '[' )
            {
               StBr2++;
               State = STATE_BRACKET;
            }
            else if( **ptri == '{' )
            {
               State = STATE_BRACKET;
               StBr3 = 1;
            }
            /* Ron Pinkas added 2001-01-08 */
            else if( **ptri == ')' && StBr1 == 0 )
            {
               rez = TRUE;
            }
            /* Ron Pinkas added 2000-06-02 */
            else if( **ptri == '&' )
            {
               bMacro = TRUE;
            }
            /* Ron Pinkas end 2000-06-02 */
            else if( **ptri == ' ' )
            {
               State = STATE_ID_END;
               /* Ron Pinkas added 2000-06-02 */
               bMacro = FALSE;
               /* Ron Pinkas end 2000-06-02 */
            }

            break;
         }

         case STATE_EXPRES:
         case STATE_EXPRES_ID:
         {
            if( **ptri == '[' )
            {
               StBr2++;
               State = STATE_BRACKET;
            }
            else if( ISNAME(**ptri) )
            {
               State = STATE_EXPRES_ID;
            }
            else if( **ptri == ' ' )
            {
               if( State == STATE_EXPRES_ID )
               {
                  State = STATE_ID_END;
               }
               else if( lens > 2 && ( ( *(*ptri-2)=='+' && *(*ptri-1)=='+' ) ||
                                    ( *(*ptri-2)=='-' && *(*ptri-1)=='-' ) ) )
               {
                  State = STATE_ID_END;
               }
            }
            /* Ron Pinkas added 2000-06-14 */
            else if( **ptri == ')' && StBr1 == 0 )
            {
               rez = TRUE;
            }
            /* Ron Pinkas end 2000-06-14 */
            else if( **ptri == '(' )
            {
               StBr1++;
               State = STATE_BRACKET;
            }
            else if( **ptri == '{' )
            {
               StBr3++;
               State = STATE_BRACKET;
            }
            else if( **ptri == ',' )
            {
               if( !prlist )
               {
                  rez = TRUE; State = STATE_EXPRES;
               }
            }
            else if( **ptri == '.' )
            {
               if( lens > 1 && *(*ptri-2) == '.' &&
                     ( *(*ptri-1) == 'T' || *(*ptri-1) == 'F' ||
                       *(*ptri-1) == 't' || *(*ptri-1) == 'f' ||
                       *(*ptri-1) == 'Y' || *(*ptri-1) == 'N' ||
                       *(*ptri-1) == 'y' || *(*ptri-1) == 'n' ) )
               {
                  State = STATE_ID_END;
               }
               else
               {
                  State = STATE_EXPRES;
                  /*
                  if( isdigit( *( *ptri + 1 ) ) )
                  {
                     State = STATE_EXPRES;
                  }
                  else if( strchr( "TFYN", toupper( *( *ptri + 1 ) ) ) && *( *ptri + 2 ) == '.' )
                  {
                     State = STATE_EXPRES;
                  }
                  else
                  {
                     rez = TRUE;
                  }
                  */
               }
            }
            else
            {
               State = STATE_EXPRES;
            }

            break;
         }
      }

      if( !rez )
      {
         /* Ron Pinkas added 2000-06-17 */
         if( **ptri != ' ' && **ptri != '\t' )
         {
            cLastChar = **ptri;
         }
         /* Ron Pinkas end 2000-06-17 */

         if( expreal != NULL )
         {
            *expreal++ = **ptri;
         }

         (*ptri)++;
         lens++;
      }
   }

   if( expreal != NULL )
   {
      if( *(expreal-1) == ' ' )
      {
         (*ptri)--;
         expreal--;
         lens--;
      }

      *expreal = '\0';
   }

   /* Ron Pinkas added 2000-06-21 */
   if( bStrict )
   {
      if( State == STATE_QUOTE1 || State == STATE_QUOTE2 || State == STATE_QUOTE3 ||
          State == STATE_BRACKET || StBr1 || StBr2 || StBr3  )
      {
          /* Alexander should we include this???
          expreal = NULL;
          */
          lens = 0;
      }
   }
   /* Ron Pinkas end 2000-06-21 */

   if( expreal )
   {
      *expreal = '\0';
   }

   #if 0
      if( lens )
      {
         printf( "Len=%i >%.*s<\n", lens, lens, *ptri - lens );
      }
      else
      {
         printf( "State %i, Inavlid Expression %s\n", State, *ptri );
      }
   #endif

   return lens;
}

static BOOL isExpres( char * stroka, BOOL prlist )
{
  int l1,l2;

  HB_TRACE(HB_TR_DEBUG, ("isExpres(%s)", stroka));

  //printf( "isExp: >%s<\n", stroka );

  l1 = strlen( stroka );
  l2 = getExpReal( NULL, &stroka, prlist, HB_PP_STR_SIZE, TRUE );

  //printf( "Len1: %i Len2: %i RealExp: >%s< Last: %c\n", l1, l2, stroka - l2, ( stroka - l2 )[l1-1] );

  /* Ron Pinkas modified 2000-06-17 Expression can't be valid if last charcter is one of these: ":/+*-%^=(<>"
  return ( l1 <= l2 );
  */

  return ( l1 <= l2 /*&& ! IsInStr( ( stroka - l2 )[l1-1], ":/+*-%^=(<>[{" ) */ );
}

static BOOL TestOptional( char *ptr1, char *ptr2 )
{
  int nbr = 0;
  BOOL flagname = FALSE;
  int statevar = 0;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("TestOptional('%s', '%s')", ptr1, ptr2));

  while( ptr1 <= ptr2 )
  {
     if( *ptr1 == '[' )
     {
        nbr++;
     }
     else if( *ptr1 == ']' )
     {
        if( nbr )
        {
           nbr--;
           flagname = FALSE;
        }
        else
        {
           return 0;
        }
     }
     else if( *ptr1 == '\1' && *(ptr1+2) == '2' && nbr )
     {
        statevar = 1;
     }
     else if( *ptr1 == '>' && statevar )
     {
        statevar = 0;
     }
     else if( *ptr1 != ' ' && *ptr1 != '\t' && !statevar )
     {
        if( nbr )
        {
           flagname = TRUE;
        }
        else
        {
           return 0;
        }
     }

     ptr1++;
  }

  /*
  if( !flagname )
  {
     while( *ptr1 != ']' )
     {
        if( *ptr1 == '[' || *ptr1 == '\0' ) return 0;
        ptr1++;
     }
  }
  */

  //printf( "nbr: %i ptr2: >%s<\n", nbr, ptr2 );

  return ( ! flagname ) && ( nbr <= 1 );
}

static BOOL CheckOptional( char * ptrmp, char * ptri, char * ptro, int * lenres, BOOL com_or_tra, BOOL com_or_xcom )
{
   int save_numBr = s_numBrackets, save_Repeate = s_Repeate;
   BOOL endTranslation = FALSE;
   BOOL bResult = TRUE;
   char * lastInputptr[ 5 ];
   char * lastopti[ 3 ], *ptr;

   HB_SYMBOL_UNUSED( com_or_tra );

   HB_TRACE(HB_TR_DEBUG, ("CheckOptional(%s, %s, %s, %p, %d, %d)", ptrmp, ptri, ptro, lenres, com_or_tra, com_or_xcom));

   s_bReplacePat = FALSE;
   lastInputptr[s_Repeate] = ptri;

   while( *ptri != '\0' && !endTranslation && bResult )
   {
      HB_SKIPTABSPACES( ptrmp );

      switch( *ptrmp )
      {
         case '[' :
           s_numBrackets++;
           s_aIsRepeate[ s_Repeate ] = 0;
           lastInputptr[s_Repeate] = ptri;
           lastopti[s_Repeate++] = ptrmp;
           ptrmp++;
           break;

         case ']' :
           if( s_numBrackets == save_numBr )
           {
              endTranslation = TRUE;
           }
           else
           {
              if( s_Repeate )
              {
                 s_Repeate--;
                 ptrmp = lastopti[s_Repeate];
              }
              else
              {
                 ptrmp++;
              }

              s_numBrackets--;
           }

           break;

         case ',' :
           if( *ptri == ',' )
           {
              ptrmp++;
              ptri++;
           }
           else
           {
              if( s_numBrackets - save_numBr > 0 )
              {
                 SkipOptional( &ptrmp );
                 ptri = lastInputptr[s_Repeate];
              }
              else
              {
                 bResult = FALSE;
              }
           }

           break;

         case '\1' :  /*  Match marker */
           //printf( "\nCheckOptional->WorkMarkers\n" );

           if( ! WorkMarkers( &ptrmp, &ptri, ptro, lenres, com_or_xcom ) )
           {
              if( s_numBrackets - save_numBr > 0 )
              {
                  SkipOptional( &ptrmp );
                  ptri = lastInputptr[s_Repeate];
              }
              else
              {
                 bResult = FALSE;
              }
           }

           break;

         case '\0':
           bResult = FALSE;

         default:    /*   Key word    */
           ptr = ptri;

           if( *ptri == ',' || truncmp( &ptri, &ptrmp, !com_or_xcom ) )
           {
              ptri = ptr;

              if( s_numBrackets - save_numBr > 0 )
              {
                 SkipOptional( &ptrmp );
                 ptri = lastInputptr[s_Repeate];
              }
              else
              {
                 bResult = FALSE;
              }
           }
      }

      HB_SKIPTABSPACES( ptri );
   }

   if( *ptri == '\0' )
   {
      do
      {
         HB_SKIPTABSPACES( ptrmp );

         if( *ptrmp == '[' )
         {
            ptrmp++;
            SkipOptional( &ptrmp );
         }
         else if( *ptrmp == ']' )
         {
            break;
         }
         else
         {
            bResult = 0;
            break;
         }
      }
      while( 1 );
   }

   s_Repeate = save_Repeate;
   s_numBrackets = save_numBr;
   s_bReplacePat = TRUE;

   return bResult;
}

static void SkipOptional( char ** ptri )
{
  int nbr = 0;

  HB_TRACE(HB_TR_DEBUG, ("SkipOptional(%p)", ptri));

  while( **ptri != ']' || nbr )
    {
      switch( **ptri ) {
      case '[':  nbr++; break;
      case ']':  nbr--; break;
      case '\1':
        (*ptri) += 3;
        if( *(*ptri-1) == '2' )
          while( **ptri != '>' ) (*ptri)++;
        break;
      }
      (*ptri)++;
    }
  if( **ptri == ']' && s_numBrackets > 0 )
    {
      if( s_Repeate ) s_Repeate--;
      s_numBrackets--; (*ptri)++;
    }
}

static void SearnRep( char * exppatt, char * expreal, int lenreal, char * ptro, int * lenres )
{
   static char expnew[ MAX_EXP ];

   int ifou, isdvig = 0;
   BOOL rezs, bFound = FALSE, bDontInstanciate = FALSE;
   int kolmarkers;
   int lennew, i;
   char lastchar = '0';
   char *ptr, *ptr2, *ptrOut = ptro;

   HB_TRACE(HB_TR_DEBUG, ("SearnRep(%s, %s, %i, %s, %p)", exppatt, expreal, lenreal, ptro, lenres));

   #ifdef DEBUG_MARKERS
      if( s_bReplacePat )
      {
         printf( "Replace '%s' with '%s' Len: %i, in '%s'\n", exppatt, expreal, lenreal, ptro );
      }
      else
      {
         printf( "Scan '%s' with '%s' Len: %i, in '%s'\n", exppatt, expreal, lenreal, ptro );
      }
   #endif

   if( *( exppatt + 1 ) == '\0' )
   {
      *( ptro + *lenres ) = '\0';
   }

   while( ( ifou = md_strAt( exppatt, ( *( exppatt + 1 ) ) ? 2 : 1, ptrOut, FALSE, FALSE, TRUE, FALSE )) > 0 ) /* ??? */
   {
      #ifdef DEBUG_MARKERS
         printf( "   Found: >%s< At: %i In: >%s< MarkerCount: %i\n", exppatt, ifou, ptrOut, (ptrOut + ifou)[2] - '0' );
      #endif

      bFound = TRUE;
      rezs = FALSE;
      ptr = ptrOut + ifou - 2;
      kolmarkers = 0;
      ptr = PrevSquare( ptr, ptrOut, &kolmarkers );

      if( ptr )
      {
         #ifdef DEBUG_MARKERS
            printf( "   Repeat: %i Previous Square: '%s'\n", s_Repeate, ptr );
         #endif

         if( s_Repeate )
         {
            s_aIsRepeate[ s_Repeate - 1 ]++;
         }

         if( !s_bReplacePat )
         {
            return;
         }

         ptr2 = ptrOut + ifou + 3;

         while( *ptr2 != ']' || *(ptr2-1) == '\\' )
         {
            if( *ptr2 == '\1' )
            {
               kolmarkers++;
            }

            ptr2++;
         }

         #ifdef DEBUG_MARKERS
            printf( "Markers: %i\n", kolmarkers );
         #endif

         if( s_Repeate && lenreal && kolmarkers && lastchar != '0' && *(ptrOut + ifou + 2) == '0' )
         {
            isdvig += ifou;
            rezs = TRUE;
         }
         else
         {
            if( lenreal == 0 )
            {
               if( s_numBrackets >= 2 )
               {
                  isdvig += ifou;
                  continue;
               }
               else
               {
                  hb_pp_Stuff( "", ptr, 0, ptr2-ptr+1, *lenres-(ptr-ptro) );
                  *lenres -= ptr2-ptr+1;
                  isdvig = ptr - ptro;
                  rezs = TRUE;
               }
            }
            else
            {
               if( s_Repeate )
               {
                  char cMarkerCount = '0', cGroupCount = '0';

                  lennew = ptr2-ptr-1;

                  // Flagging the instanciated Marker in Repeatable group as Instanciated.
                  for( i=0; i < lennew; i++ )
                  {
                     if( ptr[i] == '\1' )
                     {
                        if( ptr[i + 1] == exppatt[1] )
                        {
                            int j = i + 3;

                            ptr[ j ]++;

                            if( ptr[ j ] == '[' )
                            {
                               ptr[ j ]++;
                            }

                            if( ptr[ j ] == ']' )
                            {
                               ptr[ j ]++;
                            }

                            #ifdef DEBUG_MARKERS
                               printf( "   Marked %s as instanciated\n", ptr + i );
                            #endif

                            cMarkerCount = ptr[ j ];
                        }
                        else
                        {
                           cGroupCount = cGroupCount > ptr[ i + 3 ] ? cGroupCount : ptr[ i + 3 ];
                        }
                     }
                  }

                  // (ptrOut + ifou)[2] - '0' signify a NON repeatable forced early instanciation so no need to instanciate again for this marker.
                  if( cMarkerCount <= cGroupCount || bDontInstanciate )
                  {
                      #ifdef DEBUG_MARKERS
                         printf( "   Already instanciated %i times with %i values\n", cGroupCount - '0', cMarkerCount - '0' );
                      #endif

                      bDontInstanciate = TRUE;
                      isdvig += ifou - 1;
                      rezs = TRUE;
                      goto Instanciated;
                  }

                  memcpy( expnew, ptr+1, lennew );
                  *(expnew + lennew++) = ' ';
                  *(expnew + lennew) = '\0';

                  while( ( i = hb_strAt( exppatt, 2, expnew, lennew ) ) > 0 )
                  {
                     #ifdef DEBUG_MARKERS
                        printf( "   Expand: '%s' at %i\n", exppatt, i );
                     #endif

                     lennew += ReplacePattern( exppatt[2], expreal, lenreal, expnew+i-1, lennew );
                  }

                  if( kolmarkers )
                  {
                     s_groupchar++;

                     #ifdef DEBUG_MARKERS
                        printf( "   Increased to %c;", s_groupchar );
                     #endif

                     for( i = 0; i<lennew; i++ )
                     {
                        if( *(expnew+i) == '\1' )
                        {
                           *(expnew+i+3) = s_groupchar;

                           #ifdef DEBUG_MARKERS
                              printf( "   Group char: %s\n", (expnew+i+3) );
                           #endif

                           i += 4;
                        }
                     }
                  }

                  hb_pp_Stuff( expnew, ptr, lennew, 0, *lenres-(ptr-ptro)+1 );
                  *lenres += lennew;
                  isdvig = ptr - ptro + (ptr2-ptr-1) + lennew;
                  rezs = TRUE;

                  #ifdef DEBUG_MARKERS
                     printf( "   Instanciated Repeatable Group: %s\n", expnew );
                  #endif

                Instanciated :
                  ;
               }
               else
               {
                  // Only marker in this repeatable group, and it's not repeatable.
                  if( kolmarkers == 0 )
                  {
                     // Don't change order, must perform before expansion.
                     ptr[0]  = ' ';
                     ptr2[0] = ' ';

                     #ifdef DEBUG_MARKERS
                        printf( "   Removed Repeatable Squares for Non Repeatable exclusive Marker: '%s'\n", ptr );
                     #endif

                     // Replace sole NON repeatable into the residual repeatable container.
                     *lenres += ReplacePattern( exppatt[2], expreal, lenreal, ptrOut + ifou - 1, *lenres - isdvig - ifou + 1 );
                     isdvig += ifou - 1;

                     #ifdef DEBUG_MARKERS
                        printf( "   Replaced Non Repeatable into Residual Group '%s'\n", ptr );
                     #endif
                  }
                  else
                  {
                     lennew = ptr2 - ptr - 1;

                     // Scanning all Markers in Repeatable group to check if Instanciated.
                     for( i = 0; i < lennew; i++ )
                     {
                        if( ptr[i] == '\1' )
                        {
                           if( ptr[ i + 3 ] > '0' )
                           {
                              #ifdef DEBUG_MARKERS
                                 printf( "   '%s' Already instanciated\n", ptr + i );
                              #endif

                              isdvig = ptr2 - ptro;
                              rezs = TRUE;
                           }
                        }
                     }

                     // Maybe the group was instanciated already and since this is Non Repeatable we don't need to instanciate again.
                     if( ! rezs )
                     {
                        // Flagging all markers (EXCEPT the non repeatable that we'll be instanciated) in Repeatable group as Instanciated.
                        for( i = 0; i < lennew; i++ )
                        {
                           if( ptr[i] == '\1' )
                           {
                              if( ptr[i + 1] != exppatt[1] )
                              {
                                 ptr[ i + 3 ]++;// = '1';

                                #ifdef DEBUG_MARKERS
                                   printf( "   Marked %s as instanciated\n", ptr + i );
                                #endif
                              }
                           }
                        }

                        // *** EITHER *** this block OR the #if 0 below!!!
                        #if 1
                            while( (i = hb_strAt( exppatt, 2, ptr + 1, lennew )) > 0 )
                            {
                               #ifdef DEBUG_MARKERS
                                  printf( "   Expand: '%s' at %i\n", exppatt, i );
                               #endif

                               lennew += ReplacePattern( exppatt[2], expreal, lenreal, ptr + 1 + i - 1, lennew );
                            }

                            //printf( "   Replaced Non Repeatable into Residual Group '%s'\n", ptr );
                        #endif

                        memcpy( expnew, ptr+1, lennew );
                        *(expnew + lennew++) = ' ';
                        *(expnew + lennew) = '\0';

                        #if 0
                            while( (i = hb_strAt( exppatt, 2, expnew, lennew )) > 0 )
                            {
                               #ifdef DEBUG_MARKERS
                                  printf( "   Expand: '%s' at %i\n", exppatt, i );
                               #endif

                               lennew += ReplacePattern( exppatt[2], expreal, lenreal, expnew+i-1, lennew );
                            }
                        #endif

                        hb_pp_Stuff( expnew, ptr, lennew, 0, *lenres-(ptr-ptro)+1 );
                        *lenres += lennew;

                        isdvig = ptr - ptro + (ptr2-ptr-1) + lennew;

                        #ifdef DEBUG_MARKERS
                           printf( "   Instanciated Repeatable Group: %s with Non Repeatable %s\n", expnew, expreal );
                        #endif

                        bDontInstanciate = TRUE;
                     }
                  }

                  rezs = TRUE;
               }
            }
         }
      }

      if( ( ! rezs ) && s_bReplacePat )
      {
         if( *(ptrOut + ifou + 2) != '0' && *(exppatt+1) )
         {
            if( lastchar == '0' )
            {
               lastchar = *(ptrOut + ifou + 2);
            }

            #ifdef DEBUG_MARKERS
               printf( "Repeate: %i lastchar: '%c' '%c'\n", s_Repeate, lastchar, *(ptrOut + ifou + 2) );
            #endif

            // Ron Pinkas added [s_Repeate &&] 2002-04-26
            if( s_Repeate && lastchar != *(ptrOut + ifou + 2) )
            {
               isdvig += ifou + 3;
               ptrOut = ptro + isdvig;
               continue;
            }
         }

         #ifdef DEBUG_MARKERS
            printf( "   2\n" );
         #endif

         if( ( ptrOut + ifou )[2] - '0' )
         {
            bDontInstanciate = TRUE;
            //printf( "Expnading place holder, and flaged for NO instanciation." );
         }

         *lenres += ReplacePattern( exppatt[2], expreal, lenreal, ptrOut + ifou - 1, *lenres-isdvig-ifou+1 );
         isdvig += ifou - 1;
      }
      else if( !s_bReplacePat )
      {
         isdvig += ifou;
      }

      ptrOut = ptro + isdvig;
   }

   if( !bFound && s_Repeate )
   {
      s_aIsRepeate[ s_Repeate - 1 ]++;
   }

   #ifdef DEBUG_MARKERS
      printf( "Replaced '%s' with '%s' => >%s<\n\n", exppatt, expreal, ptro );
   #endif
}

static int ReplacePattern( char patttype, char * expreal, int lenreal, char * ptro, int lenres )
{
  int rmlen = lenreal, ifou, lenitem, i;
  char sQuotes[ 4 ] = "\"\",";

  HB_TRACE(HB_TR_DEBUG, ("ReplacePattern(%c, %s, %i, %s, %i)", patttype, expreal, lenreal, ptro, lenres));

  lenreal--;
  while( expreal[ lenreal ] == ' ' )
  {
     lenreal--;
  }
  lenreal++;

  #ifdef DEBUG_MARKERS
     printf( "   %c, '%s', %i, '%s', %i\n", patttype, expreal, lenreal, ptro, lenres );
  #endif

  switch( *(ptro+2) ) {
  case '0':  /* Regular result marker  */
    hb_pp_Stuff( expreal, ptro, lenreal, 4, lenres );
    break;
  case '1':  /* Dumb stringify result marker  */
    pp_rQuotes( expreal, sQuotes );
    hb_pp_Stuff( sQuotes, ptro, 2, 4, lenres );
    if( lenreal )
      hb_pp_Stuff( expreal, ptro+1, lenreal, 0, lenres );
    rmlen = lenreal + 2;
    break;
  case '2':  /* Normal stringify result marker  */
    if( !lenreal )
      hb_pp_Stuff( "", ptro, 0, 4, lenres );
    else if( patttype == '1' )          /* list match marker */
      {
        hb_pp_Stuff( "", ptro, 0, 4, lenres );
        lenres -= 4;
        rmlen = 0;
        do
          {
            ifou = md_strAt( ",", 1, expreal, FALSE, TRUE, FALSE, FALSE );
            lenitem = (ifou)? ifou-1:lenreal;
            if( *expreal != '\0' )
              {
                /* Ron Pinkas added 2000-01-21 */
                if( *expreal == '&' )
                {
                  i = 0;
                  if( ! ifou )
                  {
                    lenitem--;
                    if( expreal[lenitem - 1] == '.' )
                    {
                       lenitem--;
                    }
                  }
                  hb_pp_Stuff( expreal + 1, ptro, lenitem, 0, lenres );
                }
                else /* END Ron Pinkas 2000-01-21 */
                {
                  i = (ifou)? 3:2;
                  pp_rQuotes( expreal, sQuotes );
                  hb_pp_Stuff( sQuotes, ptro, i, 0, lenres );
                  hb_pp_Stuff( expreal, ptro+1, lenitem, 0, lenres+i );
                }
                ptro += i + lenitem;
                rmlen += i + lenitem;
              }
            expreal += ifou;
            lenreal -= ifou;
          }
        while( ifou > 0 );
      }
    else
      {
        /* Ron Pinkas added 2000-01-21 */
        if( *expreal == '&' )
        {
          rmlen--;
          if( expreal[lenreal - 1] == '.' )
          {
            rmlen--;
            lenreal--;
          }
          hb_pp_Stuff( expreal + 1, ptro, lenreal - 1, 4, lenres );
        }
        else /* END Ron Pinkas 2000-01-21 */
        {
          pp_rQuotes( expreal, sQuotes );
          hb_pp_Stuff( sQuotes, ptro, 2, 4, lenres );
          hb_pp_Stuff( expreal, ptro+1, lenreal, 0, lenres );
          rmlen = lenreal + 2;
        }
      }
    break;
  case '3':  /* Smart stringify result marker  */
    if( patttype == '1' )          /* list match marker */
      {
        hb_pp_Stuff( "", ptro, 0, 4, lenres );
        lenres -= 4;
        rmlen = 0;
        do
          {
            ifou = md_strAt( ",", 1, expreal, FALSE, TRUE, FALSE, FALSE );
            lenitem = (ifou)? ifou-1:lenreal;
            if( *expreal != '\0' )
              {
                if( !lenitem || *expreal == '(' || (*expreal=='&' && lenreal>1) ||
                     ( *expreal=='\"' && *(expreal+lenitem-1)=='\"' ) ||
                     ( *expreal == '\'' && *(expreal+lenitem-1)=='\'' ) )
                  {
                    if( ifou ) lenitem++;
                    if( *expreal == '&' )
                    {
                       lenitem--;
                       if( expreal[lenitem - 1] == '.' )
                       {
                          lenitem--;
                       }
                    }
                    hb_pp_Stuff( ( *expreal=='&' ) ? expreal + 1 : expreal, ptro,
                              lenitem, 0, lenres );
                  }
                else
                  {
                    i = (ifou)? 3:2;
                    pp_rQuotes( expreal, sQuotes );
                    hb_pp_Stuff( sQuotes, ptro, i, 0, lenres );
                    hb_pp_Stuff( expreal, ptro+1, lenitem, 0, lenres+i );
                    ptro += i;
                    rmlen += i;
                  }
                ptro += lenitem;
                rmlen += lenitem;
              }
            expreal += ifou;
            lenreal -= ifou;
          }
        while( ifou > 0 );
      }
    else if( !lenreal || *expreal == '(' || (*expreal=='&' && lenreal>1) ||
             ( *expreal == '\"' && *( expreal + lenreal - 1 ) == '\"' ) ||
             ( *expreal == '\'' && *( expreal + lenreal - 1 ) == '\'' ) )
      {
        if( *expreal == '&' )
        {
          rmlen--;
          if( expreal[lenreal - 1] == '.' )
          {
            rmlen--;
            lenreal--;
          }
        }
        hb_pp_Stuff( ( *expreal == '&' ) ? expreal + 1 : expreal, ptro,
                ( *expreal == '&' ) ? lenreal - 1 : lenreal, 4, lenres );
      }
    else
      {
        pp_rQuotes( expreal, sQuotes );
        hb_pp_Stuff( sQuotes, ptro, 2, 4, lenres );
        hb_pp_Stuff( expreal, ptro + 1, lenreal, 0, lenres );
        rmlen = lenreal + 2;
      }
    break;
  case '4':  /* Blockify result marker  */
    if( !lenreal )
      hb_pp_Stuff( expreal, ptro, lenreal, 4, lenres );
    else if( patttype == '1' )          /* list match marker */
      {
        hb_pp_Stuff( "", ptro, 0, 4, lenres );
        lenres -= 4;
        rmlen = 0;
        do
          {
            ifou = md_strAt( ",", 1, expreal, FALSE, TRUE, FALSE, FALSE );
            lenitem = (ifou)? ifou-1:lenreal;
            if( *expreal != '\0' )
              {
                i = (ifou)? 5:4;
                hb_pp_Stuff( "{||},", ptro, i, 0, lenres );
                hb_pp_Stuff( expreal, ptro+3, lenitem, 0, lenres+i );
                ptro += i + lenitem;
                rmlen += i + lenitem;
              }
            expreal += ifou;
            lenreal -= ifou;
          }
        while( ifou > 0 );
      }
    else if( lenreal && *expreal == '{' )
      {
        hb_pp_Stuff( expreal, ptro, lenreal, 4, lenres );
      }
    else
      {
        hb_pp_Stuff( "{||}", ptro, 4, 4, lenres );
        hb_pp_Stuff( expreal, ptro+3, lenreal, 0, lenres );
        rmlen = lenreal + 4;
      }
    break;
  case '5':  /* Logify result marker  */
    rmlen = 3;
    if( !lenreal )
      {
        hb_pp_Stuff( ".F.", ptro, 3, 4, lenres );
      }
    else
      hb_pp_Stuff( ".T.", ptro, 3, 4, lenres );
    break;
  case '6':  /* Ommit result marker  */
    rmlen = 0;
    hb_pp_Stuff( " ", ptro, 1, 4, lenres );
    break;
  }

  #ifdef DEBUG_MARKERS
     printf( "   '%s', '%s'\n", expreal, ptro );
  #endif

  return rmlen - 4;
}

static void pp_rQuotes( char * expreal, char * sQuotes )
{
  BOOL lQuote1 = FALSE;
  BOOL lQuote2 = FALSE;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("pp_rQuotes(%s, %s)", expreal, sQuotes));

  //printf( "String: >%s< Delim: %s\n", expreal, sQuotes );

  while( *expreal != '\0' )
  {
     if( *expreal == '\"' )
     {
        lQuote2 = TRUE;
     }
     else if( *expreal == '\'' )
     {
        lQuote1 = TRUE;
     }

     expreal++;
  }

  if( lQuote2 )
  {
     if( lQuote1 )
     {
        *sQuotes = '[';
        *(sQuotes+1) = ']';
     }
     else
     {
        *sQuotes = '\'';
        *(sQuotes+1) = '\'';
     }
  }
  else
  {
     *sQuotes = '\"';
     *(sQuotes+1) = '\"';
  }
}

int hb_pp_RdStr( FILE * handl_i, char * buffer, int maxlen, BOOL lDropSpaces, char * sBuffer, int * lenBuffer, int * iBuffer, int State )
{
#ifndef __WATCOMC__
  extern BOOL hb_pp_bInline;
#endif
  int readed = 0;
  char cha, cLast = '\0', symbLast = '\0';
  BOOL bOK = TRUE;

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_RdStr(%p, %s, %d, %d, %s, %p, %p, %i)", handl_i, buffer, maxlen, lDropSpaces, sBuffer, lenBuffer, iBuffer, State));

  if( *lenBuffer == 0 )
  {
    return -1;
  }

  while(1)
  {
    //printf( "Max: %i, Readed: %i <%.*s>\n", maxlen, readed, readed, buffer );

    if( *iBuffer == *lenBuffer )
    {
      if( (*lenBuffer = fread(sBuffer, 1, HB_PP_BUFF_SIZE, handl_i ) ) < 1 )
      {
        sBuffer[0] = '\n';
      }
      *iBuffer = 0;
    }

    cha = sBuffer[ *iBuffer ];
    (*iBuffer)++;

    if( cha == '\r' )
    {
      cha = ' ';
    }

    if( cha == '\n' )
    {
      if( ( ! hb_pp_bInline ) && s_ParseState == STATE_COMMENT && symbLast == ';' )
      {
        if( readed == maxlen )
        {
           hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_BUFFER_OVERFLOW, NULL, NULL );
        }

        buffer[readed++] = ';';
      }
      break;
    }
    else
    {
      if( hb_pp_bInline )
      {
        if( readed == maxlen )
        {
           hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_BUFFER_OVERFLOW, NULL, NULL );
        }

        buffer[readed++] = cha;
        continue;
      }
    }

    if( bOK )
    {
      switch( s_ParseState )
      {
        case STATE_COMMENT:
          if( cha == '/' && cLast == '*' )
          {
             s_ParseState = STATE_NORMAL;
             cha = ' ';
          }

          cLast = cha;

          if( cha != ' ' && cha != '\t' )
          {
             symbLast = cha;
          }
          break;

        case STATE_QUOTE1: if(cha=='\'')
          s_ParseState = STATE_NORMAL;
          break;

        case STATE_QUOTE2: if(cha=='\"')
          s_ParseState = STATE_NORMAL;
          break;

        case STATE_QUOTE3: if(cha==']')
          s_ParseState = STATE_NORMAL;
          break;

        default:
          switch( cha )
          {
            case '[':
              /* Ron Pinkas modified 2000-06-17
              if( ISNAME(s_prevchar) || s_prevchar == ']' )
              */
              if( ISNAME(s_prevchar) || strchr( ")]}.\"'", s_prevchar ) )
              {
                 s_ParseState = STATE_BRACKET;
              }
              else
              {
                 s_ParseState = STATE_QUOTE3;
              }
              break;

            case ']':
              s_ParseState = STATE_NORMAL;
              break;

            case '\"':
              if( s_ParseState != STATE_BRACKET )
              {
                s_ParseState = STATE_QUOTE2;
              }
              break;

            case '\'':
              if( s_ParseState != STATE_BRACKET )
              {
                s_ParseState = STATE_QUOTE1;
              }
              break;

            case '&':
              if( readed > 0 && buffer[readed-1] == '&' )
              {
                bOK = FALSE;
                readed--;
              }
              break;

            case '/':
              if( readed>0 && buffer[readed-1] == '/' )
              {
                bOK = FALSE;
                readed--;
              }
              break;

            case '*':
              if( readed > 0 && buffer[readed-1] == '/' )
              {
                s_ParseState = STATE_COMMENT;
                readed--;
              }
              else if( !State )
              {
                bOK = FALSE;
                readed = 0;
              }
              break;
          }

          if( cha != ' ' && cha != ';' )
          {
            s_prevchar = cha;
          }
      }

      if( cha != ' ' && cha != '\t' )
      {
        State = 1;
      }

      if( lDropSpaces && State )
      {
        lDropSpaces = 0;
      }

      if( bOK && (! lDropSpaces || readed == 0 ) && s_ParseState != STATE_COMMENT )
      {
        if( readed == maxlen )
        {
           hb_compGenError( hb_pp_szErrors, 'F', HB_PP_ERR_BUFFER_OVERFLOW, NULL, NULL );
        }

        buffer[readed++]=cha;
      }
    }
  }

  while(--readed >= 0 && ( buffer[readed] == ' ' || buffer[readed] == '\t') );

  /* rglab: start */
  if( cha == '\n' && readed < 0 )
  {
    readed = 0;
    buffer[ readed ] = ' ';   /* return an empty line */
  }

  /* rglab: end */
  if( buffer[readed] != ';' && s_ParseState != STATE_COMMENT )
  {
    s_ParseState = STATE_NORMAL;
  }

  readed++;
  buffer[readed]='\0';

  #if 0
     printf( "%s\n", buffer );
  #endif

  return readed;
}

int hb_pp_WrStr( FILE * handl_o, char * buffer )
{
#ifndef __WATCOMC__
  extern int hb_pp_LastOutLine;
#endif
  int lens = strlen(buffer);

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("hb_pp_WrStr(%p, >%s<)", handl_o, buffer ));

  /* Ron Pinkas added 2001-01-20 */
  if( hb_comp_files.iFiles == 1 )
  {
    for( ; hb_pp_LastOutLine < hb_comp_iLine - 1; hb_pp_LastOutLine++ )
    {
      fwrite("\n",1,1,handl_o);
    }
    hb_pp_LastOutLine = hb_comp_iLine;
  }
  /* END Ron Pinkas added 2001-01-20 */

  fwrite(buffer,lens,1,handl_o);

  if( *(buffer+lens-1) != '\n' )
  {
    fwrite("\n",1,1,handl_o);
  }

  return 0;
}

static int md_strAt( char * szSub, int lSubLen, char * szText, BOOL checkword, BOOL checkPrth, BOOL bRule, BOOL bUpper )
{
  int State = STATE_NORMAL;
  long lPos = 0, lSubPos = 0;
  int kolPrth = 0, kolSquare = 0, kolFig = 0;
  char cLastChar = '\0';

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("md_strAt(%s, %d, %s, %i, %i, %i)", szSub, lSubLen, szText, checkword, checkPrth, bRule, bUpper ));

  //printf( "\nmd_strAt( '%s', %d, '%s', %i, %i, %i )\n", szSub, lSubLen, szText, checkword, checkPrth, bRule, bUpper );

  while( *(szText+lPos) != '\0' && lSubPos < lSubLen )
  {
     if( State == STATE_QUOTE1 )
     {
        if( *(szText+lPos) == '\'' )
        {
           State = STATE_NORMAL;
        }
        lPos++;
     }
     else if( State == STATE_QUOTE2 )
     {
        if( *(szText+lPos) == '\"' )
        {
           State = STATE_NORMAL;
        }
        lPos++;
     }
     else if( State == STATE_QUOTE3 )
     {
        if( *(szText+lPos) == ']' )
        {
           State = STATE_NORMAL;
        }
        lPos++;
     }
     else
     {
        if( State == STATE_BRACKET )
        {
           if( *(szText+lPos) == ']' && ( lPos == 0 || *(szText+lPos-1) != '\\' ) )
           {
              kolSquare--;
              if( kolSquare == 0 )
              {
                 State = STATE_NORMAL;
              }

              cLastChar = ']';
              lPos++;
              continue;
           }
           else if( *(szText+lPos) == '[' && ( lPos == 0 || *(szText+lPos-1) != '\\' ) )
           {
              kolSquare++;
              cLastChar = '[';
              lPos++;
              continue;
           }
           else if( *(szText+lPos) == ',' )
           {
              cLastChar = ',';
              lPos++;
              continue;
           }
        }
        else
        {
           if( ( *(szText+lPos) == '\'' || *(szText+lPos) == '`' ) && ( lPos == 0 || *(szText+lPos-1) != '\\' ) )
           {
              State = STATE_QUOTE1;
              lPos++;
              continue;
           }
           else if( *(szText+lPos) == '\"' && ( lPos == 0 || *(szText+lPos-1) != '\\' ) )
           {
              State = STATE_QUOTE2;
              lPos++;
              continue;
           }
           else if( bRule == FALSE && *(szText+lPos) == '[' && strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) )
           {
              State = STATE_QUOTE3;
              lPos++;
              continue;
           }
           else if( *(szText+lPos) == '[' && ( lPos == 0 || *(szText+lPos-1) != '\\' ) )
           {
              State = STATE_BRACKET;
              kolSquare++;
              cLastChar = '[';
              lPos++;
              continue;
           }
           else if( *(szText+lPos) == '(' )
           {
              kolPrth++;
           }
           else if( *(szText+lPos) == ')' )
           {
              kolPrth--;
           }
           else if( *(szText+lPos) == '{' )
           {
              kolFig++;
           }
           else if( *(szText+lPos) == '}' )
           {
              kolFig--;
           }
           else if( szText[lPos] == '.' && ( szSub[lSubPos] != '.' || lSubLen == 1 ) )
           {
              if( toupper( szText[lPos + 1] ) == 'T' && szText[lPos + 2] == '.' )
              {
                 lPos += 3;
              }
              else if( toupper( szText[lPos + 1] ) == 'F' && szText[lPos + 2] == '.' )
              {
                 lPos += 3;
              }
              else if( toupper( szText[lPos + 1] ) == 'Y' && szText[lPos + 2] == '.' )
              {
                 lPos += 3;
              }
              else if( toupper( szText[lPos + 1] ) == 'N' && szText[lPos + 2] == '.' )
              {
                 lPos += 3;
              }
              else if( toupper( szText[lPos + 1] ) == 'O' && toupper( szText[lPos + 2] ) == 'R' && szText[lPos + 4] == '.' )
              {
                 lPos += 4;
              }
              else if( toupper( szText[lPos + 1] ) == 'A' && toupper( szText[lPos + 2] ) == 'N' && toupper( szText[lPos + 3] ) == 'D' && szText[lPos + 4] == '.' )
              {
                 lPos += 5;
              }
              else if( toupper( szText[lPos + 1] ) == 'N' && toupper( szText[lPos + 2] ) == 'O' && toupper( szText[lPos + 3] ) == 'T' && szText[lPos + 4] == '.' )
              {
                 lPos += 5;
              }
              else if( lPos && isdigit( szText[lPos - 1] ) && isdigit( szText[lPos + 1] ) )
              {
                 lPos++;

                 while( isdigit( szText[lPos] ) )
                 {
                    lPos++;
                 }
              }
              else
              {
                 if( szSub[lSubPos] != '.' )
                 {
                    lPos++;
                 }
              }

              if( szSub[lSubPos] != '.' )
              {
                 lSubPos = 0;
                 continue;
              }
           }
        }

        if( ( !lSubPos ) && checkPrth &&
          ( ( (kolPrth > 1) || (kolPrth == 1 && *(szText+lPos) != '(') || (kolPrth == 0 && *(szText+lPos) == ')') )
            || ( (kolFig > 1) || (kolFig == 1 && *(szText+lPos) != '{') || (kolFig == 0 && *(szText+lPos) == '}') ) ) )
        {
           cLastChar = *(szText+lPos);
           lPos++;
           continue;
        }

        if( ( bUpper && toupper(*(szText + lPos)) == toupper(*(szSub + lSubPos)) ) || ( ! bUpper && *(szText + lPos) == *(szSub + lSubPos) ) )
        {
           lSubPos++;
           cLastChar = *(szText+lPos);
           lPos++;

           if( lSubPos >= lSubLen  && checkword &&
               ( ( ISNAME(*szSub) && lPos>lSubPos && ISNAME(*(szText+lPos-lSubPos-1)) ) ||
               ( ISNAME(*(szSub+lSubLen-1)) && ISNAME(*(szText+lPos)) ) ) )
           {
              lSubPos = 0;
           }
        }
        else if( lSubPos )
        {
           lSubPos = 0;

           // Current character will be rechecked as possible new begining (lPos not incremented)!
           if( kolPrth && *(szText+lPos) == '(' )
           {
              kolPrth--;
           }
           else if( kolFig && *(szText+lPos) == '{' )
           {
              kolFig--;
           }
        }
        else
        {
           cLastChar = *(szText+lPos);
           lPos++;
        }
     }
  }

  #if 0
     if( bRule )
     {
        printf( "Finished (Rule: %i) Find: >%s< In: >%s<\n", bRule, szSub, szText );
     }
     else
     {
        printf( "Finished - Find: >%s< In: >%s<\n", szSub, szText );
     }

     if( lSubPos == lSubLen )
     {
        printf( "Found at Pos: %i >%s<\n", lPos - lSubLen, ( szText + lPos- lSubLen ) );
     }
  #endif

  return ( lSubPos < lSubLen ? 0 : lPos - lSubLen + 1 );
}

static char * PrevSquare( char * ptr, char * bound, int * kolmark )
{
   int State = STATE_NORMAL;

   HB_TRACE_STEALTH(HB_TR_DEBUG, ("PrevSquare(%s, %s, %p, %i)", ptr, bound, kolmark, ( kolmark ? *kolmark: 0 )));

   while( ptr > bound )
   {
      if( State == STATE_QUOTE1 )
      {
         if( *ptr == '\'' )  State = STATE_NORMAL;
      }
      else if( State == STATE_QUOTE2 )
      {
         if( *ptr == '\"' )  State = STATE_NORMAL;
      }
      else
      {
         if( *ptr == '\"' && *(ptr-1) != '\\' ) State = STATE_QUOTE2;
         else if( *ptr == '\'' && *(ptr-1) != '\\' ) State = STATE_QUOTE1;
         else if( kolmark && *ptr == '\1' ) (*kolmark)++;
         else if( ( *ptr == '[' || *ptr == ']' ) && *(ptr-1) != '\\' )
            break;
      }
      ptr--;
   }

   return ( *ptr == '[' && State == STATE_NORMAL ) ? ptr : NULL;
}

static int IsInStr( char symb, char * s )
{
  HB_TRACE(HB_TR_DEBUG, ("IsInStr(%c, %s)", symb, s));

  while( *s != '\0' ) if( *s++ == symb ) return 1;
  return 0;
}

void hb_pp_Stuff( char *ptri, char * ptro, int len1, int len2, int lenres )
{
  char *ptr1, *ptr2;
  int i;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("hb_pp_Stuff(%s, %s, %d, %d, %d)", ptri, ptro, len1, len2, lenres));

  if( len1 > len2 )
  {
     ptr1 = ptro + lenres;
     ptr2 = ptro + lenres + len1 - len2;

     for( i = 0; i <= lenres; ptr1--, ptr2--, i++ )
     {
        *ptr2 = *ptr1;
     }
  }
  else
  {
     ptr1 = ptro + len2;
     ptr2 = ptro + len1;

     for( ; ptr1 <= ptro + lenres; ptr1++, ptr2++ )
     {
        *ptr2 = *ptr1;
     }
  }

  ptr2 = ptro;

  for( i = 0; i < len1; i++ )
  {
     *ptr2++ = *( ptri + i );
  }
}

int hb_pp_strocpy( char * ptro, char * ptri )
{
  int lens = 0;

  HB_TRACE(HB_TR_DEBUG, ("hb_pp_strocpy(%s, %s)", ptro, ptri));

  if( ptri != NULL )
    while( *ptri != '\0' )
      {
        *ptro++ = *ptri++;
        lens++;
      }
  *ptro = '\0';
  return lens;
}

static int stroncpy( char * ptro, char * ptri, int lens )
{
  int i = 0;

  HB_TRACE(HB_TR_DEBUG, ("stroncpy(%s, %s, %d)", ptro, ptri, lens));

  for( ; i < lens; i++ ) *(ptro+i) = *ptri++;
  i--;
  while( i > 0 && *(ptro+i) == ' ' ) i--;
  i++;
  *(ptro+i) = '\0';
  return i;
}

static BOOL truncmp( char ** ptro, char ** ptri, BOOL lTrunc )
{
  char *ptrb = *ptro, co, ci;

  HB_TRACE(HB_TR_DEBUG, ("truncmp(%p, %p, %d)", ptro, ptri, lTrunc));

  //printf( "Input: '%s' MP: '%s'\n", *ptro, *ptri );

  /* 2003-02-19 Ron Pinkas replaced with code below.
  while( **ptri && **ptri != ' ' && **ptri != '\t' &&
         **ptri != ',' && **ptri != '[' && **ptri != ']' &&
         **ptri != '\1' && toupper(**ptri) == toupper(**ptro) )
  {
     (*ptro)++;
     (*ptri)++;
  }
  */

  while( **ptri && **ptro )
  {
     if( strchr( "({:=+-*/<>$^%#!", **ptri ) )
     {
        while( **ptro == ' ' || **ptro == '\t' )
        {
           (*ptro)++;
        }
     }

     if( **ptri == ' ' || **ptri == ',' || **ptri == '[' || **ptri == ']' || **ptri == '\1' || toupper( **ptri ) != toupper( **ptro ) )
     {
        break;
     }

     (*ptro)++;
     (*ptri)++;
  }

  co = *(*ptro-1);
  ci = **ptri;

  if( ( ( ci == ' ' || ci == ',' || ci == '[' || ci == ']' || ci == '\1' || ci == '\0' ) &&
        ( ( ! ISNAME( **ptro ) && ISNAME( co ) ) || ( ! ISNAME( co ) ) ) ) )
  {
     /*
      * Reject the token if it ends with first char of a Bi-Char.
      */

     // Bi Chars: "\:=\==\!=\>=\<=\+=\-=\*=\/=\^=\%=\"
     if( strchr( ":=!><+-*/^%", co ) && **ptro == '=' )
     {
        //printf( ">>>Rejected: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );
        return TRUE;
     }
     // BI-Chars: "\++\--\**\"
     else if( strchr( "+-*", co ) && **ptro == co )
     {
        //printf( ">>>Rejected: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );
        return TRUE;
     }
     // BI-Chars: "\->\<>\"
     else if( strchr( "->", co ) && **ptro == '>' )
     {
        //printf( ">>>Rejected: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );
        return TRUE;
     }

     //printf( ">>>Accepted: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );

     return FALSE;
  }
  else if( lTrunc && *ptro-ptrb >= 4 && ISNAME(ci) && !ISNAME(**ptro) && ISNAME(co) )
  {
      while( ISNAME(**ptri) )
      {
        (*ptri)++;
      }

      //printf( ">>>Accepted: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );
      return FALSE;
  }

  //printf( ">>>Rejected: '%s', MP: '%s', co: '%c', ci: '%c'\n", *ptro, *ptri, co, ci );
  return TRUE;
}

static BOOL strincmp( char * ptro, char ** ptri, BOOL lTrunc )
{
  char *ptrb = ptro, co, ci;

  HB_TRACE(HB_TR_DEBUG, ("strincmp(%s, %p)", ptro, ptri));

  for( ; **ptri != ',' && **ptri != '[' && **ptri != ']' &&
         **ptri != '\1' && **ptri != '\0' && toupper(**ptri)==toupper(*ptro);
        ptro++, (*ptri)++ );
  co = *(ptro-1);
  ci = **ptri;
  if( ( ( ci == ' ' || ci == ',' || ci == '[' ||
          ci == ']' || ci == '\1' || ci == '\0' ) &&
        ( ( !ISNAME(*ptro) && ISNAME(co) ) ||
          ( !ISNAME(co) ) ) ) )
    return FALSE;
  else if( lTrunc && ptro-ptrb >= 4 && ISNAME(ci) && !ISNAME(*ptro) && ISNAME(co) )
    {
      /*      while( ISNAME(**ptri) ) (*ptri)++; */
      return FALSE;
    }
  return TRUE;
}

static int strincpy( char * ptro, char * ptri )
{
  int len = 0;

  HB_TRACE(HB_TR_DEBUG, ("strincpy(%s, %s)", ptro, ptri));

  while( *ptri )
  {
     if( *ptri == ' ' || *ptri == ',' || *ptri == '[' || *ptri == ']' || *ptri == '\1' )
     {
        break;
     }

     if( len && ( *ptri == '(' || *ptri == ')' ) )
     {
        break;
     }

     *ptro = *ptri;

     ptro++, ptri++, len++;
  }

  return len;
}

static int strotrim( char * stroka, BOOL bRule )
{
  char *ptr = stroka, *pString, lastc = '0', curc;
  int lens = 0, State = STATE_NORMAL;

  char cLastChar = '\0';

  char *sFirstToken = stroka;

  HB_TRACE(HB_TR_DEBUG, ("strotrim(%s)", stroka));

  #if 0
     printf( "StrIn: >%s<\n", stroka );
  #endif

  while( ( curc = *stroka ) != '\0' )
  {
     if( State == STATE_QUOTE1 )
     {
        if( curc == '\'' )
        {
           State = STATE_NORMAL;

           if( ! bRule )
           {
              *stroka = '\0';

              if( strchr( pString, '"' ) == NULL )
              {
                 *pString = '"';
                 *stroka = '"';
              }
              else
              {
                 *stroka = '\'';
              }

              curc = *stroka;
           }
        }
     }
     else if( State == STATE_QUOTE2 )
     {
        if( curc == '\"' )
        {
           State = STATE_NORMAL;
        }
     }
     else if( State == STATE_QUOTE3 )
     {
        if( curc == ']' )
        {
           State = STATE_NORMAL;

           if( ! bRule )
           {
              *stroka = '\0';

              if( strchr( pString, '"' ) == NULL )
              {
                 *pString = '"';
                 *stroka = '"';
              }
              else if( strchr( pString, '\'' ) == NULL )
              {
                 *pString = '\'';
                 *stroka = '\'';
              }
              else
              {
                 *stroka = ']';
              }

              curc = *stroka;
           }
        }
     }
     else
     {
        if( curc == '\'' )
        {
           pString = ptr;
           State = STATE_QUOTE1;
        }
        else if( curc == '\"' )
        {
           pString = ptr;
           State = STATE_QUOTE2;
        }
        /* Ron Pinkas added 2000-11-05 */
        /* Ron Pinkas 2001-02-14 added bRule logic */
        else if( curc == '[' && bRule == FALSE && ( strchr( ")]}.\"'\\", cLastChar ) == NULL ) )
        {
           if( ISNAME( cLastChar ) )
           {
              if( lens < 8 && toupper( sFirstToken[0] ) == 'R' && toupper( sFirstToken[1] ) == 'E' &&
                  toupper( sFirstToken[2] ) == 'T' && toupper( sFirstToken[3] ) == 'U'  )
              {
                 if( sFirstToken[4] == ' ' )
                 {
                    pString = ptr;
                    State = STATE_QUOTE3;
                 }
                 else if( toupper( sFirstToken[4] ) == 'R' )
                 {
                    if( sFirstToken[5] == ' ' )
                    {
                       pString = ptr;
                       State = STATE_QUOTE3;
                    }
                    else if( toupper( sFirstToken[5] ) == 'N' && sFirstToken[6] == ' ' )
                    {
                       pString = ptr;
                       State = STATE_QUOTE3;
                    }
                 }
              }
           }
           else
           {
              pString = ptr;
              State = STATE_QUOTE3;
           }
        }
        /* END - Ron Pinkas added 2000-11-05 */
        else if( curc == '\t' )
        {
           curc = ' ';
        }
        else if( bRule == FALSE && curc == ';' )
        {
           char *pTmp = stroka + 1;

           while( *pTmp == ' ' || *pTmp == '\t' )
           {
              pTmp++;
           }

           if( *pTmp == '#' )
           {
              bRule = TRUE;
           }

           // Intentionally NOT resetting bRule!
        }
     }

     if( State != STATE_NORMAL || curc != ' ' || ( curc == ' ' && *( stroka + 1 ) != '\0' && lastc != ' ' && lastc != ',' && lastc != '(' && *( stroka + 1 ) != ',' ) )
     {
        *ptr++ = curc;
        lastc = curc;
        lens++;

        if( State == STATE_NORMAL )
        {
           if( curc != ' ' )
           {
              cLastChar = curc;
           }
        }
     }

     stroka++;
  }

  *ptr = '\0';

  #if 0
     printf( "Str Out: >%s<\n", ptr - lens );
  #endif

  return lens;
}

static int NextWord( char ** sSource, char * sDest, BOOL lLower )
{
  int i = 0;

  HB_TRACE(HB_TR_DEBUG, ("NextWord(%p, %s, %d)", sSource, sDest, lLower));

  HB_SKIPTABSPACES( (*sSource) );

  while( **sSource != '\0' && **sSource != ' ' && **sSource != '\t' && **sSource != '(')
  {
     *sDest++ = (lLower)? tolower(**sSource):**sSource;
     (*sSource)++;
     i++;
  }

  *sDest = '\0';

  return i;
}

static int NextName( char ** sSource, char * sDest )
{
  /* Ron Pinkas added 2000-11-08 */
  char cLastChar = '\32', *pString = NULL, *pTmp;
  /* END - Ron Pinkas added 2000-11-08 */

  int lenName = 0, State = STATE_NORMAL;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("NextName(%p, %s)", sSource, sDest));

  #if 0
     printf( "In: >%s<\n", *sSource );
  #endif

  while( **sSource != '\0' && ( State != STATE_NORMAL || **sSource != '_' && ! isalpha( **sSource ) ) )
  {
     if( State == STATE_QUOTE1 )
     {
        if( **sSource == '\'' )
        {
           State = STATE_NORMAL;

           /* Ron Pinkas added 2000-11-08 */
           **sSource = '\0';
           if( strchr( pString, '"' ) == NULL )
           {
              *pString = '"';
              **sSource = '"';
           }
           else
           {
              **sSource = '\'';
           }
           /* END - Ron Pinkas added 2000-11-08 */
        }
     }
     else if( State == STATE_QUOTE2 )
     {
        if( **sSource == '\"' )
        {
           State = STATE_NORMAL;
        }
     }
     else if( State == STATE_QUOTE3 )
     {
        if( **sSource == ']' )
        {
           State = STATE_NORMAL;

           /* Ron Pinkas added 2000-11-08 */
           **sSource = '\0';
           if( strchr( pString, '"' ) == NULL )
           {
              *pString = '"';
              **sSource = '"';
           }
           else if( strchr( pString, '\'' ) == NULL )
           {
              *pString = '\'';
              **sSource = '\'';
           }
           else
           {
              **sSource = ']';
           }
           /* END - Ron Pinkas added 2000-11-08 */
        }
     }
     /* Ron Pinkas added 2001-02-21 */
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'A' && toupper( (*sSource)[2] ) == 'N' && toupper( (*sSource)[3] ) == 'D' && (*sSource)[4] == '.' )
     {
        (*sSource) += 5;
        cLastChar = ' ';
        continue;
     }
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'N' && toupper( (*sSource)[2] ) == 'O' && toupper( (*sSource)[3] ) == 'T' && (*sSource)[4] == '.' )
     {
        (*sSource) += 5;
        cLastChar = ' ';
        continue;
     }
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'O' && toupper( (*sSource)[2] ) == 'R' && (*sSource)[3] == '.' )
     {
        (*sSource) += 4;
        cLastChar = ' ';
        continue;
     }
     /* End - Ron Pinkas added 2001-02-21 */
     /* Ron Pinkas added 2002-07-17 */
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'T' && (*sSource)[2] == '.' )
     {
        (*sSource) += 3;
        cLastChar = ' ';
        continue;
     }
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'F' && (*sSource)[2] == '.' )
     {
        (*sSource) += 3;
        cLastChar = ' ';
        continue;
     }
     /* End - Ron Pinkas added 2002-07-17 */
     /* Ron Pinkas added 2002-12-21 */
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'Y' && (*sSource)[2] == '.' )
     {
        (*sSource) += 3;
        cLastChar = ' ';
        continue;
     }
     else if( (*sSource)[0] == '.' && toupper( (*sSource)[1] ) == 'N' && (*sSource)[2] == '.' )
     {
        (*sSource) += 3;
        cLastChar = ' ';
        continue;
     }
     /* End - Ron Pinkas added 2002-07-17 */
     else if( **sSource == '\'' )
     {
        /* Ron Pinkas added 2000-11-08 */
        pString = *sSource;
        State = STATE_QUOTE1;
     }
     else if( **sSource == '\"' )
     {
        /* Ron Pinkas added 2000-11-08 */
        pString = *sSource;
        State = STATE_QUOTE2;
     }
     /* Ron Pinkas added 2000-11-08 */
     else if( **sSource == '[' )
     {
        if( s_bArray == FALSE && strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) )
        {
           /* Ron Pinkas added 2000-11-08 */
           pString = *sSource;
           State = STATE_QUOTE3;
        }
     }
     /* END - Ron Pinkas added 2000-11-08 */

     /* Ron Pinkas added 2000-11-08 */
     if( State == STATE_NORMAL && **sSource != ' ' && **sSource != '\t' )
     {
        cLastChar = **sSource;
     }
     /* END - Ron Pinkas added 2000-11-08 */

     (*sSource)++;
  }

  while( ISNAME( **sSource ) )
  {
     *sDest++ = *(*sSource)++;
     lenName++;
  }
  *sDest = '\0';

  if( lenName > 3 && lenName < 7 )
  {
     if( toupper( (sDest - lenName)[0] ) == 'R' && toupper( (sDest - lenName)[1] ) == 'E' &&
         toupper( (sDest - lenName)[2] ) == 'T' && toupper( (sDest - lenName)[3] ) == 'U'  )
     {
        if( (sDest - lenName)[4] == '\0' )
        {
           s_bArray = FALSE;
           goto Done;
        }
        else if( toupper( (sDest - lenName)[4] ) == 'R' )
        {
           if( (sDest - lenName)[5] == '\0' )
           {
              s_bArray = FALSE;
              goto Done;
           }
           else if( toupper( (sDest - lenName)[5] ) == 'N' )
           {
              s_bArray = FALSE;
              goto Done;
           }
        }
     }
  }

  /* Ron Pinkas added 2000-11-08 - Prepare for next run. */
  pTmp = *sSource;
  while( *pTmp && ( *pTmp == ' ' || *pTmp == '\t' ) )
  {
     pTmp++;
  }

  s_bArray = ( *pTmp == '[' );
  /* END - Ron Pinkas added 2000-11-08 */

  #if 0
     printf( "Len: %i NextName: >%s<\n", lenName, sDest - lenName );
     printf( "Rest: >%s<\n", *sSource );
  #endif

 Done:

  return lenName;
}

static int NextStopper( char ** sSource, char * sDest )
{
  int iLen = 0;

  HB_TRACE_STEALTH(HB_TR_DEBUG, ("NextStopper(%p, %s)", sSource, sDest));

  #if 0
     printf( "In: >%s<\n", *sSource );
  #endif

  while( ISNAME( (*sSource)[ iLen ] ) )
  {
     sDest[ iLen ] = (*sSource)[ iLen ];
     iLen++;
  }
  sDest[ iLen ] = '\0';

  #if 0
     printf( "Len: %i NextName: >%s<\n", iLen, sDest );
     printf( "Rest: >%s<\n", (*sSource) + iLen );
  #endif

  return iLen;
}

static int NextParm( char ** sSource, char * sDest )
{
  int lenName = 0, State = STATE_NORMAL, StBr = 0;
  char cLastChar = '\0';

  HB_TRACE(HB_TR_DEBUG, ("NextParm(%p, %s)", sSource, sDest));

  HB_SKIPTABSPACES( (*sSource) );

  while( **sSource != '\0' )
  {
     if( State == STATE_QUOTE1 )
     {
        if( **sSource == '\'' )
        {
           State = STATE_NORMAL;
        }
     }
     else if( State == STATE_QUOTE2 )
     {
        if( **sSource == '\"' )
        {
           State = STATE_NORMAL;
        }
     }
     else if( State == STATE_QUOTE3 )
     {
        if( **sSource == ']' )
        {
           State = STATE_NORMAL;
        }
     }
     else if( **sSource == '\'' )
     {
        State = STATE_QUOTE1;
     }
     else if( **sSource == '\"' )
     {
        State = STATE_QUOTE2;
     }
     else if( **sSource == '[' && strchr( ")]}.\"'", cLastChar ) == NULL && ! ISNAME( cLastChar ) )
     {
        State = STATE_QUOTE3;
     }
     /* Ron Pinkas added 2000-11-26 */
     else if( **sSource == '[' )
     {
        StBr++;
     }
     else if( **sSource == ']' )
     {
        StBr--;
     }
     /* END - Ron Pinkas added 2000-11-26 */
     else if( **sSource == '{' )
     {
        StBr++;
     }
     else if( **sSource == '}' )
     {
        StBr--;
     }
     else if( **sSource == '(' )
     {
        StBr++;
     }
     else if( **sSource == ')' || **sSource == ',' )
     {
        if( StBr == 0 )
        {
           break;
        }

        if( **sSource == ')' )
        {
           StBr--;
        }
     }

     if( sDest != NULL )
     {
        *sDest++ = **sSource;
     }

     if( State == STATE_NORMAL && **sSource != ' ' && **sSource != '\t' )
     {
        cLastChar = **sSource;
     }

     (*sSource)++;
     lenName++;
  }

  if( sDest )
  {
     *sDest = '\0';
  }

  #if 0
     if( sDest )
     {
        printf( "NextParm: >%s<\n", sDest - lenName );
     }
     else
     {
        printf( "NextParm Len: %i\n", lenName );
     }
  #endif

  return lenName;
}

static BOOL IsIdentifier( char *szProspect )
{
   if( isalpha( (int) szProspect[0] ) || szProspect[0] == '_' )
   {
      int i = 1;

      while( ISNAME( szProspect[i] ) )
      {
        i++;
      }
      while( szProspect[i] == ' ' )
      {
        i++;
      }

      return ( szProspect[i] == '\0' ) ;
   }

   return FALSE;
}

static BOOL OpenInclude( char * szFileName, HB_PATHNAMES * pSearch, PHB_FNAME pMainFileName, BOOL bStandardOnly, char * szInclude )
{
  FILE * fptr;
  PHB_FNAME pFileName;
  PFILE pFile;

  HB_TRACE(HB_TR_DEBUG, ("OpenInclude('%s', %p, %p, %p, %i, '%s')", szFileName, pSearch, pMainFileName, bStandardOnly, szInclude));

  errno = 0;
  if( bStandardOnly )
  {
     fptr = 0;
     szInclude[ 0 ] = '\0';
  }
  else
  {
     pFileName = hb_fsFNameSplit( szFileName );

     if( ( pFileName->szPath == NULL || *(pFileName->szPath) == '\0' ) && pMainFileName )
        pFileName->szPath = pMainFileName->szPath;

     hb_fsFNameMerge( szInclude, pFileName );

     fptr = fopen( szInclude, "r" );
     hb_xfree( pFileName );
  }

  if( !fptr && pSearch && errno != EMFILE )
  {
      pFileName = hb_fsFNameSplit( szFileName );
      pFileName->szName = szFileName;
      pFileName->szExtension = NULL;
      while( pSearch && !fptr )
      {
          pFileName->szPath = pSearch->szPath;
          hb_fsFNameMerge( szInclude, pFileName );
          fptr = fopen( szInclude, "r" );
          pSearch = pSearch->pNext;
      }
      hb_xfree( pFileName );
  }

  if( fptr )
  {
     pFile = ( PFILE ) hb_xgrab( sizeof( _FILE ) );
     pFile->handle = fptr;
     pFile->pBuffer = hb_xgrab( HB_PP_BUFF_SIZE );
     pFile->iBuffer = pFile->lenBuffer = 10;
     pFile->szFileName = ( char * ) hb_xgrab( strlen( szFileName ) + 1 );
     hb_pp_strocpy( pFile->szFileName, szFileName );

     if( hb_comp_files.pLast )
        hb_comp_files.pLast->iLine = hb_comp_iLine;
     hb_comp_iLine = 1;

     pFile->iLine = 1;
     pFile->pPrev = hb_comp_files.pLast;
     hb_comp_files.pLast = pFile;
     hb_comp_files.iFiles++;
     return TRUE;
  }

  return FALSE;
}


void CloseInclude( void )
{
   PFILE pFile;

   /* we close the currently include file and continue */
   fclose( hb_comp_files.pLast->handle );
   hb_xfree( hb_comp_files.pLast->pBuffer );
   hb_xfree( hb_comp_files.pLast->szFileName );
   pFile = ( PFILE ) ( ( PFILE ) hb_comp_files.pLast )->pPrev;
   hb_xfree( hb_comp_files.pLast );
   hb_comp_files.pLast = pFile;
   if( hb_comp_files.pLast )
      hb_comp_iLine = hb_comp_files.pLast->iLine;
   hb_comp_files.iFiles--;
}

int hb_pp_NextToken( char** pLine )
{
   char *sLine, *pTmp;
   char s2[3];
   size_t Counter, nLen, iPad = 0;

   sLine = *pLine;
   nLen = strlen( sLine );

   //printf( "\nProcessing: >%s<\n", sLine );

   // *** To be removed after final testing !!!
   while( sLine[0] == ' ' )
   {
      sLine++; nLen--; iPad++;
   }

   s_sToken[0] = '\0';
   s2[2]      = '\0';

   if( nLen >= 2 )
   {
      s2[0] = sLine[0];
      s2[1] = sLine[1];

      if( strstr( "++\\--\\->\\:=\\==\\!=\\<>\\>=\\<=\\+=\\-=\\*=\\^=\\**\\/=\\%=", (char*) s2 ) )
      {
         s_sToken[0] = s2[0];
         s_sToken[1] = s2[1];
         s_sToken[2] = '\0';

         goto Done;
      }
      else if( s2[0] == '[' && s2[1] == '[' )
      {
         pTmp = strstr( sLine + 2, "]]" );
         if( pTmp == NULL )
         {
            s_sToken[0] = '['; // Clipper does NOT consider '[[' a single token
            s_sToken[1] = '\0';
         }
         else
         {
            strncpy( (char *) s_sToken, sLine, ( pTmp - sLine ) + 2 );
            s_sToken[( pTmp - sLine ) + 2] = '\0';
         }

         goto Done;
      }
   }

   if( isalpha( sLine[0] ) || sLine[0] == '_' )
   {
      s_sToken[0] = sLine[0];
      Counter = 1;

      // Why did I have the '\\' is NOT clear - document if and when reinstating!!!
      while( isalnum( sLine[Counter] ) || sLine[Counter] == '_'  ) //|| sLine[Counter] == '\\' )
      {
         s_sToken[Counter] = sLine[Counter];
         Counter++;
      }

      s_sToken[Counter] = '\0';
      goto Done;
   }
   else if( isdigit( sLine[0] ) )
   {
      s_sToken[0] = sLine[0];
      Counter = 1;
      while( isdigit( sLine[Counter] ) || sLine[Counter] == '\\' )
      {
         s_sToken[Counter] = sLine[Counter];
         Counter++;
      }

      // Consume the point (and subsequent digits) only if digits follow...
      if( sLine[Counter] == '.' && isdigit( sLine[Counter + 1] ) )
      {
         s_sToken[Counter] = '.';
         Counter++;
         s_sToken[Counter] = sLine[Counter];
         Counter++;
         while( isdigit( sLine[Counter] ) || sLine[Counter] == '\\' )
         {
            s_sToken[Counter] = sLine[Counter];
            Counter++;
         }
      }

      // Either way we are done.
      s_sToken[Counter] = '\0';
      goto Done;
   }
   else if( sLine[0] == '.' && isdigit( sLine[1] ) )
   {
      s_sToken[0] = '.';
      s_sToken[1] = sLine[1];
      Counter = 2;
      while( isdigit( sLine[Counter] ) )
      {
         s_sToken[Counter] = sLine[Counter];
         Counter++;
      }

      s_sToken[Counter] = '\0';
      goto Done;
   }
   else if( sLine[0] == '.' )
   {
      if( nLen >= 5 && sLine[4] == '.' )
      {
         if( toupper( sLine[1] ) == 'A' && toupper( sLine[2] ) == 'N' && toupper( sLine[3] ) == 'D' )
         {
            s_sToken[0] = '.';
            s_sToken[1] = 'A';
            s_sToken[2] = 'N';
            s_sToken[3] = 'D';
            s_sToken[4] = '.';
            s_sToken[5] = '\0';

            goto Done;
         }
         else if( toupper( sLine[1] ) == 'N' && toupper( sLine[2] ) == 'O' && toupper( sLine[3] ) == 'T' )
         {
            s_sToken[0] = '!';
            s_sToken[1] = '\0';

            /* Skip the unaccounted letters ( .NOT. <-> ! ) */
            sLine += 4;

            goto Done;
         }
      }

      if( nLen >= 4 && sLine[3] == '.' && toupper( sLine[1] ) == 'O' && toupper( sLine[2] ) == 'R' )
      {
         s_sToken[0] = '.';
         s_sToken[1] = 'O';
         s_sToken[2] = 'R';
         s_sToken[3] = '.';
         s_sToken[4] = '\0';

         goto Done;
      }

      if( nLen >= 3 && sLine[2] == '.' )
      {
         if( toupper( sLine[1] ) == 'T' )
         {
            s_sToken[0] = '.';
            s_sToken[1] = 'T';
            s_sToken[2] = '.';
            s_sToken[3] = '\0';

            goto Done;
         }
         else if( toupper( sLine[1] ) == 'F' )
         {
            s_sToken[0] = '.';
            s_sToken[1] = 'F';
            s_sToken[2] = '.';
            s_sToken[3] = '\0';

            goto Done;
         }
      }

      s_sToken[0] = '.';
      s_sToken[1] = '\0';

      goto Done;
   }
   else if( sLine[0] == '"' )
   {
      pTmp = strchr( sLine + 1, '"' );
      if( pTmp == NULL )
      {
         s_sToken[0] = '"';
         s_sToken[1] = '\0';
      }
      else
      {
         strncpy( (char *) s_sToken, sLine, ( pTmp - sLine ) + 1 );
         s_sToken[( pTmp - sLine ) + 1] = '\0';
      }

      goto Done;
   }
   else if( sLine[0] == '\'' )
   {
      pTmp = strchr( sLine + 1, '\'' );
      if( pTmp == NULL )
      {
         s_sToken[0] = '\'';
         s_sToken[1] = '\0';
      }
      else
      {
         strncpy( (char *) s_sToken, sLine, ( pTmp - sLine ) + 1 );
         s_sToken[( pTmp - sLine ) + 1] = '\0';

         if( strchr( s_sToken, '"' ) == NULL )
         {
            s_sToken[0] = '"';
            s_sToken[( pTmp - sLine )] = '"';
         }
      }

      goto Done;
   }
   else if( sLine[0] == '[' )
   {
      if( s_bArray )
      {
         s_sToken[0] = '[';
         s_sToken[1] = '\0';
      }
      else
      {
         pTmp = strchr( sLine + 1, ']' );
         if( pTmp == NULL )
         {
            s_sToken[0] = '[';
            s_sToken[1] = '\0';
         }
         else
         {
            strncpy( (char *) s_sToken, sLine, ( pTmp - sLine ) + 1 );
            s_sToken[( pTmp - sLine ) + 1] = '\0';

            if( strchr( (char *) s_sToken, '"' ) == NULL )
            {
               s_sToken[0] = '"';
               s_sToken[( pTmp - sLine )] = '"';
            }
            else if( strchr( (char *) s_sToken, '\'' ) == NULL )
            {
               s_sToken[0] = '\'';
               s_sToken[( pTmp - sLine )] = '\'';
            }
         }
      }

      goto Done;
   }
   else if( sLine[0] == '\\' )
   {
      s_sToken[0] = '\\';
      s_sToken[1] = sLine[1];
      s_sToken[2] = '\0';

      goto Done;
   }
   else if ( strchr( "+-*/:=^!&()[]{}@,|<>#%?$~", sLine[0] ) )
   {
      s_sToken[0] = sLine[0];
      s_sToken[1] = '\0';

      goto Done;
   }
   else
   {
      // Todo Generic Error.
      //printf( "\nUnexpected case: %s\n", sLine );
      //getchar();
      s_sToken[0] = sLine[0];
      s_sToken[1] = '\0';
   }

 Done:

   sLine += ( nLen = strlen( (char *) s_sToken ) );

   if( s_sToken[0] == '.' && nLen > 1 && s_sToken[nLen - 1] == '.' )
   {
      s_bArray = FALSE;
   }
   else
   {
      s_bArray = ( isalnum( s_sToken[0] ) || strchr( "])}._", s_sToken[0] ) );
   }

   while( sLine[0] == ' ' || sLine[0] == '\t' )
   {
      sLine++;
      nLen++;
   }

   *pLine = (char *) sLine;

   //printf( "Token: >%s< Line: >%s<\n", s_sToken, *pLine );

   return nLen + iPad;
}
