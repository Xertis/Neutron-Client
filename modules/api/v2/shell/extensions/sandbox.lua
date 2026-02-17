local module = {
    players = {}
}


function module.players.get_all()
    return PLAYER_LIST
end

return module