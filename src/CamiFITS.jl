module CamiFITS

import CamiMath
import Printf
import Dates           # used in fits_private_sector

export indices

export dictPass
export dictFail
export dictWarn
export dictHint
export dictError

export FITSError
export errFITS
export msgError
export msgErr

export _fits_standard
export _index_space
export _size_word
export _format_com
export _split_wordsize
export _update_spaces
export _offset
export _format_long_data
export _format_value_string

export _format_keyword
export _format_value
export _format_comment
export _format_record
export _format_normrecord
export _format_longrecord
export _passed_keyword_test

export dictDefinedTerms
export dictDefinedKeywords
export fits_terminology
export fits_keyword
export fits_keywords

export test_FITS_filnam

export test_fits_create
export test_fits_read
export test_fits_extend

export test_fits_extend
export test_fits_read

export test_fits_keyword
export test_fits_add_key
export test_fits_edit_key
export test_fits_delete_key
export test_fits_rename_key

export FITS_filnam
export FITS_test

export FITS
export FITS_HDU
export FITS_header
export FITS_card
export FITS_data
export FITS_table

export cast_FITS
export cast_FITS_header
export cast_FITS_card
export cast_FITS_data

export cast_FITS_test
export cast_FITS_filnam

export parse_FITS_TABLE

#export force_create

export fits_create
export fits_create_test
export fits_read
export fits_extend
export fits_info
export fits_copy
export fits_combine
export fits_add_key
export fits_edit_key
export fits_delete_key
export fits_rename_key
export fits_verifier
export name_verifier

#export plot_matrices
#export plot!
export step125
export select125
export edges
export steps
export stepcenters
export stepedges
#export centerticks
#export edgeticks
#export centers
#export edges

export FORTRAN_format
export cast_FORTRAN_format
export cast_FORTRAN_datatype

include("julia_toolbox.jl")
include("fits_objects.jl")
include("dicts.jl")
include("fits_pointers.jl")
include("read_io.jl")
include("write_io.jl")
include("fits_private_sector.jl")
include("fits_public_sector.jl")
include("plot_private_sector.jl")
include("plot_public_sector.jl")
include("Header-and-Data-Input.jl")
include("FORTRAN.jl")
include("fits_tests.jl")
include("test_fits_format.jl")

end