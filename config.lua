Config = {}

Config.Framework = 'esx' -- or 'qbcore'

Config.TargetOptions = {
    {
        label = "Claim Paycheck",
        icon = "fas fa-money-bill-alt",
        event = "jayzie-paycheck:openMenu",
        distance = 2.0
    }
}

Config.NPC = {
    { -- NPC 1
        model = 'a_m_m_farmer_01',
        coords = vector3(-267.93, -961.34, 31.22),
        heading = 205.0,
        showBlip = true,  -- Control whether the blip is shown or not
        blip = {
            name = "Paycheck NPC 1",
            sprite = 500, 
            color = 2, 
            scale = 0.9
        },
        animation = { -- Add animation details
            dict = 'amb@world_human_aa_smoke@male@idle_a', -- Animation dictionary
            clip = 'idle_a', -- Animation clip
            flag = 1 -- Optional animation flag
        }
    },
    
    -- { -- NPC 2
    --     model = 'a_m_m_farmer_01',
    --     coords = vector3(-267.93, -961.34, 31.22),
    --     heading = 205.0,
    --     showBlip = true,  -- Control whether the blip is shown or not
    --     blip = {
    --         name = "Paycheck NPC 1",
    --         sprite = 500, 
    --         color = 2, 
    --         scale = 0.9
    --     },
    --     animation = { -- Add animation details
    --         dict = 'amb@world_human_aa_smoke@male@idle_a', -- Animation dictionary
    --         clip = 'idle_a', -- Animation clip
    --         flag = 1 -- Optional animation flag
    --     }
    -- },

}
