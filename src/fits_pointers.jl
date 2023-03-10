function _record_pointers(o::IO)

    n = o.size ÷ 80                             # number of records in IO (36 records/block)

    r = [(i-1)*80 for i=1:n]                    # start-of-record pointers (80 bytes/record)

    return r

end

function _block_pointers(o::IO)

    n = o.size ÷ 2880                           # number of blocks in IO

    b = [(i-1)*2880 for i=1:n]                  # start-of-block pointers (2880 bytes/block)

    return b

end

function _header_pointers(o::IO)

    b = _block_pointers(o::IO)                  # b: start-of-block pointers

    h::Array{Int,1} = []                        # h: init start-of-header pointers

    for i ∈ Base.eachindex(b)                   # i: start-of-block pointer
        Base.seek(o,b[i])
        key = String(Base.read(o,8))
        key ∈ ["SIMPLE  ", "XTENSION"] ? Base.push!(h,b[i]) : false
    end

    return h                                    # return start-of-header pointers

end

function _hdu_pointers(o::IO)

    h = _header_pointers(o::IO)                 # h: start-of-header pointers

    return h                                    # return start-of-HDU (= start-of-header) pointers

end     

function _data_pointers(o::IO)

    b = _block_pointers(o::IO)                  # b: start-of-block pointers

    d::Array{Int,1} = []                        # h: init start-of-data pointers

    for i ∈ eachindex(b)                        # i: start-of-block pointer (36 records/block = 2880 bytes)
        Base.seek(o,b[i])
        [(key = String(Base.read(o,8)); key == "END     " ? Base.push!(d,b[i]+2880) : Base.skip(o,72)) for j=0:35]
    end

    return d                                    # return start-of-data pointers

end
