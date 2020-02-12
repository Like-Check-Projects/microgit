class RepositoryPolicy

  def self.show?(namespace : Namespace, repository : Repository, current_user : User | Nil)


  end

  def self.show?(repository : Repository, current_user : User | Nil, context)
    unless repo_user?(repository, current_user)
      raise Lucky::RouteNotFoundError.new(context)
    end
  rescue Exception
    raise Lucky::RouteNotFoundError.new(context)
  end

  def self.repo_user?(repository : Repository, current_user : User | Nil)
    return false if current_user.nil? && repository.privated
    if repository.team
      #!repository.team.users.id(current_user.id).first.nil? || !repository.privated
      true
    elsif repository.user
      repository.user.try { |u| u.id } == current_user.try { |u| u.id} || !repository.privated
    else
      false
    end
  end
end