/*
 * $Id: hbset.h,v 1.39 2007/09/22 06:39:49 andijahja Exp $
 */

/*
 * Harbour Project source code:
 * Header file for the Set API
 *
 * Copyright 1999 David G. Holm <dholm@jsd-llc.com>
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

#ifndef HB_SET_H_
#define HB_SET_H_

#include "hbapi.h"
#include "hbapigt.h"
#include "hbapifs.h"

HB_EXTERN_BEGIN

typedef enum
{
   HB_SET_INVALID_      = 0,

   HB_SET_EXACT         = 1,
   HB_SET_FIXED         = 2,
   HB_SET_DECIMALS      = 3,
   HB_SET_DATEFORMAT    = 4,
   HB_SET_EPOCH         = 5,
   HB_SET_PATH          = 6,
   HB_SET_DEFAULT       = 7,

   HB_SET_EXCLUSIVE     = 8,
   HB_SET_SOFTSEEK      = 9,
   HB_SET_UNIQUE        = 10,
   HB_SET_DELETED       = 11,

   HB_SET_CANCEL        = 12,
   HB_SET_DEBUG         = 13,
   HB_SET_TYPEAHEAD     = 14,

   HB_SET_COLOR         = 15,
   HB_SET_CURSOR        = 16,
   HB_SET_CONSOLE       = 17,
   HB_SET_ALTERNATE     = 18,
   HB_SET_ALTFILE       = 19,
   HB_SET_DEVICE        = 20,
   HB_SET_EXTRA         = 21,
   HB_SET_EXTRAFILE     = 22,
   HB_SET_PRINTER       = 23,
   HB_SET_PRINTFILE     = 24,
   HB_SET_MARGIN        = 25,

   HB_SET_BELL          = 26,
   HB_SET_CONFIRM       = 27,
   HB_SET_ESCAPE        = 28,
   HB_SET_INSERT        = 29,
   HB_SET_EXIT          = 30,
   HB_SET_INTENSITY     = 31,
   HB_SET_SCOREBOARD    = 32,
   HB_SET_DELIMITERS    = 33,
   HB_SET_DELIMCHARS    = 34,

   HB_SET_WRAP          = 35,
   HB_SET_MESSAGE       = 36,
   HB_SET_MCENTER       = 37,
   HB_SET_SCROLLBREAK   = 38,

   HB_SET_EVENTMASK     = 39,

   HB_SET_VIDEOMODE     = 40,

   HB_SET_MBLOCKSIZE    = 41,
   HB_SET_MFILEEXT      = 42,

   HB_SET_STRICTREAD    = 43,
   HB_SET_OPTIMIZE      = 44,
   HB_SET_AUTOPEN       = 45,
   HB_SET_AUTORDER      = 46,
   HB_SET_AUTOSHARE     = 47,

   /* Harbour SET extensions start at 100 */
   HB_SET_LANGUAGE      = 100,
   HB_SET_IDLEREPEAT    = 101,
   HB_SET_TRACE           = 102,
   HB_SET_TRACEFILE       = 103,
   HB_SET_TRACESTACK      = 104,
   HB_SET_FILECASE        = 105,
   HB_SET_DIRCASE         = 106,
   HB_SET_DIRSEPARATOR    = 107,
   HB_SET_ERRORLOOP       = 108,
   HB_SET_OUTPUTSAFETY    = 109,
   HB_SET_DBFLOCKSCHEME   = 110,
   HB_SET_BACKGROUNDTASKS = 111,
   HB_SET_TRIMFILENAME    = 112,
   HB_SET_GTMODE          = 113,
   HB_SET_BACKGROUNDTICK  = 114,
   HB_SET_PRINTERJOB      = 115,
   HB_SET_HARDCOMMIT      = 116,
   HB_SET_FORCEOPT        = 117,
   HB_SET_EOL             = 118,
   HB_SET_ERRORLOG        = 119,
   HB_SET_TIMEFORMAT      = 120

} HB_set_enum;

typedef struct
{
   /* Lower case members are indirectly related to a SET */
   FHANDLE hb_set_althan;
   BOOL    hb_set_century;
   FHANDLE hb_set_extrahan;
   FHANDLE hb_set_printhan;

   /* Upper case members are directly related to a SET */
   BOOL    HB_SET_ALTERNATE;
   char *  HB_SET_ALTFILE;
   BOOL    HB_SET_AUTOPEN;
   int     HB_SET_AUTORDER;
   int     HB_SET_AUTOSHARE;
   BOOL    HB_SET_BELL;
   BOOL    HB_SET_CANCEL;
   char    HB_SET_COLOR[ CLR_STRLEN ];
   BOOL    HB_SET_CONFIRM;
   BOOL    HB_SET_CONSOLE;
   char *  HB_SET_DATEFORMAT;
   BOOL    HB_SET_DEBUG;
   int     HB_SET_DECIMALS;
   char *  HB_SET_DEFAULT;
   BOOL    HB_SET_DELETED;
   char *  HB_SET_DELIMCHARS;
   BOOL    HB_SET_DELIMITERS;
   char *  HB_SET_DEVICE;
   BOOL    HB_SET_EOF;
   int     HB_SET_EPOCH;
   BOOL    HB_SET_ESCAPE;
   HB_inkey_enum  HB_SET_EVENTMASK;
   BOOL    HB_SET_EXACT;
   BOOL    HB_SET_EXCLUSIVE;
   BOOL    HB_SET_EXIT;
   BOOL    HB_SET_EXTRA;
   char *  HB_SET_EXTRAFILE;
   BOOL    HB_SET_FIXED;
   BOOL    HB_SET_IDLEREPEAT;
   BOOL    HB_SET_INSERT;
   BOOL    HB_SET_INTENSITY;
   char *  HB_SET_PATH;
   int     HB_SET_MARGIN;
   int     HB_SET_MBLOCKSIZE;
   BOOL    HB_SET_MCENTER;
   int     HB_SET_MESSAGE;
   char *  HB_SET_MFILEEXT;
   BOOL    HB_SET_OPTIMIZE;
   BOOL    HB_SET_PRINTER;
   char *  HB_SET_PRINTFILE;
   BOOL    HB_SET_SCOREBOARD;
   BOOL    HB_SET_SCROLLBREAK;
   BOOL    HB_SET_SOFTSEEK;
   BOOL    HB_SET_STRICTREAD;
   int     HB_SET_TYPEAHEAD;
   BOOL    HB_SET_UNIQUE;
   int     HB_SET_FILECASE;
   int     HB_SET_DIRCASE;
   char    HB_SET_DIRSEPARATOR;
   int     HB_SET_VIDEOMODE;
   BOOL    HB_SET_WRAP;

   int     HB_SET_DBFLOCKSCHEME;

   BOOL    HB_SET_TRACE;
   char    HB_SET_TRACEFILE[_POSIX_PATH_MAX];
   char    HB_SET_TRACESTACK;

   int     HB_SET_ERRORLOOP;
   BOOL    HB_SET_OUTPUTSAFETY;
   BOOL    HB_SET_BACKGROUNDTASKS;
   BOOL    HB_SET_TRIMFILENAME ;

   BOOL    hb_set_winprinter;
   FHANDLE hb_set_winhan;
   char *  hb_set_printerjob;
   int     HB_SET_GTMODE;
   int     HB_SET_BACKGROUNDTICK;
   BOOL    HB_SET_HARDCOMMIT;
   BOOL    HB_SET_FORCEOPT;
   PHB_ITEM HB_SET_EOL;
   BOOL    HB_SET_APPENDERROR;
   char    HB_SET_ERRORLOG[_POSIX_PATH_MAX];
   char *  HB_SET_TIMEFORMAT;

} HB_SET_STRUCT;

#define HB_SET_CASE_MIXED  0
#define HB_SET_CASE_LOWER  1
#define HB_SET_CASE_UPPER  2

#define HB_SET_TRACESTACK_NONE    0
#define HB_SET_TRACESTACK_CURRENT 1
#define HB_SET_TRACESTACK_ALL     2

// extern HB_EXPORT HB_SET_STRUCT hb_set;
extern HB_SET_STRUCT hb_set;
extern HB_SET_STRUCT *hb_set_ptr;

HB_EXPORT HB_SET_STRUCT *hb_GetSetStructPtr( void );
extern void hb_setInitialize( void );
extern void hb_setRelease( void );
extern HB_EXPORT HB_PATHNAMES * hb_setGetFirstSetPath( void );

typedef enum
{
   HB_SET_LISTENER_BEFORE,
   HB_SET_LISTENER_AFTER
} HB_set_listener_enum;
typedef void HB_SET_LISTENER_CALLBACK( HB_set_enum, HB_set_listener_enum );

extern HB_EXPORT int hb_setListenerAdd( HB_SET_LISTENER_CALLBACK * );
extern HB_EXPORT void hb_setListenerNotify( HB_set_enum, HB_set_listener_enum );
extern HB_EXPORT int hb_setListenerRemove( int );

extern HB_EXPORT FHANDLE hb_setAltHan( void );
extern HB_EXPORT BOOL    hb_setCentury( void );
extern HB_EXPORT FHANDLE hb_setExtraHan( void );
extern HB_EXPORT FHANDLE hb_setPrintHan( void );
extern HB_EXPORT BOOL    hb_setAlternate( void );
extern HB_EXPORT char *  hb_setAltFile( void );
extern HB_EXPORT BOOL    hb_setAutOpen( void );
extern HB_EXPORT int     hb_setAutOrder( void );
extern HB_EXPORT int     hb_setAutoShare( void );
extern HB_EXPORT BOOL    hb_setBell( void );
extern HB_EXPORT BOOL    hb_setCancel( void );
extern HB_EXPORT char *  hb_setColor( void );
extern HB_EXPORT BOOL    hb_setConfirm( void );
extern HB_EXPORT BOOL    hb_setConsole( void );
extern HB_EXPORT char *  hb_setDateFormat( void );
extern HB_EXPORT BOOL    hb_setDebug( void );
extern HB_EXPORT int     hb_setDecimals( void );
extern HB_EXPORT char *  hb_setDefault( void );
extern HB_EXPORT BOOL    hb_setDeleted( void );
extern HB_EXPORT char *  hb_setDelimChars( void );
extern HB_EXPORT BOOL    hb_setDelimiters( void );
extern HB_EXPORT char *  hb_setDevice( void );
extern HB_EXPORT BOOL    hb_setEOF( void );
extern HB_EXPORT int     hb_setEpoch( void );
extern HB_EXPORT BOOL    hb_setEscape( void );
extern HB_EXPORT HB_inkey_enum  hb_setEventMask( void );
extern HB_EXPORT BOOL    hb_setExact( void );
extern HB_EXPORT BOOL    hb_setExclusive( void );
extern HB_EXPORT BOOL    hb_setExit( void );
extern HB_EXPORT BOOL    hb_setExtra( void );
extern HB_EXPORT char *  hb_setExtraFile( void );
extern HB_EXPORT BOOL    hb_setFixed( void );
extern HB_EXPORT BOOL    hb_setIdleRepeat( void );
extern HB_EXPORT BOOL    hb_setInsert( void );
extern HB_EXPORT BOOL    hb_setIntensity( void );
extern HB_EXPORT char *  hb_setPath( void );
extern HB_EXPORT int     hb_setMargin( void );
extern HB_EXPORT int     hb_setMBlockSize( void );
extern HB_EXPORT BOOL    hb_setMCenter( void );
extern HB_EXPORT int     hb_setMessage( void );
extern HB_EXPORT char *  hb_setMFileExt( void );
extern HB_EXPORT BOOL    hb_setOptimize( void );
extern HB_EXPORT BOOL    hb_setPrinter( void );
extern HB_EXPORT char *  hb_setPrintFile( void );
extern HB_EXPORT BOOL    hb_setScoreBoard( void );
extern HB_EXPORT BOOL    hb_setScrollBreak( void );
extern HB_EXPORT BOOL    hb_setSoftSeek( void );
extern HB_EXPORT BOOL    hb_setStrictRead( void );
extern HB_EXPORT int     hb_setTypeAhead( void );
extern HB_EXPORT BOOL    hb_setUnique( void );
extern HB_EXPORT int     hb_setFileCase( void );
extern HB_EXPORT int     hb_setDirCase( void );
extern HB_EXPORT char    hb_setDirSeparator( void );
extern HB_EXPORT int     hb_setVideoMode( void );
extern HB_EXPORT BOOL    hb_setWrap( void );
extern HB_EXPORT int     hb_setDBFLockScheme( void );
extern HB_EXPORT BOOL    hb_setTrace( void );
extern HB_EXPORT char *  hb_setTraceFile( void );
extern HB_EXPORT char    hb_setTraceStack( void );
extern HB_EXPORT int     hb_setErrorLoop( void );
extern HB_EXPORT BOOL    hb_setOutputSafety( void );
extern HB_EXPORT BOOL    hb_setBackgroundTasks( void );
extern HB_EXPORT BOOL    hb_setTrimFileName( void );
extern HB_EXPORT BOOL    hb_setWinPrinter( void );
extern HB_EXPORT FHANDLE hb_setWinHan( void );
extern HB_EXPORT char *  hb_setPrinterJob( void );
extern HB_EXPORT int     hb_setGTMode( void );
extern HB_EXPORT int     hb_setBackGroundTick( void );
extern HB_EXPORT BOOL    hb_setHardCommit( void );
extern HB_EXPORT BOOL    hb_setForceOpt( void );
extern HB_EXPORT PHB_ITEM hb_setEOL( void );
extern HB_EXPORT BOOL    hb_setAppendError( void );
extern HB_EXPORT char *  hb_setErrorLog( void );
extern HB_EXPORT char *  hb_setTimeFormat( void );

#ifndef HB_SET_STACK
   #define HB_SET_STACK (*hb_GetSetStructPtr())
#endif

HB_EXTERN_END

#endif /* HB_SET_H_ */
