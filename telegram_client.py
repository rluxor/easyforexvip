import configparser
from telethon.errors import SessionPasswordNeededError
from telethon import TelegramClient, events, sync

config = configparser.ConfigParser()
config.read('telegram.config')

api_id = int(config['TELEGRAM']['api_id'])
api_hash = str(config['TELEGRAM']['api_hash'])
username = str(config['TELEGRAM']['username'])
phone = str(config['TELEGRAM']['phone'])


def init_telegram_client():

    client = TelegramClient(username, api_id, api_hash)
    client.start()

    if not client.is_user_authorized():
        client.send_code_request(phone)
        try:
            client.sign_in(phone, input('Enter the code: '))
        except SessionPasswordNeededError:
            client.sign_in(password=input('Password: '))

    return client