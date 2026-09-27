const { initializeApp } = require("firebase-admin/app");

const {
  getAuth,
} = require("firebase-admin/auth");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const readline = require("readline");

// ============================================================
// FIREBASE ADMIN
// ============================================================

initializeApp();

const auth = getAuth();
const db = getFirestore();

// ============================================================
// VALIDATE EMAIL
// ============================================================

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// ============================================================
// GENERATE TEMPORARY PASSWORD
// ============================================================

function generateTemporaryPassword() {
  return Math.floor(
    100000 + Math.random() * 900000
  ).toString();
}

// ============================================================
// ASK QUESTION
// ============================================================

function askQuestion(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// ============================================================
// CREATE SUBJECT TEACHER ACCOUNT
// ============================================================

async function createSubjectTeacherAccount(email) {
  try {
    email = email.trim().toLowerCase();

    if (!isValidEmail(email)) {
      throw new Error(
        "Invalid email address."
      );
    }

    console.log(
      "\nSearching for Subject Teacher profile..."
    );

    const snapshot = await db
      .collection("users")
      .where("email", "==", email)
      .where(
        "role",
        "==",
        "Subject Teacher"
      )
      .get();

    // --------------------------------------------------------
    // PROFILE NOT FOUND
    // --------------------------------------------------------

    if (snapshot.empty) {
      throw new Error(
        `No Subject Teacher profile found in users collection for ${email}.`
      );
    }

    // --------------------------------------------------------
    // DUPLICATE PROFILE
    // --------------------------------------------------------

    if (snapshot.size > 1) {
      throw new Error(
        `Multiple Subject Teacher profiles found for ${email}. Please remove the duplicate first.`
      );
    }

    const teacherDoc = snapshot.docs[0];
    const teacherData =
        teacherDoc.data();

    const teacherName =
        (teacherData.name || "Subject Teacher")
            .toString()
            .trim();

    console.log(
      `Teacher found: ${teacherName}`
    );

    console.log(
      `Employee ID: ${
        teacherData.employeeId || "N/A"
      }`
    );

    console.log(
      `Department: ${
        teacherData.department || "N/A"
      }`
    );

    console.log(
      `Designation: ${
        teacherData.designation || "N/A"
      }`
    );

    // ========================================================
    // CHECK EXISTING FIREBASE AUTH ACCOUNT
    // ========================================================

    let existingAuthUser = null;

    try {
      existingAuthUser =
          await auth.getUserByEmail(email);
    } catch (error) {
      if (
        error.code !==
        "auth/user-not-found"
      ) {
        throw error;
      }
    }

    // ========================================================
    // EXISTING AUTH ACCOUNT
    // ========================================================

    if (existingAuthUser) {
      console.log(
        "\nFirebase Authentication account already exists."
      );

      await teacherDoc.ref.update({
        uid: existingAuthUser.uid,
        accountStatus: "Active",
        updatedAt:
            FieldValue.serverTimestamp(),
      });

      console.log(
        "Firestore teacher profile updated."
      );

      console.log(
        `Firebase UID: ${existingAuthUser.uid}`
      );

      console.log(
        "\nPassword was NOT changed."
      );

      console.log(
        "Use the existing teacher password."
      );

      return;
    }

    // ========================================================
    // NEW AUTH ACCOUNT
    // ========================================================

    const temporaryPassword =
        generateTemporaryPassword();

    console.log(
      "\nCreating Firebase Authentication account..."
    );

    const authUser =
        await auth.createUser({
      email: email,
      password: temporaryPassword,
      displayName: teacherName,
      emailVerified: false,
    });

    // ========================================================
    // UPDATE FIRESTORE PROFILE
    // ========================================================

    await teacherDoc.ref.update({
      uid: authUser.uid,

      role: "Subject Teacher",

      accountStatus: "Active",

      mustChangePassword: true,

      passwordStatus: "Temporary",

      passwordCreatedAt:
          FieldValue.serverTimestamp(),

      updatedAt:
          FieldValue.serverTimestamp(),
    });

    // ========================================================
    // SUCCESS
    // ========================================================

    console.log(
      "\n========================================"
    );

    console.log(
      "SUBJECT TEACHER ACCOUNT CREATED"
    );

    console.log(
      "========================================"
    );

    console.log(
      `Name       : ${teacherName}`
    );

    console.log(
      `Email      : ${email}`
    );

    console.log(
      `Employee ID: ${
        teacherData.employeeId || "N/A"
      }`
    );

    console.log(
      `Firebase UID: ${authUser.uid}`
    );

    console.log(
      "----------------------------------------"
    );

    console.log(
      `TEMP PASSWORD: ${temporaryPassword}`
    );

    console.log(
      "----------------------------------------"
    );

    console.log(
      "Give this temporary password privately"
    );

    console.log(
      "to the Subject Teacher."
    );

    console.log(
      "The password is NOT stored in Firestore."
    );

    console.log(
      "Teacher must change the password after login."
    );

    console.log(
      "========================================\n"
    );
  } catch (error) {
    console.error(
      "\nFailed to create Subject Teacher account."
    );

    if (error.code) {
      console.error(
        `Error code: ${error.code}`
      );
    }

    console.error(
      `Error: ${error.message}`
    );
  }
}

// ============================================================
// MAIN
// ============================================================

async function main() {
  let email = process.argv[2];

  if (!email) {
    email = await askQuestion(
      "Enter the Subject Teacher email address: "
    );
  }

  await createSubjectTeacherAccount(
    email
  );
}

main();