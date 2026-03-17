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
TC001 - Get All Report Groups
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}
    Status Should Be    200    ${resp}
    ${groups}=      Set Variable    ${resp.json()['data']}
    ${matching}=    Evaluate    [g for g in ${groups} if g.get('routeId') == '${ROUTE_ID}' and g.get('category') == '${CATEGORY}']
    ${count}=       Get Length    ${matching}
    Should Be Equal As Integers    ${count}    1
    Should Be Equal As Integers    ${matching[0]['reportCount']}    2

TC002 - Filter Report Groups by Status
    ${headers}=    Create Admin Headers
    ${params}=     Create Dictionary    status=PENDING
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}
    ${groups}=      Set Variable    ${resp.json()['data']}
    ${matching}=    Evaluate    [g for g in ${groups} if g.get('routeId') == '${ROUTE_ID}' and g.get('category') == '${CATEGORY}']
    ${count}=       Get Length    ${matching}
    Should Be Equal As Integers    ${count}    1
    Should Be Equal As Strings     ${matching[0]['status']}    PENDING

TC003 - Get Report Group Detail
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=     Set Variable    ${resp.json()['data']}
    ${count}=       Get Length    ${reports}
    Should Be Equal As Integers    ${count}    2
    ${reporter_ids}=    Evaluate    sorted([r['reporter']['id'] for r in ${reports}])
    ${expected_ids}=    Evaluate    sorted(['${PASSENGER1_ID}', '${PASSENGER2_ID}'])
    Should Be Equal    ${reporter_ids}    ${expected_ids}

TC004 - Get Report Group Detail with Non-existent Group
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin/group/cmlpxzy4f0002dkc6ub2pxzzz/safety    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=     Set Variable    ${resp.json()['data']}
    ${count}=       Get Length    ${reports}
    Should Be Equal As Integers    ${count}    0

TC005 - Update Group Status To Completed
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=COMPLETED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Integers    ${resp.json()['data']['updated']}    2
    ${detail}=      GET    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}    headers=${headers}
    Status Should Be    200    ${detail}
    ${reports}=     Set Variable    ${detail.json()['data']}
    ${statuses}=    Evaluate    list(set([r['status'] for r in ${reports}]))
    ${status_count}=    Get Length    ${statuses}
    Should Be Equal As Integers    ${status_count}    1
    Should Be Equal As Strings     ${statuses[0]}    COMPLETED

TC006 - Update Group Status To Rejected
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=REJECTED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Integers    ${resp.json()['data']['updated']}    2
    ${detail}=      GET    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}    headers=${headers}
    ${reports}=     Set Variable    ${detail.json()['data']}
    ${statuses}=    Evaluate    list(set([r['status'] for r in ${reports}]))
    ${status_count}=    Get Length    ${statuses}
    Should Be Equal As Integers    ${status_count}    1
    Should Be Equal As Strings     ${statuses[0]}    REJECTED

TC007 - Update Group Status with Invalid Value
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=WAITING
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}/status    json=${body}    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 422, 500]

TC008 - Access Admin API Without Token
    ${resp}=       GET    url=${BASE_URL}/reports/admin    expected_status=401

TC009 - Access Admin API With Invalid Token
    ${headers}=    Create Dictionary    Authorization=Bearer invalid.jwt.token.value
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [401, 403]

TC010 - Notifications Created For All Reporters After Group Status Update
    [Documentation]    Verify both reporters receive REPORT notifications after admin group status update.
    ${headers_admin}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=ON_PROGRESS
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}/status    json=${body}    headers=${headers_admin}
    Status Should Be    200    ${resp}
    Should Be Equal As Integers    ${resp.json()['data']['updated']}    2

    Login As Reporter 1
    ${headers_reporter}=    Create Reporter1 Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp_notifs}=    GET    url=${BASE_URL}/notifications    headers=${headers_reporter}    params=${params}
    Status Should Be    200    ${resp_notifs}
    ${notifications}=    Set Variable    ${resp_notifs.json()['data']}
    ${filtered}=    Evaluate    [n for n in ${notifications} if n.get('metadata', {}).get('reportId') == '${REPORT1_ID}' and n.get('metadata', {}).get('status') == 'ON_PROGRESS']
    ${count}=      Get Length    ${filtered}
    Should Be True    ${count} > 0

    Login As Reporter 2
    ${headers_reporter2}=    Create Reporter2 Headers
    ${resp_notifs2}=    GET    url=${BASE_URL}/notifications    headers=${headers_reporter2}    params=${params}
    Status Should Be    200    ${resp_notifs2}
    ${notifications2}=    Set Variable    ${resp_notifs2.json()['data']}
    ${filtered2}=    Evaluate    [n for n in ${notifications2} if n.get('metadata', {}).get('reportId') == '${REPORT2_ID}' and n.get('metadata', {}).get('status') == 'ON_PROGRESS']
    ${count2}=      Get Length    ${filtered2}
    Should Be True    ${count2} > 0

TC011 - Group Detail Reflects Latest Updated Status
    ${headers}=    Create Admin Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/${CATEGORY}    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=     Set Variable    ${resp.json()['data']}
    ${statuses}=    Evaluate    list(set([r['status'] for r in ${reports}]))
    ${status_count}=    Get Length    ${statuses}
    Should Be Equal As Integers    ${status_count}    1
    Should Be Equal As Strings     ${statuses[0]}    ON_PROGRESS

*** Keywords ***
Setup Admin Context
    Login As Admin
    Create PBI6 Grouped Test Data

Teardown PBI6 Test Data
    Run Keyword And Ignore Error    Delete PBI6 Grouped Test Data

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

Create PBI6 Grouped Test Data
    File Should Exist    ${PBI6_SETUP_SCRIPT}
    ${result}=    Run Process    node    --no-warnings    ${PBI6_SETUP_SCRIPT}    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    Should Be Equal As Integers    ${result.rc}    0
    ${out}=    Evaluate    """${result.stdout}""".strip()    json
    ${data}=   Evaluate    json.loads("""${out}""")    json
    Set Suite Variable    ${PASSENGER1_ID}     ${data['passenger1Id']}
    Set Suite Variable    ${PASSENGER1_USERNAME}    ${data['passenger1Username']}
    Set Suite Variable    ${PASSENGER2_ID}     ${data['passenger2Id']}
    Set Suite Variable    ${PASSENGER2_USERNAME}    ${data['passenger2Username']}
    Set Suite Variable    ${TEST_PASSWORD}    ${data['testPassword']}
    Set Suite Variable    ${DRIVER_ID}        ${data['driverId']}
    Set Suite Variable    ${ROUTE_ID}         ${data['routeId']}
    Set Suite Variable    ${CATEGORY}         ${data['category']}
    Set Suite Variable    ${REPORT1_ID}       ${data['report1Id']}
    Set Suite Variable    ${REPORT2_ID}       ${data['report2Id']}

Login As Reporter 1
    &{payload}=    Create Dictionary    username=${PASSENGER1_USERNAME}    password=${TEST_PASSWORD}
    ${resp}=    POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    ${token}=    Set Variable    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${REPORTER1_TOKEN}    ${token}

Login As Reporter 2
    &{payload}=    Create Dictionary    username=${PASSENGER2_USERNAME}    password=${TEST_PASSWORD}
    ${resp}=    POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    ${token}=    Set Variable    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${REPORTER2_TOKEN}    ${token}

Create Reporter1 Headers
    ${headers}=    Create Dictionary    Authorization=${REPORTER1_TOKEN}
    RETURN    ${headers}

Create Reporter2 Headers
    ${headers}=    Create Dictionary    Authorization=${REPORTER2_TOKEN}
    RETURN    ${headers}

Delete PBI6 Grouped Test Data
    File Should Exist    ${PBI6_TEARDOWN_SCRIPT}
    ${result}=    Run Process    node    --no-warnings    ${PBI6_TEARDOWN_SCRIPT}    --passenger1Id    ${PASSENGER1_ID}    --passenger2Id    ${PASSENGER2_ID}    --driverId    ${DRIVER_ID}    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    # Teardown should never break the suite; best-effort cleanup.
