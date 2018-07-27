#!/usr/bin/env ruby

require 'httparty'
require 'json'

class DroneSlack
  # Update this template for the output into Slack.
  #
  # https://api.slack.com/docs/message-attachments
  def template
    {
      channel: channel,
      attachments: [
        {
          fallback: "Drone build #{build} #{status}",
          color: build_status[:color],
          title: "#{repo_name}#{sha[0...7]}",
          title_link: link,
          fields: [
            {
              title: "Status",
              value: build_status[:message],
              short: true,
            },
            {
              title: "Committer",
              value: author,
              short: true,
            },
            {
              title: "Branch",
              value: branch,
              short: true,
            },
            {
              title: "Build time",
              value: time_taken,
              short: true,
            }
          ]
        }
      ]
    }.to_json
  end

  def notify
    HTTParty.post(
      webhook,
      body: template,
    ).body
  end

  # Produces a hash depending on the status of the build
  def build_status
    if status == "success"
      {
        color: "good",
        message: ":tada: Succeeded :tada:"
      }
    else
      {
        color: "danger",
        message: ":crying_cat_face: Failed :sadparrot:"
      }
    end
  end

  def time_taken
    seconds = finished.to_i - started.to_i
    if seconds < 60
      return "#{seconds}s"
    end

    if seconds < 3600
      return Time.at(seconds).utc.strftime("%Mm %Ss")
    end

    Time.at(seconds).utc.strftime("%H:%M:%S")
  end

  def drone_env(name)
    ENV.fetch("DRONE_#{name.upcase}", nil)
  end

  def set_parameter(parameter_name, required = true)
    parameter = "PLUGIN_" + parameter_name.upcase

    if required && ENV[parameter].nil?
      abort("Must set #{parameter}")
    end

    return false if ENV[parameter].nil?

    ENV[parameter]
  end

  # Fetches the parameters set by the by Drone file
  def webhook
    set_parameter("webhook")
  end

  def channel
    set_parameter("channel")
  end

  # These are environment variables set by Drone itself
  #
  # http://readme.drone.io/0.5/usage/environment-reference/
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
    drone_env("build_started")
  end

  def finished
    drone_env("build_finished")
  end

  def link
    drone_env("build_link")
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

end

DroneSlack.new.notify
