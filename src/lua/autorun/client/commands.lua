local profiles = {}
local BINMAN_VERSION = "1.0.0"
local BINMAN_DIRECTORY = "binman"


// Internal functions
local ValidateProfileName = function( args )
    if ( table.IsEmpty( args ) ) then
        error( "Console command argument list was empty." )
    end

    local name = args[1]

    if ( name:match( "%W" ) ) then
        print( "BinMan: Invalid profile name '" .. name .."' - must only be made up of alphanumeric characters. Aborted." )
        return nil
    end

    if args[ 2 ] ~= nil then
        print( "BinMan: Profile names must be a single string. Aborted." )
        return nil
    end

    return name:lower()
end

local GenerateFilePath = function ( name )
    return BINMAN_DIRECTORY .. "/" .. name .. ".json"
end


// Console command functions
local SaveProfile = function( ply, cmd, args )
    // Check that profile name is valid
    local profile = ValidateProfileName( args )
    if profile == nil then return end

    // Gather all binds into a data structure
    local binds = {}
    for key = 1, BUTTON_CODE_LAST do
        binds[ key ] = input.LookupKeyBinding( key )
    end

    // Store all of the binds in a file
    file.Write( GenerateFilePath( profile ), util.TableToJSON( binds ) )

    // Add profile to list of profiles if not already present
    if ( profiles[ profile ] == nil ) then
        profiles[ profile ] = profile
    end

    print( "BinMan: Profile saved - '" .. profile .. "'." )
end

local LoadProfile = function ( ply, cmd, args )
    // Check that profile name is valid
    local profile = ValidateProfileName( args )
    if profile == nil then return end

    // Read binds from file
    local contents = file.Read( GenerateFilePath( profile ), "DATA" )
    local binds = {}
    if contents == nil then
        print( "BinMan: No profile named '" .. profile .. "' exists. Aborted." )
        return
    else
        binds = util.JSONToTable( contents )
        if ( binds == nil or table.IsEmpty( binds ) ) then
            print( "BinMan: Profile '" .. profile "' appears to be corrupted. Aborted." )
            return
        end
    end

    // Save the existing binds as "previous" profile as a backup
    SaveProfile( ply, cmd, { "previous", } )

    // Set the loaded binds as the new binds
    // TODO - there is currently no way to set user binds using GLua

    print( "BinMan: Loaded profile '" .. profile .. "'. To restore previous binds, load the profile 'previous'." )
end

local AutoCompleteProfiles = function ( cmd, stringargs )
    // TODO
    print( "UNIMPLEMENTED" )
end


// Create BinMan data directory if it doesn't already exist
if ( not file.Exists( BINMAN_DIRECTORY, "DATA" ) ) then
    file.CreateDir( BINMAN_DIRECTORY )
else
    // Retrieve existing profile names for autocompletion
    local files, _ = file.Find( BINMAN_DIRECTORY .. "/*.json", "DATA" )
    for _, filename in ipairs( files ) do
        name = string.sub( filename, 1, -6 )  // Get profile name without ".json"
        profiles[ name ] = name
    end
end

// Register console commands
concommand.Add( "binman_save", SaveProfile, AutoCompleteProfiles, "Save your current keybinds as a named profile." )
concommand.Add( "binman_load", LoadProfile, AutoCompleteProfiles, "Load a named binds profile. Use 'previous' for keybinds used before last profile load." )
