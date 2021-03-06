class MicrogitGit
  include Caching
  def initialize(@repo : Repository)
    @repo_git = Git::Repo.open(@repo.git_path)
  end

  def raw
    @repo_git
  end

  def can_get_git_data?
    !raw.empty?
  end

  def get_branch_diff(target_branch) : Git::Diff
    target_commit = Git::Commit.lookup(raw, target_branch.target_id)
    master_commit = last_commit("master")

    master_commit.not_nil!.diff(target_commit)
  end

  def last_commit(branch = "master")
    return unless can_get_git_data?
    Git::Commit.lookup(raw, caching("last_commit/#{branch}") do
      target = Git::Branch.lookup(raw, branch)
      return nil if @repo_git.empty?
      target.target_id
    end)
  end

  def branches
    raw.branches
  end

  def branches_count
    caching("branches") do
      branches.each_name.size
    end
  end

  def size
    caching("size") do
      output = IO::Memory.new
      cmd = "du -sk #{@repo.git_path}"
      Process.run(cmd, shell: true, output: output)
      ((output.to_s.split.first.to_f / 1024)).round(2)
    end
  end

  def merge_branch(merge_request, user) : Git::Oid | Nil
    target = Git::Branch.lookup(raw, merge_request.branch)

    diff = get_branch_diff(target)
    return nil if diff.size == 0

    target_commit = Git::Commit.lookup(raw, target.target_id)
    master_commit = raw.last_commit

    commit_author = Git::Signature.new("Håkan Nylén", user.email)
    array_commits = [master_commit, target_commit]

    commit_data = Git::CommitData.new("Merge commit of #{merge_request.branch}", array_commits, target_commit.tree, commit_author, commit_author, "HEAD")

    Git::Commit.create(raw, commit_data)
  end

  def ahead_behind_branch(target_branch)
    target_commit = Git::Commit.lookup(raw, target_branch.target_id)
    master_commit = raw.last_commit

    @repo_git.ahead_behind(target_commit, master_commit)
  end

  def root_ref
    refs = @repo_git.branches

    if refs["master"]
      "master"
    else
      refs[0]
    end
  end

  def commit_topic(commit_message : String) : String
    commit_message.split("\n\n").first
  end

  def commit_message(commit_message : String) : String
    commit_message.split("\n\n").second
  end

  def commit_count(ref = last_commit)
    caching("commit_count") do
      return 0 if @repo_git.empty?
      return 0 if ref.nil?
      count = 0
      @repo_git.walk(ref.sha) do |c|
        count += 1
      end
      count
    end
  end

  def find_file(file_path)
    return nil if tree.nil?
    return nil if @repo_git.empty?
    tree.try { |t| t.path(file_path) }
  rescue Git::Error
    return nil
  end

  def find_file_blob(file_path = nil)
    return nil if raw.empty?
    entry = find_file(file_path)
    return nil if entry.nil?
    Git::Blob.lookup(raw, entry.oid)
  rescue Git::Error
    return nil
  end

  def tree(ref = last_commit)
    return nil if ref.nil?
    return nil if raw.empty?
    ref.tree
  end

  def tree_by_path(path, branch = "master")
    return nil if raw.empty?
    tree_entry = tree(last_commit(branch))
    return nil if tree_entry.nil?
    raw.lookup_tree(tree_entry.not_nil!.path(path).oid)
  end

  def log_by_walk(sha, options)
    walker = raw.walk(sha)
    walker.to_a
  end

  def log_by_shell(sha, options)
    cmd = git_command("--git-dir=#{@repo.git_path} log")
    cmd += " -n #{options["limit"].to_i}"
    cmd += " --format=%H"
    cmd += " --skip=#{options.fetch("offset", 0).to_i}" if options.fetch("offset", false)
    cmd += " --follow" if options.fetch("follow", false)
    cmd += " --no-merges" if options.fetch("skip_merges", false)
    cmd += " --after=#{options.fetch("after", Time.utc).try { |t| t }}" if options.fetch("after", false)
    cmd += " --before=#{options.fetch("before", Time.utc).try { |t| t }}" if options.fetch("before", false)
    cmd += " #{sha}"
    cmd += " -- #{options["path"]}" if options.fetch("path", false)

    raw_output = IO::Memory.new

    Process.run(cmd, shell: true, output: raw_output)

    log = [] of Git::Commit
    output = raw_output.to_s

    output.split("\n").each do |c|
      next if c.empty?
      log << Git::Commit.lookup(@repo_git, c.strip)
    end

    return log
  end

  def last_for_path(ref, path = nil)
    Git::Commit.lookup(@repo_git, caching("last/#{path}") do
      log_by_shell(
        ref, {
        path:  path,
        limit: 1,
      }
      ).first.to_s
    end)
  end

  def sha_from_ref(ref)
    raw.rev_parse(ref).oid
  end

  def git_command(command)
    git_bin = ENV["git_path"]? || "git"
    command = "#{git_bin} #{command}"
    command
  end
end
