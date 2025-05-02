// Favi.Dev
// Main JavaScript file for the developer tools UI

// Main variables
let isVisible = false;
let devToolsData = {
    playerData: {},
    resources: [],
    settings: {},
    teleportLocations: [],
    features: {},
    monitoredEvents: [],
    logs: []
};

let currentTheme = 'dark';
let activeTab = 'events';
let isMonitoringEvents = false;

// Initialize the UI when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Hide UI immediately on load to prevent it from flashing on screen
    hideDevTools();
    
    setupTabSwitching();
    setupButtons();
    setupInputs();
    setupToggles();
    startClock();
    
    // When running in FiveM, we need to listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'openDevTools') {
            showDevTools(data.data);
        } else if (data.action === 'closeDevTools') {
            hideDevTools();
        } else if (data.action === 'updatePlayerData') {
            updatePlayerData(data.data);
        } else if (data.action === 'updateResources') {
            updateResourcesList(data.data);
        } else if (data.action === 'updateEventMonitoring') {
            updateEventMonitoring(data.data.events);
        } else if (data.action === 'luaExecutionResult') {
            updateLuaResult(data.data);
        } else if (data.action === 'updateDebugInfo') {
            updateDebugInfo(data.data);
        } else if (data.action === 'clearLogs') {
            clearLogs();
        } else if (data.action === 'addLog') {
            addLog(data.data);
        } else if (data.action === 'copyToClipboard') {
            copyToClipboard(data.data);
        } else if (data.action === 'monitoredEvent') {
            addMonitoredEvent(data.data);
        }
    });
    
    // For testing in browser - disabled for production
    /*
    if (window.location.hostname !== 'nui-frame-app') {
        // Show the UI with mock data for development
        showDevTools({
            playerData: {
                name: 'Test Player',
                id: 123,
                position: { x: 123.45, y: 678.90, z: 29.43 },
                heading: 180.0
            },
            resources: [
                { name: 'qb-core', status: 'started' },
                { name: 'qb-inventory', status: 'started' },
                { name: 'qb-phone', status: 'started' }
            ],
            settings: {
                HotKey: 'F7',
                DefaultFontSize: 14,
                Theme: 'dark',
                ShowClock: true,
                Animation: true,
                BlurBackground: true
            },
            teleportLocations: [
                { name: 'LSPD', x: 440.91, y: -983.04, z: 30.69 },
                { name: 'Hospital', x: 307.76, y: -594.99, z: 43.28 },
                { name: 'Garage', x: -330.01, y: -780.33, z: 33.96 }
            ],
            features: {
                EventMonitoring: { Enabled: true },
                LuaExecution: { Enabled: true },
                ResourceManager: { Enabled: true },
                DebugTools: { 
                    Enabled: true,
                    ShowCoordinates: true,
                    ShowHeading: true,
                    ShowEntityInfo: true,
                    ShowServerInfo: true
                },
                LiveLogs: { Enabled: true }
            }
        });
    }
    */
});

// Setup tab switching
function setupTabSwitching() {
    const tabItems = document.querySelectorAll('.sidebar-item');
    tabItems.forEach(item => {
        item.addEventListener('click', function() {
            const tabId = this.getAttribute('data-tab');
            if (tabId === activeTab) return;
            
            // Update sidebar selection
            document.querySelector('.sidebar-item.active').classList.remove('active');
            this.classList.add('active');
            
            // Update tab content
            document.querySelector('.tab-content.active').classList.remove('active');
            document.getElementById(tabId + '-tab').classList.add('active');
            
            activeTab = tabId;
        });
    });
}

// Setup button click handlers
function setupButtons() {
    // Close button
    document.getElementById('close-button').addEventListener('click', function() {
        hideDevTools();
        sendData('closeDevTools', {});
    });
    
    // Settings button
    document.getElementById('settings-button').addEventListener('click', function() {
        document.querySelector('.sidebar-item.active').classList.remove('active');
        document.querySelector('[data-tab="settings"]').classList.add('active');
        
        document.querySelector('.tab-content.active').classList.remove('active');
        document.getElementById('settings-tab').classList.add('active');
        
        activeTab = 'settings';
    });
    
    // Events tab buttons
    document.getElementById('start-monitoring').addEventListener('click', function() {
        isMonitoringEvents = true;
        sendData('startMonitoringEvents', {});
    });
    
    document.getElementById('stop-monitoring').addEventListener('click', function() {
        isMonitoringEvents = false;
        sendData('stopMonitoringEvents', {});
    });
    
    document.getElementById('clear-events').addEventListener('click', function() {
        document.querySelector('#events-table tbody').innerHTML = '';
        devToolsData.monitoredEvents = [];
    });
    
    document.getElementById('trigger-event').addEventListener('click', function() {
        const eventName = document.getElementById('event-name').value;
        const eventType = document.getElementById('event-type').value;
        const eventArgs = document.getElementById('event-args').value.split(',').map(arg => arg.trim());
        
        if (!eventName) {
            addLog({
                message: 'Please enter an event name',
                type: 'error',
                time: getCurrentTime()
            });
            return;
        }
        
        sendData('triggerEvent', {
            eventName: eventName,
            isServerEvent: eventType === 'server',
            args: eventArgs
        });
    });
    
    // Functions tab buttons
    document.getElementById('execute-function').addEventListener('click', function() {
        const functionName = document.getElementById('function-name').value;
        const functionType = document.getElementById('function-type').value;
        const functionArgs = document.getElementById('function-args').value.split(',').map(arg => arg.trim());
        
        if (!functionName) {
            addLog({
                message: 'Please enter a function name',
                type: 'error',
                time: getCurrentTime()
            });
            return;
        }
        
        sendData('executeFunction', {
            functionName: functionName,
            isServerFunction: functionType === 'server',
            args: functionArgs
        });
    });
    
    document.getElementById('clear-function-result').addEventListener('click', function() {
        document.getElementById('function-result').innerHTML = '// Result will appear here';
    });
    
    // Lua tab buttons
    document.getElementById('execute-lua').addEventListener('click', function() {
        const code = document.getElementById('lua-code').value;
        const context = document.getElementById('lua-context').value;
        
        if (!code) {
            addLog({
                message: 'Please enter some code to execute',
                type: 'error',
                time: getCurrentTime()
            });
            return;
        }
        
        sendData('executeLua', {
            code: code,
            isServerSide: context === 'server'
        });
    });
    
    document.getElementById('clear-lua').addEventListener('click', function() {
        document.getElementById('lua-code').value = '';
        document.getElementById('lua-result').innerHTML = '// Result will appear here';
    });
    
    // Teleport tab buttons
    document.getElementById('copy-coords-vector3').addEventListener('click', function() {
        sendData('copyCoords', { format: 'vector3' });
    });
    
    document.getElementById('copy-coords-vector4').addEventListener('click', function() {
        sendData('copyCoords', { format: 'vector4' });
    });
    
    document.getElementById('copy-coords-table').addEventListener('click', function() {
        sendData('copyCoords', { format: 'table' });
    });
    
    document.getElementById('teleport-to-coords').addEventListener('click', function() {
        const x = document.getElementById('teleport-x').value;
        const y = document.getElementById('teleport-y').value;
        const z = document.getElementById('teleport-z').value;
        const h = document.getElementById('teleport-h').value;
        
        if (!x || !y || !z) {
            addLog({
                message: 'Please enter valid coordinates',
                type: 'error',
                time: getCurrentTime()
            });
            return;
        }
        
        sendData('teleport', {
            x: parseFloat(x),
            y: parseFloat(y),
            z: parseFloat(z),
            h: h ? parseFloat(h) : undefined
        });
    });
    
    document.getElementById('save-current-location').addEventListener('click', function() {
        // This would typically save to the server, for this example we just add to local array
        const name = prompt('Enter a name for this location:');
        if (!name) return;
        
        const coords = devToolsData.playerData.position;
        const heading = devToolsData.playerData.heading;
        
        if (!coords) return;
        
        const newLocation = {
            name: name,
            x: coords.x,
            y: coords.y,
            z: coords.z,
            h: heading
        };
        
        devToolsData.teleportLocations.push(newLocation);
        updateLocationsList();
        
        // In a real implementation, we would send this to the server to save
        // sendData('saveLocation', newLocation);
    });
    
    // Resources tab buttons
    document.getElementById('refresh-resources').addEventListener('click', function() {
        sendData('getResources', {});
    });
    
    // Logs tab buttons
    document.getElementById('clear-logs').addEventListener('click', function() {
        sendData('clearLogs', {});
    });
    
    document.getElementById('export-logs').addEventListener('click', function() {
        // Create a blob with the logs and download it
        const logsContent = devToolsData.logs.map(log => 
            `[${log.time}] [${log.type.toUpperCase()}] ${log.message}`
        ).join('\n');
        
        const blob = new Blob([logsContent], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `devtools_logs_${new Date().toISOString().replace(/:/g, '-')}.txt`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    });
    
    // Settings tab buttons
    document.getElementById('save-settings').addEventListener('click', function() {
        const settings = {
            HotKey: document.getElementById('hotkey').value,
            DefaultFontSize: parseInt(document.getElementById('font-size').value),
            Theme: document.getElementById('theme').value,
            ShowClock: document.getElementById('show-clock').checked,
            Animation: document.getElementById('animation').checked,
            BlurBackground: document.getElementById('blur-background').checked
        };
        
        devToolsData.settings = settings;
        applySettings(settings);
        
        sendData('saveSettings', settings);
        
        addLog({
            message: 'Settings saved successfully',
            type: 'success',
            time: getCurrentTime()
        });
    });
    
    document.getElementById('reset-settings').addEventListener('click', function() {
        // Reset to default settings
        const defaultSettings = {
            HotKey: 'F7',
            DefaultFontSize: 14,
            Theme: 'dark',
            ShowClock: true,
            Animation: true,
            BlurBackground: true
        };
        
        // Update form
        document.getElementById('hotkey').value = defaultSettings.HotKey;
        document.getElementById('font-size').value = defaultSettings.DefaultFontSize;
        document.getElementById('font-size-value').textContent = defaultSettings.DefaultFontSize + 'px';
        document.getElementById('theme').value = defaultSettings.Theme;
        document.getElementById('show-clock').checked = defaultSettings.ShowClock;
        document.getElementById('animation').checked = defaultSettings.Animation;
        document.getElementById('blur-background').checked = defaultSettings.BlurBackground;
        
        // Apply settings
        devToolsData.settings = defaultSettings;
        applySettings(defaultSettings);
        
        sendData('saveSettings', defaultSettings);
        
        addLog({
            message: 'Settings reset to default',
            type: 'info',
            time: getCurrentTime()
        });
    });
}

// Setup input handlers
function setupInputs() {
    // Font size slider
    const fontSizeInput = document.getElementById('font-size');
    const fontSizeValue = document.getElementById('font-size-value');
    
    fontSizeInput.addEventListener('input', function() {
        fontSizeValue.textContent = this.value + 'px';
        document.documentElement.style.setProperty('--font-size', this.value + 'px');
    });
    
    // Resource search
    const resourceSearch = document.getElementById('resource-search');
    resourceSearch.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase();
        const resourceRows = document.querySelectorAll('#resources-table tbody tr');
        
        resourceRows.forEach(row => {
            const resourceName = row.querySelector('td:first-child').textContent.toLowerCase();
            if (resourceName.includes(searchTerm)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });
    
    // Event filter
    const eventFilter = document.getElementById('event-filter');
    eventFilter.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase();
        const eventRows = document.querySelectorAll('#events-table tbody tr');
        
        eventRows.forEach(row => {
            const eventName = row.querySelector('td:nth-child(2)').textContent.toLowerCase();
            if (eventName.includes(searchTerm)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });
    
    // Log level filter
    const logLevelFilter = document.getElementById('log-level');
    logLevelFilter.addEventListener('change', function() {
        const selectedLevel = this.value;
        const logEntries = document.querySelectorAll('.log-entry');
        
        logEntries.forEach(entry => {
            if (selectedLevel === 'all' || entry.getAttribute('data-level') === selectedLevel) {
                entry.style.display = '';
            } else {
                entry.style.display = 'none';
            }
        });
    });
}

// Setup toggle switches
function setupToggles() {
    // Debug toggles
    document.getElementById('toggle-coordinates').addEventListener('change', function() {
        const isChecked = this.checked;
        sendData('toggleDebugSetting', {
            setting: 'ShowCoordinates',
            value: isChecked
        });
    });
    
    document.getElementById('toggle-heading').addEventListener('change', function() {
        const isChecked = this.checked;
        sendData('toggleDebugSetting', {
            setting: 'ShowHeading',
            value: isChecked
        });
    });
    
    document.getElementById('toggle-entity-info').addEventListener('change', function() {
        const isChecked = this.checked;
        sendData('toggleDebugSetting', {
            setting: 'ShowEntityInfo',
            value: isChecked
        });
    });
    
    document.getElementById('toggle-server-info').addEventListener('change', function() {
        const isChecked = this.checked;
        sendData('toggleDebugSetting', {
            setting: 'ShowServerInfo',
            value: isChecked
        });
    });
}

// Start clock
function startClock() {
    updateClock();
    setInterval(updateClock, 1000);
}

// Update clock
function updateClock() {
    const now = new Date();
    const timeString = now.toLocaleTimeString();
    document.getElementById('server-time').textContent = timeString;
}

// Show the developer tools UI
function showDevTools(data) {
    devToolsData = data;
    isVisible = true;
    
    // Update UI with data
    updatePlayerData(data.playerData);
    updateResourcesList(data.resources);
    updateLocationsList();
    
    // Apply settings
    if (data.settings) {
        applySettings(data.settings);
        updateSettingsForm(data.settings);
    }
    
    // Initialize debug toggles
    if (data.features && data.features.DebugTools) {
        document.getElementById('toggle-coordinates').checked = data.features.DebugTools.ShowCoordinates || false;
        document.getElementById('toggle-heading').checked = data.features.DebugTools.ShowHeading || false;
        document.getElementById('toggle-entity-info').checked = data.features.DebugTools.ShowEntityInfo || false;
        document.getElementById('toggle-server-info').checked = data.features.DebugTools.ShowServerInfo || false;
    }
    
    // Show the UI with animation
    const container = document.getElementById('dev-tools-container');
    container.classList.remove('hidden');
    
    // Use setTimeout to ensure the hidden class removal is processed before adding visible
    setTimeout(() => {
        container.classList.add('visible');
        
        if (data.settings && data.settings.Animation) {
            container.classList.add('fade-in');
            setTimeout(() => {
                container.classList.remove('fade-in');
            }, 300);
        }
    }, 10);
}

// Hide the developer tools UI
function hideDevTools() {
    if (!isVisible && document.getElementById('dev-tools-container').classList.contains('hidden')) return;
    isVisible = false;
    
    const container = document.getElementById('dev-tools-container');
    
    if (devToolsData.settings && devToolsData.settings.Animation) {
        container.classList.add('fade-out');
        setTimeout(() => {
            container.classList.remove('visible');
            container.classList.remove('fade-out');
            setTimeout(() => {
                container.classList.add('hidden');
            }, 50);
        }, 300);
    } else {
        container.classList.remove('visible');
        setTimeout(() => {
            container.classList.add('hidden');
        }, 50);
    }
}

// Update player data in the UI
function updatePlayerData(data) {
    devToolsData.playerData = data;
    
    document.getElementById('player-info').textContent = `Player: ${data.name} (ID: ${data.id})`;
    
    // Update coordinates on the teleport tab
    let coordsText = '';
    if (data.position) {
        coordsText = `X: ${parseFloat(data.position.x).toFixed(2)} Y: ${parseFloat(data.position.y).toFixed(2)} Z: ${parseFloat(data.position.z).toFixed(2)}`;
        
        if (data.heading) {
            coordsText += ` H: ${parseFloat(data.heading).toFixed(2)}`;
        }
    }
    
    document.getElementById('current-coords').textContent = coordsText;
    
    // Pre-fill teleport fields with current coordinates
    if (data.position) {
        document.getElementById('teleport-x').value = parseFloat(data.position.x).toFixed(2);
        document.getElementById('teleport-y').value = parseFloat(data.position.y).toFixed(2);
        document.getElementById('teleport-z').value = parseFloat(data.position.z).toFixed(2);
        
        if (data.heading) {
            document.getElementById('teleport-h').value = parseFloat(data.heading).toFixed(2);
        }
    }
}

// Update the resources list in the UI
function updateResourcesList(resources) {
    if (!resources || !Array.isArray(resources)) return;
    
    devToolsData.resources = resources;
    const tableBody = document.querySelector('#resources-table tbody');
    tableBody.innerHTML = '';
    
    resources.forEach(resource => {
        const row = document.createElement('tr');
        
        const nameCell = document.createElement('td');
        nameCell.textContent = resource.name;
        row.appendChild(nameCell);
        
        const statusCell = document.createElement('td');
        statusCell.textContent = resource.status;
        if (resource.status === 'started') {
            statusCell.classList.add('success-text');
        } else if (resource.status === 'stopped') {
            statusCell.classList.add('error-text');
        }
        row.appendChild(statusCell);
        
        const actionsCell = document.createElement('td');
        
        // Only show certain actions based on current status
        if (resource.status === 'started') {
            const restartBtn = document.createElement('button');
            restartBtn.className = 'action-button';
            restartBtn.innerHTML = '<i class="fas fa-sync-alt"></i> Restart';
            restartBtn.addEventListener('click', function() {
                sendData('restartResource', { resourceName: resource.name });
            });
            actionsCell.appendChild(restartBtn);
            
            const stopBtn = document.createElement('button');
            stopBtn.className = 'action-button';
            stopBtn.innerHTML = '<i class="fas fa-stop"></i> Stop';
            stopBtn.addEventListener('click', function() {
                sendData('stopResource', { resourceName: resource.name });
            });
            actionsCell.appendChild(stopBtn);
        } else {
            const startBtn = document.createElement('button');
            startBtn.className = 'action-button';
            startBtn.innerHTML = '<i class="fas fa-play"></i> Start';
            startBtn.addEventListener('click', function() {
                sendData('startResource', { resourceName: resource.name });
            });
            actionsCell.appendChild(startBtn);
        }
        
        row.appendChild(actionsCell);
        tableBody.appendChild(row);
    });
}

// Update the events monitoring table in the UI
function updateEventMonitoring(events) {
    if (!events || !Array.isArray(events)) return;
    
    devToolsData.monitoredEvents = events;
    const tableBody = document.querySelector('#events-table tbody');
    tableBody.innerHTML = '';
    
    events.forEach(event => {
        addEventToTable(event);
    });
}

// Add a monitored event to the UI
function addMonitoredEvent(event) {
    devToolsData.monitoredEvents.push(event);
    
    // Keep the array within limits
    if (devToolsData.monitoredEvents.length > 100) {
        devToolsData.monitoredEvents.shift();
    }
    
    // Add to table
    addEventToTable(event);
}

// Add event to the table
function addEventToTable(event) {
    const tableBody = document.querySelector('#events-table tbody');
    const row = document.createElement('tr');
    
    const timeCell = document.createElement('td');
    timeCell.textContent = event.time;
    row.appendChild(timeCell);
    
    const nameCell = document.createElement('td');
    nameCell.textContent = event.name;
    row.appendChild(nameCell);
    
    const sourceCell = document.createElement('td');
    sourceCell.textContent = event.source;
    row.appendChild(sourceCell);
    
    const argsCell = document.createElement('td');
    argsCell.textContent = JSON.stringify(event.args);
    row.appendChild(argsCell);
    
    const actionsCell = document.createElement('td');
    
    const copyBtn = document.createElement('button');
    copyBtn.className = 'action-button';
    copyBtn.innerHTML = '<i class="fas fa-copy"></i>';
    copyBtn.title = 'Copy event data';
    copyBtn.addEventListener('click', function() {
        copyToClipboard(JSON.stringify(event, null, 2));
    });
    actionsCell.appendChild(copyBtn);
    
    const triggerBtn = document.createElement('button');
    triggerBtn.className = 'action-button';
    triggerBtn.innerHTML = '<i class="fas fa-bolt"></i>';
    triggerBtn.title = 'Trigger this event';
    triggerBtn.addEventListener('click', function() {
        document.getElementById('event-name').value = event.name;
        document.getElementById('event-type').value = event.source === 'server' ? 'server' : 'client';
        
        // Convert args to comma-separated string if they exist
        if (event.args && event.args.length > 0) {
            document.getElementById('event-args').value = JSON.stringify(event.args)
                .replace(/^\[|\]$/g, '')  // Remove brackets
                .replace(/"/g, '');       // Remove quotes
        } else {
            document.getElementById('event-args').value = '';
        }
    });
    actionsCell.appendChild(triggerBtn);
    
    row.appendChild(actionsCell);
    tableBody.appendChild(row);
    
    // Filter if a filter is active
    const searchTerm = document.getElementById('event-filter').value.toLowerCase();
    if (searchTerm && !event.name.toLowerCase().includes(searchTerm)) {
        row.style.display = 'none';
    }
}

// Update the locations list in the teleport tab
function updateLocationsList() {
    const locationsList = document.getElementById('locations-list');
    locationsList.innerHTML = '';
    
    if (!devToolsData.teleportLocations || !Array.isArray(devToolsData.teleportLocations)) return;
    
    devToolsData.teleportLocations.forEach(location => {
        const locationItem = document.createElement('div');
        locationItem.className = 'location-item';
        locationItem.textContent = location.name;
        
        locationItem.addEventListener('click', function() {
            // Fill the teleport fields
            document.getElementById('teleport-x').value = parseFloat(location.x).toFixed(2);
            document.getElementById('teleport-y').value = parseFloat(location.y).toFixed(2);
            document.getElementById('teleport-z').value = parseFloat(location.z).toFixed(2);
            
            if (location.h) {
                document.getElementById('teleport-h').value = parseFloat(location.h).toFixed(2);
            } else {
                document.getElementById('teleport-h').value = '';
            }
            
            // Mark this item as selected
            document.querySelectorAll('.location-item.active').forEach(item => {
                item.classList.remove('active');
            });
            
            this.classList.add('active');
        });
        
        locationsList.appendChild(locationItem);
    });
}

// Update the Lua result in the UI
function updateLuaResult(data) {
    const resultArea = document.getElementById('lua-result');
    
    if (data.success) {
        resultArea.innerHTML = `<span class="success-text">Success:</span> ${escapeHtml(data.result || '')}`;
    } else {
        resultArea.innerHTML = `<span class="error-text">Error:</span> ${escapeHtml(data.result || '')}`;
    }
}

// Update debug info in the UI
function updateDebugInfo(data) {
    // Update coordinates display
    if (data.coords) {
        document.getElementById('current-coords').textContent = data.coords;
    }
    
    // Update player debug data
    if (data.playerInfo) {
        const playerDataEl = document.getElementById('player-debug-data');
        let playerHtml = '';
        
        playerHtml += `<div>Health: ${data.playerInfo.health}</div>`;
        playerHtml += `<div>Armor: ${data.playerInfo.armor}</div>`;
        playerHtml += `<div>Speed: ${data.playerInfo.speed.toFixed(1)} km/h</div>`;
        playerHtml += `<div>Vehicle: ${data.playerInfo.vehicle}</div>`;
        
        playerDataEl.innerHTML = playerHtml;
    }
    
    // Update entity debug data
    if (data.entityInfo) {
        const entityDataEl = document.getElementById('entity-debug-data');
        let entityHtml = '';
        
        entityHtml += `<div>Type: ${data.entityInfo.type}</div>`;
        entityHtml += `<div>Model: ${data.entityInfo.model || data.entityInfo.hash}</div>`;
        entityHtml += `<div>Hash: ${data.entityInfo.hashHex}</div>`;
        entityHtml += `<div>Distance: ${data.entityInfo.distance}m</div>`;
        entityHtml += `<div>Health: ${data.entityInfo.health}</div>`;
        entityHtml += `<div>NetID: ${data.entityInfo.netId}</div>`;
        
        // Add type-specific info
        if (data.entityInfo.type === 'Vehicle') {
            entityHtml += `<div>Plate: ${data.entityInfo.plate}</div>`;
            entityHtml += `<div>Class: ${data.entityInfo.class}</div>`;
        } else if (data.entityInfo.type === 'Ped') {
            entityHtml += `<div>Is Player: ${data.entityInfo.isPlayer ? 'Yes' : 'No'}</div>`;
        }
        
        entityDataEl.innerHTML = entityHtml;
    } else {
        document.getElementById('entity-debug-data').innerHTML = '<div>No entity found</div>';
    }
}

// Add a log to the logs tab
function addLog(log) {
    // Add to local log array
    devToolsData.logs.push(log);
    
    // Keep the array within limits
    if (devToolsData.logs.length > 200) {
        devToolsData.logs.shift();
    }
    
    const logsContainer = document.getElementById('logs-container');
    const logEntry = document.createElement('div');
    logEntry.className = 'log-entry';
    logEntry.setAttribute('data-level', log.type);
    
    // Check if filtered
    const logLevelFilter = document.getElementById('log-level').value;
    if (logLevelFilter !== 'all' && log.type !== logLevelFilter) {
        logEntry.style.display = 'none';
    }
    
    const timestamp = document.createElement('span');
    timestamp.className = 'log-timestamp';
    timestamp.textContent = log.time;
    
    const level = document.createElement('span');
    level.className = 'log-level ' + log.type;
    level.textContent = log.type.toUpperCase();
    
    const message = document.createElement('span');
    message.className = 'log-message';
    message.textContent = log.message;
    
    logEntry.appendChild(timestamp);
    logEntry.appendChild(level);
    logEntry.appendChild(message);
    
    logsContainer.appendChild(logEntry);
    
    // Auto-scroll to bottom if feature is enabled
    if (devToolsData.features && devToolsData.features.LiveLogs && devToolsData.features.LiveLogs.AutoScroll) {
        logsContainer.scrollTop = logsContainer.scrollHeight;
    }
}

// Clear all logs
function clearLogs() {
    document.getElementById('logs-container').innerHTML = '';
    devToolsData.logs = [];
}

// Apply settings to the UI
function applySettings(settings) {
    if (!settings) return;
    
    // Set font size
    if (settings.DefaultFontSize) {
        document.documentElement.style.setProperty('--font-size', settings.DefaultFontSize + 'px');
    }
    
    // Set theme
    if (settings.Theme) {
        if (settings.Theme === 'light') {
            document.body.classList.add('light-theme');
        } else {
            document.body.classList.remove('light-theme');
        }
        currentTheme = settings.Theme;
    }
    
    // Set animation
    if (settings.Animation === false) {
        // Disable animations
        const style = document.createElement('style');
        style.id = 'no-animation-style';
        style.textContent = '* { animation: none !important; transition: none !important; }';
        document.head.appendChild(style);
    } else {
        // Enable animations (remove the style if it exists)
        const noAnimStyle = document.getElementById('no-animation-style');
        if (noAnimStyle) {
            noAnimStyle.remove();
        }
    }
    
    // Set clock visibility
    if (settings.ShowClock === false) {
        document.getElementById('server-time').style.display = 'none';
    } else {
        document.getElementById('server-time').style.display = '';
    }
}

// Update settings form
function updateSettingsForm(settings) {
    if (!settings) return;
    
    // Update input values
    if (settings.DefaultFontSize) {
        document.getElementById('font-size').value = settings.DefaultFontSize;
        document.getElementById('font-size-value').textContent = settings.DefaultFontSize + 'px';
    }
    
    if (settings.Theme) {
        document.getElementById('theme').value = settings.Theme;
    }
    
    if (settings.HotKey) {
        document.getElementById('hotkey').value = settings.HotKey;
    }
    
    document.getElementById('show-clock').checked = settings.ShowClock !== false;
    document.getElementById('animation').checked = settings.Animation !== false;
    document.getElementById('blur-background').checked = settings.BlurBackground !== false;
}

// Get current time
function getCurrentTime() {
    const now = new Date();
    return now.toLocaleTimeString();
}

// Send data to game (NUI callback)
function sendData(action, data) {
    // When running in browser, just log to console
    if (window.location.hostname !== 'nui-frame-app') {
        console.log('NUI Callback:', action, data);
        return;
    }
    
    fetch(`https://qb-devtools/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(response => {
        if (response.result) {
            // Process callback result if needed
            if (action === 'executeFunction') {
                document.getElementById('function-result').innerHTML = 
                    response.success 
                        ? escapeHtml(response.result) 
                        : `<span class="error-text">Error:</span> ${escapeHtml(response.message)}`;
            }
        }
    })
    .catch(error => {
        console.error('Error in NUI callback:', error);
    });
}

// Utility functions
function copyToClipboard(text) {
    // Create a temporary textarea
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'absolute';
    textarea.style.left = '-99999px';
    document.body.appendChild(textarea);
    textarea.select();
    
    try {
        document.execCommand('copy');
        console.log('Text copied to clipboard');
    } catch (err) {
        console.error('Failed to copy text: ', err);
    }
    
    document.body.removeChild(textarea);
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    if (!text) return '';
    
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
