module CamiFITS

import CamiMath
import Printf
import Dates           # used in fits_private_sector

export FITSError
export errFITS
export dictErrors

export dictDefinedTerms
export terminology
export _isavailable

export err_FITS_name
export test_FITS_name
export test_fits_format

export test_fits_create
export test_fits_extend
export test_fits_read

export test_fits_add_key
export test_fits_edit_key
export test_fits_delete_key
export test_fits_rename_key

export FITS_HDU
export FITS_header
export FITS_data
export FITS_table
export parse_FITS_TABLE
export FITS_name
export isvalid_FITS_name
export cast_FITS_name

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

include("dicts.jl")
include("fits_pointers.jl")
include("read_io.jl")
include("write_io.jl")
include("fits_objects.jl")
include("fits_private_sector.jl")
include("fits_public_sector.jl")
include("plot_private_sector.jl")
include("plot_public_sector.jl")
include("Header-and-Data-Input.jl")
include("FORTRAN.jl")
include("fits_tests.jl")
include("test_fits_format.jl")

end
