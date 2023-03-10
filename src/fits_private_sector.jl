# SPDX-License-Identifier: MIT

# ............................................ FITS private sector ................................................................

using Dates

# ........................................... cast filename into a FITSname object .................................

"""
    cast_FITS_name(str::String)

Decompose the FITS filename 'filnam.fits' into its name, prefix, numerator and extension.
#### Examples:
```
strExample = "T23.01.fits"
f = cast_FITS_name(strExample)
FITS_name("T23.01", "T23.", "01", ".fits")

f.name, f.prefix, f.numerator, f.extension
("T23.01", "T23.", "01", ".fits")
```
"""
function cast_FITS_name(str::String)

    Base.length(Base.strip(str)) == 0 && error("FitsError: filename required")

    ne = Base.findlast('.',str)                                     # ne: first digit of extension
    nl = Base.length(str)                                           # ne: length of file name including extension

    hasextension = isnothing(ne) ? false : true

    if hasextension
        strNam = str[1:ne-1]
        strExt = Base.rstrip(str[ne:nl])
        strExt = Base.Unicode.lowercase(strExt)
        isfits = strExt == ".fits" ? true : false
        n = Base.Unicode.isdigit(str[ne-1]) ? ne-1 : nothing        # n: last digit of numerator (if existent)
    else
        isfits = false
        n = Base.Unicode.isdigit(str[nl]) ? nl : nothing            # n: last digit of numerator (if existent)
    end

    isfits || error("FitsError: '$(str)': incorrect filename (lacks mandatory '.fits' extension)")

    if !isnothing(n)
        strNum = ""
        while Base.Unicode.isdigit(str[n])
            strNum = str[n] * strNum
            n -= 1
        end
        strPre = str[1:n]
    else
        strPre = strNam
        strNum = " "
    end

    return FITS_name(strNam,strPre,strNum,strExt)

end

# ........................................... cast records into a FITS_header object .................................

function _cast_header(records::Array{String,1}, hduindex::Int)

    records = _rm_blanks(records)         # remove blank records to collect header records data (key, val, comment)
    nrec = length(records)                # number of keys in header with given hduindex

    keys = [Base.strip(records[i][1:8]) for i=1:nrec]
    vals = [records[i][9:10] ≠ "= " ? records[i][11:31] : _fits_parse(records[i][11:31]) for i=1:nrec]
    coms = [records[i][34:80] for i=1:nrec]
    dict = [keys[i] => vals[i] for i=1:nrec]
    maps = [keys[i] => i for i=1:nrec]

    return FITS_header(hduindex,records,keys,vals,coms,Dict(dict),Dict(maps))

end

# .................................. cast data into FITS_data objects ....................................

function _cast_data(hduindex::Int, hdutype::String, data)

    return FITS_data(hduindex, hdutype, data)

end

function _fits_bzero(E::DataType)

    return E ∉ [Int8, UInt16, UInt32, UInt64, UInt128] ? 0.0 : E == Int8 ? -128 : 2^(8sizeof(E)-1)

end

function _fits_eltype(nbits::Int, bzero::Number)

    E = nbits ==   8 ? UInt8 :
        nbits ==  16 ? Int16 :
        nbits ==  32 ? Int32 :
        nbits ==  64 ? Int64 : Int64

    E = nbits == -32 ? Float32 :
        nbits == -64 ? Float64 : E

    E = bzero == 0.0 ? E : E == UInt8 ? Int8 :
                           E == Int16 ? UInt16 :
                           E == Int32 ? UInt32 :
                           E == Int64 ? UInt64 : E

    return E

end

function _fits_new_records(key::String, val::Any, com::String)

    k = _format_recordkey(key)
    v = _format_recordvalue(val)
    c = _format_recordcomment(com,val)

    records = length(v * c) > 67 ? _format_recordslongstring(k, v, c) : [(k * "= " * v * " / " * c)]

    return records

end

function _fits_obsolete_records(h::FITS_header, recordindex::Int)

    n = recordindex

    if typeof(h.values[n]) <: AbstractString
       while (h.comments[n][end-1:end] == "&'") | (h.keys[n+1] == "CONTINUE")
          n += 1
       end
    end

    records = [h.records[i] for i=recordindex:n]

    return records

end

function _fits_parse(str::String) # routine

    T = Float32
    s = Base.strip(str)
    c = Base.collect(s)
    l = Base.length(s)

    Base.length(s) == 0 && return 0

    d = [Base.Unicode.isdigit(c[i]) for i ∈ Base.eachindex(c)]  # d: digits
    p = [Base.Unicode.ispunct(c[i]) for i ∈ Base.eachindex(c)]  # p: punctuation

    s[1] == '\'' && return str
    s[1] == '-'  && (d[1] = true) && (p[1] = false)     # change leading sign into digit (for type parsing only)
    s[1] == '+'  && (d[1] = true) && (p[1] = false)     # change leading sign into digit (for type parsing only)

    a = p .== d                                         # a: other non-digit or punctuation characters

    ia = [i for i ∈ Base.eachindex(a) if a[i]==1]       # ia: indices of nonzero elements of a
    ip = [i for i ∈ Base.eachindex(p) if p[i]==1]       # ip: indices of nonzero elements of p

    sd = Base.sum(d)                                    # sd: number of digits
    sp = Base.sum(p)                                    # sd: number of punctuation characters
    sa = Base.sum(a)                                    # sa: number of other non-digit or punctuation characters

    E = ['E','D','e','p']

    sd == l && return Base.parse(Int,s)
    sa >= 2 && return str
    sp >= 3 && return str
    sa == 1 && s == "T" && return true
    sa == 1 && s == "F" && return false
    sa == 0 && sp == 1 && s[ip[1]] == '.' && return Base.parse(T,s)
    sp == 0 && sa == 1 && s[ia[1]] ∈ E && return Base.parse(T,s)
    sp == 1 && s[ip[1]] == '-' && s[ip[1]-1] ∈ E && return Base.parse(T,s)
    sp == 1 && s[ip[1]] == '.' && s[ia[1]] ∈ E && ip[1] < ia[1]  && return Base.parse(T,s)
    sp == 2 && s[ip[1]] == '.' && s[ip[2]] == '-' && s[ip[2]-1] ∈ E && ip[1] < ia[1]  &&  return Base.parse(T,s)

    return error("FitsError: $(str): parsing error")

end

function _format_key(key::String)::String

    key = Base.Unicode.uppercase(Base.strip(key))

    length(key) > 8 && error("FitsError: '$(key)': length exceeds 8 characters (FITS standard)")

    return key

end

function _format_recordcomment(com::String,val::Any)::String

    strErr = "FitsWarning: record truncated at 80 characters (FITS standard)"

    c = strip(com)
    v = _format_recordvalue(val)
    T = typeof(val)

    (T <: DateTime) | (T <: Real) ? (length(v * c) > 67 ? (c = c[1:67-length(v)]; println(strErr)) : 0) : 0

    return length(c) > 47 ? com : rpad(c,67-length(v))

end

function _format_recordkey(key::String)

    return rpad(key,8)

end

function _format_recordslongstring(key::String, val::AbstractString, com::String)

    lcom = length(com)
    last = lcom > 0 ? "&'" : "'"
    lval = length(val)

    records = [(key * "= " * val)]

    if  lval < 70
        records[1] = rpad(records[1][1:end-1] * last,80)
    elseif (lval == 70)
        chr = records[1][end-1]
        records[1] = records[1][1:end-2] * last
        Base.push!(records,rpad(("CONTINUE  '" * chr * last),80))
    elseif lval > 70
         val = val[1:end-1]
        lval = length(val)
        nrec = (length(val)-68)÷67 + 1
        nrec > 1 ? [push!(records,("CONTINUE  '" * val[68i+2-i:68(i+1)-i] * "&'")) for i=1:nrec-1] : 0
         val = val[68(nrec)+2-nrec:end]; lval = length(val)
        (lcom == 0) & (lval == 1) ? (records[end] = records[end][1:end-2] * val * "'"; lval  =0) : 0
        lval > 0 ? Base.push!(records,rpad(("CONTINUE  '" * val * last),80)) : 0
    end

    if lcom <= 65
        Base.push!(records, rpad("CONTINUE  '' / " * com,80))
    else
        ncom = lcom÷64 + 1
        ncom > 1 ? [push!(records,"CONTINUE  '&' / " * com[64i+1:64(i+1)]) for i=0:ncom-2] : 0
        Base.push!(records,rpad("CONTINUE  '' / " * com[64(ncom-1)+1:end],80))
    end

    return records

end

function _format_recordvalue(val::Any)

    typeof(val) <: AbstractChar && error("FitsError: '$(val)': invalid record value (not 'numeric', 'date' or 'single quote' delimited string')")
    typeof(val) <: AbstractString ? (length(val) > 1 ? true : error("FitsError: string value not delimited by single quotes")) : 0

    typeof(val) <: AbstractString && return _format_recordvalue_charstring(val)
    typeof(val) <: DateTime && return _format_recordvalue_datetime(val)
    typeof(val) <: Real   && return _format_recordvalue_numeric(val)

    return error("FitsError: '$(val)' invalid record value type")

end

function _format_recordvalue_charstring(val::AbstractString)

    isascii(val) || error("FitsError: string not standard ASCII")

    isasciiprintable = !convert(Bool,sum(.!(31 .< Int.(collect(val)) .< 127)))

    isasciiprintable || error("FitsError: string not printable (not restricted to ASCII range 32-126)")

    v = (strip(val))

    (v[1] == '\'') & (v[end] == '\'') || error("FitsError: string value not delimited by single quotes")

    recordvalue = length(v) == 10 ? rpad(v,20) : length(v) < 21 ? rpad(v[1:end-1],19) * "'" : val

    return recordvalue

end

function _format_recordvalue_datetime(val::Dates.DateTime)

    return "'" * string(val) * "'"

end

function _format_recordvalue_numeric(val::Real)

    val = typeof(val) != Bool ? string(val) : val == true ? "T" : "F"

    return lpad(val,20)

end

function _hdu_count(o::IO)

    h = _header_pointers(o::IO)                 # h: start-of-header pointers

    return length(h)                            # number of HDUs

end

function _isavailable(filename::String, protect::Bool)

     return (!Base.Filesystem.isfile(filename) | !protect)

end

function _rm_blanks(records::Array{String,1})               # remove blank records

    record_B = repeat(' ',length(records[1]))

    return [records[i] for i ∈ findall(records .≠ record_B)]

end

function _validate_FITS_name(filename::String)

    return cast_FITS_name(filename)

end
