import json


def format_message_json(message):
    message_text = message.message

    if '@' not in message_text:
        return None

    output = message_text.split()

    operation = {
        "id": message.id,
        "date": message.date.strftime("%Y-%m-%d %H:%M:%S"),
        "symbol": output[0],
        "action": output[1],
        "open_price": output[3],
        "tp_scalping": output[5],
        "tp_intraday": output[8],
        "tp_swing": output[11],
        "sl_price": output[14],
    }

    operation_text = json.dumps(operation)

    return operation_text


def format_message_text(message):

    operation = None

    message_text = message.message.upper()


    # Operaciones de compra y venta
    if '@' in message_text:
        output = message_text.split()

        operation = str(message.id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + output[0] + ',' + output[
            1] \
                    + ',' + output[3] + ',' + output[5] + ',' + output[8] + ',' + output[11] + ',' + output[14]

    # Operaciones take profit
    if 'HIT TP' in message_text or 'HIT SL' in message_text:

        if message.is_reply:

            # Obtener el id reply que tiene el original
            operation = str(message.reply_to_msg_id) + ',' + message.date.strftime("%Y-%m-%d %H:%M:%S") + ',' + 'SYMBOL' + ',' + \
                        'CLOSE' + ',0,0,0,0,0'

    return operation
