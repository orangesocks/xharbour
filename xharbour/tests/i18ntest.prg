************************************************************
* i18ntest.prg
* $Id: i18ntest.prg,v 1.3 2003/06/24 02:17:21 fsgiudice Exp $
*
* Test for internationalization system
*
* (C) Giancarlo Niccolai
*

#include "inkey.ch"

Procedure MAIN()
   LOCAL nChoice, nLangs
   LOCAL aLanguages
   LOCAL aLangCodes := { "en_US", "it_IT", "fr_FR", "es_MX" }

   SET COLOR TO W+/B
   SetMode( 25, 80 )

   nChoice := 1
   nLangs := Len( aLangCodes ) + 1
   DO WHILE nChoice < nLangs .and. nChoice > 0
      aLanguages := { ;
         i18n( "International" ), ;
         i18n( "Italian" ), ;
         i18n( "French" ), ;
         i18n( "Spanish" ), ;
         i18n( "Quit" ) }

      CLEAR SCREEN
      @2,10 SAY i18n( "X H A R B O U R - Internationalization test " )
      @4,10 SAY i18n( "Current language: " ) + HB_I18NGetLanguageName() +;
                  "(" +HB_I18NGetLanguage() +")"
      @6,10 SAY i18n( "This is a test with a plain string")
      @7,10 SAY i18n( "This is a test " + "with a static '+' string" )
      @8,10 SAY i18n( "This is a test using a 'compile time' '" +chr(65)+"'")
      @9,10 SAY i18n( "Test mixing" + e"\tescaped\t")

      @12,10 SAY i18n( "Select Language: " )
      MakeBox( 12,40, 20, 55 )
      nChoice := Achoice(13, 41, 19, 54, aLanguages,,, ;
         Ascan( aLangCodes, { |x| x == HB_I18NGetLanguage() } ) )

      IF nChoice > 0 .and. nChoice < nLangs
         HB_I18NSetLanguage( aLangCodes[ nChoice ] )
      ENDIF
   ENDDO


RETURN

PROCEDURE MakeBox( nRow, nCol, nRowTo, nColTo )
   @nRow, nCol, nRowTo, nColTo ;
        BOX( Chr( 201 ) + Chr( 205 ) + Chr( 187 ) + Chr( 186 ) +;
        Chr( 188 ) + Chr( 205 ) + Chr( 200 ) + Chr( 186 ) + Space( 1 ) )
RETURN

