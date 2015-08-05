#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
require "rubygems"
require "bundler/setup"
Bundler.setup

require_relative "./lib/config"
require_relative "./lib/logging"
require_relative "./lib/env"
require_relative "./lib/http"

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
INIT_HUE      = env_int("INIT_HUE", true) || 49_500
INIT_SAT      = env_int("INIT_SAT", true) || 254
INIT_BRI      = env_int("INIT_BRI", true) || 127

###############################################################################
# Helper Functions
###############################################################################
def make_req_struct(url, data)
  tmp = { method:   :put,
          url:      url,
          put_data: Oj.dump(data) }
  tmp.merge(EASY_OPTIONS)
end

def hue_init(config)
  make_req_struct(hue_group_endpoint(config, 0), "on"  => true,
                                                 "bri" => INIT_BRI,
                                                 "sat" => INIT_SAT,
                                                 "hue" => INIT_HUE)
end

###############################################################################
# Main
###############################################################################
# TODO: Hoist this into a separate script.
# debug "Initializing lights..."
init_reqs = CONFIG["bridges"]
            .values
            .map { |config| hue_init(config) }
Curl::Multi.http(init_reqs, MULTI_OPTIONS) do |easy|
  if easy.response_code != 200
    error "Failed to initialize light (will try again): #{easy.url}"
    add(easy)
  end
end