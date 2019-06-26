#!/usr/bin/env ruby

require 'drone_plugin'
require 'httparty'
require 'json'

class DroneSlack
  attr_reader :plugin

  def initialize
    @plugin = DronePlugin.new
  end

  # Update this template for the output into Slack.
  #
  # https://api.slack.com/docs/message-attachments
  def template
    {
      channel: channel,
      attachments: [
        {
          fallback: "Drone build #{plugin.build} #{plugin.status}",
          color: build_status[:color],
          title: "#{plugin.repo_name} (##{plugin.build})",
          title_link: plugin.link,
          fields: [
            {
              title: 'Status',
              value: build_status[:message],
              short: true
            },
            {
              title: 'Committer',
              value: plugin.author,
              short: true
            },
            {
              title: 'Commit',
              value: plugin.commit_summary,
              short: false
            }
          ]
        }
      ]
    }.to_json
  end

  def notify
    if post_check
      puts 'Posting message to Slack'
      HTTParty.post(
        webhook,
        body: template
      ).body
    else
      puts 'Build in good state. Not posting Slack message.'
    end
  end

  # Produces a hash depending on the status of the build
  def build_status
    if plugin.status == 'success' && plugin.prev_build_status == 'failure'
      {
        color: 'good',
        message: ":sweat_smile: Recovered (#{time_taken}) :nail_care:"
      }
    elsif status == 'success'
      {
        color: 'good',
        message: ":tada: Succeeded (#{time_taken}) :tada:"
      }
    else
      {
        color: 'danger',
        message: ":crying_cat_face: Failed (#{time_taken}) :sadparrot:"
      }
    end
  end

  def commit_summary
    [
      commit_title,
      "(<#{plugin.commit_link}|#{plugin.sha[0..7]}> / #{plugin.branch})"
    ].join("\n")
  end

  def commit_title
    plugin.commit_message.each_line.to_a.map(&:strip).first
  end

  def time_taken
    seconds = plugin.finished.to_i - plugin.started.to_i
    return "#{seconds}s" if seconds < 60

    return Time.at(seconds).utc.strftime('%Mm %Ss') if seconds < 3600

    Time.at(seconds).utc.strftime('%H:%M:%S')
  end

  def post_check
    return true unless recovery_mode

    if plugin.status == 'success' && plugin.prev_build_status == 'failure'
      true
    else
      plugin.status == 'failure'
    end
  end

  # Fetches the parameters set by the by Drone file
  def webhook
    plugin.set_parameter('webhook')
  end

  def channel
    plugin.set_parameter('channel')
  end

  def recovery_mode
    plugin.set_parameter('recovery_mode', false)
  end
end

DroneSlack.new.notify
