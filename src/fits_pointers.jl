# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                          fits_pointersr.jl
#                         Jook Walraven 13-05-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                      _record_pointer(o::IO)
#           ptr array:   pointer to start of record (80 bytes/record)
# ------------------------------------------------------------------------------

function _record_pointer(o::IO) # pointer to start of record  (80 bytes/record)

    n = o.size ÷ 80               # number of records in IO (36 records/block)

    ptr = [(i - 1) * 80 for i = 1:n]

    return ptr

end

# ------------------------------------------------------------------------------
#                      _block_pointer(o::IO)
#         ptr array:   pointer to start of block (2880 bytes/block)
# ------------------------------------------------------------------------------

function _block_pointer(o::IO) # pointer to start of block

    n = o.size ÷ 2880             # number of blocks in IO

    ptr = [(i - 1) * 2880 for i = 1:n]

    return ptr

end

# ------------------------------------------------------------------------------
#                      _header_pointer(o::IO)
#         ptr array:   pointer to start of header
# ------------------------------------------------------------------------------

function _header_pointer(o::IO)

    b = _block_pointer(o::IO)             # b: start-of-block pointers

    ptr::Array{Int,1} = []                   # h: init start-of-header pointers

    for i ∈ Base.eachindex(b)              # i: start-of-block pointer
        Base.seek(o, b[i])
        key = String(Base.read(o, 8))
        key ∈ ["SIMPLE  ", "XTENSION"] ? Base.push!(ptr, b[i]) : false
    end

    return ptr                               # return start-of-header pointers

end

# ------------------------------------------------------------------------------
#                      _hdu_pointer(o::IO)
#         ptr array:   pointer to start of hdu
# ------------------------------------------------------------------------------

function _hdu_pointer(o::IO)

    ptr = _header_pointer(o::IO)  # h: start-of-header pointers

    return ptr                     # return start-of-HDU pointers

end

# ------------------------------------------------------------------------------
#                      _data_pointer(o::IO)
#         ptr array:   pointer to start of data block
# ------------------------------------------------------------------------------

function _data_pointer(o::IO)

    b = _block_pointer(o::IO)   # b: start-of-block pointers

    ptr::Vector{Int} = []         # h: init start-of-data pointers

    for i ∈ eachindex(b)         # i: start-of-block pointer (36 records/block)
        Base.seek(o, b[i])
        [(key = String(Base.read(o, 8));
        key == "END     " ?
        Base.push!(ptr, b[i] + 2880) : Base.skip(o, 72)) for j = 0:35]
    end

    return ptr                                    # return start-of-data pointers

end

# ------------------------------------------------------------------------------
#                      _end_pointer(o::IO)
#         ptr array:   pointer to end of data block
# ------------------------------------------------------------------------------

function _end_pointer(o::IO)

    ptrhdu = _hdu_pointer(o)
    nhdu = length(ptrhdu)

    ptr = [(i < nhdu ? ptrhdu[i+1] : length(o.data)) for i = 1:nhdu]

    return ptr

end 
