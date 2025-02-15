const functions = require('firebase-functions/v1');
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
      const missedDateTime = new Date(checkInDateTime.getTime() + 5*60000);
      if ((checkInTime.status === 'open' || checkInTime.status === 'pending') && now > missedDateTime) {
        checkInTime.status = 'missed';
      }
      if (checkInTime.status === 'pending' && now <= missedDateTime && now >= checkInDateTime) {
        checkInTime.status = 'open';
      }
      return checkInTime;
    });

    await admin.firestore().collection('users').doc(userDoc.id).update({
      checkInTimes: updatedCheckInTimes
    });
  });

  return null;
});
