import json


def format_easy_forex(message, title):

    message_text = message.message.upper()
    # Array to store 3 operations
    operations = []

    # id,date,symbol,action,open_price,tp_scalping,sl_price,comment

    if 'GOLD' in message_text:
        message_text = message_text.replace('GOLD', 'XAUUSD')

    # BUY AND SELL ORDERS
    if '@' in message_text and ('BUY' in message_text or 'SELL' in message_text):
        output = message_text.split()

        # operation = str(message.id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + output[0] + ',' \
        #            + output[1] + ',' + output[3] + ',' + output[5] + ',' + output[8] + ',' + output[11] + ',' \
        #            + output[14] + ',' + title

        title1 = 'EasyForex,' + str(message.id) + ',TP1,' + output[5]
        operation1 = str(message.id) + ';' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ';' + output[0] + ';' \
                     + output[1] + ';' + output[5] + ';' + output[14] + ';' + title1

        title2 = 'EasyForex,' + str(message.id) + ',TP2,' + output[8]
        operation2 = str(message.id) + ';' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ';' + output[0] + ';' \
                     + output[1] + ';' + output[8] + ';' + output[14] + ';' + title2

        title3 = 'EasyForex,' + str(message.id) + ',TP3,' + output[11]
        operation3 = str(message.id) + ';' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ';' + output[0] + ';' \
                     + output[1] + ';' + output[11] + ';' + output[14] + ';' + title3

        operations.append(operation1)
        operations.append(operation2)
        operations.append(operation3)

    # CLOSE OR TAKE PROFIT ORDERS
    if 'CUT ' in message_text or 'CLOSE ' in message_text:

        if message.is_reply:
            # Get the original id reply
            title = 'EasyForex,' + str(message.reply_to_msg_id) + ',CLOSE,' + '0'
            operation = str(message.reply_to_msg_id) + ';' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ';' + \
                        'NOW' + ';' + 'CLOSE' + ';0;0' + ';' + title
            operations.append(operation)

    return operations


def format_message_text(event):
    operations = []
    message = event.message
    chat = event.chat

    try:
        operations = format_easy_forex(message, chat.title)
        return operations

    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        return operations
