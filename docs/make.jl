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
        "Home" => "intro.md",
        "Manual" => "manual.md",
        "API" => "man/api.md",
        "Index" => "index.md",
    ]
)

deploydocs(;
    repo = "github.com/walra356/CamiFITS.jl.git",
    devbranch = "main"
)

