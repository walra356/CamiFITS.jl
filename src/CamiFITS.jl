module CamiFITS

import CamiMath
#import Printf
#import Dates           # used in fits_private_sector

using Printf
using Dates           # used in fits_private_sector
using LinearAlgebra

#export _read_TABLE_data
export IORead
export IOWrite
export _read_header
export _read_hdu

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

export _table_data_types

export dictDefinedTerms
export dictDefinedKeywords
export fits_terminology
export fits_keyword
export fits_mandatory_keyword

export FITS_test

export FITS
export FITS_filnam
export FITS_HDU
export FITS_header
export FITS_card
export FITS_dataobject
export FITS_array

export cast_FITS_array

export cast_FITS
export cast_FITS_filnam
export cast_FITS_HDU
export cast_FITS_header
export cast_FITS_card
export cast_FITS_dataobject

export cast_FITS_test

export FORTRAN_format
export FORTRAN_eltype_char

export cast_FORTRAN_format

export parse_FITS_TABLE

export fits_create
export fits_record_dump
export fits_read
export fits_save
export fits_save_as
export fits_extend!
export fits_info
export fits_copy
export fits_collect
export fits_tform
export fits_tzero
export fits_zero_offset
export fits_apply_offset
export fits_remove_offset


export fits_add_key!
export fits_edit_key!
export fits_delete_key!
export fits_records
export fits_rename_key!
export fits_verifier
export name_verifier

export test_FITS_filnam

export test_fits_copy
export test_fits_create
export test_fits_read
export test_fits_extend!
export test_fits_table_extend!
export test_fits_read
export test_fits_save_as
export test_fits_collect
export test_fits_pointer
export test_fits_zero_offset
export test_format_hdutype
export test_table_datatype
export test_bintable_datatype
export test_FORTRAN_format
export test_FORTRAN_eltype_char
export dataset_table
export dataset_bintable

export test_fits_info
export test_fits_keyword
export test_fits_add_key!
export test_fits_edit_key!
export test_fits_delete_key!
export test_fits_rename_key!

include("julia_toolbox.jl")
include("fits_objects.jl")
include("dicts.jl")
include("fits_pointers.jl")
include("read_io.jl")
include("write_io.jl")
include("fits_private_sector.jl")
include("fits_public_sector.jl")
# include("Header-and-Data-Input.jl")
include("FORTRAN.jl")
include("fits_tests.jl")
include("test_fits_format.jl")

end