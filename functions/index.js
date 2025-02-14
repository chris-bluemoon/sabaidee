const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.scheduledCheckInStatusUpdate = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now().toDate();
  const usersSnapshot = await admin.firestore().collection('users').get();

  usersSnapshot.forEach(async (userDoc) => {
    const userData = userDoc.data();
    const checkInTimes = userData.checkInTimes;

    const updatedCheckInTimes = checkInTimes.map(checkInTime => {
      const checkInDateTime = new Date(checkInTime.dateTime);
      if ((checkInTime.status === 'open' || checkInTime.status === 'pending') && now > checkInDateTime) {
        checkInTime.status = 'missed';
      }
      return checkInTime;
    });

    await admin.firestore().collection('users').doc(userDoc.id).update({
      checkInTimes: updatedCheckInTimes
    });
  });

  return null;
});
