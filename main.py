# This is a sample Python script.
import telegram_client as tc
import src
from telethon import TelegramClient, events, sync
import zmq
import time

# ID easy forex vip
chat = 1436688109
# Id canal de test
chat_test = 1558245993
# Inicializamos el cliente para leer de telegram
client = tc.init_telegram_client()

# Inicializamos la conexion socket para mt4
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.bind("tcp://127.0.0.1:9999")

print('TELEGRAM LISTENER READY')


@client.on(events.NewMessage(chats=chat_test))
async def new_message_listener(event):
    # get message
    operation = src.format_message(event.message.message)

    socket.send_string(operation)
    print(operation)
    time.sleep(2)

    message = socket.recv()
    print(message)


with client:
    client.run_until_disconnected()
