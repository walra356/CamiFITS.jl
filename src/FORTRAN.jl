# ....................................................... FORTRAN-format object .............................................................................

"""
    FORTRAN_format

Object to hold a FORTRAN format specifier decomposed in its fields.

Accepted *datatype specifiers* are:  `Aw`,  `Iw`,  `Fw.d`,  `Ew.d`,  `Dw.d`

Accepted *output formating specifiers* are: `Aw`,  `Iw.m`,  `Bw.m`,  `Ow.m`,
`Zw.m`,  `Fw.d`,  `Ew.dEe`,  `ENw.d`,  `ESw.d`,  `Gw.dEe`,  `Dw.dEe`.
Notation: `w` - width, `m` (optional) - minimum number of digits, `d` - number
of digits to right of decimal, `e` - number of digits in exponent `N`/`S`
(optional) indicates engineering/scientific formating of the `E` type.

The fields are:
* `.Type`: primary FORTRAN datatype (`::String`)
* `.TypeChar`: primary FORTRAN datatype character (`::Char`)
* `.EngSci`: secundary datatype character - N for engineering/ S for scientific (`::Union{Char,Nothing}`)
* `.width`: width of numeric field (`::Int`)
* `.nmin`: minimum number of digits displayed (`::Int`)
* `.ndec`: number of digits to right of decimal (`::Int`)
* `.nexp`: number of digits in exponent (`::Int`)
"""
struct FORTRAN_format

    Type::String
    TypeChar::Char
    EngSci::Union{Char,Nothing}
    width::Int
    nmin::Int
    ndec::Int
    nexp::Int

end

# ................... cast format or datatype string 'format' into FORTRAN_format object ...........................

"""
    cast_FORTRAN_format(format::String)

Decompose the format specifier `format` into its fields and cast this into the
[`FORTRAN_format`](@ref) object. Allowed format specifiers are of the types:
`Aw`, `Iw.m`, `Bw.m`, `Ow.m`, `Zw.m`, `Fw.d`, `Ew.dEe`, `ENw.d`, `ESw.d`,
`Gw.dEe`, `Dw.dEe`, with: `w` - width, `m `(optional) - minimum number of
digits, `d` - number of digits to right of decimal, `e` - number of digits in
exponent; `N`/`S` (optional) indicates engineering/scientific formating of
the `E` type.
#### Examples:
```
f = cast_FORTRAN_format("I10")
  FORTRAN_format("Iw", 'I', nothing, 10, 0, 0, 0)

f = cast_FORTRAN_format("I10.12")
  FORTRAN_format("Iw.m", 'I', nothing, 10, 12, 0, 0)

f = cast_FORTRAN_format("E10.5E3")
  FORTRAN_format("Ew.dEe", 'E', nothing, 10, 0, 5, 3)

f.Type, f.TypeChar, f.EngSci, f.width, f.nmin, f.ndec, f.nexp
  ("Ew.dEe", 'E', nothing, 10, 0, 5, 3)
```
"""
function cast_FORTRAN_format(str::String)

    s = strip(str,['\'',' ']); w = m = d = e = 0

    strErr = "FitsError: $s: not a valid FORTRAN print format "
    accept = ['A','I','B','O','Z','F','E','G','D','N','S','.','1','2','3','4','5','6','7','8','9','0']

    sum([s[i] ∉ accept for i ∈ eachindex(s)]) == 0 ? n=length(s) : return error(strErr * "(unknown type character)")
    n > 1 ?  X = s[1] : return error(strErr * " (width field not specified)")
    s[2] ∈ ['N','S'] ? (ns = s[2]; i = 3) : (ns = nothing; i = 2)
    rst = s[i:end]; length(rst) < 1 && return error(strErr * "(decimal side not specified)")

    if !occursin('.', rst)
        sum(.!isnumeric.(collect(rst))) > 0 && return error(strErr)
        X ∈ ['A','I','B','O','Z'] ? (t = X * "w"; w = parse(Int,rst)) : 0
        X ∈ ['F','E','G','D'] && return error(strErr * "(decimal field not specified)")
    else
        X ∈ ['A'] && return error(strErr * "(decimal point incompatible with $X type)")
        spl = split(rst,'.'); length(spl) > 2 && return error(strErr * "(two decimal points not allowed)")
        lhs = spl[1]
        rhs = spl[2]
        length(lhs) < 1 && return error(strErr * "(width field not specified)")
        length(rhs) < 1 && return error(strErr * "(decimal side not specified)")
        sum(.!isnumeric.(collect(lhs))) > 0 && return error(strErr * "(width field not numeric)")

        if !occursin('E',rhs)
            sum(.!isnumeric.(collect(rhs))) > 0 && return error(strErr * "(decimal field not numeric)")
            x = isnothing(ns) ? "" : ns
            X ∈ ['E','G','D'] ? (t = X * x * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
        else
            X ∈ ['F','I','B','O','Z'] && return error(strErr * "(exponent incompatible with $X type)")
            splE = split(rhs,'E'); length(splE) > 2 && return error(strErr * "(unexpected E character)")
            rhs1 = splE[1]
            rhs2 = splE[2]
            length(rhs1) < 1 && return error(strErr * "(decimal field not specified)")
            length(rhs2) < 1 && return error(strErr * "(exponent field not specified)")
            sum(.!isnumeric.(collect(rhs1))) > 0 && return error(strErr * "(decimal field not numeric)")
            sum(.!isnumeric.(collect(rhs2))) > 0 && return error(strErr * "(exponent field not numeric)")
            X ∈ ['E','G','D'] ? (t = X * "w.dEe"; w = parse(Int,lhs); d = parse(Int,rhs1); e = parse(Int,rhs2)) : 0
        end
        X ∈ ['I','B','O','Z'] ? (t = X * "w.m"; w = parse(Int,lhs); m = parse(Int,rhs)) : 0
        X ∈ ['F'] ? (t = X * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
    end

    return FORTRAN_format(t,X,ns,w,m,d,e)

end


"""
    cast_FORTRAN_datatype(format::String)

Decompose the format specifier `format` into its fields and cast this into the
[`FORTRAN_format`](@ref) object. Allowed format specifiers are of the types:
`Aw`, `Iw`, `Fw.d`, `Ew.d`, `Dw.d`, where: `w` - width, `d` - number of digits
to right of decimal point.
#### Examples:
```
f = cast_FORTRAN_datatype("I10")
  FORTRAN_format("Iw", 'I', nothing, 10, 0, 0, 0)

f = cast_FORTRAN_datatypet("F10.4")
  FORTRAN_format("Fw.d", 'F', nothing, 10, 0, 4, 0)

f = cast_FORTRAN_datatype("E10.5")
  FORTRAN_format("Ew.d", 'E', nothing, 10, 0, 5, 0)

f.Type, f.TypeChar, f.EngSci, f.width, f.nmin, f.ndec, f.nexp
  ("Ew.d", 'E', nothing, 10, 0, 5, 0)
```
"""
function cast_FORTRAN_datatype(str::String)

    s = strip(str,['\'',' ']); w = d = 0

    strErr = "FitsError: $s: not a valid FORTRAN datatype "
    accept = ['A','I','F','E','D','.','1','2','3','4','5','6','7','8','9','0']

    sum([s[i] ∉ accept for i ∈ eachindex(s)]) == 0 ? n=length(s) : return error(strErr * "(unknown type character)")
    n > 1 ?  X = s[1] : return error(strErr * " (width field not specified)")
    rst = s[2:end]; length(rst) < 1 && return error(strErr * "(decimal side not specified)")

    if !occursin('.', rst)
        sum(.!isnumeric.(collect(rst))) > 0 && return error(strErr)
        X ∈ ['A','I'] ? (t = X * "w"; w = parse(Int,rst)) : 0
        X ∈ ['F','E','D'] && return error(strErr * "(decimal field not specified)")
    else
        X ∈ ['A','I'] && return error(strErr * "(decimal point incompatible with $X type)")
        spl = split(rst,'.'); length(spl) > 2 && return error(strErr * "(two decimal points not allowed)")
        lhs = spl[1]
        rhs = spl[2]
        length(lhs) < 1 && return error(strErr * "(width field not specified)")
        length(rhs) < 1 && return error(strErr * "(decimal side not specified)")
        sum(.!isnumeric.(collect(lhs))) > 0 && return error(strErr * "(width field not numeric)")

        sum(.!isnumeric.(collect(rhs))) > 0 && return error(strErr * "(decimal field not numeric)")
        X ∈ ['E','D'] ? (t = X * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
        X ∈ ['F'] ? (t = X * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
    end

    return FORTRAN_format(t,X,nothing,w,0,d,0)

end
