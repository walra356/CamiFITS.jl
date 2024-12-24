# SPDX-License-Identifier: MIT

# Copyright (c) 2024 Jook Walraven <69215586+walra356@users.noreply.github.com> and contributors

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ------------------------------------------------------------------------------
#                            test_fits_format.jl
# ------------------------------------------------------------------------------

# ==============================================================================
#                               fits_terminology()
# ..............................................................................
function _suggest(dict::Dict, term::String; test=false)

    o = sort(collect(keys(dict)))
    a = [o[i][1] for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(term[1])

    itr = findall(x -> x == X, a)

    str = term * ":"
    str *= "\nNot one of the FITS defined terms."
    str *= "\nsuggestions: "
    for i ∈ itr
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]
    str *= "\n\nreference: " * _fits_standard

    return test ? true : str

end
@doc raw"""
    fits_terminology([term::String [; test=false]])

Description of the *defined terms* from [FITS standard](https://fits.gsfc.nasa.gov/fits_standard.html): 

ANSI, ASCII, ASCII NULL, ASCII character, ASCII digit, ASCII space, ASCII text, 
Array, Array value, Basic FITS, Big endian, Bit, Byte, Card image, 
Character string, Conforming extension, Data block, Deprecate, Entry, 
Extension, Extension type name, FITS, FITS Support Office, FITS block, 
FITS file, FITS structure, Field, File, Floating point, Fraction, 
Group parameter value, HDU Header and Data Unit., Header, Header block, Heap, 
IAU, IAUFWG, IEEE, IEEE NaN, IEEE special values, Indexed keyword, 
Keyword name, Keyword record, MEF, Mandatory keyword, Mantissa, NOST, 
Physical value, Pixel, Primary HDU, Primary data array, Primary header, 
Random Group, Record, Repeat count, Reserved keyword, SIF, Special records, 
Standard extension.
```
julia> fits_terminology()
FITS defined terms:
ANSI, ASCII, ASCII NULL, ASCII character, ..., SIF, Special records, Standard extension.

julia> fits_terminology("FITS")
FITS:
Flexible Image Transport System.

julia> get(dictDefinedTerms, "FITS", nothing)
"Flexible Image Transport System."

julia> fits_terminology("p")
p:
Not one of the FITS defined terms.
suggestions: Physical value, Pixel, Primary HDU, Primary data array, Primary header.

see FITS Standard - https://fits.gsfc.nasa.gov/fits_standard.html
```
"""
function fits_terminology(term::String; test=false)

    term = isnothing(term) ? "" : term
    dict = dictDefinedTerms

    length(term) > 0 || return fits_terminology()

    o = sort(collect(keys(dict)))
    u = [Base.uppercase(o[i]) for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(term)

    itr = findall(x -> x == X, u)

    str = length(itr) == 0 ? _suggest(dict::Dict, term::String; test) :
          (o[itr][1] * ":\n" * Base.get(dict, o[itr][1], nothing))

    test ? (return str) : println(str)

end
function fits_terminology(; test=false)

    dict = dictDefinedTerms

    o = sort(collect(keys(dict)))

    str = "FITS defined terms:\n"
    for i ∈ eachindex(o)
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]
    str *= "\n\nreference: " * _fits_standard

    test ? true : println(str)

end


# ==============================================================================
#                            fits_keyword(keyword)
# ------------------------------------------------------------------------------

function _suggest_keyword(dict::Dict, keyword::String; msg=true)

    o = sort(collect(keys(dict)))
    u = [o[i][1] for i ∈ eachindex(o)]
    keyword = _format_keyword(keyword)
    X = keyword[1]

    itr = findall(x -> x == X, u)

    str = keyword * ": "
    str *= "Not recognized as a FITS defined keyword"
    str *= "\nsuggestions: "
    for i ∈ itr
        str *= o[i]
        str *= ", "
    end

    str = str[1:end-2]
    str *= "\n\nreference: " * _fits_standard

    return msg ? println(str) : str

end
# ------------------------------------------------------------------------------
function _keywords(str, o, class, status, hdutype)

    for i ∈ eachindex(o)
        if (o[i][3] == class) & (o[i][4] == status) & (hdutype ∈ o[i][5])
            str *= (isone(i) ? "(blanks) " : rpad(o[i][1], 9))
        end
    end

    return str

end
# ------------------------------------------------------------------------------
function _all_keywords(; msg=true)

    dict = dictDefinedKeywords

    o = sort(collect(keys(dict)))

    str = "FITS defined keywords:\n\n"
    for i ∈ eachindex(o)
        str *= fits_keyword(o[i]; msg=false)
        str *= "\n\n"
    end

    return msg ? println(str) : str

end
# ------------------------------------------------------------------------------
@doc raw"""
    fits_keyword(keyword::String [; msg=true])
    fits_keyword([; hdutype="all" [, msg=true]])

Description of the *reserved keywords* of the [FITS standard](https://fits.gsfc.nasa.gov/fits_standard.html):

(blanks), ALL, AUTHOR, BITPIX, BLANK, BLOCKED, BSCALE, BUNIT, BZERO, CDELTn, 
COMMENT, CROTAn, CRPIXn, CRVALn, CTYPEn, DATAMAX, DATAMIN, DATE, DATE-OBS,
END, EPOCH, EQUINOX, EXTEND, EXTLEVEL, EXTNAME, EXTVER, GCOUNT, GROUPS,
HISTORY, INSTRUME, NAXIS, NAXISn, OBJECT, OBSERVER, ORIGIN, PCOUNT, PSCALn,
PTYPEn, PZEROn, REFERENC, SIMPLE, TBCOLn, TDIMn, TDISPn, TELESCOP, TFIELDS,
TFORMn, THEAP, TNULLn, TSCALn, TTYPEn, TUNITn, TZEROn, XTENSION,

where `n = 1,...,nmax` as specified for the keyword. Use the `keyword` "ALL" 
to dump the full list of keyword descriptions.

The descriptions are based on appendix C to [FITS standard - version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html),
which is *not part of the standard but included for convenient reference*.
```
julia> fits_keyword("naxisn");
KEYWORD:    NAXISn
REFERENCE:  FITS Standard - version 4.0 - Appendix C
CLASS:      general
STATUS:     mandatory
HDU:        primary, groups, extension, array, image, ASCII-table, bintable,
VALUE:      integer
RANGE:      [0:]
COMMENT:    size of the axis
DEFINITION: The value field of this indexed keyword shall contain a non-negative integer,  
representing the number of elements along axis n of a data array.
The NAXISn must be present for all values n = 1,...,NAXIS, and for no other values of n.   
A value of zero for any of the NAXISn signifies that no data follow the header in the HDU. 
If NAXIS is equal to 0, there should not be any NAXISn keywords.

julia> fits_keyword()
FITS defined keywords:
(blanks) AUTHOR   BITPIX   BLANK    BLOCKED  BSCALE   BUNIT    BZERO    
CDELTn   COMMENT  CROTAn   CRPIXn   CRVALn   CTYPEn   DATAMAX  DATAMIN  
DATE     DATE-OBS END      EPOCH    EQUINOX  EXTEND   EXTLEVEL EXTNAME  
EXTVER   GCOUNT   GROUPS   HISTORY  INSTRUME NAXIS    NAXISn   OBJECT   
OBSERVER ORIGIN   PCOUNT   PSCALn   PTYPEn   PZEROn   REFERENC SIMPLE   
TBCOLn   TDIMn    TDISPn   TELESCOP TFIELDS  TFORMn   THEAP    TNULLn   
TSCALn   TTYPEn   TUNITn   TZEROn   XTENSION

HDU options: 'primary', 'extension', 'array', 'image', 'ASCII-table', 'bintable'

reference: FITS Standard - version 4.0 - Appendix C
```
"""
function fits_keyword(keyword::String; msg=true)

    keyword = keyword ≠ "all" ? strip(keyword) : return _all_keywords(; msg)
    keyword = keyword == "" ? repeat(' ', 8) : keyword

    dict = dictDefinedKeywords

    o = sort(collect(keys(dict)))
    u = [Base.uppercase(o[i]) for i ∈ eachindex(o)]
    X = Base.Unicode.uppercase(keyword)

    itr = findall(x -> x == X, u)

    length(itr) ≠ 0 || return _suggest_keyword(dict, X; msg)

    o = Base.get(dict, o[itr][1], nothing)

    str = "KEYWORD:    " * o[1]
    str *= "\nREFERENCE:  " * o[2]
    str *= "\nCLASS:      " * o[3]
    str *= "\nSTATUS:     " * o[4]
    str *= "\nHDU:        " * join([o[5][i] * ", " for i ∈ eachindex(o[5])])
    str *= "\nVALUE:      " * o[6]
    o[7] ≠ "" ? (str *= "\n" * o[7]) : false
    o[8] ≠ "" ? (str *= "\nDEFAULT:    " * o[8]) : false
    str *= "\nCOMMENT:    " * o[9]
    str *= "\nDEFINITION: " * o[10]

    return msg ? println(str) : str

end
function fits_keyword(; hdutype="all", msg=true)

    dict = dictDefinedKeywords

    k = sort(collect(keys(dict)))
    o = [Base.get(dict, k[:][i], nothing) for i ∈ eachindex(k)]

    str = "FITS defined keywords:\n"
    if hdutype == "all"
        for i ∈ eachindex(o)
            str *= (isone(i) ? "(blanks) " : rpad(o[i][1], 9))
            iszero(i % 8) ? str = str * "\n" : false
        end
    else
        str *= "HDU type: '" * hdutype * "'"
        str *= "\n- general\n"
        str *= "  - mandatory: "
        str = _keywords(str, o, "general", "mandatory", hdutype)
        str *= "\n  - reserved : "
        str = _keywords(str, o, "general", "reserved", hdutype)

        str *= "\n- bibliographic\n"
        str *= "  - mandatory: "
        str = _keywords(str, o, "bibliographic", "mandatory", hdutype)
        str *= "\n  - reserved : "
        str = _keywords(str, o, "bibliographic", "reserved", hdutype)

        str *= "\n- commentary\n"
        str *= "  - mandatory: "
        str = _keywords(str, o, "commentary", "mandatory", hdutype)
        str *= "\n  - reserved : "
        str = _keywords(str, o, "commentary", "reserved", hdutype)

        str *= "\n- observation\n"
        str *= "  - mandatory: "
        str = _keywords(str, o, "observation", "mandatory", hdutype)
        str *= "\n  - reserved : "
        str = _keywords(str, o, "observation", "reserved", hdutype)
    end

    str *= "\n\nHDU options: "
    str *= "'PRIMARY ', "
    str *= "'IMAGE   ', "
    str *= "'ARRAY   ', "
    str *= "'TABLE   ', "
    str *= "'BINTABLE'"
    str *= "\n\nreference: " * _fits_standard

    return msg ? println(str) : str

end
function fits_mandatory_keyword(hdu::FITS_HDU)

    hdutype = hdu.dataobject.hdutype

    dict = dictDefinedKeywords

    k = sort(collect(keys(dict)))
    o = [Base.get(dict, k[:][i], nothing) for i ∈ eachindex(k)]

    u = []
    class = "general"
    status = "mandatory"
    for i ∈ eachindex(o)
        if (o[i][3] == class) & (o[i][4] == status) & (hdutype ∈ o[i][5])
            push!(u, o[i][1])
        end
    end

    return u

end