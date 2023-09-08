if GetResourceState("ox_lib") == "started" then
    return
end

lib = {}

-- Need to implement zones modules when ox_lib is not present.