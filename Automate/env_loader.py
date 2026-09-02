import os
from dotenv import load_dotenv

# โหลดตัวแปรจากไฟล์ .env ขึ้นมา
load_dotenv()

# สร้างตัวแปรให้ Robot Framework นำไปใช้งานต่อ
TEST_PHONE = os.getenv('TEST_PHONE')
TEST_PASSWORD = os.getenv('TEST_PASSWORD')
TEST_OTP = os.getenv('TEST_OTP')
TMS_USER = os.getenv('TMS_USER')
TMS_PASSWORD = os.getenv('TMS_PASSWORD')
TMS_URL = os.getenv('TMS_URL')
KAFKA_URL = os.getenv('KAFKA_URL')
KAFKA_USER = os.getenv('KAFKA_USER')
KAFKA_PASSWORD = os.getenv('KAFKA_PASSWORD')
TMS_CORE_API_URL = os.getenv('TMS_CORE_API_URL')
TMS_API_USERNAME = os.getenv('TMS_API_USERNAME')
TMS_API_PASSWORD = os.getenv('TMS_API_PASSWORD')
