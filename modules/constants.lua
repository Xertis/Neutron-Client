CONFIG = {}

PACK_ID = "quartz"
CONFIG_PATH = pack.shared_file(PACK_ID, "config.json")

CHUNK_LOADING_DISTANCE = 0

COLORS = {
    red =    "[#ff0000]",
    yellow = "[#ffff00]",
    blue =   "[#0000FF]",
    black =  "[#000000]",
    green =  "[#00FF00]",
    white =  "[#FFFFFF]",
    gray =   "[#4d4d4d]"
}

PROTOCOL_VERSION = 3
API_VERSION = 2
PROTOCOL_STATES = {
    Status = 0,
    Login = 1,
    Active = 2
}