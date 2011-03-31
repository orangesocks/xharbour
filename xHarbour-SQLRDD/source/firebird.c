/* $CATEGORY$SQLRDD/HIDE$FILES$HIDE$
* SQLRDD Firebird Native Access
* Copyright (c) 2004 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"
#include "hbdefs.h"
#include "hbapierr.h"
#include "hashapi.h"
#include "hbfast.h"

#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include "sqlodbc.ch"

#include "firebird.h"

#if TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif

#define MAX_COLUMNS_IN_QUERY  620
#define MSG_BUFFER_LEN        1024
#define LOGFILE               "fb.log"

#define CHECK_ERROR(session)  (session->status[0] == 1 && session->status[1] > 0)
#define ERRORLOGANDEXIT(session, from) { fb_log_status(session, from); hb_retnl(SQL_ERROR); return; }

#ifndef ISC_INT64_FORMAT
#if (defined(_MSC_VER) && defined(WIN32)) || (defined(__BORLANDC__) && defined(__WIN32__))
#define   ISC_INT64_FORMAT   "I64"
#else
#define   ISC_INT64_FORMAT   "ll"
#endif
#endif

static PHB_DYNS s_pSym_SR_DESERIALIZE = NULL;
static PHB_DYNS s_pSym_SR_FROMJSON = NULL;

static char isc_tpb[] = {isc_tpb_version3,
                         isc_tpb_write,
                         isc_tpb_read_committed,
                         isc_tpb_rec_version,
                         isc_tpb_nowait};

typedef struct _FB_SESSION
{
   isc_db_handle db;
   ISC_STATUS status[20];
   isc_tr_handle transac;
   XSQLDA ISC_FAR * sqlda;
   isc_stmt_handle stmt;
   char msgerror[512];
   long errorcode;
   int transactionPending;
} FB_SESSION;

typedef FB_SESSION * PFB_SESSION;

typedef struct vary1 {
    short vary_length;
    char  vary_string [1];
} VARY;

const double divider[19] = { 1, 1E1, 1E2, 1E3, 1E4,   1E5, 1E6, 1E7, 1E8, 1E9, 1E10, 1E11, 1E12, 1E13, 1E14, 1E15, 1E16, 1E17, 1E18 };

/*------------------------------------------------------------------------*/

void fb_log_status( PFB_SESSION session, char * from )
{
   long * pVect = session->status;
   isc_interprete( session->msgerror, &pVect );
   session->errorcode = session->status[1];
   HB_SYMBOL_UNUSED( from );

//   TraceLog( LOGFILE, "FireBird Error: %s - %s - code: %i (see iberr.h)\n", from, session->msgerror, session->status[1] );
   if (session->transac)
   {
      isc_rollback_transaction( session->status, &(session->transac) );
      if ( CHECK_ERROR(session) )
      {
         ERRORLOGANDEXIT( session, "FBROLLBACKTRANSACTION ON ERROR" );
      }
      else
      {
         session->transac = NULL;
         session->transactionPending = 0;
      }
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBCONNECT )  // FBConnect( cDatabase, cUser, cPassword, [charset], @hEnv )
{
   XSQLVAR * var;
   const char * db_connect;
   const char * user;
   const char * passwd;
   const char * charset;
   char dpb[256];
   int  i, len;

   PFB_SESSION session = (PFB_SESSION) hb_xgrab( sizeof( FB_SESSION ) );

   session->db = NULL;
   session->transac = NULL;
   session->sqlda    = ( XSQLDA ISC_FAR * ) hb_xgrab( XSQLDA_LENGTH ( MAX_COLUMNS_IN_QUERY ) );
   session->sqlda->sqln = MAX_COLUMNS_IN_QUERY;
   session->sqlda->version = SQLDA_VERSION1;
   session->stmt = NULL;
   session->transactionPending = 0;

   for ( i = 0, var = session->sqlda->sqlvar; i < MAX_COLUMNS_IN_QUERY; i++, var++ )
   {
      var->sqldata = NULL;
   }

   db_connect = hb_parcx(1);
   user       = hb_parcx(2);
   passwd     = hb_parcx(3);
   charset    = hb_parc(4);

   i = 0;
   dpb[i++] = isc_dpb_version1;
   dpb[i++] = isc_dpb_user_name;
   len = strlen(user);
   dpb[i++] = (char) len;
   strncpy(&(dpb[i]), user, len);
   i += len;

   dpb[i++] = isc_dpb_password;
   len = strlen(passwd);
   dpb[i++] = len;
   strncpy(&(dpb[i]), passwd, len);
   i += len;

   if ( charset != NULL )
   {
      dpb[i++] = isc_dpb_lc_ctype;
      len = strlen(charset);
      dpb[i++] = len;
      strncpy(&(dpb[i]), charset, len);
      i += len;
   }
   if ( isc_attach_database( session->status, 0, db_connect, &(session->db), i, dpb ) )
   {
      fb_log_status(session, "FBCONNECT");
      TraceLog( LOGFILE, "FireBird Error: %s - code: %i (see iberr.h)\n", session->msgerror, session->status[1] );
      hb_xfree( session->sqlda );
      hb_xfree( session );
      hb_retnl(SQL_ERROR);
      return;
   }
   else
   {
      hb_retni( SQL_SUCCESS );
      hb_storptr( ( void * ) session, 5 );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBCLOSE )   // FBClose( hEnv )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   int i;
   XSQLVAR * var;

   if (session)
   {
      if (session->transac)
      {
         if ( isc_commit_transaction( session->status, &(session->transac) ) )
         {
            ERRORLOGANDEXIT( session, "FBCLOSE" );
         }
      }

      if ( isc_detach_database ( session->status, &(session->db) ) )
      {
         ERRORLOGANDEXIT( session, "FBCLOSE" );
      }

      for ( i = 0, var = session->sqlda->sqlvar; i < MAX_COLUMNS_IN_QUERY; i++, var++ )
      {
         if (var->sqldata)
         {
            hb_xfree( var->sqldata );
            hb_xfree( var->sqlind );
         }
      }
      hb_xfree( session->sqlda );
      hb_xfree( session );
   }
   hb_retni( SQL_SUCCESS );
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBBEGINTRANSACTION )  // FBBeginTransaction( hEnv )
{
   PFB_SESSION session = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if ( CHECK_ERROR(session) && session->transac )
   {
      isc_rollback_transaction( session->status, &(session->transac) );
      if ( CHECK_ERROR(session) )
      {
         ERRORLOGANDEXIT( session, "FBROLLBACKTRANSACTION" );
      }
      else
      {
         session->transac = NULL;
         session->transactionPending = 0;
      }
   }

   if (session->transactionPending && session->transac)
   {
      isc_commit_retaining( session->status, &(session->transac) );
      if ( CHECK_ERROR(session) )
      {
         session->transactionPending = 0;
         isc_commit_transaction( session->status, &(session->transac) );
         if ( CHECK_ERROR(session) )
         {
            ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION1_1" );
         }

         if (isc_start_transaction(session->status, &(session->transac), 1, &(session->db), (unsigned short) sizeof(isc_tpb), isc_tpb))
         {
            ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION1_2" );
         }
         else
         {
            hb_retni( SQL_SUCCESS );
         }

      }
   }
   else
   {
      if (session->transac)
      {
         isc_commit_transaction( session->status, &(session->transac) );
         if ( CHECK_ERROR(session) )
         {
            ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION2" );
         }
      }

      if (isc_start_transaction(session->status, &(session->transac), 1, &(session->db), (unsigned short) sizeof(isc_tpb), isc_tpb))
      {
         ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION3" );
      }
      else
      {
         hb_retni( SQL_SUCCESS );
      }
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBCOMMITTRANSACTION )  // FBBeginTransaction( hEnv )
{
   PFB_SESSION session = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if (session->transac)
   {
      isc_commit_transaction( session->status, &(session->transac) );
      if ( CHECK_ERROR(session) )
      {
         ERRORLOGANDEXIT( session, "FBCOMMITTRANSACTION1" );
      }
      else
      {
         session->transac = NULL;
         session->transactionPending = 0;
         hb_retni( SQL_SUCCESS );
      }
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBROLLBACKTRANSACTION )  // FBRollBackTransaction( hEnv )
{
   PFB_SESSION session = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if (session->transac)
   {
      isc_rollback_transaction( session->status, &(session->transac) );
      if ( CHECK_ERROR(session) )
      {
         ERRORLOGANDEXIT( session, "FBROLLBACKTRANSACTION" );
      }
      else
      {
         session->transac = NULL;
         session->transactionPending = 0;
         hb_retni( SQL_SUCCESS );
      }
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBEXECUTE ) // FBExecute( hEnv, cCmd, nDialect )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   const char * command = hb_parcx(2);
   int i, dtype;
   XSQLVAR * var;

   if (session->stmt)
   {
      if (isc_dsql_free_statement( session->status, &(session->stmt), DSQL_drop))
      {
          ERRORLOGANDEXIT( session, "FBEXECUTE1" );
      }
     session->stmt = NULL;
   }

   if (isc_dsql_allocate_statement( session->status, &(session->db), &(session->stmt) ))
   {
      ERRORLOGANDEXIT( session, "FBEXECUTE2" );
   }

   if (!session->transac)
   {
      if (isc_start_transaction(session->status, &(session->transac), 1, &(session->db), (unsigned short) sizeof(isc_tpb), isc_tpb))
      {
         ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION1_3" );
      }
      else
      {
         hb_retni( SQL_SUCCESS );
      }
   }
   //printf( "isc_dsql_prepare %p %p %p %s %p\n", session->status, session->transac, session->stmt, command, session->sqlda );
   if (isc_dsql_prepare( session->status, &(session->transac), &(session->stmt), 0, command, hb_parni(3), session->sqlda ))
   {
      ERRORLOGANDEXIT( session, (char *) command );
   }

   for ( i = 0, var = session->sqlda->sqlvar; i < session->sqlda->sqld; i++, var++ )
   {
      dtype = ( var->sqltype & ~1 );
      if (var->sqldata)
      {
         hb_xfree( var->sqldata );
         hb_xfree( var->sqlind );
      }
      switch ( dtype )
      {
      case IB_SQL_TEXT:
         var->sqldata = (SCHAR *) hb_xgrab( (sizeof ( char ) * var->sqllen ) + 1 );
         break;
      case IB_SQL_VARYING:
         var->sqldata = (SCHAR *) hb_xgrab( (sizeof ( char ) * var->sqllen ) + 3 );
         break;
      case IB_SQL_LONG:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( long ) );
         break;
      case IB_SQL_SHORT:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( short ) );
         break;
      case IB_SQL_FLOAT:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( float ) );
         break;
      case IB_SQL_DOUBLE:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( double ) );
         break;
      case IB_SQL_D_FLOAT:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( float ) * 2 );
         break;
      case IB_SQL_TIMESTAMP:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( ISC_TIMESTAMP ) + 10 );
         break;
      case IB_SQL_ARRAY:
      case IB_SQL_QUAD:
      case IB_SQL_BLOB:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( ISC_QUAD ) );
         break;
      case IB_SQL_TYPE_TIME:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( ISC_TIME ) + 10 );
         break;
      case IB_SQL_TYPE_DATE:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( ISC_DATE ) );
         break;
      case IB_SQL_INT64:
         var->sqldata = (SCHAR *) hb_xgrab( sizeof ( ISC_INT64 ) * var->sqllen );
         break;
      default:
        var->sqldata = (SCHAR *) hb_xgrab( sizeof ( char ) * var->sqllen );
        break;
      }
      var->sqlind = ( short * ) hb_xgrab( sizeof ( short ) );
   }

   session->transactionPending = 1;

   if ( !session->sqlda->sqld )
   {
      if ( isc_dsql_execute( session->status, &(session->transac), &(session->stmt), hb_parni(3), NULL ) )
      {
         ERRORLOGANDEXIT( session, "FBEXECUTE4" );
      }
   }
   else
   {
      if ( isc_dsql_execute( session->status, &(session->transac), &(session->stmt), hb_parni(3), session->sqlda ) )
      {
         ERRORLOGANDEXIT( session, "FBEXECUTE5" );
      }
   }

   hb_retni( SQL_SUCCESS );
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBEXECUTEIMMEDIATE ) // FBExecuteImmediate( hEnv, cCmd, nDialect )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   const char * command = hb_parcx(2);

   if (!session->transac)
   {
      if (isc_start_transaction(session->status, &(session->transac), 1, &(session->db), (unsigned short) sizeof(isc_tpb), isc_tpb))
      {
         ERRORLOGANDEXIT( session, "FBBEGINTRANSACTION1_4" );
      }
      else
      {
         hb_retni( SQL_SUCCESS );
      }
   }

   if (isc_dsql_execute_immediate( session->status, &(session->db), &(session->transac), 0, command, hb_parni(3), NULL ))
   {
      ERRORLOGANDEXIT( session, (char *) command );
   }

   session->transactionPending = 1;
   hb_retni( SQL_SUCCESS );
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBDESCRIBECOL )   // FBDescribeCol( hStmt, nCol, @cName, @nType, @nLen, @nDec, @nNull )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   int icol = hb_parni( 2 );
   int dtype, rettype, i;
   XSQLVAR * var;

   if ( session && session->sqlda->sqld >= (icol) )
   {
      var = session->sqlda->sqlvar;
      for ( i = 0; i < icol-1; i++, var++ ){}
      
      dtype = ( ( (XSQLVAR *) var )->sqltype & ~1 );

      switch ( dtype )
      {
      case IB_SQL_TEXT:
      case IB_SQL_VARYING:
         rettype = SQL_CHAR;
         hb_storni( var->sqllen, 5 );
         hb_storni( var->sqlscale, 6 );

         break;
      case IB_SQL_TYPE_TIME:
         rettype = SQL_CHAR;
         hb_storni( 13, 5 );
         hb_storni( 0, 6 );

         break;
      case IB_SQL_TIMESTAMP:
         rettype = SQL_CHAR;
         
         hb_storni( 24, 5 );
         hb_storni( 0, 6 );
         break;
      case IB_SQL_SHORT:
      
         rettype = SQL_SMALLINT;
         hb_storni( var->sqllen, 1 );
         hb_storni( var->sqlscale, 0 );
         break;

      case IB_SQL_LONG:
      case IB_SQL_INT64:      

         rettype = SQL_NUMERIC;
         hb_storni( 20, 5 );
         hb_storni( -var->sqlscale, 6 );
         break;
      
      case IB_SQL_FLOAT:
      case IB_SQL_DOUBLE:
      case IB_SQL_D_FLOAT:
         rettype = SQL_DOUBLE;
         hb_storni( 23, 5 );
         hb_storni( 3, 6 );
         
         break;
      case IB_SQL_BLOB:
      case IB_SQL_ARRAY:
      case IB_SQL_QUAD:

         rettype = SQL_LONGVARCHAR;
         hb_storni( 10L, 5 );
         hb_storni( 0L, 6 );
         break;
      case IB_SQL_TYPE_DATE:

         rettype = SQL_DATE;
         hb_storni( 8L, 5 );
         hb_storni( 0L, 6 );
         break;
      default:      

         TraceLog( LOGFILE, "Unrecognized data type returned in query: %i\n", dtype );
         rettype = SQL_CHAR;
         hb_storni( var->sqllen, 5 );
         hb_storni( var->sqlscale, 6 );
         
         break;
      }
//      hb_storclen( (char *) var->sqlname, var->sqlname_length, 3 );
         //TraceLog("size.log","%s %lu %lu\r \n",var->aliasname,var->sqllen, -var->sqlscale);
      hb_storclen( (char *) var->aliasname, var->aliasname_length, 3 );
      hb_storni( rettype, 4 );

      if ( var->sqltype & 1 )
      {
         hb_storni( 1, 7 );
      }
      else
      {
         hb_storni( 0, 7 );
      }

      hb_retni( SQL_SUCCESS );
   }
   else
   {
      hb_retni( SQL_ERROR );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBNUMRESULTCOLS )  // FBNumResultCols( hEnv, @nResultSetColumnCount )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if ( session )
   {
      hb_storni( session->sqlda->sqld, 2 );
      hb_retni( SQL_SUCCESS );
   }
   else
   {
      hb_retni( SQL_ERROR );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBERROR )   // FBError( hEnv )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if ( session )
   {
      hb_retc( session->msgerror );
      hb_storni( session->errorcode, 2 );
   }
   else
   {
      hb_retni( SQL_ERROR );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBFETCH )   // FBFetch( hEnv )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   if ( session )
   {
      if( isc_dsql_fetch( session->status, &(session->stmt), session->sqlda->version, session->sqlda ) )
      {
         hb_retni( SQL_NO_DATA_FOUND );
      }
      else
      {
         hb_retni( SQL_SUCCESS );
      }
   }
   else
   {
      hb_retni( SQL_ERROR );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBGETDATA )    // FBGetData( hEnv, nField, @uData )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   int icol = hb_parni( 2 );
   int dtype, i;
   char data[MSG_BUFFER_LEN], *p;
   char date_s[30];
   struct tm times;
   ISC_QUAD * blob_id;
   isc_blob_handle blob_handle = NULL;
   short blob_seg_len;
   char * resp, item, * read_blob;
   char blob_items[] = { isc_info_blob_total_length, isc_info_blob_num_segments };
   char res_buffer[20];
   LONG blob_size = 0L, num_segments = 0L, count, residual_size;
   short length;
   BOOL bEnd = 0;
   XSQLVAR * var;
   VARY * vary;

   if ( session && session->sqlda->sqld >= (icol) )
   {
      var = session->sqlda->sqlvar;
      for ( i = 0; i < icol-1; i++, var++ ){}

      if( ( var->sqltype & 1 ) && ( *var->sqlind < 0 ) )
      {
         hb_storc( " ", 3 );
      }
      else
      {
         dtype = ( ( (XSQLVAR *) var )->sqltype & ~1 );
         switch ( dtype )
         {
         case IB_SQL_TEXT:
            hb_storclen( (char *) var->sqldata, var->sqllen, 3 );
            break;
         case IB_SQL_VARYING:
            vary = (VARY*) var->sqldata;
            vary->vary_string[vary->vary_length] = '\0';
            hb_storc( (char *) vary->vary_string, 3 );
            break;
         case IB_SQL_TIMESTAMP:
            isc_decode_timestamp( ( ISC_TIMESTAMP ISC_FAR * ) var->sqldata, &times );
            sprintf ( date_s, "%04d-%02d-%02d %02d:%02d:%02d.%04lu",
                  times.tm_year + 1900,
                  times.tm_mon + 1,
                  times.tm_mday,
                  times.tm_hour,
                  times.tm_min,
                  times.tm_sec,
                  ( ( ISC_TIMESTAMP * ) var->sqldata )->timestamp_time % 10000 );

//            sprintf ( p, "%*s ", 24, date_s );
            hb_storc( date_s, 3 );
            break;

         case IB_SQL_TYPE_TIME:
            isc_decode_sql_time( ( ISC_TIME ISC_FAR * ) var->sqldata, &times );
            sprintf ( date_s, "%02d:%02d:%02d.%04lu",
                  times.tm_hour,
                  times.tm_min,
                  times.tm_sec, ( *( ( ISC_TIME * ) var->sqldata ) ) % 10000 );
            hb_storc( date_s, 3 );
            break;

         case IB_SQL_LONG:
         case IB_SQL_INT64:
         case IB_SQL_SHORT:
            p = data;
            {
               ISC_INT64  value;
               short field_width, dscale;
               switch (dtype)
               {
               case IB_SQL_SHORT:
                  value = (ISC_INT64) *(short ISC_FAR *) var->sqldata;
                  field_width = 6;
                  break;

               case IB_SQL_LONG:
                  value = (ISC_INT64) *(long ISC_FAR *) var->sqldata;
                  field_width = 11;
                  break;

               case IB_SQL_INT64:
                  value = (ISC_INT64) *(ISC_INT64 ISC_FAR *) var->sqldata;
                  field_width = 21;
                  break;
               }

               dscale = var->sqlscale;

               if (dscale < 0)
               {
                  ISC_INT64 tens;
                  short i;
                  tens = 1;
                  for (i = 0; i > dscale; i--)
                  {
                     tens *= 10;
                  }

                  if (value >= 0)
                  {
                     sprintf( p, "%*" ISC_INT64_FORMAT "d.%0*" ISC_INT64_FORMAT "d",
                              field_width - 1 + dscale,
                              (ISC_INT64) value / tens,
                              -dscale,
                              (ISC_INT64) value % tens );
                  }
                  else if ((value / tens) != 0)
                  {
                     sprintf( p, "%*" ISC_INT64_FORMAT "d.%0*" ISC_INT64_FORMAT "d",
                              field_width - 1 + dscale,
                              (ISC_INT64) (value / tens),
                              -dscale,
                              (ISC_INT64) -(value % tens));
                  }
                  else
                  {
                     sprintf( p, "%*s.%0*" ISC_INT64_FORMAT "d",
                              field_width - 1 + dscale,
                              "-0",
                              -dscale,
                              (ISC_INT64) -(value % tens));
                  }
               }
               else if (dscale)
               {
                  sprintf( p, "%*" ISC_INT64_FORMAT "d%0*d", field_width, (ISC_INT64) value, dscale, 0);
               }
               else
               {
                  sprintf(p, "%*" ISC_INT64_FORMAT "d", field_width, (ISC_INT64) value);
               }
            };
            hb_storc( p, 3 );
            break;

         case IB_SQL_FLOAT:
            p = data;
            sprintf( p, "%15g ", *(float ISC_FAR *) (var->sqldata));
            hb_storc( p, 3 );
            break;

         case IB_SQL_DOUBLE:
            p = data;
            sprintf( p, "%24f ", *(double ISC_FAR *) (var->sqldata));
            hb_storc( p, 3 );
            break;

         case IB_SQL_BLOB:
         case IB_SQL_ARRAY:
         case IB_SQL_QUAD:
            blob_id = ( ISC_QUAD * ) var->sqldata;
            if ( isc_open_blob2( session->status, &(session->db), &(session->transac), &blob_handle, blob_id, 0, NULL))
            {
               ERRORLOGANDEXIT( session, "FBGETDATA1" );
            }
            if ( isc_blob_info( session->status, &blob_handle, sizeof(blob_items), blob_items, sizeof(res_buffer), res_buffer ) )
            {
               ERRORLOGANDEXIT( session, "FBGETDATA2" );
            }
            for ( resp = res_buffer; * resp != isc_info_end ;)
            {
               item = *resp++;
               length = (short)isc_vax_integer( resp, 2 );
               resp += 2;
               switch (item)
               {
               case isc_info_blob_total_length:
                  blob_size = isc_vax_integer( resp, length );
                  break;
               case isc_info_blob_num_segments:
                  num_segments = isc_vax_integer( resp, length );
                  break;
               case isc_info_truncated:
                  bEnd = 1;
                  break;
               default:
                  break;
               }
               if (bEnd)
               {
                  break;
               }
               resp += length;
            };
            read_blob = (char *) hb_xgrab( blob_size + 1 );
            read_blob[blob_size] = '\0';
            p = read_blob;
            residual_size = blob_size;

            for ( count=0; count <= num_segments; count++ )
            {
               if (isc_get_segment( session->status, &blob_handle, (unsigned short ISC_FAR *) &blob_seg_len, (unsigned short) residual_size, p ) != isc_segstr_eof)
               {
                  p += blob_seg_len;
                  residual_size -= blob_seg_len;
               }
            }

            if ( isc_close_blob( session->status, &blob_handle ) )
            {
               ERRORLOGANDEXIT( session, "FBGETDATA3" );
            }

            hb_storclenAdopt( read_blob, blob_size, 3 );
            break;

         case IB_SQL_TYPE_DATE:
            isc_decode_sql_date ( ( ISC_DATE ISC_FAR * ) var->sqldata, &times );
            sprintf( date_s, "%04d-%02d-%02d", times.tm_year + 1900, times.tm_mon + 1, times.tm_mday );
            p = data;
            sprintf( p, "%*s ", 8, date_s );
            hb_storc( p, 3 );
            break;

         default:
            TraceLog( LOGFILE, "Unsupported data type returned in query: %i\n", dtype );
            break;
         }
      }
      hb_retni( SQL_SUCCESS );
   }
   else
   {
      hb_retni( SQL_ERROR );
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBCREATEDB )
{
   isc_db_handle newdb = NULL;
   isc_tr_handle trans = NULL;
   long status[20];
   char create_db[1024];
   const char * db_name;
   const char * username;
   const char * passwd;
   const char * charset;
   int page;
   int dialect;

   db_name = hb_parcx(1);
   username = hb_parcx(2);
   passwd = hb_parcx(3);
   page = hb_parni(4);
   charset = hb_parc(5);
   dialect = hb_parni(6);

   if (!dialect)
   {
      dialect = 3;
   }

   if (charset && page)
   {
      sprintf(create_db,
         "CREATE DATABASE '%s' USER '%s' PASSWORD '%s' PAGE_SIZE = %i DEFAULT CHARACTER SET %s",
         db_name, username, passwd, page, charset );
   }
   else if( charset )
   {
      sprintf(create_db,
         "CREATE DATABASE '%s' USER '%s' PASSWORD '%s' DEFAULT CHARACTER SET %s",
         db_name, username, passwd, charset );
   }
   else if( page )
   {
      sprintf(create_db,
         "CREATE DATABASE '%s' USER '%s' PASSWORD '%s' PAGE_SIZE = %i",
         db_name, username, passwd, page, charset );
   }
   else
   {
      sprintf(create_db, "CREATE DATABASE '%s' USER '%s' PASSWORD '%s'", db_name, username, passwd, page, charset );
   }

   if (isc_dsql_execute_immediate(status, &newdb, &trans, 0, create_db, dialect, NULL))
   {
      hb_retni( SQL_ERROR );
      TraceLog( LOGFILE, "FireBird Error: %s - code: %i (see iberr.h)\n", "create database", status[1] );
   }
   else
   {
	 if ( isc_detach_database ( status, &newdb ) )
	 {
		 hb_retni( SQL_ERROR );
		 return ;
     }	 
  
      hb_retni( SQL_SUCCESS );
   }
}

/*------------------------------------------------------------------------*/

static void firebird_info_cb(void *arg, char const *s)
{
   if(*(char*)arg)
   {
      strcat((char*)arg, " ");
//      strcat((char*)arg, s);
   }
   else
   {
      strcpy((char*)arg, s);
   }
}

HB_FUNC( FBVERSION )
{
   SLONG num_version = 0L;
   char tmp[1000];

   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );

   *tmp = 0;

   if (!isc_version( &(session->db), firebird_info_cb, (void*)tmp))
   {
   	isc_vax_integer( tmp, 100 );
      hb_retnl( num_version );
   }
   hb_retc( tmp );
}

/*------------------------------------------------------------------------*/

void FBFieldGet( PHB_ITEM pField, PHB_ITEM pItem, char * bBuffer, LONG lLenBuff, BOOL bQueryOnly, ULONG ulSystemID, BOOL bTranslate )
{
   LONG lType;
   LONG lLen, lDec;
   PHB_ITEM pTemp;
   HB_SYMBOL_UNUSED( bQueryOnly );
   HB_SYMBOL_UNUSED( ulSystemID );

   lType = ( LONG ) hb_arrayGetNL( pField, 6 );
   lLen  = ( LONG ) hb_arrayGetNL( pField, 3 );
   lDec  = ( LONG ) hb_arrayGetNL( pField, 4 );

   if( lLenBuff <= 0 )     // database content is NULL
   {
      switch( lType )
      {
         case SQL_CHAR:
         {
            char * szResult = ( char * ) hb_xgrab( lLen + 1 );
            hb_xmemset( szResult, ' ', lLen );
            hb_itemPutCPtr( pItem, szResult, (ULONG) lLen );
            break;
         }
         case SQL_NUMERIC:
         case SQL_FAKE_NUM:
         case SQL_DOUBLE:
         case SQL_FLOAT:
         {
            char szResult[2] = { ' ', '\0' };
            sr_escapeNumber( szResult, (ULONG) lLen, (ULONG) lDec, pItem );
            break;
         }
         case SQL_DATE:
         {
            char dt[9] = {' ',' ',' ',' ',' ',' ',' ',' ','\0'};
            hb_itemPutDS( pItem, dt );
            break;
         }
         case SQL_LONGVARCHAR:
         {
            hb_itemPutCL( pItem, bBuffer, 0 );
            break;
         }
         case SQL_BIT:
         case SQL_SMALLINT:
         {
            hb_itemPutL( pItem, FALSE );
            break;
         }

#ifdef SQLRDD_TOPCONN
         case SQL_FAKE_DATE:
         {
            hb_itemPutDS( pItem, bBuffer );
            break;
         }
#endif
         default:
            TraceLog( LOGFILE, "Invalid data type detected: %i\n", lType );
      }
   }
   else
   {
      switch( lType )
      {
         case SQL_CHAR:
         {
            LONG lPos;
            char * szResult = ( char * ) hb_xgrab( lLen + 1 );
            hb_xmemcpy( szResult, bBuffer, ( LONG ) (lLen < lLenBuff ? lLen : lLenBuff ) );

            for( lPos = ( LONG ) lLenBuff; lPos < lLen; lPos++ )
            {
               szResult[ lPos ] = ' ';
            }
            hb_itemPutCPtr( pItem, szResult, (ULONG) lLen );
            break;
         }
         case SQL_DOUBLE:
         case SQL_FLOAT:
         case SQL_NUMERIC:
         {
            sr_escapeNumber( bBuffer, (ULONG) lLen, (ULONG) lDec, pItem );
            break;
         }
         case SQL_DATE:
         {
            char dt[9];
            dt[0] = bBuffer[0];
            dt[1] = bBuffer[1];
            dt[2] = bBuffer[2];
            dt[3] = bBuffer[3];
            dt[4] = bBuffer[5];
            dt[5] = bBuffer[6];
            dt[6] = bBuffer[8];
            dt[7] = bBuffer[9];
            dt[8] = '\0';
            hb_itemPutDS( pItem, dt );
            break;
         }
         case SQL_LONGVARCHAR:
         {
            if( lLenBuff > 0 && (strncmp( bBuffer, "[", 1 ) == 0 || strncmp( bBuffer, "[]", 2 ) )&& (sr_lSerializeArrayAsJson()) )
            {
               if (s_pSym_SR_FROMJSON == NULL )
               {
                  hb_dynsymLock();
                  s_pSym_SR_FROMJSON = hb_dynsymFindName( "HB_JSONDECODE" );
                  hb_dynsymUnlock();
                  if ( s_pSym_SR_FROMJSON  == NULL ) printf( "Could not find Symbol HB_JSONDECODE\n" );            
               }
               hb_vmPushSymbol( s_pSym_SR_FROMJSON->pSymbol );
               hb_vmPushNil();
               hb_vmPushString( bBuffer, lLenBuff );
               pTemp = hb_itemNew( NULL );
               hb_vmPush(pTemp);
               hb_vmDo( 2 );
               hb_itemForwardValue( pItem, pTemp );              
               hb_itemRelease( pTemp );

            }

            else if( lLenBuff > 10 && strncmp( bBuffer, SQL_SERIALIZED_SIGNATURE, 10 ) == 0 && (!sr_lSerializedAsString()) )
            {
               if( s_pSym_SR_DESERIALIZE == NULL )
               {
                  hb_dynsymLock();
                  s_pSym_SR_DESERIALIZE = hb_dynsymFindName( "SR_DESERIALIZE" );
                  hb_dynsymUnlock();
                  if ( s_pSym_SR_DESERIALIZE  == NULL ) printf( "Could not find Symbol SR_DESERIALIZE\n" );
               }
               hb_vmPushSymbol( s_pSym_SR_DESERIALIZE->pSymbol );
               hb_vmPushNil();
               hb_vmPushString( bBuffer, lLenBuff );
               hb_vmDo( 1 );

               pTemp = hb_itemNew( NULL );
               hb_itemForwardValue( pTemp, hb_stackReturnItem() );

               if( HB_IS_HASH( pTemp ) && sr_isMultilang() && bTranslate )
               {
                  ULONG ulPos;
                  if( hb_hashScan( pTemp, sr_getCurrentLang(), &ulPos ) ||
                      hb_hashScan( pTemp, sr_getSecondLang(), &ulPos ) ||
                      hb_hashScan( pTemp, sr_getRootLang(), &ulPos ) )
                  {
                     hb_itemCopy( pItem, hb_hashGetValueAt( pTemp, ulPos ) );
                  }
               }
               else
               {
                  hb_itemForwardValue( pItem, pTemp );
               }
               hb_itemRelease( pTemp );
            }

            else
            {
               hb_itemPutCL( pItem, bBuffer, (ULONG) lLenBuff );
            }
            break;
         }
         case SQL_BIT:
         case SQL_SMALLINT:
         {
            hb_itemPutL( pItem, hb_strVal( bBuffer, lLenBuff ) > 0  ? TRUE : FALSE );
//            hb_itemPutL( pItem, bBuffer[0] == '1' ? TRUE : FALSE );
//            hb_itemPutL( pItem, hb_strValInt( bBuffer, &iOverflow ) > 0  ? TRUE : FALSE );
            break;
         }

#ifdef SQLRDD_TOPCONN
         case SQL_FAKE_DATE:
         {
            hb_itemPutDS( pItem, bBuffer );
            break;
         }
#endif
         default:
            TraceLog( LOGFILE, "Invalid data type detected: %i\n", lType );
      }
   }
}

/*------------------------------------------------------------------------*/

HB_FUNC( FBLINEPROCESSED )
{
   PFB_SESSION session  = ( PFB_SESSION ) hb_itemGetPtr( hb_param( 1, HB_IT_POINTER ) );
   int icol, cols;
   int dtype, i;
   char data[MSG_BUFFER_LEN], *p;
   char date_s[30];
   struct tm times;
   ISC_QUAD * blob_id;
   isc_blob_handle blob_handle = NULL;
   short blob_seg_len;
   char * resp, item, * read_blob;
   char blob_items[] = { isc_info_blob_total_length, isc_info_blob_num_segments };
   char res_buffer[20];
   LONG blob_size = 0L, num_segments = 0L, count, residual_size;
   short length;
   BOOL bEnd = 0;
   XSQLVAR * var;
   VARY * vary;

   PHB_ITEM temp;
   PHB_ITEM pFields = hb_param( 3, HB_IT_ARRAY );
   BOOL  bQueryOnly = hb_parl( 4 );
   ULONG ulSystemID = hb_parnl( 5 );
   BOOL  bTranslate = hb_parl( 6 );
   PHB_ITEM pRet    = hb_param( 7, HB_IT_ARRAY );
   LONG lIndex;

   if( session )
   {
      cols = pFields->item.asArray.value->ulLen;

      for( icol = 1; icol <= cols; icol++ )
      {
         temp = hb_itemNew( NULL );
         var = session->sqlda->sqlvar;
         lIndex  = hb_arrayGetNL( hb_arrayGetItemPtr( pFields, icol ), FIELD_ENUM );

         if( lIndex == 0 )
         {
            hb_arraySetForward( pRet, icol, temp );
         }
         else
         {
            for ( i = 0; i < lIndex-1; i++, var++ ){}

            if( ( var->sqltype & 1 ) && ( *var->sqlind < 0 ) )
            {
               FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) "", 0, bQueryOnly, ulSystemID, bTranslate );
               hb_arraySetForward( pRet, icol , temp );
            }
            else
            {
               dtype = ( ( (XSQLVAR *) var )->sqltype & ~1 );
               switch ( dtype )
               {
               case IB_SQL_TEXT:
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) var->sqldata, var->sqllen, bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;
               case IB_SQL_VARYING:
                  vary = (VARY*) var->sqldata;
                  vary->vary_string[vary->vary_length] = '\0';
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) vary->vary_string, strlen( vary->vary_string ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;
               case IB_SQL_TIMESTAMP:
                  isc_decode_timestamp( ( ISC_TIMESTAMP ISC_FAR * ) var->sqldata, &times );
                  sprintf ( date_s, "%04d-%02d-%02d %02d:%02d:%02d.%04lu",
                        times.tm_year + 1900,
                        times.tm_mon + 1,
                        times.tm_mday,
                        times.tm_hour,
                        times.tm_min,
                        times.tm_sec,
                        ( ( ISC_TIMESTAMP * ) var->sqldata )->timestamp_time % 10000 );

      //            sprintf ( p, "%*s ", 24, date_s );

                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) date_s, strlen( date_s ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               case IB_SQL_TYPE_TIME:
                  isc_decode_sql_time( ( ISC_TIME ISC_FAR * ) var->sqldata, &times );
                  sprintf ( date_s, "%02d:%02d:%02d.%04lu",
                        times.tm_hour,
                        times.tm_min,
                        times.tm_sec, ( *( ( ISC_TIME * ) var->sqldata ) ) % 10000 );

                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) date_s, strlen( date_s ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               case IB_SQL_LONG:
               case IB_SQL_INT64:
               case IB_SQL_SHORT:
                  p = data;
                  {
                     ISC_INT64  value;
                     short field_width, dscale;
                     switch (dtype)
                     {
                     case IB_SQL_SHORT:
                        value = (ISC_INT64) *(short ISC_FAR *) var->sqldata;
                        field_width = 6;
                        break;

                     case IB_SQL_LONG:
                        value = (ISC_INT64) *(long ISC_FAR *) var->sqldata;
                        field_width = 11;
                        break;

                     case IB_SQL_INT64:
                        value = (ISC_INT64) *(ISC_INT64 ISC_FAR *) var->sqldata;
                        field_width = 21;
                        break;
                     }

                     dscale = var->sqlscale;

                     if (dscale < 0)
                     {
                        ISC_INT64 tens;
                        short i;
                        tens = 1;
                        for (i = 0; i > dscale; i--)
                        {
                           tens *= 10;
                        }

                        if (value >= 0)
                        {
                           sprintf( p, "%*" ISC_INT64_FORMAT "d.%0*" ISC_INT64_FORMAT "d",
                                    field_width - 1 + dscale,
                                    (ISC_INT64) value / tens,
                                    -dscale,
                                    (ISC_INT64) value % tens );
                        }
                        else if ((value / tens) != 0)
                        {
                           sprintf( p, "%*" ISC_INT64_FORMAT "d.%0*" ISC_INT64_FORMAT "d",
                                    field_width - 1 + dscale,
                                    (ISC_INT64) (value / tens),
                                    -dscale,
                                    (ISC_INT64) -(value % tens));
                        }
                        else
                        {
                           sprintf( p, "%*s.%0*" ISC_INT64_FORMAT "d",
                                    field_width - 1 + dscale,
                                    "-0",
                                    -dscale,
                                    (ISC_INT64) -(value % tens));
                        }
                     }
                     else if (dscale)
                     {
                        sprintf( p, "%*" ISC_INT64_FORMAT "d%0*d", field_width, (ISC_INT64) value, dscale, 0);
                     }
                     else
                     {
                        sprintf(p, "%*" ISC_INT64_FORMAT "d", field_width, (ISC_INT64) value);
                     }
                  };
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) p, strlen( p ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               case IB_SQL_FLOAT:
                  p = data;
                  sprintf( p, "%15g ", *(float ISC_FAR *) (var->sqldata));
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) p, strlen( p ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               case IB_SQL_DOUBLE:
                  p = data;
                  sprintf( p, "%24f ", *(double ISC_FAR *) (var->sqldata));
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) p, strlen( p ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               case IB_SQL_BLOB:
               case IB_SQL_ARRAY:
               case IB_SQL_QUAD:
                  blob_id = ( ISC_QUAD * ) var->sqldata;
                  if ( isc_open_blob2( session->status, &(session->db), &(session->transac), &blob_handle, blob_id, 0, NULL))
                  {
                     ERRORLOGANDEXIT( session, "FBGETDATA1" );
                  }
                  if ( isc_blob_info( session->status, &blob_handle, sizeof(blob_items), blob_items, sizeof(res_buffer), res_buffer ) )
                  {
                     ERRORLOGANDEXIT( session, "FBGETDATA2" );
                  }
                  for ( resp = res_buffer; * resp != isc_info_end ;)
                  {
                     item = *resp++;
                     length = (short)isc_vax_integer( resp, 2 );
                     resp += 2;
                     switch (item)
                     {
                     case isc_info_blob_total_length:
                        blob_size = isc_vax_integer( resp, length );
                        break;
                     case isc_info_blob_num_segments:
                        num_segments = isc_vax_integer( resp, length );
                        break;
                     case isc_info_truncated:
                        bEnd = 1;
                        break;
                     default:
                        break;
                     }
                     if (bEnd)
                     {
                        break;
                     }
                     resp += length;
                  };
                  read_blob = (char *) hb_xgrab( blob_size + 1 );
                  read_blob[blob_size] = '\0';
                  p = read_blob;
                  residual_size = blob_size;

                  for ( count=0; count <= num_segments; count++ )
                  {
                     if (isc_get_segment( session->status, &blob_handle, (unsigned short ISC_FAR *) &blob_seg_len, (unsigned short) residual_size, p ) != isc_segstr_eof)
                     {
                        p += blob_seg_len;
                        residual_size -= blob_seg_len;
                     }
                  }

                  if ( isc_close_blob( session->status, &blob_handle ) )
                  {
                     ERRORLOGANDEXIT( session, "FBGETDATA3" );
                  }

                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) read_blob, blob_size, bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );

                  hb_storclenAdopt( read_blob, blob_size, 3 );
                  hb_xfree( read_blob );
                  break;

               case IB_SQL_TYPE_DATE:
                  isc_decode_sql_date ( ( ISC_DATE ISC_FAR * ) var->sqldata, &times );
                  sprintf( date_s, "%04d-%02d-%02d", times.tm_year + 1900, times.tm_mon + 1, times.tm_mday );
                  p = data;
                  sprintf( p, "%*s ", 8, date_s );
                  FBFieldGet( hb_arrayGetItemPtr( pFields, icol ), temp, (char * ) p, strlen( p ), bQueryOnly, ulSystemID, bTranslate );
                  hb_arraySetForward( pRet, icol , temp );
                  break;

               default:
                  TraceLog( LOGFILE, "Unsupported data type returned in query: %i\n", dtype );
                  break;
               }
            }
         }
         hb_itemRelease( temp );
      }
      hb_retni( SQL_SUCCESS );
   }
}

/*------------------------------------------------------------------------*/
