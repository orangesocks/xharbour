/*
 * $Id: hberrors.h,v 1.15 2004/02/18 10:50:44 andijahja Exp $
 */

/*
 * Harbour Project source code:
 * Header file for compiler error codes
 *
 * Copyright 1999 Ryszard Glab <rglab@imid.med.pl>
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#ifndef HB_ERRORS_H_
#define HB_ERRORS_H_

#include "hbsetup.h"

HB_EXTERN_BEGIN

/*
 * Errors generated by Harbour compiler
 */
#define HB_COMP_ERR_OUTSIDE                     1
#define HB_COMP_ERR_FUNC_DUPL                   2
#define HB_COMP_ERR_VAR_DUPL                    3
#define HB_COMP_ERR_FOLLOWS_EXEC                4
#define HB_COMP_ERR_OUTER_VAR                   5
#define HB_COMP_ERR_NUMERIC_FORMAT              6
#define HB_COMP_ERR_STRING_TERMINATOR           7
#define HB_COMP_ERR_FUNC_RESERVED               8
#define HB_COMP_ERR_ILLEGAL_INIT                9
#define HB_COMP_ERR_ENDIF                       10
#define HB_COMP_ERR_ENDDO                       11
#define HB_COMP_ERR_ENDCASE                     12
#define HB_COMP_ERR_NEXTFOR                     13
#define HB_COMP_ERR_UNMATCHED_ELSE              14
#define HB_COMP_ERR_UNMATCHED_ELSEIF            15
#define HB_COMP_ERR_SYNTAX                      16
#define HB_COMP_ERR_UNCLOSED_STRU               17
#define HB_COMP_ERR_UNMATCHED_EXIT              18
#define HB_COMP_ERR_SYNTAX2                     19
#define HB_COMP_ERR_INCOMPLETE_STMT             20
#define HB_COMP_ERR_CHECKING_ARGS               21
#define HB_COMP_ERR_INVALID_LVALUE              22
#define HB_COMP_ERR_INVALID_REFER               23
#define HB_COMP_ERR_PARAMETERS_NOT_ALLOWED      24
#define HB_COMP_ERR_EXIT_IN_SEQUENCE            25
#define HB_COMP_ERR_UNTERM_ARRAY_INDEX          26
#define HB_COMP_ERR_MEMALLOC                    27
#define HB_COMP_ERR_MEMREALLOC                  28
#define HB_COMP_ERR_MEMFREE                     29
#define HB_COMP_ERR_YACC                        30
#define HB_COMP_ERR_JUMP_TOO_LONG               31
#define HB_COMP_ERR_CREATE_OUTPUT               32
#define HB_COMP_ERR_CREATE_PPO                  33
#define HB_COMP_ERR_BADOPTION                   34
#define HB_COMP_ERR_BADPARAM                    35
#define HB_COMP_ERR_BADFILENAME                 36
#define HB_COMP_ERR_MAYHEM_IN_CASE              37
#define HB_COMP_ERR_INVALID_TYPE                38
#define HB_COMP_ERR_INVALID_ALIAS               39
#define HB_COMP_ERR_INVALID_INDEX               40
#define HB_COMP_ERR_INVALID_BOUND               41
#define HB_COMP_ERR_BAD_MACRO                   42
#define HB_COMP_ERR_INVALID_SEND                43
#define HB_COMP_ERR_FUNC_ANNOUNCE               44
#define HB_COMP_ERR_JUMP_NOT_FOUND              45
#define HB_COMP_ERR_CASE                        46
#define HB_COMP_ERR_BLOCK                       47
#define HB_COMP_ERR_GET_COMPLEX_MACRO           48
#define HB_COMP_ERR_INVALID_INLINE              49
#define HB_COMP_ERR_TOOMANY_INLINE              50
#define HB_COMP_ERR_REQUIRES_C                  51
#define HB_COMP_ERR_MISSING_ENDTEXT             52
#define HB_COMP_ERR_OPTIMIZEDLOCAL_OUT_OF_RANGE 53
#define HB_COMP_ERR_UNMATCHED_WITHOBJECT        54
#define HB_COMP_ERR_GLOBAL_MISPLACED            55
#define HB_COMP_ERR_TOOMANY_GLOBALS             56
#define HB_COMP_ERR_EXTERNGLOBAL_ASSIGN         57
#define HB_COMP_ERR_TOOMANY_PARAMS              58
#define HB_COMP_ERR_INVALID_CONSTANT            59
#define HB_COMP_ERR_CREATE_HIL                  60
#define HB_COMP_ERR_ILLEGAL_CHARACTER           61

#define HB_COMP_WARN_AMBIGUOUS_VAR              1
#define HB_COMP_WARN_MEMVAR_ASSUMED             2
#define HB_COMP_WARN_VAR_NOT_USED               3
#define HB_COMP_WARN_BLOCKVAR_NOT_USED          4
#define HB_COMP_WARN_NO_RETURN_VALUE            5
#define HB_COMP_WARN_PROC_RETURN_VALUE          6
#define HB_COMP_WARN_FUN_WITH_NO_RETURN         7
#define HB_COMP_WARN_ASSIGN_TYPE                8
#define HB_COMP_WARN_OPERAND_TYPE               9
#define HB_COMP_WARN_OPERANDS_INCOMPATIBLE      10
#define HB_COMP_WARN_ASSIGN_SUSPECT             11
#define HB_COMP_WARN_OPERAND_SUSPECT            12
#define HB_COMP_WARN_NOT_ARRAY                  13
#define HB_COMP_WARN_RETURN_TYPE                14
#define HB_COMP_WARN_RETURN_SUSPECT             15
#define HB_COMP_WARN_PARAM_COUNT                16
#define HB_COMP_WARN_PARAM_TYPE                 17
#define HB_COMP_WARN_PARAM_SUSPECT              18
#define HB_COMP_WARN_DUP_DECLARATION            19
#define HB_COMP_WARN_DECLARATION_CONFLICT       20
#define HB_COMP_WARN_NOT_INITIALIZED            21
#define HB_COMP_WARN_VAL_NOT_USED               22
#define HB_COMP_WARN_ARRAY_ASSIGN_TYPE          23
#define HB_COMP_WARN_ARRAY_ASSIGN_SUSPECT       24
#define HB_COMP_WARN_CLASS_NOT_FOUND            25
#define HB_COMP_WARN_MESSAGE_NOT_FOUND          26
#define HB_COMP_WARN_MEANINGLESS                27
#define HB_COMP_WARN_UNREACHABLE                28
#define HB_COMP_WARN_DUPL_ANNOUNCE              29

/*
 * Errors generated by Harbour preprocessor
 */
#define HB_PP_ERR_CANNOT_OPEN                   1
#define HB_PP_ERR_DIRECTIVE_ELSE                2
#define HB_PP_ERR_DIRECTIVE_ENDIF               3
#define HB_PP_ERR_WRONG_NAME                    4
#define HB_PP_ERR_DEFINE_ABSENT                 5
#define HB_PP_ERR_COMMAND_DEFINITION            6
#define HB_PP_ERR_PATTERN_DEFINITION            7
#define HB_PP_ERR_RECURSE                       8
#define HB_PP_ERR_WRONG_DIRECTIVE               9
#define HB_PP_ERR_EXPLICIT                      10
#define HB_PP_ERR_MEMALLOC                      11
#define HB_PP_ERR_MEMREALLOC                    12
#define HB_PP_ERR_MEMFREE                       13
#define HB_PP_ERR_PRAGMA_BAD_VALUE              14
#define HB_PP_ERR_CANNOT_OPEN_RULES             15
#define HB_PP_ERR_BAD_RULES_FILE_NAME           16
#define HB_PP_ERR_TOO_MANY_INCLUDES             17
#define HB_PP_ERR_BUFFER_OVERFLOW               18
#define HB_PP_ERR_LABEL_MISSING                 19
#define HB_PP_ERR_TOO_MANY_MARKERS              20
#define HB_PP_ERR_UNCLOSED_OPTIONAL             21
#define HB_PP_ERR_UNCLOSED_REPEATABLE           22
#define HB_PP_ERR_UNKNOWN_RESULTMARKER          23
#define HB_PP_ERR_TOO_MANY_INSTANCES            24
#define HB_PP_ERR_TOO_MANY_OPTIONALS            25

#define HB_PP_WARN_DEFINE_REDEF                 1
#define HB_PP_WARN_NO_DIRECTIVES                2
#define HB_PP_WARN_NO_MARKERS                   3

extern void hb_compGenError( char * szErrors[], char cPrefix, int iError, const char * szError1, const char * szError2 ); /* generic parsing error management function */
extern void hb_compGenWarning( char * szWarnings[], char cPrefix, int iWarning, const char * szWarning1, const char * szWarning2); /* generic parsing warning management function */

HB_EXTERN_END

#endif /* HB_ERRORS_H_ */
