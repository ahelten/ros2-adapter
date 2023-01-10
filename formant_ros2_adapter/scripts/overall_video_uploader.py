import base64
import json
import subprocess
import glob
import os
from formant.sdk.agent.v1 import Client as FormantClient

if __name__ == "__main__":
    fclient = FormantClient()

    #clear any existing videos
    if os.path.exists('/home/formant/video'):
        for f in glob.glob(os.path.join('/home/formant/video', '*')):
            os.remove(f)

    while True:
        for f in glob.glob('/home/formant/video/video_*.txt'):
            try:
                video_data = open(f, 'rb').read()
                output = f[:f.find('.')] + '.jpg'
                jpg_command = ["ffmpeg", "-y", "-hide_banner", "-movflags", "frag_keyframe+empty_moov", "-qscale:v", "10", output, "-i", "-"]
                jpg_result = subprocess.run(
                    jpg_command,
                    input=video_data,
                    stderr=subprocess.PIPE,
                    stdout=subprocess.PIPE
                )
                jpg_data = open(output, 'rb').read()
                jpg_string = base64.b64encode(jpg_data).decode('utf-8')
                data = {
                    'descriptor': f[f.find('_')+1:f.find('.')],
                    'frame_data': jpg_string
                }
                fclient.send_on_custom_data_channel('video_stream', json.dumps(data).encode('utf-8'))
            except:
                continue