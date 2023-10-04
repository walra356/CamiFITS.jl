using CamiFITS
using Test

@testset "CamiFITS.jl" begin

    @test test_fits_info()
    @test test_fits_copy()
    @test test_fits_create()
    @test test_fits_keyword()
    ######@test test_fits_read()
    @test test_fits_save_as()
    @test test_fits_collect()
    @test test_fits_pointer()
    @test test_fits_zero_offset()
    @test test_format_hdutype()
    @test test_table_datatype()
    @test test_bintable_datatype()

    @test test_fits_add_key!()
    @test test_fits_delete_key!()
    @test test_fits_edit_key!()
    @test test_fits_rename_key!()
    @test test_FORTRAN_format()
    @test test_FORTRAN_eltype_char()
    @test test_FORTRAN_fits_table_tform()
    @test test_FORTRAN_fits_table_tdisp()

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    f = fits_create(filnam, data; protect=false)
    fits_extend!(f, data; hdutype="Image")
    fits_extend!(f, data; hdutype="IMAGE")
    @test_throws FITSError fits_create(filnam)
    rm(filnam)
    @test_throws FITSError fits_create("kanweg")
    @test_throws FITSError fits_create("kanweg.fit")
    @test_throws FITSError fits_create(" .fits")

    @test fits_terminology("FITS"; test=true) == "FITS:\nFlexible Image Transport System."
    @test fits_terminology("s"; test=true)
    @test fits_terminology(; test=true)

end