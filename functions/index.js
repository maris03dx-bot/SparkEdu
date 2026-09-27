const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");

const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const logger = require("firebase-functions/logger");

// ============================================================
// FIREBASE ADMIN
// ============================================================

initializeApp();

const db = getFirestore();

// ============================================================
// GLOBAL SETTINGS
// ============================================================

setGlobalOptions({
  maxInstances: 10,
  region: "asia-south1",
});

// ============================================================
// MSG91 SECRETS
//
// These will NOT be stored inside Flutter or source code.
// We will configure them later.
// ============================================================

const MSG91_AUTH_KEY = defineSecret("MSG91_AUTH_KEY");
const MSG91_TEMPLATE_ID = defineSecret("MSG91_TEMPLATE_ID");
const MSG91_SENDER_ID = defineSecret("MSG91_SENDER_ID");

// ============================================================
// NORMALIZE INDIAN PHONE NUMBER
// ============================================================

function normalizeIndianPhone(phone) {
  if (!phone) {
    return null;
  }

  let value = phone.toString().trim();

  // Remove spaces, brackets, hyphens, etc.
  value = value.replace(/[^\d+]/g, "");

  // +91XXXXXXXXXX
  if (value.startsWith("+91") && value.length === 13) {
    return value.substring(1);
  }

  // 91XXXXXXXXXX
  if (value.startsWith("91") && value.length === 12) {
    return value;
  }

  // 0XXXXXXXXXX
  if (value.startsWith("0") && value.length === 11) {
    return "91" + value.substring(1);
  }

  // XXXXXXXXXX
  if (value.length === 10) {
    return "91" + value;
  }

  return null;
}

// ============================================================
// FIND STUDENT
// ============================================================

async function findStudent(studentId) {
  if (!studentId) {
    return null;
  }

  const studentIdString = studentId.toString();

  // ----------------------------------------------------------
  // Search by registerNo
  // ----------------------------------------------------------

  const registerQuery = await db
      .collection("users")
      .where("role", "==", "Student")
      .where("registerNo", "==", studentIdString)
      .limit(1)
      .get();

  if (!registerQuery.empty) {
    return registerQuery.docs[0];
  }

  // ----------------------------------------------------------
  // Search by rollNo
  // ----------------------------------------------------------

  const rollQuery = await db
      .collection("users")
      .where("role", "==", "Student")
      .where("rollNo", "==", studentIdString)
      .limit(1)
      .get();

  if (!rollQuery.empty) {
    return rollQuery.docs[0];
  }

  return null;
}

// ============================================================
// SEND SMS THROUGH MSG91
// ============================================================

async function sendParentSMS({
  parentPhone,
  studentName,
  subject,
  date,
}) {
  const authKey = MSG91_AUTH_KEY.value();
  const templateId = MSG91_TEMPLATE_ID.value();
  const senderId = MSG91_SENDER_ID.value();

  const mobile = normalizeIndianPhone(parentPhone);

  if (!mobile) {
    throw new Error("Invalid parent phone number.");
  }

  if (!authKey) {
    throw new Error("MSG91_AUTH_KEY is not configured.");
  }

  if (!templateId) {
    throw new Error("MSG91_TEMPLATE_ID is not configured.");
  }

  if (!senderId) {
    throw new Error("MSG91_SENDER_ID is not configured.");
  }

  // ----------------------------------------------------------
  // MSG91 FLOW REQUEST
  //
  // IMPORTANT:
  // The variable names below must match the variables
  // configured in your approved MSG91/DLT template.
  // ----------------------------------------------------------

  const payload = {
    template_id: templateId,
    short_url: "0",

    recipients: [
      {
        mobiles: mobile,

        VAR1: studentName,
        VAR2: subject,
        VAR3: date,
      },
    ],
  };

  const response = await fetch(
      "https://control.msg91.com/api/v5/flow",
      {
        method: "POST",

        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "authkey": authKey,
        },

        body: JSON.stringify(payload),
      },
  );

  let responseData;

  try {
    responseData = await response.json();
  } catch (_) {
    responseData = {
      message: await response.text(),
    };
  }

  logger.info("MSG91 response", {
    responseData,
    mobile,
  });

  if (!response.ok) {
    throw new Error(
        `MSG91 HTTP ${response.status}: ${
          responseData.message || "SMS request failed"
        }`,
    );
  }

  if (
    responseData.type &&
    responseData.type.toString().toLowerCase() === "error"
  ) {
    throw new Error(
        responseData.message || "MSG91 rejected the SMS request.",
    );
  }

  return responseData;
}

// ============================================================
// ATTENDANCE ABSENT TRIGGER
// ============================================================
//
// This runs automatically whenever a new attendance document
// is created.
//
// Path:
// attendance/{attendanceId}
// ============================================================

exports.sendAbsentParentSMS = onDocumentCreated(
    {
      document: "attendance/{attendanceId}",

      secrets: [
        MSG91_AUTH_KEY,
        MSG91_TEMPLATE_ID,
        MSG91_SENDER_ID,
      ],
    },

    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        logger.warn("No attendance document found.");
        return;
      }

      const attendanceData = snapshot.data();

      // --------------------------------------------------------
      // ONLY PROCESS ABSENT RECORDS
      // --------------------------------------------------------

      const status = attendanceData.status
          ?.toString()
          .toLowerCase()
          .trim();

      if (status !== "absent") {
        logger.info(
            "Attendance is not Absent. SMS not required.",
            {
              attendanceId: event.params.attendanceId,
              status,
            },
        );

        return;
      }

      const studentId =
          attendanceData.studentId?.toString();

      const studentName =
          attendanceData.studentName?.toString() ||
          "Student";

      const subject =
          attendanceData.subject?.toString() ||
          "Class";

      const date =
          attendanceData.date?.toString() ||
          "";

      // --------------------------------------------------------
      // CREATE SMS TRACKING DOCUMENT
      // --------------------------------------------------------

      const notificationRef = db
          .collection("sms_notifications")
          .doc(event.params.attendanceId);

      // --------------------------------------------------------
      // FIND STUDENT
      // --------------------------------------------------------

      try {
        const studentDoc = await findStudent(studentId);

        if (!studentDoc) {
          await notificationRef.set({
            attendanceId:
                event.params.attendanceId,

            studentId,
            studentName,
            subject,
            date,

            type: "Absent Parent SMS",

            status: "failed",

            failureReason:
                "Student record not found in users collection.",

            createdAt:
                FieldValue.serverTimestamp(),

            updatedAt:
                FieldValue.serverTimestamp(),
          });

          logger.error(
              "Student not found.",
              {
                studentId,
              },
          );

          return;
        }

        const studentData = studentDoc.data();

        // ------------------------------------------------------
        // GET PARENT PHONE
        // ------------------------------------------------------

        const parentPhone =
            studentData.parentPhone?.toString();

        if (!parentPhone) {
          await notificationRef.set({
            attendanceId:
                event.params.attendanceId,

            studentId,
            studentName,
            subject,
            date,

            type: "Absent Parent SMS",

            status: "failed",

            failureReason:
                "parentPhone is missing from student record.",

            createdAt:
                FieldValue.serverTimestamp(),

            updatedAt:
                FieldValue.serverTimestamp(),
          });

          logger.error(
              "Parent phone missing.",
              {
                studentId,
              },
          );

          return;
        }

        // ------------------------------------------------------
        // SAVE PENDING STATUS
        // ------------------------------------------------------

        await notificationRef.set({
          attendanceId:
              event.params.attendanceId,

          studentId,

          studentName,

          subject,

          date,

          parentPhone,

          type: "Absent Parent SMS",

          status: "sending",

          createdAt:
              FieldValue.serverTimestamp(),

          updatedAt:
              FieldValue.serverTimestamp(),
        });

        // ------------------------------------------------------
        // SEND SMS
        // ------------------------------------------------------

        const smsResponse = await sendParentSMS({
          parentPhone,
          studentName,
          subject,
          date,
        });

        // ------------------------------------------------------
        // SUCCESS
        // ------------------------------------------------------

        await notificationRef.update({
          status: "sent",

          provider: "MSG91",

          providerResponse: smsResponse,

          sentAt:
              FieldValue.serverTimestamp(),

          updatedAt:
              FieldValue.serverTimestamp(),
        });

        logger.info(
            "Absent parent SMS request successful.",
            {
              studentId,
              studentName,
              subject,
            },
        );
      } catch (error) {
        // ------------------------------------------------------
        // FAILURE
        // ------------------------------------------------------

        logger.error(
            "Failed to send absent parent SMS.",
            {
              attendanceId:
                  event.params.attendanceId,

              studentId,

              error:
                  error.message,
            },
        );

        await notificationRef.set(
            {
              attendanceId:
                  event.params.attendanceId,

              studentId,

              studentName,

              subject,

              date,

              type:
                  "Absent Parent SMS",

              status:
                  "failed",

              failureReason:
                  error.message ||
                  "Unknown SMS error.",

              failedAt:
                  FieldValue.serverTimestamp(),

              updatedAt:
                  FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            },
        );

        // We intentionally don't throw again.
        //
        // Attendance must remain successfully recorded
        // even if SMS delivery fails.
      }
    },
);