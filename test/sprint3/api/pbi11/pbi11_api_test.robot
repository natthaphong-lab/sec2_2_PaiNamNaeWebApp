*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           Process
Library           OperatingSystem
Suite Setup       Setup PBI11 Test Context
Suite Teardown    Teardown PBI11 Test Data

*** Variables ***
${BASE_URL}          http://localhost:3000/api
${ADMIN_USERNAME}    admin123
${ADMIN_PASSWORD}    123456789
${BACKEND_CWD}       ${CURDIR}/../../../../code/backend
${SETUP_SCRIPT}      ${BACKEND_CWD}/scripts/pbi11_setup.js
${TEARDOWN_SCRIPT}   ${BACKEND_CWD}/scripts/pbi11_teardown.js

*** Test Cases ***
# ---------------------------------------------------------------------------
# Part 1 — Create Report (POST /api/reports) — Driver reports incident
# ---------------------------------------------------------------------------

TC001 - Driver Creates Incident Report Successfully
    [Documentation]    Happy path: driverA reports passengerA (passengerBehavior)
    ...    using a valid booking on driverA's own route.
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${PASSENGER_A_ID}
    ...    category=passengerBehavior
    ...    types=["disruptive","rude"]
    ...    description=Robot Framework PBI11 - passenger behavior report
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}
    Status Should Be    201    ${resp}
    Should Be True      ${resp.json()['success']}
    Should Be Equal As Strings    ${resp.json()['data']['status']}           PENDING
    Should Be Equal As Strings    ${resp.json()['data']['category']}         passengerBehavior
    Should Be Equal As Strings    ${resp.json()['data']['reporterRole']}     DRIVER
    Should Be Equal As Strings    ${resp.json()['data']['bookingId']}        ${BOOKING_A_ID}
    Should Be Equal As Strings    ${resp.json()['data']['reportedUserId']}   ${PASSENGER_A_ID}
    Set Suite Variable    ${CREATED_REPORT_ID}    ${resp.json()['data']['id']}

TC002 - Create Report Without Auth Token Returns 401
    [Documentation]    Request with no Authorization header must be rejected.
    ${resp}=    POST    url=${BASE_URL}/reports    expected_status=401

TC003 - Driver Uses Booking Not On Own Route Returns 400
    [Documentation]    driverA tries to use bookingC which belongs to driverB's route.
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_C_ID}
    ...    reportedUserId=${PASSENGER_A_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400
    Should Contain    ${resp.json()['message']}    Booking route does not belong to this driver

TC004 - Driver Reports Wrong Passenger Returns 400
    [Documentation]    driverA uses bookingA (passenger=passengerA) but reports passengerB.
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${PASSENGER_B_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400
    Should Contain    ${resp.json()['message']}    Reported user must be the booking passenger

TC005 - Driver Reports Self Returns 400
    [Documentation]    A driver cannot report themselves. The role-specific participant
    ...    check fires before the self-report guard, so the API returns
    ...    "Reported user must be the booking passenger" (driverA != passengerA).
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400
    Should Contain    ${resp.json()['message']}    Reported user must be the booking passenger

TC006 - Admin Role Cannot Create Report Returns 403
    [Documentation]    Only PASSENGER and DRIVER roles may create reports.
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${body}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${PASSENGER_A_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    json=${body}    expected_status=403
    Should Contain    ${resp.json()['message']}    Only passengers and drivers can create reports

TC007 - Create Report With Non-existent Booking Returns 404
    [Documentation]    A syntactically valid CUID that does not exist in DB.
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=cmlpxzy4f0002dkc6ub2pxzzz
    ...    reportedUserId=${PASSENGER_A_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 404]

TC008 - Create Report With Invalid Category Returns 400
    [Documentation]    Sending a category value that does not exist in the enum.
    ${headers}=    Create Driver A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${PASSENGER_A_ID}
    ...    category=invalidCategory
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400

# ---------------------------------------------------------------------------
# Part 2 — Read My Reports (GET /api/reports/me  &  GET /api/reports/:id)
# ---------------------------------------------------------------------------

TC009 - Driver Gets Own Reports
    [Documentation]    GET /reports/me must return only reports created by driverA.
    ${headers}=    Create Driver A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/me    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=    Set Variable    ${resp.json()['data']}
    ${ids}=        Evaluate    [r['id'] for r in ${reports}]
    Should Contain    ${ids}    ${CREATED_REPORT_ID}
    ${foreign}=    Evaluate    [r for r in ${reports} if r['reporterId'] != '${DRIVER_A_ID}']
    Length Should Be    ${foreign}    0

TC010 - Driver Gets Own Report By ID
    [Documentation]    The reporter can fetch the full report by its ID.
    ${headers}=    Create Driver A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/${CREATED_REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['id']}    ${CREATED_REPORT_ID}

TC011 - Another Driver Gets Report By ID Returns 404
    [Documentation]    driverB must not see driverA's report — ownership isolation.
    ${headers}=    Create Driver B Headers
    ${resp}=       GET    url=${BASE_URL}/reports/${CREATED_REPORT_ID}    headers=${headers}    expected_status=404

# ---------------------------------------------------------------------------
# Part 3 — Notification after report submission
# ---------------------------------------------------------------------------

TC012 - Notification REPORT_CREATED Exists After Report Submit
    [Documentation]    System creates a REPORT notification (kind=REPORT_CREATED) for
    ...    the driver immediately after the report is created (TC001).
    ${headers}=    Create Driver A Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp}=       GET    url=${BASE_URL}/notifications    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}
    ${notifs}=     Set Variable    ${resp.json()['data']}
    ${found}=      Evaluate
    ...    [n for n in ${notifs} if n.get('metadata', {}).get('kind') == 'REPORT_CREATED' and n.get('metadata', {}).get('reportId') == '${CREATED_REPORT_ID}']
    Should Be True    len(${found}) > 0

# ---------------------------------------------------------------------------
# Part 4 — Admin updates status & driver is notified
# ---------------------------------------------------------------------------

TC013 - Admin Updates Report Group Status To ON_PROGRESS
    [Documentation]    Admin changes the routeId+category group to ON_PROGRESS.
    ...    Uses the pre-created report (category=passengerBehavior) from suite setup.
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary
    ...    status=ON_PROGRESS
    ...    notificationBody=ทีมงานกำลังตรวจสอบรายงานของคุณ
    ${resp}=       PATCH
    ...    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/passengerBehavior/status
    ...    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be True    ${resp.json()['success']}
    Should Be True    ${resp.json()['data']['updated']} > 0

TC014 - Driver Receives REPORT_STATUS_UPDATED Notification
    [Documentation]    After TC013, driverA must have a REPORT_STATUS_UPDATED
    ...    notification with status=ON_PROGRESS.
    ${headers}=    Create Driver A Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp}=       GET    url=${BASE_URL}/notifications    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}
    ${notifs}=     Set Variable    ${resp.json()['data']}
    ${found}=      Evaluate
    ...    [n for n in ${notifs} if n.get('metadata', {}).get('kind') == 'REPORT_STATUS_UPDATED' and n.get('metadata', {}).get('status') == 'ON_PROGRESS']
    Should Be True    len(${found}) > 0
    Set Suite Variable    ${UPDATE_NOTIF_ID}    ${found[0]['id']}

TC015 - Driver Sees Updated Status In Own Reports
    [Documentation]    After admin update, GET /reports/me should reflect the new status.
    ${headers}=    Create Driver A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/me    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=    Set Variable    ${resp.json()['data']}
    ${matching}=   Evaluate
    ...    [r for r in ${reports} if r['id'] == '${PRE_REPORT_ID}']
    Should Be True    len(${matching}) > 0
    Should Be Equal As Strings    ${matching[0]['status']}    ON_PROGRESS

TC016 - Driver Marks Status Update Notification As Read
    [Documentation]    PATCH /notifications/:id/read sets readAt and decreases unread count.
    ${headers}=         Create Driver A Headers
    ${resp_before}=     GET    url=${BASE_URL}/notifications/unread-count    headers=${headers}
    ${count_before}=    Set Variable    ${resp_before.json()['data']['unread']}
    ${resp}=            PATCH    url=${BASE_URL}/notifications/${UPDATE_NOTIF_ID}/read    headers=${headers}
    Status Should Be    200    ${resp}
    Should Not Be Equal    ${resp.json()['data']['readAt']}    ${None}
    ${resp_after}=      GET    url=${BASE_URL}/notifications/unread-count    headers=${headers}
    ${count_after}=     Set Variable    ${resp_after.json()['data']['unread']}
    Should Be True    ${count_after} < ${count_before}

# ---------------------------------------------------------------------------
# Part 5 — Authorization boundary checks
# ---------------------------------------------------------------------------

TC017 - Non-Admin Cannot Access Admin Report List Returns 403
    [Documentation]    A driver token must receive 403 on admin-only endpoints.
    ${headers}=    Create Driver A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    expected_status=403

TC018 - Admin Updates Report Group With Invalid Status Value
    [Documentation]    Sending an unrecognised status enum value must fail.
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=INVALID_STATUS
    ${resp}=       PATCH
    ...    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/passengerBehavior/status
    ...    json=${body}    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 422, 500]

*** Keywords ***
# ---------------------------------------------------------------------------
# Suite lifecycle
# ---------------------------------------------------------------------------

Setup PBI11 Test Context
    Login As Admin
    Run PBI11 Setup Script

Teardown PBI11 Test Data
    Run Keyword And Ignore Error    Run PBI11 Teardown Script

# ---------------------------------------------------------------------------
# Script runners
# ---------------------------------------------------------------------------

Run PBI11 Setup Script
    File Should Exist    ${SETUP_SCRIPT}
    ${result}=    Run Process
    ...    node    --no-warnings    ${SETUP_SCRIPT}
    ...    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    Should Be Equal As Integers    ${result.rc}    0    Setup script failed:\n${result.stderr}
    ${data}=    Evaluate    json.loads("""${result.stdout.strip()}""")    json
    Set Suite Variable    ${DRIVER_A_ID}            ${data['driverAId']}
    Set Suite Variable    ${DRIVER_A_USERNAME}      ${data['driverAUsername']}
    Set Suite Variable    ${DRIVER_A_PASSWORD}      ${data['driverAPassword']}
    Set Suite Variable    ${DRIVER_B_ID}            ${data['driverBId']}
    Set Suite Variable    ${DRIVER_B_USERNAME}      ${data['driverBUsername']}
    Set Suite Variable    ${DRIVER_B_PASSWORD}      ${data['driverBPassword']}
    Set Suite Variable    ${PASSENGER_A_ID}         ${data['passengerAId']}
    Set Suite Variable    ${PASSENGER_B_ID}         ${data['passengerBId']}
    Set Suite Variable    ${ROUTE_ID}               ${data['routeId']}
    Set Suite Variable    ${BOOKING_A_ID}           ${data['bookingAId']}
    Set Suite Variable    ${BOOKING_B_ID}           ${data['bookingBId']}
    Set Suite Variable    ${BOOKING_C_ID}           ${data['bookingCId']}
    Set Suite Variable    ${PRE_REPORT_ID}          ${data['preReportId']}
    Set Suite Variable    ${CREATED_REPORT_ID}      ${EMPTY}
    Set Suite Variable    ${UPDATE_NOTIF_ID}        ${EMPTY}
    Login As Driver A
    Login As Driver B

Run PBI11 Teardown Script
    File Should Exist    ${TEARDOWN_SCRIPT}
    ${da}=    Get Variable Value    ${DRIVER_A_ID}       ${EMPTY}
    ${db}=    Get Variable Value    ${DRIVER_B_ID}       ${EMPTY}
    ${pa}=    Get Variable Value    ${PASSENGER_A_ID}    ${EMPTY}
    ${pb}=    Get Variable Value    ${PASSENGER_B_ID}    ${EMPTY}
    ${result}=    Run Process
    ...    node    --no-warnings    ${TEARDOWN_SCRIPT}
    ...    --driverAId       ${da}
    ...    --driverBId       ${db}
    ...    --passengerAId    ${pa}
    ...    --passengerBId    ${pb}
    ...    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE

# ---------------------------------------------------------------------------
# Login helpers
# ---------------------------------------------------------------------------

Login As Admin
    &{payload}=    Create Dictionary    username=${ADMIN_USERNAME}    password=${ADMIN_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${ADMIN_TOKEN}    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${ADMIN_ID}       ${resp.json()['data']['user']['id']}

Login As Driver A
    &{payload}=    Create Dictionary    username=${DRIVER_A_USERNAME}    password=${DRIVER_A_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${DRIVER_A_TOKEN}    Bearer ${resp.json()['data']['token']}

Login As Driver B
    &{payload}=    Create Dictionary    username=${DRIVER_B_USERNAME}    password=${DRIVER_B_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${DRIVER_B_TOKEN}    Bearer ${resp.json()['data']['token']}

# ---------------------------------------------------------------------------
# Header factories
# ---------------------------------------------------------------------------

Create Admin Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    RETURN    ${headers}

Create Admin Json Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    RETURN    ${headers}

Create Driver A Headers
    ${headers}=    Create Dictionary    Authorization=${DRIVER_A_TOKEN}
    RETURN    ${headers}

Create Driver B Headers
    ${headers}=    Create Dictionary    Authorization=${DRIVER_B_TOKEN}
    RETURN    ${headers}
