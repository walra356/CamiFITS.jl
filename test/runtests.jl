using CamiFITS
using Test

@testset "CamiFITS.jl" begin

    @test edges(1:5, 2.5, 2.5) == [-1.25, 1.25, 3.75, 6.25, 8.75]
    @test steps([4, 2, 6]) == [0, 4, 6, 12]
    @test stepcenters([4, 2, 6]) == [2.0, 5.0, 9.0]
    @test stepedges([4, 2, 6]) == [0, 4, 6, 12]
    @test select125([1, 2, 4, 6, 8, 10, 13, 16, 18, 20, 40, 60, 80, 100]) == [2, 6, 10, 16, 20, 60, 100]
    @test step125.([5, 10, 21.3, 50, 100.1]) == [1, 2, 5, 10, 20]

    @test test_fits_info()
    @test test_fits_copy()
    @test test_fits_create()
    @test test_fits_extend!()
    @test test_fits_keyword()
    @test test_fits_read()
    @test test_fits_save_as()
    @test test_fits_collect()

    @test test_fits_add_key!()
    @test test_fits_delete_key!()
    @test test_fits_edit_key!()
    @test test_fits_rename_key!()

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f];
    f = fits_create(filnam, data; protect=false);
    fits_extend!(f, data, "'ARRAY   '")
    fits_extend!(f, data, "'IMAGE   '")
    r = fits_record_dump(filnam);
    @test r[9][2][1:3] == "END" 
    @test r[37][2][1:20] == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0\0\0\0\0\0"
    @test r[109][2][1:20] == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0\0\0\0\0\0"
    @test r[181][2][1:20] == "\x80\0\x04>\x80\0\x04\f\x80\0\x04\x1f\0\0\0\0\0\0\0\0"
    @test fits_verifier(filnam; msg=false) == 0
    @test_throws FITSError fits_create(filnam)
    rm(filnam)
    @test_throws FITSError fits_create("kanweg")
    @test_throws FITSError fits_create("kanweg.fit")
    @test_throws FITSError fits_create(" .fits")

    @test fits_terminology("FITS"; test=true) == "FITS:\nFlexible Image Transport System."
    @test fits_terminology("s"; test=true)
    @test fits_terminology(; test=true)

end

