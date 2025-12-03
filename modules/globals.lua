CONTENT_PACKS = {}
CACHED_DATA = {over = false}

PLAYER_LIST = {}
TEMP_PLAYERS = {}
CLIENT_PLAYER = nil
CLIENT = nil
SERVER = nil

update_config = function() file.write(CONFIG_PATH, json.tostring(CONFIG, true)) end