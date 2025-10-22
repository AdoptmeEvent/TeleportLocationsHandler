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

-- We use a minimal settings table, as we are not dealing with house ownership.
local teleportSettings = {
    -- Optional: You can add simple callback functions here if needed.
    player_about_to_teleport = function() 
        print(string.format("Player is about to teleport to %s...", destinationId)) 
    end,
    -- This callback executes AFTER the smooth transition to the PizzaShop is complete.
    teleport_completed_callback = function()
        local rugPath = "Interiors.PizzaShop.Geometry.BasicRug.Colorable"
        
        print(string.format("Teleport to %s completed. Now attempting to move player to the rug: %s", destinationId, rugPath))
        
        -- Use WaitForChild with a timeout in case the interior is still streaming in, 
        -- though it should ideally be streamed by this point.
        local TargetPart = Workspace:WaitForChild("Interiors", 5):FindFirstChild(rugPath:match("^Interiors%.(.*)"), true)
        
        if TargetPart and TargetPart:IsA("BasePart") then
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            
            if Character and Character.PrimaryPart then
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
local waitBeforeTeleport = 3 -- Reduced from the original 10+ seconds for housing
print(string.format("\nWaiting %d seconds before attempting teleport to %s...", waitBeforeTeleport, destinationId))
task.wait(waitBeforeTeleport)

print(string.format("\n--- Initiating Direct Teleport to %s ---", destinationId))

-- Call the enter_smooth function for the teleport
-- Arguments: (destinationId, doorId, settingsTable, optionalExitingDoor)
InteriorsM.enter_smooth(destinationId, doorIdForTeleport, teleportSettings, nil)

print("\nAutomatic direct teleport script initiated.")
