
// What32.Lib
// Clipboard functions

#define HB_OS_WIN_32_USED
#define _WIN32_WINNT   0x0400

#include <shlobj.h>
#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"

//-------------------------------------------------------------------------------

HB_FUNC( CLOSECLIPBOARD )
{
   hb_retl( CloseClipboard() );
}
//-------------------------------------------------------------------------------

HB_FUNC( COUNTCLIPBOARDFORMATS )
{
   hb_retni( CountClipboardFormats() ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( EMPTYCLIPBOARD )
{
   hb_retl( EmptyClipboard() ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( ENUMCLIPBOARDFORMATS )
{
   hb_retni( EnumClipboardFormats( (UINT) hb_parni(1) ) );
}


//-------------------------------------------------------------------------------

HB_FUNC( SETCLIPBOARDVIEWER )
{
   hb_retnl( (ULONG) SetClipboardViewer( (HWND) hb_parnl(1) ) );
}


//-----------------------------------------------------------------------------
// WINUSERAPI BOOL WINAPI ChangeClipboardChain( IN HWND hWndRemove, IN HWND hWndNewNext);


HB_FUNC( CHANGECLIPBOARDCHAIN )
{
   hb_retl( ChangeClipboardChain( (HWND) hb_parnl( 1 ), (HWND) hb_parnl( 2 ) ) ) ;
}


//-----------------------------------------------------------------------------
// WINUSERAPI HWND WINAPI GetOpenClipboardWindow( VOID);


HB_FUNC( GETOPENCLIPBOARDWINDOW )
{
   hb_retnl( (LONG) GetOpenClipboardWindow(  ) ) ;
}


//-----------------------------------------------------------------------------
// WINUSERAPI int WINAPI GetPriorityClipboardFormat( OUT UINT *paFormatPriorityList, IN int cFormats);

HB_FUNC( GETPRIORITYCLIPBOARDFORMAT )
{
   UINT *p, *paFP ;
   UINT i;

   p = paFP = (PUINT) hb_xgrab( hb_parinfa( 1, 0 ) * sizeof(UINT)  );
   for ( i=1; i<=hb_parinfa( 1, 0 ); i++ )
   {
     *p++ = hb_parni( 1, i ) ;
   }
   hb_retni( GetPriorityClipboardFormat( (UINT *) paFP, hb_parinfa( 1, 0 ) ) ) ;

}

//-----------------------------------------------------------------------------
// WINUSERAPI DWORD WINAPI GetClipboardSequenceNumber( VOID);

#if(WINVER >= 0x0500)

HB_FUNC( GETCLIPBOARDSEQUENCENUMBER )
{
   hb_retnl( (LONG) GetClipboardSequenceNumber(  ) ) ;
}

#endif

//-------------------------------------------------------------------------------

HB_FUNC( GETCLIPBOARDOWNER )
{
   hb_retnl( (ULONG) GetClipboardOwner() ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( GETCLIPBOARDVIEWER )
{
   hb_retnl( (ULONG) GetClipboardViewer() ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( ISCLIPBOARDFORMATAVAILABLE )
{
   hb_retl( IsClipboardFormatAvailable( hb_parni(1) ) );
}

//-------------------------------------------------------------------------------

HB_FUNC( OPENCLIPBOARD )
{
   hb_retl( OpenClipboard( (HWND) hb_parnl(1) ) ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( REGISTERCLIPBOARDFORMAT )
{
   hb_retni( RegisterClipboardFormat( (LPCSTR) hb_parc(1) ) ) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( GETCLIPBOARDDATA )
{
   HANDLE hClipMem ;
   LPSTR  lpClip ;

   hClipMem = GetClipboardData( (UINT) hb_parni(1) );

   if( hClipMem )
    {
      lpClip = GlobalLock(hClipMem) ;
      hb_retclen( lpClip , GlobalSize(hClipMem) ) ;
      GlobalUnlock( hClipMem ) ;
    }
}

//-------------------------------------------------------------------------------

HB_FUNC( GETCLIPBOARDFORMATNAME )
{
   int nRet ;
   char cName[128] ;
   int cchMaxCount ;

   nRet = GetClipboardFormatName( (UINT) hb_parni(1), cName, 127 ) ;

   if ( nRet == 0 )
      hb_retc("") ;
   else
      hb_retclen(cName, nRet) ;
}

//-------------------------------------------------------------------------------

HB_FUNC( SETCLIPBOARDDATA )
{
   HANDLE hMem ;
   void far *pMem ;
   DWORD dwLen ;

   if ( hb_pcount() > 1 )
   {
      dwLen = (DWORD) hb_parclen(2) + ( hb_parni(1) == CF_TEXT ? 1 : 0 ) ;
      hMem = GlobalAlloc( ( GMEM_MOVEABLE | GMEM_DDESHARE) , dwLen ) ;
      if (  hMem )
      {
          pMem = GlobalLock( hMem) ;
          memcpy(pMem, hb_parc(2), dwLen ) ;
          GlobalUnlock( hMem ) ;
          hb_retnl( (ULONG) SetClipboardData( (UINT) hb_parni(1), hMem ) ) ;
      }
      else
         hb_retnl(0);
   }
}

