# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            test_fits_format.jl
#                          Jook Walraven 22-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                      fits_verifier(filnam; msg=true)
#
# - to verrify FITS format of existing file
# ------------------------------------------------------------------------------

function fits_verifier(filnam::String; msg=true)

    msg && println("fits_verifier: " * filnam)

    isfile(filnam) || return println("file not found")

    passed = Bool[]

    push!(passed, _filnam_test(filnam; protect=false, msg))
    push!(passed, _block_test(filnam; msg))

    f = fits_read(filnam)

    for i ∈ eachindex(f.hdu)
        msg && println("HDU-$i:")
        append!(passed, _record_count(f.hdu[i]; msg))
    end

    return sum(.!passed)

end

# ------------------------------------------------------------------------------
#               test 1: _filnam_test(filnam; protect=false, msg=true)
# ------------------------------------------------------------------------------

function _filnam_test(filnam::String; protect=false, msg=true)

    err = _err_FITS_filnam(filnam::String; protect)

    F = cast_FITS_test(1, err)

    if msg
        str = F.passed ? "Passed " : "Failed "
        str *= F.name * ":" * repeat(' ', 20 - length(F.name))
        str *= err == 0 ? F.msgpass :
               err == 1 ? F.msgfail :
               err == 2 ? F.msgwarn :
               err == 3 ? F.msgwarn :
               err == 4 ? F.msghint : "err $(err) not found"
        println(str)
    end

    return F.passed

end

# ------------------------------------------------------------------------------
#                       test 2: _block_test(filnam)
# ------------------------------------------------------------------------------

function _block_test(filnam::String; msg=true)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    err = remain > 0 ? 1 : 0

    F = cast_FITS_test(2, err)

    if msg
        str = F.passed ? "Passed " : "Failed "
        str *= F.name * ":" * repeat(' ', 20 - length(F.name))
        str *= (err == 0 ? F.msgpass : F.msgfail)
        println(str)
    end

    return F.passed

end

# ------------------------------------------------------------------------------
#                        test 3: _record_count(hdu)
# ------------------------------------------------------------------------------

function _record_count(hdu::FITS_HDU; msg=true)

    typeof(hdu) <: FITS_HDU || error("Error: FITS_HDU not found")

    card = hdu.header.card
    hduindex = hdu.header.hduindex

    nrec = length(card)
    nblock = nrec ÷ 36
    remain = nrec % 36

    err = remain > 0 ? 1 : 0

    F = cast_FITS_test(3, err)

    if msg
        str = F.passed ? "Passed " : "Failed "
        str *= F.name * ":" * repeat(' ', 20 - length(F.name))
        str *= (err == 0 ? F.msgpass : F.msgfail)
        println(str)
    end

    return F.passed

end



function _passed_filnam_test(filnam::String)

    err = _err_FITS_filnam(filnam)

    if err === 0
        str = "$(filnam) - passed name test:    "
        str *= "file exists, has valid name and may be overwritten."
    elseif err === 1
        str = "$(filnam) - failed name test:    " * msgError(err)
    elseif err === 2
        str = "$(filnam) - failed name test:    " * msgError(err)
    elseif err === 3
        str = "$(filnam) - failed name test:    " * msgError(err)
    elseif err === 4
        str = "$(filnam) - passed name test:    "
        str *= "file exists and has valid name "
        str *= "- use ';protect=false' to lift overwrite protection."
    end

    println(str)

    passed = err === 0 ? true : err === 4 ? true : false

    return passed

end


function _passed_block_test(filnam::String) #_testIORead(filnam::String)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    txt = nblock > 1 ? "blocks " : "block "

    if remain > 0
        err = 6 # FITS format requires integer number of blocks (of 2880 bytes)
        str = "$(filnam) - failed block test:    " * msgError(err)
    else
        err = 0
        str = "$(filnam) - passed block test:    "
        str *= "file consists of exactly $(nblock) " * txt
        str *= "(of 2880 bytes)."
    end

    println(str)

    passed = err > 0 ? false : true

    return passed

end

function _passed_record_count(hdu::FITS_HDU)

    typeof(hdu) <: FITS_HDU || error("Error: FITS_HDU not found")

    records = hdu.header.records
    hduindex = hdu.header.hduindex

    nrec = length(records)
    nblock = nrec ÷ 36
    remain = nrec % 36

    txt = nblock > 1 ? "blocks " : "block "

    if remain > 0
        err = 8 # header shall consist of integer number of blocks (of 36 records)
        str = "HDU$(hduindex) - header failed block test:    "
        str *= msgError(err)
        str *= " - nrec = $(nrec), nblock = $(nblock), remainder = $(remain)"
    else
        err = 0
        str = "HDU$(hduindex) - header passed block test:    "
        str *= "HDU consists of exactly $(nblock) " * txt
        str *= "(of 36 records of 80 bytes)."
    end

    println(str)

    passed = err > 0 ? false : true

    return passed

end

function _passed_ASCII_test(hdu::FITS_HDU)

    typeof(hdu) <: FITS_HDU || error("Error: FITS_HDU not found")

    hduindex = hdu.header.hduindex
    records = hdu.header.records

    recvals = join(records)
    isascii = !convert(Bool, sum(.!(31 .< Int.(collect(recvals)) .< 127)))

    if isascii
        err = 0
        str = "HDU$(hduindex) - header passed ASCII test:    "
        str *= "header contains only the restricted set of ASCII text characters, decimal 32 through 126."
    else
        err = 9 # header blocks shall contain only the restricted set of ASCII text characters, decimal 32 through 126
        str = "HDU$(hduindex) - header failed ASCII test:    "
        str *= msgError(err)
    end

    println(str)

    passed = err > 0 ? false : true

    return passed

end

function _passed_keyword_test(hdu::FITS_HDU)

    typeof(hdu) <: FITS_HDU || error("Error: FITS_HDU not found")

    hduindex = hdu.header.hduindex
    records = hdu.header.records

    recs = _rm_blanks(records)         # remove blank records to collect header records data (key, val, comment)
    nrec = length(recs)                # number of keys in header with given hduindex

    keys = [Base.strip(records[i][1:8]) for i = 1:nrec]
    vals = [records[i][9:10] ≠ "= " ? records[i][11:31] :
            _fits_parse(records[i][11:31]) for i = 1:nrec]

    err = 0

    if hduindex == 1
        err = keys[1] == "SIMPLE" ? 0 : 1
        err += keys[2] == "BITPIX" ? 0 : 1
        err += keys[3] == "NAXIS" ? 0 : 1
        for i = 1:vals[3]
            err += keys[3+i] == "NAXIS$i" ? 0 : 1
        end
    else
        err = keys[1] == "XTENSION" ? 0 : 1
        err += keys[2] == "BITPIX" ? 0 : 1
        err += keys[3] == "NAXIS" ? 0 : 1
        for i = 1:vals[3]
            err += keys[3+i] == "NAXIS$i" ? 0 : 1
        end
        err += keys[3+vals[3]+1] == "PCOUNT  " ? 0 : 1
        err += keys[3+vals[3]+2] == "GCOUNT  " ? 0 : 1
    end

    if err == 0
        str = "HDU$(hduindex) - header passed keyword test:    "
        str *= "mandatory keywords all present and in proper order."
    else
        err = 11 # mandatory keyword not present or out of order
        str = "HDU$(hduindex) - header failed keyword test:    "
        str *= msgError(err)
    end

    println(str)

    passed = err > 0 ? false : true

    return passed

end

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
    X = Base.Unicode.uppercase(keyword[1])

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
TFORMn, THEAP, TNULLn, TSCALn, TTYPEn, TUNITn, TZEROn, XTENSION.

The descriptions are based on appendix C to [FITS standard - version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html),
which is *not part of the standard but included for convenient reference*.
```
julia> fits_keyword("END");
KEYWORD:    END
REFERENCE:  FITS Standard - version 4.0 - Appendix C
CLASS:      general
STATUS:     mandatory
HDU:        primary, groups, extension, array, image, ASCII-table, bintable,
VALUE:      none
DEFAULT:    none
COMMENT:    marks the end of the header keywords
DEFINITION: This keyword has no associated value.  Columns 9-80 shall be filled with ASCII blanks.

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
    #o[7] ≠ "" ? (str *= "\n" * o[7]) : false
    str *= "\nDEFAULT:    " * o[7]
    str *= "\nCOMMENT:    " * o[8]
    str *= "\nDEFINITION: " * o[9]

    msg && println(str)

    return str

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
    str *= "'primary', 'extension', 'array', 'image', 'ASCII-table', 'bintable'"
    str *= "\n\nreference: " * _fits_standard

    return msg ? println(str) : str

end
function _primary_hdu()

end
function fits_reserved_keywords(hdu::FITS_HDU)

    hdutype = hdu.dataobject.hdutype

    hdutype == "PRIMARY" && return _primary_hdu()

end
