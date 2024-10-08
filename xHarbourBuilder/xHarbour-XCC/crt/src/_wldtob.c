/****************************************************************************
 *                                                                          *
 * File    : _wldtob.c                                                      *
 *                                                                          *
 * Purpose : __wldtob function.                                             *
 *                                                                          *
 * History : Date      Reason                                               *
 *           00-09-15  Created                                              *
 *           01-09-10  Rewritten for C99.                                   *
 *                                                                          *
 ****************************************************************************/

#include <float.h>
#include <stdlib.h>
#include <wchar.h>
#include "xmath.h"
#include "xwstdio.h"

/* macros */
#define MAXDIG  40  /* safe for 128-bit long double */
#define NDIG    8   /* decimal digits generated for each multiply */
#define NXDIG   7   /* hexadecimal digits generated for each multiply */

/* static data */
static const long double pows[] = {
    1e1L, 1e2L, 1e4L, 1e8L, 1e16L, 1e32L,
#if _LBIAS > 0x100  /* assume IEEE 754 8- or 10-byte */
    1e64L, 1e128L, 1e256L,
#if _DLONG  /* assume IEEE 754 10-byte */
    1e512L, 1e1024L, 1e2048L, 1e4096L,
#endif
#endif
};

/* convert long double to wide text */
void __wldtob(__wprtinfo *px, wchar_t code)
{
    wchar_t ac[MAXDIG];
    wchar_t *p = ac;
    long double ldval = px->v.ld;
    short errx, nsig, xexp;
    static const wchar_t inf[] = { L'i', L'n', L'f', L'\0' };
    static const wchar_t Inf[] = { L'I', L'N', L'F', L'\0' };
    static const wchar_t nan[] = { L'n', L'a', L'n', L'\0' };
    static const wchar_t Nan[] = { L'N', L'A', L'N', L'\0' };
    static const wchar_t xdigs[] = { L'0', L'1', L'2', L'3', L'4', L'5', L'6', L'7', L'8', L'9', L'a', L'b', L'c', L'd', L'e', L'f' };
    static const wchar_t Xdigs[] = { L'0', L'1', L'2', L'3', L'4', L'5', L'6', L'7', L'8', L'9', L'A', L'B', L'C', L'D', L'E', L'F' };

    if (code == L'a' || code == L'A')
        ;
    else if (px->prec < 0)
        px->prec = 6;
    else if (px->prec == 0 && (code == L'g' || code == L'G'))
        px->prec = 1;

    if ((errx = __fpunscalel(&xexp, &px->v.ld)) == FP_NAN)
    {
        /* x == NaN */
        wmemcpy(px->s, (code == L'a' || code == L'e' || code == L'f' || code == L'g') ? nan : Nan, px->n1 = 3);
        return;
    }
    else if (errx > 0)
    {
        /* x == INF */
        wmemcpy(px->s, (code == L'a' || code == L'e' || code == L'f' || code == L'g') ? inf : Inf, px->n1 = 3);
        return;
    }

    if (code == L'a' || code == L'A')
    {
        /* put "0x" */
        *px->s++ = L'0';
        *px->s++ = (code == L'a') ? L'x' : L'X';
        px->n0 +=2;
    }

    if (errx == 0)  /* x == 0 */
    {
        nsig = 0, xexp = 0;
    }
    else if (code == L'a' || code == L'A')
    {
        /* 0 < |x|, generate hex fraction, binary exponent */
        const wchar_t *digits = (code == L'a') ? xdigs : Xdigs;
        int gen;

        nsig = (px->prec < 0) ? MAXDIG - NXDIG : px->prec + 1;
        gen = nsig + 1;
        ldval = (ldval < 0) ? -px->v.ld : px->v.ld;
        xexp -= 4;  /* one leading nonzero hex digit */

        for (*p++ = 0x0; 0 < gen && 0 < ldval; p += NXDIG)
        {
            /* convert NXDIG at a time */
            int j;
            long lo;

            __fpscalel(&ldval, 4 * NXDIG);

            lo = (long)ldval;

            if ((gen -= NXDIG) > 0)
                ldval -= (long double)lo;

            for (p += NXDIG, j = NXDIG; 0 < lo && 0 <= --j; )
                *--p = (int)(lo & 0xf), lo >>= 4;

            while (--j >= 0)
                *--p = 0;
        }

        gen = p - &ac[1];
        p = &ac[1];
        if (gen < nsig)
            nsig = gen;
        if (nsig >= 0)
        {
            /* round and strip trailing zeros */
            const char drop = (nsig < gen && p[nsig] >= 0x8) ? 0xf : 0x0;
            int n;

            for (n = nsig; p[--n] == drop; )
                --nsig;

            if (drop == 0xf)
                ++p[n];

            if (n < 0)
                --p, ++nsig, xexp += 4;

            for (n = nsig; 0 <= --n; )
                p[n] = digits[p[n]];
        }

        if (px->prec < 0)
            px->prec = nsig - 1;
    }
    else
    {
        /* 0 < |x|, generate decimal fraction and exponent */
        /* scale ldval to ~~10^(NDIG/2) */
        {
            int i, n;

            if (ldval < 0)
                ldval = -ldval;

            if ((xexp = xexp * 30103L / 100000L - NDIG / 2) < 0)
            {
                /* scale up */
                n = (-xexp + (NDIG / 2 - 1)) & ~(NDIG / 2 - 1);
                xexp = -n;
                for (i = 0; 0 < n; n >>= 1, ++i)
                    if (n & 1) ldval *= pows[i];
            }
            else if (xexp > 0)
            {
                /* scale down */
                long double factor = 1.0;

                xexp &= ~(NDIG / 2 - 1);
                for (n = xexp, i = 0; 0 < n; n >>= 1, ++i)
                    if (n & 1) factor *= pows[i];
                ldval /= factor;
            }
        }

        /* convert significant digits */
        {
            int gen = px->prec + (code == L'f' || code == L'F' ? xexp + 2 + NDIG : 2 + NDIG / 2);

            if (LDBL_DIG + NDIG / 2 < gen)
                gen = LDBL_DIG + NDIG / 2;

            for (*p++ = L'0'; 0 < gen && 0 < ldval; p += NDIG)
            {
                /* convert NDIG at a time */
                int j;
                long lo = (long)ldval;

                if ((gen -= NDIG) > 0)
                    ldval = (ldval - (long double)lo) * 1e8L;

                for (p += NDIG, j = NDIG; lo > 0 && --j >= 0; )
                {
                    /* convert NDIG digits */
                    ldiv_t qr = ldiv(lo, 10);
                    *--p = qr.rem + L'0', lo = qr.quot;
                }

                while (--j >= 0)
                    *--p = L'0';
            }

            gen = p - &ac[1];
            for (p = &ac[1], xexp += NDIG-1; *p == L'0'; ++p)
                --gen, --xexp;  /* correct xexp */
            nsig = px->prec + (code == L'f' || code == L'F' ? xexp + 1 : code == L'e' || code == L'E' ? 1 : 0);
            if (gen < nsig)
                nsig = gen;
            if (nsig >= 0)
            {
                /* round and strip trailing zeros */
                const char drop = (nsig < gen && L'5' <= p[nsig] && p[nsig] <= L'9') ? L'9' : L'0';
                int n;

                for (n = nsig; p[--n] == drop; )
                    --nsig;

                if (drop == L'9')
                    ++p[n];

                if (n < 0)
                    --p, ++nsig, ++xexp;
            }
        }
    }

    __wgenld(px, code, p, nsig, xexp);
}

