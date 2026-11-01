local content_loader = {}

local loaders = {}

local function close_io_stream(loader)
    local current_pack = loader.current_pack

    if (current_pack.io_stream) then
        current_pack.io_stream:close()
        current_pack.io_stream = nil

        local hash = hash_to_string(current_pack.hash:final())
        local hash_mismatch = loader.content_info[current_pack.index].zip_hash ~= hash
        if (hash_mismatch) then
            -- todo handle error
        end
        loader.content_info[current_pack.index].success = not hash_mismatch
        current_pack.hash = nil
    end
end

function content_loader.start(server_address, content_info, event_funcs)
    if (loaders[server_address] ~= nil) then
        return
    end
    local loader = {
        progress = 0,
        content_info = content_info,
        current_pack = {
            index = 0,
            progress = 0
        },
        on_progress = event_funcs.on_progress or function() end,
        on_stop = event_funcs.on_stop or function() end
    }

    loaders[server_address] = loader
end

function content_loader.feed(server_address, byte_array)
    local loader = loaders[server_address]
    if (loader == nil) then
        return
    end

    local current_pack = loader.current_pack
    local bytes_size = byte_array.size
    loader.progress = loader.progress + bytes_size
    loader.on_progress(loader.progress)

    while (bytes_size > 0) do
        local file_size = current_pack.index == 0 and 0 or loader.content_info[current_pack.index].bytes_size
        local write_size = math.min(file_size - current_pack.progress, bytes_size)

        if (write_size == 0) then
            close_io_stream(loader)
            current_pack.index = current_pack.index + 1
            current_pack.progress = 0

            if (current_pack.index > #loader.content_info) then
                -- todo handle error
                return
            end

            if (file.isdir(PACKS_CACHE_PATH) == false) then
                file.mkdirs(PACKS_CACHE_PATH)
            end

            local pack_info = loader.content_info[current_pack.index]
            local path = PACKS_CACHE_PATH .. pack_info.id .. "#" .. pack_info.zip_hash .. ".zip"
            pack_info.path = path

            current_pack.io_stream = file.open(path, "wb")
            current_pack.hash = crypto.hash_new("SHA256")
            pack_info.success = false
        else
            local slice = byte_array:slice(byte_array.size - bytes_size + 1, write_size)
            current_pack.io_stream:write(slice)
            current_pack.hash:update(Bytearray_as_string(slice))
            bytes_size = bytes_size - write_size
            current_pack.progress = current_pack.progress + write_size
        end
    end
end

local function unzip(zip_file_path, dest_path, pack_id)
    local entry_point = file.mount(zip_file_path)

    if (file.isdir(dest_path) == true) then
        file.remove_tree(dest_path)
    end
    dest_path = dest_path .. pack_id .. "/"
    file.mkdirs(dest_path)

    local current_path = entry_point .. ":"
    local file_indexes = { 1 }
    while (true) do
        local file_list = file.list(current_path)

        for i = file_indexes[#file_indexes], #file_list do
            local path = file_list[i]
            if (file.isfile(path)) then
                file.write_bytes(dest_path .. file.path(path), file.read_bytes(path, false))
            else
                file.mkdir(dest_path .. file.path(path))
                if (current_path:ends_with(":")) then
                    current_path = current_path .. file.name(path)
                else
                    current_path = current_path .. "/" .. file.name(path)
                end
                file_indexes[#file_indexes] = i + 1
                table.insert(file_indexes, 1)

                goto dive_into
            end
        end

        if (current_path == entry_point .. ":") then
            break
        end

        current_path = file.parent(current_path)
        table.remove(file_indexes, #file_indexes)

        ::dive_into::
    end

    file.unmount(entry_point)
end

function content_loader.finish(server_address)
    local loader = loaders[server_address]
    if (loader == nil) then
        return
    end

    close_io_stream(loader)
    local success = true

    for _, pack_info in pairs(loader.content_info) do
        if (pack_info.success == true) then
            local target_directory = PACKS_CACHE_PATH .. pack_info.id .. "#" .. pack_info.unpacked_hash .. "/"
            unzip(pack_info.path, target_directory, pack_info.id)
            file.remove(pack_info.path)
        else
            success = false
        end
    end

    loader.on_stop(success)

    loaders[server_address] = nil
end

function content_loader.stop(server_address)
    local loader = loaders[server_address]
    if (loader == nil) then
        return
    end

    close_io_stream(loader)

    for _, pack_info in pairs(loader.content_info) do
        local target_directory = PACKS_CACHE_PATH .. pack_info.id .. "#" .. pack_info.unpacked_hash .. "/"
        local zip_file = PACKS_CACHE_PATH .. pack_info.id .. "#" .. pack_info.zip_hash .. ".zip"
        if (file.isdir(target_directory) == true) then
            file.remove_tree(target_directory)
        end
        if (file.isfile(zip_file) == true) then
            file.remove(zip_file)
        end
    end

    loader.on_stop(false)
end

return content_loader