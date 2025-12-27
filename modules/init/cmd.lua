local protocol = require "multiplayer/protocol-kernel/protocol"

console.add_command(
    "chat message:str",
    "Send message",
    function (args)
        if SERVER then
            SERVER:push_packet(protocol.ClientMsg.ChatMessage, {args[1]})
        else
            console.log('Невозможно отправить сообщение')
        end
    end
)
console.submit = function (command)
    local name, _ = command:match("^(%S+)%s*(.*)$")

    if name == "chat" then
        console.execute(command)
    else
        console.execute("chat '/"..command.."'")
    end
end