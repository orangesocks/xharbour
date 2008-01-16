/*
 * $Id: alt.c,v 1.3 2006/04/07 09:47:19 lculik Exp $
 */

/*
 * File......: ALT.C
 * Author....: Ted Means
 * CIS ID....: 73067,3332
 *
 * This function is an original work by Ted Means and is placed in the
 * public domain.
 *
 * Modification history:
 * ---------------------
 *
 *    Rev 1.5   16 Apr 2000 17:30:00   Luiz Rafael Culik
 * Ported to Harbour
 *
 *    Rev 1.4   15 Jul 1993 23:48:00   GLENN
 * Dropped _MK_FP for preferred 0x00400017
 *
 *    Rev 1.3   13 Jul 1993 22:28:58   GLENN
 * Added call to _MK_FP in order to be compatible in protected mode.
 *
 *    Rev 1.2   15 Aug 1991 23:08:34   GLENN
 * Forest Belt proofread/edited/cleaned up doc
 *
 *    Rev 1.1   14 Jun 1991 19:53:36   GLENN
 * Minor edit to file header
 *
 *    Rev 1.0   01 Apr 1991 01:02:42   GLENN
 * Nanforum Toolkit
 *
 *
 */


/*  $DOC$
 *  $FUNCNAME$
 *     FT_ALT()
 *  $CATEGORY$
 *     Keyboard/Mouse
 *  $ONELINER$
 *     Determine status of the Alt key
 *  $SYNTAX$
 *     FT_ALT() -> lValue
 *  $ARGUMENTS$
 *     None
 *  $RETURNS$
 *     .T. if Alt key is pressed, .F. if otherwise.
 *  $DESCRIPTION$
 *     This function is useful for times you need to know whether or not the
 *     Alt key is pressed, such as during a MemoEdit().
 *  $EXAMPLES$
 *     IF FT_ALT()
 *        @24, 0 say "Alt"
 *     ELSE
 *        @24, 0 say "   "
 *     ENDIF
 *  $SEEALSO$
 *     FT_CAPLOCK() FT_CTRL() FT_NUMLOCK() FT_PRTSCR() FT_SHIFT()
 *  $END$
 */

#include <hbapi.h>
#include <hbapigt.h>

HB_FUNC(FT_ALT)
{
#if defined(HB_OS_DOS)
   {
      hb_retl( ( int ) ( ( *( char * ) 0x00400017 ) & 0x8 ) );

      return;
   }
#else

   hb_retl( hb_gt_info( GTI_KBDSHIFTS, FALSE, 0, NULL) & GTI_KBD_ALT );

#endif
}
