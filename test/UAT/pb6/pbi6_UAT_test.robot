*** Settings ***
Library    SeleniumLibrary

*** Variables ***
${URL}             http://localhost:3001
${BROWSER}         Chrome
${ADMIN_USER}      admin123
${ADMIN_PASS}      123456789

*** Test Cases ***
TC001
    I open the login page
    I login with valid credentials
    Sleep    3s

    Wait Until Element Is Visible    xpath=//*[@id="__nuxt"]/div/div[1]/header/div/div[1]/nav/div[4]    timeout=10s
    Mouse Over    xpath=//*[@id="__nuxt"]/div/div[1]/header/div/div[1]/nav/div[4]
    Wait Until Element Is Visible    xpath=//*[@id="__nuxt"]/div/div[1]/header/div/div[1]/nav/div[4]/div[2]/a[2]    timeout=5s

    Click Element    xpath=//*[@id="__nuxt"]/div/div[1]/header/div/div[1]/nav/div[4]/div[2]/a[2]
    Wait Until Location Contains    ${URL}/admin/users    timeout=5s

    Click Element    xpath=//*[@id="sidebar"]/div/nav/a[6]
    Wait Until Location Contains    ${URL}/admin/reports    timeout=5s
    Location Should Be    ${URL}/admin/reports

TC002
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]    timeout=10s
    Click Element    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]
    Wait Until Page Contains    รายละเอียดการรายงานผู้ขับขี่    timeout=10s
    Page Should Contain    รายละเอียดการรายงานผู้ขับขี่

    Click Element    xpath=//*[@id="main-content"]/div[1]/a
    Wait Until Location Contains    ${URL}/admin/reports    timeout=10s
    Sleep    1s
    Location Should Be    ${URL}/admin/reports

TC003
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]    timeout=10s
    Click Element    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]
    Wait Until Page Contains    รายละเอียดการรายงานผู้ขับขี่    timeout=10s
    Page Should Contain    รายละเอียดการรายงานผู้ขับขี่

    Click Element    xpath=//*[@id="main-content"]/div[2]/div[2]/div/div[2]/button[2]
    Wait Until Element Contains    xpath=//*[@id="main-content"]/div[2]/div[2]/div/span    approved    timeout=10s
    Element Should Contain    xpath=//*[@id="main-content"]/div[2]/div[2]/div/span    approved

    Click Element    xpath=//*[@id="main-content"]/div[1]/a
    Wait Until Location Contains    ${URL}/admin/reports    timeout=10s
    Location Should Be    ${URL}/admin/reports

TC004
    Wait Until Element Is Visible    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]    timeout=10s
    Click Element    xpath=//*[@id="main-content"]/div/div[3]/div[2]/table/tbody/tr/td[6]/div/button[1]
    Wait Until Page Contains    รายละเอียดการรายงานผู้ขับขี่    timeout=10s
    Page Should Contain    รายละเอียดการรายงานผู้ขับขี่

    Click Element    xpath=//*[@id="main-content"]/div[2]/div[2]/div/div[2]/button[3]
    Wait Until Element Contains    xpath=//*[@id="main-content"]/div[2]/div[2]/div/span    rejected    timeout=10s
    Element Should Contain    xpath=//*[@id="main-content"]/div[2]/div[2]/div/span    rejected






*** Keywords ***
I open the login page
    Open Browser    ${URL}/login    ${BROWSER}
    Maximize Browser Window

I login with valid credentials
    Input Text      xpath=//*[@id="identifier"]       ${ADMIN_USER}
    Input Password  xpath=//*[@id="password"]    ${ADMIN_PASS}
    Click Button    xpath=//*[@id="loginForm"]/button