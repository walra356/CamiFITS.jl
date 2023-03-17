

function _create(filnam::String, data=[]; protect=true)

    nhdu = 1
    hdutype = "PRIMARY"

    FITS_data = [_cast_data(i, hdutype, data) for i = 1:nhdu]
    FITS_headers = [_cast_header(_PRIMARY_input(FITS_data[i]), i) for i = 1:nhdu]

    FITS = [FITS_HDU(filnam, i, FITS_headers[i], FITS_data[i]) for i = 1:nhdu]

    return _fits_save(FITS)

end
# ..............................................................................

function test_err_FITS_name()

    _create("runtest"; protect=false)
    _create("runtest.fit"; protect=false)
    _create("runtest.fits"; protect=false)
    _create(".fits"; protect=false)

    o = [err_FITS_name("")]
    o = push!(o, err_FITS_name("runtest"))
    o = push!(o, err_FITS_name("runtest.fit"))
    o = push!(o, err_FITS_name("runtest"))
    o = push!(o, err_FITS_name(".fits"))
    o = push!(o, err_FITS_name("runtest.fits"))
    o = push!(o, err_FITS_name("runtest.fits"; protect=false))

    u = [1, 2, 2, 2, 3, 4, 0]

    rm("runtest")
    rm("runtest.fit")
    rm("runtest.fits")
    rm(".fits")

    return o == u ? true : false

end

function test_fits_create()

    strExample = "runtest.fits"
    _create(strExample; protect=false)

    f = fits_read(strExample)
    a = f[1].header.keys[1] == "SIMPLE"
    b = f[1].dataobject.data == Any[]
    c = get(Dict(f[1].header.dict), "SIMPLE", 0)
    d = get(Dict(f[1].header.dict), "NAXIS", 0) == 0

    rm(strExample)

    o = isnothing(findfirst(.![a, b, c, d])) ? true : false

    return o

end

function test_fits_rename_key()

    strExample = "minimal.fits"
    _create(strExample; protect=false)
    fits_add_key(strExample, 1, "KEYNEW1", true, "this is record 5")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test1 = i == 5

    fits_rename_key(strExample, 1, "KEYNEW1", "KEYNEW2")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW2", 0)

    test2 = i == 5

    test = .![test1, test2]

    o = isnothing(findfirst(.![test1, test2])) ? true : false

    rm(strExample)

    return o

end

function test_fits_delete_key()

    strExample = "minimal.fits"
    _create(strExample; protect=false)
    fits_add_key(strExample, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test1 = i == 5

    fits_delete_key(strExample, 1, "KEYNEW1")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test2 = i == 0

    test = .![test1, test2]

    o = isnothing(findfirst(.![test1, test2])) ? true : false

    rm(strExample)

    return o

end

function test_fits_edit_key()

    strExample = "minimal.fits"
    _create(strExample; protect=false)
    fits_add_key(strExample, 1, "KEYNEW1", true, "FITS dataset may contain extension")
    fits_edit_key(strExample, 1, "KEYNEW1", false, "comment has changed")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW1", 0)
    r = f[1].header.records

    test = r[i] == "KEYNEW1 =                    F / comment has changed                            "

    rm(strExample)

    return test

end

function test_fits_add_key()

    strExample = "minimal.fits"
    _create(strExample; protect=false)
    fits_add_key(strExample, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    f = fits_read(strExample)
    i = get(f[1].header.maps, "KEYNEW1", 0)
    r = f[1].header.records

    test = r[i] == "KEYNEW1 =                    T / FITS dataset may contain extension             "

    rm(strExample)

    return test

end

function test_fits_extend()

    strExample = "test_example.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    fits_create(strExample, data; protect=false)

    f = fits_read(strExample)
    a = Float16[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6]
    b = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f]
    c = [1.23, 2.12, 3.0, 4.0, 5.0]
    d = ['a', 'b', 'c', 'd', 'e']
    e = ["a", "bb", "ccc", "dddd", "ABCeeaeeEEEEEEEEEEEE"]
    data = [a, b, c, d, e]
    fits_extend(strExample, data, "TABLE")

    f = fits_read(strExample)
    a = f[1].header.keys[1] == "SIMPLE"
    b = f[1].dataobject.data[1] == 0x0000043e
    c = f[2].header.keys[1] == "XTENSION"
    d = f[2].dataobject.data[1] == "1.0e-6 1086 1.23 a a                    "
    e = get(Dict(f[2].header.dict), "NAXIS", 0) == 2

    rm(strExample)

    o = isnothing(findfirst(.![a, b, c, d, e])) ? true : false

    return o

end

function test_fits_read()

    strExample = "minimal.fits"
    _create(strExample; protect=false)

    f = fits_read(strExample)
    a = f[1].header.keys[1] == "SIMPLE"
    b = f[1].dataobject.data == Any[]
    c = get(Dict(f[1].header.dict), "SIMPLE", 0)
    d = get(Dict(f[1].header.dict), "NAXIS", 0) == 0

    rm(strExample)

    o = isnothing(findfirst(.![a, b, c, d])) ? true : false

    return o

end

