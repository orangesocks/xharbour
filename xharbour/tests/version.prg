//
// $Id: version.prg,v 1.4 2000/04/10 22:33:06 vszel Exp $
//

// Testing the VERSION function
/* Harbour Project source code
   http://www.Harbour-Project.org/
   Donated to the public domain by David G. Holm <dholm@jsd-llc.com>.
*/

function Main()

   outstd( chr( 34 ) + version() + chr( 34 ) + hb_osnewline() )
   outstd( chr( 34 ) + hb_compiler() + chr( 34 ) + hb_osnewline() )
   outstd( chr( 34 ) + os() + chr( 34 ) + hb_osnewline() )

   return nil
