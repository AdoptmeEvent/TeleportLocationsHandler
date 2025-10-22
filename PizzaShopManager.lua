-- This is a LocalScript (put in StarterPlayerScripts or similar)
-- This script is designed to automatically teleport the local player to the specified interior: PizzaShop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace") -- Added reference to Workspace

-- --- MODULE LOADING ---

local InteriorsM = nil
local UIManager = nil 

local successInteriorsM, errorMessageInteriorsM = pcall(function()
    -- Assuming this path is correct for your game's InteriorsM module.
    InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
end)

if not successInteriorsM then
    warn("Failed to require InteriorsM:", errorMessageInteriorsM)
    warn("Please ensure the path 'ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM' is correct.")
    return
end

local successUIManager, errorMessageUIManager = pcall(function()
    -- Assuming Fsys is a module in ReplicatedStorage that loads other modules like UIManager.
    UIManager = require(ReplicatedStorage:WaitForChild("Fsys")).load("UIManager")
end)

if not successUIManager or not UIManager then
    warn("Failed to require UIManager module. The script will continue, but ensure UIManager is not critical for teleport initiation.")
end


print("InteriorsM module loaded successfully.")

-- --- TELEPORT CONFIGURATION ---

local destinationId = "PizzaShop" -- THE TARGET DESTINATION
local doorIdForTeleport = "MainDoor" -- Assuming the PizzaShop uses "MainDoor" or a similar identifier for its main entrance

-- We now use a more complete settings table to satisfy the InteriorsM module's requirements.
local teleportSettings = {
    -- **CRITICAL FIX:** Added required fade properties to resolve 'attempt to index string with start_transparency'
    fade_in_length = 0.5,
    fade_out_length = 0.4,
    fade_color = Color3.new(0, 0, 0), 
    start_transparency = 0, -- This was the property that was missing/causing the error.
    
    -- Other necessary settings for a smooth transition (copied from original context)
    anchor_char_immediately = true,
    move_camera = true,

    -- Callbacks (our custom logic)
    player_about_to_teleport = function() 
        print(string.format("Player is about to teleport to %s...", destinationId)) 
    end,
    -- This callback executes AFTER the smooth transition to the PizzaShop is complete.
    teleport_completed_callback = function()
        local rugPath = "Interiors.PizzaShop.Geometry.BasicRug.Colorable"
        local TargetPart = nil

        -- Step 1: Wait for the top-level Interiors folder.
        local interiorsFolder = Workspace:WaitForChild("Interiors", 5)
        
        -- Step 2: Use a loop to repeatedly check for the specific deep part path.
        -- We will check 10 times with a 0.1 second wait in between (1 second total).
        local attempts = 0
        while not TargetPart and attempts < 10 do 
            if interiorsFolder then
                -- FindFirstChild(name, recursive)
                TargetPart = interiorsFolder:FindFirstChild("PizzaShop.Geometry.BasicRug.Colorable", true)
            end
            if not TargetPart then
                task.wait(0.1)
            end
            attempts = attempts + 1
        end

        print(string.format("Teleport to %s completed. Now attempting to move player to the rug: %s (Found: %s)", destinationId, rugPath, tostring(TargetPart)))
        
        
        if TargetPart and TargetPart:IsA("BasePart") then
            -- Ensure the character is loaded and ready
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            
            if Character and Character.PrimaryPart then
                -- Add a small wait for physics stability before the move
                task.wait(0.1) 
                
                -- Set the character's CFrame to the part's CFrame, shifted 3 studs up 
                -- to ensure the HumanoidRootPart is above the rug and doesn't clip.
                local targetCFrame = TargetPart.CFrame * CFrame.new(0, 3, 0)
                Character:SetPrimaryPartCFrame(targetCFrame)
                print("Player successfully moved onto the BasicRug.")
            else
                warn("Character or Character's PrimaryPart not found after initial teleport.")
            end
        else
            warn("Target part 'workspace." .. rugPath .. "' not found. Could not move player to rug.")
        end
    end,
}

-- Wait a short time to ensure all core game scripts and modules have initialized.
local waitBeforeTeleport = 3 
print(string.format("\nWaiting %d seconds before attempting teleport to %s...", waitBeforeTeleport, destinationId))
task.wait(waitBeforeTeleport)

print(string.format("\n--- Initiating Direct Teleport to %s ---", destinationId))

-- Call the enter_smooth function for the teleport, wrapped in pcall for debugging.
-- We are passing a final boolean argument (true) which often signifies 'teleport_player'
local success, result = pcall(InteriorsM.enter_smooth, InteriorsM, destinationId, doorIdForTeleport, teleportSettings, nil, true) -- Added 'true'

if not success then
    -- Log any new errors
    warn(string.format("Error during enter_smooth: %s", result))
else
    print("InteriorsM.enter_smooth call initiated successfully.")
end

-- Keep the script alive long enough for the teleport to complete
task.wait(10)

print("\nAutomatic direct teleport script process finished.")
