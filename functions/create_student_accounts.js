const fs = require("fs");
const path = require("path");
const { randomInt } = require("crypto");
const xlsx = require("xlsx");

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

// ============================================================
// FIREBASE ADMIN INITIALIZATION
// ============================================================

initializeApp();

const auth = getAuth();
const db = getFirestore();

// ============================================================
// CONFIGURATION
// ============================================================

const DEFAULT_EXCEL_FILE = "students.xlsx";

const REQUIRED_COLUMNS = [
  "Name",
  "Register No",
  "Email",
  "Department",
  "Year",
  "Section",
  "Class Name",
  "Parent No",
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function cleanValue(value) {
  if (value === undefined || value === null) {
    return "";
  }

  return String(value).trim();
}

function normalizeHeader(value) {
  return cleanValue(value)
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function normalizeEmail(email) {
  return cleanValue(email).toLowerCase();
}

function normalizeClassValue(value) {
  return cleanValue(value)
    .replace(/\s+/g, "")
    .toUpperCase();
}

// ============================================================
// GENERATE RANDOM 6-DIGIT TEMPORARY PASSWORD
// ============================================================

function generateTemporaryPassword(usedPasswords = new Set()) {
  let password;

  do {
    password = randomInt(100000, 1000000).toString();
  } while (usedPasswords.has(password));

  usedPasswords.add(password);

  return password;
}

// ============================================================
// VALIDATION HELPERS
// ============================================================

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidRegisterNo(registerNo) {
  return /^[0-9]+$/.test(registerNo);
}

// ============================================================
// EXCEL PATH
// ============================================================

function getExcelFilePath() {
  const argumentPath = process.argv[2];

  if (argumentPath && argumentPath.trim() !== "") {
    return path.resolve(argumentPath.trim());
  }

  return path.join(__dirname, DEFAULT_EXCEL_FILE);
}

// ============================================================
// FIND EXCEL COLUMN
// ============================================================

function createColumnFinder(actualHeaders, row) {
  return (columnName) => {
    const normalizedColumn = normalizeHeader(columnName);

    const actualColumn = actualHeaders.find(
      (header) =>
        normalizeHeader(header) === normalizedColumn,
    );

    if (!actualColumn) {
      return "";
    }

    return cleanValue(row[actualColumn]);
  };
}

// ============================================================
// DERIVE SECTION FROM CLASS NAME
// ============================================================
//
// Example:
//
// 25CSEB2
// ├── 25   -> batch
// ├── CSE  -> department
// └── B2   -> section
//
// ============================================================

function deriveSectionFromClassName(
  className,
  department,
) {
  const normalizedClassName =
    normalizeClassValue(className);

  const normalizedDepartment =
    normalizeClassValue(department);

  if (
    !normalizedClassName ||
    !normalizedDepartment
  ) {
    return "";
  }

  const departmentIndex =
    normalizedClassName.indexOf(
      normalizedDepartment,
    );

  if (departmentIndex === -1) {
    return "";
  }

  const sectionStart =
    departmentIndex +
    normalizedDepartment.length;

  const derivedSection =
    normalizedClassName.substring(
      sectionStart,
    );

  return derivedSection.trim();
}

// ============================================================
// DERIVE BATCH FROM CLASS NAME
// ============================================================
//
// Example:
//
// 25CSEB2 -> 25
// 26ITB1  -> 26
//
// ============================================================

function deriveBatchFromClassName(
  className,
  department,
) {
  const normalizedClassName =
    normalizeClassValue(className);

  const normalizedDepartment =
    normalizeClassValue(department);

  if (
    !normalizedClassName ||
    !normalizedDepartment
  ) {
    return "";
  }

  const departmentIndex =
    normalizedClassName.indexOf(
      normalizedDepartment,
    );

  if (departmentIndex <= 0) {
    return "";
  }

  const batch =
    normalizedClassName.substring(
      0,
      departmentIndex,
    );

  if (!/^[0-9]+$/.test(batch)) {
    return "";
  }

  return batch;
}

// ============================================================
// NORMALIZE CLASS INFORMATION
// ============================================================
//
// Recommended Excel:
//
// Section    = B2
// Class Name = 25CSEB2
//
// If Excel accidentally contains:
//
// Section    = 25CSEB2
// Class Name = 25CSEB2
//
// this function converts Section to B2.
//
// ============================================================

function normalizeClassInformation(
  section,
  className,
  department,
) {
  let normalizedSection =
    normalizeClassValue(section);

  let normalizedClassName =
    normalizeClassValue(className);

  // If Class Name is missing but Section contains
  // the full class name, use Section as Class Name.
  if (
    !normalizedClassName &&
    normalizedSection
  ) {
    const normalizedDepartment =
      normalizeClassValue(department);

    if (
      normalizedDepartment &&
      normalizedSection.includes(
        normalizedDepartment,
      )
    ) {
      normalizedClassName =
        normalizedSection;
    }
  }

  // If Class Name exists, derive the actual section.
  if (normalizedClassName) {
    const derivedSection =
      deriveSectionFromClassName(
        normalizedClassName,
        department,
      );

    if (derivedSection) {
      normalizedSection =
        derivedSection;
    }
  }

  return {
    section: normalizedSection,
    className: normalizedClassName,
  };
}

// ============================================================
// READ EXCEL FILE
// ============================================================

function readStudentsFromExcel(filePath) {
  console.log(
    "\n============================================",
  );

  console.log(
    " Reading Excel File",
  );

  console.log(
    "============================================",
  );

  console.log(
    `File: ${filePath}`,
  );

  if (!fs.existsSync(filePath)) {
    throw new Error(
      `Excel file not found: ${filePath}`,
    );
  }

  const workbook =
    xlsx.readFile(filePath);

  if (
    workbook.SheetNames.length === 0
  ) {
    throw new Error(
      "The Excel file does not contain any worksheet.",
    );
  }

  const sheetName =
    workbook.SheetNames[0];

  const worksheet =
    workbook.Sheets[sheetName];

  const rows =
    xlsx.utils.sheet_to_json(
      worksheet,
      {
        defval: "",
        raw: false,
      },
    );

  if (rows.length === 0) {
    throw new Error(
      "The Excel worksheet does not contain any student rows.",
    );
  }

  // ----------------------------------------------------------
  // CHECK REQUIRED COLUMNS
  // ----------------------------------------------------------

  const firstRow = rows[0];

  const actualHeaders =
    Object.keys(firstRow);

  const normalizedHeaders =
    actualHeaders.map(
      normalizeHeader,
    );

  const missingColumns = [];

  for (
    const requiredColumn of
    REQUIRED_COLUMNS
  ) {
    const normalizedRequired =
      normalizeHeader(
        requiredColumn,
      );

    if (
      !normalizedHeaders.includes(
        normalizedRequired,
      )
    ) {
      missingColumns.push(
        requiredColumn,
      );
    }
  }

  if (
    missingColumns.length > 0
  ) {
    throw new Error(
      `Missing required Excel columns: ` +
      `${missingColumns.join(", ")}`,
    );
  }

  // ----------------------------------------------------------
  // MAP EXCEL ROWS
  // ----------------------------------------------------------

  const students =
    rows.map(
      (row, index) => {
        const rowNumber =
          index + 2;

        const findColumnValue =
          createColumnFinder(
            actualHeaders,
            row,
          );

        const name =
          findColumnValue(
            "Name",
          );

        const registerNo =
          findColumnValue(
            "Register No",
          );

        const email =
          normalizeEmail(
            findColumnValue(
              "Email",
            ),
          );

        const department =
          findColumnValue(
            "Department",
          );

        const year =
          findColumnValue(
            "Year",
          );

        const rawSection =
          findColumnValue(
            "Section",
          );

        const rawClassName =
          findColumnValue(
            "Class Name",
          );

        const parentPhone =
          findColumnValue(
            "Parent No",
          );

        const classInformation =
          normalizeClassInformation(
            rawSection,
            rawClassName,
            department,
          );

        return {
          rowNumber,
          name,
          registerNo,
          email,
          department,
          year,
          section:
            classInformation.section,
          className:
            classInformation.className,
          parentPhone,
          role: "Student",

          // Temporary password is generated
          // ONLY for a newly created Auth account.
          temporaryPassword: null,
        };
      },
    );

  return students;
}

// ============================================================
// VALIDATE STUDENT ROW
// ============================================================

function validateStudent(student) {
  const errors = [];

  if (!student.name) {
    errors.push(
      "Name is missing",
    );
  }

  if (!student.registerNo) {
    errors.push(
      "Register No is missing",
    );
  } else if (
    !isValidRegisterNo(
      student.registerNo,
    )
  ) {
    errors.push(
      "Register No must contain only numbers",
    );
  }

  if (!student.email) {
    errors.push(
      "Email is missing",
    );
  } else if (
    !isValidEmail(
      student.email,
    )
  ) {
    errors.push(
      "Invalid email",
    );
  }

  if (!student.department) {
    errors.push(
      "Department is missing",
    );
  }

  if (!student.year) {
    errors.push(
      "Year is missing",
    );
  }

  if (!student.section) {
    errors.push(
      "Section is missing",
    );
  }

  if (!student.className) {
    errors.push(
      "Class Name is missing",
    );
  }

  if (!student.parentPhone) {
    errors.push(
      "Parent No is missing",
    );
  }

  return errors;
}

// ============================================================
// CHECK DUPLICATE REGISTER NUMBERS
// ============================================================

function findDuplicateRegisterNumbers(
  students,
) {
  const registerNumbers =
    new Map();

  const duplicates = [];

  for (
    const student of students
  ) {
    if (!student.registerNo) {
      continue;
    }

    if (
      registerNumbers.has(
        student.registerNo,
      )
    ) {
      duplicates.push({
        registerNo:
          student.registerNo,
        firstRow:
          registerNumbers.get(
            student.registerNo,
          ),
        duplicateRow:
          student.rowNumber,
      });
    } else {
      registerNumbers.set(
        student.registerNo,
        student.rowNumber,
      );
    }
  }

  return duplicates;
}

// ============================================================
// CHECK DUPLICATE EMAILS
// ============================================================

function findDuplicateEmails(
  students,
) {
  const emails = new Map();

  const duplicates = [];

  for (
    const student of students
  ) {
    if (!student.email) {
      continue;
    }

    if (
      emails.has(student.email)
    ) {
      duplicates.push({
        email:
          student.email,
        firstRow:
          emails.get(
            student.email,
          ),
        duplicateRow:
          student.rowNumber,
      });
    } else {
      emails.set(
        student.email,
        student.rowNumber,
      );
    }
  }

  return duplicates;
}

// ============================================================
// FIND EXISTING STUDENT BY REGISTER NUMBER
// ============================================================

async function findStudentByRegisterNo(
  registerNo,
) {
  const query =
    await db
      .collection("users")
      .where(
        "registerNo",
        "==",
        registerNo,
      )
      .limit(5)
      .get();

  if (query.empty) {
    return null;
  }

  // Prefer Student role.
  for (
    const doc of query.docs
  ) {
    const data =
      doc.data();

    if (
      data.role === "Student"
    ) {
      return {
        uid: doc.id,
        data,
      };
    }
  }

  // Fallback to first document.
  const firstDoc =
    query.docs[0];

  return {
    uid: firstDoc.id,
    data:
      firstDoc.data(),
  };
}

// ============================================================
// FIND MENTOR ASSIGNED TO CLASS
// ============================================================
//
// The Associate Dean assigns a mentor to a class document:
//
// classes/25CSEB2
//
// {
//   className: "25CSEB2",
//   mentorUid: "...",
//   mentorName: "Mr. Arun",
//   ...
// }
//
// During student import, the student's:
//
// mentorUid
// mentorName
//
// are automatically synchronized from the class document.
//
// ============================================================

async function getClassMentorAssignment(
  className,
) {
  const normalizedClassName =
    normalizeClassValue(className);

  if (!normalizedClassName) {
    return {
      hasMentor: false,
      mentorUid: "",
      mentorName: "",
    };
  }

  const classRef =
    db
      .collection("classes")
      .doc(normalizedClassName);

  const classSnapshot =
    await classRef.get();

  if (!classSnapshot.exists) {
    throw new Error(
      `Class ${normalizedClassName} does not exist in Firestore.`,
    );
  }

  const classData =
    classSnapshot.data() || {};

  const mentorUid =
    cleanValue(
      classData.mentorUid || "",
    );

  const mentorName =
    cleanValue(
      classData.mentorName || "",
    );

  if (!mentorUid) {
    return {
      hasMentor: false,
      mentorUid: "",
      mentorName: "",
    };
  }

  return {
    hasMentor: true,
    mentorUid,
    mentorName,
  };
}

// ============================================================
// CREATE / UPDATE CLASS
// ============================================================
//
// Every unique Class Name in the Excel file gets a
// Firestore document:
//
// classes/{className}
//
// Example:
//
// classes/25CSEB2
//
// {
//   className: "25CSEB2",
//   batch: "25",
//   department: "CSE",
//   year: "II",
//   section: "B2"
// }
//
// IMPORTANT:
// Existing mentorUid / mentorName fields are preserved because
// this function uses merge: true.
//
// ============================================================

async function createOrUpdateClass(
  classInformation,
) {
  const className =
    normalizeClassValue(
      classInformation.className,
    );

  const department =
    normalizeClassValue(
      classInformation.department,
    );

  const year =
    cleanValue(
      classInformation.year,
    );

  const section =
    normalizeClassValue(
      classInformation.section,
    );

  if (!className) {
    throw new Error(
      "Cannot create class because Class Name is missing.",
    );
  }

  if (!department) {
    throw new Error(
      `Cannot create class ${className} because Department is missing.`,
    );
  }

  if (!year) {
    throw new Error(
      `Cannot create class ${className} because Year is missing.`,
    );
  }

  if (!section) {
    throw new Error(
      `Cannot create class ${className} because Section is missing.`,
    );
  }

  const batch =
    deriveBatchFromClassName(
      className,
      department,
    );

  const classRef =
    db
      .collection("classes")
      .doc(className);

  const existingClass =
    await classRef.get();

  const classData = {
    className,
    batch,
    department,
    year,
    section,
    updatedAt:
      FieldValue.serverTimestamp(),
  };

  if (!existingClass.exists) {
    classData.createdAt =
      FieldValue.serverTimestamp();

    await classRef.set(
      classData,
    );

    console.log(
      `Class created: ${className}`,
    );
  } else {
    // IMPORTANT:
    // merge:true preserves mentorUid and mentorName
    // already assigned by the Associate Dean.

    await classRef.set(
      classData,
      {
        merge: true,
      },
    );

    console.log(
      `Class updated: ${className}`,
    );
  }

  return classData;
}

// ============================================================
// CREATE / UPDATE ALL UNIQUE CLASSES
// ============================================================
//
// This runs BEFORE student account creation.
//
// Therefore the class list is created from the Excel file,
// not from whichever students happen to exist in Firestore.
//
// ============================================================

async function createOrUpdateClasses(
  students,
) {
  console.log(
    "\n============================================",
  );

  console.log(
    " Creating / Updating Classes",
  );

  console.log(
    "============================================",
  );

  const uniqueClasses =
    new Map();

  for (
    const student of students
  ) {
    const className =
      normalizeClassValue(
        student.className,
      );

    if (!className) {
      continue;
    }

    if (
      !uniqueClasses.has(
        className,
      )
    ) {
      uniqueClasses.set(
        className,
        student,
      );
    }
  }

  console.log(
    `Unique classes found: ${
      uniqueClasses.size
    }`,
  );

  let createdCount = 0;
  let updatedCount = 0;

  for (
    const [
      className,
      student,
    ] of uniqueClasses
  ) {
    const classRef =
      db
        .collection("classes")
        .doc(className);

    const existingClass =
      await classRef.get();

    await createOrUpdateClass({
      className:
        student.className,
      department:
        student.department,
      year:
        student.year,
      section:
        student.section,
    });

    if (existingClass.exists) {
      updatedCount++;
    } else {
      createdCount++;
    }
  }

  console.log(
    "\nClass summary:",
  );

  console.log(
    `New classes: ${createdCount}`,
  );

  console.log(
    `Updated classes: ${updatedCount}`,
  );

  console.log(
    `Total classes: ${
      uniqueClasses.size
    }`,
  );
}

// ============================================================
// CREATE / UPDATE ONE STUDENT
// ============================================================

async function createStudent(
  student,
  usedPasswords,
) {
  console.log(
    "\n--------------------------------------------",
  );

  console.log(
    `Processing Excel row: ${student.rowNumber}`,
  );

  console.log(
    `Student: ${student.name}`,
  );

  console.log(
    `Register No: ${student.registerNo}`,
  );

  console.log(
    `Email: ${student.email}`,
  );

  console.log(
    `Class Name: ${student.className}`,
  );

  console.log(
    `Section: ${student.section}`,
  );

  // ----------------------------------------------------------
  // GET CLASS MENTOR
  // ----------------------------------------------------------
  //
  // The class document is created/updated before this function
  // runs.
  //
  // Example:
  //
  // classes/25CSEB2
  //
  // mentorUid  -> Firebase UID of Mr. Arun
  // mentorName -> Mr. Arun
  //
  // ----------------------------------------------------------

  const mentorAssignment =
    await getClassMentorAssignment(
      student.className,
    );

  if (
    mentorAssignment.hasMentor
  ) {
    console.log(
      `Class mentor found: ${
        mentorAssignment.mentorName ||
        "(name not available)"
      }`,
    );

    console.log(
      `Mentor UID: ${mentorAssignment.mentorUid}`,
    );
  } else {
    console.log(
      "No mentor is currently assigned to this class.",
    );
  }

  // ----------------------------------------------------------
  // FIRST REGISTER NUMBER CHECK
  // ----------------------------------------------------------

  const existingRegisterProfile =
    await findStudentByRegisterNo(
      student.registerNo,
    );

  if (
    existingRegisterProfile !== null
  ) {
    const existingUid =
      existingRegisterProfile.uid;

    const existingData =
      existingRegisterProfile.data;

    const existingEmail =
      normalizeEmail(
        existingData.email || "",
      );

    const existingName =
      cleanValue(
        existingData.name || "",
      );

    const existingRole =
      cleanValue(
        existingData.role || "",
      );

    // --------------------------------------------------------
    // CHECK SAME AUTH ACCOUNT
    // --------------------------------------------------------

    let emailUserRecord =
      null;

    try {
      emailUserRecord =
        await auth.getUserByEmail(
          student.email,
        );
    } catch (error) {
      if (
        error.code !==
        "auth/user-not-found"
      ) {
        throw error;
      }
    }

    if (
      emailUserRecord !== null &&
      emailUserRecord.uid ===
        existingUid
    ) {
      console.log(
        "Existing Register No belongs to the same student.",
      );

      console.log(
        "Existing student profile will be updated.",
      );
    } else if (
      emailUserRecord === null &&
      existingEmail ===
        student.email
    ) {
      throw new Error(
        `Register No ${student.registerNo} ` +
        `already belongs to "${existingName}", ` +
        `but its Authentication account ` +
        `could not be found. ` +
        `Manual review required.`,
      );
    } else {
      const existingEmailText =
        existingEmail ||
        "(no email)";

      throw new Error(
        `Register No ${student.registerNo} ` +
        `is already assigned to another student. ` +
        `Existing name: ` +
        `"${existingName || "(unknown)"}", ` +
        `Existing email: ` +
        `"${existingEmailText}", ` +
        `Existing UID: ${existingUid}, ` +
        `Existing role: ` +
        `${existingRole || "(unknown)"}. ` +
        `This Excel row was not imported.`,
      );
    }
  }

  // ----------------------------------------------------------
  // FIREBASE AUTHENTICATION
  // ----------------------------------------------------------

  let userRecord;
  let accountCreated = false;

  try {
    userRecord =
      await auth.getUserByEmail(
        student.email,
      );

    console.log(
      "Authentication account already exists.",
    );
  } catch (error) {
    if (
      error.code !==
      "auth/user-not-found"
    ) {
      throw error;
    }

    // --------------------------------------------------------
    // NEW ACCOUNT
    // --------------------------------------------------------

    student.temporaryPassword =
      generateTemporaryPassword(
        usedPasswords,
      );

    userRecord =
      await auth.createUser({
        email:
          student.email,
        password:
          student.temporaryPassword,
        displayName:
          student.name,
      });

    accountCreated = true;

    console.log(
      "Firebase Authentication account created.",
    );

    console.log(
      "Random 6-digit temporary password generated.",
    );
  }

  // ----------------------------------------------------------
  // SECOND REGISTER CHECK
  // ----------------------------------------------------------

  const profileByRegister =
    await findStudentByRegisterNo(
      student.registerNo,
    );

  if (
    profileByRegister !== null &&
    profileByRegister.uid !==
      userRecord.uid
  ) {
    throw new Error(
      `Register No ${student.registerNo} ` +
      `is already linked to another ` +
      `Firebase user. Import cancelled for ` +
      `${student.name}.`,
    );
  }

  // ----------------------------------------------------------
  // FIRESTORE PROFILE
  // ----------------------------------------------------------

  const studentRef =
    db
      .collection("users")
      .doc(userRecord.uid);

  const existingProfile =
    await studentRef.get();

  // ----------------------------------------------------------
  // PROFILE DATA
  // ----------------------------------------------------------

  const profileData = {
    uid:
      userRecord.uid,

    name:
      student.name,

    registerNo:
      student.registerNo,

    email:
      student.email,

    department:
      student.department,

    year:
      student.year,

    section:
      student.section,

    className:
      student.className,

    parentPhone:
      student.parentPhone,

    role:
      "Student",

    updatedAt:
      FieldValue.serverTimestamp(),
  };

  // ----------------------------------------------------------
  // AUTOMATIC CLASS -> MENTOR LINK
  // ----------------------------------------------------------
  //
  // If the class has a mentor:
  //
  // mentorUid  = class.mentorUid
  // mentorName = class.mentorName
  //
  // If the class has NO mentor:
  // remove any old mentor assignment from the student.
  //
  // This makes Excel import automatically synchronize
  // the student with the Associate Dean's class assignment.
  //
  // ----------------------------------------------------------

  if (
    mentorAssignment.hasMentor
  ) {
    profileData.mentorUid =
      mentorAssignment.mentorUid;

    profileData.mentorName =
      mentorAssignment.mentorName;

    console.log(
      `Student linked to mentor: ${
        mentorAssignment.mentorName ||
        mentorAssignment.mentorUid
      }`,
    );
  } else {
    profileData.mentorUid =
      FieldValue.delete();

    profileData.mentorName =
      FieldValue.delete();

    console.log(
      "Student mentor assignment cleared because this class has no mentor.",
    );
  }

  // ----------------------------------------------------------
  // NEW STUDENT
  // ----------------------------------------------------------

  if (!existingProfile.exists) {
    profileData.createdAt =
      FieldValue.serverTimestamp();

    profileData.mustChangePassword =
      true;

    profileData.passwordStatus =
      "temporary";

    profileData.passwordCreatedAt =
      FieldValue.serverTimestamp();

    await studentRef.set(
      profileData,
    );

    console.log(
      "Firestore student profile created.",
    );
  } else {
    // --------------------------------------------------------
    // EXISTING STUDENT
    // --------------------------------------------------------
    //
    // Password is NOT changed.
    //
    await studentRef.set(
      profileData,
      {
        merge: true,
      },
    );

    console.log(
      "Existing Firestore student profile updated.",
    );
  }

  // ----------------------------------------------------------
  // LOGIN INFORMATION
  // ----------------------------------------------------------

  console.log(
    `Account status: ${
      accountCreated
        ? "Created"
        : "Already existed"
    }`,
  );

  if (accountCreated) {
    console.log(
      `Temporary password: ${
        student.temporaryPassword
      }`,
    );

    console.log(
      "Password status: Temporary",
    );

    console.log(
      "Student must change password on first login.",
    );
  } else {
    console.log(
      "Temporary password: Not changed",
    );

    console.log(
      "Existing student password was preserved.",
    );
  }

  return {
    success: true,
    accountCreated,
    student,
  };
}

// ============================================================
// MAIN IMPORTER
// ============================================================

async function main() {
  console.log("\n");

  console.log(
    "============================================",
  );

  console.log(
    " SparkEdu Excel Student Importer",
  );

  console.log(
    "============================================",
  );

  console.log(
    "Firebase project: sparkedu-4c3e9",
  );

  console.log(
    "============================================",
  );

  const excelFilePath =
    getExcelFilePath();

  // ----------------------------------------------------------
  // READ EXCEL
  // ----------------------------------------------------------

  let students;

  try {
    students =
      readStudentsFromExcel(
        excelFilePath,
      );
  } catch (error) {
    console.error(
      "\n❌ Excel reading failed:",
    );

    console.error(
      error.message || error,
    );

    process.exitCode = 1;

    return;
  }

  console.log(
    `\nStudents found in Excel: ${
      students.length
    }`,
  );

  // ----------------------------------------------------------
  // SHOW CLASS INFORMATION
  // ----------------------------------------------------------

  console.log(
    "\n============================================",
  );

  console.log(
    " Class Information",
  );

  console.log(
    "============================================",
  );

  for (
    const student of students
  ) {
    console.log(
      `${student.name} | ` +
      `Register No: ${student.registerNo} | ` +
      `Class: ${student.className} | ` +
      `Section: ${student.section}`,
    );
  }

  // ----------------------------------------------------------
  // VALIDATE ROWS
  // ----------------------------------------------------------

  console.log(
    "\n============================================",
  );

  console.log(
    " Validating Student Data",
  );

  console.log(
    "============================================",
  );

  const validStudents = [];
  const invalidStudents = [];

  for (
    const student of students
  ) {
    const errors =
      validateStudent(student);

    if (errors.length > 0) {
      invalidStudents.push({
        student,
        errors,
      });

      console.error(
        `❌ Row ${student.rowNumber}: ` +
        `${student.name || "(no name)"}`,
      );

      for (
        const error of errors
      ) {
        console.error(
          `   - ${error}`,
        );
      }
    } else {
      validStudents.push(
        student,
      );
    }
  }

  // ----------------------------------------------------------
  // DUPLICATE REGISTER NUMBERS
  // ----------------------------------------------------------

  const duplicateRegisters =
    findDuplicateRegisterNumbers(
      validStudents,
    );

  if (
    duplicateRegisters.length > 0
  ) {
    console.log(
      "\n❌ Duplicate Register Numbers " +
      "found inside the Excel file:",
    );

    for (
      const duplicate of
      duplicateRegisters
    ) {
      console.error(
        `Register No ${duplicate.registerNo}: ` +
        `rows ${duplicate.firstRow} and ` +
        `${duplicate.duplicateRow}`,
      );
    }

    console.error(
      "\nImport stopped to prevent duplicate student data.",
    );

    process.exitCode = 1;

    return;
  }

  // ----------------------------------------------------------
  // DUPLICATE EMAILS
  // ----------------------------------------------------------

  const duplicateEmails =
    findDuplicateEmails(
      validStudents,
    );

  if (
    duplicateEmails.length > 0
  ) {
    console.log(
      "\n❌ Duplicate Emails found inside " +
      "the Excel file:",
    );

    for (
      const duplicate of
      duplicateEmails
    ) {
      console.error(
        `Email ${duplicate.email}: ` +
        `rows ${duplicate.firstRow} and ` +
        `${duplicate.duplicateRow}`,
      );
    }

    console.error(
      "\nImport stopped to prevent duplicate accounts.",
    );

    process.exitCode = 1;

    return;
  }

  // ----------------------------------------------------------
  // INVALID ROWS
  // ----------------------------------------------------------

  if (
    invalidStudents.length > 0
  ) {
    console.log(
      `\nValid rows: ${
        validStudents.length
      }`,
    );

    console.log(
      `Invalid rows: ${
        invalidStudents.length
      }`,
    );

    console.error(
      "\nImport stopped because some rows " +
      "contain invalid data.",
    );

    console.error(
      "Fix the Excel file and run the importer again.",
    );

    process.exitCode = 1;

    return;
  }

  console.log(
    `\nAll ${validStudents.length} ` +
    "student rows are valid.",
  );

  // ----------------------------------------------------------
  // CREATE / UPDATE CLASS RECORDS
  // ----------------------------------------------------------
  //
  // Classes are created from the Excel file before
  // student account processing.
  //
  // IMPORTANT:
  // Existing mentorUid and mentorName fields on the class
  // document are preserved because createOrUpdateClass()
  // uses merge:true.
  //
  // Example:
  //
  // classes/25CSEB2
  //
  // {
  //   className: "25CSEB2",
  //   batch: "25",
  //   department: "CSE",
  //   year: "II",
  //   section: "B2",
  //   mentorUid: "...",
  //   mentorName: "Mr. Arun"
  // }
  //
  // ----------------------------------------------------------

  try {
    await createOrUpdateClasses(
      validStudents,
    );
  } catch (error) {
    console.error(
      "\n❌ Class creation/update failed:",
    );

    console.error(
      error.message || error,
    );

    process.exitCode = 1;

    return;
  }

  // ----------------------------------------------------------
  // IMPORT STUDENTS
  // ----------------------------------------------------------

  console.log(
    "\n============================================",
  );

  console.log(
    " Importing Students",
  );

  console.log(
    "============================================",
  );

  let successCount = 0;
  let failedCount = 0;
  let createdAccountCount = 0;
  let existingAccountCount = 0;

  const failedStudents = [];

  // Prevent duplicate temporary passwords
  // during this import.
  const usedTemporaryPasswords =
    new Set();

  // ----------------------------------------------------------
  // PROCESS EACH STUDENT
  // ----------------------------------------------------------

  for (
    const student of validStudents
  ) {
    try {
      const result =
        await createStudent(
          student,
          usedTemporaryPasswords,
        );

      successCount++;

      if (
        result.accountCreated
      ) {
        createdAccountCount++;
      } else {
        existingAccountCount++;
      }
    } catch (error) {
      failedCount++;

      failedStudents.push({
        student,
        error:
          error.message ||
          String(error),
      });

      console.error(
        `\n❌ Failed: ${student.name}`,
      );

      console.error(
        error.message || error,
      );
    }
  }

  // ----------------------------------------------------------
  // FINAL SUMMARY
  // ----------------------------------------------------------

  console.log("\n");

  console.log(
    "============================================",
  );

  console.log(
    " Import Finished",
  );

  console.log(
    "============================================",
  );

  console.log(
    `Total rows: ${students.length}`,
  );

  console.log(
    `Successful: ${successCount}`,
  );

  console.log(
    `Failed: ${failedCount}`,
  );

  console.log(
    `New Auth accounts: ${
      createdAccountCount
    }`,
  );

  console.log(
    `Existing Auth accounts: ${
      existingAccountCount
    }`,
  );

  console.log(
    "============================================",
  );

  // ----------------------------------------------------------
  // FAILED STUDENTS
  // ----------------------------------------------------------

  if (
    failedStudents.length > 0
  ) {
    console.log(
      "\nFailed students:",
    );

    for (
      const failed of
      failedStudents
    ) {
      console.log(
        `- ${failed.student.name} ` +
        `(${failed.student.registerNo})`,
      );

      console.log(
        `  Reason: ${failed.error}`,
      );
    }
  }

  // ----------------------------------------------------------
  // NEW TEMPORARY PASSWORDS
  // ----------------------------------------------------------

  if (
    createdAccountCount > 0
  ) {
    console.log(
      "\n============================================",
    );

    console.log(
      " NEW STUDENT TEMPORARY PASSWORDS",
    );

    console.log(
      "============================================",
    );

    console.log(
      "IMPORTANT: These passwords are shown only",
    );

    console.log(
      "because they were generated during this import.",
    );

    console.log(
      "They are NOT stored as plain text in Firestore.",
    );

    console.log(
      "Give each temporary password securely to its student.",
    );

    console.log(
      "============================================",
    );

    for (
      const student of
      validStudents
    ) {
      if (
        student.temporaryPassword !==
        null
      ) {
        console.log(
          `${student.name} | ` +
          `Register No: ${student.registerNo} | ` +
          `Class: ${student.className} | ` +
          `Email: ${student.email} | ` +
          `Temporary Password: ` +
          `${student.temporaryPassword}`,
        );
      }
    }

    console.log(
      "============================================",
    );
  }

  if (
    createdAccountCount === 0
  ) {
    console.log(
      "\nNo new accounts were created.",
    );

    console.log(
      "Therefore, no existing student passwords were changed.",
    );
  }

  if (failedCount > 0) {
    process.exitCode = 1;
  }
}

// ============================================================
// START
// ============================================================

main();