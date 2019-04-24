using Documenter, Dispatcher

makedocs(
    # options
    modules = [Dispatcher],
    format = Documenter.HTML(prettyurls=(get(ENV, "CI", nothing) == "true")),
    pages = [
        "Home" => "index.md",
        "Manual" => "pages/manual.md",
        "API" => "pages/api.md",
    ],
    sitename = "Dispatcher.jl",
    authors = "Invenia Technical Computing",
    assets = ["assets/invenia.css"],
)

deploydocs(
    repo = "github.com/invenia/Dispatcher.jl.git",
    target = "build",
)
