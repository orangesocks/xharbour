// SERVER:
Procedure Main( cPort )

   LOCAL Socket, s
   LOCAL nResponse, cResponse

   CLS

   IF Empty( cPort )
      cPort := "2000"
   ENDIF

   InetInit()

   Socket := InetServer( Val( cPort ) )

   @ 5, 5 SAY "Server listening: ..."

   s := InetAccept( Socket )

   @ 6, 5 SAY "Connection from: " + InetAddress( s ) + ":" + Str( InetPort( s ), 5 )

   nResponse := InetSend( s, "Welcome to my server!" + Chr(13) + Chr(10) )
   TraceLog( nResponse )

   DO WHILE nResponse >= 0
      *Note that cResponse is NIL the first time, while is allocated the others
      cResponse := InetRecvLine( s, @nResponse )

      IF InetErrorCode( s ) != 0
          @ 8, 5 SAY Space(70)
          @ 8, 5 SAY "Error code " + Str( InetErrorCode( s ) ) + ": " + InetErrorDesc( s )
          @ 9, 5 SAY "Any key to quit..."

          Inkey(0)

          EXIT
      ELSE
         @ 7, 5 SAY "Received:"
         @ 8, 5 SAY space(70)
         @ 8, 5 SAY cResponse

         cResponse := "Count: " + Str( nResponse ) + " characters" + Chr(13) + Chr(10)
         InetSend( s, cResponse )

         @  9, 5 SAY "Sent:"
         @ 10, 5 SAY space(70)
         @ 10, 5 SAY cResponse
      ENDIF
   ENDDO

   InetClose( s )
   InetDestroy( s )

   InetClose( Socket )
   InetDestroy( Socket )

   InetCleanup()

RETURN
