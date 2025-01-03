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
#                            read_IO.jl
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                     IORead(filnam::String)
# 
#   - read filnam from disc 
#   - test for integral number of blocks of 2880 bytes/block
# ------------------------------------------------------------------------------  

function IORead(filnam::String)

    o = IOBuffer()

    Base.write(o, Base.read(filnam))

    return o

end

# ------------------------------------------------------------------------------
#                   _read_header(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------

function _read_header(o::IO, p::FITS_pointer, hduindex::Int; msg=false)

    hduindex ≤ p.nhdu || error("hduindex ≤ $(p.nhdu) required")

    Base.seek(o, p.hdu_start[hduindex])

    nrow = (p.hdr_stop[hduindex]-p.hdr_start[hduindex])÷80
 
    record = [String(Base.read(o, 80)) for i = 1:nrow]
    
    if msg 
        str = "_read_header:\n"
        str *= "p.hdr_start[hduindex] = $(p.hdr_start[hduindex])\n"
        str *= "p.hdr_stop[hduindex] = $(p.hdr_stop[hduindex])\n"
        str *= "record[1] = $(record[1])\n"
        str *= "remain = $((p.hdr_stop[hduindex]-p.hdr_start[hduindex]) % 80)\n"
        str *= "cast header[$(hduindex)]\n"
        println(str)
    end
    
    return cast_FITS_header(record)

end
# ------------------------------------------------------------------------------
#                   read_hdu(o, p, hduindex; msg-false)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------  

function read_hdu(o::IO, p::FITS_pointer, hduindex::Int; msg=false)  # read data using header information

msg && println("read hdu[$(hduindex)]")

        header = _read_header(o, p, hduindex; msg) #  FITS_header
    dataobject = _read_data(o, p, hduindex, header; msg)

    return FITS_HDU(hduindex, header, dataobject)

end

# ------------------------------------------------------------------------------
#                   _read_data(o, p, hduindex; msg=false)
# ------------------------------------------------------------------------------  

function _read_data(o::IO, p::FITS_pointer, hduindex::Int, header::FITS_header; msg=false)  # read data using header information

    hdutype = header.card[1].keyword == "XTENSION" ? header.card[1].value : "'PRIMARY '"
    hdutype = Base.strip(hdutype)
    hdutype = Base.Unicode.uppercase(hdutype)
    
    if     hdutype == "'PRIMARY '"
        data = _read_image_data(o, p, hduindex, header; msg)
    elseif hdutype == "'IMAGE   '"
        data = _read_image_data(o, p, hduindex, header; msg)
    elseif hdutype == "'TABLE   '"
        data = _read_table_data(o, p, hduindex, header; msg)
    elseif hdutype == "'BINTABLE'"
        data = _read_bintable_data(o, p, hduindex, header; msg)
    else
        Base.throw(FITSError(msgErr(25)))
    end
    
 msg && println("cast dataobject[$(hduindex)]:")

    return FITS_dataobject(hdutype, data)
    
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
#                      fits_remove_zero_offset(data)
# ------------------------------------------------------------------------------

@doc raw"""
    fits_remove_zero_offset(data)
 
Shift the `Int` range of values onto the `UInt` range by *adding* to the `data`
the appropriate integer offset value as specified by the `BZERO` keyword.

NB. Since the FITS format *does not support a native unsigned integer data 
type* (except `UInt8`), unsigned values of the types `UInt16`, `UInt32` and 
`UInt64`, are recovered from stored native signed integers of the types `Int16`,
`Int32` and `Int64`, respectively, by *adding* the appropriate integer offset 
specified by the (positive) `BZERO` keyword value. For the byte data type 
(`UInt8`), the converse technique can be used to recover the signed byte values
(`Int8`) from the stored native unsigned values (`UInt`) by *adding* the 
(negative) `BZERO` offset value. 

This method is included and used in *reading* stored data to ensure backward 
compatibility with software not supporting native values of the types 
`Int8`, `UInt16`, `UInt32` and `UInt64`.
#### Example:
```
julia> fits_remove_zero_offset(Int32[-2147483648])
1-element Vector{UInt32}:
 0x00000000

julia> Int(0x00000000)
0

julia> fits_remove_zero_offset(UInt8[128])
1-element Vector{Int8}:
 0
```
"""
function fits_remove_zero_offset(data) # to have double range for natural numbers

    T = eltype(data)

    T ∈ (UInt8, Int16, Int32, Int64) || error("Error: datatype inconsistent with BZERO > 0")
    T == UInt8 && return Int8.(Int.(data) .- 128)
    T == Int16 && return UInt16.(Int.(data) .+ 32768)
    T == Int32 && return UInt32.(Int.(data) .+ 2147483648)
    T == Int64 && return UInt64.(Int128.(data) .+ 9223372036854775808) # workaround for InexactError:trunc(Int64, 9223372036854775808)
 
    return data
    
end
# ------------------------------------------------------------------------------
function _read_image_data(o::IO, p::FITS_pointer, hduindex::Int, header::FITS_header; msg=false)

    ptrdata = p.data_start #_data_pointer(o)
    Base.seek(o, ptrdata[hduindex])
    
    i = get(header.map, "NAXIS", 0)
    ndims = header.card[i].value

    if ndims > 0                           # e.g. dims=(512,512,1)
        dims = Core.tuple([header.card[i+n].value for n = 1:ndims]...)      
        ndata = Base.prod(dims)            # number of data points
        i = get(header.map, "BITPIX", 0)
        bitpix = header.card[i].value
        T = _fits_type(bitpix)
        data = [Base.ntoh(Base.read(o, T)) for n = 1:ndata] # change from network ordering (big-endian) to host ordering (depends on machine)
msg && println("after ntoh: hdu[$(hduindex)].dataobject.data = ", data) 
        i = get(header.map, "BZERO", 0)
        bzero = i > 0 ? header.card[i].value : 0.0
        data = iszero(bzero) ? data : fits_remove_zero_offset(data) # restore Types (UInt16/UInt32/UInt64/Int8) - if applicable (i.e., for Bzero > 0)
msg && println("read: restore datatype: data = ", data) 
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

function _read_table_data(o::IO, p::FITS_pointer, hduindex::Int, header::FITS_header; msg=false)

    ptr = p.data_start #_data_pointer(o)

#    header = _read_header(o, hduindex) # FITS_header object

#    Base.seek(o, ptr[hduindex])
    lrow = header.card[header.map["NAXIS1"]].value # row length in bytes
    nrow = header.card[header.map["NAXIS2"]].value # number of rows

    Base.seek(o, ptr[hduindex])
  
    data = [String(Base.read(o, lrow)) for i = 1:nrow]

msg && println("read table data: ", data) 

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

    x = str[n:end]

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
function _set_type(x::Char, bzero::Real)

    X = ['L', 'B', 'I', 'J', 'K', 'A', 'E', 'D', 'C', 'M', 'P', 'Q', 'X']

    x ∈ X || return Base.throw(FITSError(msgErr(44))) # illegal datatype

    if x ∈ ['B', 'I', 'J', 'K']
        T = x == 'B' ? UInt8 : x == 'I' ? Int16 :
            x == 'J' ? Int32 : x == 'K' ? Int64 : nothing
    elseif x ∈ ['E', 'D', 'C', 'M']
        T = x == 'E' ? Float32 : x == 'D' ? Float64 :
            x == 'C' ? ComplexF32 : x == 'M' ? ComplexF64 : nothing
    elseif x ∈ ['P', 'Q']
        T = x == 'P' ? UInt32 : 
            x == 'Q' ? UInt64 : nothing
    elseif x == 'X'
        T = Int
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
# ------------------------------------------------------------------------------
function _read_bintable_data(o::IO, p::FITS_pointer, hduindex::Int, header::FITS_header; msg=false)

    ptr = p.data_start

    #header = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = header.card[header.map["NAXIS1"]].value # row length in bytes
    nrow = header.card[header.map["NAXIS2"]].value # number of rows
    tfields = header.card[header.map["TFIELDS"]].value

    tform = _read_indexed_keyword(header, "TFORM", tfields, "'U'")
    tchar = [_t_char(tform[i])[1] for i = 1:tfields]
    tuple = [_t_char(tform[i])[2:6] == "tuple" for i = 1:tfields]

    r = [_repeat(tform[i]) for i = 1:tfields]

    tscal = _read_indexed_keyword(header, "TSCAL", tfields, 1.0)
    tzero = _read_indexed_keyword(header, "TZERO", tfields, 0.0)
    tdims = _read_indexed_keyword(header, "TDIM", tfields, nothing)
    tdisp = _read_indexed_keyword(header, "TDISP", tfields, nothing)

    Base.seek(o, ptr[hduindex])

    data = Vector{Any}(undef, nrow)
    for i = 1:nrow
        data[i] = Any[]
        row = Any[]
        for j = 1:tfields
            t = _set_type(tchar[j], tzero[j])
            val = []
            for k = 1:r[j]
                a = Base.ntoh(Base.read(o, t)) # change from network to host ordering
                #a = iszero(tzero[j]) ? a : _remove_offset(a)
                a = iszero(tzero[j]) ? a : fits_remove_zero_offset(a)
                push!(val, a)
            end
            append!(row, val)
        end
        append!(data[i], row)
    end

    o = Any[]

    for i = 1:nrow
        k = 0 # extra variable to handle bitvectors
        row = Any[]
        for j = 1:tfields
            n = r[j]
            if n > 0
                if tchar[j] == 'A'
                    if isnothing(tdims[j]) && !tuple[j]
                        if n > 1
                            d = join(Char.(data[i][k+1:k+n]))
                        else
                            d = Char(data[i][k+1])
                        end
                    else
                        d = Char.(data[i][k+1:k+n])
                        d = tuple[j] ? d : reshape(d, tdims[j])
                    end
                    k += n
                elseif tchar[j] == 'L'
                    if n > 1
                        d = Bool.(data[i][k+1:k+n])
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = Bool(data[i][k+1])
                    end
                    k += n
                elseif tchar[j] == 'X'
                    if n > 1
                        d = [data[i][k+m] for m = 1:n]
                        d = bitstring.(d)
                        p = findfirst.("1", d)
                        d = [d[m][p[m].start:end] for m = 1:n]
                        d = collect.(d)
                        d = [BitVector(parse.(Int, d[m])) for m = 1:n]
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = data[i][k+1]
                        d = bitstring(d)
                        p = findfirst("1", d)
                        d = d[p.start:end]
                        d = collect(d)
                        d = BitVector(parse.(Int, d))
                    end
                    k += n
                elseif (tchar[j] == 'P') ⊻ (tchar[j] == 'Q')
                    error("variable-length arrays not yet implemented")
                    #    push!(row, Tuple([data[i][k+m] for m = 1:n])) 
                    #    k += n
                else
                    if n > 1
                        d = [data[i][k+m] for m = 1:n]
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = data[i][k+1]
                    end
                    k += n
                end
                d = tuple[j] ? Tuple(d) : d
                push!(row, d)
            end
        end
        push!(o, row)
    end

    for i = 1:nrow
        for j = 1:tfields
            V = typeof(o[1][j])
            T = typeof(o[i][j])
            T ≠ V && Base.throw(FITSError(msgErr(46)))
        end
    end

    return o

end