# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            test_fits_format.jl
#                          Jook Walraven 22-03-2023
# ------------------------------------------------------------------------------

function _passed_filnam_test(filnam::String)

    err = err_FITS_name(filnam)

    if err === 0
        str = "$(filnam) - passed name test:    "
        str *= "file exists, has valid name and may be overwritten."
    elseif err === 1
        str = "$(filnam) - failed name test:    " * CamiFITS.msgFITS(err)
    elseif err === 2
        str = "$(filnam) - failed name test:    " * CamiFITS.msgFITS(err)
    elseif err === 3
        str = "$(filnam) - failed name test:    " * CamiFITS.msgFITS(err)
    elseif err === 4
        str = "$(filnam) - passed name test:    "
        str *= "file exists and has valid name "
        str *= "- use ';protect=false' to lift overwrite protection."
    end

    println(str)

    passed = err === 0 ? true : err === 4 ? true : false

    return passed

end

function _passed_block_test(filnam::String) #_test_fits_read_IO(filnam::String)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    txt = nblock > 1 ? "blocks " : "block "
    
    if remain > 0
        err = 6 # FITS format requires integer number of blocks (of 2880 bytes)
        str = "$(filnam) - failed block test:    " * CamiFITS.msgFITS(err)
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
        str *= msgFITS(err)
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
        str *= msgFITS(err)
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
        str *= msgFITS(err)
    end
    
    println(str)

    passed = err > 0 ? false : true

    return passed

end

function test_fits_format(filnam::String; msg=true)

    o = Bool[]

    push!(o, _passed_filnam_test(filnam::String))
    push!(o, _passed_block_test(filnam::String))

    hdu = fits_read(filnam)

    append!(o, [_passed_record_count(hdu[i]) for i ∈ eachindex(hdu)])
    append!(o, [_passed_ASCII_test(hdu[i]) for i ∈ eachindex(hdu)])
    append!(o, [_passed_keyword_test(hdu[i]) for i ∈ eachindex(hdu)])

    return o

end