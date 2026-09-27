const admin = require("firebase-admin");

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    "ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set."
  );
  console.error(
    "Set it to your Firebase Admin SDK service-account JSON file first."
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function createSecurityProfiles() {
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

    const uid = String(data.uid || doc.id).trim();
    const role = String(data.role || "").trim();

    if (!uid || !role) {
      console.log(
        `SKIPPED ${doc.id}: missing uid or role`
      );
      skipped++;
      continue;
    }

    const profile = {
      uid,
      role,
      department: String(data.department || "").trim(),
      year: String(data.year || "").trim(),
      section: String(data.section || "").trim(),
      className: String(data.className || "").trim(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const profileRef = db
      .collection("security_profiles")
      .doc(uid);

    batch.set(
      profileRef,
      profile,
      { merge: true }
    );

    console.log(
      `Prepared: ${uid} -> ${role}`
    );

    created++;
  }

  if (created > 0) {
    await batch.commit();
  }

  console.log("");
  console.log("======================================");
  console.log("Security profile migration completed");
  console.log("======================================");
  console.log(`Profiles created/updated: ${created}`);
  console.log(`Users skipped: ${skipped}`);
}

createSecurityProfiles().catch((error) => {
  console.error("");
  console.error("Migration failed:");
  console.error(error);
  process.exit(1);
});