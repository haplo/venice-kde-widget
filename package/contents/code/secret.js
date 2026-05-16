// Wrapper around the kwallet.sh helper, driven via a P5Support executable
// DataSource provided by the caller.
//
// Usage (the caller owns one P5Support.DataSource bound to "executable" and
// forwards its onNewData signal to Secret.handleData):
//
//     P5Support.DataSource {
//         id: execSource
//         engine: "executable"
//         connectedSources: []
//         onNewData: (sourceName, data) => Secret.handleData(execSource, sourceName, data)
//     }
//
//     Secret.load(execSource, scriptPath, function(token, error) { ... })
//     Secret.save(execSource, scriptPath, token, function(ok, error) { ... })
//     Secret.clear(execSource, scriptPath, function(ok, error) { ... })
//     Secret.cancelAll(execSource) // drop any in-flight callbacks
//
// `token` in the load callback is "" when no secret is stored (not an error).
// `error` is null on success.
//
// Logging never includes the token value; only the subcommand + exit code,
// and helper stderr (only on failure — secret-tool's stderr never contains
// the secret).

// Single-quote-escape a value for /bin/sh so it can be embedded safely.
function shQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
}

// Pending callbacks keyed by sourceName so we can dispatch via handleData().
// Each entry is { generation: <int>, callback: function }. The generation
// counter lets cancel() invalidate an in-flight call so a late response
// (e.g. arriving after a watchdog timeout) is silently dropped instead of
// stomping on caller state.
var _pending = {}
var _generation = 0

// Caller wires this to the DataSource's onNewData signal.
function handleData(dataSource, sourceName, data) {
    var entry = _pending[sourceName]
    if (!entry) return
    delete _pending[sourceName]
    dataSource.disconnectSource(sourceName)
    entry.callback(data)
}

// Cancel an in-flight call so a late response is ignored. Safe to call
// whether or not the call is still pending. Returns true if a pending
// call was cancelled.
function cancel(dataSource, command) {
    if (!_pending[command]) return false
    delete _pending[command]
    dataSource.disconnectSource(command)
    return true
}

// Cancel every in-flight call. Used by the widget watchdog to ensure a
// late response can't stomp on user-visible state after we've already
// given up and moved on.
function cancelAll(dataSource) {
    var cancelled = 0
    for (var cmd in _pending) {
        if (!Object.prototype.hasOwnProperty.call(_pending, cmd)) continue
        delete _pending[cmd]
        dataSource.disconnectSource(cmd)
        cancelled += 1
    }
    return cancelled
}

function _run(dataSource, subcommand, command, callback) {
    _generation += 1
    var myGen = _generation
    console.log("[venice/secret] running:", subcommand, "gen=", myGen)
    _pending[command] = {
        generation: myGen,
        callback: function(data) {
            var exitCode = data["exit code"]
            console.log("[venice/secret]", subcommand, "exit=", exitCode, "gen=", myGen)
            callback(data)
        }
    }
    dataSource.connectSource(command)
}

function load(dataSource, scriptPath, callback) {
    var cmd = "sh " + shQuote(scriptPath) + " load"
    _run(dataSource, "load", cmd, function(data) {
        var stdout = (data["stdout"] || "").toString()
        // Strip exactly one trailing newline if present (secret-tool appends one).
        if (stdout.length && stdout.charAt(stdout.length - 1) === "\n") {
            stdout = stdout.substring(0, stdout.length - 1)
        }
        var exitCode = data["exit code"]
        if (exitCode === 0) {
            callback(stdout, null)
        } else if (exitCode === 1) {
            // No match — treat as "no token stored".
            callback("", null)
        } else {
            var stderr = (data["stderr"] || "").toString().trim()
            console.log("[venice/secret] load stderr:", stderr)
            callback("", stderr || ("kwallet.sh load failed (exit " + exitCode + ")"))
        }
    })
}

function save(dataSource, scriptPath, token, callback) {
    if (!token) {
        callback(false, "Token is empty")
        return
    }
    // Pass the token via env var so it doesn't appear as a script argument.
    // It does briefly appear in /bin/sh's argv (visible to the same user only)
    // — acceptable trade-off given P5Support has no stdin channel.
    var cmd = "env VENICE_TOKEN=" + shQuote(token) + " sh " + shQuote(scriptPath) + " store"
    _run(dataSource, "store", cmd, function(data) {
        var exitCode = data["exit code"]
        if (exitCode === 0) {
            callback(true, null)
        } else {
            var stderr = (data["stderr"] || "").toString().trim()
            console.log("[venice/secret] store stderr:", stderr)
            callback(false, stderr || ("kwallet.sh store failed (exit " + exitCode + ")"))
        }
    })
}

function clear(dataSource, scriptPath, callback) {
    var cmd = "sh " + shQuote(scriptPath) + " clear"
    _run(dataSource, "clear", cmd, function(data) {
        var exitCode = data["exit code"]
        if (exitCode === 0) {
            callback(true, null)
        } else {
            var stderr = (data["stderr"] || "").toString().trim()
            console.log("[venice/secret] clear stderr:", stderr)
            callback(false, stderr || ("kwallet.sh clear failed (exit " + exitCode + ")"))
        }
    })
}
