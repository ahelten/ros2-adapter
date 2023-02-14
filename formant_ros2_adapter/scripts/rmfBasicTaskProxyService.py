from formant.sdk.agent.v1 import Client as FormantClient
import subprocess
import time

import requests

def rmf_ms_callback(message):
    print("transfering to rmf ms...")
    cmd = "curl -k http://localhost:8081/api/RmfStart"
    return_value = subprocess.call(cmd, shell=True)
    print(return_value)


if __name__ == "__main__":
    print("Startint rmf proxy service...")
    print("Registering callback...", flush = True)
    fclient = FormantClient(
        ignore_throttled=True,
        ignore_unavailable=True,
    )

    fclient.register_custom_data_channel_message_callback(
        rmf_ms_callback, channel_name_filter=["rmf-ms-command"]
    )

    while True:
        time.sleep(10)
