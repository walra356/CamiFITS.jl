# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            read_IO.jl
#                        Jook Walraven 19-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                     IORead(filnam::String)
# 
#   - read filnam from disc 
#   - test for integral number of blocks of 2880 bytes/block
# ------------------------------------------------------------------------------  

function IORead(filnam::String)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

    return o

end

# ------------------------------------------------------------------------------
#                   _read_header(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------

function _read_header(o::IO, hduindex::Int)

    ptrhdu = _hdu_pointer(o)
    ptrdat = _data_pointer(o)

    Base.seek(o, ptrhdu[hduindex])

    record::Vector{String} = []

    for i = (ptrhdu[hduindex]÷80+1):(ptrdat[hduindex]÷80)
        rec = String(Base.read(o, 80))
        Base.push!(record, rec)
    end

    return cast_FITS_header(record)

end

# ------------------------------------------------------------------------------
#                   _read_hdu(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------  

function _read_hdu(o::IO, hduindex::Int)  # read data using header information

    h = _read_header(o, hduindex) #  FITS_header

    hdutype = h.card[1].keyword == "XTENSION" ? h.card[1].value : "'PRIMARY '"
    hdutype = Base.strip(hdutype)
    hdutype = Base.Unicode.uppercase(hdutype)

    if     hdutype == "'PRIMARY '"
        data = _read_image_data(o, hduindex)
    elseif hdutype == "'IMAGE   '"
        data = _read_image_data(o, hduindex)
    elseif hdutype == "'TABLE   '"
        data = _read_table_data(o, hduindex)
    elseif hdutype == "'BINTABLE'"
        data = _read_bintable_data(o, hduindex)
    else
        Base.throw(FITSError(msgErr(25)))
    end

    dataobject = FITS_dataobject(hdutype, data)

    return FITS_HDU(hduindex, h, dataobject)

end

# ------------------------------------------------------------------------------
#                   _read_image_data(o::IO, hduindex::Int)
#
#   - reads image data in accordance with header information
# ------------------------------------------------------------------------------  

function _fits_type(bitpix::Int)

    T = bitpix == 8 ? UInt8 :
        bitpix == 16 ? Int16 :
        bitpix == 32 ? Int32 :
        bitpix == 64 ? Int64 :
        bitpix == -32 ? Float32 :
        bitpix == -64 ? Float64 : Base.throw(FITSError(msgErr(42)))

    return T

end
# ------------------------------------------------------------------------------
function _read_image_data(o::IO, hduindex::Int)

    header = _read_header(o, hduindex)            # FITS_header object

    ptrdata = _data_pointer(o)
    Base.seek(o, ptrdata[hduindex])
    
    i = get(header.map, "NAXIS", 0)
    ndims = header.card[i].value

    if ndims > 0                           # e.g. dims=(512,512,1)
        dims = Core.tuple([header.card[i+n].value for n = 1:ndims]...)      
        ndata = Base.prod(dims)            # number of data points
        i = get(header.map, "BITPIX", 0)
        bitpix = header.card[i].value
        T = _fits_type(bitpix)
        data = [Base.read(o, T) for n = 1:ndata]
        data = Base.ntoh.(data)  # change from network to host ordering
        # data = data .+ T(bzero)
        # remove mapping between UInt-range and Int-range (if applicable):
        data = fits_remove_offset(data, header)
        data = Base.reshape(data, dims)
    else
        data = Any[]
    end

    return data

end

# ------------------------------------------------------------------------------
#                   _read_table_data(o::IO, hduindex::Int)
#
#   - reads table data in accordance with header information
# ------------------------------------------------------------------------------  

function _read_table_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows

    Base.seek(o, ptr[hduindex])

    data = [String(Base.read(o, lrow)) for i = 1:nrow]

    return data

end

# ------------------------------------------------------------------------------
#                   _read_bintable_data(o::IO, hduindex::Int)
#
#   - reads bintable data in accordance with header information
# ------------------------------------------------------------------------------  

function _t_char(str::String)

    n = 1
    while !isletter(str[n])
        n += 1
    end

    x = str[n]

    return x

end
# ------------------------------------------------------------------------------
function _repeat(str::String)

    s = strip(str, ['\'', ' '])

    r = n = 1
    while isnumeric(s[n])
        r = parse(Int, s[1:n])
        n += 1
    end

    return r

end
# ------------------------------------------------------------------------------
function r_correct!(r::Vector{Int}, char::Vector{Char})

    for i ∈ eachindex(r)
        r[i] = iszero(r[i]) ? r[i] : char == 'P' ? 2 : char == 'Q' ? 2 : r[i]
    end

    return r

end
# ------------------------------------------------------------------------------
function _set_type(x::Char, bzero::Float64)

    X = ['L', 'B', 'I', 'J', 'K', 'A', 'E', 'D', 'C', 'M', 'P', 'Q']

    x ≠ 'X' || return Base.throw(FITSError(msgErr(46))) # 'X' not a Julia type

    x ∈ X || return Base.throw(FITSError(msgErr(44))) # illegal datatype

    if x ∈ ['B', 'I', 'J', 'K']
        if iszero(bzero)
            T = x == 'B' ? UInt8 : x == 'I' ? Int16 : 
                x == 'J' ? Int32 : x == 'K' ? Int64 : nothing
        else
            T = x == 'B' ? Int8 : x == 'I' ? UInt16 : 
                x == 'J' ? UInt32 : x == 'K' ? UInt64 : nothing
        end
    elseif x ∈ ['E', 'D', 'C', 'M']
        T = x == 'E' ? Float32 : x == 'D' ? Float64 :
            x == 'C' ? ComplexF32 : x == 'M' ? ComplexF64 : nothing
    elseif x ∈ ['P', 'Q']
        T = x == 'P' ? UInt32 : 
            x == 'Q' ? UInt64 : nothing
    else
        T = UInt8
    end

    return T

end
# ------------------------------------------------------------------------------
function _read_indexed_keyword(h::FITS_header, key::String, n::Int, default)

    idx = [get(h.map, key * "$i", 0) for i = 1:n]
   
    o = [idx[i] > 0 ? h.card[idx[i]].value : default for i = 1:n]

    return o

end
function _remove_offset(data)

    T = eltype(data)

    T == UInt8 && return Int8.(Int.(data) .- 128)
    T == Int16 && return UInt16.(Int.(data) .+ 32768)
    T == Int32 && return UInt32.(Int.(data) .+ 2147483648)
    T == Int64 && return UInt64.(Int128.(data) .+ 9223372036854775808)

    # workaround for InexactError:trunc(Int64, 9223372036854775808)

end
# ------------------------------------------------------------------------------
function _read_bintable_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows
    tfields = h.card[h.map["TFIELDS"]].value

    tform = _read_indexed_keyword(h, "TFORM", tfields, "'U'")
    tchar = [_t_char(tform[i]) for i = 1:tfields]

    r = [_repeat(tform[i]) for i = 1:tfields]
    r = r_correct!(r ,tchar) # r=1 -> r=2 for 'P' and 'Q' arrays 

    tscal = _read_indexed_keyword(h, "TSCAL", tfields, 1.0)
    tzero = _read_indexed_keyword(h, "TZERO", tfields, 0.0)

    Base.seek(o, ptr[hduindex])

    data = Any[]
    for i = 1:nrow
        val = Any[]
        for j = 1:tfields
            for k = 1:r[j]
                T = _set_type(tchar[j], tzero[j])
                a = Base.read(o, T)
                a = Base.ntoh(a) # change from network to host ordering
                a = iszero(tzero[j]) ? a : _remove_offset(a)
                push!(val, a)
            end
        end
        data = append!(data, val)
    end  

    dat = Vector{Any}(nothing, tfields)
    row = Vector{Any}(nothing, nrow) 

    k = 0
    for i = 1:nrow
        for j = 1:tfields
            n = r[j]
            if n > 0
                if tchar[j] == 'A'
                    row[j] = join(Char.(data[k+1:k+n]))
                    k += n
                elseif tchar[j] == 'P'
                    row[j] = (data[k+1], data[k+2])
                    k += 2
                elseif tchar[j] == 'Q'
                    row[j] = (data[k+1], data[k+2])
                    k += 2
                else
                    row[j] = n > 1 ? Tuple([data[k+m] for m = 1:n]) : data[k+1] 
                    k += n
                end
            end
        end
        dat[i] = Tuple(row)
    end

    data = Tuple(dat)

    return data

end