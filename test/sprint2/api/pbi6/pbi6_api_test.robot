*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           Process
Library           OperatingSystem
Suite Setup       Setup Admin Context
Suite Teardown    Teardown PBI6 Test Data

*** Variables ***
${BASE_URL}       http://localhost:3000/api
${ADMIN_USERNAME}    admin123
${ADMIN_PASSWORD}    123456789
${BACKEND_CWD}    ${CURDIR}/../../../../code/backend
${PBI6_SETUP_SCRIPT}    ${BACKEND_CWD}/scripts/pbi6_setup.js
${PBI6_TEARDOWN_SCRIPT}    ${BACKEND_CWD}/scripts/pbi6_teardown.js

*** Test Cases ***
TC001 - Get All Reports
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}
    Status Should Be    200    ${resp}

TC002 - Filter Reports by Status
    ${headers}=    Create Admin Headers
    ${params}=     Create Dictionary    status=PENDING
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}

TC003 - Get Report Detail by ID
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin/${REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}

TC004 - Get Report Detail with Non-existent ID
    ${headers}=    Create Admin Headers
    ${fake_id}=    Set Variable    cmlpxzy4f0002dkc6ub2pxzzz
    ${resp}=       GET    url=${BASE_URL}/reports/admin/${fake_id}    headers=${headers}    expected_status=any
    Status Should Be    404    ${resp}
    ${status}    ${value}=    Run Keyword And Ignore Error    Set Variable    ${resp.json()['message']}
    IF    '${status}' == 'PASS'
        Should Be Equal As Strings    ${value}    Report not found
    END

TC005 - Update Status To Completed
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=COMPLETED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['status']}    COMPLETED

TC006 - Update Status To Rejected
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=REJECTED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['status']}    REJECTED

TC007 - Update Status with Invalid Value
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=WAITING
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}    expected_status=400
    ${status}    ${msg}=    Run Keyword And Ignore Error    Set Variable    ${resp.json()['message']}
    IF    '${status}' == 'PASS'
        Should Contain    ${msg}    status
    END

TC008 - Access Admin API Without Token
    ${resp}=       GET    url=${BASE_URL}/reports/admin    expected_status=401

TC009 - Access Admin API With Invalid Token
    ${headers}=    Create Dictionary    Authorization=Bearer invalid.jwt.token.value
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [401, 403]

TC010 - Notification Created After Status Update
    [Documentation]    Verify reporter receives REPORT notification after admin status update (see notification.doc.js).
    ${headers_admin}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=ON_PROGRESS
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers_admin}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['status']}    ON_PROGRESS

    Login As Reporter
    ${headers_reporter}=    Create Reporter Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp_notifs}=    GET    url=${BASE_URL}/notifications    headers=${headers_reporter}    params=${params}
    Status Should Be    200    ${resp_notifs}
    ${notifications}=    Set Variable    ${resp_notifs.json()['data']}
    ${filtered}=    Evaluate    [n for n in ${notifications} if n.get('metadata', {}).get('reportId') == '${REPORT_ID}' and n.get('metadata', {}).get('status') == 'ON_PROGRESS']
    ${count}=      Get Length    ${filtered}
    Should Be True    ${count} > 0

TC011 - Delete Report by ID
    ${headers}=    Create Admin Headers
    ${resp}=       DELETE    url=${BASE_URL}/reports/admin/${REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}

*** Keywords ***
Setup Admin Context
    Login As Admin
    Create PBI6 Test User And Report

Teardown PBI6 Test Data
    Run Keyword And Ignore Error    Delete PBI6 Test Report And User

Login As Admin
    &{payload}=    Create Dictionary    username=${ADMIN_USERNAME}    password=${ADMIN_PASSWORD}
    ${resp}=    POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    ${token}=    Set Variable    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${ADMIN_TOKEN}    ${token}
    Set Suite Variable    ${ADMIN_ID}       ${resp.json()['data']['user']['id']}

Create Admin Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    RETURN    ${headers}

Create Admin Json Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    RETURN    ${headers}

Create PBI6 Test User And Report
    File Should Exist    ${PBI6_SETUP_SCRIPT}
    ${result}=    Run Process    node    --no-warnings    ${PBI6_SETUP_SCRIPT}    --reportedUserId    ${ADMIN_ID}    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    Should Be Equal As Integers    ${result.rc}    0
    ${out}=    Evaluate    """${result.stdout}""".strip()    json
    ${data}=   Evaluate    json.loads("""${out}""")    json
    Set Suite Variable    ${TEST_USER_ID}     ${data['testUserId']}
    Set Suite Variable    ${TEST_USERNAME}    ${data['testUsername']}
    Set Suite Variable    ${TEST_PASSWORD}    ${data['testPassword']}
    Set Suite Variable    ${REPORT_ID}        ${data['reportId']}

Login As Reporter
    &{payload}=    Create Dictionary    username=${TEST_USERNAME}    password=${TEST_PASSWORD}
    ${resp}=    POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    ${token}=    Set Variable    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${REPORTER_TOKEN}    ${token}

Create Reporter Headers
    ${headers}=    Create Dictionary    Authorization=${REPORTER_TOKEN}
    RETURN    ${headers}

Delete PBI6 Test Report And User
    File Should Exist    ${PBI6_TEARDOWN_SCRIPT}
    ${result}=    Run Process    node    --no-warnings    ${PBI6_TEARDOWN_SCRIPT}    --reportId    ${REPORT_ID}    --testUserId    ${TEST_USER_ID}    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    # Teardown should never break the suite; best-effort cleanup.
