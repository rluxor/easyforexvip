# This is a sample Python script.
import time
import traceback
from datetime import date, datetime
import telegram_client as tc
import src
from telethon import events
import zmq
import orderSender

# Obtenemos los canales del fichero de config
channels = tc.get_channels()

# Pedimos el socket para escuchar
#socket_input = int(input("Introduce server socket to listen: "))
socket_input = tc.get_socket()
socket_address = "tcp://127.0.0.1:" + str(socket_input)

# Inicializamos la conexion socket para mt4
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.bind(socket_address)
poll = zmq.Poller()
poll.register(socket, zmq.POLLIN)

#Inicializamos la conexion con telegram
client = tc.init_telegram_client()

print('Telegram listening on: {}\n', format(socket_address))


def send_order(operation, event):
    # Formateamos el mensaje de salida para el logging
    log_msg = "{} - [{}] - New Trade    --> {}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                                       event.chat.title, operation)
    if 'CLOSE' in operation:
        log_msg = "{} - [{}] - Close Trade  --> {}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                                           event.chat.title, operation)

    src.write_log(log_msg, True)

    try:

        socket.send_string(operation)
        sockets = dict(poll.poll(1000))

        if socket in sockets:
            messageRecv = socket.recv().decode('utf-8')
            log_msg = "{} - [{}] - MT4 Response --> {}".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                                               event.chat.title, messageRecv)
            src.write_log(log_msg, True)

    except zmq.ZMQError as e:
        if e.errno == zmq.EAGAIN:
            pass


@client.on(events.NewMessage(chats=channels))
async def new_message_listener(event):

    try:

        # get message
        operations = orderSender.format_message_text(event)

        if len(operations) == 0:
            log_msg = "{} - [{}] - Msg {} Not Send \n".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                                              event.chat.title, event.message.id)
            src.write_log(log_msg, False)

        else:
            for operation in operations:
                send_order(operation, event)

    except Exception as error:

        log_msg = "{} - [{}] - Msg {} Not Send - ERROR\n".format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                                                 event.chat.title, event.message.id)
        src.write_log(log_msg, False)
        error_msg = traceback.format_exc()
        src.write_log(error_msg, True)


with client:
    client.run_until_disconnected()
