//
// $Id: testzip.prg,v 1.3 2003/09/14 09:27:23 paultucker Exp $
//

// Requires samples.lib for gauge support
//

#include "common.ch"
#include "setcurs.ch"

proc Main()
Local aFiles, aGauge, nLen, aDir
Local aGaugeFile

   ZipCreate( "TEST.ZIP", "testzip.prg" )

   aFiles := {"testzip.prg",GetEnv("windir")+ "\win.ini"}
   nLen   := Len(afiles)

   ZipCreate( "TEST1.ZIP", aFiles[2] )
   ZipCreate( "TEST2.ZIP", aFiles, 8, {|cFile,nPos| qout("Added " + cFile)})

   // something here is not clipper compatible
   ?;?;?
   ?
   ?;?;?

   aGauge := GaugeNew( row()-6, 5, row()-4,74 , "W/B", "W+/B" ,'�')
   GaugeDisplay( aGauge )

   aGaugeFile := GaugeNew( row()+2, 5, row()+4,74 , "W/B", "W+/B" ,'�')
   GaugeDisplay( aGaugeFile )

   aDir   := Directory( "*.prg" )
   aFiles := {}
   Aeval( aDir, {|a| aadd( aFiles, a[1]) })
   nLen   := Len(afiles)

   set cursor off

   ZipCreate("test3.zip", aFiles, 8, ;
              {|cFile,nPos| GaugeUpdate(aGauge,nPos/nLen) },,'hello',,,;
              {|nPos,nCur| GaugeUpdate(aGaugeFile,nPos/nCur)})

   set cursor on

   ? str( nlen ) +" files were added to the zip"

   // method 1
   aFiles :=  hb_GetFilesInZip( "test3.zip" )
   if aFiles != NIL
      ? str( Len( aFiles ) ) + " files are in the zip"
   endif
   // or simpler, method 2
   ? str( hb_GetFileCount("test3.zip" ) ) + " files using alternate method"

   ZipHasPassword( "TEST1.ZIP" )
   ZipHasPassword( "test3.zip" )

function ZipCreate(cFile, uContents, nLevel, bUpdate, lOverwrite, password,;
                   lPath, lDrive, bFileUpdate)
   Local lRet

   Default lOverwrite to .t.
   Default lPath to .t.

   IF ( lRet := HB_ZIPFILE( cFile, uContents, nLevel, bUpdate, lOverwrite,;
                            password, lPath, lDrive, bFileUpdate) )
      ? cFile + " was successfully created"
   ENDIF

Return lRet

Function ZipHasPassword( cFile )
   Local lRet

   ? cFile + " has " + iif(lRet := hb_ZipWithPassword(cFile),"a","no" )+ " password"

Return lRet
