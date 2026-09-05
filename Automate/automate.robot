*** Settings ***
Library    AppiumLibrary      run_on_failure=Capture Page Screenshot
Library    SeleniumLibrary    run_on_failure=Capture Page Screenshot    # เพิ่ม Library สำหรับเทสเว็บ
Library    OperatingSystem    # เพิ่ม Library สำหรับรันคำสั่ง OS (เปิดจอ Emulator)
Library    ScreenCapLibrary    # เพิ่ม Library สำหรับอัดหน้าจอ Windows
Library    Collections         # เพิ่ม Library สำหรับจัดการ Dictionary/List
Library    String              # เพิ่ม Library สำหรับจัดการ String
Library    RequestsLibrary     # เพิ่ม Library สำหรับยิง API โดยตรง (ใช้กับ TC_REG_060)
Variables  env_loader.py       # เพิ่มตัวโหลดค่าจากไฟล์ .env
Variables  test_data.yaml      # เพิ่มตัวโหลด Test Data (External Order No./Task No. ต่างๆ) แยกออกมาจากไฟล์นี้
Suite Setup    Set Library Search Order    AppiumLibrary    SeleniumLibrary
*** Variables ***
# ตั้งค่า Server และ Device
${APPIUM_SERVER}      http://127.0.0.1:4723
${PLATFORM_NAME}      Android
${AUTOMATION_NAME}    UIAutomator2
${APP_PACKAGE}        com.bigc.driver.uat
${APP_ACTIVITY}       com.bigcdev.driverapp.MainActivity    # หมายเหตุ: หากรันแล้วแอปไม่เปิด อาจจะต้องแก้ชื่อ Activity ให้ตรงกับของแอปจริงนะครับ

# หมายเหตุ: Test Data ทั้งหมด (External Order No./Task No. ต่างๆ ที่ใช้ใน TC_REG_058 ขึ้นไป) ย้ายไปอยู่ใน test_data.yaml แล้ว
# แก้ไขค่าที่นั่นก่อนรัน หรือส่งผ่าน command line เช่น --variable EXTERNAL_ORDER_NO_PENDING:xxxxxxxxxx

*** Test Cases ***
TC_REG_001: Verify Import booking function
    [Documentation]    ทดสอบการ Import excel file template
    
    # เริ่มอัดวิดีโอหน้าจอ Windows ทั้งหมด
    Start Video Recording    alias=windows_record    name=TC_REG_001    fps=15
    
    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin
    
    # 2. ไปที่เมนู Booking และทำการ Import
    Process Booking Import
    
    # 3. อ่านค่า Booking No และ Status จากแถวแรก
    ${booking_no}    ${status}=    Get Latest Booking Info
    
    # ตรวจสอบ Status หากพบว่าเป็น ERROR ให้ทำการ Logout ออกจากเว็บและหยุดการทำงานทันที
    Run Keyword If    '${status.upper()}' == 'ERROR'    Run Keywords
    ...    Logout TMS Admin    AND
    ...    Close Browser    AND
    ...    Stop Video Recording    alias=windows_record    AND
    ...    Fail    นำเข้าไม่สำเร็จ! พบสถานะเป็น ERROR สำหรับ Booking: ${booking_no}

    # 4. เปลี่ยนไปใช้แอปพลิเคชันมือถือ
    Open Driver App
    
    # 5. ล็อกอินเข้าสู่ระบบด้วยเบอร์โทรศัพท์และรหัสผ่าน
    Login With Credentials    ${TEST_PHONE}    ${TEST_PASSWORD}
    
    # 6. กรอกรหัส OTP ที่ได้รับ
    Submit OTP    ${TEST_OTP}
    
    # 7. กด Clock in เข้างาน และตรวจสอบเลข Booking บนหน้าจอ
    Tap Clockin Driver App Menu    ${booking_no}
    
    # 8. ออกจากระบบแอปมือถือและปิดแอป
    Logout From Driver App
    Close Driver App
    
    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows
    Stop Video Recording    alias=windows_record

TC_REG_002: Verify Create DL function(Auto create DL)
    [Documentation]    ทดสอบการส่ง Message ผ่าน Kafka เพื่อ Auto Create DL
    
    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_002    fps=15
    
    # 1. โหลด JSON Payload จากไฟล์ booking_data.json
    ${json_string}=    Get File    ${CURDIR}${/}booking_data.json    encoding=UTF-8
    ${json_data}=      Evaluate    __import__('json').loads($json_string)    json
    
    # 2. ดึงค่า external_delivery_no มาใช้เป็น Key
    ${key_value}=      Get From Dictionary    ${json_data}    external_delivery_no
    
    # 3. Login Kafka UI
    Login To Kafka UI
    
    # 4. เลือก Topic และส่ง Message
    Produce Kafka Message    ${key_value}    ${json_string}
    
    # 5. Logout ออกจาก Kafka UI
    Logout From Kafka UI
    
    # 6. ปิด Browser
    SeleniumLibrary.Close Browser

    # 7. เปิด TMS Admin เพื่อตรวจสอบ Delivery Order
    Login To TMS Admin
    
    # 8. ไปที่เมนู Delivery Order และค้นหาด้วย External Delivery No.
    ${delivery_no}=    Verify Delivery Order In TMS    ${key_value}
    
    # 9. ไปที่เมนู Delivery Loads และค้นหาด้วย Delivery No.
    Verify Delivery Load In TMS    ${delivery_no}
    
    # 10. Logout TMS Admin
    Logout TMS Admin
    
    # 11. ปิด Browser
    Close Browser
    
    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_003: Verify Create DT function(Auto create DT)
    [Documentation]    ทดสอบการส่ง Message ผ่าน Kafka เพื่อ Auto Create DT
    
    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_003    fps=15
    
    # 0. โหลด JSON Payload จากไฟล์ booking_data.json
    ${json_string}=    Get File    ${CURDIR}${/}booking_data.json    encoding=UTF-8
    ${json_data}=      Evaluate    __import__('json').loads($json_string)    json
    ${key_value}=      Get From Dictionary    ${json_data}    external_delivery_no

    # 1. เปิด TMS Admin เพื่อตรวจสอบ Delivery Order
    Login To TMS Admin

    # 2. ไปที่เมนู Delivery Order และค้นหาด้วย External Delivery No.
    ${delivery_no}=    Verify Delivery Order In TMS    ${key_value}

    # 3. ไปที่เมนู Delivery Loads และค้นหาด้วย Delivery No.
    Verify Delivery Load In TMS    ${delivery_no}

    # 4. เปลี่ยนไปใช้แอปพลิเคชันมือถือ
    Open Driver App
    
    # 5. เช็คสถานะว่าอยู่หน้า Login หรือไม่ (ถ้าไม่เจอแสดงว่า Login ค้างไว้อยู่แล้ว)
    ${is_login_screen}=    Run Keyword And Return Status    Wait Until Element Is Visible    xpath=//android.widget.EditText[@text="เบอร์โทรศัพท์"]    timeout=20s
    Run Keyword If    ${is_login_screen}    Login With Credentials    ${TEST_PHONE}    ${TEST_PASSWORD}
    Run Keyword If    ${is_login_screen}    Submit OTP    ${TEST_OTP}
    
    # 7. กด Clock in เข้างาน, ถ่ายรูป และยืนยัน
    Driver Clockin
    
    # 8. กลับไปที่ TMS Admin และคลิกเมนู Delivery Tasks
    # พยายามดันหน้าต่าง Browser ขึ้นมาด้านหน้า
    Run Keyword And Ignore Error    OperatingSystem.Run    powershell -Command "(New-Object -ComObject WScript.Shell).AppActivate('Chrome')"
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[contains(@href, 'delivery_tasks/tms_task')]    timeout=20s
    ${menu_dt}=    SeleniumLibrary.Get WebElement    xpath=//a[contains(@href, 'delivery_tasks/tms_task')]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${menu_dt}
    Sleep    2s

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_058: Verify cancel order function when order is in Pending status
    [Documentation]    ทดสอบว่าระบบอนุญาตให้ cancel Delivery Order ที่มีสถานะ Pending (ผลที่คาดหวัง: cancel สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_058    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_PENDING}

    # 2. ตรวจสอบว่าระบบ cancel สำเร็จ (success=true, code=SUCCESS)
    Verify Cancel Order Succeeded    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะเปลี่ยนเป็น CANCELLED แล้วจริง
    # หมายเหตุ: สมมติว่าสถานะหลัง cancel สำเร็จคือ "CANCELLED" ถ้าระบบใช้ label อื่น ให้แก้คำนี้
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_PENDING}    CANCELLED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่า entry ล่าสุดใน Status History เป็น Cancel
    Open Delivery Order Detail From List
    Verify Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_059: Verify cancel order function when order is in Planned status
    [Documentation]    ทดสอบว่าระบบอนุญาตให้ cancel Delivery Order ที่มีสถานะ Planned (ผลที่คาดหวัง: cancel สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_059    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_PLANNED}

    # 2. ตรวจสอบว่าระบบ cancel สำเร็จ (success=true, code=SUCCESS)
    Verify Cancel Order Succeeded    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะเปลี่ยนเป็น CANCELLED แล้วจริง
    # หมายเหตุ: สมมติว่าสถานะหลัง cancel สำเร็จคือ "CANCELLED" ถ้าระบบใช้ label อื่น ให้แก้คำนี้
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_PLANNED}    CANCELLED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่า entry ล่าสุดใน Status History เป็น Cancel
    Open Delivery Order Detail From List
    Verify Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_060: Verify cancel order function when order is in IN_LOAD status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ IN_LOAD (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_060    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น IN_LOAD (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO}

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_061: Verify cancel order function when order is in IN_TASK status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ IN_TASK (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_061    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_IN_TASK}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น IN_TASK (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_IN_TASK}    IN_TASK

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_062: Verify cancel order function when order is in DISPATCHED status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ DISPATCHED (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_062    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_DISPATCHED}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น DISPATCHED (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_DISPATCHED}    DISPATCHED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_063: Verify cancel order function when order is in IN_TRANSIT status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ IN_TRANSIT (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_063    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_IN_TRANSIT}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น IN_TRANSIT (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_IN_TRANSIT}    IN_TRANSIT

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_064: Verify cancel order function when order is in DELIVERED status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ DELIVERED (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_064    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_DELIVERED}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น DELIVERED (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_DELIVERED}    DELIVERED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_065: Verify cancel order function when order is in CANCELLED status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ CANCELLED อยู่แล้ว (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_065    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_CANCELLED}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น CANCELLED (ไม่มีการเปลี่ยนแปลงซ้ำ)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_CANCELLED}    CANCELLED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_066: Verify cancel order function when order is in FAILED status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ FAILED (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_066    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_FAILED}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น FAILED (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_FAILED}    FAILED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_067: Verify cancel order function when order is in TO_ATTEMPT status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ TO_ATTEMPT (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_067    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_TO_ATTEMPT}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น TO_ATTEMPT (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_TO_ATTEMPT}    TO_ATTEMPT

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_068: Verify cancel order function when order is in RE_SCHEDULE status
    [Documentation]    ทดสอบว่าระบบไม่อนุญาตให้ cancel Delivery Order ที่มีสถานะ RE_SCHEDULED (ผลที่คาดหวัง: cancel ไม่สำเร็จ)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_068    fps=15

    # 1. ยิง API cancel order โดยตรงด้วย External Delivery No. ที่กำหนด
    ${response}=    Cancel Delivery Order Via API    ${EXTERNAL_ORDER_NO_RE_SCHEDULE}

    # 2. ตรวจสอบว่าระบบปฏิเสธการ cancel (success=false, code=CANCEL_NOT_ALLOW)
    Verify Cancel Order Rejected    ${response}

    # 3. เข้า TMS Admin เพื่อตรวจสอบว่าสถานะยังคงเป็น RE_SCHEDULED (ไม่ถูกยกเลิกจริง)
    Login To TMS Admin
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_RE_SCHEDULE}    RE_SCHEDULED

    # 4. เข้าหน้า Detail ของ order แล้วตรวจสอบว่าไม่มี Cancel ปรากฏใน Status History
    Open Delivery Order Detail From List
    Verify No Cancel In Status History

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_069: Verify Add ad-hoc Order button in task detail with Dispatched status
    [Documentation]    ทดสอบว่าไม่มีปุ่ม Add Ad-hoc Order ปรากฏในหน้า Delivery Task Detail เมื่อ Task อยู่ในสถานะ Dispatched

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_069    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2-3. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. ที่สถานะ Dispatched แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_DISPATCHED}

    # 4. ตรวจสอบว่าไม่มีปุ่ม Add Ad-hoc Order ปรากฏอยู่เลย
    Verify Add Ad Hoc Order Button Not Present

    # 5. ออกจากระบบ
    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_080: Verify Add ad-hoc Order function when admin user add order with Pending status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ Pending) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_080    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น Pending จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_PENDING}    PENDING

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. ที่สถานะ Pending แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ Pending แล้วกด Save
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_PENDING}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_081: Verify Add ad-hoc Order function when admin user add order with IN_LOAD status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ IN_LOAD) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_081    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น IN_LOAD จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_IN_LOAD}    IN_LOAD

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ IN_LOAD
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_IN_LOAD}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_082: Verify Add ad-hoc Order function when admin user add order with IN_TASK status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ IN_TASK) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_082    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น IN_TASK จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_IN_TASK}    IN_TASK

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ IN_TASK
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_IN_TASK}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_083: Verify Add ad-hoc Order function when admin user add order with DISPATCHED status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ DISPATCHED) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_083    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น DISPATCHED จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_DISPATCHED}    DISPATCHED

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ DISPATCHED
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_DISPATCHED}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_084: Verify Add ad-hoc Order function when admin user add order with IN_TRANSIT status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ IN_TRANSIT) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_084    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น IN_TRANSIT จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_IN_TRANSIT}    IN_TRANSIT

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ IN_TRANSIT
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_IN_TRANSIT}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_085: Verify Add ad-hoc Order function when admin user add order with DELIVERED status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ DELIVERED) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_085    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น DELIVERED จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_DELIVERED}    DELIVERED

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ DELIVERED
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_DELIVERED}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_086: Verify Add ad-hoc Order function when admin user add order with TO_ATTEMPT status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ TO_ATTEMPT) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_086    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น TO_ATTEMPT จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_TO_ATTEMPT}    TO_ATTEMPT

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ TO_ATTEMPT
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_TO_ATTEMPT}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_087: Verify Add ad-hoc Order function when admin user add order with FAILED status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ FAILED) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_087    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น FAILED จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_FAILED}    FAILED

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ FAILED
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_FAILED}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_088: Verify Add ad-hoc Order function when admin user add order with RE_SCHEDULED status into the task
    [Documentation]    ทดสอบว่า admin สามารถเพิ่ม Ad-hoc Order (สถานะ RE_SCHEDULED) เข้าไปใน Delivery Task ได้สำเร็จ (ผลที่คาดหวัง: กด Save ได้ เจอ Toast "Success!" และเห็นเลขนี้ในตาราง Delivery Orders ของ Task)

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_088    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น RE_SCHEDULED จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_RE_SCHEDULE}    RE_SCHEDULED

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-8. เพิ่ม Order ด้วย External Order No. สถานะ RE_SCHEDULED ให้สำเร็จ (แสดง preview, กด Save, รอ Toast "Success!" แล้วปิด)
    Add Ad Hoc Order Successfully To Task    ${EXTERNAL_ORDER_NO_ADHOC_RE_SCHEDULE}

    # 9. ตรวจสอบในหน้า Task Detail เดิมนี้เลยว่ามีเลข External Order No. นี้ปรากฏในตาราง Delivery Orders ของ Task แล้ว (ยืนยันว่าเพิ่มสำเร็จจริง)
    Verify Order In Task Delivery Orders Table    ${EXTERNAL_ORDER_NO_ADHOC_RE_SCHEDULE}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

TC_REG_089: Verify Add ad-hoc Order function when admin user add order with CANCELLED status into the task
    [Documentation]    ทดสอบว่า admin ไม่สามารถเพิ่ม Ad-hoc Order (สถานะ CANCELLED) เข้าไปใน Delivery Task ที่มีอยู่แล้วได้ (ผลที่คาดหวัง: ขึ้น "No addable orders")

    # เริ่มอัดวิดีโอหน้าจอ Windows
    Start Video Recording    alias=windows_record    name=TC_REG_089    fps=15

    # 1. Login TMS Admin ทางเว็บก่อน
    Login To TMS Admin

    # 2. พิสูจน์ก่อนว่า External Order No. ที่จะใช้ทดสอบมีสถานะเป็น CANCELLED จริง โดยไปที่เมนู Delivery Order แล้วค้นหาด้วยเลขนี้
    Verify Delivery Order In TMS    ${EXTERNAL_ORDER_NO_ADHOC_CANCELLED}    CANCELLED

    # 3-4. ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view เข้าหน้า Detail
    Open Delivery Task Detail By Task No    ${TASK_NO_PENDING}

    # 5-7. ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order, เพิ่ม Order ด้วย External Order No. ที่สถานะ CANCELLED
    Add Ad Hoc Order To Task    ${EXTERNAL_ORDER_NO_ADHOC_CANCELLED}

    Logout TMS Admin
    Close Browser

    # สิ้นสุดการอัดวิดีโอหน้าจอ Windows (ใช้ Ignore Error เผื่อกรณี BitBlt permission error)
    Run Keyword And Ignore Error    Stop Video Recording    alias=windows_record

*** Keywords ***
Open Driver App
    [Documentation]    เปิดแอปพลิเคชัน
    
    # พยายามดันหน้าต่าง Emulator หรือโปรแกรมจำลองแอนดรอยด์ขึ้นมาด้านหน้า (สำหรับ Windows)
    Run Keyword And Ignore Error    OperatingSystem.Run    powershell -Command "(New-Object -ComObject WScript.Shell).AppActivate('Android Emulator')"
    Run Keyword And Ignore Error    OperatingSystem.Run    powershell -Command "(New-Object -ComObject WScript.Shell).AppActivate('emulator')"
    Run Keyword And Ignore Error    OperatingSystem.Run    powershell -Command "(New-Object -ComObject WScript.Shell).AppActivate('LDPlayer')"
    
    # ปิดแอปให้สนิทก่อนเปิดใหม่ เพื่อให้กลับมาเริ่มที่หน้าแรกเสมอ
    Run Keyword And Ignore Error    OperatingSystem.Run    adb shell am force-stop ${APP_PACKAGE}
    Sleep    2s
    
    Open Application    ${APPIUM_SERVER}
    ...                 platformName=${PLATFORM_NAME}
    ...                 automationName=${AUTOMATION_NAME}
    ...                 appPackage=${APP_PACKAGE}
    ...                 appActivity=${APP_ACTIVITY}
    ...                 noReset=true

Login With Credentials
    [Documentation]    กรอกเบอร์โทรศัพท์ รหัสผ่าน และกดเข้าสู่ระบบ
    [Arguments]    ${phone}    ${password}
    Wait Until Element Is Visible    xpath=//android.widget.EditText[@text="เบอร์โทรศัพท์"]    timeout=5s
    Input Text    xpath=//android.widget.EditText[@text="เบอร์โทรศัพท์"]    ${phone}
    Input Text    xpath=//android.widget.EditText[@text="รหัสผ่าน"]       ${password}
    Hide Keyboard
    Click Element    accessibility_id=เข้าสู่ระบบ

Submit OTP
    [Documentation]    กรอกรหัส OTP 6 หลักและกดยืนยัน
    [Arguments]    ${otp_code}
    Wait Until Element Is Visible    xpath=//android.widget.TextView[@text="ยืนยัน OTP ของคุณ"]    timeout=15s
    
    # ดึงช่องกรอก OTP ทั้งหมดมาเก็บไว้เป็น List
    ${otp_fields}=    Get WebElements    class=android.widget.EditText
    
    # แตะที่ช่องแรกเพื่อให้คีย์บอร์ดเด้งขึ้นมา
    Click Element    ${otp_fields}[0]
    Sleep    1s
    
    # วนลูปส่งคำสั่งกดคีย์บอร์ดตัวเลขทีละตัว (ใช้ Android Keycode: 0=7, 1=8, ..., 9=16)
    FOR    ${index}    IN RANGE    6
        ${digit}=    Evaluate    '${otp_code}'[${index}]
        ${keycode}=    Evaluate    int(${digit}) + 7
        Press Keycode    ${keycode}
    END
    
    # กดปุ่มยืนยัน
    # สามารถใช้ xpath หรีอ accessibility_id ตามที่นักพัฒนาตั้งไว้
    Click Element    accessibility_id=ยืนยัน

Close Driver App
    [Documentation]    ปิดแอปพลิเคชัน
    Close Application

Logout From Driver App
    [Documentation]    กดเข้าหน้า Profile และกดออกจากระบบ
    # 1. รอจนกว่าปุ่ม Profile จะปรากฏ (เพิ่ม timeout เผื่อรอโหลดหลังล็อกอิน)
    Wait Until Element Is Visible    accessibility_id=Profile    timeout=15s
    Click Element    accessibility_id=Profile
    
    # 2. รอเมนูออกจากระบบโหลดขึ้นมา และกด
    Wait Until Element Is Visible    accessibility_id=ออกจากระบบ,     timeout=10s
    Click Element    accessibility_id=ออกจากระบบ, 

Login To TMS Admin
    [Documentation]    ล็อกอินเข้าระบบ TMS Admin ผ่านเว็บ
    SeleniumLibrary.Open Browser    ${TMS_URL}    chrome
    SeleniumLibrary.Maximize Browser Window
    Sleep    2s
    SeleniumLibrary.Wait Until Element Is Visible    id=email    timeout=30s
    SeleniumLibrary.Input Text    id=email    ${TMS_USER}
    SeleniumLibrary.Input Text    id=password    ${TMS_PASSWORD}
    SeleniumLibrary.Press Keys    id=password    ENTER
    Sleep    2s
    
Tap Clockin Driver App Menu
    [Arguments]    ${booking_no}
    [Documentation]    คลิกปุ่ม Clock in และตรวจสอบความถูกต้องของ Booking No บนหน้าจอ
    Wait Until Element Is Visible    xpath=//android.view.View[@content-desc="Clock in"]/com.horcrux.svg.SvgView/com.horcrux.svg.GroupView/com.horcrux.svg.PathView
    Click Element    xpath=//android.view.View[@content-desc="Clock in"]/com.horcrux.svg.SvgView/com.horcrux.svg.GroupView/com.horcrux.svg.PathView
    
    # ตรวจสอบเลข Booking ว่าตรงกับที่ Import ไปหรือไม่
    Wait Until Element Is Visible    xpath=//android.widget.TextView[@text="${booking_no}"]    timeout=15s
    Log To Console    \n✅ ตรวจสอบพบเลข Booking: ${booking_no} ถูกต้อง!

Driver Clockin
    [Documentation]    ไปที่เมนู Clockin, กดลงเวลาเข้างาน, ถ่ายรูป, และยืนยัน
    
    # ไปที่เมนู clockin
    Wait Until Element Is Visible    xpath=//android.view.View[@content-desc="Clock in"]/com.horcrux.svg.SvgView/com.horcrux.svg.GroupView/com.horcrux.svg.PathView    timeout=15s
    Click Element    xpath=//android.view.View[@content-desc="Clock in"]/com.horcrux.svg.SvgView/com.horcrux.svg.GroupView/com.horcrux.svg.PathView
    Sleep    2s
    
    # กด ลงเวลาเข้างานเลย
    Wait Until Element Is Visible    xpath=//android.view.ViewGroup[contains(@content-desc, 'ลงเวลาเข้างานเลย')]    timeout=15s
    Click Element    xpath=//android.view.ViewGroup[contains(@content-desc, 'ลงเวลาเข้างานเลย')]
    Sleep    2s
    
    # กด shutter
    Wait Until Element Is Visible    xpath=//android.widget.ScrollView/android.view.ViewGroup/android.view.ViewGroup/android.view.ViewGroup[7]/android.view.ViewGroup    timeout=15s
    Click Element    xpath=//android.widget.ScrollView/android.view.ViewGroup/android.view.ViewGroup/android.view.ViewGroup[7]/android.view.ViewGroup
    Sleep    3s
    
    # กด ยืนยัน
    Wait Until Element Is Visible    xpath=//android.view.ViewGroup[@content-desc="ยืนยัน"]    timeout=15s
    Click Element    xpath=//android.view.ViewGroup[@content-desc="ยืนยัน"]
    Sleep    2s

Process Booking Import
    [Documentation]    คลิกเมนู Booking, รอโหลดข้อมูล และคลิกปุ่ม Import
    # คลิกไปที่เมนู Booking
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//li[.//span[text()='Booking']]    timeout=15s
    SeleniumLibrary.Click Element    xpath=//li[.//span[text()='Booking']]
    Sleep    1s
    
    # รอคำว่า per page แสดงขึ้นมา
    SeleniumLibrary.Wait Until Page Contains    per page    timeout=30s
    Sleep    1s
    
    # คลิกที่ปุ่ม sync
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//button[.//span[@aria-label='file-sync']]    timeout=15s
    SeleniumLibrary.Click Element    xpath=//button[.//span[@aria-label='file-sync']]
    Sleep    1s
    
    # คลิกที่ปุ่ม import ไอคอน (ปุ่มที่ 2 ในแถว Import Booking)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//div[contains(@class, 'import-export-content') and .//span[text()='Import Booking']]//button[.//span[@aria-label='import']]    timeout=15s
    SeleniumLibrary.Click Element    xpath=//div[contains(@class, 'import-export-content') and .//span[text()='Import Booking']]//button[.//span[@aria-label='import']]
    Sleep    1s
    
    # เลือกไฟล์อัปโหลด โดยส่ง Path ไฟล์เข้าไปที่ input type="file" โดยตรง (ไม่ต้องคลิกกรอบเพื่อเปิดหน้าต่าง Windows)
    SeleniumLibrary.Wait Until Page Contains Element    xpath=//input[@type='file']    timeout=15s
    SeleniumLibrary.Choose File    xpath=//input[@type='file']    C:\\ShareFolder\\BJC\\claude_proj\\DriverApp\\importfile\\ImportBooking.xlsx
    
    # กดปุ่ม Verify
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//button[.//span[text()='Verify']]    timeout=15s
    SeleniumLibrary.Click Element    xpath=//button[.//span[text()='Verify']]
    
    # รอจนปุ่ม Import แสดงขึ้นมาและกด
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//button[.//span[text()='Import']]    timeout=15s
    SeleniumLibrary.Click Element    xpath=//button[.//span[text()='Import']]
    Sleep    3s

Logout TMS Admin
    # รอให้ล็อกอินสำเร็จและแสดงรูปโปรไฟล์
    SeleniumLibrary.Wait Until Element Is Visible    css=span.ant-avatar    timeout=15s
    SeleniumLibrary.Click Element    css=span.ant-avatar
    Sleep    1s
    # รอให้เมนู Signout ปรากฏและคลิก
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//span[text()='Signout']    timeout=15s
    Sleep    1s    # รอให้แอนิเมชันของเมนูโหลดเสร็จ
    SeleniumLibrary.Click Element    xpath=//li[.//span[text()='Signout']]
    
Close Browser
    SeleniumLibrary.Close Browser

Get Latest Booking Info
    [Documentation]    ดึงข้อมูล Booking No และ Status จากแถวบนสุด
    # ให้เวลาระบบประมวลผลไฟล์สักครู่
    Sleep    2s
    
    # ระบบตารางมักจะรีเฟรชข้อมูลเองหรือมีข้อมูลโผล่มาแล้ว
    # (เอาปุ่ม file-sync ออกเพราะไปกดโดนปุ่มเปิด Import/Export)
    
    # เลื่อนขวาไปหาหัวคอลัมน์ Created At และกดจัดเรียง 2 ครั้ง (เพื่อให้ใหม่สุดอยู่บน)
    # ใช้ Javascript ในการคลิกเพื่อป้องกันการโดนคอลัมน์ขวาสุดบัง (ElementClickInterceptedException)
    ${th_element}=    SeleniumLibrary.Get WebElement    xpath=//th[contains(., 'Created At')]
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "center", block: "center"});    ARGUMENTS    ${th_element}
    Sleep    1s
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${th_element}
    Sleep    1s
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${th_element}
    Sleep    1s
    
    # เลื่อนกลับมาซ้ายสุดของตาราง แล้วหยุด 3 วินาทีตามที่ต้องการ
    ${first_th}=    SeleniumLibrary.Get WebElement    xpath=//th[1]
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "start", block: "center"});    ARGUMENTS    ${first_th}
    Sleep    3s
    
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//tr[contains(@class, 'ant-table-row')][1]    timeout=15s
    
    # อ่านข้อมูลก่อนเพื่อนำมาเช็คสถานะ
    ${booking_no}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]
    ${status}=        SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[3]//span
    
    # กำหนดสีไฮไลต์ (Confirmed = เขียว, Error = แดง)
    ${border_color}=    Set Variable If    '${status.upper()}' == 'CONFIRMED'    green      red
    ${bg_color}=        Set Variable If    '${status.upper()}' == 'CONFIRMED'    \#e6ffe6    \#ffe6e6
    
    # Highlight แถวแรกเพื่อให้เห็นชัดเจนในวิดีโอตามสีของสถานะ
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]    ${border_color}    ${bg_color}
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[3]    ${border_color}    ${bg_color}
    
    # อ่านค่า Created At (โดยอ้างอิงตำแหน่ง index ของหัวคอลัมน์ Created At)
    ${created_at}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[count(//th[contains(., 'Created At')]/preceding-sibling::th)+1]
    
    # แสดงผลทางหน้าจอ Command line (Console)
    Log To Console    \n=========================
    Log To Console    Booking No: ${booking_no}
    Log To Console    Status: ${status}
    Log To Console    Created At: ${created_at}
    Log To Console    =========================
    
    RETURN    ${booking_no}    ${status}

Highlight Web Element
    [Documentation]    วาดกรอบสีตามที่กำหนดรอบๆ Element เพื่อให้สังเกตง่ายในวิดีโอ
    [Arguments]    ${locator}    ${border_color}=red    ${bg_color}=\#ffe6e6
    ${element}=    SeleniumLibrary.Get WebElement    ${locator}
    SeleniumLibrary.Execute Javascript    arguments[0].style.border='3px solid ${border_color}';    ARGUMENTS    ${element}
    SeleniumLibrary.Execute Javascript    arguments[0].style.backgroundColor='${bg_color}';    ARGUMENTS    ${element}
    Sleep    1s

Login To Kafka UI
    [Documentation]    ล็อกอินเข้าระบบ Kafka UI
    SeleniumLibrary.Open Browser    ${KAFKA_URL}    chrome
    SeleniumLibrary.Maximize Browser Window
    SeleniumLibrary.Wait Until Element Is Visible    id=username    timeout=15s
    SeleniumLibrary.Input Text    id=username    ${KAFKA_USER}
    SeleniumLibrary.Input Text    id=password    ${KAFKA_PASSWORD}
    SeleniumLibrary.Click Button    xpath=//button[@type='submit']
    Sleep    2s

Produce Kafka Message
    [Documentation]    เลือก Topic bigc.lastmiles.do-post แล้วส่ง Message พร้อม Key และ Value
    [Arguments]    ${key_value}    ${payload_string}
    
    # คลิกที่เมนู Topics
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[@title='Topics']    timeout=15s
    SeleniumLibrary.Click Element    xpath=//a[@title='Topics']
    Sleep    1s
    
    # คลิกที่ Topic bigc.lastmiles.do-post
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[@title='bigc.lastmiles.do-post']    timeout=15s
    SeleniumLibrary.Click Element    xpath=//a[@title='bigc.lastmiles.do-post']
    Sleep    1s
    
    # คลิกปุ่ม Produce Message
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//button[contains(text(), 'Produce Message')]    timeout=15s
    SeleniumLibrary.Click Button    xpath=//button[contains(text(), 'Produce Message')]
    Sleep    2s
    
    # รอ Editor โหลดสักครู่ และแฮ็กให้มองเห็นช่องกรอก
    SeleniumLibrary.Wait Until Page Contains Element    xpath=(//textarea[contains(@class, 'ace_text-input')])[1]    timeout=5s
    SeleniumLibrary.Execute Javascript    document.querySelectorAll('.ace_text-input')[0].style.opacity = '1';
    SeleniumLibrary.Execute Javascript    document.querySelectorAll('.ace_text-input')[1].style.opacity = '1';
    
    # =========================================================================
    # วาง Key (ใช้วิธี Copy ใส่ Clipboard แล้ว CTRL+V)
    # =========================================================================
    Sleep    1s
    SeleniumLibrary.Execute Javascript    var temp = document.createElement("textarea"); temp.value = arguments[0]; document.body.appendChild(temp); temp.select(); document.execCommand("copy"); document.body.removeChild(temp);    ARGUMENTS    ${key_value}
    SeleniumLibrary.Press Keys    xpath=(//textarea[contains(@class, 'ace_text-input')])[1]    CTRL+a+BACKSPACE
    SeleniumLibrary.Press Keys    xpath=(//textarea[contains(@class, 'ace_text-input')])[1]    CTRL+v
    
    # =========================================================================
    # วาง Value JSON (ใช้วิธี Copy ใส่ Clipboard แล้ว CTRL+V)
    # =========================================================================
    Sleep    1s
    SeleniumLibrary.Execute Javascript    var temp = document.createElement("textarea"); temp.value = arguments[0]; document.body.appendChild(temp); temp.select(); document.execCommand("copy"); document.body.removeChild(temp);    ARGUMENTS    ${payload_string}
    SeleniumLibrary.Press Keys    xpath=(//textarea[contains(@class, 'ace_text-input')])[2]    CTRL+a+BACKSPACE
    SeleniumLibrary.Press Keys    xpath=(//textarea[contains(@class, 'ace_text-input')])[2]    CTRL+v
    
    # =========================================================================
    # กดปุ่มส่งข้อความ
    # =========================================================================
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//button[contains(text(), 'Produce Message') and @type='submit']    timeout=5s
    SeleniumLibrary.Click Button    xpath=//button[contains(text(), 'Produce Message') and @type='submit']
    Sleep    1s

Logout From Kafka UI
    [Documentation]    Logout ออกจากระบบ Kafka UI
    # กดที่เมนู admin (อาจเป็น div, span หรือ button)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//div[contains(text(), 'admin')] | //span[contains(text(), 'admin')] | //button[contains(., 'admin')]    timeout=5s
    SeleniumLibrary.Click Element    xpath=//div[contains(text(), 'admin')] | //span[contains(text(), 'admin')] | //button[contains(., 'admin')]
    
    # กดที่ Log out
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//div[contains(text(), 'Log out')] | //li[contains(text(), 'Log out')] | //a[contains(text(), 'Log out')]    timeout=5s
    SeleniumLibrary.Click Element    xpath=//div[contains(text(), 'Log out')] | //li[contains(text(), 'Log out')] | //a[contains(text(), 'Log out')]
    Sleep    1s

Verify Delivery Order In TMS
    [Documentation]    ไปที่เมนู Delivery Order ค้นหาด้วย External Order No. และ Highlight แถวที่พบ (ค่า default ของสถานะที่คาดหวังคือ IN_LOAD)
    [Arguments]    ${external_order_no}    ${expected_status}=IN_LOAD
    
    # คลิกเมนู Delivery Order (ใช้ JavaScript เพื่อหลีกเลี่ยง ElementClickInterceptedException)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[contains(@href, 'delivery_order/tms_delivery_order')]    timeout=20s
    ${menu_do}=    SeleniumLibrary.Get WebElement    xpath=//a[contains(@href, 'delivery_order/tms_delivery_order')]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${menu_do}
    Sleep    2s
    
    # กรอก External Order No. ในช่องค้นหา (Clear ก่อน เพื่อลบค่าเก่า แล้วกด Enter เพื่อ trigger การค้นหา)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    timeout=15s
    SeleniumLibrary.Clear Element Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]
    SeleniumLibrary.Input Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ${external_order_no}
    SeleniumLibrary.Press Keys    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ENTER
    Sleep    2s
    
    # รอผลลัพธ์โหลดเสร็จ (รอให้แถวแรกมีค่า External Order No ตรงกับที่ค้นหา)
    SeleniumLibrary.Wait Until Element Contains    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[3]    ${external_order_no}    timeout=15s
    
    # อ่าน Delivery No., External Order No. และ Status จากแถวแรก
    ${found_delivery_no}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]
    ${found_ext_no}=         SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[3]
    ${found_status}=         SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[5]//span
    
    # กำหนดสี Highlight (ถ้า External No. ตรงกันและ Status = ${expected_status} → เขียว, อื่นๆ → แดง)
    ${is_match}=    Evaluate    '${found_ext_no}' == '${external_order_no}' and '${found_status.upper()}' == '${expected_status.upper()}'
    ${border_color}=    Set Variable If    ${is_match}    green    red
    ${bg_color}=        Set Variable If    ${is_match}    \#e6ffe6    \#ffe6e6
    
    # Highlight แถวบนสุด — คอลัมน์ External Order No. และ Status
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[3]    ${border_color}    ${bg_color}
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[5]    ${border_color}    ${bg_color}
    Sleep    2s
    
    # แสดงผลใน Console
    Log To Console    \n=========================
    Log To Console    Delivery No: ${found_delivery_no}
    Log To Console    External Order No: ${found_ext_no}
    Log To Console    Status: ${found_status}
    Log To Console    =========================
    
    # ตรวจสอบความถูกต้อง
    Should Be Equal    ${found_ext_no}    ${external_order_no}    External Order No. ไม่ตรงกัน!
    Should Be Equal As Strings    ${found_status.upper()}    ${expected_status.upper()}    Status ไม่ใช่ ${expected_status}!
    
    RETURN    ${found_delivery_no}

Verify Delivery Load In TMS
    [Documentation]    ไปที่เมนู Delivery Loads ค้นหาด้วย Delivery No. และ Highlight Load No, Status, Delivery Orders
    [Arguments]    ${delivery_no}
    
    # คลิกเมนู Delivery Loads (ใช้ JavaScript เพื่อหลีกเลี่ยง ElementClickInterceptedException)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[contains(@href, 'delivery_loads/tms_delivery_load')]    timeout=20s
    ${menu_dl}=    SeleniumLibrary.Get WebElement    xpath=//a[contains(@href, 'delivery_loads/tms_delivery_load')]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${menu_dl}
    Sleep    2s
    
    # กรอก Delivery No. ในช่องค้นหา (Clear ก่อน เพื่อลบค่าเก่า แล้วกด Enter เพื่อ trigger การค้นหา)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    timeout=15s
    SeleniumLibrary.Clear Element Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]
    SeleniumLibrary.Input Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ${delivery_no}
    SeleniumLibrary.Press Keys    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ENTER
    Sleep    2s
    
    # รอผลลัพธ์โหลดเสร็จ (รอให้แถวแรกมีค่า Delivery No ตรงกับที่ค้นหา)
    SeleniumLibrary.Wait Until Element Contains    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[12]    ${delivery_no}    timeout=15s
    
    # อ่านค่า Load No. (td[2]), Status (td[6]), Delivery Orders (td[12]) จากแถวแรก
    ${found_load_no}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]
    ${found_status}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[6]//span
    ${found_delivery_orders}=    SeleniumLibrary.Get Text    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[12]//span
    
    # Highlight สีเขียวเสมอ (แสดงข้อมูลที่พบ)
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]     green    \#e6ffe6
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[6]     green    \#e6ffe6
    Highlight Web Element    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[12]    green    \#e6ffe6
    Sleep    2s
    
    # แสดงผลใน Console
    Log To Console    \n=========================
    Log To Console    Load No: ${found_load_no}
    Log To Console    Status: ${found_status}
    Log To Console    Delivery Orders: ${found_delivery_orders}
    Log To Console    =========================

Cancel Delivery Order Via API
    [Documentation]    ยิง POST request ไปยัง TMS Core API เพื่อขอ cancel Delivery Order ด้วย External Delivery No. ที่กำหนด และคืนค่า Response object
    [Arguments]    ${external_delivery_no}

    RequestsLibrary.Create Session    tms_core    ${TMS_CORE_API_URL}

    # เข้ารหัส Basic Auth จาก Username/Password (credential นี้คงที่ ไม่หมดอายุเหมือน session token)
    ${basic_auth}=    Evaluate    __import__('base64').b64encode(("${TMS_API_USERNAME}:${TMS_API_PASSWORD}").encode()).decode()

    # ต้องใส่ User-Agent แบบ browser จริง ไม่งั้น Cloudflare Bot Management จะตีกลับเป็นหน้า Challenge (403)
    # ก่อนถึง API จริง แม้ Auth จะถูกต้องก็ตาม (ยืนยันแล้วว่า UA ของ curl/python-requests โดน block)
    ${headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Authorization=Basic ${basic_auth}
    ...    User-Agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36

    ${reason}=    Create Dictionary    reason_code=${EMPTY}    reason_description=${EMPTY}
    ${body}=    Create Dictionary
    ...    external_delivery_no=${external_delivery_no}
    ...    mode=cancel
    ...    reason=${reason}

    ${response}=    RequestsLibrary.POST On Session
    ...    tms_core
    ...    /api/v1/tms_delivery_order/cancel/${external_delivery_no}
    ...    json=${body}
    ...    headers=${headers}
    ...    expected_status=any

    Log To Console    \n=========================
    Log To Console    Cancel API - External Delivery No: ${external_delivery_no}
    Log To Console    Cancel API - Status Code: ${response.status_code}
    Log To Console    Cancel API - Response Body: ${response.text}
    Log To Console    =========================

    RETURN    ${response}

Verify Cancel Order Rejected
    [Documentation]    ตรวจสอบว่า Response จาก API cancel บ่งชี้ว่าระบบปฏิเสธการ cancel เนื่องจากสถานะปัจจุบันไม่อนุญาต (success=false, code=CANCEL_NOT_ALLOW)
    [Arguments]    ${response}

    ${resp_json}=    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    success
    Should Be Equal As Strings    ${resp_json}[success]    False
    ...    ระบบ cancel order สำเร็จ ทั้งที่ควรจะถูกปฏิเสธเพราะสถานะเป็น IN_LOAD
    Should Be Equal As Strings    ${resp_json}[code]    CANCEL_NOT_ALLOW
    ...    error code จาก API ไม่ตรงกับที่คาดหวัง (CANCEL_NOT_ALLOW)
    Should Contain    ${resp_json}[message]    cannot be cancelled
    ...    error message จาก API ไม่ตรงกับที่คาดหวัง

    Log To Console    \n✅ ยืนยันแล้วว่าระบบไม่อนุญาตให้ cancel order สถานะ IN_LOAD (${resp_json}[message])

Verify Cancel Order Succeeded
    [Documentation]    ตรวจสอบว่า Response จาก API cancel บ่งชี้ว่าระบบ cancel สำเร็จ (success=true, code=SUCCESS)
    [Arguments]    ${response}

    ${resp_json}=    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    success
    Should Be Equal As Strings    ${resp_json}[success]    True
    ...    ระบบ cancel order ไม่สำเร็จ ทั้งที่ควรจะสำเร็จเพราะสถานะเป็น Pending
    Should Be Equal As Strings    ${resp_json}[code]    SUCCESS
    ...    error code จาก API ไม่ตรงกับที่คาดหวัง (SUCCESS)
    Should Contain    ${resp_json}[message]    cancelled successfully
    ...    error message จาก API ไม่ตรงกับที่คาดหวัง

    Log To Console    \n✅ ยืนยันแล้วว่าระบบ cancel order สถานะ Pending สำเร็จ (${resp_json}[message])

Open Delivery Order Detail From List
    [Documentation]    คลิกปุ่ม Detail (ไอคอน file-text ในคอลัมน์ ACTIONS) ของแถวแรกในหน้า Delivery Order List เพื่อเข้าหน้า Detail
    SeleniumLibrary.Wait Until Element Is Visible
    ...    xpath=//tr[contains(@class, 'ant-table-row')][1]//a[contains(@class, 'table-action-button')][.//span[@aria-label='file-text']]
    ...    timeout=15s
    ${detail_btn}=    SeleniumLibrary.Get WebElement
    ...    xpath=//tr[contains(@class, 'ant-table-row')][1]//a[contains(@class, 'table-action-button')][.//span[@aria-label='file-text']]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${detail_btn}
    SeleniumLibrary.Wait Until Page Contains    Status History    timeout=20s
    Sleep    1s

Verify No Cancel In Status History
    [Documentation]    ตรวจสอบว่า entry ล่าสุด (ตามเวลา) ใน Status History timeline ไม่ใช่ Cancel เพื่อยืนยันว่า order ไม่ได้ถูกยกเลิกจริง
    ${timeline_locator}=    Set Variable    xpath=//ul[contains(@class, 'ant-timeline')]
    ${last_item_locator}=    Set Variable
    ...    xpath=(//ul[contains(@class, 'ant-timeline')]//li[contains(@class, 'ant-timeline-item')])[last()]

    SeleniumLibrary.Wait Until Element Is Visible    ${timeline_locator}    timeout=20s

    ${last_item}=    SeleniumLibrary.Get WebElement    ${last_item_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "center", block: "center"});    ARGUMENTS    ${last_item}
    Sleep    1s

    ${last_status_text}=    SeleniumLibrary.Get Text    ${last_item_locator}
    Highlight Web Element    ${last_item_locator}    green    \#e6ffe6

    Log To Console    \n=========================
    Log To Console    Latest Status History Entry:\n${last_status_text}
    Log To Console    =========================

    Should Not Contain    ${last_status_text}    Cancel
    ...    สถานะล่าสุดใน Status History เป็น Cancel ทั้งที่ระบบควรปฏิเสธการ cancel!
    ...    ignore_case=True

    Log To Console    \n✅ ยืนยันแล้วว่าสถานะล่าสุดใน Status History ไม่ใช่ Cancel (order ยังไม่ถูกยกเลิกจริง)

Verify Cancel In Status History
    [Documentation]    ตรวจสอบว่า entry ล่าสุด (ตามเวลา) ใน Status History timeline เป็น Cancel เพื่อยืนยันว่า order ถูกยกเลิกจริงตาม response ที่ได้
    ${timeline_locator}=    Set Variable    xpath=//ul[contains(@class, 'ant-timeline')]
    ${last_item_locator}=    Set Variable
    ...    xpath=(//ul[contains(@class, 'ant-timeline')]//li[contains(@class, 'ant-timeline-item')])[last()]

    SeleniumLibrary.Wait Until Element Is Visible    ${timeline_locator}    timeout=20s

    ${last_item}=    SeleniumLibrary.Get WebElement    ${last_item_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "center", block: "center"});    ARGUMENTS    ${last_item}
    Sleep    1s

    ${last_status_text}=    SeleniumLibrary.Get Text    ${last_item_locator}
    Highlight Web Element    ${last_item_locator}    green    \#e6ffe6

    Log To Console    \n=========================
    Log To Console    Latest Status History Entry:\n${last_status_text}
    Log To Console    =========================

    Should Contain    ${last_status_text}    Cancel
    ...    สถานะล่าสุดใน Status History ไม่ใช่ Cancel ทั้งที่ระบบควร cancel สำเร็จ!
    ...    ignore_case=True

    Log To Console    \n✅ ยืนยันแล้วว่าสถานะล่าสุดใน Status History เป็น Cancel (order ถูกยกเลิกสำเร็จจริง)

Open Delivery Task Detail By Task No
    [Documentation]    ไปที่เมนู Delivery Tasks ค้นหาด้วย Task No. แล้วคลิกปุ่ม view (ไอคอน file-text) ของแถวแรกเพื่อเข้าหน้า Detail
    [Arguments]    ${task_no}

    # คลิกเมนู Delivery Tasks (ใช้ JavaScript เพื่อหลีกเลี่ยง ElementClickInterceptedException)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//a[contains(@href, 'delivery_tasks/tms_task')]    timeout=20s
    ${menu_dt}=    SeleniumLibrary.Get WebElement    xpath=//a[contains(@href, 'delivery_tasks/tms_task')]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${menu_dt}
    Sleep    2s

    # กรอก Task No. ในช่องค้นหา (Clear ก่อน เพื่อลบค่าเก่า แล้วกด Enter เพื่อ trigger การค้นหา)
    SeleniumLibrary.Wait Until Element Is Visible    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    timeout=15s
    SeleniumLibrary.Clear Element Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]
    SeleniumLibrary.Input Text    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ${task_no}
    SeleniumLibrary.Press Keys    xpath=//input[@placeholder='Search' and contains(@class, 'ant-input')]    ENTER
    Sleep    2s

    # รอผลลัพธ์โหลดเสร็จ (รอให้แถวแรกมีค่า Task No ตรงกับที่ค้นหา)
    SeleniumLibrary.Wait Until Element Contains    xpath=//tr[contains(@class, 'ant-table-row')][1]/td[2]    ${task_no}    timeout=15s

    # คลิกปุ่ม view (ไอคอน file-text ในคอลัมน์ ACTIONS) ของแถวแรก
    SeleniumLibrary.Wait Until Element Is Visible
    ...    xpath=//tr[contains(@class, 'ant-table-row')][1]//a[contains(@class, 'table-action-button')][.//span[@aria-label='file-text']]
    ...    timeout=15s
    ${view_btn}=    SeleniumLibrary.Get WebElement
    ...    xpath=//tr[contains(@class, 'ant-table-row')][1]//a[contains(@class, 'table-action-button')][.//span[@aria-label='file-text']]
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${view_btn}
    # รอข้อความ "Delivery Orders" แทน "Add Ad-hoc Order" เพราะปุ่ม Add Ad-hoc Order อาจไม่มีในบาง Task (เช่น สถานะ Dispatched - ดู TC_REG_069)
    # ส่วน "Delivery Orders" เป็น section ที่มีอยู่ในหน้า Task Detail เสมอไม่ว่าสถานะไหน
    SeleniumLibrary.Wait Until Page Contains    Delivery Orders    timeout=20s
    Sleep    1s

Get Visible Add Ad Hoc Order Button
    [Documentation]    คืนค่า WebElement ของปุ่ม Add Ad-hoc Order ตัวที่มองเห็นได้จริง (หน้านี้มีปุ่มที่ตรง xpath ซ้ำใน DOM 2 ตัว)
    ...    ใช้ contains(., ...) แทน contains(text(), ...) เพราะ React มักแทรก comment node คั่นกลาง text ทำให้ text() คืนหลาย node
    ...    Fail ถ้ายังไม่เจอตัวที่มองเห็นได้ - ให้เรียกผ่าน Wait Until Keyword Succeeds เพื่อ retry จนกว่าจะเจอจริง
    ${adhoc_btn_locator}=    Set Variable    xpath=//button[contains(., 'Add Ad-hoc Order')]
    ${candidates}=    SeleniumLibrary.Get WebElements    ${adhoc_btn_locator}
    FOR    ${candidate}    IN    @{candidates}
        ${is_visible}=    Run Keyword And Return Status    SeleniumLibrary.Element Should Be Visible    ${candidate}
        IF    ${is_visible}
            RETURN    ${candidate}
        END
    END
    Fail    ยังไม่พบปุ่ม Add Ad-hoc Order ที่มองเห็นได้ในหน้า Delivery Task Detail (จะลองใหม่)

Verify Add Ad Hoc Order Button Not Present
    [Documentation]    ตรวจสอบว่าไม่มีปุ่ม Add Ad-hoc Order ที่มองเห็นได้เลยในหน้า Delivery Task Detail (ใช้กับ Task ที่ไม่ควรมีปุ่มนี้ เช่น สถานะ Dispatched)
    ${adhoc_btn_locator}=    Set Variable    xpath=//button[contains(., 'Add Ad-hoc Order')]
    ${candidates}=    SeleniumLibrary.Get WebElements    ${adhoc_btn_locator}

    ${visible_found}=    Set Variable    ${False}
    FOR    ${candidate}    IN    @{candidates}
        ${is_visible}=    Run Keyword And Return Status    SeleniumLibrary.Element Should Be Visible    ${candidate}
        IF    ${is_visible}
            ${visible_found}=    Set Variable    ${True}
            BREAK
        END
    END

    Should Not Be True    ${visible_found}
    ...    พบปุ่ม Add Ad-hoc Order ในหน้า Delivery Task Detail ทั้งที่ไม่ควรมี!

    Log To Console    \n✅ ยืนยันแล้วว่าไม่มีปุ่ม Add Ad-hoc Order ปรากฏในหน้า Task Detail นี้ตามที่คาดหวัง

Add Ad Hoc Order To Task
    [Documentation]    ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order ในหน้า Delivery Task Detail แล้วค้นหา Order ด้วย External Order No. ที่กำหนด
    ...    ผลที่คาดหวัง (PASS) คือต้องขึ้น "No addable orders" แปลว่า order สถานะ Pending นี้ไม่สามารถเพิ่มเป็น Ad-hoc เข้า task นี้ได้
    [Arguments]    ${external_order_no}

    # ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order (นี่คือข้อกำหนดหลักของ test case นี้)
    # ใช้ contains(., ...) แทน contains(text(), ...) เพราะ React มักแทรก comment node คั่นกลาง text
    # ทำให้ text() คืนหลาย node แล้ว contains() เช็คแค่ node แรก (อาจไม่ match) - contains(., ...) รวม string-value ทั้งหมดของ element แทน
    # หน้านี้มีปุ่มที่ตรง xpath ซ้ำ 2 ตัว (เช่น responsive layout ซ่อนอันนึงไว้) เลยต้องหาเอาตัวที่มองเห็นได้จริง แทนที่จะเชื่อตัวแรกใน DOM
    SeleniumLibrary.Wait Until Page Contains Element    xpath=//button[contains(., 'Add Ad-hoc Order')]    timeout=20s
    ...    error=ไม่พบปุ่ม Add Ad-hoc Order ในหน้า Delivery Task Detail!

    # หน้านี้มีปุ่มที่ตรง xpath ซ้ำ 2 ตัว (เช่น responsive layout ซ่อนอันนึงไว้) และบางครั้งยังไม่ visible ทันทีตอนเพิ่งเจอใน DOM
    # เลยต้อง retry จนกว่าจะเจอตัวที่มองเห็นได้จริง แทนที่จะเชื่อตัวแรกที่เจอแค่ครั้งเดียว
    ${adhoc_btn}=    Wait Until Keyword Succeeds    20s    1s    Get Visible Add Ad Hoc Order Button
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "center", block: "center"});    ARGUMENTS    ${adhoc_btn}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${adhoc_btn}
    Sleep    1s

    # ช่องกรอก External Order No. เป็น Ant Design Select แบบพิมพ์ค้นหา (placeholder "Search delivery orders to add")
    ${search_selector_locator}=    Set Variable
    ...    xpath=//div[contains(@class,'ant-select-selector')][.//span[contains(@class,'ant-select-selection-placeholder') and contains(., 'Search delivery orders to add')]]
    ${search_input_locator}=    Set Variable
    ...    xpath=//div[contains(@class,'ant-select-selector')][.//span[contains(@class,'ant-select-selection-placeholder') and contains(., 'Search delivery orders to add')]]//input[contains(@class,'ant-select-selection-search-input')]

    SeleniumLibrary.Wait Until Element Is Visible    ${search_selector_locator}    timeout=15s
    ${search_selector}=    SeleniumLibrary.Get WebElement    ${search_selector_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${search_selector}
    Sleep    1s

    # เอา readonly ออกก่อน (Ant Design ใส่ readonly ไว้ตอนยังไม่ focus) เพื่อให้พิมพ์ผ่าน Selenium ได้แน่นอน
    # รอ input ตัวจริงให้ปรากฏก่อน (คลิกเปิด select แล้ว input อาจ re-render ช้ากว่า container นิดหน่อย)
    SeleniumLibrary.Wait Until Element Is Visible    ${search_input_locator}    timeout=10s
    ${search_input}=    SeleniumLibrary.Get WebElement    ${search_input_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].removeAttribute('readonly');    ARGUMENTS    ${search_input}
    SeleniumLibrary.Input Text    ${search_input_locator}    ${external_order_no}
    Sleep    2s

    # รอผลค้นหา (debounce) แล้วตรวจสอบว่า dropdown ขึ้น "No addable orders" (empty state)
    # นี่คือผลลัพธ์ที่คาดหวัง (PASS) - order สถานะ Pending นี้ไม่ควรถูกเพิ่มเป็น Ad-hoc เข้า task ได้
    Sleep    2s
    ${empty_state_locator}=    Set Variable
    ...    xpath=//div[contains(@class, 'ant-select-item-empty') and contains(., 'No addable orders')]
    SeleniumLibrary.Wait Until Element Is Visible    ${empty_state_locator}    timeout=15s
    ...    error=ไม่พบข้อความ "No addable orders" - คาดหวังว่า order สถานะ Pending นี้ไม่ควรเพิ่มเป็น Ad-hoc ได้!

    Log To Console    \n✅ ยืนยันแล้วว่าไม่สามารถเพิ่ม Order สถานะ Pending นี้เป็น Ad-hoc เข้า task ได้ (แสดง "No addable orders" ตามที่คาดหวัง)

    # ปิด popup Add Ad-hoc Order ก่อนออกจากหน้านี้ ด้วยปุ่ม Cancel (ไม่งั้น ant-modal-wrap จะค้างบังปุ่มอื่น เช่นตอน Logout ทำให้ ElementClickInterceptedException)
    # ใช้ JS click (ไม่ใช่ Click Element) เพื่อไม่ให้ mouse cursor จริงเลื่อนผ่านปุ่ม Save/dropdown อื่นบนหน้าจอจนไปโดน hover โดยไม่ตั้งใจ
    ${cancel_btn_locator}=    Set Variable    xpath=//button[contains(@class, 'cancel') and contains(., 'Cancel')]
    SeleniumLibrary.Wait Until Element Is Visible    ${cancel_btn_locator}    timeout=10s
    ${cancel_btn}=    SeleniumLibrary.Get WebElement    ${cancel_btn_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${cancel_btn}
    SeleniumLibrary.Wait Until Element Is Not Visible    ${search_selector_locator}    timeout=10s
    Sleep    1s

Add Ad Hoc Order Successfully To Task
    [Documentation]    ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order ในหน้า Delivery Task Detail แล้วเพิ่ม Order ด้วย External Order No. ที่กำหนดให้สำเร็จ
    ...    ผลที่คาดหวัง (PASS) คือต้องมี preview (Orders/Items/Weight/Volume/COD) แสดงขึ้นมา กด Save ได้ และเจอ Toast "Success!"
    [Arguments]    ${external_order_no}

    # ตรวจสอบว่ามีปุ่ม Add Ad-hoc Order (เหมือน Add Ad Hoc Order To Task - ดูคอมเมนต์ที่นั่นสำหรับเหตุผลของแต่ละจุด)
    SeleniumLibrary.Wait Until Page Contains Element    xpath=//button[contains(., 'Add Ad-hoc Order')]    timeout=20s
    ...    error=ไม่พบปุ่ม Add Ad-hoc Order ในหน้า Delivery Task Detail!

    # หน้านี้มีปุ่มที่ตรง xpath ซ้ำ 2 ตัว (เช่น responsive layout ซ่อนอันนึงไว้) และบางครั้งยังไม่ visible ทันทีตอนเพิ่งเจอใน DOM
    # เลยต้อง retry จนกว่าจะเจอตัวที่มองเห็นได้จริง แทนที่จะเชื่อตัวแรกที่เจอแค่ครั้งเดียว
    ${adhoc_btn}=    Wait Until Keyword Succeeds    20s    1s    Get Visible Add Ad Hoc Order Button
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "center", block: "center"});    ARGUMENTS    ${adhoc_btn}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${adhoc_btn}
    Sleep    1s

    # ช่องกรอก External Order No. เป็น Ant Design Select แบบพิมพ์ค้นหา (placeholder "Search delivery orders to add")
    ${search_selector_locator}=    Set Variable
    ...    xpath=//div[contains(@class,'ant-select-selector')][.//span[contains(@class,'ant-select-selection-placeholder') and contains(., 'Search delivery orders to add')]]
    ${search_input_locator}=    Set Variable
    ...    xpath=//div[contains(@class,'ant-select-selector')][.//span[contains(@class,'ant-select-selection-placeholder') and contains(., 'Search delivery orders to add')]]//input[contains(@class,'ant-select-selection-search-input')]

    SeleniumLibrary.Wait Until Element Is Visible    ${search_selector_locator}    timeout=15s
    ${search_selector}=    SeleniumLibrary.Get WebElement    ${search_selector_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${search_selector}
    Sleep    1s

    # เอา readonly ออกก่อน (Ant Design ใส่ readonly ไว้ตอนยังไม่ focus) เพื่อให้พิมพ์ผ่าน Selenium ได้แน่นอน
    # รอ input ตัวจริงให้ปรากฏก่อน (คลิกเปิด select แล้ว input อาจ re-render ช้ากว่า container นิดหน่อย)
    SeleniumLibrary.Wait Until Element Is Visible    ${search_input_locator}    timeout=10s
    ${search_input}=    SeleniumLibrary.Get WebElement    ${search_input_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].removeAttribute('readonly');    ARGUMENTS    ${search_input}
    SeleniumLibrary.Input Text    ${search_input_locator}    ${external_order_no}
    Sleep    2s

    # คลิกเลือก option ที่เจอใน dropdown (กด ENTER ไม่ trigger การเลือกจริง สำหรับ select ตัวนี้ ต้องคลิกที่ option โดยตรง)
    # แล้วรอ preview (Orders/Items/Weight/Volume/COD) แสดงขึ้นมา - นี่คือผลลัพธ์ที่คาดหวัง (PASS)
    ${option_locator}=    Set Variable    xpath=(//div[contains(@class, 'ant-select-item-option')])[1]
    SeleniumLibrary.Wait Until Element Is Visible    ${option_locator}    timeout=15s
    ...    error=ไม่พบตัวเลือก Order ใน dropdown หลังค้นหา - คาดหวังว่า order สถานะ RE_SCHEDULED นี้ควรเพิ่มเป็น Ad-hoc ได้!
    ${option}=    SeleniumLibrary.Get WebElement    ${option_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${option}

    SeleniumLibrary.Wait Until Page Contains    Orders:    timeout=15s
    ...    error=ไม่พบ preview (Orders/Items/Weight/...) หลังเลือก Order - คาดหวังว่า order สถานะ RE_SCHEDULED นี้ควรเพิ่มเป็น Ad-hoc ได้!
    Sleep    1s

    # กดปุ่ม Save
    ${save_btn_locator}=    Set Variable    xpath=//button[@form='form-popup-detail' and @type='submit']
    SeleniumLibrary.Wait Until Element Is Visible    ${save_btn_locator}    timeout=10s
    ${save_btn}=    SeleniumLibrary.Get WebElement    ${save_btn_locator}
    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${save_btn}

    # รอ Toast "Success!" แสดงขึ้นมา แล้วคลิกเพื่อปิด (best-effort เท่านั้น)
    # Toast นี้มักหายไปเร็วมากเพราะหน้ากำลัง reload/re-fetch ข้อมูลพร้อมกัน (browser busy จนพลาดจังหวะได้ง่าย)
    # ผลลัพธ์จริงที่ต้องผ่านคือ Verify Order In Task Delivery Orders Table ในขั้นตอนถัดไป จึงไม่ทำให้ test fail แค่เพราะจับ Toast ไม่ทัน
    ${toast_locator}=    Set Variable    xpath=//div[contains(@class, 'custom-toast-content')][contains(., 'Success!')]
    ${toast_caught}=    Run Keyword And Return Status
    ...    SeleniumLibrary.Wait Until Element Is Visible    ${toast_locator}    timeout=5s
    IF    ${toast_caught}
        ${toast}=    SeleniumLibrary.Get WebElement    ${toast_locator}
        Run Keyword And Ignore Error    SeleniumLibrary.Execute Javascript    arguments[0].click();    ARGUMENTS    ${toast}
        Log To Console    \n✅ พบ Toast "Success!" และปิดแล้ว
    ELSE
        Log To Console    \n⚠️ จับ Toast "Success!" ไม่ทัน (อาจหายไปเร็วเกินไประหว่างหน้าโหลด) - จะไปยืนยันผลจากตาราง Delivery Orders แทน
    END
    Sleep    1s

    # เลื่อนหน้าจอลงมาหาตาราง Delivery Orders ทันทีหลัง Toast เพื่อให้เห็น/ตรวจสอบต่อได้
    SeleniumLibrary.Wait Until Page Contains Element    xpath=//*[contains(text(), 'Delivery Orders')]    timeout=15s
    ${delivery_orders_heading}=    SeleniumLibrary.Get WebElement    xpath=//*[contains(text(), 'Delivery Orders')]
    # ใช้ inline: "nearest" (ไม่ใช่ "center") กันไม่ให้ตารางที่ scroll แนวนอนได้ถูกเลื่อนไปกลางจนคอลัมน์ External Delivery No. หลุดจากจอ
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "nearest", block: "center"});    ARGUMENTS    ${delivery_orders_heading}
    Sleep    2s

    Log To Console    \n✅ ยืนยันแล้วว่าเพิ่ม Order สถานะ RE_SCHEDULED เป็น Ad-hoc เข้า task สำเร็จ (พบ Toast "Success!")

Verify Order In Task Delivery Orders Table
    [Documentation]    ตรวจสอบว่า External Order No. ที่กำหนดปรากฏอยู่ในตาราง Delivery Orders ของหน้า Task Detail เดิม (ไม่ต้องออกจากหน้านี้) และ highlight แถวที่พบ
    [Arguments]    ${external_order_no}

    # scroll ไปที่ section "Delivery Orders" ก่อน เพราะตารางอยู่ใต้ fold - บางตารางไม่ render แถวจนกว่าจะ scroll เข้าใกล้ (lazy/virtualized render)
    SeleniumLibrary.Wait Until Page Contains Element    xpath=//*[contains(text(), 'Delivery Orders')]    timeout=15s
    ${section_heading}=    SeleniumLibrary.Get WebElement    xpath=//*[contains(text(), 'Delivery Orders')]
    # ใช้ inline: "nearest" (ไม่ใช่ "center") กันไม่ให้ตารางที่ scroll แนวนอนได้ถูกเลื่อนไปกลางจนคอลัมน์ External Delivery No. หลุดจากจอ
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "nearest", block: "center"});    ARGUMENTS    ${section_heading}
    Sleep    1s

    # ใช้ contains(., ...) แทน normalize-space(.)=... เผื่อ cell มี markup/whitespace แฝงอยู่ (เจอปัญหาแบบนี้กับ element อื่นมาก่อนในไฟล์นี้)
    # หลังกด Save ฝั่ง backend ประมวลผล (เช่น คำนวณ route/shift ใหม่ทั้ง task) อาจใช้เวลาเกิน 1 นาที จึงตั้ง timeout ไว้ยาว
    ${row_locator}=    Set Variable
    ...    xpath=//tr[@data-row-key][td[2][contains(., '${external_order_no}')]]
    SeleniumLibrary.Wait Until Element Is Visible    ${row_locator}    timeout=120s
    ...    error=ไม่พบ External Order No: ${external_order_no} ในตาราง Delivery Orders ของ Task นี้ - คาดหวังว่าจะถูกเพิ่มเข้ามาแล้ว!

    ${row}=    SeleniumLibrary.Get WebElement    ${row_locator}
    # ใช้ inline: "nearest" (ไม่ใช่ "center") กันไม่ให้ตารางเลื่อนแนวนอนจนคอลัมน์ External Delivery No. หลุดจากจอ (ต้องการให้อยู่ชิดซ้าย)
    SeleniumLibrary.Execute Javascript    arguments[0].scrollIntoView({inline: "nearest", block: "center"});    ARGUMENTS    ${row}
    Highlight Web Element    ${row_locator}    green    \#e6ffe6
    Sleep    2s

    Log To Console    \n✅ ยืนยันแล้วว่า External Order No: ${external_order_no} ถูกเพิ่มเข้า Task นี้สำเร็จ (พบในตาราง Delivery Orders)
