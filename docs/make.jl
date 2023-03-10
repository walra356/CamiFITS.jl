using Documenter
using CamiFITS

makedocs(;
    modules=[CamiFITS],
    authors="<walra356@planet.nl> and contributors",
    #repo = "github.com/walra356/CamiFITS.jl.git",
    sitename="CamiFITS.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        #canonical="https://walra356.github.io/CamiFITS.jl",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
        "Library" => "man/library.md",
        "Index" => "man/index.md",
    ]
)

deploydocs(;
    repo = "github.com/walra356/CamiFITS.jl.git",
    devbranch = "main"
)
