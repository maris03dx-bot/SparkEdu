const admin = require("firebase-admin");

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error("ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set.");
  console.error(
    "Set it to your Firebase Admin SDK service-account JSON file first."
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function createLoginIdentifiers() {
  console.log("Reading users collection...");

  const snapshot = await db.collection("users").get();

  console.log(`Found ${snapshot.size} user documents.`);

  if (snapshot.empty) {
    console.log("No users found. Nothing to do.");
    return;
  }

  const batch = db.batch();

  let created = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const role = String(data.role || "").trim();
    const registerNo = String(data.registerNo || "").trim();
    const email = String(data.email || "").trim();

    /*
     * Only students need Register Number login.
     */
    if (role !== "Student") {
      console.log(
        `SKIPPED ${doc.id}: not a Student account`
      );
      skipped++;
      continue;
    }

    if (!registerNo) {
      console.log(
        `SKIPPED ${doc.id}: missing registerNo`
      );
      skipped++;
      continue;
    }

    if (!email) {
      console.log(
        `SKIPPED ${doc.id}: missing email`
      );
      skipped++;
      continue;
    }

    /*
     * login_identifiers/{registerNo}
     *
     * This collection contains ONLY the information
     * required to convert Register No -> Firebase email.
     */
    const loginRef = db
        .collection("login_identifiers")
        .doc(registerNo);

    batch.set(
      loginRef,
      {
        email: email,
        role: "Student",
        updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        merge: true,
      }
    );

    console.log(
      `Prepared: ${registerNo} -> ${email}`
    );

    created++;
  }

  if (created > 0) {
    await batch.commit();
  }

  console.log("");
  console.log("======================================");
  console.log("Login identifier migration completed");
  console.log("======================================");
  console.log(`Identifiers created/updated: ${created}`);
  console.log(`Users skipped: ${skipped}`);
}

createLoginIdentifiers().catch((error) => {
  console.error("");
  console.error("Migration failed:");
  console.error(error);
  process.exit(1);
});