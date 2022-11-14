import json


def format_message(message):
    if '@' not in message:
        return None

    output = message.split()

    operation = {
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
