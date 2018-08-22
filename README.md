# FutureLearn Drone Slack

A Ruby Drone plugin to send messages to Slack.

## Updating the template

Edit the `template` method in [drone-slack.rb](drone-slack.rb).

## Running locally

To test locally, copy [.env.example](.env.example) to `.env` and change the values accordingly.

### Docker

If you have made changes, you should build the image:

`docker build --rm -t drone-slack:test .`

Then run the image:

`docker run --rm --env-file .env drone-slack:test`

### Without Docker

You will need to set all environment variables set in `.env`:

`sed '/^\s*$/d; /^#/d; s/^/export /g' .env`

You can wrap this into your environment:

`$(sed '/^\s*$/d; /^#/d; s/^/export /g' .env)`

Then run the script:

`ruby drone-slack.rb`
