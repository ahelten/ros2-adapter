from formant.sdk.agent.v1 import Client as FormantClient
import subprocess
import time

def ros_command_callback(message):
    cmd = message.payload.decode("utf-8")
    return_value = subprocess.call(cmd, shell=True)
    print(return_value)

if __name__ == "__main__":
    print("Registering callback...", flush = True)
    fclient = FormantClient(
        ignore_throttled=True,
        ignore_unavailable=True,
    )

    fclient.register_custom_data_channel_message_callback(
        ros_command_callback, channel_name_filter=["ros-command"]
    )

    while True:
        time.sleep(10)
