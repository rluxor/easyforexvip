import configparser
from telethon.errors import SessionPasswordNeededError
from telethon import TelegramClient, events, sync

config = configparser.ConfigParser()
config.read('telegram.config')


def init_telegram_client():
    api_id = int(config['TELEGRAM-LOGIN']['api_id'])
    api_hash = str(config['TELEGRAM-LOGIN']['api_hash'])
    username = str(config['TELEGRAM-LOGIN']['username'])
    phone = str(config['TELEGRAM-LOGIN']['phone'])

    client = TelegramClient(username, api_id, api_hash)
    client.start()

    if not client.is_user_authorized():
        client.send_code_request(phone)
        try:
            client.sign_in(phone, input('Enter the code: '))
        except SessionPasswordNeededError:
            client.sign_in(password=input('Password: '))

    return client


def get_channels():
    channels_real = config['TELEGRAM-CHANNELS']['channels']
    channels = list(map(int, channels_real.split(',')))
    return channels


def get_socket():
    socket = config['MT4-SOCKET']['socket']
    return int(socket)
