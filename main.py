# This is a sample Python script.
from datetime import time

import telegram_client as tc
import src
from telethon import events
import zmq


channels = tc.get_channels()

# Pedimos el socket para escuchar
socket_input = int(input("Introduce server socket to listen: "))
socket_address = "tcp://127.0.0.1:" + str(socket_input)

# Inicializamos el cliente para leer de telegram
client = tc.init_telegram_client()

# Inicializamos la conexion socket para mt4
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.bind(socket_address)

print(channels)
print('TELEGRAM LISTENER READY ON ADDRESS: ', socket_address)


@client.on(events.NewMessage(chats=channels))
async def new_message_listener(event):
    # get message
    operation = src.format_message_text(event)

    if operation is None:
        print("--> {}: Msg Not Send: {}".format(event.chat.title, event.message.message))
    else:
        print(operation)
        socket.send_string(operation)

        messageRecv = socket.recv().decode('utf-8')
        print(messageRecv)

with client:
    client.run_until_disconnected()
