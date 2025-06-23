import QtQuick

QtObject {
    id: homeAssistant
    
    property string baseUrl: ""
    property string accessToken: ""
    property var entityStates: ({})
    property var allEntities: []
    property bool isLoadingEntities: false
    
    signal stateChanged(string entityId, var state)
    signal error(string message)
    signal entitiesLoaded(var entities)
    
    function callService(domain, service, entityId, serviceData, callback) {
        if (!baseUrl || !accessToken) {
            error("Home Assistant URL and access token must be configured")
            return
        }
        
        var xhr = new XMLHttpRequest()
        var url = baseUrl + "/api/services/" + domain + "/" + service
        
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        xhr.setRequestHeader("Content-Type", "application/json")
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    try {
                        var response = JSON.parse(xhr.responseText || "[]")
                        if (callback) callback(true, response)
                    } catch (e) {
                        if (callback) callback(true, [])
                    }
                } else {
                    console.log("Home Assistant API error:", xhr.status, xhr.responseText)
                    error("API call failed: " + xhr.status)
                    if (callback) callback(false, xhr.responseText)
                }
            }
        }
        
        var requestData = {
            entity_id: entityId
        }
        
        if (serviceData) {
            for (var key in serviceData) {
                requestData[key] = serviceData[key]
            }
        }
        
        xhr.send(JSON.stringify(requestData))
    }
    
    function getState(entityId, callback) {
        if (!baseUrl || !accessToken) {
            error("Home Assistant URL and access token must be configured")
            return
        }
        
        var xhr = new XMLHttpRequest()
        var url = baseUrl + "/api/states/" + entityId
        
        xhr.open("GET", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var state = JSON.parse(xhr.responseText)
                        entityStates[entityId] = state
                        stateChanged(entityId, state)
                        if (callback) callback(true, state)
                    } catch (e) {
                        console.log("Error parsing state response:", e)
                        if (callback) callback(false, null)
                    }
                } else {
                    console.log("Failed to get state for", entityId, ":", xhr.status)
                    if (callback) callback(false, null)
                }
            }
        }
        
        xhr.send()
    }
    
    function getAllEntities(callback) {
        if (!baseUrl || !accessToken) {
            error("Home Assistant URL and access token must be configured")
            return
        }
        
        if (isLoadingEntities) {
            console.log("Already loading entities, skipping request")
            return
        }
        
        isLoadingEntities = true
        var xhr = new XMLHttpRequest()
        var url = baseUrl + "/api/states"
        
        xhr.open("GET", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingEntities = false
                if (xhr.status === 200) {
                    try {
                        var states = JSON.parse(xhr.responseText)
                        var entities = []
                        
                        for (var i = 0; i < states.length; i++) {
                            var state = states[i]
                            var entity = {
                                entity_id: state.entity_id,
                                friendly_name: state.attributes.friendly_name || state.entity_id,
                                domain: state.entity_id.split('.')[0],
                                state: state.state,
                                icon: state.attributes.icon || "",
                                device_class: state.attributes.device_class || "",
                                unit_of_measurement: state.attributes.unit_of_measurement || ""
                            }
                            entities.push(entity)
                        }
                        
                        // Sort entities by domain, then by friendly name
                        entities.sort(function(a, b) {
                            if (a.domain !== b.domain) {
                                return a.domain.localeCompare(b.domain)
                            }
                            return a.friendly_name.localeCompare(b.friendly_name)
                        })
                        
                        allEntities = entities
                        entitiesLoaded(entities)
                        if (callback) callback(true, entities)
                    } catch (e) {
                        console.log("Error parsing entities response:", e)
                        error("Failed to parse entities list")
                        if (callback) callback(false, [])
                    }
                } else {
                    console.log("Failed to get entities:", xhr.status, xhr.responseText)
                    error("Failed to load entities: " + xhr.status)
                    if (callback) callback(false, [])
                }
            }
        }
        
        xhr.send()
    }
    
    function testConnection(callback) {
        if (!baseUrl || !accessToken) {
            error("Home Assistant URL and access token must be configured")
            return
        }
        
        var xhr = new XMLHttpRequest()
        var url = baseUrl + "/api/"
        
        xhr.open("GET", url, true)
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (callback) callback(true, response.message || "Connected successfully")
                    } catch (e) {
                        if (callback) callback(true, "Connected successfully")
                    }
                } else {
                    var errorMsg = "Connection failed: " + xhr.status
                    if (xhr.status === 401) {
                        errorMsg = "Authentication failed - check your access token"
                    } else if (xhr.status === 0) {
                        errorMsg = "Connection failed - check your Home Assistant URL"
                    }
                    error(errorMsg)
                    if (callback) callback(false, errorMsg)
                }
            }
        }
        
        xhr.send()
    }
    
    function searchEntities(query, domains) {
        var filtered = []
        var queryLower = query.toLowerCase()
        
        for (var i = 0; i < allEntities.length; i++) {
            var entity = allEntities[i]
            
            // Filter by domain if specified
            if (domains && domains.length > 0 && domains.indexOf(entity.domain) === -1) {
                continue
            }
            
            // Search in entity_id and friendly_name
            if (entity.entity_id.toLowerCase().indexOf(queryLower) !== -1 ||
                entity.friendly_name.toLowerCase().indexOf(queryLower) !== -1) {
                filtered.push(entity)
            }
        }
        
        return filtered
    }
    
    function toggleEntity(entityId) {
        var domain = entityId.split('.')[0]
        
        switch (domain) {
            case 'light':
                callService('light', 'toggle', entityId)
                break
            case 'switch':
                callService('switch', 'toggle', entityId)
                break
            case 'automation':
                callService('automation', 'toggle', entityId)
                break
            case 'fan':
                callService('fan', 'toggle', entityId)
                break
            case 'input_boolean':
                callService('input_boolean', 'toggle', entityId)
                break
            default:
                callService('homeassistant', 'toggle', entityId)
                break
        }
    }
    
    function turnOn(entityId, serviceData) {
        var domain = entityId.split('.')[0]
        callService(domain, 'turn_on', entityId, serviceData)
    }
    
    function turnOff(entityId) {
        var domain = entityId.split('.')[0]
        callService(domain, 'turn_off', entityId)
    }
}
