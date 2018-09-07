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
          title: "#{repo_name} (##{build})",
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
              title: "Commit",
              value: commit_summary,
              short: false,
            }
          ]
        }
      ]
    }.to_json
  end

  def notify
    if post_check
      puts "Posting message to Slack"
      HTTParty.post(
        webhook,
        body: template,
      ).body
    else
      puts "Build in good state. Not posting Slack message."
    end
  end

  # Produces a hash depending on the status of the build
  def build_status
    if status == "success"
      {
        color: "good",
        message: ":tada: Succeeded (#{time_taken}) :tada:"
      }
    elsif status == 'success' && prev_build_status == 'failure'
      {
        color: "good",
        message: ":sweat_smile: Recovered (#{time_taken}) :nail_care:"
      }
    else
      {
        color: "danger",
        message: ":crying_cat_face: Failed (#{time_taken}) :sadparrot:"
      }
    end
  end

  def commit_summary
    [
      commit_title,
      "(<#{commit_link}|#{sha[0..7]}> / #{branch})"
    ].join("\n")
  end

  def commit_title
    commit_message.each_line.to_a.map(&:strip).first
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

  def post_check
    return true unless recovery_mode

    if status == 'success' && prev_build_status == 'failure'
      true
    elsif status == 'failure'
      true
    else
      false
    end
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

  def recovery_mode
    set_parameter("recovery_mode")
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

  def commit_message
    drone_env("commit_message")
  end

  def commit_link
    drone_env("commit_link")
  end

  def prev_build_status
    drone_env("prev_build_status")
  end
end

DroneSlack.new.notify
