
#define _WIN32_WINNT   0x0400

#include <shlobj.h>
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h> 
#include <htmlhelp.h> 
#include <mapi.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"
#include "winreg.h"
#include "tchar.h"



//컴컴컴컴컴컴컴컴컴컴컴컴�\\
//
// MapiSendMail( 0,                      ;   // hWnd
//               'This is Subject',      ;   // cSubject
//		 			  'And this is text',     ;   // cText
//					  'Pritpal Bedi',         ;   // Sender's Name
//					  'vouchcac@hotmail.com', ;   // Sender's Address
//					  'Pritpal',              ;   // Recipient's Name
//					  'info@vouchcac.com',    ;   // Recipient's Address
//					  'c:\autoexec.bat'       )   // File attached
//
//컴컴컴컴컴컴컴컴컴컴컴컴�\\

HB_FUNC ( MAPISENDMAIL )
{
	MapiRecipDesc orig ;
	MapiRecipDesc rcpt ;
	MapiFileDesc  file ;
	MapiMessage   mssg ;
	
	orig.ulReserved         = NULL         ;  // Reserved
	orig.ulRecipClass       = MAPI_ORIG    ;  // Reciepient Class MAPI_TO MAPI_CC MAPI_BCC
	orig.lpszName           = hb_parc( 4 ) ;  // Originator's Name
	orig.lpszAddress        = hb_parc( 5 ) ;  // Originators Address
	orig.ulEIDSize          = NULL         ;  // Count in bytes of size of pEntryID
	orig.lpEntryID          = NULL         ;  // System-specific Originator reference

	rcpt.ulReserved         = NULL         ;  // Reserved
	rcpt.ulRecipClass       = MAPI_TO      ;  // Reciepient Class MAPI_TO MAPI_CC MAPI_BCC
	rcpt.lpszName           = hb_parc( 6 ) ;  // Reciepient's Name, e.g., vouchcac@hotmail.com
	rcpt.lpszAddress        = hb_parc( 7 ) ;  // Reciepient's Address
	rcpt.ulEIDSize          = NULL         ;  // Count in bytes of size of pEntryID
	rcpt.lpEntryID          = NULL         ;  // System-specific Recipient reference

	file.ulReserved         = NULL         ;  // Reserved for future usage
	file.flFlags            = NULL         ;  // Flags ?
	file.nPosition          = -1           ;  // Character of text to be replaced by attachment
	file.lpszPathName       = hb_parc( 8 ) ;  // Full Path Name with Extension of the attached file 
	file.lpszFileName       = NULL         ;  // Original File Name ( optional )
	file.lpFileType         = NULL         ;  // Attachment file type ( can be lpMapiFileTagExt )
	
	mssg.ulReserved         = NULL         ;  // Reserved
	mssg.lpszSubject        = hb_parc( 2 ) ;  // Message Subject
	mssg.lpszNoteText       = hb_parc( 3 ) ;  // Message Text
	mssg.lpszMessageType    = NULL         ;  // Message Class
	mssg.lpszDateReceived   = NULL         ;  // in yyyy/mm/dd hh:mm format
	mssg.lpszConversationID = NULL         ;  // Conversation thread ID
	mssg.flFlags            = NULL         ;  // unread, return receipt
	mssg.lpOriginator       = &orig        ;  // Originator's descriptor
	mssg.nRecipCount        = 1            ;  // Number of receipients
	mssg.lpRecips           = &rcpt        ;  // Recipient descriptors
	mssg.nFileCount         = 1            ;  // Number of file attachments
	mssg.lpFiles            = &file        ;  // Attachment descriptors
	
	// to send the mail direcly and without intervenstion
	hb_retnl( (ULONG) MAPISendMail( 0, 0, &mssg, 0, 0 ) ) ;
	
	// to opem default mail client's dialog box
	// hb_retnl( (ULONG) MAPISendMail( 0, 0, &mssg, 8, 0 ) ) ;
}
