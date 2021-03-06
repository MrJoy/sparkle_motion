#!/usr/bin/env ruby
require "yaml"
require "json"
require "set"
require "chunky_png"

FRAME_TIME  = 40
SCALE_X     = 40
SCALE_Y     = 4 # About 10ms per pixel....

def in_ms(val); (val * 1000).round; end

def coalesce(item, base_time, frame_time)
  start_at = in_ms(item["start"]) - base_time
  duration = in_ms(item["duration"])
  # Return the starting *frame*...
  ((start_at + duration) / frame_time.to_f).round
end

def safe_parse(raw)
  tmp = JSON.parse(raw)
  if tmp.is_a?(Hash) && tmp.key?("transitiontime")
    # Transition time is in 10ths of a second.
    tmp["transitiontime"] = tmp["transitiontime"] * 100
  end
  tmp
rescue StandardError
  raw
end

def organize_rest_result(data)
  result = false
  # The transitiontime component will always be true...
  filtered = data.reject { |datum| datum.values.first.keys.first =~ %r{/transitiontime\z} }
  result_codes = filtered.map(&:to_a).map(&:first).map(&:first).sort.uniq
  if result_codes.length == 1
    # Only one status.  Phew!
    result = (result_codes.first == "success")
  else
    # Not sure this outcome is actually *possible*, but the format
    # of the response from the Hue Bridge seems to allow for it...
    #
    # You'll know which parameter(s) failed by the type of the value:
    # If it's a `Hash`, there was an error.  Otherwise, it succeeded.
    puts "WAT: #{data.inspect}"
    result = nil
  end
  result
end

def chunk(items, base_time, frame_time = FRAME_TIME)
  # TODO: This should be chunked at the granularity defined by SparkleMotion::Node::FRAME_PERIOD
  #
  # TODO: We... probably do not want to blow up memory like this, but rather,
  # TODO: round the time into frames, and when iterating over this, look at the
  # TODO: gap length and proceed accordingly.
  chunks_out = Set.new
  items.each do |item|
    transition  = (item["payload"]["transitiontime"] / frame_time).round
    start_frame = coalesce(item, base_time, frame_time)
    end_frame   = start_frame + transition
    # TODO: Hrm.  Looking at duration is... not the right way to go.  We should
    # TODO: probably assume that the light begins changing at roughly (start + duration)
    # TODO: -- it definitely continues for some period of time towards the target value
    # TODO: where that period is defined by the transition time...

    # TODO: We need to interpolate, but we need the previous value as it existed
    # TODO: when we started.  I.E. it may or may not have gotten done
    # TODO: interpolating but wherever it had gotten to when we started
    # TODO: is the starting point for our interpolation...
    chunks_out.add("success"        => item["success"],
                   "bri"            => item["payload"]["bri"],
                   "transitiontime" => transition,
                   "start_frame"    => start_frame,
                   "end_frame"      => end_frame)
  end
  chunks_out
end

def perform_with_timing(msg, &action)
  printf "#{msg}..."
  before = Time.now.to_f
  action.call
ensure
  puts " #{(Time.now.to_f - before).round(2)} seconds."
end

def stringify_keys(hash); Hash[hash.map { |key, val| [key.to_s, val] }]; end

lines       = []
bucketed    = {}
good_events = {}
chunked     = {}
source      = ARGV.shift
dest        = "#{source.sub(/\.raw\z/, '')}.png"

perform_with_timing "Parsing raw data" do
  File.open(source, "r") do |f|
    f.each_line do |line|
      # TODO: Uh, we need proper CSV parsing here...  And proper CSV generation.
      # TODO: In the meantime I'll cheat and rely on my knowledge that commas will
      # TODO: only appear in the payload.
      elts    = line.split(",", 4)
      parsed  = { "time"    => elts[0].to_f,
                  "action"  => elts[1],
                  "url"     => elts[2],
                  "payload" => safe_parse(elts[3]) }
      lines.push parsed
      bucketed[parsed["url"]] ||= []
      bucketed[parsed["url"]].push("time"    => parsed["time"],
                                   "action"  => parsed["action"],
                                   "payload" => parsed["payload"])
    end
  end
end

perform_with_timing "Organizing data" do
  bucketed.each do |url, events|
    events.each_with_index do |event, index|
      next unless event["action"] == "END"
      unless index > 0 && events[index - 1]["action"] == "BEGIN"
        # Calling this out because it would seriously bite us if it happened.
        puts "Ordering issue!  GAH!  Perhaps results got interleaved oddly?!"
        next
      end
      raw       = url.split("/")
      bridge    = raw[2]
      light_id  = raw[6].to_i
      # TODO: We'll need to pull config data to map this into a *logical* index!
      light     = [bridge, light_id]
      good_events[light] ||= []
      good_events[light].push("start"     => events[index - 1]["time"],
                              "duration"  => event["time"] - events[index - 1]["time"],
                              "payload"   => events[index - 1]["payload"],
                              "success"   => organize_rest_result(event["payload"]))
                              # light_id:      [bridge, light_id])
    end
  end
end

perform_with_timing "Extracting successful events" do
  base_times = []
  good_events.each do |_k, v|
    v.sort_by! { |hsh| hsh["start"] }
    base_times << v[0]["start"]
  end
  base_time = (base_times.sort.first * 1000).round
  good_events.each do |k, _v|
    chunked[k] = chunk(good_events[k], base_time)
  end
end

simplified = perform_with_timing "Simplifying data for output" do
  Hash[chunked.map { |idx, data| [idx, data.is_a?(Set) ? data.to_a : data] }]
end

def to_color(rel_y, target_y, payload, last_bri)
  lerp     = (rel_y.to_f / target_y.to_f)
  lerp     = 1.0 if lerp > 1.0
  next_bri = payload["bri"]
  cur_bri  = (last_bri + (lerp * (next_bri - last_bri))).round
  gb       = payload["success"] ? cur_bri : 0
  ChunkyPNG::Color.rgba(cur_bri, gb, gb, 255)
end

# TODO: This needs to be computed in terms of start_frame AND transitiontime...
size_x = simplified.keys.count * SCALE_X
size_y = (simplified.values.map { |l| l.map { |m| m["start_frame"] }.last }.sort.last + 1) * SCALE_Y
max_y  = size_y - 1
puts "Expected target size: #{size_x}x#{size_y}"
perform_with_timing "Writing PNG" do
  config  = YAML.load(File.read("config.yml"))
  png     = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)
  # require "pry"
  # binding.pry
  # TODO: Map the keys here into the index of lights!  Order by light position....
  keys = simplified.keys.sort.map do |light|
    bridge_id = config["bridges"].to_a.find { |(_id, br)| br["ip"] == light[0] }.first
    x_offset = 0
    # TODO: Make which light group we're looking at be configurable...
    config["light_groups"]["main_lights"].each_with_index do |light_ref, idx|
      next unless light_ref[0] == bridge_id && light_ref[1] == light[1]
      x_offset = idx
      break
    end
    [x_offset, bridge_id, light]
  end

  keys.sort { |a, b| a[0] <=> b[0] }.each do |(x_offset, bridge_id, light)|
    puts "%2d => %s, %d" % [x_offset, bridge_id, light[1]]
    x_min     = (x_offset * SCALE_X)
    x_max     = (x_min + SCALE_X) - 1
    last_bri  = 0
    simplified[light].each_with_index do |cur_sample, s_idx|
      next_sample   = simplified[light][s_idx + 1]
      y_min         = cur_sample["start_frame"] * SCALE_Y
      y_max_target  = cur_sample["end_frame"] * SCALE_Y - 1
      rel_y_target  = y_max_target - y_min
      if next_sample
        alt_y_max = (next_sample["start_frame"] * SCALE_Y) - 1
        # if alt_y_max <= y_max_target
          # Perfect timing if they're equal.  So very unlikely...
          # If they're not equal: Overlap -- we cut ourselves off before the transition finished.
        y_max = alt_y_max
        # else
        #   # We have a gap where the transition time finished, but we haven't
        #   # received a new command yet.
        #   y_max = y_max_target
        # end
      else
        y_max = y_max_target
        y_max = (y_max > max_y) ? max_y : y_max
      end
      (x_min..x_max).each do |x|
        (y_min..y_max).each do |y|
          rel_y = y - y_min
          png[x, y] = to_color(rel_y, rel_y_target, cur_sample, last_bri)
        end
      end
      last_bri = cur_sample["bri"]
    end
  end
  png.save(dest, interlace: false)
end
