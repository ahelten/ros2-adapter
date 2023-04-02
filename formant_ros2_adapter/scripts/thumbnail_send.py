import sys
import cv2
import base64
import json
import time
import threading
from formant.sdk.agent.v1 import Client as FormantClient

class BotVideoGrabber(object):
    FETCH_RATE = 1/30  #insure we keep frame buffer empty

    def __init__(self, fclient):
        print("Starting video thumbnail script")
        # Camera RTSP streams are stored under device app config values
        camera_front_rtsp = fclient.get_app_config("camera_front", None)
        print("Camera front configured stream:", str(camera_front_rtsp))
        self.cap_front = cv2.VideoCapture(camera_front_rtsp)
        self.cap_front.set(cv2.CAP_PROP_BUFFERSIZE, 1)

        camera_rear_rtsp = fclient.get_app_config("camera_rear", None)
        print("Camera rear configured stream:", str(camera_rear_rtsp))
        self.cap_rear = cv2.VideoCapture(camera_rear_rtsp)
        self.cap_rear.set(cv2.CAP_PROP_BUFFERSIZE, 1)

        self.thread = threading.Thread(target=self.grab_frames, args=())
        self.thread.start()

    def grab_frames(self):
        while True:
            if self.cap_front.isOpened():
                self.cap_front.grab()
            if self.cap_rear.isOpened():
                self.cap_rear.grab()
            time.sleep(self.FETCH_RATE)

    def retrieve_frame_front(self):
        return self.cap_front.retrieve()

    def retrieve_frame_rear(self):
        return self.cap_rear.retrieve()

    def __del__(self):
        self.thread.join()

if __name__ == '__main__':
    FPS = 2
    IMAGE_WIDTH = 360
    IMAGE_HEIGHT = 240
    fclient = FormantClient()
    cam = BotVideoGrabber(fclient)
    while True:
        start_time = time.time()
        front_data = {
            'img': "",
            'timestamp': float(time.time())
        }
        rear_data = {
            'img': "",
            'timestamp': float(time.time())
        }

        try: 
            # Get Front camera image and send
            _, image = cam.retrieve_frame_front()
            if _:
                image = cv2.resize(image, (IMAGE_WIDTH, IMAGE_HEIGHT))
                encode = cv2.imencode(".jpg", image)[1]
                image_string = base64.b64encode(encode).decode()
                front_data['img'] = image_string
                fclient.send_on_custom_data_channel("video_stream_front", json.dumps(front_data).encode("utf-8"))

            # Get rear camera image and send
            _, image = cam.retrieve_frame_rear()
            if _:
                image = cv2.resize(image, (IMAGE_WIDTH, IMAGE_HEIGHT))
                encode = cv2.imencode(".jpg", image)[1]
                image_string = base64.b64encode(encode).decode()
                rear_data['img'] = image_string
                fclient.send_on_custom_data_channel("video_stream_rear", json.dumps(rear_data).encode("utf-8"))
        except Exception as e: 
            print(e)

        # Sleep based on FPS desired
        sleep_time = (1 / FPS) - (time.time() - start_time) 
        if sleep_time > 0:
            time.sleep(sleep_time)