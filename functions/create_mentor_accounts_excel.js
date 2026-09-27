const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const xlsx = require("xlsx");

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

// ============================================================
// FIREBASE INITIALIZATION
// ============================================================

initializeApp();

const auth = getAuth();
const db = getFirestore();

// ============================================================
// CONFIGURATION
// ============================================================

const DEFAULT_EXCEL_FILE = "mentors.xlsx";

const REQUIRED_COLUMNS = [
  "Employee ID",
  "Name",
  "Email",
  "Phone",
  "Department",
  "Designation",
];

// ============================================================
// HELPERS
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

function normalizeEmail(value) {
  return cleanValue(value).toLowerCase();
}

function normalizeEmployeeId(value) {
  return cleanValue(value).toUpperCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPhone(phone) {
  if (!phone) {
    return true;
  }

  return /^[0-9]{10,15}$/.test(phone);
}

function generateTemporaryPassword() {
  return crypto.randomInt(100000, 1000000).toString();
}

function getExcelFilePath() {
  const argumentPath = process.argv[2];

  if (argumentPath) {
    return path.resolve(argumentPath);
  }

  return path.join(__dirname, DEFAULT_EXCEL_FILE);
}

// ============================================================
// FIRESTORE LOOKUPS
// ============================================================

async function findMentorByEmployeeId(employeeId) {
  if (!employeeId) {
    return null;
  }

  const snapshot = await db
    .collection("users")
    .where("employeeId", "==", employeeId)
    .where("role", "==", "Mentor")
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  return snapshot.docs[0];
}

async function findMentorByEmail(email) {
  if (!email) {
    return null;
  }

  const snapshot = await db
    .collection("users")
    .where("email", "==", email)
    .where("role", "==", "Mentor")
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  return snapshot.docs[0];
}

// ============================================================
// AUTH LOOKUP
// ============================================================

async function findAuthUserByEmail(email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return null;
    }

    throw error;
  }
}

// ============================================================
// CREATE / UPDATE ONE MENTOR
// ============================================================

async function processMentor(mentor, rowNumber, generatedPasswords) {
  const employeeId = normalizeEmployeeId(mentor["Employee ID"]);
  const name = cleanValue(mentor["Name"]);
  const email = normalizeEmail(mentor["Email"]);
  const phone = cleanValue(mentor["Phone"]);
  const department = cleanValue(mentor["Department"]);
  const designation = cleanValue(mentor["Designation"]);

  console.log("\n----------------------------------------");
  console.log(`Processing Excel row ${rowNumber}`);
  console.log("----------------------------------------");

  // ----------------------------------------------------------
  // VALIDATION
  // ----------------------------------------------------------

  if (!employeeId) {
    throw new Error("Employee ID is required.");
  }

  if (!name) {
    throw new Error("Name is required.");
  }

  if (!email) {
    throw new Error("Email is required.");
  }

  if (!department) {
    throw new Error("Department is required.");
  }

  if (!designation) {
    throw new Error("Designation is required.");
  }

  if (!isValidEmail(email)) {
    throw new Error(`Invalid email address: ${email}`);
  }

  if (!isValidPhone(phone)) {
    throw new Error(
      `Invalid phone number: ${phone}. Use 10 to 15 digits.`
    );
  }

  // ----------------------------------------------------------
  // CHECK EXISTING FIRESTORE MENTOR BY EMPLOYEE ID
  // ----------------------------------------------------------

  const existingByEmployeeId =
    await findMentorByEmployeeId(employeeId);

  // ----------------------------------------------------------
  // CHECK EXISTING FIRESTORE MENTOR BY EMAIL
  // ----------------------------------------------------------

  const existingByEmail = await findMentorByEmail(email);

  if (
    existingByEmployeeId &&
    existingByEmail &&
    existingByEmployeeId.id !== existingByEmail.id
  ) {
    throw new Error(
      `Employee ID ${employeeId} and email ${email} belong to different Mentor profiles.`
    );
  }

  const existingMentorDoc =
    existingByEmployeeId || existingByEmail;

  // ----------------------------------------------------------
  // CHECK FIREBASE AUTH ACCOUNT
  // ----------------------------------------------------------

  const existingAuthUser = await findAuthUserByEmail(email);

  // ----------------------------------------------------------
  // EXISTING FIRESTORE PROFILE
  // ----------------------------------------------------------

  if (existingMentorDoc) {
    const existingData = existingMentorDoc.data();

    console.log(
      `Existing Mentor profile found: ${existingMentorDoc.id}`
    );

    // If Auth account exists, keep the existing password.
    if (existingAuthUser) {
      await existingMentorDoc.ref.update({
        uid: existingAuthUser.uid,
        name,
        email,
        employeeId,
        phone,
        department,
        designation,
        role: "Mentor",
        accountStatus: "Active",
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log("Existing Firebase account preserved.");
      console.log("Existing password was NOT changed.");
      console.log("Mentor profile updated.");

      return {
        status: "updated",
        employeeId,
        email,
        name,
      };
    }

    // --------------------------------------------------------
    // FIRESTORE PROFILE EXISTS BUT AUTH DOES NOT
    // --------------------------------------------------------

    const temporaryPassword = generateTemporaryPassword();

    const authUser = await auth.createUser({
      email,
      password: temporaryPassword,
      displayName: name,
      emailVerified: false,
    });

    await existingMentorDoc.ref.update({
      uid: authUser.uid,
      name,
      email,
      employeeId,
      phone,
      department,
      designation,
      role: "Mentor",
      accountStatus: "Active",
      mustChangePassword: true,
      passwordStatus: "Temporary",
      passwordCreatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    generatedPasswords.push({
      employeeId,
      name,
      email,
      temporaryPassword,
    });

    console.log("Firebase Authentication account created.");
    console.log("Existing Firestore Mentor profile updated.");
    console.log("Temporary password generated.");

    return {
      status: "created",
      employeeId,
      email,
      name,
    };
  }

  // ----------------------------------------------------------
  // NO FIRESTORE PROFILE
  // ----------------------------------------------------------

  if (existingAuthUser) {
    throw new Error(
      `Firebase Authentication account already exists for ${email}, but no Mentor Firestore profile was found.`
    );
  }

  // ----------------------------------------------------------
  // CREATE NEW AUTH ACCOUNT
  // ----------------------------------------------------------

  const temporaryPassword = generateTemporaryPassword();

  console.log("Creating Firebase Authentication account...");

  const authUser = await auth.createUser({
    email,
    password: temporaryPassword,
    displayName: name,
    emailVerified: false,
  });

  // ----------------------------------------------------------
  // CREATE FIRESTORE PROFILE
  // ----------------------------------------------------------

  await db.collection("users").doc(authUser.uid).set({
    uid: authUser.uid,
    name,
    email,
    employeeId,
    phone,
    department,
    designation,

    role: "Mentor",

    accountStatus: "Active",

    mustChangePassword: true,
    passwordStatus: "Temporary",

    passwordCreatedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  generatedPasswords.push({
    employeeId,
    name,
    email,
    temporaryPassword,
  });

  console.log("Firebase Authentication account created.");
  console.log("Firestore Mentor profile created.");
  console.log("Temporary password generated.");

  return {
    status: "created",
    employeeId,
    email,
    name,
  };
}

// ============================================================
// READ EXCEL FILE
// ============================================================

function readMentorExcel(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(
      `Excel file not found:\n${filePath}`
    );
  }

  console.log("\nReading Excel file:");
  console.log(filePath);

  const workbook = xlsx.readFile(filePath);

  if (!workbook.SheetNames.length) {
    throw new Error("The Excel file contains no worksheets.");
  }

  const firstSheetName = workbook.SheetNames[0];

  const worksheet = workbook.Sheets[firstSheetName];

  const rows = xlsx.utils.sheet_to_json(worksheet, {
    defval: "",
    raw: false,
  });

  if (!rows.length) {
    throw new Error(
      "The Excel worksheet contains no mentor records."
    );
  }

  // ----------------------------------------------------------
  // CHECK REQUIRED HEADERS
  // ----------------------------------------------------------

  const firstRow = rows[0];

  const actualHeaders = Object.keys(firstRow);

  const normalizedActualHeaders =
    actualHeaders.map(normalizeHeader);

  const missingColumns = REQUIRED_COLUMNS.filter(
    (requiredColumn) =>
      !normalizedActualHeaders.includes(
        normalizeHeader(requiredColumn)
      )
  );

  if (missingColumns.length > 0) {
    throw new Error(
      `Missing required Excel columns:\n${missingColumns.join(
        "\n"
      )}`
    );
  }

  // ----------------------------------------------------------
  // MAP ACTUAL HEADERS TO STANDARD HEADERS
  // ----------------------------------------------------------

  const headerMap = {};

  for (const requiredColumn of REQUIRED_COLUMNS) {
    const normalizedRequired =
      normalizeHeader(requiredColumn);

    const actualHeader = actualHeaders.find(
      (header) =>
        normalizeHeader(header) === normalizedRequired
    );

    headerMap[requiredColumn] = actualHeader;
  }

  // ----------------------------------------------------------
  // NORMALIZE ROWS
  // ----------------------------------------------------------

  return rows.map((row) => {
    const normalizedRow = {};

    for (const requiredColumn of REQUIRED_COLUMNS) {
      normalizedRow[requiredColumn] =
        cleanValue(row[headerMap[requiredColumn]]);
    }

    return normalizedRow;
  });
}

// ============================================================
// VALIDATE DUPLICATES INSIDE EXCEL
// ============================================================

function validateExcelDuplicates(rows) {
  const employeeIds = new Map();
  const emails = new Map();

  for (let index = 0; index < rows.length; index++) {
    const row = rows[index];

    const excelRowNumber = index + 2;

    const employeeId = normalizeEmployeeId(
      row["Employee ID"]
    );

    const email = normalizeEmail(row["Email"]);

    if (employeeId) {
      if (employeeIds.has(employeeId)) {
        throw new Error(
          `Duplicate Employee ID "${employeeId}" found in Excel rows ${employeeIds.get(
            employeeId
          )} and ${excelRowNumber}.`
        );
      }

      employeeIds.set(employeeId, excelRowNumber);
    }

    if (email) {
      if (emails.has(email)) {
        throw new Error(
          `Duplicate email "${email}" found in Excel rows ${emails.get(
            email
          )} and ${excelRowNumber}.`
        );
      }

      emails.set(email, excelRowNumber);
    }
  }
}

// ============================================================
// MAIN
// ============================================================

async function main() {
  console.log("\n========================================");
  console.log("SPARKEDU MENTOR EXCEL IMPORT");
  console.log("========================================");

  const excelFilePath = getExcelFilePath();

  console.log(`Excel file: ${excelFilePath}`);

  const rows = readMentorExcel(excelFilePath);

  console.log(`Mentors found in Excel: ${rows.length}`);

  validateExcelDuplicates(rows);

  console.log("Excel validation successful.");

  const generatedPasswords = [];

  let createdCount = 0;
  let updatedCount = 0;
  let failedCount = 0;

  const results = [];

  // ==========================================================
  // PROCESS EACH MENTOR
  // ==========================================================

  for (let index = 0; index < rows.length; index++) {
    const row = rows[index];

    const excelRowNumber = index + 2;

    try {
      const result = await processMentor(
        row,
        excelRowNumber,
        generatedPasswords
      );

      results.push(result);

      if (result.status === "created") {
        createdCount++;
      } else if (result.status === "updated") {
        updatedCount++;
      }
    } catch (error) {
      failedCount++;

      const employeeId = normalizeEmployeeId(
        row["Employee ID"]
      );

      const email = normalizeEmail(row["Email"]);

      console.error(
        `FAILED — Row ${excelRowNumber} — Employee ID: ${employeeId} — Email: ${email}`
      );

      console.error(`Reason: ${error.message}`);
    }
  }

  // ==========================================================
  // FINAL SUMMARY
  // ==========================================================

  console.log("\n\n========================================");
  console.log("MENTOR IMPORT COMPLETED");
  console.log("========================================");

  console.log(`Total Excel rows : ${rows.length}`);
  console.log(`Created          : ${createdCount}`);
  console.log(`Updated          : ${updatedCount}`);
  console.log(`Failed           : ${failedCount}`);

  // ==========================================================
  // TEMPORARY PASSWORDS
  // ==========================================================

  if (generatedPasswords.length > 0) {
    console.log("\n========================================");
    console.log("NEW MENTOR TEMPORARY PASSWORDS");
    console.log("========================================");

    console.log(
      "IMPORTANT: These passwords are shown only here."
    );

    console.log(
      "They are NOT stored in Firestore."
    );

    console.log(
      "Give each temporary password privately to the corresponding mentor."
    );

    console.log("");

    for (const mentor of generatedPasswords) {
      console.log("----------------------------------------");
      console.log(`Employee ID : ${mentor.employeeId}`);
      console.log(`Name        : ${mentor.name}`);
      console.log(`Email       : ${mentor.email}`);
      console.log(
        `TEMP PASSWORD: ${mentor.temporaryPassword}`
      );
    }

    console.log("----------------------------------------");
  } else {
    console.log(
      "\nNo new temporary passwords were generated."
    );

    console.log(
      "Existing Mentor passwords were preserved."
    );
  }

  console.log("\n========================================");

  if (failedCount > 0) {
    console.log(
      "Some mentor records failed. Check the errors above."
    );
  } else {
    console.log(
      "All mentor records processed successfully."
    );
  }

  console.log("========================================\n");
}

main().catch((error) => {
  console.error("\n========================================");
  console.error("MENTOR IMPORT FAILED");
  console.error("========================================");
  console.error(error.message);
  console.error("========================================\n");

  process.exit(1);
});