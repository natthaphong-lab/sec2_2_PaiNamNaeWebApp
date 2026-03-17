*** Settings ***
Library    SeleniumLibrary
Test Setup    Login

*** Variables ***
${URL}        https://csse2268.cpkku.com/login
${MYTRIP_URL} https://csse2268.cpkku.com/myTrip
${PROFILE_URL} https://csse2268.cpkku.com/profile
${BROWSER}    chrome
${USERNAME}   koeeyPassenger
${PASSWORD}   admin1234


*** Keywords ***
Login
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window

    Wait Until Element Is Visible    id=identifier    10s
    Input Text      id=identifier    ${USERNAME}

    Wait Until Element Is Visible    id=password      10s
    Input Password  id=password      ${PASSWORD}

    Click Element   xpath=//button[@type='submit']
    Wait Until Page Does Not Contain Element    id=identifier    10s

Go To Report Page
    Click Element    xpath=//a[contains(text(),'การเดินทางของฉัน')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'ยืนยันแล้ว')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'รายงานปัญหา')]
    Sleep    3s



*** Test Cases ***
TC001 
    Click Element    xpath=//a[contains(text(),'การเดินทางของฉัน')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'ยืนยันแล้ว')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'รายงานปัญหา')]
    Sleep    5s
    Capture Page Screenshot    TC001.png

TC002
    Go To Report Page
    Click Element    xpath=//*[@id="__nuxt"]/div/div[1]/main/div/div/button[1]
    Sleep    3s
    Click Element    xpath=//label[contains(.,'ขับรถเร็วเกินที่กฎหมายกำหนด')]
    Sleep    3s
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/video_test.mp4
    Sleep    3s
    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    Sleep    5s
    Capture Page Screenshot    TC002.png


TC003
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาอื่น ๆ']
    Sleep    3s
    Input Text    xpath=//textarea[@placeholder='อธิบายรายละเอียดเหตุการณ์']    พบซากหนูตาย
    Sleep    3s
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/money.jpg
    Sleep    3s
    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    Sleep    3s
    Handle Alert    ACCEPT
    Sleep    3s
    Capture Page Screenshot    TC003.png

TC004
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งของหาย / ของตกหล่น']
    Sleep    3s
    Click Element    xpath=//label[contains(.,'ฉันลืมของไว้บนรถ')]
    Input Text    xpath=//textarea[@placeholder='อธิบายรายละเอียดเหตุการณ์']    ลืมของไว้ในรถ
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/money.jpg
    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    Sleep    6s
    Capture Page Screenshot    TC004.png

TC005
    Go To    https://csse2268.cpkku.com/profile
    Click Element    xpath=//*[normalize-space()='ประวัติการรายงานของฉัน']
    Wait Until Page Contains    ประวัติการรายงาน    10s

    Sleep    5s
    Capture Page Screenshot    TC005.png


TC006
    Go To    https://csse2268.cpkku.com/profile
    Click Element    xpath=//*[normalize-space()='ประวัติการรายงานของฉัน']
    Wait Until Page Contains    ประวัติการรายงาน    10s
    Sleep    2s
    Click Element    xpath=//*[starts-with(@id,'report-')]
    Sleep    5s
    Page Should Contain    สถานะการดำเนินการ
    Capture Page Screenshot    TC006.png


TC007
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาเกี่ยวกับรถ']
    Sleep    1s
    Click Element    xpath=//label[contains(.,'รถสกปรก')]
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/README.md
    Sleep    2s
    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    Sleep    2s
    Handle Alert    ACCEPT
    Sleep    2s
    Page Should Contain    รองรับเฉพาะไฟล์รูปภาพ วิดีโอ หรือเสียงเท่านั้น
    Capture Page Screenshot    TC007.png

TC008
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาเกี่ยวกับรถ']
    Sleep    1s
    Click Element    xpath=//label[contains(.,'รถสกปรก')]
    Sleep    2s
    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    ${text}=    Handle Alert
    Should Be Equal    ${text}    กรุณาแนบสื่ออย่างน้อย 1 ไฟล์
    Capture Page Screenshot    TC008.png



TC009
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งของหาย / ของตกหล่น']
    Wait Until Element Is Visible
    ...    xpath=//span[normalize-space()='ฉันลืมของไว้บนรถ']
    ...    10s

    Click Element
    ...    xpath=//span[normalize-space()='ฉันลืมของไว้บนรถ']

    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    ${text}=    Handle Alert
    Should Be Equal    ${text}    กรุณากรอกรายละเอียดเพิ่มเติม
    # Handle Alert    ACCEPT
    Capture Page Screenshot    TC009.png

TC0010
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งของหาย / ของตกหล่น']

    Wait Until Element Is Visible
    ...    xpath=//button[normalize-space()='ยืนยัน']
    ...    10s

    Click Element    xpath=//button[normalize-space()='ยืนยัน']
    ${text}=    Handle Alert
    Should Be Equal    ${text}    กรุณาเลือกหัวข้อ
    Capture Page Screenshot    TC0010.png

TC011
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาเกี่ยวกับรถ']
    Sleep    1s
    Click Element    xpath=//label[contains(.,'รถสกปรก')]
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture1.jpg
    Sleep    1s
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture2.jpg
    Sleep    1s
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture3.jpg
    Sleep    1s
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/money.jpg
    Sleep    2s
    Page Should Contain    แนบไฟล์ได้สูงสุด 3 ไฟล์
    Capture Page Screenshot    TC0011.png

TC012
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาเกี่ยวกับรถ']
    Sleep    1s
    Click Element    xpath=//label[contains(.,'รถสกปรก')]
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/more10mb.mp4
    Sleep    2s
    Page Should Contain    ไฟล์ต้องมีขนาดไม่เกิน 10MB ต่อไฟล์
    Capture Page Screenshot    TC0012.png