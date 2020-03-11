class Repositories::MergeRequests::Activities::Create < BrowserAction
  include RepositoryHelper
  post "/:namespace_slug/:repository_slug/merge_requests/:merge_request_id/comment" do
    repository = check_access
    namespace = get_namespace
    merge_request = MergeRequestQuery.find(merge_request_id)
    SaveActivityForItems.create(params, merge_request_id: merge_request.id, user_id: current_user.id, type: 0) do |operation, comment|
      if comment
        flash.success = "The record has been saved"
        redirect MergeRequests::Show.with(repository.namespace_slug, repository.slug, merge_request.id)
      else
        flash.failure = "It looks like the form is not valid"
        comments = ActivityForItemsQuery.new.preload_user.merge_request_id(merge_request_id)
        html MergeRequests::ShowPage, operation: operation, merge_request: merge_request, repository: repository, namespace: namespace, comments: comments
      end
    end
  end
end