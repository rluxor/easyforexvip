import json

log_file = 'tgm_mt4.log'


def write_log(log_msg, print_log):

    if print_log:
        print(log_msg)

    with open(log_file, 'a') as f:
        f.writelines(log_msg + '\n')


def format_easy_forex(message, title):
    operation = None
    message_text = message.message.upper()

    # Message format to send
    # id,date,symbol,action,open_price,tp_scalping,tp_intraday,tp_swing,sl_price,comment

    if 'GOLD' in message_text:
        message_text = message_text.replace('GOLD', 'XAUUSD')

    # BUY AND SELL ORDERS
    if '@' in message_text and ('BUY' in message_text or 'SELL' in message_text):
        output = message_text.split()

        operation = str(message.id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + output[0] + ',' \
                    + output[1] + ',' + output[3] + ',' + output[5] + ',' + output[8] + ',' + output[11] + ',' \
                    + output[14] + ',' + title

    # CLOSE OR TAKE PROFIT ORDERS
    if ' CUT ' in message_text or ' CLOSE ' in message_text:

        if message.is_reply:
            # Get the original id reply
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        str(message.id) + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title

    return operation


def format_blue_forex(message, title):
    operation = None
    message_text = message.message.upper()

    # Message format to send
    # id,date,symbol,action,open_price,tp_scalping,tp_intraday,tp_swing,sl_price

    if 'GOLD' in message_text:
        message_text = message_text.replace('GOLD', 'XAUUSD')

    # BUY AND SELL ORDERS
    if 'SELL' in message_text or 'BUY' in message_text:
        output = message_text.split()

        operation = str(message.id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + output[0] + ',' \
                    + output[1] + ',' + output[4] + ',' + output[8] + ',0,0,' + output[6] + ',' + title

    # CLOSE OR TAKE PROFIT ORDERS
    if 'CLOSE' in message_text:

        if 'NOW' in message_text and message.is_reply:
            # Get the original id reply
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'NOW' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title

        if 'IN -' in message_text and message.is_reply:
            # Get the original id reply
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'NOW' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title

        if 'HALF' in message_text and message.is_reply:
            # Get the original id reply
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'HALF' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title

    return operation


def format_forex_king(message, title):
    operation = None
    message_text = message.message.upper()

    # Message format to send
    # id,date,symbol,action,open_price,tp_scalping,tp_intraday,tp_swing,sl_price

    if 'GOLD' in message_text:
        message_text = message_text.replace('GOLD', 'XAUUSD')

    # BUY AND SELL ORDERS
    if 'SELL' in message_text or 'BUY' in message_text:
        output = message_text.split()

        operation = str(message.id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + output[0] + ',' \
                    + output[1] + ',' + output[2] + ',' + output[6] + ',0,0,' + output[4] + ',' + title

    # CLOSE OR TAKE PROFIT ORDERS
    if 'CLOSE' in message_text:

        if 'NOW' in message_text and message.is_reply:
            # Get the original id reply
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'NOW' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title
        elif 'HALF' in message_text and message.is_reply:
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'HALF' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title
        else:
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + \
                        'NOW' + ',' + 'CLOSE' + ',0,0,0,0,0' + ',' + title

    return operation


def format_message_text(event):
    operation = None

    message = event.message
    chat = event.chat

    try:
        # easy forex VIP
        if chat.id == 1436688109 or chat.id == 1558245993:
            operation = format_easy_forex(message, chat.title)

        return operation

    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        return operation
