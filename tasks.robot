*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Windows
Library    RPA.RobotLogListener
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Variables ***
${img_folder}     ${OUTPUT_DIR}${/}PNG_Files
${pdf_folder}     ${OUTPUT_DIR}${/}PDF_Files
${output_folder}    ${OUTPUT_DIR}
${zip_file}    ${output_folder}${/}PDF_Archives.zip    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    Open the robot order website
    ${orders}=    Get orders
    Open Order Robot Webpage
    Complete orders for all people
    Zip PDF Files

*** Keywords ***

Directory Cleanup
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}

Open the robot order website
    Open Available Browser    url=https://robotsparebinindustries.com

Get orders 
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True  
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Log    ${order}
    END
    RETURN    ${orders}

Open Order Robot Webpage
    Click Link    alias:Orderyourrobot1

Close the annoying modal
    Click Button When Visible    css:.btn-dark

Fill and submit the form for one person
    [Arguments]    ${orders}
    Close the annoying modal
    Select From List By Index    //*[@id="head"]    ${orders}[Head]
    Select Radio Button     body     ${orders}[Body]
    Input Text    class:form-control     ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Sleep    1s
    Press Keys    ${None}    TAB   
    Press Keys    ${None}    ENTER
    Wait Until Page Contains Element    id:robot-preview-image
    Sleep    1s

Save screenshot of robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    ${img_folder}${/}robot${order}.png 

Error Check
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"] 
        Run Keyword If  '${alert}'=='True'  Wait and Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END

Save receipt as PDF
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_folder}${/}receipt${order}.pdf    

Embed image in PDF
    [Arguments]    ${pdf_file}    ${screenshot_file}
    Open Pdf    ${pdf_file}
    @{myfiles}=    Create List    ${screenshot_file}:x=0,y=0
    Add Files To Pdf    ${myfiles}    ${pdf_file}    ${True}
    Close Pdf    ${pdf_file}

Order another robot
    Sleep    1s
    Wait And Click Button  //button[@id="order-another"]

Complete orders for all people
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Fill and submit the form for one person    ${order}
        ${screenshot}=    Save screenshot of robot    ${order}[Order number]
        Mute Run On Failure    Page Should Contain Element 
        Wait Until Element Is Visible    id:order
        Sleep     2s 
        Click Button    id:order
        Error Check
        ${pdf}=    Save receipt as PDF    ${order}[Order number]
        Embed image in PDF    ${pdf_folder}${/}receipt${order}[Order number].pdf    ${img_folder}${/}robot${order}[Order number].png               
        Order another robot
        Sleep     2s
    END
Zip PDF Files    
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive= ${True}    include=*.pdf
