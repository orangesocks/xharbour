REQUEST DBFCDX
#define _TESTRDD "DBFCDX"
#include "rddtst.prg"

FUNCTION test_main()

RDDTESTC {15,.f.,.f.,.f.}, local n                         ; use "_tst" shared                    ; for n:=1 to 15                    ; dbappend()                          ; replace FNUM with int((n+2)/3)      ; replace FSTR with chr(FNUM+48)      ; next
RDDTESTF NIL, {15,.f.,.f.,.f.}, dbcommit()
RDDTESTF NIL, {15,.f.,.f.,.f.}, dbunlock()
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FNUM tag TG_N to "_tst"
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst"
RDDTESTF "TG_C", {1,.f.,.f.,.f.}, ORDSETFOCUS(1)
RDDTESTF "TG_N", {1,.f.,.f.,.f.}, ORDSETFOCUS()
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK(0,.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(0,.T.,.T.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK(0.5,.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(0.5,.T.,.T.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK(1.0,.T.,.F.)
RDDTESTF .t., {3,.f.,.f.,.t.}, DBSEEK(1.0,.T.,.T.)
RDDTESTF .t., {4,.f.,.f.,.t.}, DBSEEK(2.0,.T.,.F.)
RDDTESTF .t., {6,.f.,.f.,.t.}, DBSEEK(2.0,.T.,.T.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK(2.5,.T.,.F.)
RDDTESTF .f., {6,.f.,.f.,.f.}, DBSEEK(2.5,.T.,.T.)
RDDTESTF .t., {13,.f.,.f.,.t.}, DBSEEK(5.0,.T.,.F.)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK(5.0,.T.,.T.)
RDDTESTF "TG_N", {15,.f.,.f.,.t.}, ORDSETFOCUS(2)
RDDTESTF "TG_C", {15,.f.,.f.,.t.}, ORDSETFOCUS()
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("", .T.,.F.)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("1",.T.,.F.)
RDDTESTF .t., {3,.f.,.f.,.t.}, DBSEEK("1",.T.,.T.)
RDDTESTF .t., {4,.f.,.f.,.t.}, DBSEEK("2",.T.,.F.)
RDDTESTF .t., {6,.f.,.f.,.t.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .t., {13,.f.,.f.,.t.}, DBSEEK("5",.T.,.F.)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {15,.f.,.f.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTF NIL, {15,.f.,.f.,.f.}, ORDSCOPE(0,"3")
RDDTESTF NIL, {15,.f.,.f.,.f.}, ORDSCOPE(1,"4")
RDDTESTF "3", {15,.f.,.f.,.f.}, DBORDERINFO(39)
RDDTESTF "4", {15,.f.,.f.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("", .T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK("1",.T.,.F.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK("1",.T.,.T.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK("2",.T.,.F.)
RDDTESTF .f., {7,.f.,.f.,.f.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("5",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTF "3", {16,.f.,.t.,.f.}, ORDSCOPE(0,"3")
RDDTESTF "4", {16,.f.,.t.,.f.}, ORDSCOPE(1,"2")
RDDTESTF "3", {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF "2", {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("3",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("3",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("4",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("4",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, orddescend()
RDDTESTF .f., {16,.f.,.t.,.f.}, orddescend(,,.T.)
RDDTESTF .t., {16,.f.,.t.,.f.}, orddescend()
RDDTESTF "2", {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF "3", {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {16,.f.,.t.,.f.}, ORDSCOPE(0,NIL)
RDDTESTF .t., {16,.f.,.t.,.f.}, ORDSCOPE(1,NIL)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("", .T.,.F.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .t., {3,.f.,.f.,.t.}, DBSEEK("1",.T.,.F.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("1",.T.,.T.)
RDDTESTF .t., {6,.f.,.f.,.t.}, DBSEEK("2",.T.,.F.)
RDDTESTF .t., {4,.f.,.f.,.t.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("5",.T.,.F.)
RDDTESTF .t., {13,.f.,.f.,.t.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {15,.f.,.f.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTF NIL, {16,.f.,.t.,.f.}, ORDSCOPE(0,"4")
RDDTESTF NIL, {16,.f.,.t.,.f.}, ORDSCOPE(1,"3")
RDDTESTF "4", {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF "3", {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("", .T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("5",.T.,.F.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTF "4", {16,.f.,.t.,.f.}, ORDSCOPE(0,"3")
RDDTESTF "3", {16,.f.,.t.,.f.}, ORDSCOPE(1,"4")
RDDTESTF "3", {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF "4", {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("", .T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("3",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("3",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("4",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("4",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("5",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTC {15,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst" DESCEND
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("",.T.,.F.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {1,.f.,.f.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .t., {3,.f.,.f.,.t.}, DBSEEK("1",.T.,.F.)
RDDTESTF .t., {1,.f.,.f.,.t.}, DBSEEK("1",.T.,.T.)
RDDTESTF .t., {6,.f.,.f.,.t.}, DBSEEK("2",.T.,.F.)
RDDTESTF .t., {4,.f.,.f.,.t.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .t., {15,.f.,.f.,.t.}, DBSEEK("5",.T.,.F.)
RDDTESTF .t., {13,.f.,.f.,.t.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {15,.f.,.f.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTF NIL, {16,.f.,.t.,.f.}, ORDSCOPE(0,"4")
RDDTESTF NIL, {16,.f.,.t.,.f.}, ORDSCOPE(1,"3")
RDDTESTF "4", {16,.f.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF "3", {16,.f.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("", .T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("", .T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK(" ",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("0",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("1",.T.,.T.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("2",.T.,.T.)
RDDTESTF .t., {9,.f.,.f.,.t.}, DBSEEK("3",.T.,.F.)
RDDTESTF .t., {7,.f.,.f.,.t.}, DBSEEK("3",.T.,.T.)
RDDTESTF .t., {12,.f.,.f.,.t.}, DBSEEK("4",.T.,.F.)
RDDTESTF .t., {10,.f.,.f.,.t.}, DBSEEK("4",.T.,.T.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("5",.T.,.F.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("5",.T.,.T.)
RDDTESTF .f., {12,.f.,.f.,.f.}, DBSEEK("6",.T.,.F.)
RDDTESTF .f., {16,.f.,.t.,.f.}, DBSEEK("6",.T.,.T.)
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst"
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTOP()
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBSKIP(0)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(0)
RDDTESTF NIL, {15,.f.,.f.,.f.}, DBGOBOTTOM()
RDDTESTF NIL, {15,.f.,.f.,.f.}, DBSKIP(0)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(0)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {2,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(5)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBSKIP(5)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(5)
RDDTESTF NIL, {15,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {10,.f.,.f.,.f.}, DBSKIP(-5)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(10)
RDDTESTF NIL, {11,.f.,.f.,.f.}, DBSKIP(-5)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTO(16)
RDDTESTF NIL, {15,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {15,.f.,.f.,.f.}, ORDSCOPE(0,"3")
RDDTESTF NIL, {15,.f.,.f.,.f.}, ORDSCOPE(1,"4")
RDDTESTF "3", {15,.f.,.f.,.f.}, DBORDERINFO(39)
RDDTESTF "4", {15,.f.,.f.,.f.}, DBORDERINFO(40)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {6,.f.,.f.,.f.}, DBGOTO(6)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {6,.f.,.f.,.f.}, DBGOTO(6)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {8,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBGOTO(12)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBGOTO(12)
RDDTESTF NIL, {11,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {14,.f.,.f.,.f.}, DBGOTO(14)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTO(16)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTC {7,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst" FOR FNUM>2 .AND. FNUM<=4
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {6,.f.,.f.,.f.}, DBGOTO(6)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {6,.f.,.f.,.f.}, DBGOTO(6)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {8,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBGOTO(12)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBGOTO(12)
RDDTESTF NIL, {11,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {14,.f.,.f.,.f.}, DBGOTO(14)
RDDTESTF NIL, {7,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTO(16)
RDDTESTF NIL, {12,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst" FOR FNUM<>2 .AND. FNUM<4
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {2,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF NIL, {3,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {8,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {7,.f.,.f.,.f.}, DBGOTO(7)
RDDTESTF NIL, {3,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {10,.f.,.f.,.f.}, DBGOTO(10)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {10,.f.,.f.,.f.}, DBGOTO(10)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {14,.f.,.f.,.f.}, DBGOTO(14)
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTO(16)
RDDTESTF NIL, {9,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTOP()
RDDTESTF NIL, {2,.f.,.f.,.f.}, DBSKIP(1)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTOP()
RDDTESTF NIL, {1,.t.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {9,.f.,.f.,.f.}, DBGOBOTTOM()
RDDTESTF NIL, {16,.f.,.t.,.f.}, DBSKIP(1)
RDDTESTF NIL, {9,.f.,.f.,.f.}, DBGOBOTTOM()
RDDTESTF NIL, {8,.f.,.f.,.f.}, DBSKIP(-1)
RDDTESTF NIL, {8,.f.,.f.,.f.}, ORDSCOPE(0,"5")
RDDTESTF "5", {8,.f.,.f.,.f.}, DBORDERINFO(39)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTOP()
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOBOTTOM()
RDDTESTC {16,.t.,.t.,.f.}, INDEX on FSTR tag TG_C to "_tst" FOR FNUM==6
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOTOP()
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBGOBOTTOM()
RDDTESTF NIL, {16,.t.,.t.,.f.}, ORDSCOPE()
RDDTESTF NIL, {16,.t.,.t.,.f.}, ORDSCOPE(0)
RDDTESTF NIL, {16,.t.,.t.,.f.}, ORDSCOPE(1)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {16,.t.,.t.,.f.}, ORDSCOPE(0,NIL)
RDDTESTF .t., {16,.t.,.t.,.f.}, ORDSCOPE(1,NIL)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF .t., {16,.t.,.t.,.f.}, ORDSCOPE(0,NIL)
RDDTESTF .t., {16,.t.,.t.,.f.}, ORDSCOPE(1,NIL)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF NIL, {16,.t.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF NIL, {16,.t.,.t.,.f.}, ORDSCOPE(0,{||"3"})
RDDTESTF NIL, {16,.t.,.t.,.f.}, ORDSCOPE(1,{||"4"})
RDDTESTF {||"3"}, {16,.t.,.t.,.f.}, DBORDERINFO(39)
RDDTESTF {||"4"}, {16,.t.,.t.,.f.}, DBORDERINFO(40)
RDDTESTF {||"3"}, {16,.t.,.t.,.f.}, ORDSCOPE({},"3")
RDDTESTF {||"4"}, {16,.t.,.t.,.f.}, ORDSCOPE(1,"4")
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE()
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(0)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(1)
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(0)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(1)
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(0,"3")
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(0)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(1)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(2)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(3)
RDDTESTF .f., {16,.t.,.t.,.f.}, orddescend(,,.T.)
RDDTESTF "4", {16,.t.,.t.,.f.}, ORDSCOPE(0)
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(1)
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(2)
RDDTESTF "3", {16,.t.,.t.,.f.}, ORDSCOPE(3)
RDDTESTF .t., {16,.t.,.t.,.f.}, orddescend(,,.F.)
RDDTESTF .t., {16,.t.,.t.,.f.}, ORDSCOPE(0,NIL)
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst"
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTOP()
RDDTESTF .t., {4,.f.,.f.,.f.}, ORDSKIPUNIQUE()
RDDTESTF .t., {7,.f.,.f.,.f.}, ORDSKIPUNIQUE(1)
RDDTESTF .t., {10,.f.,.f.,.f.}, ORDSKIPUNIQUE(2)
RDDTESTF .t., {9,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF .t., {6,.f.,.f.,.f.}, ORDSKIPUNIQUE(-2)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTOP()
RDDTESTF .t., {1,.t.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF .t., {4,.f.,.f.,.f.}, ORDSKIPUNIQUE()
RDDTESTF NIL, {15,.f.,.f.,.f.}, DBGOBOTTOM()
RDDTESTF .t., {12,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF .t., {13,.f.,.f.,.f.}, ORDSKIPUNIQUE()
RDDTESTF .t., {16,.f.,.t.,.f.}, ORDSKIPUNIQUE()
RDDTESTF .t., {15,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF "TG_C", {15,.f.,.f.,.f.}, ORDSETFOCUS(0)
RDDTESTF NIL, {1,.f.,.f.,.f.}, DBGOTO(1)
RDDTESTF .t., {2,.f.,.f.,.f.}, ORDSKIPUNIQUE()
RDDTESTF .t., {1,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst" FOR FNUM<>2 .AND. FNUM<4
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF .t., {3,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF NIL, {4,.f.,.f.,.f.}, DBGOTO(4)
RDDTESTF .t., {7,.f.,.f.,.f.}, ORDSKIPUNIQUE()
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF .t., {1,.t.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF NIL, {13,.f.,.f.,.f.}, DBGOTO(13)
RDDTESTF .t., {16,.f.,.t.,.f.}, ORDSKIPUNIQUE()
RDDTESTC {1,.f.,.f.,.f.}, INDEX on FSTR tag TG_C to "_tst" FOR RECNO()<>5
RDDTESTF NIL, {5,.f.,.f.,.f.}, DBGOTO(5)
RDDTESTF .t., {3,.f.,.f.,.f.}, ORDSKIPUNIQUE(-1)
RDDTESTF NIL, {5,.f.,.f.,.f.}, DBGOTO(5)
RDDTESTF .t., {7,.f.,.f.,.f.}, ORDSKIPUNIQUE()

RETURN NIL
