*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           Process
Library           OperatingSystem
Suite Setup       Setup PBI13 Test Context
Suite Teardown    Teardown PBI13 Test Data

*** Variables ***
${BASE_URL}          http://localhost:3000/api
${ADMIN_USERNAME}    admin123
${ADMIN_PASSWORD}    123456789
${BACKEND_CWD}       ${CURDIR}/../../../../code/backend
${SETUP_SCRIPT}      ${BACKEND_CWD}/scripts/pbi13_setup.js
${TEARDOWN_SCRIPT}   ${BACKEND_CWD}/scripts/pbi13_teardown.js

*** Test Cases ***
# ---------------------------------------------------------------------------
# Part 1 — Create Report (POST /api/reports)
# ---------------------------------------------------------------------------

TC001 - Passenger Creates Driver Behavior Report Successfully
    [Documentation]    Happy path: passengerA reports driverA using a valid booking.
    ...    Verifies 201, correct fields in response, and captures the new report ID
    ...    for use in later test cases.
    ${headers}=    Create Passenger A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=driverBehavior
    ...    types=["rude","speeding"]
    ...    description=Robot Framework PBI13 - driver behavior report
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}
    Status Should Be    201    ${resp}
    Should Be True      ${resp.json()['success']}
    Should Be Equal As Strings    ${resp.json()['data']['status']}           PENDING
    Should Be Equal As Strings    ${resp.json()['data']['category']}         driverBehavior
    Should Be Equal As Strings    ${resp.json()['data']['reporterRole']}     PASSENGER
    Should Be Equal As Strings    ${resp.json()['data']['bookingId']}        ${BOOKING_A_ID}
    Should Be Equal As Strings    ${resp.json()['data']['reportedUserId']}   ${DRIVER_A_ID}
    Set Suite Variable    ${CREATED_REPORT_ID}    ${resp.json()['data']['id']}

TC002 - Create Report Without Auth Token Returns 401
    [Documentation]    Request with no Authorization header must be rejected with 401.
    ${resp}=    POST    url=${BASE_URL}/reports    expected_status=401

TC003 - Create Report Booking Belongs To Another Passenger Returns 400
    [Documentation]    passengerA cannot use bookingB which belongs to passengerB.
    ${headers}=    Create Passenger A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_B_ID}
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=driverBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400
    Should Contain    ${resp.json()['message']}    Booking does not belong to this passenger

TC004 - Create Report Reported User Not Booking Driver Returns 400
    [Documentation]    driverB is not the driver of bookingA (driverA is). Must return 400.
    ${headers}=    Create Passenger A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${DRIVER_B_ID}
    ...    category=driverBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400
    Should Contain    ${resp.json()['message']}    Reported user must be the booking driver

TC005 - Admin Role Cannot Create Report Returns 403
    [Documentation]    Only PASSENGER and DRIVER roles may create reports.
    ...    Admin token must receive 403 from the role guard in the controller.
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${body}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=driverBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    json=${body}    expected_status=403
    Should Contain    ${resp.json()['message']}    Only passengers and drivers can create reports

TC006 - Create Report With Non-existent Booking Returns 404
    [Documentation]    A syntactically valid CUID that does not exist in DB returns 404.
    ${headers}=    Create Passenger A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=cmlpxzy4f0002dkc6ub2pxzzz
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=driverBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 404]

TC007 - Create Report With Driver-Only Category Returns 400
    [Documentation]    'passengerBehavior' is only allowed for DRIVER reporters.
    ...    Passenger sending it must receive 400 from the service-level category guard.
    ${headers}=    Create Passenger A Headers
    ${files}=      Evaluate    {'_dummy': ('', b'')}
    ${data}=       Create Dictionary
    ...    bookingId=${BOOKING_A_ID}
    ...    reportedUserId=${DRIVER_A_ID}
    ...    category=passengerBehavior
    ${resp}=       POST    url=${BASE_URL}/reports    headers=${headers}    files=${files}    data=${data}    expected_status=400

# ---------------------------------------------------------------------------
# Part 2 — Read My Reports (GET /api/reports/me  &  GET /api/reports/:id)
# ---------------------------------------------------------------------------

TC008 - Get My Reports Returns Only Own Reports
    [Documentation]    GET /reports/me must list reports where reporterId equals the caller.
    ...    TC001's report must be present; no foreign reports may appear.
    ${headers}=    Create Passenger A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/me    headers=${headers}
    Status Should Be    200    ${resp}
    ${reports}=    Set Variable    ${resp.json()['data']}
    ${ids}=        Evaluate    [r['id'] for r in ${reports}]
    Should Contain    ${ids}    ${CREATED_REPORT_ID}
    ${foreign}=    Evaluate    [r for r in ${reports} if r['reporterId'] != '${PASSENGER_A_ID}']
    Length Should Be    ${foreign}    0

TC009 - Get Own Report By ID Returns Report Data
    [Documentation]    The reporter can retrieve the full report by its ID.
    ${headers}=    Create Passenger A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/${CREATED_REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['id']}    ${CREATED_REPORT_ID}

TC010 - Get Another Users Report By ID Returns 404
    [Documentation]    passengerB must not see passengerA's report — ownership isolation.
    ${headers}=    Create Passenger B Headers
    ${resp}=       GET    url=${BASE_URL}/reports/${CREATED_REPORT_ID}    headers=${headers}    expected_status=404

# ---------------------------------------------------------------------------
# Part 3 — Notification after report submission
# ---------------------------------------------------------------------------

TC011 - Notification REPORT_CREATED Exists After Report Submit
    [Documentation]    System creates a REPORT notification (kind=REPORT_CREATED) for the
    ...    reporter immediately after the report is created (TC001).
    ${headers}=    Create Passenger A Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp}=       GET    url=${BASE_URL}/notifications    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}
    ${notifs}=     Set Variable    ${resp.json()['data']}
    ${found}=      Evaluate
    ...    [n for n in ${notifs} if n.get('metadata', {}).get('kind') == 'REPORT_CREATED' and n.get('metadata', {}).get('reportId') == '${CREATED_REPORT_ID}']
    Should Be True    len(${found}) > 0

# ---------------------------------------------------------------------------
# Part 4 — Admin updates status & passenger is notified
# ---------------------------------------------------------------------------

TC012 - Admin Updates Report Group Status To ON_PROGRESS
    [Documentation]    Admin changes the whole routeId+category group to ON_PROGRESS.
    ...    Uses the pre-created report (category=driverBehavior) from suite setup.
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary
    ...    status=ON_PROGRESS
    ...    notificationBody=ทีมงานกำลังตรวจสอบรายงานของคุณ
    ${resp}=       PATCH
    ...    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/driverBehavior/status
    ...    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be True    ${resp.json()['success']}
    Should Be True    ${resp.json()['data']['updated']} > 0

TC013 - Passenger Receives REPORT_STATUS_UPDATED Notification
    [Documentation]    After TC012, passengerA must have a REPORT_STATUS_UPDATED
    ...    notification with status=ON_PROGRESS. Captures the notification ID
    ...    for TC014.
    ${headers}=    Create Passenger A Headers
    ${params}=     Create Dictionary    type=REPORT
    ${resp}=       GET    url=${BASE_URL}/notifications    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}
    ${notifs}=     Set Variable    ${resp.json()['data']}
    ${found}=      Evaluate
    ...    [n for n in ${notifs} if n.get('metadata', {}).get('kind') == 'REPORT_STATUS_UPDATED' and n.get('metadata', {}).get('status') == 'ON_PROGRESS']
    Should Be True    len(${found}) > 0
    Set Suite Variable    ${UPDATE_NOTIF_ID}    ${found[0]['id']}

TC014 - Passenger Marks Status Update Notification As Read
    [Documentation]    PATCH /notifications/:id/read sets readAt and decreases unread count.
    ${headers}=         Create Passenger A Headers
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

TC015 - Non-Admin Cannot Access Admin Report List Returns 403
    [Documentation]    A passenger token must receive 403 on any admin-only endpoint.
    ${headers}=    Create Passenger A Headers
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    expected_status=403

TC016 - Admin Updates Report Group With Invalid Status Value
    [Documentation]    Sending an unrecognised status enum value must not succeed (400/422/500).
    ${headers}=    Create Admin Json Headers
    ${body}=       Create Dictionary    status=INVALID_STATUS
    ${resp}=       PATCH
    ...    url=${BASE_URL}/reports/admin/group/${ROUTE_ID}/driverBehavior/status
    ...    json=${body}    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 422, 500]

*** Keywords ***
# ---------------------------------------------------------------------------
# Suite lifecycle
# ---------------------------------------------------------------------------

Setup PBI13 Test Context
    Login As Admin
    Run PBI13 Setup Script

Teardown PBI13 Test Data
    Run Keyword And Ignore Error    Run PBI13 Teardown Script

# ---------------------------------------------------------------------------
# Script runners
# ---------------------------------------------------------------------------

Run PBI13 Setup Script
    File Should Exist    ${SETUP_SCRIPT}
    ${result}=    Run Process
    ...    node    --no-warnings    ${SETUP_SCRIPT}
    ...    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    Should Be Equal As Integers    ${result.rc}    0    Setup script failed:\n${result.stderr}
    ${data}=    Evaluate    json.loads("""${result.stdout.strip()}""")    json
    Set Suite Variable    ${PASSENGER_A_ID}         ${data['passengerAId']}
    Set Suite Variable    ${PASSENGER_A_USERNAME}   ${data['passengerAUsername']}
    Set Suite Variable    ${PASSENGER_A_PASSWORD}   ${data['passengerAPassword']}
    Set Suite Variable    ${PASSENGER_B_ID}         ${data['passengerBId']}
    Set Suite Variable    ${PASSENGER_B_USERNAME}   ${data['passengerBUsername']}
    Set Suite Variable    ${PASSENGER_B_PASSWORD}   ${data['passengerBPassword']}
    Set Suite Variable    ${DRIVER_A_ID}            ${data['driverAId']}
    Set Suite Variable    ${DRIVER_B_ID}            ${data['driverBId']}
    Set Suite Variable    ${ROUTE_ID}               ${data['routeId']}
    Set Suite Variable    ${BOOKING_A_ID}           ${data['bookingAId']}
    Set Suite Variable    ${BOOKING_B_ID}           ${data['bookingBId']}
    Set Suite Variable    ${PRE_REPORT_ID}          ${data['preReportId']}
    # Pre-init variables that are populated by later test cases
    Set Suite Variable    ${CREATED_REPORT_ID}      ${EMPTY}
    Set Suite Variable    ${UPDATE_NOTIF_ID}        ${EMPTY}
    Login As Passenger A
    Login As Passenger B

Run PBI13 Teardown Script
    File Should Exist    ${TEARDOWN_SCRIPT}
    ${pa}=    Get Variable Value    ${PASSENGER_A_ID}    ${EMPTY}
    ${pb}=    Get Variable Value    ${PASSENGER_B_ID}    ${EMPTY}
    ${da}=    Get Variable Value    ${DRIVER_A_ID}       ${EMPTY}
    ${db}=    Get Variable Value    ${DRIVER_B_ID}       ${EMPTY}
    ${result}=    Run Process
    ...    node    --no-warnings    ${TEARDOWN_SCRIPT}
    ...    --passengerAId    ${pa}
    ...    --passengerBId    ${pb}
    ...    --driverAId       ${da}
    ...    --driverBId       ${db}
    ...    cwd=${BACKEND_CWD}    stdout=PIPE    stderr=PIPE
    # Teardown should never break the suite; best-effort cleanup.

# ---------------------------------------------------------------------------
# Login helpers
# ---------------------------------------------------------------------------

Login As Admin
    &{payload}=    Create Dictionary    username=${ADMIN_USERNAME}    password=${ADMIN_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${ADMIN_TOKEN}    Bearer ${resp.json()['data']['token']}
    Set Suite Variable    ${ADMIN_ID}       ${resp.json()['data']['user']['id']}

Login As Passenger A
    &{payload}=    Create Dictionary    username=${PASSENGER_A_USERNAME}    password=${PASSENGER_A_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${PASSENGER_A_TOKEN}    Bearer ${resp.json()['data']['token']}

Login As Passenger B
    &{payload}=    Create Dictionary    username=${PASSENGER_B_USERNAME}    password=${PASSENGER_B_PASSWORD}
    ${resp}=       POST    url=${BASE_URL}/auth/login    json=${payload}
    Status Should Be    200    ${resp}
    Set Suite Variable    ${PASSENGER_B_TOKEN}    Bearer ${resp.json()['data']['token']}

# ---------------------------------------------------------------------------
# Header factories
# ---------------------------------------------------------------------------

Create Admin Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    RETURN    ${headers}

Create Admin Json Headers
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    RETURN    ${headers}

Create Passenger A Headers
    ${headers}=    Create Dictionary    Authorization=${PASSENGER_A_TOKEN}
    RETURN    ${headers}

Create Passenger B Headers
    ${headers}=    Create Dictionary    Authorization=${PASSENGER_B_TOKEN}
    RETURN    ${headers}
