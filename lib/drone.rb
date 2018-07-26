# http://readme.drone.io/0.5/usage/environment-reference/

class Drone
  def author
    drone_env("commit_author")
  end

  def branch
    drone_env("commit_branch")
  end

  def build
    drone_env("build_number")
  end

  def status
    drone_env("job_status")
  end

  def started
    drone_env("job_started")
  end

  def finished
    drone_env("job_finished")
  end

  def link
    drone_env("link")
  end

  def repo_name
    drone_env("repo")
  end

  def repo_owner
    drone_env("repo_owner")
  end

  def sha
    drone_env("commit_sha")
  end

  private

  def drone_env(name)
    ENV.fetch("DRONE_#{name.upcase}", nil)
  end
end
