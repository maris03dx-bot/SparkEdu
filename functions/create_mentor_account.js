const { initializeApp } = require("firebase-admin/app");
const {
  getAuth,
  EmailAlreadyExistsError,
} = require("firebase-admin/auth");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");
const readline = require("readline");

// Initialize Firebase Admin
initializeApp();

const auth = getAuth();
const db = getFirestore();

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function generateTemporaryPassword() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

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

async function createMentorAccount(email) {
  try {
    email = email.trim().toLowerCase();

    if (!isValidEmail(email)) {
      throw new Error("Invalid email address.");
    }

    console.log("\nSearching for mentor profile...");

    // Find mentor profile in Firestore
    const snapshot = await db
      .collection("users")
      .where("email", "==", email)
      .where("role", "==", "Mentor")
      .get();

    if (snapshot.empty) {
      throw new Error(
        `No Mentor profile found in users collection for ${email}.`
      );
    }

    if (snapshot.size > 1) {
      throw new Error(
        `Multiple Mentor profiles found for ${email}. Please remove the duplicate first.`
      );
    }

    const mentorDoc = snapshot.docs[0];
    const mentorData = mentorDoc.data();

    const mentorName = (mentorData.name || "Mentor").toString();

    console.log(`Mentor found: ${mentorName}`);
    console.log(`Employee ID: ${mentorData.employeeId || "N/A"}`);
    console.log(`Department: ${mentorData.department || "N/A"}`);
    console.log(`Year: ${mentorData.year || "N/A"}`);
    console.log(`Section: ${mentorData.section || "N/A"}`);

    // Check whether Firebase Authentication account already exists
    let existingAuthUser = null;

    try {
      existingAuthUser = await auth.getUserByEmail(email);
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
    }

    // ---------------------------------------------------------
    // CASE 1: Firebase Auth account already exists
    // ---------------------------------------------------------
    if (existingAuthUser) {
      console.log("\nFirebase Authentication account already exists.");

      await mentorDoc.ref.update({
        uid: existingAuthUser.uid,
        accountStatus: "Active",
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log("Firestore mentor profile updated.");
      console.log(`Firebase UID: ${existingAuthUser.uid}`);
      console.log("\nPassword was NOT changed.");
      console.log("Use the existing mentor password.");

      return;
    }

    // ---------------------------------------------------------
    // CASE 2: Create new Firebase Auth account
    // ---------------------------------------------------------
    const temporaryPassword = generateTemporaryPassword();

    console.log("\nCreating Firebase Authentication account...");

    const authUser = await auth.createUser({
      email: email,
      password: temporaryPassword,
      displayName: mentorName,
      emailVerified: false,
    });

    // Update Firestore mentor profile with actual Firebase Auth UID
    await mentorDoc.ref.update({
      uid: authUser.uid,
      accountStatus: "Active",
      mustChangePassword: true,
      passwordStatus: "Temporary",
      passwordCreatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log("\n========================================");
    console.log("MENTOR ACCOUNT CREATED SUCCESSFULLY");
    console.log("========================================");
    console.log(`Name       : ${mentorName}`);
    console.log(`Email      : ${email}`);
    console.log(`Employee ID: ${mentorData.employeeId || "N/A"}`);
    console.log(`Firebase UID: ${authUser.uid}`);
    console.log("----------------------------------------");
    console.log(`TEMP PASSWORD: ${temporaryPassword}`);
    console.log("----------------------------------------");
    console.log("Give this temporary password privately");
    console.log("to the mentor.");
    console.log("The password is NOT stored in Firestore.");
    console.log("Mentor must change the password after login.");
    console.log("========================================\n");
  } catch (error) {
    console.error("\nFailed to create mentor account.");

    if (error.code) {
      console.error(`Error code: ${error.code}`);
    }

    console.error(`Error: ${error.message}`);
  }
}

async function main() {
  let email = process.argv[2];

  if (!email) {
    email = await askQuestion(
      "Enter the Mentor email address: "
    );
  }

  await createMentorAccount(email);
}

main();