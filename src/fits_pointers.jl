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
#                      _row(o::IO)
#         nr array:   row numbers = single-line-record numbers (80 bytes/record)
# ------------------------------------------------------------------------------

function _row_nr(o::IO) # pointer to start of record  (80 bytes/record)

    nr = _record_pointer(o) .÷ 80

    return nr

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
#                      _block_rows(o::IO)
#         nr array:   start-of-block rows (36 rows/block)
# ------------------------------------------------------------------------------

function _block_row(o::IO) # pointer to start of block

    nr = _block_pointer(o) .÷ 80

    return nr

end

# ------------------------------------------------------------------------------
#                      _header_pointer(o::IO)
#         ptr array:   start-of-header pointers
# ------------------------------------------------------------------------------

function _header_pointer(o::IO)

    b = _block_pointer(o::IO)    # b: start-of-block pointers

    ptr::Array{Int,1} = []       # ptr: init start-of-header pointers

    for i ∈ Base.eachindex(b)    # i: start-of-block pointer
        Base.seek(o, b[i])
        key = String(Base.read(o, 8))
        key ∈ ["SIMPLE  ", "XTENSION"] ? Base.push!(ptr, b[i]) : false
    end

    return ptr  # return start-of-header pointers

end

# ------------------------------------------------------------------------------
#                      _header_row(o::IO)
#          nr array:   start-of-header rows
# ------------------------------------------------------------------------------

function _header_row(o::IO)

    nr = _header_pointer(o) .÷ 80

    return nr

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
#                      _hdu_row(o::IO)
#          nr array:   start-of-hdu rows
# ------------------------------------------------------------------------------

function _hdu_row(o::IO)

    nr = _hdu_pointer(o) .÷ 80

    return nr

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
#                      _data_row(o::IO)
#          nr array:   start-of-data rows
# ------------------------------------------------------------------------------

function _data_row(o::IO)

    nr = _data_pointer(o) .÷ 80

    return nr

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

# ------------------------------------------------------------------------------
#                      _end_row(o::IO)
#          nr array:   end-of-data = end-of-hdu rows
# ------------------------------------------------------------------------------

function _end_row(o::IO)

    nr = _end_pointer(o) .÷ 80

    return nr

end
