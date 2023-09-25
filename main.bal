import ballerina/http;

// Define a record type for Lecturer
public type Lecturer record {|
    readonly string staffNo;
    string officeNo;
    string name;
    string title;
    string[] courses;
|};

// Define a record type for Office
public type Office record {|
    readonly string officeNo;
    string name;
|};

// Define a record type for Conflict response
public type ConflictingStaffNo record {|
    *http:Conflict;
    ErrorMessage body; 
|};

// Define a record type for error messages
public type ErrorMessage record {|
    string errorMessage;
|};

// Changing the port number for the service
configurable int port = 9090;

// Define a record type for Created response
public type CreatedLecturer record {|
    *http:Created;
    Lecturer body;
|};

// Define a record type for Not Found response
public type LecturerNotFound record {|
    *http:NotFound;
    ErrorMessage body;
|};

// Define a partial Lecturer record for updates
public type LecturerPart record {|
    string officeNo;
    string name;
    string title;
    string[] courses;
|};

// Define a Ballerina service on the /FCIStaff endpoint
service /FCIStaff on new http:Listener(9090) {
    // Initialize a table for storing Lecturer records
    private table<Lecturer> key(staffNo) lecturers;

    // Initialize a table for storing Office records
    private table<Office> key(officeNo) offices;

    // Initialization function for the service
    function init() {
        self.lecturers = table [];
        self.offices = table [];
    }

    // Resource to get all the lecturers
    isolated resource function get getAllLecturers() returns Lecturer[] {
        return self.lecturers.toArray();
    }

    // Resource to add a new lecturer
    resource function post addLecturer(@http:Payload Lecturer newLecturer) returns CreatedLecturer|ConflictingStaffNo {
        // Check if a lecturer with the same staffNo already exists
        string[] existingCourseCodes = from var {staffNo} in self.lecturers
            where staffNo == newLecturer.staffNo
            select staffNo;

        if existingCourseCodes.length() > 0 {
            return <ConflictingStaffNo>{
                body: {
                    errorMessage: string `Error: a course with code ${newLecturer.staffNo} already exists`
                }
            };
        } else {
            // Add the new lecturer to the table
            self.lecturers.add(newLecturer);
            return <CreatedLecturer>{body: newLecturer};
        }
    }

    // Resource to get a lecturer by staffNo
    resource function get getLecturerByStaffNo/[string StaffNo]() returns Lecturer|LecturerNotFound {
        Lecturer? theCourse = self.lecturers[StaffNo];
       
        if theCourse == () {
            return <LecturerNotFound>{
                body: {errorMessage: string `Error no lecturer with this ${StaffNo}`}
            };
        } else {
            return theCourse;
        }
    }

    // Resource to get lecturers by officeNo
    resource function get getLecturerByOfficeNo/[string theOffice]() returns string[]|LecturerNotFound {
         string[] lecturersOffice = from var {officeNo, name} in self.lecturers
           where officeNo == theOffice
           select name;
           
           return lecturersOffice;
    }

    // Resource to update a lecturer by staffNo
    resource function put updateLecturer/[string StaffNo](@http:Payload LecturerPart lecturerPart) returns LecturerNotFound|Lecturer {
        Lecturer? theLecturer = self.lecturers[StaffNo];
        
        if theLecturer == (){
            return <LecturerNotFound>{
                body: {errorMessage: string `Error no course with code ${StaffNo}`}
            };
        }else{
            // Update the lecturer fields if provided in the request
            string? officeNo = lecturerPart?.officeNo;
            if officeNo != (){
                theLecturer.officeNo = officeNo;
            }

            string? name = lecturerPart?.name;
            if name != () {
                theLecturer.name = name;
            }

            string? title = lecturerPart?.title;
            if title != () {
                theLecturer.title = title;
            }

            string[]? courses = lecturerPart?.courses;
            if courses != (){
                theLecturer.courses = courses;
            }
            return theLecturer;
        }
    }

    // Resource to delete a lecturer by staffNo
    resource function delete deleteLecturer/[string StaffNo] () returns LecturerNotFound|http:Ok {
        Lecturer? theLecturer = self.lecturers[StaffNo];

        if theLecturer == () {
            return <LecturerNotFound>{
                body: {errorMessage: string `Error no lecturer with this number ${StaffNo}`}
            };
        }else {
            http:Ok ok = {body: "Deleted Lecturer"};
            return ok;
        }
    }
}
