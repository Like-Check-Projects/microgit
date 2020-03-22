class Namespaces::Show < BrowserAction
  include Auth::AllowGuests
  include RepositoryHelper

  get "/:namespace_slug" do
    namespace = get_namespace
    item = namespace.item
    if item.is_a?(User)
      repos = if !current_user.nil? && UserPolicy.list_private_repos?(item, current_user, context)
        RepositoryQuery.new.preload_user.preload_team.user_id(item.id)
      else
        RepositoryQuery.new.preload_user.preload_team.user_id(item.id).privated(false)
      end

      html ShowUserPage, user: item, repositories: repos.not_nil!
    elsif item.is_a?(Team)
      repos = if !current_user.nil? && TeamPolicy.list_private_repos?(item, current_user, context)
        RepositoryQuery.new.preload_user.preload_team.team_id(item.id)
      else
        RepositoryQuery.new.preload_user.preload_team.team_id(item.id).privated(false)
      end

      html ShowTeamPage, team: item, repositories: repos.not_nil!
    else
      raise Lucky::RouteNotFoundError.new(context)
    end
  end
end
