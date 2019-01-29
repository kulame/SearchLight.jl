"""
Provides logging functionality for SearchLight apps.
"""
module Loggers

using Millboard, Dates, MiniLogging
using SearchLight

import Base.log
export log


"""
Map Genie log levels to MiniLogging levels
"""
const LOG_LEVEL_MAPPING = Dict(
  :debug    => MiniLogging.DEBUG,
  :info     => MiniLogging.INFO,
  :warn     => MiniLogging.WARN,
  :error    => MiniLogging.ERROR,
  :err      => MiniLogging.ERROR,
  :critical => MiniLogging.CRITICAL
)


"""
    log(message, level = "info"; showst::Bool = true) :: Nothing
    log(message::Any, level::Any = "info"; showst::Bool = false) :: Nothing
    log(message::String, level::Symbol) :: Nothing

Logs `message` to all configured logs (STDOUT, FILE, etc) by delegating to `Lumberjack`.
Supported values for `level` are "info", "warn", "debug", "err" / "error", "critical".
If `level` is `error` or `critical` it will also dump the stacktrace onto STDOUT.

# Examples
```julia
```
"""
function log(message::Union{String,Symbol,Number,Exception}, level::Union{String,Symbol} = :debug; showst = false) :: Nothing
  message = string(message)
  level = string(level)

  basic_config(LOG_LEVEL_MAPPING[SearchLight.config.log_level], log_path())
  length(get_logger().handlers) == 1 && push!(get_logger().handlers, MiniLogging.Handler(stderr, "%Y-%m-%d %H:%M:%S"))

  loggo = get_logger()

  if level == "debug"
    MiniLogging.@debug(loggo, message)
  elseif level == "info"
    MiniLogging.@info(loggo, message)
  elseif level == "warn"
    MiniLogging.@warn(loggo, message)
  elseif level == "error" || level == "err"
    MiniLogging.@error(loggo, message)
  elseif level == "critical"
    MiniLogging.@critical(loggo, message)
  else
    MiniLogging.@debug(loggo, message)
  end

  if (level == "error") && showst
    println()
    stacktrace()
  end

  nothing
end


"""
    truncate_logged_output(output::String) :: String

Truncates (shortens) output based on `output_length` settings and appends "..." -- to be used for limiting the output length when logging.

# Examples
```julia
julia> SearchLight.config.output_length
100

julia> SearchLight.config.output_length = 10
10

julia> Loggers.truncate_logged_output("abc " ^ 10)
"abc abc ab..."
```
"""
function truncate_logged_output(output::String) :: String
  length(output) > SearchLight.config.output_length && output[1:SearchLight.config.output_length] * "..."
end


"""
    setup_loggers()

Sets up default app loggers (STDOUT and per env file loggers) defferring to the logging module.
Automatically invoked.
"""
function setup_loggers()

end


function log_path()
  "$(joinpath(SearchLight.LOG_PATH, SearchLight.config.app_env)).log"
end


"""
    empty_log_queue() :: Vector{Tuple{String,Symbol}}

The SearchLight log queue is used to push log messages in the early phases of framework bootstrap,
when the logger itself is not available. Once the logger is ready, the queue is emptied and the
messages are logged.
Automatically invoked.
"""
function empty_log_queue() :: Nothing
  for log_message in SearchLight.SEARCHLIGHT_LOG_QUEUE
    log(log_message...)
  end

  empty!(SearchLight.SEARCHLIGHT_LOG_QUEUE)

  nothing
end


"""
    macro location()

Provides a macro that injects the FILE and the LINE where the logger was invoked.
"""
macro location()
  :(log(" in $(@__FILE__):$(@__LINE__)", :err))
end

function initlogfile()
  dirname(log_path()) |> mkpath
  touch(log_path())
end

initlogfile()
empty_log_queue()

end
