const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.resetTimetableStatus = functions.pubsub.schedule("every day 00:00").onRun(async (context) => {
  const timetablesRef = admin.firestore().collection("timetables");

  try {
    const snapshot = await timetablesRef.get();
    const batch = admin.firestore().batch();

    snapshot.forEach((doc) => {
      batch.update(doc.ref, { status: "upcoming" });
    });

    await batch.commit();
    console.log("Timetable statuses reset to 'upcoming'");
  } catch (error) {
    console.error("Error resetting timetable statuses:", error);
  }
});
