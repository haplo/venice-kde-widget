// Venice.ai API Client
//
// Usage:
//   API.fetchBalance(apiKey, callback)
//     callback(success, data, errorMessage)
//

function fetchBalance(apiKey, callback) {
    if (!apiKey) {
        callback(false, null, "No API key configured")
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
                callback(true, data, null)
            } catch (e) {
                callback(false, null, "Failed to parse response: " + e.message)
            }
        } else if (xhr.status === 401) {
            callback(false, null, "Authentication failed — check your API key")
        } else {
            callback(false, null, "Request failed (HTTP " + xhr.status + ")")
        }
    }

    xhr.onerror = function() {
        callback(false, null, "Network error — check your connection")
    }

    xhr.ontimeout = function() {
        callback(false, null, "Request timed out")
    }

    xhr.send()
}
