require 'httparty'
require 'json'

require_relative 'plugin'
require_relative 'drone'

class DroneSlack
  attr :plugin, :drone

  def initialize
    @plugin = Plugin.new
    @drone  = Drone.new
  end

  def build_status
    if drone.status == "success"
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
    seconds = drone.started.to_i - drone.finished.to_i
    Time.at(seconds).utc.strftime("%H:%M:%S")
  end

  # https://api.slack.com/docs/message-attachments
  def payload
    {
      channel: plugin.channel,
      attachments: [
        {
          fallback: "Drone build #{drone.build} #{drone.status}",
          color: build_status[:color],
          title: "#{drone.repo_owner}/#{drone.repo_name}#{drone.sha[0...7]}",
          title_link: drone.link,
          fields: [
            {
              title: "Status",
              value: build_status[:message],
              short: true,
            },
            {
              title: "Committer",
              value: drone.author,
              short: true,
            },
            {
              title: "Branch",
              value: drone.branch,
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
      plugin.webhook,
      body: payload,
    ).body
  end
end
