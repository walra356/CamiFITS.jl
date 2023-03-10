function _test_saturation(data; bitchip::Int=14, bitpix::Int=32, bzero::Int=0, numkin::Int=1)

    bitchip_sat::Int = (2^bitchip - 1) * numkin
    bitpix_sat::Int = 2^bitpix - bzero

    data = convert(Array{Int,3},data)

    o1::Array{Int,1} = []
    o2::Array{Int,1} = []

    [append!(o1, CamiFITS.find_all(vec(data[:,:,i]), bitchip_sat; count=true)[1] for i ∈ axes(data,3))]
    [append!(o2, CamiFITS.find_all(vec(data[:,:,i]), bitpix_sat; count=true)[1] for i ∈ axes(data,3))]

    sum(o1) > 0 ? println("Warning: physical saturation detected ($(sum(o1)) times)") : false
    sum(o2) > 0 ? println("Warning: $bitpix bit saturation detected ($(sum(o2)) times)") : false

end
