/*
 * $Id: fm.c,v 1.33 2003/05/25 17:03:19 jonnymind Exp $
 */

/*
 * Harbour Project source code:
 * The Fixed Memory API
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

/*
 * The following parts are Copyright of the individual authors.
 * www - http://www.harbour-project.org
 *
 * Copyright 1999 David G. Holm <dholm@jsd-llc.com>
 *    hb_xmemcpy()
 *    hb_xmemset()
 *
 * Copyright 1999-2001 Viktor Szakats <viktor.szakats@syenar.hu>
 *    hb_xquery()
 *    MEMORY()
 *
 * See doc/license.txt for licensing terms.
 *
 */

#define HB_OS_WIN_32_USED
#define HB_THREAD_OPTIMIZE_STACK

/* NOTE: For OS/2. Must be ahead of any and all #include statements */
#define INCL_BASE
#define INCL_DOSMISC
#define INCL_DOSERRORS
#define INCL_DOSPROCESS

#ifndef __MPW__
   #ifdef HB_OS_DARWIN
      #include <stdlib.h>     /* There is no malloc.h in Darwin */
   #else
      #include <malloc.h>
   #endif
#endif

#include "hbapi.h"
#include "hbstack.h"
#include "hbapierr.h"
#include "hbmemory.ch"

#if defined(HB_FM_STATISTICS) && !defined(HB_TR_LEVEL)
   #define HB_TR_LEVEL HB_TR_ERROR
#endif

#ifdef HB_FM_STATISTICS

#define HB_MEMINFO_SIGNATURE 0x19730403

typedef struct _HB_MEMINFO
{
   ULONG  ulSignature;
   ULONG  ulSize;
   USHORT uiProcLine;
   char   szProcName[ HB_SYMBOL_NAME_LEN + 1 ];
   struct _HB_MEMINFO * pPrevBlock;
   struct _HB_MEMINFO * pNextBlock;
} HB_MEMINFO, * PHB_MEMINFO;

static LONG s_lMemoryBlocks = 0;      /* memory blocks used */
static LONG s_lMemoryMaxBlocks = 0;   /* maximum number of used memory blocks */
static LONG s_lMemoryMaxConsumed = 0; /* memory size consumed */
static LONG s_lMemoryConsumed = 0;    /* memory max size consumed */
static LONG s_lAllocations = 0;
static LONG s_lReAllocations = 0;
static LONG s_lFreed = 0;

static PHB_MEMINFO s_pFirstBlock = NULL;
static PHB_MEMINFO s_pLastBlock = NULL;

#endif

/* allocates fixed memory, do *not* exits on failure */
void HB_EXPORT * hb_xalloc( ULONG ulSize )
{
   void * pMem;
#ifdef HB_FM_STATISTICS
    HB_THREAD_STUB
#endif

   /* NOTE: we cannot use here HB_TRACE because it will overwrite the
    * function name/line number of code which called hb_xalloc/hb_xgrab
    */
   HB_TRACE_STEALTH(HB_TR_INFO, ("hb_xalloc(%lu)", ulSize));

   if( ulSize == 0 )
   {
      hb_errInternal( HB_EI_XGRABNULLSIZE, NULL, NULL, NULL );
   }

#ifdef HB_FM_STATISTICS

   HB_CRITICAL_LOCK( hb_allocMutex );
   pMem = malloc( ulSize + sizeof( HB_MEMINFO ) + sizeof( ULONG ) );

   if( ! pMem )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      return NULL;
   }

   s_lAllocations++;

   if( ! s_pFirstBlock )
   {
      ( ( PHB_MEMINFO ) pMem )->pPrevBlock = NULL;
      s_pFirstBlock = ( PHB_MEMINFO ) pMem;
   }
   else
   {
      ( ( PHB_MEMINFO ) pMem )->pPrevBlock = s_pLastBlock;
      s_pLastBlock->pNextBlock = ( PHB_MEMINFO ) pMem;
   }

   s_pLastBlock = ( PHB_MEMINFO ) pMem;

   ( ( PHB_MEMINFO ) pMem )->pNextBlock = NULL;
   ( ( PHB_MEMINFO ) pMem )->ulSignature = HB_MEMINFO_SIGNATURE;
   ( ( PHB_MEMINFO ) pMem )->ulSize = ulSize;  /* size of the memory block */

   {
      ULONG *pSig = (ULONG *)( ( ( unsigned char * ) pMem ) + ulSize + sizeof(HB_MEMINFO) );
      *pSig = HB_MEMINFO_SIGNATURE;
   }

   if( hb_tr_level() >= HB_TR_DEBUG )
   {
      /* NOTE: PRG line number/procname is not very useful during hunting
      * for memory leaks - this is why we are using the previously stored
      * function/line info - this is a location of code that called
      * hb_xalloc/hb_xgrab
      */
      /* C line number */
      ( ( PHB_MEMINFO ) pMem )->uiProcLine = hb_tr_line_;
      strcpy( ( ( PHB_MEMINFO ) pMem )->szProcName, hb_tr_file_ );
   }
   else
   {

      if( HB_VM_STACK.pItems && ( HB_VM_STACK.pBase != HB_VM_STACK.pItems ) )
      {
          /* PRG line number */
         ( ( PHB_MEMINFO ) pMem )->uiProcLine = (*(HB_VM_STACK.pBase))->item.asSymbol.lineno;
          /* PRG ProcName */
         strcpy( ( ( PHB_MEMINFO ) pMem )->szProcName, (*(HB_VM_STACK.pBase))->item.asSymbol.value->szName );
      }
      else
      {
         /* PRG line number */
         ( ( PHB_MEMINFO ) pMem )->uiProcLine = 0;
         /* PRG ProcName */
         ( ( PHB_MEMINFO ) pMem )->szProcName[ 0 ] = '\0';
      }
   }

   s_lMemoryConsumed += ulSize;

   if( s_lMemoryMaxConsumed < s_lMemoryConsumed )
   {
      s_lMemoryMaxConsumed = s_lMemoryConsumed;
   }

   s_lMemoryBlocks++;

   if( s_lMemoryMaxBlocks < s_lMemoryBlocks )
   {
      s_lMemoryMaxBlocks = s_lMemoryBlocks;
   }

   HB_TRACE_STEALTH( HB_TR_INFO, ( "hb_xalloc(%lu) returning: %p", ulSize, (char *) pMem + sizeof( HB_MEMINFO ) ) );

   HB_CRITICAL_UNLOCK( hb_allocMutex );

   return ( char * ) pMem + sizeof( HB_MEMINFO );

#else

#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_LOCK( hb_allocMutex );
#endif

   pMem = malloc( ulSize );

#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_UNLOCK( hb_allocMutex );
#endif
   return pMem;
 #endif
}

/* allocates fixed memory, exits on failure */
void HB_EXPORT * hb_xgrab( ULONG ulSize )
{
   void * pMem;

   /* NOTE: we cannot use here HB_TRACE because it will overwrite the
    * function name/line number of code which called hb_xalloc/hb_xgrab
    */
   HB_TRACE_STEALTH(HB_TR_INFO, ("hb_xgrab(%lu)", ulSize));

   if( ulSize == 0 )
   {
      hb_errInternal( HB_EI_XGRABNULLSIZE, NULL, NULL, NULL );
   }

#ifdef HB_FM_STATISTICS

   HB_CRITICAL_LOCK( hb_allocMutex );
   pMem = malloc( ulSize + sizeof( HB_MEMINFO ) + sizeof( ULONG ) );

   if( ! pMem )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );

      hb_errInternal( HB_EI_XGRABALLOC, NULL, NULL, NULL );
   }
   /* allocation should be counted AFTER we know that malloc has suceed */
   s_lAllocations++;

   if( ! s_pFirstBlock )
   {
      ( ( PHB_MEMINFO ) pMem )->pPrevBlock = NULL;
      s_pFirstBlock = ( PHB_MEMINFO ) pMem;
   }
   else
   {
      ( ( PHB_MEMINFO ) pMem )->pPrevBlock = s_pLastBlock;
      s_pLastBlock->pNextBlock = ( PHB_MEMINFO ) pMem;
   }

   s_pLastBlock = ( PHB_MEMINFO ) pMem;

   ( ( PHB_MEMINFO ) pMem )->pNextBlock = NULL;
   ( ( PHB_MEMINFO ) pMem )->ulSignature = HB_MEMINFO_SIGNATURE;
   ( ( PHB_MEMINFO ) pMem )->ulSize = ulSize;  /* size of the memory block */

   {
      ULONG *pSig = (ULONG *)( ( ( unsigned char * ) pMem ) + ulSize + sizeof(HB_MEMINFO) );
      *pSig = HB_MEMINFO_SIGNATURE;
   }

   if( hb_tr_level() >= HB_TR_DEBUG )
   {
      /* NOTE: PRG line number/procname is not very useful during hunting
      * for memory leaks - this is why we are using the previously stored
      * function/line info - this is a location of code that called
      * hb_xalloc/hb_xgrab
      */
      /* C line number */
      ( ( PHB_MEMINFO ) pMem )->uiProcLine = hb_tr_line_;
      strcpy( ( ( PHB_MEMINFO ) pMem )->szProcName, hb_tr_file_ );
   }
   else
   {
      HB_THREAD_STUB
      if( HB_VM_STACK.pItems && ( HB_VM_STACK.pBase != HB_VM_STACK.pItems ) )
      {
         /* PRG line number */
         ( ( PHB_MEMINFO ) pMem )->uiProcLine = (*(HB_VM_STACK.pBase))->item.asSymbol.lineno;
         /* PRG ProcName */
         strcpy( ( ( PHB_MEMINFO ) pMem )->szProcName, (*(HB_VM_STACK.pBase))->item.asSymbol.value->szName );
      }
      else
      {
         /* PRG line number */
         ( ( PHB_MEMINFO ) pMem )->uiProcLine = 0;
         /* PRG ProcName */
         ( ( PHB_MEMINFO ) pMem )->szProcName[ 0 ] = '\0';
      }
   }

   s_lMemoryConsumed += ulSize;

   if( s_lMemoryMaxConsumed < s_lMemoryConsumed )
   {
      s_lMemoryMaxConsumed = s_lMemoryConsumed;
   }

   s_lMemoryBlocks++;

   if( s_lMemoryMaxBlocks < s_lMemoryBlocks )
   {
      s_lMemoryMaxBlocks = s_lMemoryBlocks;
   }

   HB_TRACE_STEALTH( HB_TR_INFO, ( "hb_xgrab(%lu) returning: %p", ulSize, (char *) pMem + sizeof( HB_MEMINFO ) ) );

   HB_CRITICAL_UNLOCK( hb_allocMutex );

   return ( char * ) pMem + sizeof( HB_MEMINFO );

#else

#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_LOCK( hb_allocMutex );
#endif

   pMem = malloc( ulSize );

#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_UNLOCK( hb_allocMutex );
#endif

   if( ! pMem )
   {
      hb_errInternal( HB_EI_XGRABALLOC, NULL, NULL, NULL );
   }

   return pMem;

#endif
}

void HB_EXPORT * hb_xrealloc( void * pMem, ULONG ulSize )       /* reallocates memory */
{
#ifdef HB_FM_STATISTICS
   PHB_MEMINFO pMemBlock;
   ULONG ulMemSize;
   ULONG *pSig;

   HB_TRACE_STEALTH(HB_TR_INFO, ("hb_xrealloc(%p, %lu)", pMem, ulSize));

   HB_CRITICAL_LOCK( hb_allocMutex );
   s_lReAllocations++;

   if( ! pMem )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      hb_errInternal( HB_EI_XREALLOCNULL, NULL, NULL, NULL );
   }

   if( ulSize == 0 )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      hb_errInternal( HB_EI_XREALLOCNULLSIZE, NULL, NULL, NULL );
   }

   pMemBlock = ( PHB_MEMINFO ) ( ( char * ) pMem - sizeof( HB_MEMINFO ) );

   if( pMemBlock->ulSignature != HB_MEMINFO_SIGNATURE )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      hb_errInternal( HB_EI_XREALLOCINV, NULL, NULL, NULL );
   }

   ulMemSize = pMemBlock->ulSize;

   pSig = (ULONG *)( ( ( unsigned char * ) pMem ) + ulMemSize );

   if( *pSig != HB_MEMINFO_SIGNATURE )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      hb_errInternal( HB_EI_XMEMOVERFLOW, "hb_xrealloc()", NULL, NULL );
   }

   pMem = realloc( pMemBlock, ulSize + sizeof( HB_MEMINFO ) + sizeof( ULONG ) );

   s_lMemoryConsumed += ( ulSize - ulMemSize );

   if( s_lMemoryMaxConsumed < s_lMemoryConsumed )
   {
      s_lMemoryMaxConsumed = s_lMemoryConsumed;
   }

   if( ! pMem )
   {
      HB_CRITICAL_UNLOCK( hb_allocMutex );
      hb_errInternal( HB_EI_XREALLOC, NULL, NULL, NULL );
   }

   ( ( PHB_MEMINFO ) pMem )->ulSize = ulSize;  /* size of the memory block */
   {
      ULONG *pSig = (ULONG *)( ( ( unsigned char * ) pMem ) + ulSize + sizeof(HB_MEMINFO) );
      *pSig = HB_MEMINFO_SIGNATURE;
   }

   if( ( ( PHB_MEMINFO ) pMem )->pPrevBlock )
   {
      ( ( PHB_MEMINFO ) pMem )->pPrevBlock->pNextBlock = ( PHB_MEMINFO ) pMem;
   }

   if( ( ( PHB_MEMINFO ) pMem )->pNextBlock )
   {
      ( ( PHB_MEMINFO ) pMem )->pNextBlock->pPrevBlock = ( PHB_MEMINFO ) pMem;
   }

   if( s_pFirstBlock == pMemBlock )
   {
      s_pFirstBlock = ( PHB_MEMINFO ) pMem;
   }

   if( s_pLastBlock == pMemBlock )
   {
      s_pLastBlock = ( PHB_MEMINFO ) pMem;
   }

   HB_CRITICAL_UNLOCK( hb_allocMutex );

   return ( char * ) pMem + sizeof( HB_MEMINFO );

#else

   HB_TRACE(HB_TR_DEBUG, ("hb_xrealloc(%p, %lu)", pMem, ulSize));

   if( ! pMem )
   {
      hb_errInternal( HB_EI_XREALLOCNULL, NULL, NULL, NULL );
   }

   if( ulSize == 0 )
   {
      hb_errInternal( HB_EI_XREALLOCNULLSIZE, NULL, NULL, NULL );
   }


#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_LOCK( hb_allocMutex );
#endif

   pMem = realloc( pMem, ulSize );

#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_UNLOCK( hb_allocMutex );
#endif

   if( ! pMem )
   {
      hb_errInternal( HB_EI_XREALLOC, NULL, NULL, NULL );
   }

   return pMem;

#endif
}

void hb_xfree( void * pMem )            /* frees fixed memory */
{

#ifdef HB_FM_STATISTICS

   HB_TRACE_STEALTH( HB_TR_INFO, ( "hb_xfree(%p)", pMem ) );

   HB_CRITICAL_LOCK( hb_allocMutex );
   s_lFreed++;

   if( pMem )
   {
      PHB_MEMINFO pMemBlock = ( PHB_MEMINFO ) ( ( char * ) pMem - sizeof( HB_MEMINFO ) );
      ULONG *pSig;

      if( pMemBlock->ulSignature != HB_MEMINFO_SIGNATURE )
      {
         //printf( "hb_xfree() Invalid Pointer %p %s", (char *) pMem, (char *) pMem );

         HB_CRITICAL_UNLOCK( hb_allocMutex );
         hb_errInternal( HB_EI_XFREEINV, "hb_xfree() Invalid Pointer %p %s", (char *) pMem, (char *) pMem );
      }

      pSig  = (ULONG *)( ( ( unsigned char * ) pMem ) + pMemBlock->ulSize );

      if( *pSig != HB_MEMINFO_SIGNATURE )
      {
         HB_CRITICAL_UNLOCK( hb_allocMutex );
         hb_errInternal( HB_EI_XMEMOVERFLOW, "hb_xfree(%p) Pointer Overflow '%s'", (char *) pMem, (char *) pMem );
      }

      s_lMemoryConsumed -= pMemBlock->ulSize;
      s_lMemoryBlocks--;

      if( pMemBlock->pPrevBlock )
      {
         pMemBlock->pPrevBlock->pNextBlock = pMemBlock->pNextBlock;
      }
      else
      {
         s_pFirstBlock = pMemBlock->pNextBlock;
      }

      if( pMemBlock->pNextBlock )
      {
         pMemBlock->pNextBlock->pPrevBlock = pMemBlock->pPrevBlock;
      }
      else
      {
         s_pLastBlock = pMemBlock->pPrevBlock;
      }

      free( ( void * ) pMemBlock );

      HB_CRITICAL_UNLOCK( hb_allocMutex );
   }
   else
   {
      HB_TRACE_STEALTH(HB_TR_INFO, ("hb_xfree(NULL)!"));

      HB_CRITICAL_UNLOCK( hb_allocMutex );

      hb_errInternal( HB_EI_XFREENULL, "hb_xfree(NULL)", NULL, NULL );
   }

#else

   HB_TRACE(HB_TR_DEBUG, ("hb_xfree(%p)", pMem));

   if( pMem )
   {
#ifndef HB_SAFE_ALLOC
      HB_CRITICAL_LOCK( hb_allocMutex );
#endif

      free( pMem );

#ifndef HB_SAFE_ALLOC
      HB_CRITICAL_UNLOCK( hb_allocMutex );
#endif
   }
   else
   {
      hb_errInternal( HB_EI_XFREENULL, NULL, NULL, NULL );
   }

#endif



}

/* NOTE: Debug function, it will always return 0 when HB_FM_STATISTICS is
         not defined, don't use it for final code [vszakats] */

ULONG HB_EXPORT hb_xsize( void * pMem ) /* returns the size of an allocated memory block */
{
   HB_TRACE(HB_TR_DEBUG, ("hb_xsize(%p)", pMem));

   #ifdef HB_FM_STATISTICS
      return ( ( PHB_MEMINFO ) ( ( char * ) pMem - sizeof( HB_MEMINFO ) ) )->ulSize;
   #else
      HB_SYMBOL_UNUSED( pMem );

      return 0;
   #endif
}

void HB_EXPORT hb_xinit( void ) /* Initialize fixed memory subsystem */
{
   HB_TRACE(HB_TR_DEBUG, ("hb_xinit()"));

   #ifdef HB_THREAD_SUPPORT
      hb_stackInit();
      hb_threadInit();
   #endif
}

void HB_EXPORT hb_xexit( void ) /* Deinitialize fixed memory subsystem */
{
   HB_TRACE(HB_TR_DEBUG, ("hb_xexit()"));

#ifdef HB_FM_STATISTICS

   if( s_lMemoryBlocks || hb_cmdargCheck( "INFO" ) )
   {
      PHB_MEMINFO pMemBlock;
      USHORT ui;
      char buffer[ 100 ];

      hb_conOutErr( hb_conNewLine(), 0 );
      hb_conOutErr( "----------------------------------------", 0 );
      hb_conOutErr( hb_conNewLine(), 0 );
      sprintf( buffer, "Total %li allocations (%li reallocation), of which %li freed.", s_lAllocations, s_lReAllocations, s_lFreed );
      hb_conOutErr( buffer, 0 );
      hb_conOutErr( hb_conNewLine(), 0 );
      sprintf( buffer, "Highest total allocated %li, bytes in %li blocks.", s_lMemoryMaxConsumed, s_lMemoryMaxBlocks );
      hb_conOutErr( buffer, 0 );

      if( s_lMemoryBlocks )
      {
         hb_conOutErr( hb_conNewLine(), 0 );
         sprintf( buffer, "WARNING! Memory allocated but not released: %li bytes (%li blocks)", s_lMemoryConsumed, s_lMemoryBlocks );
         hb_conOutErr( buffer, 0 );
      }

      hb_conOutErr( hb_conNewLine(), 0 );

      for( ui = 1, pMemBlock = s_pFirstBlock; pMemBlock; pMemBlock = pMemBlock->pNextBlock )
      {
         /* Safety Termination. */
         ( (char *) ( pMemBlock + 1 ) )[ pMemBlock->ulSize - 1 ] = '\0';

         HB_TRACE( HB_TR_ERROR, ( "Block %i %p (size %lu) %s(%i), \"%s\"",
            ui++,
            (char *) ( pMemBlock + 1 ),
            pMemBlock->ulSize,
            pMemBlock->szProcName,
            pMemBlock->uiProcLine,
            (char *) ( pMemBlock + 1 ) ) );
      }
   }

#endif
}

#if UINT_MAX != ULONG_MAX

/* hb_xmemcpy and hb_xmemset are only needed when
   unsigned int and unsigned long differ in length */

void * hb_xmemcpy( void * pDestArg, void * pSourceArg, ULONG ulLen )
{
   BYTE * pDest;
   BYTE * pSource;
   ULONG  ulRemaining;
   int    iCopySize;

   HB_TRACE(HB_TR_DEBUG, ("hb_xmemcpy(%p, %p, %lu)", pDestArg, pSourceArg, ulLen));

   pDest = ( BYTE * ) pDestArg;
   pSource = ( BYTE * ) pSourceArg;
   ulRemaining = ulLen;

   while( ulRemaining )
   {
      /* Overcome the memcpy() size_t limitation */
      if( ulRemaining > UINT_MAX )
      {
         iCopySize = UINT_MAX;
         ulRemaining -= ( ULONG ) iCopySize;
      }
      else
      {
         iCopySize = ( int ) ulRemaining;
         ulRemaining = 0;
      }
      memcpy( pDest, pSource, iCopySize );
      pDest += iCopySize;
      pSource += iCopySize;
   }

   return pDestArg;
}

void * hb_xmemset( void * pDestArg, int iFill, ULONG ulLen )
{
   BYTE * pDest;
   ULONG  ulRemaining;
   int    iSetSize;

   HB_TRACE(HB_TR_DEBUG, ("hb_xmemset(%p, %d, %lu)", pDestArg, iFill, ulLen));

   pDest = ( BYTE * ) pDestArg;
   ulRemaining = ulLen;

   while( ulRemaining )
   {
      /* Overcome the memset() size_t limitation */
      if( ulRemaining > UINT_MAX )
      {
         iSetSize = UINT_MAX;
         ulRemaining -= ( ULONG ) iSetSize;
      }
      else
      {
         iSetSize = ( int ) ulRemaining;
         ulRemaining = 0;
      }
      memset( pDest, iFill, iSetSize );
      pDest += iSetSize;
   }

   return pDestArg;
}

#endif

ULONG hb_xquery( USHORT uiMode )
{
   ULONG ulResult;
   HB_THREAD_STUB

   HB_TRACE(HB_TR_DEBUG, ("hb_xquery(%hu)", uiMode));

/*
#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_LOCK( hb_allocMutex );
#ifndef HB_SAFE_ALLOC
*/
   /* TODO: Return the correct values instead of 9999 [vszakats] */

   switch( uiMode )
   {
   case HB_MEM_CHAR:       /*               (Free Variable Space [KB])          */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = memorystatus.dwAvailPhys / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         ULONG ulSysInfo = 0;

         if( DosQuerySysInfo( QSV_TOTAVAILMEM, QSV_TOTAVAILMEM, &ulSysInfo, sizeof( ULONG ) ) != NO_ERROR )
            ulResult = 0;
         else
            ulResult = ulSysInfo / 1024;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_BLOCK:      /*               (Largest String [KB])               */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = HB_MIN( memorystatus.dwAvailPhys, ULONG_MAX ) / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         ULONG ulSysInfo = 0;

         if( DosQuerySysInfo( QSV_TOTAVAILMEM, QSV_TOTAVAILMEM, &ulSysInfo, sizeof( ULONG ) ) != NO_ERROR )
            ulResult = 0;
         else
            ulResult = HB_MIN( ulSysInfo, ULONG_MAX ) / 1024;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_RUN:        /*               (RUN Memory [KB])                   */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = memorystatus.dwAvailPhys / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         ULONG ulSysInfo = 0;

         if( DosQuerySysInfo( QSV_TOTAVAILMEM, QSV_TOTAVAILMEM, &ulSysInfo, sizeof( ULONG ) ) != NO_ERROR )
            ulResult = 0;
         else
            ulResult = ulSysInfo / 1024;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_VM:         /* UNDOCUMENTED! (Virtual Memory [KB])               */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = memorystatus.dwAvailVirtual / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         ULONG ulSysInfo = 0;

         if( DosQuerySysInfo( QSV_TOTAVAILMEM, QSV_TOTAVAILMEM, &ulSysInfo, sizeof( ULONG ) ) != NO_ERROR )
            ulResult = 0;
         else
            ulResult = ulSysInfo / 1024;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_EMS:        /* UNDOCUMENTED! (Free Expanded Memory [KB]) (?)     */
      #if defined(HB_OS_WIN_32) || defined(HB_OS_OS2)
         ulResult = 0;
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_FM:         /* UNDOCUMENTED! (Fixed Memory/Heap [KB]) (?)        */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = memorystatus.dwTotalPhys / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         ULONG ulSysInfo = 0;

         if( DosQuerySysInfo( QSV_MAXPRMEM, QSV_MAXPRMEM, &ulSysInfo, sizeof( ULONG ) ) != NO_ERROR )
            ulResult = 0;
         else
            ulResult = ulSysInfo / 1024;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_FMSEGS:     /* UNDOCUMENTED! (Segments in Fixed Memory/Heap) (?) */
      #if defined(HB_OS_WIN_32) || defined(HB_OS_OS2)
         ulResult = 1;
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_SWAP:       /* UNDOCUMENTED! (Free Swap Memory [KB])             */
      #if defined(HB_OS_WIN_32)
      {
         MEMORYSTATUS memorystatus;
         GlobalMemoryStatus( &memorystatus );
         ulResult = memorystatus.dwAvailPageFile / 1024;
      }
      #elif defined(HB_OS_OS2)
      {
         /* NOTE: There is no way to know how much a swap file can grow on an
                  OS/2 system. I think we should return free space on DASD
                  media which contains swap file [maurilio.longo] */
         ulResult = 9999;
      }
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_CONV:       /* UNDOCUMENTED! (Free Conventional [KB])            */
      #if defined(HB_OS_WIN_32) || defined(HB_OS_OS2)
         ulResult = 0;
      #else
         ulResult = 9999;
      #endif
      break;

   case HB_MEM_EMSUSED:    /* UNDOCUMENTED! (Used Expanded Memory [KB]) (?)     */
      ulResult = 0;
      break;

   case HB_MEM_USED:       /* Harbour extension (Memory used [bytes])           */
#ifdef HB_FM_STATISTICS
      ulResult = s_lMemoryConsumed;
#else
      ulResult = 0;
#endif
      break;

   case HB_MEM_USEDMAX:    /* Harbour extension (Maximum memory used [bytes])   */
#ifdef HB_FM_STATISTICS
      ulResult = s_lMemoryMaxConsumed;
#else
      ulResult = 0;
#endif
      break;

   case HB_MEM_STACKITEMS: /* Harbour extension (Total items allocated for the stack)      */
      ulResult = HB_VM_STACK.wItems;
      break;

   case HB_MEM_STACK:      /* Harbour extension (Total memory size used by the stack [bytes]) */
      ulResult = HB_VM_STACK.wItems * sizeof( HB_ITEM );
      break;

   case HB_MEM_STACK_TOP : /* Harbour extension (Total items currently on the stack)      */
      ulResult = hb_stackTopOffset( );
      break;

   default:
      ulResult = 0;
   }

/*
#ifndef HB_SAFE_ALLOC
   HB_CRITICAL_UNLOCK( hb_allocMutex );
#endif
*/

   return ulResult;
}

HB_FUNC( MEMORY )
{
   HB_THREAD_STUB
   hb_retnl( hb_xquery( hb_parni( 1 ) ) );
}

#ifdef HB_FM_STATISTICS
HB_FUNC( HB_FM_STAT ) {};
#else
HB_FUNC( HB_FM_NOSTAT ) {};
#endif
