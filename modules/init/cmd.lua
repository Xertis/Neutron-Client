local protocol = require "multiplayer/protocol-kernel/protocol"

console.add_command(
    "chat message:str",
    "Send message",
    function(args)
        local message = args[1]
        if string.starts_with(message, "//") then
            return console.execute(message)
        end

        if SERVER then
            SERVER:push_packet(protocol.ClientMsg.ChatMessage, { message })
        else
            console.log('Невозможно отправить сообщение')
        end
    end
)
console.submit = function(command)
    local name, body = command:match("^(%S+)%s*(.*)$")

    if name == "chat" then
        console.execute(command)
    elseif string.starts_with(name, "/") then
        local valid_name = string.sub(name, 2)
        if console.is_cheat(valid_name) then
            console.log("The cheat command cannot be executed")
            return
        end
        if #body > 0 then body = " " .. body end
        console.log(console.execute(valid_name .. body))
    else
        console.execute("chat '/" .. command .. "'")
    end
end
