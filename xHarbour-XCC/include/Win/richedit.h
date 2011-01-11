#ifndef _RICHEDIT_H
#define _RICHEDIT_H

/* Windows RichEdit control definitions */

#include <pshpack4.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _RICHEDIT_VER
#define _RICHEDIT_VER  0x0300
/* Version 1.0 = 0x0100 */
/* Version 2.0 = 0x0200 */
/* Version 2.1 = 0x0210 */
#endif

#define cchTextLimitDefault  32767

#define CERICHEDIT_CLASSA  "RichEditCEA"
#define CERICHEDIT_CLASSW  L"RichEditCEW"
#define RICHEDIT_CLASSA  "RichEdit20A"
#define RICHEDIT_CLASS10A  "RICHEDIT"
#define RICHEDIT_CLASSW  L"RichEdit20W"

#define CF_RTF  TEXT("Rich Text Format")
#define CF_RTFNOOBJS  TEXT("Rich Text Format Without Objects")
#define CF_RETEXTOBJ  TEXT("RichEdit Text and Objects")

#ifndef WM_CONTEXTMENU
#define WM_CONTEXTMENU  0x007B
#endif
#ifndef WM_PRINTCLIENT
#define WM_PRINTCLIENT  0x0318
#endif

#ifndef WM_NOTIFY
#define WM_NOTIFY  0x004E
typedef struct _nmhdr {
    HWND hwndFrom;
    UINT_PTR idFrom;
    UINT code;
} NMHDR;
#endif /* WM_NOTIFY */

#ifndef EM_GETLIMITTEXT
#define EM_GETLIMITTEXT  (WM_USER+37)
#endif
#ifndef EM_POSFROMCHAR
#define EM_POSFROMCHAR  (WM_USER+38)
#define EM_CHARFROMPOS  (WM_USER+39)
#endif
#ifndef EM_SCROLLCARET
#define EM_SCROLLCARET  (WM_USER+49)
#endif
#define EM_CANPASTE  (WM_USER+50)
#define EM_DISPLAYBAND  (WM_USER+51)
#define EM_EXGETSEL  (WM_USER+52)
#define EM_EXLIMITTEXT  (WM_USER+53)
#define EM_EXLINEFROMCHAR  (WM_USER+54)
#define EM_EXSETSEL  (WM_USER+55)
#define EM_FINDTEXT  (WM_USER+56)
#define EM_FORMATRANGE  (WM_USER+57)
#define EM_GETCHARFORMAT  (WM_USER+58)
#define EM_GETEVENTMASK  (WM_USER+59)
#define EM_GETOLEINTERFACE  (WM_USER+60)
#define EM_GETPARAFORMAT  (WM_USER+61)
#define EM_GETSELTEXT  (WM_USER+62)
#define EM_HIDESELECTION  (WM_USER+63)
#define EM_PASTESPECIAL  (WM_USER+64)
#define EM_REQUESTRESIZE  (WM_USER+65)
#define EM_SELECTIONTYPE  (WM_USER+66)
#define EM_SETBKGNDCOLOR  (WM_USER+67)
#define EM_SETCHARFORMAT  (WM_USER+68)
#define EM_SETEVENTMASK  (WM_USER+69)
#define EM_SETOLECALLBACK  (WM_USER+70)
#define EM_SETPARAFORMAT  (WM_USER+71)
#define EM_SETTARGETDEVICE  (WM_USER+72)
#define EM_STREAMIN  (WM_USER+73)
#define EM_STREAMOUT  (WM_USER+74)
#define EM_GETTEXTRANGE  (WM_USER+75)
#define EM_FINDWORDBREAK  (WM_USER+76)
#define EM_SETOPTIONS  (WM_USER+77)
#define EM_GETOPTIONS  (WM_USER+78)
#define EM_FINDTEXTEX  (WM_USER+79)
#define EM_GETWORDBREAKPROCEX  (WM_USER+80)
#define EM_SETWORDBREAKPROCEX  (WM_USER+81)
#define EM_SETUNDOLIMIT  (WM_USER+82)
#define EM_REDO  (WM_USER+84)
#define EM_CANREDO  (WM_USER+85)
#define EM_GETUNDONAME  (WM_USER+86)
#define EM_GETREDONAME  (WM_USER+87)
#define EM_STOPGROUPTYPING  (WM_USER+88)
#define EM_SETTEXTMODE  (WM_USER+89)
#define EM_GETTEXTMODE  (WM_USER+90)
#define EM_AUTOURLDETECT  (WM_USER+91)
#define EM_GETAUTOURLDETECT  (WM_USER+92)
#define EM_SETPALETTE  (WM_USER+93)
#define EM_GETTEXTEX  (WM_USER+94)
#define EM_GETTEXTLENGTHEX  (WM_USER+95)
#define EM_SHOWSCROLLBAR  (WM_USER+96)
#define EM_SETTEXTEX  (WM_USER+97)
#define EM_SETPUNCTUATION  (WM_USER+100)
#define EM_GETPUNCTUATION  (WM_USER+101)
#define EM_SETWORDWRAPMODE  (WM_USER+102)
#define EM_GETWORDWRAPMODE  (WM_USER+103)
#define EM_SETIMECOLOR  (WM_USER+104)
#define EM_GETIMECOLOR  (WM_USER+105)
#define EM_SETIMEOPTIONS  (WM_USER+106)
#define EM_GETIMEOPTIONS  (WM_USER+107)
#define EM_CONVPOSITION  (WM_USER+108)
#define EM_SETLANGOPTIONS  (WM_USER+120)
#define EM_GETLANGOPTIONS  (WM_USER+121)
#define EM_GETIMECOMPMODE  (WM_USER+122)
#define EM_FINDTEXTW  (WM_USER+123)
#define EM_FINDTEXTEXW  (WM_USER+124)
#define EM_RECONVERSION  (WM_USER+125)
#define EM_SETIMEMODEBIAS  (WM_USER+126)
#define EM_GETIMEMODEBIAS  (WM_USER+127)
#define EM_SETBIDIOPTIONS  (WM_USER+200)
#define EM_GETBIDIOPTIONS  (WM_USER+201)
#define EM_SETTYPOGRAPHYOPTIONS  (WM_USER+202)
#define EM_GETTYPOGRAPHYOPTIONS  (WM_USER+203)
#define EM_SETEDITSTYLE  (WM_USER+204)
#define EM_GETEDITSTYLE  (WM_USER+205)
#define EM_OUTLINE  (WM_USER+220)
#define EM_GETSCROLLPOS  (WM_USER+221)
#define EM_SETSCROLLPOS  (WM_USER+222)
#define EM_SETFONTSIZE  (WM_USER+223)
#define EM_GETZOOM  (WM_USER+224)
#define EM_SETZOOM  (WM_USER+225)

#define SES_EMULATESYSEDIT  1
#define SES_BEEPONMAXTEXT  2
#define SES_EXTENDBACKCOLOR  4
#define SES_MAPCPS  8
#define SES_EMULATE10  16
#define SES_USECRLF  32
#define SES_USEAIMM  64
#define SES_NOIME  128
#define SES_ALLOWBEEPS  256
#define SES_UPPERCASE  512
#define SES_LOWERCASE  1024
#define SES_NOINPUTSEQUENCECHK  2048
#define SES_BIDI  4096
#define SES_SCROLLONKILLFOCUS  8192
#define SES_XLTCRCRLFTOCR  16384

#define IMF_AUTOKEYBOARD  0x0001
#define IMF_AUTOFONT  0x0002
#define IMF_IMECANCELCOMPLETE  0x0004
#define IMF_IMEALWAYSSENDNOTIFY  0x0008
#define IMF_AUTOFONTSIZEADJUST  0x0010
#define IMF_UIFONTS  0x0020
#define IMF_DUALFONT  0x0080

#define ICM_NOTOPEN  0x0000
#define ICM_LEVEL3  0x0001
#define ICM_LEVEL2  0x0002
#define ICM_LEVEL2_5  0x0003
#define ICM_LEVEL2_SUI  0x0004

#define TO_ADVANCEDTYPOGRAPHY  1
#define TO_SIMPLELINEBREAK  2

#define EMO_EXIT  0
#define EMO_ENTER  1
#define EMO_PROMOTE  2
#define EMO_EXPAND  3
#define EMO_MOVESELECTION  4
#define EMO_GETVIEWMODE  5

#define EMO_EXPANDSELECTION  0
#define EMO_EXPANDDOCUMENT  1

#define VM_NORMAL  4
#define VM_OUTLINE  2

#define EN_MSGFILTER  0x0700
#define EN_REQUESTRESIZE  0x0701
#define EN_SELCHANGE  0x0702
#define EN_DROPFILES  0x0703
#define EN_PROTECTED  0x0704
#define EN_CORRECTTEXT  0x0705
#define EN_STOPNOUNDO  0x0706
#define EN_IMECHANGE  0x0707
#define EN_SAVECLIPBOARD  0x0708
#define EN_OLEOPFAILED  0x0709
#define EN_OBJECTPOSITIONS  0x070A
#define EN_LINK  0x070B
#define EN_DRAGDROPDONE  0x070C
#define EN_PARAGRAPHEXPANDED  0x070D
#define EN_ALIGNLTR  0x0710
#define EN_ALIGNRTL  0x0711

#define ENM_NONE  0x00000000
#define ENM_CHANGE  0x00000001
#define ENM_UPDATE  0x00000002
#define ENM_SCROLL  0x00000004
#define ENM_KEYEVENTS  0x00010000
#define ENM_MOUSEEVENTS  0x00020000
#define ENM_REQUESTRESIZE  0x00040000
#define ENM_SELCHANGE  0x00080000
#define ENM_DROPFILES  0x00100000
#define ENM_PROTECTED  0x00200000
#define ENM_CORRECTTEXT  0x00400000
#define ENM_SCROLLEVENTS  0x00000008
#define ENM_DRAGDROPDONE  0x00000010
#define ENM_PARAGRAPHEXPANDED  0x00000020

#define ENM_IMECHANGE  0x00800000
#define ENM_LANGCHANGE  0x01000000
#define ENM_OBJECTPOSITIONS  0x02000000
#define ENM_LINK  0x04000000

#define ES_NOOLEDRAGDROP  0x00000008
#define ES_DISABLENOSCROLL  0x00002000
#define ES_SUNKEN  0x00004000
#define ES_SAVESEL  0x00008000
#define ES_SELFIME  0x00040000
#define ES_VERTICAL  0x00400000
#define ES_NOIME  0x00080000
#define ES_SELECTIONBAR  0x01000000

#if (_WIN32_WINNT > 0x0400) || (WINVER > 0x0400)
#define ES_EX_NOCALLOLEINIT  0x00000000
#else
#define ES_EX_NOCALLOLEINIT  0x01000000
#endif

#define ECO_AUTOWORDSELECTION  0x00000001
#define ECO_AUTOVSCROLL  0x00000040
#define ECO_AUTOHSCROLL  0x00000080
#define ECO_NOHIDESEL  0x00000100
#define ECO_READONLY  0x00000800
#define ECO_WANTRETURN  0x00001000
#define ECO_SAVESEL  0x00008000
#define ECO_SELECTIONBAR  0x01000000
#define ECO_VERTICAL  0x00400000

#define ECOOP_SET  0x0001
#define ECOOP_OR  0x0002
#define ECOOP_AND  0x0003
#define ECOOP_XOR  0x0004

#define WB_CLASSIFY  3
#define WB_MOVEWORDLEFT  4
#define WB_MOVEWORDRIGHT  5
#define WB_LEFTBREAK  6
#define WB_RIGHTBREAK  7

#define WB_MOVEWORDPREV  4
#define WB_MOVEWORDNEXT  5
#define WB_PREVBREAK  6
#define WB_NEXTBREAK  7

#define PC_FOLLOWING  1
#define PC_LEADING  2
#define PC_OVERFLOW  3
#define PC_DELIMITER  4

#define WBF_WORDWRAP  0x010
#define WBF_WORDBREAK  0x020
#define WBF_OVERFLOW  0x040
#define WBF_LEVEL1  0x080
#define WBF_LEVEL2  0x100
#define WBF_CUSTOM  0x200

#define IMF_FORCENONE  0x0001
#define IMF_FORCEENABLE  0x0002
#define IMF_FORCEDISABLE  0x0004
#define IMF_CLOSESTATUSWINDOW  0x0008
#define IMF_VERTICAL  0x0020
#define IMF_FORCEACTIVE  0x0040
#define IMF_FORCEINACTIVE  0x0080
#define IMF_FORCEREMEMBER  0x0100
#define IMF_MULTIPLEEDIT  0x0400

#define WBF_CLASS  ((BYTE)0x0F)
#define WBF_ISWHITE  ((BYTE)0x10)
#define WBF_BREAKLINE  ((BYTE)0x20)
#define WBF_BREAKAFTER  ((BYTE)0x40)

#define CFM_BOLD  0x00000001
#define CFM_ITALIC  0x00000002
#define CFM_UNDERLINE  0x00000004
#define CFM_STRIKEOUT  0x00000008
#define CFM_PROTECTED  0x00000010
#define CFM_LINK  0x00000020
#define CFM_SIZE  0x80000000
#define CFM_COLOR  0x40000000
#define CFM_FACE  0x20000000
#define CFM_OFFSET  0x10000000
#define CFM_CHARSET  0x08000000

#define CFE_BOLD  0x0001
#define CFE_ITALIC  0x0002
#define CFE_UNDERLINE  0x0004
#define CFE_STRIKEOUT  0x0008
#define CFE_PROTECTED  0x0010
#define CFE_LINK  0x0020
#define CFE_AUTOCOLOR  0x40000000

#define yHeightCharPtsMost  1638

#define SCF_SELECTION  0x0001
#define SCF_WORD  0x0002
#define SCF_DEFAULT  0x0000
#define SCF_ALL  0x0004
#define SCF_USEUIRULES  0x0008
#define SCF_ASSOCIATEFONT  0x0010
#define SCF_NOKBUPDATE  0x0020

#define SF_TEXT  0x0001
#define SF_RTF  0x0002
#define SF_RTFNOOBJS  0x0003
#define SF_TEXTIZED  0x0004
#define SF_UNICODE  0x0010
#define SF_USECODEPAGE  0x0020
#define SF_NCRFORNONASCII  0x0040

#define SFF_SELECTION  0x8000
#define SFF_PLAINRTF  0x4000
#define SFF_PERSISTVIEWSCALE  0x2000
#define SFF_KEEPDOCINFO  0x1000
#define SFF_PWD  0x0800
#define SF_RTFVAL  0x0700

#define MAX_TAB_STOPS  32
#define lDefaultTab  720

#define wReserved  wEffects

#define PFM_STARTINDENT  0x00000001
#define PFM_RIGHTINDENT  0x00000002
#define PFM_OFFSET  0x00000004
#define PFM_ALIGNMENT  0x00000008
#define PFM_TABSTOPS  0x00000010
#define PFM_NUMBERING  0x00000020
#define PFM_OFFSETINDENT  0x80000000

#define PFN_BULLET  0x0001

#define PFA_LEFT  0x0001
#define PFA_RIGHT  0x0002
#define PFA_CENTER  0x0003

#define CHARFORMATDELTA  (sizeof(CHARFORMAT2) - sizeof(CHARFORMAT))

#define CFM_SMALLCAPS  0x0040
#define CFM_ALLCAPS  0x0080
#define CFM_HIDDEN  0x0100
#define CFM_OUTLINE  0x0200
#define CFM_SHADOW  0x0400
#define CFM_EMBOSS  0x0800
#define CFM_IMPRINT  0x1000
#define CFM_DISABLED  0x2000
#define CFM_REVISED  0x4000
#define CFM_REVAUTHOR  0x00008000
#define CFM_ANIMATION  0x00040000
#define CFM_KERNING  0x00100000
#define CFM_SPACING  0x00200000
#define CFM_WEIGHT  0x00400000
#define CFM_STYLE  0x00080000
#define CFM_LCID  0x02000000
#define CFM_BACKCOLOR  0x04000000
#define CFM_UNDERLINETYPE  0x00800000
#define CFM_SUBSCRIPT  (CFE_SUBSCRIPT|CFE_SUPERSCRIPT)
#define CFM_SUPERSCRIPT  CFM_SUBSCRIPT

#define CFM_EFFECTS  (CFM_BOLD|CFM_ITALIC|CFM_UNDERLINE|CFM_COLOR|CFM_STRIKEOUT|CFE_PROTECTED|CFM_LINK)
#define CFM_EFFECTS2  (CFM_EFFECTS|CFM_DISABLED|CFM_SMALLCAPS|CFM_ALLCAPS|CFM_HIDDEN|CFM_OUTLINE|CFM_SHADOW|CFM_EMBOSS|CFM_IMPRINT|CFM_DISABLED|CFM_REVISED|CFM_SUBSCRIPT|CFM_SUPERSCRIPT|CFM_BACKCOLOR)
#define CFM_ALL  (CFM_EFFECTS|CFM_SIZE|CFM_FACE|CFM_OFFSET|CFM_CHARSET)
#define CFM_ALL2  (CFM_ALL|CFM_EFFECTS2|CFM_BACKCOLOR|CFM_LCID|CFM_UNDERLINETYPE|CFM_WEIGHT|CFM_REVAUTHOR|CFM_SPACING|CFM_KERNING|CFM_STYLE|CFM_ANIMATION)

#define CFE_SUBSCRIPT  0x00010000
#define CFE_SUPERSCRIPT  0x00020000

#define CFE_SMALLCAPS  CFM_SMALLCAPS
#define CFE_ALLCAPS  CFM_ALLCAPS
#define CFE_HIDDEN  CFM_HIDDEN
#define CFE_OUTLINE  CFM_OUTLINE
#define CFE_SHADOW  CFM_SHADOW
#define CFE_EMBOSS  CFM_EMBOSS
#define CFE_IMPRINT  CFM_IMPRINT
#define CFE_DISABLED  CFM_DISABLED
#define CFE_REVISED  CFM_REVISED
#define CFE_AUTOBACKCOLOR  CFM_BACKCOLOR

#define CFU_CF1UNDERLINE  0xFF
#define CFU_INVERT  0xFE
#define CFU_UNDERLINEHAIRLINE  10
#define CFU_UNDERLINETHICK  9
#define CFU_UNDERLINEWAVE  8
#define CFU_UNDERLINEDASHDOTDOT  7
#define CFU_UNDERLINEDASHDOT  6
#define CFU_UNDERLINEDASH  5
#define CFU_UNDERLINEDOTTED  4
#define CFU_UNDERLINEDOUBLE  3
#define CFU_UNDERLINEWORD  2
#define CFU_UNDERLINE  1
#define CFU_UNDERLINENONE  0

#define PFM_SPACEBEFORE  0x00000040
#define PFM_SPACEAFTER  0x00000080
#define PFM_LINESPACING  0x00000100
#define PFM_STYLE  0x00000400
#define PFM_BORDER  0x00000800
#define PFM_SHADING  0x00001000
#define PFM_NUMBERINGSTYLE  0x00002000
#define PFM_NUMBERINGTAB  0x00004000
#define PFM_NUMBERINGSTART  0x00008000
#define PFM_RTLPARA  0x00010000
#define PFM_KEEP  0x00020000
#define PFM_KEEPNEXT  0x00040000
#define PFM_PAGEBREAKBEFORE  0x00080000
#define PFM_NOLINENUMBER  0x00100000
#define PFM_NOWIDOWCONTROL  0x00200000
#define PFM_DONOTHYPHEN  0x00400000
#define PFM_SIDEBYSIDE  0x00800000
#define PFM_TABLE  0x40000000
#define PFM_COLLAPSED  0x01000000
#define PFM_OUTLINELEVEL  0x02000000
#define PFM_BOX  0x04000000

#define PFM_EFFECTS  (PFM_RTLPARA|PFM_KEEP|PFM_KEEPNEXT|PFM_TABLE|PFM_PAGEBREAKBEFORE|PFM_NOLINENUMBER|PFM_NOWIDOWCONTROL|PFM_DONOTHYPHEN|PFM_SIDEBYSIDE|PFM_TABLE)
#define PFM_ALL  (PFM_STARTINDENT|PFM_RIGHTINDENT|PFM_OFFSET|PFM_ALIGNMENT|PFM_TABSTOPS|PFM_NUMBERING|PFM_OFFSETINDENT|PFM_RTLPARA)
#define PFM_ALL2  (PFM_ALL|PFM_EFFECTS|PFM_SPACEBEFORE|PFM_SPACEAFTER|PFM_LINESPACING|PFM_STYLE|PFM_SHADING|PFM_BORDER|PFM_NUMBERINGTAB|PFM_NUMBERINGSTART|PFM_NUMBERINGSTYLE)

#define PFE_RTLPARA  (PFM_RTLPARA>>16)
#define PFE_KEEP  (PFM_KEEP>>16)
#define PFE_KEEPNEXT  (PFM_KEEPNEXT>>16)
#define PFE_PAGEBREAKBEFORE  (PFM_PAGEBREAKBEFORE>>16)
#define PFE_NOLINENUMBER  (PFM_NOLINENUMBER>>16)
#define PFE_NOWIDOWCONTROL  (PFM_NOWIDOWCONTROL>>16)
#define PFE_DONOTHYPHEN  (PFM_DONOTHYPHEN>>16)
#define PFE_SIDEBYSIDE  (PFM_SIDEBYSIDE>>16)
#define PFE_OUTLINELEVEL  (PFM_OUTLINELEVEL>>16)
#define PFE_COLLAPSED  (PFM_COLLAPSED>>16)
#define PFE_BOX  (PFM_BOX>>16)
#define PFE_TABLE  0x4000

#define PFN_ARABIC  2
#define PFN_LCLETTER  3
#define PFN_UCLETTER  4
#define PFN_LCROMAN  5
#define PFN_UCROMAN  6

#define PFNS_PAREN  0x000
#define PFNS_PARENS  0x100
#define PFNS_PERIOD  0x200
#define PFNS_PLAIN  0x300
#define PFNS_NONUMBER  0x400

#define PFA_JUSTIFY  4
#define PFA_FULL_INTERWORD  4
#define PFA_FULL_INTERLETTER  5
#define PFA_FULL_SCALED  6
#define PFA_FULL_GLYPHS  7
#define PFA_SNAP_GRID  8

#define SEL_EMPTY  0x0000
#define SEL_TEXT  0x0001
#define SEL_OBJECT  0x0002
#define SEL_MULTICHAR  0x0004
#define SEL_MULTIOBJECT  0x0008

#define GCM_RIGHTMOUSEDROP  0x8000

#define OLEOP_DOVERB  1

#define ST_DEFAULT  0
#define ST_KEEPUNDO  1
#define ST_SELECTION  2

#define GT_DEFAULT  0
#define GT_USECRLF  1
#define GT_SELECTION  2

#define GTL_DEFAULT  0
#define GTL_USECRLF  1
#define GTL_PRECISE  2
#define GTL_CLOSE  4
#define GTL_NUMCHARS  8
#define GTL_NUMBYTES  16

#if (_RICHEDIT_VER == 0x0100)
#define BOM_DEFPARADIR  0x0001
#define BOM_PLAINTEXT  0x0002
#endif /* _RICHEDIT_VER == 0x0100 */
#define BOM_NEUTRALOVERRIDE  0x0004
#define BOM_CONTEXTREADING  0x0008
#define BOM_CONTEXTALIGNMENT  0x0010

#if (_RICHEDIT_VER == 0x0100)
#define BOE_RTLDIR  0x0001
#define BOE_PLAINTEXT  0x0002
#endif /* _RICHEDIT_VER == 0x0100 */
#define BOE_NEUTRALOVERRIDE  0x0004
#define BOE_CONTEXTREADING  0x0008
#define BOE_CONTEXTALIGNMENT  0x0010

#define FR_MATCHDIAC  0x20000000
#define FR_MATCHKASHIDA  0x40000000
#define FR_MATCHALEFHAMZA  0x80000000

#ifndef WCH_EMBEDDING
#define WCH_EMBEDDING  (WCHAR)0xFFFC
#endif

typedef enum tagTextMode {
    TM_PLAINTEXT=1,
    TM_RICHTEXT=2,
    TM_SINGLELEVELUNDO=4,
    TM_MULTILEVELUNDO=8,
    TM_SINGLECODEPAGE=16,
    TM_MULTICODEPAGE=32
} TEXTMODE;

typedef LONG (*EDITWORDBREAKPROCEX)(char*,LONG,BYTE,INT);

typedef struct _charformat {
    UINT cbSize;
    DWORD dwMask;
    DWORD dwEffects;
    LONG yHeight;
    LONG yOffset;
    COLORREF crTextColor;
    BYTE bCharSet;
    BYTE bPitchAndFamily;
    char szFaceName[LF_FACESIZE];
} CHARFORMATA;

typedef struct _charformatw {
    UINT cbSize;
    DWORD dwMask;
    DWORD dwEffects;
    LONG yHeight;
    LONG yOffset;
    COLORREF crTextColor;
    BYTE bCharSet;
    BYTE bPitchAndFamily;
    WCHAR szFaceName[LF_FACESIZE];
} CHARFORMATW;

typedef struct _charrange {
    LONG cpMin;
    LONG cpMax;
} CHARRANGE;

typedef struct _textrange {
    CHARRANGE chrg;
    LPSTR lpstrText;
} TEXTRANGEA;

typedef struct _textrangew {
    CHARRANGE chrg;
    LPWSTR lpstrText;
} TEXTRANGEW;

typedef DWORD (CALLBACK *EDITSTREAMCALLBACK)(DWORD_PTR,LPBYTE,LONG,LONG*);

typedef struct _editstream {
    DWORD_PTR dwCookie;
    DWORD dwError;
    EDITSTREAMCALLBACK pfnCallback;
} EDITSTREAM;

typedef struct _findtext {
    CHARRANGE chrg;
    LPCSTR lpstrText;
} FINDTEXTA;

typedef struct _findtextw {
    CHARRANGE chrg;
    LPCWSTR lpstrText;
} FINDTEXTW;

typedef struct _findtextexa {
    CHARRANGE chrg;
    LPCSTR lpstrText;
    CHARRANGE chrgText;
} FINDTEXTEXA;

typedef struct _findtextexw {
    CHARRANGE chrg;
    LPCWSTR lpstrText;
    CHARRANGE chrgText;
} FINDTEXTEXW;

typedef struct _formatrange {
    HDC hdc;
    HDC hdcTarget;
    RECT rc;
    RECT rcPage;
    CHARRANGE chrg;
} FORMATRANGE;

typedef struct _paraformat {
    UINT cbSize;
    DWORD dwMask;
    WORD wNumbering;
    WORD wEffects;
    LONG dxStartIndent;
    LONG dxRightIndent;
    LONG dxOffset;
    WORD wAlignment;
    SHORT cTabCount;
    LONG rgxTabs[MAX_TAB_STOPS];
} PARAFORMAT;

#ifdef __cplusplus
struct CHARFORMAT2W : _charformatw {
    WORD wWeight;
    SHORT sSpacing;
    COLORREF crBackColor;
    LCID lcid;
    DWORD dwReserved;
    SHORT sStyle;
    WORD wKerning;
    BYTE bUnderlineType;
    BYTE bAnimation;
    BYTE bRevAuthor;
};

struct CHARFORMAT2A : _charformat {
    WORD wWeight;
    SHORT sSpacing;
    COLORREF crBackColor;
    LCID lcid;
    DWORD dwReserved;
    SHORT sStyle;
    WORD wKerning;
    BYTE bUnderlineType;
    BYTE bAnimation;
    BYTE bRevAuthor;
};
#else /* !__cplusplus */
typedef struct _charformat2w {
    UINT cbSize;
    DWORD dwMask;
    DWORD dwEffects;
    LONG yHeight;
    LONG yOffset;
    COLORREF crTextColor;
    BYTE bCharSet;
    BYTE bPitchAndFamily;
    WCHAR szFaceName[LF_FACESIZE];
    WORD wWeight;
    SHORT sSpacing;
    COLORREF crBackColor;
    LCID lcid;
    DWORD dwReserved;
    SHORT sStyle;
    WORD wKerning;
    BYTE bUnderlineType;
    BYTE bAnimation;
    BYTE bRevAuthor;
    BYTE bReserved1;
} CHARFORMAT2W;

typedef struct _charformat2a {
    UINT cbSize;
    DWORD dwMask;
    DWORD dwEffects;
    LONG yHeight;
    LONG yOffset;
    COLORREF crTextColor;
    BYTE bCharSet;
    BYTE bPitchAndFamily;
    char szFaceName[LF_FACESIZE];
    WORD wWeight;
    SHORT sSpacing;
    COLORREF crBackColor;
    LCID lcid;
    DWORD dwReserved;
    SHORT sStyle;
    WORD wKerning;
    BYTE bUnderlineType;
    BYTE bAnimation;
    BYTE bRevAuthor;
} CHARFORMAT2A;
#endif /* __cplusplus */

#ifdef __cplusplus
struct PARAFORMAT2 : _paraformat {
    LONG dySpaceBefore;
    LONG dySpaceAfter;
    LONG dyLineSpacing;
    SHORT sStyle;
    BYTE bLineSpacingRule;
    BYTE bOutlineLevel;
    WORD wShadingWeight;
    WORD wShadingStyle;
    WORD wNumberingStart;
    WORD wNumberingStyle;
    WORD wNumberingTab;
    WORD wBorderSpace;
    WORD wBorderWidth;
    WORD wBorders;
};
#else /* __cplusplus */
typedef struct _paraformat2 {
    UINT cbSize;
    DWORD dwMask;
    WORD wNumbering;
    WORD wReserved;
    LONG dxStartIndent;
    LONG dxRightIndent;
    LONG dxOffset;
    WORD wAlignment;
    SHORT cTabCount;
    LONG rgxTabs[MAX_TAB_STOPS];
    LONG dySpaceBefore;
    LONG dySpaceAfter;
    LONG dyLineSpacing;
    SHORT sStyle;
    BYTE bLineSpacingRule;
    BYTE bOutlineLevel;
    WORD wShadingWeight;
    WORD wShadingStyle;
    WORD wNumberingStart;
    WORD wNumberingStyle;
    WORD wNumberingTab;
    WORD wBorderSpace;
    WORD wBorderWidth;
    WORD wBorders;
} PARAFORMAT2;
#endif /* __cplusplus */

typedef struct _msgfilter {
    NMHDR nmhdr;
    UINT msg;
    WPARAM wParam;
    LPARAM lParam;
} MSGFILTER;

typedef struct _reqresize {
    NMHDR nmhdr;
    RECT rc;
} REQRESIZE;

typedef struct _selchange {
    NMHDR nmhdr;
    CHARRANGE chrg;
    WORD seltyp;
} SELCHANGE;

typedef struct _endropfiles {
    NMHDR nmhdr;
    HANDLE hDrop;
    LONG cp;
    BOOL fProtected;
} ENDROPFILES;

typedef struct _enprotected {
    NMHDR nmhdr;
    UINT msg;
    WPARAM wParam;
    LPARAM lParam;
    CHARRANGE chrg;
} ENPROTECTED;

typedef struct _ensaveclipboard {
    NMHDR nmhdr;
    LONG cObjectCount;
    LONG cch;
} ENSAVECLIPBOARD;

typedef struct _enoleopfailed {
    NMHDR nmhdr;
    LONG iob;
    LONG lOper;
    HRESULT hr;
} ENOLEOPFAILED;

typedef struct _objectpositions {
    NMHDR nmhdr;
    LONG cObjectCount;
    LONG *pcpPositions;
} OBJECTPOSITIONS;

typedef struct _enlink {
    NMHDR nmhdr;
    UINT msg;
    WPARAM wParam;
    LPARAM lParam;
    CHARRANGE chrg;
} ENLINK;

typedef struct _encorrecttext {
    NMHDR nmhdr;
    CHARRANGE chrg;
    WORD seltyp;
} ENCORRECTTEXT;

typedef struct _punctuation {
    UINT iSize;
    LPSTR szPunctuation;
} PUNCTUATION;

typedef struct _compcolor {
    COLORREF crText;
    COLORREF crBackground;
    DWORD dwEffects;
}COMPCOLOR;

typedef struct _repastespecial {
    DWORD dwAspect;
    DWORD_PTR dwParam;
} REPASTESPECIAL;

typedef enum _undonameid {
    UID_UNKNOWN=0,
    UID_TYPING=1,
    UID_DELETE=2,
    UID_DRAGDROP=3,
    UID_CUT=4,
    UID_PASTE=5
} UNDONAMEID;

typedef struct _settextex {
    DWORD flags;
    UINT codepage;
} SETTEXTEX;

typedef struct _gettextex {
    DWORD cb;
    DWORD flags;
    UINT codepage;
    LPCSTR lpDefaultChar;
    LPBOOL lpUsedDefChar;
} GETTEXTEX;

typedef struct _gettextlengthex {
    DWORD flags;
    UINT codepage;
} GETTEXTLENGTHEX;

typedef struct _bidioptions {
    UINT cbSize;
    WORD wMask;
    WORD wEffects;
} BIDIOPTIONS;

/* added by Pelles C development team 2000-09-08 */
#define RichEdit_Enable(hwndCtl,fEnable)  (BOOL)EnableWindow((hwndCtl),(fEnable))
#define RichEdit_GetText(hwndCtl,lpch,cchMax)  (int)GetWindowText((hwndCtl),(lpch),(cchMax))
#define RichEdit_GetTextLength(hwndCtl)  (int)GetWindowTextLength(hwndCtl)
#define RichEdit_SetText(hwndCtl,lpsz)  (BOOL)SetWindowText((hwndCtl),(lpsz))
#define RichEdit_LimitText(hwndCtl,cchMax)  ((void)SendMessage((hwndCtl),EM_LIMITTEXT,(WPARAM)(cchMax),0))
#define RichEdit_GetLineCount(hwndCtl)  ((int)(DWORD)SendMessage((hwndCtl),EM_GETLINECOUNT,0,0))
#define RichEdit_GetLine(hwndCtl,line,lpch,cchMax)  ((*((int *)(lpch))=(cchMax)), ((int)(DWORD)SendMessage((hwndCtl),EM_GETLINE,(WPARAM)(int)(line),(LPARAM)(LPTSTR)(lpch))))
#define RichEdit_GetRect(hwndCtl,lprc)  ((void)SendMessage((hwndCtl),EM_GETRECT,0,(LPARAM)(RECT*)(lprc)))
#define RichEdit_SetRect(hwndCtl,lprc)  ((void)SendMessage((hwndCtl),EM_SETRECT,0,(LPARAM)(const RECT*)(lprc)))
#define RichEdit_GetSel(hwndCtl)  ((DWORD)SendMessage((hwndCtl),EM_GETSEL,0,0))
#define RichEdit_SetSel(hwndCtl,ichStart,ichEnd)  ((void)SendMessage((hwndCtl),EM_SETSEL,(ichStart),(ichEnd)))
#define RichEdit_ReplaceSel(hwndCtl,lpszReplace)  ((void)SendMessage((hwndCtl),EM_REPLACESEL,0,(LPARAM)(LPCTSTR)(lpszReplace)))
#define RichEdit_GetModify(hwndCtl)  ((BOOL)(DWORD)SendMessage((hwndCtl),EM_GETMODIFY,0,0))
#define RichEdit_SetModify(hwndCtl,fModified)  ((void)SendMessage((hwndCtl),EM_SETMODIFY,(WPARAM)(UINT)(fModified),0))
#define RichEdit_ScrollCaret(hwndCtl)  ((BOOL)(DWORD)SendMessage((hwndCtl),EM_SCROLLCARET,0,0))
#define RichEdit_LineFromChar(hwndCtl,ich)  ((int)(DWORD)SendMessage((hwndCtl),EM_LINEFROMCHAR,(WPARAM)(int)(ich),0))
#define RichEdit_LineIndex(hwndCtl,line)  ((int)(DWORD)SendMessage((hwndCtl),EM_LINEINDEX,(WPARAM)(int)(line),0))
#define RichEdit_LineLength(hwndCtl,line)  ((int)(DWORD)SendMessage((hwndCtl),EM_LINELENGTH,(WPARAM)(int)(line),0))
#define RichEdit_Scroll(hwndCtl,dv,dh)  ((void)SendMessage((hwndCtl),EM_LINESCROLL,(WPARAM)(dh),(LPARAM)(dv)))
#define RichEdit_CanUndo(hwndCtl)  ((BOOL)(DWORD)SendMessage((hwndCtl),EM_CANUNDO,0,0))
#define RichEdit_Undo(hwndCtl)  ((BOOL)(DWORD)SendMessage((hwndCtl),EM_UNDO,0,0))
#define RichEdit_EmptyUndoBuffer(hwndCtl)  ((void)SendMessage((hwndCtl),EM_EMPTYUNDOBUFFER,0,0))
#define RichEdit_GetFirstVisibleLine(hwndCtl)  ((int)(DWORD)SendMessage((hwndCtl),EM_GETFIRSTVISIBLELINE,0,0))
#define RichEdit_SetReadOnly(hwndCtl,fReadOnly)  ((BOOL)(DWORD)SendMessage((hwndCtl),EM_SETREADONLY,(WPARAM)(BOOL)(fReadOnly),0))
#define RichEdit_SetWordBreakProc(hwndCtl,lpfnWordBreak)  ((void)SendMessage((hwndCtl),EM_SETWORDBREAKPROC,0,(LPARAM)(EDITWORDBREAKPROC)(lpfnWordBreak)))
#define RichEdit_GetWordBreakProc(hwndCtl)  ((EDITWORDBREAKPROC)SendMessage((hwndCtl),EM_GETWORDBREAKPROC,0,0))
#define RichEdit_CanPaste(hwnd,uFormat)  (BOOL)SendMessage((hwnd),EM_CANPASTE,(WPARAM)(UINT)(uFormat),0)
#define RichEdit_CharFromPos(hwnd,lppt)  (int)SendMessage((hwnd),EM_CHARFROMPOS,0,(LPARAM)(POINTL*)(lppt))  /* fixed 03-06-22 */
#define RichEdit_DisplayBand(hwnd,lprc)  (BOOL)SendMessage((hwnd),EM_DISPLAYBAND,0,(LPARAM)(LPRECT)(lprc))
#define RichEdit_ExGetSel(hwnd,lpchr)  (void)SendMessage((hwnd),EM_EXGETSEL,0,(LPARAM)(CHARRANGE*)(lpchr))
#define RichEdit_ExLimitText(hwnd,cchTextMax)  (void)SendMessage((hwnd), EM_EXLIMITTEXT, 0, (LPARAM) (DWORD) cchTextMax)
#define RichEdit_ExLineFromChar(hwnd,ichCharPos)  (int)SendMessage((hwnd),EM_EXLINEFROMCHAR,0,(LPARAM)(DWORD)(ichCharPos))
#define RichEdit_ExSetSel(hwnd,ichCharRange)  (int)SendMessage((hwnd),EM_EXSETSEL,0,(LPARAM)(CHARRANGE*)(ichCharRange))
#define RichEdit_FindText(hwnd,fuFlags,lpFindText)  (int)SendMessage((hwnd),EM_FINDTEXT,(WPARAM)(UINT)(fuFlags),(LPARAM)(FINDTEXT*)(lpFindText))
#define RichEdit_FindTextEx(hwnd,fuFlags,lpFindText)  (int)SendMessage((hwnd),EM_FINDTEXTEX,(WPARAM)(UINT)(fuFlags),(LPARAM)(FINDTEXT*)(lpFindText))
#define RichEdit_FindWordBreak(hwnd,code,ichStart)  (int)SendMessage((hwnd),EM_FINDWORDBREAK,(WPARAM)(UINT)(code),(LPARAM)(DWORD)(ichStart))
#define RichEdit_FormatRange(hwnd,fRender,lpFmt)  (int)SendMessage((hwnd),EM_FORMATRANGE,(WPARAM)(BOOL)(fRender),(LPARAM)(FORMATRANGE*)(lpFmt))
#define RichEdit_GetCharFormat(hwnd,fSelection,lpFmt)  (DWORD)SendMessage((hwnd),EM_GETCHARFORMAT,(WPARAM)(BOOL)(fSelection),(LPARAM)(CHARFORMAT*)(lpFmt))
#define RichEdit_GetEventMask(hwnd)  (DWORD)SendMessage((hwnd),EM_GETEVENTMASK,0,0)
#define RichEdit_GetLimitText(hwnd)  (int)SendMessage((hwnd),EM_GETLIMITTEXT,0,0)
#define RichEdit_GetOleInterface(hwnd,ppObject)  (BOOL)SendMessage((hwnd),EM_GETOLEINTERFACE,0,(LPARAM)(LPVOID*)(ppObject))
#define RichEdit_GetOptions(hwnd)  (UINT)SendMessage((hwnd),EM_GETOPTIONS,0,0)
#define RichEdit_GetParaFormat(hwnd,lpFmt)  (DWORD)SendMessage((hwnd),EM_GETPARAFORMAT,0,(LPARAM)(PARAFORMAT*)(lpFmt))
#define RichEdit_GetSelText(hwnd,lpBuf)  (int)SendMessage((hwnd),EM_GETSELTEXT,0,(LPARAM)(LPSTR)(lpBuf))
#define RichEdit_GetTextRange(hwnd,lpRange)  (int)SendMessage((hwnd),EM_GETTEXTRANGE,0,(LPARAM)(TEXTRANGE*)(lpRange))
#define RichEdit_GetWordBreakProcEx(hwnd)  (EDITWORDBREAKPROCEX *)SendMessage((hwnd),EM_GETWORDBREAKPROCEX,0,0)
#define RichEdit_HideSelection(hwnd,fHide,fChangeStyle)  (void)SendMessage((hwnd),EM_HIDESELECTION,(WPARAM)(BOOL)(fHide),(LPARAM)(BOOL)(fChangeStyle))
#define RichEdit_PasteSpecial(hwnd,uFormat)  (void)SendMessage((hwnd),EM_PASTESPECIAL,(WPARAM)(UINT)(uFormat),0)
#define RichEdit_PosFromChar(hwnd,wCharIndex)  (DWORD)SendMessage((hwnd),EM_POSFROMCHAR,(WPARAM)wCharIndex,0)
#define RichEdit_RequestResize(hwnd)  (void)SendMessage((hwnd),EM_REQUESTRESIZE,0,0)
#define RichEdit_SelectionType(hwnd)  (int)SendMessage((hwnd),EM_SELECTIONTYPE,0,0)
#define RichEdit_SetBkgndColor(hwnd,fUseSysColor,clr)  (COLORREF)SendMessage((hwnd),EM_SETBKGNDCOLOR,(WPARAM)(BOOL)(fUseSysColor),(LPARAM)(COLORREF)(clr))
#define RichEdit_SetCharFormat(hwnd,uFlags,lpFmt)  (BOOL)SendMessage((hwnd),EM_SETCHARFORMAT,(WPARAM)(UINT)(uFlags),(LPARAM)(CHARFORMAT*)(lpFmt))
#define RichEdit_SetEventMask(hwnd,dwMask)  (DWORD)SendMessage((hwnd),EM_SETEVENTMASK,0,(LPARAM)(DWORD)(dwMask))
#define RichEdit_SetOleCallback(hwnd,lpObj)  (BOOL)SendMessage((hwnd),EM_SETOLECALLBACK,0,(LPARAM)(IRichEditOleCallback*)(lpObj))
#define RichEdit_SetOptions(hwnd,fOperation,fOptions)  (UINT)SendMessage((hwnd),EM_SETOPTIONS,(WPARAM)(UINT)(fOperation),(LPARAM)(UINT)(fOptions))
#define RichEdit_SetParaFormat(hwnd,lpFmt)  (BOOL)SendMessage((hwnd),EM_SETPARAFORMAT,0,(LPARAM)(PARAFORMAT*)(lpFmt))
#define RichEdit_SetTargetDevice(hwnd,hdcTarget,cxLineWidth)  (BOOL)SendMessage((hwnd),EM_SETTARGETDEVICE,(WPARAM)(HDC)(hdcTarget),(LPARAM)(int)(cxLineWidth))
#define RichEdit_SetWordBreakProcEx(hwnd,pfnWordBreakProcEx)  (EDITWORDBREAKPROCEX*)SendMessage((hwnd),EM_SETWORDBREAKPROCEX,0,(LPARAM)(EDITWORDBREAKPROCEX*)pfnWordBreakProcEx)
#define RichEdit_StreamIn(hwnd,uFormat,lpStream)  (int)SendMessage((hwnd),EM_STREAMIN,(WPARAM)(UINT)(uFormat),(LPARAM)(EDITSTREAM*)(lpStream))
#define RichEdit_StreamOut(hwnd,uFormat,lpStream)  (int)SendMessage((hwnd),EM_STREAMOUT,(WPARAM)(UINT)(uFormat),(LPARAM)(EDITSTREAM*)(lpStream))

#if (_RICHEDIT_VER >= 0x0200)
#ifdef UNICODE
#define RICHEDIT_CLASS RICHEDIT_CLASSW
#define CHARFORMAT CHARFORMATW
#define CHARFORMAT2 CHARFORMAT2W
#define TEXTRANGE TEXTRANGEW
#define FINDTEXT FINDTEXTW
#define FINDTEXTEX FINDTEXTEXW
#else
#define RICHEDIT_CLASS RICHEDIT_CLASSA
#define CHARFORMAT CHARFORMATA
#define CHARFORMAT2 CHARFORMAT2A
#define TEXTRANGE TEXTRANGEA
#define FINDTEXT FINDTEXTA
#define FINDTEXTEX FINDTEXTEXA
#endif /* UNICODE */
#else /* _RICHEDIT_VER >= 0x0200 */
#define RICHEDIT_CLASS RICHEDIT_CLASS10A
#define CHARFORMAT CHARFORMATA
#define TEXTRANGE TEXTRANGEA
#define FINDTEXT FINDTEXTA
#define FINDTEXTEX FINDTEXTEXA
#endif /* _RICHEDIT_VER >= 0x0200 */

#include <poppack.h>

#ifdef __cplusplus
}
#endif

#endif /* _RICHEDIT_H */
