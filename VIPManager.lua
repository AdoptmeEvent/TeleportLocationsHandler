-- This is a LocalScript (put in StarterPlayerScripts or similar)
-- This script is designed to automatically teleport the local player to the VIP interior,
-- and then place the character directly onto a specific part (Floor) inside the model once it is loaded.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Attempt to require necessary modules.
local InteriorsM = nil
local UIManager = nil 

local successInteriorsM, errorMessageInteriorsM = pcall(function()
    InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
end)

if not successInteriorsM then
    warn("Failed to require InteriorsM:", errorMessageInteriorsM)
    warn("Please ensure the path 'ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM' is correct.")
    return
end

local successUIManager, errorMessageUIManager = pcall(function()
    -- UIManager is often found in ReplicatedStorage or as a service.
    UIManager = require(ReplicatedStorage:WaitForChild("Fsys")).load("UIManager")
end)

if not successUIManager or not UIManager then
    warn("Failed to require UIManager module:", errorMessageUIManager)
    warn("Attempting to get UIManager as a service (less likely for this context)...")
    UIManager = game:GetService("UIManager") -- Fallback, though less likely to be the correct UIManager for apps
    if not UIManager then
        warn("Could not load UIManager module or service. Teleport script might not function correctly.")
        return
    end
end


print("InteriorsM module loaded successfully. Proceeding with automatic teleport setup.")
print("UIManager module loaded successfully.")


-- --- TELEPORT SETTINGS ---
local teleportSettings = {
    fade_in_length = 0.5, -- Duration of the fade-in effect (seconds)
    fade_out_length = 0.4, -- Duration of the fade-out effect (seconds)
    fade_color = Color3.new(0, 0, 0), -- Color to fade to (black in this case)

    player_to_teleport_to = nil,
    anchor_char_immediately = true, -- Whether to anchor the character right away
    post_character_anchored_wait = 0.5, -- Wait time after character is anchored

    -- These properties are part of the settings table expected by enter_smooth.
    door_id_for_location_module = nil,
    exiting_door = nil,
    
    -- Callback function executed just before the player starts teleporting.
    player_about_to_teleport = function() print("Player is about to teleport...") end,
}

-- --- DIRECT TELEPORT TO VIP ---
local destinationId = "VIP" -- New destination is VIP
local doorIdForTeleport = "MainDoor" -- This ID should match the door object name in the VIP interior

-- Function to handle position adjustment after the teleport is visually complete.
local function handlePostTeleportMovement()
    
    local character = LocalPlayer.Character
    
    -- Wait up to 5 seconds for the HumanoidRootPart to appear
    local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart", 5) 

    if not humanoidRootPart then
        warn("HumanoidRootPart not found after character load.")
        return
    end
    
    -- --- ROBUST WAIT FOR TARGET MODEL ---
    local vip = nil 
    local interiors = workspace:FindFirstChild("Interiors")
    
    if interiors then
        print("Waiting for VIP model to appear in Workspace.Interiors...")
        -- Wait up to 10 seconds for the VIP model to load
        vip = interiors:WaitForChild("VIP", 10) 
    end

    if not vip then
        warn("VIP model did not load within the timeout period.") 
        return
    end
    
    -- Initial wait to ensure the screen fade is completely gone and the module has done its first CFrame.
    task.wait(1.0) 

    -- FIND TARGET PART: Search for the specific Floor part inside the loaded VIP interior.
    -- Path: workspace.Interiors.VIP.Visuals.Floor
    local targetPart = vip:FindFirstChild("Visuals", true) 
        and vip.Visuals:FindFirstChild("Floor", true)


    if targetPart and targetPart:IsA("BasePart") then
        
        -- Set the CFrame to the target part's position, plus a larger vertical offset (5.0 studs) for safety.
        local targetCFrame = targetPart.CFrame + Vector3.new(0, 5.0, 0) -- CHANGED: Increased vertical offset to 5.0
        local totalTime = 0
        local ENFORCEMENT_DURATION = 2.0 -- How long to aggressively set the position (2 seconds)
        
        -- AGGRESSIVE CFrame ENFORCEMENT: Use Heartbeat to constantly override the CFrame.
        -- Declare connection outside the Heartbeat function so it can be reliably disconnected.
        local connection = nil 
        
        connection = RunService.Heartbeat:Connect(function(dt)
            totalTime = totalTime + dt
            
            -- Continually set the CFrame to ensure the module cannot override it
            humanoidRootPart.CFrame = targetCFrame
            humanoidRootPart.Anchored = false 
            
            -- Stop hammering the CFrame after the duration is met
            if totalTime > ENFORCEMENT_DURATION then
                if connection then -- Check if connection is valid before disconnecting
                    connection:Disconnect()
                end
                print("Aggressive CFrame enforcement finished. Character should be stable at the VIP Floor.")
            end
        end)
        
        -- Also set the CFrame once immediately after connecting the event
        humanoidRootPart.CFrame = targetCFrame

        print("Character teleported directly onto the VIP Floor part (Aggressive Enforcement Active).")
    else
        warn("Target part (VIP Floor) not found inside the loaded VIP model. Check the path and part name.") 
    end
end


-- Wait for the interior to stream. This duration might need adjustment based on your game's loading speed.
local waitBeforeTeleport = 10
print(string.format("\nWaiting %d seconds for interior to stream before teleport...", waitBeforeTeleport))
task.wait(waitBeforeTeleport)

print("\n--- Initiating Direct Teleport to VIP ---") 
print("Attempting to trigger automatic door teleport to destination:", destinationId)
print("Using door ID:", doorIdForTeleport)
print("Position adjustment will be handled by a separate background task.")

-- Add a final small wait right before the InteriorsM.enter_smooth call
task.wait(1) 

-- Call the enter_smooth function for the teleport
InteriorsM.enter_smooth(destinationId, doorIdForTeleport, teleportSettings, nil)

-- --- FIX: Initiate a separate task to handle post-teleport position adjustment reliably. ---
-- This task uses WaitForChild to guarantee the VIP model is loaded.
task.spawn(handlePostTeleportMovement)

print("\nautomatic direct VIP teleport script initiated.") 
