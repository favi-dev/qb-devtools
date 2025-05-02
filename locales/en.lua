local Translations = {
    error = {
        no_permission = 'You do not have permission to use this',
        invalid_command = 'Invalid command',
        invalid_resource = 'Invalid resource name',
        execution_failed = 'Execution failed',
        restart_failed = 'Failed to restart resource',
        invalid_target = 'Invalid target player',
        function_not_found = 'Function not found',
        invalid_parameters = 'Invalid parameters',
        restricted_function = 'This function is restricted',
    },
    success = {
        command_executed = 'Command executed successfully',
        resource_restarted = 'Resource restarted successfully',
        teleported = 'Teleported successfully',
        function_executed = 'Function executed successfully',
    },
    info = {
        dev_tools_activated = 'Developer Tools activated',
        dev_tools_deactivated = 'Developer Tools deactivated',
        coordinates_copied = 'Coordinates copied to clipboard',
        event_monitoring_started = 'Event monitoring started',
        event_monitoring_stopped = 'Event monitoring stopped',
        logs_cleared = 'Logs cleared',
        event_triggered = 'Event triggered',
    },
    ui = {
        title = 'Developer Tools',
        close = 'Close',
        save = 'Save',
        apply = 'Apply',
        cancel = 'Cancel',
        reload = 'Reload',
        clear = 'Clear',
        copy = 'Copy',
        
        -- Tabs
        tab_events = 'Events',
        tab_functions = 'Functions',
        tab_lua = 'Lua Executor',
        tab_teleport = 'Teleport',
        tab_debug = 'Debug',
        tab_resources = 'Resources',
        tab_logs = 'Logs',
        tab_settings = 'Settings',
        
        -- Events tab
        start_monitoring = 'Start Monitoring',
        stop_monitoring = 'Stop Monitoring',
        filter_events = 'Filter Events',
        event_name = 'Event Name',
        event_source = 'Source',
        event_args = 'Arguments',
        event_time = 'Time',
        trigger_event = 'Trigger Event',
        
        -- Functions tab
        execute_function = 'Execute Function',
        function_name = 'Function Name',
        function_args = 'Arguments',
        result = 'Result',
        
        -- Lua executor tab
        execute_code = 'Execute Code',
        execution_context = 'Execution Context',
        client_side = 'Client-side',
        server_side = 'Server-side',
        execution_result = 'Execution Result',
        
        -- Teleport tab
        current_location = 'Current Location',
        saved_locations = 'Saved Locations',
        custom_coordinates = 'Custom Coordinates',
        x_coordinate = 'X Coordinate',
        y_coordinate = 'Y Coordinate',
        z_coordinate = 'Z Coordinate',
        teleport_to = 'Teleport To',
        save_current = 'Save Current Location',
        
        -- Debug tab
        player_info = 'Player Info',
        entity_info = 'Entity Info',
        server_info = 'Server Info',
        show_coordinates = 'Show Coordinates',
        show_heading = 'Show Heading',
        show_entity_info = 'Show Entity Info',
        
        -- Resources tab
        resource_name = 'Resource Name',
        resource_status = 'Status',
        restart_resource = 'Restart',
        start_resource = 'Start',
        stop_resource = 'Stop',
        search_resources = 'Search Resources',
        
        -- Logs tab
        log_level = 'Log Level',
        log_message = 'Message',
        log_timestamp = 'Timestamp',
        clear_logs = 'Clear Logs',
        export_logs = 'Export Logs',
        
        -- Settings tab
        font_size = 'Font Size',
        theme = 'Theme',
        dark_theme = 'Dark',
        light_theme = 'Light',
        hotkey = 'Hotkey',
        show_clock = 'Show Clock',
        animation = 'Animation',
        blur_background = 'Blur Background',
        reset_settings = 'Reset Settings',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
