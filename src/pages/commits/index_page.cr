class Commits::IndexPage < MainLayout
  needs repo : MicrogitGit
  needs repository : Repository
  needs namespace : Namespace
  quick_def page_title, "All"

  def content
    render_template "repositories/repo_links.html.ecr"
    render_template "commits/index.html.ecr"
  end
end