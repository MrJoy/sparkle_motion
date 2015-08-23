def announce_iteration_config(iters)
  if iters > 0
    FluxHue.logger.unknown { "Running for #{iters} iterations." }
  else
    FluxHue.logger.unknown { "Running until we're killed.  Send SIGHUP to terminate with stats." }
  end
end

def format_float(num); num ? num.round(2) : "-"; end

def format_rate(rate); "#{format_float(rate)}/sec"; end

def print_stat(name, value, rate)
  FluxHue.logger.unknown { "* #{value} #{name} (#{format_rate(rate)})" }
end

STATS = [
  ["requests",       :requests,      :requests_sec],
  ["successes",      :successes,     :successes_sec],
  ["failures",       :failures,      :failures_sec],
  ["hard timeouts",  :hard_timeouts, :hard_timeouts_sec],
  ["soft timeouts",  :soft_timeouts, :soft_timeouts_sec],
]

def print_stats(results)
  STATS.each do |(name, count, rate)|
    print_stat(name, results.send(count), results.send(rate))
  end
end

# TODO: Show per-bridge and aggregate stats.
def print_results(results)
  FluxHue.logger.unknown { "Results:" }
  print_stats(results)

  FluxHue.logger.unknown { "* #{format_float(results.failure_rate)}% failure rate" }
  suffix = " (#{format_float(results.elapsed / ITERATIONS.to_f)}/iteration)" if ITERATIONS > 0
  FluxHue.logger.unknown { "* #{format_float(results.elapsed)} seconds elapsed#{suffix}" }
end