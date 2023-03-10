using CamiFITS
using Test

@testset "CamiFITS.jl" begin

    @test edges(1:5, 2.5, 2.5) == [-1.25, 1.25, 3.75, 6.25, 8.75]
    @test steps([4, 2, 6]) == [0, 4, 6, 12]
    @test stepcenters([4, 2, 6]) == [2.0, 5.0, 9.0]
    @test stepedges([4, 2, 6]) == [0, 4, 6, 12]
    @test select125([1, 2, 4, 6, 8, 10, 13, 16, 18, 20, 40, 60, 80, 100]) == [2, 6, 10, 16, 20, 60, 100]
    @test step125.([5, 10, 21.3, 50, 100.1]) == [1, 2, 5, 10, 20]
    @test fits_create()
    @test fits_extend()
    @test fits_read()
    @test fits_add_key()
    @test fits_edit_key()
    @test fits_delete_key()
    @test fits_rename_key()
    @test definition("FITS")

end
