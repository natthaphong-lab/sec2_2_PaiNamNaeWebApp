*** Settings ***
Library    SeleniumLibrary
Test Setup    Login

*** Variables ***
${URL}        https://csse2268.cpkku.com/login
${MYROUTE_URL} https://csse2268.cpkku.com/myRoute
${PROFILE_URL} https://csse2268.cpkku.com/profile
${BROWSER}    chrome
${USERNAME}   koeeyDriver
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
    Go To    https://csse2268.cpkku.com/myRoute
    Sleep    2s
    Click Element    xpath=//button[contains(text(),'ยืนยันแล้ว')]
    Sleep    2s
    Click Element    xpath=//button[contains(text(),'รายงานปัญหา')]
    Sleep    2s



*** Test Cases ***
# TC001 
#     Go To Report Page
#     Capture Page Screenshot    TC001.png

# TC002
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาด้านความปลอดภัยเกี่ยวกับการขับขี่']
#     Sleep    3s
#     Click Element    xpath=//label[contains(.,'ผู้โดยสารพยายามรบกวนการขับขี่')]
#     Sleep    3s
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/driveDrink.mp4
#     Sleep    3s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Wait Until Element Is Visible
#     ...    xpath=//*[contains(text(),'สำเร็จ')]
#     ...    10s
#     Capture Page Screenshot    TC002.png

# TC002
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาด้านความปลอดภัยเกี่ยวกับการขับขี่']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'ผู้โดยสารพยายามรบกวนการขับขี่')]
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/talk.mp4
#     Sleep    2s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Sleep    5s
#     Capture Page Screenshot    TC002.png

# TC003
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งของหาย / ของตกหล่น']

#     Wait Until Element Is Visible
#     ...    xpath=//*[@id="__nuxt"]/div/div[1]/main/div/div/div[1]/div/label[1]
#     ...    10s
#     Click Element
#     ...    xpath=//*[@id="__nuxt"]/div/div[1]/main/div/div/div[1]/div/label[1]

#     Input Text    xpath=//textarea[@placeholder='อธิบายรายละเอียดเหตุการณ์']    กระเป๋าสตางค์หายระหว่างเดินทาง
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture.jpg
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Wait Until Element Is Visible
#     ...    xpath=//*[contains(text(),'สำเร็จ')]
#     ...    10s
#     Capture Page Screenshot    TC003.png

# TC004
#     Go To Report Page

#     Wait Until Element Is Visible
#     ...    xpath=//button[contains(.,'แจ้งปัญหาอื่น')]
#     ...    10s
#     Click Element    xpath=//button[contains(.,'แจ้งปัญหาอื่น')]

#     Wait Until Element Is Visible
#     ...    xpath=//textarea[@placeholder='อธิบายรายละเอียดเหตุการณ์']
#     ...    10s

#     Input Text
#     ...    xpath=//textarea[@placeholder='อธิบายรายละเอียดเหตุการณ์']
#     ...    พบซากหนูตาย

#     Choose File
#     ...    xpath=//input[@type='file']
#     ...    ${CURDIR}/files/mouse.jpg

#     Click Element    xpath=//button[normalize-space()='ยืนยัน']


#     Handle Alert    ACCEPT
#     Capture Page Screenshot    TC004.png

# TC005
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาพฤติกรรมผู้โดยสาร']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'ไม่มาตามเวลาที่ตกลงกันไว้')]
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/talk.mp4
#     Sleep    2s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Sleep    10s
#     Wait Until Element Is Visible
#     ...    xpath=//*[contains(text(),'สำเร็จ')]
#     ...    10s
#     Capture Page Screenshot    TC005.png

# TC006
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาเกี่ยวกับความเสียหายต่อรถและทรัพย์สิน']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'รถสกปรกจากผู้โดยสาร')]
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture.jpg
#     Sleep    2s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Wait Until Element Is Visible
#     ...    xpath=//*[contains(text(),'สำเร็จ')]
#     ...    10s
#     Capture Page Screenshot    TC006.png




# TC007
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาพฤติกรรมผู้โดยสาร']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'พูดจาไม่สุภาพ คุกคาม หรือ ข่มขู่')]
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/README.md
#     Sleep    2s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Sleep    2s
#     Handle Alert    ACCEPT
#     Sleep    2s
#     Page Should Contain    รองรับเฉพาะไฟล์รูปภาพ วิดีโอ หรือเสียงเท่านั้น
#     Capture Page Screenshot    TC007.png

# TC008
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาพฤติกรรมผู้โดยสาร']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'พูดจาไม่สุภาพ คุกคาม หรือ ข่มขู่')]
#     Sleep    2s
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     Sleep    3s
#     Handle Alert    ACCEPT
#     Capture Page Screenshot    TC008.png



# TC009
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งของหาย / ของตกหล่น']

#     Wait Until Element Is Visible
#     ...    xpath=//*[@id="__nuxt"]/div/div[1]/main/div/div/div[1]/div/label[1]
#     ...    10s
#     Click Element
#     ...    xpath=//*[@id="__nuxt"]/div/div[1]/main/div/div/div[1]/div/label[1]

#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture.jpg
#     Click Element    xpath=//button[normalize-space()='ยืนยัน']
#     ${text}=    Handle Alert
#     Should Be Equal    ${text}    กรุณากรอกรายละเอียดเพิ่มเติม
#     Capture Page Screenshot    TC009.png

# TC0010
#     Go To Report Page
#     Click Element    xpath=//button[contains(normalize-space(.),'แจ้งของหาย')]

#     Wait Until Page Contains Element    xpath=//button[normalize-space(.)='ยืนยัน']    10s
#     Click Element    xpath=//button[normalize-space(.)='ยืนยัน']

#     ${text}=    Handle Alert
#     Should Be Equal    ${text}    กรุณาเลือกหัวข้อ
#     Capture Page Screenshot    TC0010.png

# TC011
#     Go To Report Page
#     Click Element    xpath=//button[normalize-space()='แจ้งปัญหาพฤติกรรมผู้โดยสาร']
#     Sleep    1s
#     Click Element    xpath=//label[contains(.,'ไม่มาตามเวลาที่ตกลงกันไว้')]
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture.jpg
#     Sleep    1s
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/mouse.jpg
#     Sleep    1s
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/talk.mp4
#     Sleep    1s
#     Choose File    xpath=//input[@type='file']    ${CURDIR}/files/picture.jpg
#     Sleep    2s
#     Page Should Contain    แนบไฟล์ได้สูงสุด 3 ไฟล์
#     Capture Page Screenshot    TC011.png

TC012
    Go To Report Page
    Click Element    xpath=//button[normalize-space()='แจ้งปัญหาพฤติกรรมผู้โดยสาร']
    Sleep    1s
    Click Element    xpath=//label[contains(.,'ไม่มาตามเวลาที่ตกลงกันไว้')]
    Choose File    xpath=//input[@type='file']    ${CURDIR}/files/more10k.mp4
    Sleep    2s
    Page Should Contain    ไฟล์ต้องมีขนาดไม่เกิน 10MB ต่อไฟล์
    Capture Page Screenshot    TC0012.png
