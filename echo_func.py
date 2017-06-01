import base64

def echo_func(event, context):
    print(base64.b64decode(event["Records"][0]["kinesis"]["data"]))
    return 'message'
