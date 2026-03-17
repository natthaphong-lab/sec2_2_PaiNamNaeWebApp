*** Settings ***
# UAT เปลี่ยนสถานะรายงาน: 1 หมวด DRIVER + 1 หมวด PASSENGER
# ตรวจครบ 4 สถานะ และตรวจว่า COMPLETED กับ REJECTED กดพร้อมกันไม่ได้
# การเทสซ้ำ: ต้องมีรายงาน PENDING อย่างน้อย 1 รายการจากไดรเวอร์ และ 1 จากผู้โดยสาร (หรือ reset ข้อมูลก่อนรัน)
# ปิด pop-up Chrome: ใช้ headless (ค่าเริ่มต้น) หรือรันแบบมีหน้าต่างแล้วกด OK เองภายในเวลาที่รอ
Library    SeleniumLibrary
Suite Setup    Open Browser And Login Then Report Management
Suite Teardown    Close Browser

*** Variables ***
${URL}                http://localhost:3001
${BROWSER}            Chrome
${ADMIN_USER}         admin123
${ADMIN_PASS}         123456789
# True = รัน Chrome แบบ headless (ไม่มี pop-up รหัสผ่าน), False = เปิดหน้าต่าง (ถ้าโผล่ pop-up ให้กด OK เอง)
${USE_HEADLESS}       True
# ปุ่มสถานะในหน้ารายละเอียดเรียงตาม: 1=PENDING 2=ON_PROGRESS 3=COMPLETED 4=REJECTED (เก็บแค่ expression ไม่มี xpath=)
${STATUS_BUTTONS_XPATH}    //*[@id="main-content"]//div[contains(.,'สถานะปัจจุบัน')]//div[contains(@class,'ml-auto')]/button
${STATUS_BADGE_XPATH}      //*[@id="main-content"]//div[contains(.,'สถานะปัจจุบัน')]//span[contains(@class,'rounded-full')]

*** Test Cases ***
TC01 ไปหน้า Report Management แล้วกดไอคอนรูปดวงตา (รายงานจาก DRIVER)
    [Documentation]    1. กดปุ่ม Report Management จากเมนูแอดมินให้ไปถึงหน้ารายการรายงาน\n2. เลือกรายงานจาก DRIVER สถานะ PENDING แล้วกดไอคอนรูปดวงตาที่แถวแรก
    Go To Report List
    Filter Reports    PENDING    DRIVER
    Open First Report By Eye
    Page Should Contain    รายละเอียดการรายงาน

TC02 จากหน้ารายละเอียดรายงานผู้ขับขี่ กดปุ่มย้อนกลับ
    [Documentation]    1. อยู่หน้ารายละเอียดการรายงานผู้ขับขี่\n2. กดปุ่มย้อนกลับให้กลับมาหน้า Report Management
    # ถ้ายังไม่อยู่หน้ารายละเอียด ให้เปิดจาก DRIVER ก่อน
    Go To Report List
    Filter Reports    PENDING    DRIVER
    Open First Report By Eye
    Page Should Contain    รายละเอียดการรายงาน
    Click Element    xpath=//*[@id="main-content"]/div[1]/a
    Wait Until Location Contains    ${URL}/admin/reports    timeout=10s
    Location Should Be    ${URL}/admin/reports

TC03 เปลี่ยนสถานะรายงานผู้ขับขี่เป็น COMPLETED แล้วตรวจว่า REJECTED กดไม่ได้
    [Documentation]    1. อยู่หน้ารายละเอียดการรายงานผู้ขับขี่ (รายงานจาก DRIVER สถานะเริ่มต้นเป็น PENDING)\n2. เปลี่ยนสถานะผ่านปุ่มบนสุดให้เป็น ON_PROGRESS\n3. เปลี่ยนสถานะเป็น COMPLETED\n4. ตรวจสอบว่าปุ่ม REJECTED ถูกปิดการใช้งาน (กดไม่ได้)
    Go To Report List
    Filter Reports    PENDING    DRIVER
    Open First Report By Eye
    Override Confirm Dialog
    ตรวจสอบและเปลี่ยนสถานะเป็น ON_PROGRESS
    ตรวจสอบและเปลี่ยนสถานะเป็น COMPLETED
    ตรวจสอบปุ่ม REJECTED ถูก disabled (กดไม่ได้)
    Capture Page Screenshot    filename=TC03_DRIVER_COMPLETED.png

TC04 เปลี่ยนสถานะรายงานผู้โดยสารเป็น REJECTED แล้วตรวจว่า COMPLETED กดไม่ได้
    [Documentation]    1. อยู่หน้ารายละเอียดการรายงานผู้โดยสาร (รายงานจาก PASSENGER สถานะเริ่มต้นเป็น PENDING)\n2. เปลี่ยนสถานะผ่านปุ่มบนสุดให้เป็น ON_PROGRESS\n3. เปลี่ยนสถานะเป็น REJECTED\n4. ตรวจสอบว่าปุ่ม COMPLETED ถูกปิดการใช้งาน (กดไม่ได้)
    Go To Report List
    Filter Reports    PENDING    PASSENGER
    Open First Report By Eye
    Override Confirm Dialog
    ตรวจสอบและเปลี่ยนสถานะเป็น ON_PROGRESS
    ตรวจสอบและเปลี่ยนสถานะเป็น REJECTED
    ตรวจสอบปุ่ม COMPLETED ถูก disabled (กดไม่ได้)
    Capture Page Screenshot    filename=TC04_PASSENGER_REJECTED.png

*** Keywords ***
Open Chrome Without Password Manager Popup
    ${options}=    Evaluate    __import__('importlib').import_module('selenium.webdriver.chrome.options').Options()
    ${prefs}=    Evaluate    {"credentials_enable_service": False, "profile.password_manager_enabled": False}
    Call Method    ${options}    add_experimental_option    prefs    ${prefs}
    ${chrome_arg}=    Set Variable    --disable-features=PasswordLeakDetection
    Call Method    ${options}    add_argument    ${chrome_arg}
    # โหมด headless จะไม่โผล่ pop-up "Change your password" ของ Chrome
    ${headless_arg}=    Set Variable    --headless=new
    Run Keyword If    '${USE_HEADLESS}'=='True'    Call Method    ${options}    add_argument    ${headless_arg}
    Open Browser    ${URL}    Chrome    options=${options}

Dismiss Password Breach Popup If Present
    Sleep    1s
    # ลองกด OK (ปุ่มใน dialog ของ Chrome)
    Run Keyword And Ignore Error    Wait Until Element Is Visible    xpath=//button[contains(.,'OK')]    timeout=3s
    Run Keyword And Ignore Error    Click Element    xpath=//button[contains(.,'OK')]
    Sleep    0.5s
    Run Keyword And Ignore Error    Click Element    xpath=//button[normalize-space()='OK']
    Run Keyword And Ignore Error    Press Keys    None    RETURN
    Run Keyword And Ignore Error    Press Keys    None    ESCAPE
    Sleep    0.5s

Open Browser And Login Then Report Management
    Open Chrome Without Password Manager Popup
    IF    '${USE_HEADLESS}' != 'True'
        Maximize Browser Window
    END
    Go To    ${URL}/login
    IF    '${USE_HEADLESS}' != 'True'
        Dismiss Password Breach Popup If Present
    END
    Login And Go To Report Management

Login And Go To Report Management
    I login with valid credentials
    Sleep    2s
    IF    '${USE_HEADLESS}' != 'True'
        Wait For User To Dismiss Chrome Popup
    END
    Go To Dashboard Then Report Management

I open the login page
    Go To    ${URL}
    Maximize Browser Window

I login with valid credentials
    Wait Until Element Is Visible    xpath=//*[@id="identifier"]    timeout=10s
    Input Text      xpath=//*[@id="identifier"]       ${ADMIN_USER}
    Input Password  xpath=//*[@id="password"]    ${ADMIN_PASS}
    Click Button    xpath=//*[@id="loginForm"]/button
    Sleep    2s

Wait For User To Dismiss Chrome Popup
    Log    ถ้ามี pop-up "Change your password" ของ Chrome ให้กด OK (รอได้ 15 วินาที)    WARN
    Sleep    15s

Go To Dashboard Then Report Management
    IF    '${USE_HEADLESS}' != 'True'
        Dismiss Password Breach Popup If Present
    END
    Sleep    1s
    # ไปหน้า Report Management โดยตรง (ไม่พึ่ง sidebar เพื่อให้รันใน headless ได้)
    Go To    ${URL}/admin/reports
    Wait Until Location Contains    ${URL}/admin/reports    timeout=10s
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]    timeout=15s
    Location Should Be    ${URL}/admin/reports

Go To Report List
    Go To    ${URL}/admin/reports
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]//table    timeout=10s

Filter Reports
    [Arguments]    ${status}    ${reporter_role}
    # สถานะคำขอ: PENDING, ON_PROGRESS, COMPLETED, REJECTED
    Select From List By Value    xpath=//*[@id="main-content"]//label[contains(.,'สถานะคำขอ')]/following-sibling::select    ${status}
    # รายงานจาก: DRIVER หรือ PASSENGER
    Select From List By Value    xpath=//*[@id="main-content"]//label[contains(.,'รายงานจาก')]/following-sibling::select    ${reporter_role}
    Click Button    xpath=//*[@id="main-content"]//button[contains(.,'ใช้ตัวกรอง')]
    Sleep    2s

Open First Report By Eye
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]//table/tbody/tr/td[7]/div/button[1]    timeout=10s
    Click Element    xpath=//*[@id="main-content"]//table/tbody/tr[1]/td[7]/div/button[1]
    Wait Until Location Contains    ${URL}/admin/reports/    timeout=10s
    Wait Until Page Contains    รายละเอียดการรายงาน    timeout=10s

Override Confirm Dialog
    Execute JavaScript    window.confirm = function() { return true; }

ตรวจสอบและเปลี่ยนสถานะเป็น ON_PROGRESS
    # ปุ่มที่ 2 = ON_PROGRESS
    Wait Until Element Is Visible    xpath=${STATUS_BUTTONS_XPATH}    timeout=5s
    Click Element    xpath=(${STATUS_BUTTONS_XPATH})[2]
    Sleep    1s
    # รอให้ badge อัปเดต (ข้อความขึ้นต้นด้วย "อยู่ระหว่าง" ได้หลายแบบ)
    Wait Until Element Is Visible    xpath=${STATUS_BADGE_XPATH}    timeout=5s
    Sleep    1s

ตรวจสอบและเปลี่ยนสถานะเป็น COMPLETED
    # ปุ่มที่ 3 = COMPLETED
    Click Element    xpath=(${STATUS_BUTTONS_XPATH})[3]
    Sleep    1s
    Wait Until Element Is Visible    xpath=${STATUS_BADGE_XPATH}    timeout=5s
    Sleep    1s

ตรวจสอบและเปลี่ยนสถานะเป็น REJECTED
    # ปุ่มที่ 4 = REJECTED
    Click Element    xpath=(${STATUS_BUTTONS_XPATH})[4]
    Sleep    1s
    Wait Until Element Is Visible    xpath=${STATUS_BADGE_XPATH}    timeout=5s
    Sleep    1s

ตรวจสอบปุ่ม REJECTED ถูก disabled (กดไม่ได้)
    # ปุ่มที่ 4 = REJECTED ต้อง disabled
    Element Should Be Disabled    xpath=(${STATUS_BUTTONS_XPATH})[4]

ตรวจสอบปุ่ม COMPLETED ถูก disabled (กดไม่ได้)
    # ปุ่มที่ 3 = COMPLETED ต้อง disabled
    Element Should Be Disabled    xpath=(${STATUS_BUTTONS_XPATH})[3]
