/*
 * $Id: hbrddsdf.h,v 1.11 2009/07/22 16:55:02 marchuet Exp $
 */

/*
 * Harbour Project source code:
 *    SDF RDD
 *
 * Copyright 2006 Przemyslaw Czerpak <druzus / at / priv.onet.pl>
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

#ifndef HB_RDDSDF_H_
#define HB_RDDSDF_H_

#include "hbapirdd.h"

HB_EXTERN_BEGIN

/* SDF default file extensions */
#define SDF_TABLEEXT                      ".txt"


/*
 *  SDF WORKAREA
 *  ------------
 *  The Workarea Structure of SDF RDD
 *
 */

typedef struct _SDFAREA
{
   AREA area;

   /*
   *  SDFS's additions to the workarea structure
   *
   *  Warning: The above section MUST match WORKAREA exactly!  Any
   *  additions to the structure MUST be added below, as in this
   *  example.
   */

   PHB_FILE pFile;                  /* Data file handle */
   char *   szFileName;             /* Name of data file */
   char *   szEol;                  /* EOL marker */
   USHORT   uiEolLen;               /* Size of EOL marker */
   USHORT   uiRecordLen;            /* Size of record */
   USHORT * pFieldOffset;           /* Pointer to field offset array */
   BYTE *   pRecord;                /* Buffer of record data */
   HB_FOFFSET ulRecordOffset;       /* Current record offest */
   HB_FOFFSET ulNextOffset;         /* Next record offest */
   HB_FOFFSET ulFileSize;           /* File table size in export mode */
   ULONG    ulRecNo;                /* Current record */
   ULONG    ulRecCount;             /* Number of records (in export) */
   BOOL     fTransRec;              /* Can put whole records */
   BOOL     fFlush;                 /* Data was written to SDF and not commited */
   BOOL     fShared;                /* Shared file */
   BOOL     fReadonly;              /* Read only file */
   BOOL     fPositioned;            /* Positioned record */
   BOOL     fRecordChanged;         /* Record changed */
} SDFAREA;

typedef SDFAREA * LPSDFAREA;

#ifndef SDFAREAP
#define SDFAREAP LPSDFAREA
#endif

HB_EXTERN_END

#endif /* HB_RDDSDF_H_ */
