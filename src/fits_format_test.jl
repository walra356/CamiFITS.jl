# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            fits_format_test.jl
#                          Jook Walraven 22-03-2023
# ------------------------------------------------------------------------------

function _passed_fname_test(filnam::String)

    err = err_FITS_name(filnam)

    if err === 0
        str = "Passed name test: \n    "
        str *= "$(filnam) exists, has valid name and may be overwritten."
    elseif err === 1
        str = "Failed name test: \n    " * CamiFITS.msgFITS(1)
    elseif err === 2
        str = "Failed name test: \n    " * CamiFITS.msgFITS(2)
    elseif err === 3
        str = "Failed name test: \n    " * CamiFITS.msgFITS(3)
    elseif err === 4
        str = "Passed name test: \n    "
        str *= "$(filnam) exists and has valid name "
        str *= "- set ';protect=false' to lift overwrite protection."
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

    txt = nblock > 1 "blocks " : "block "
    
    if remain > 0
        err = 6
        str = "Failed block test: \n    " * CamiFITS.msgFITS(err)
    else
        err = 0
        str = "Passed block test: \n    "
        str *= "$(filnam) consists of exactly $(nblock) " * txt
        str *= "of 2880 bytes."
    end

    println(str)

    passed = err == 0 ? true : false

    return passed

end

function fits_format_test(filnam::String)

    a = _passed_fname_test(filnam::String)
    b = _passed_block_test(filnam::String)

end