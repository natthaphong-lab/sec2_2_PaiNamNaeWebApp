*** Settings ***
Library           RequestsLibrary
Library           Collections

*** Variables ***
${BASE_URL}       http://localhost:3000/api
# --- ใส่ค่าที่คุณมีตรงนี้ ---
${ADMIN_TOKEN}    Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjbWxrbGFvcnAwMDAwNmQ4bG9lMHMyNW8yIiwicm9sZSI6IkFETUlOIiwiaWF0IjoxNzcxMjYwMDkzLCJleHAiOjE3NzEyNjM2OTN9.519JyS7yXEjDnzmr6EklH4pjeGbbqaTs_4k4-sxQThU
${REPORT_ID}      cmlpg76qy001ldkc6pxjc14l1

*** Test Cases ***
TC001 - Get All Reports
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}
    Status Should Be    200    ${resp}

TC002 - Filter Reports by Status
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${params}=     Create Dictionary    status=PENDING
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    params=${params}
    Status Should Be    200    ${resp}

TC003 - Get Report Detail by ID
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${resp}=       GET    url=${BASE_URL}/reports/admin/${REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}

TC004 - Get Report Detail with Non-existent ID
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${fake_id}=    Set Variable    cmlpxzy4f0002dkc6ub2pxzzz 
    ${resp}=       GET    url=${BASE_URL}/reports/admin/${fake_id}    headers=${headers}    expected_status=any
    
    # เช็กว่าเป็น 404 จริงไหม
    Status Should Be    404    ${resp}
    
    # เช็ก Message (ใช้ Run Keyword And Ignore Error เผื่อระบบไม่คืน JSON)
    ${status}    ${value}=    Run Keyword And Ignore Error    Set Variable    ${resp.json()['message']}
    IF    '${status}' == 'PASS'
        Should Be Equal As Strings    ${value}    Report not found
    END

TC005 - Update Status to APPROVED
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    ${body}=       Create Dictionary    status=APPROVED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}

TC006 - Update Status to REJECTED
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    ${body}=       Create Dictionary    status=REJECTED
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}

TC007 - Update Status with Invalid Value
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}    Content-Type=application/json
    ${body}=       Create Dictionary    status=WAITING
    ${resp}=       PATCH    url=${BASE_URL}/reports/admin/${REPORT_ID}/status    json=${body}    headers=${headers}    expected_status=400

TC008 - Access Admin API Without Token
    # ไม่ใส่ Headers เลย
    ${resp}=       GET    url=${BASE_URL}/reports/admin    expected_status=401

TC009 - Access Admin API With User Token
    [Documentation]    ทดสอบว่า User ธรรมดาเข้า Admin ไม่ได้
    # ถ้ายังไม่มี Token ของ User จริงๆ ให้ใช้ Token มั่วๆ ที่ยาวพอจะเป็น JWT เพื่อเช็ก 401/403
    ${headers}=    Create Dictionary    Authorization=Bearer cmlpcj4ab0000jmcthy7bi0gy
    ${resp}=       GET    url=${BASE_URL}/reports/admin    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [401, 403]

TC010 - Delete Report by ID
    [Documentation]    ลบ Report และเช็ก Message
    ${headers}=    Create Dictionary    Authorization=${ADMIN_TOKEN}
    ${resp}=       DELETE    url=${BASE_URL}/reports/admin/${REPORT_ID}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['message']}    Report deleted successfully