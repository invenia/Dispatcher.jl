using Documenter, Dispatcher

makedocs(
    # options
    modules = [Dispatcher],
    format = :html,
    pages = [
        "Home" => "index.md",
        "Manual" => "pages/manual.md",
        "API" => "pages/api.md",
        "Index" => "pages/index.md",
    ],
    sitename = "Dispatcher.jl",
    authors = "Invenia Technical Computing",
    assets = ["assets/invenia.css"],
)
