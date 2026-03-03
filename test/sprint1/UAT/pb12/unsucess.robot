*** Settings ***
Library    SeleniumLibrary

*** Test Cases ***
UAT-002_1
    Open Browser    http://csse2268.cpkku.com/login/    chrome
    Maximize Browser Window

    # login
    Wait Until Element Is Visible    xpath=//input[@type='text']    10s
    Input Text    xpath=//input[@type='text']    keoeeyboy
    Input Text    xpath=//input[@type='password']    admin1234
    Click Button  xpath=//button[@type='submit']
    Sleep    3s

    Click Element    xpath=//a[contains(text(),'การเดินทางทั้งหมด')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'ยืนยันแล้ว')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'รายงานคนขับ')]
    Sleep    5s
    


    Wait Until Element Is Visible    xpath=//textarea    2s
    Click Element    xpath=//textarea
    Input Text       xpath=//textarea    ขับเร็วจนนึกว่าติดห้าดาว

    Wait Until Element Is Visible    xpath=//input[@type='file']    10s
    Choose File    xpath=//input[@type='file']    ${EXECDIR}${/}report.jpg

    Page Should Not Contain
    ...    ส่งรายงานสำเร็จ
    ...    10s

    Sleep    3s
    Capture Page Screenshot
    Close Browser

UAT-002_2
    Open Browser    http://csse2268.cpkku.com/login/    chrome
    Maximize Browser Window

    # login
    Wait Until Element Is Visible    xpath=//input[@type='text']    10s
    Input Text    xpath=//input[@type='text']    keoeeyboy
    Input Text    xpath=//input[@type='password']    admin1234
    Click Button  xpath=//button[@type='submit']
    Sleep    3s

    Click Element    xpath=//a[contains(text(),'การเดินทางทั้งหมด')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'ยืนยันแล้ว')]
    Sleep    3s
    Click Element    xpath=//button[contains(text(),'รายงานคนขับ')]
    Sleep    5s
    
    Click Element
    ...    xpath=//label[contains(text(),'ขับรถเร็วและประมาท')]

    Wait Until Element Is Visible    xpath=//textarea    2s
    Click Element    xpath=//textarea
    Input Text       xpath=//textarea    ขับเร็วจนนึกว่าติดห้าดาว

    Page Should Not Contain
    ...    ส่งรายงานสำเร็จ
    ...    10s

    Sleep    3s
    Capture Page Screenshot
    Close Browser


