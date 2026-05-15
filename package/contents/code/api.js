// Venice.ai API Client
//
// Usage:
//   API.fetchBalance(apiKey, callback)
//     callback(success, data, errorMessage, errorKind)
//
// errorKind values:
//   "auth"     - HTTP 401/403, the token is missing/invalid/expired
//   "network"  - transport error
//   "timeout"  - request timed out
//   "http"     - other non-2xx HTTP status
//   "parse"    - response body could not be parsed
//   "config"   - caller passed no API key
//   null       - on success

function fetchBalance(apiKey, callback) {
    if (!apiKey) {
        callback(false, null, "No API key configured", "config")
        return
    }

    var xhr = new XMLHttpRequest()
    var url = "https://api.venice.ai/api/v1/billing/balance"

    xhr.open("GET", url)
    xhr.setRequestHeader("Authorization", "Bearer " + apiKey)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.timeout = 10000

    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return

        if (xhr.status === 200) {
            try {
                var data = JSON.parse(xhr.responseText)
                callback(true, data, null, null)
            } catch (e) {
                callback(false, null, "Failed to parse response: " + e.message, "parse")
            }
        } else if (xhr.status === 401 || xhr.status === 403) {
            callback(false, null, "Authentication failed — set a valid API token", "auth")
        } else {
            callback(false, null, "Request failed (HTTP " + xhr.status + ")", "http")
        }
    }

    xhr.onerror = function() {
        callback(false, null, "Network error — check your connection", "network")
    }

    xhr.ontimeout = function() {
        callback(false, null, "Request timed out", "timeout")
    }

    xhr.send()
}
