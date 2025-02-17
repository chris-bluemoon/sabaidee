const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.scheduledCheckInStatusUpdate = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const usersSnapshot = await admin.firestore().collection('users').get();
    usersSnapshot.forEach(async (userDoc) => {
        const userId = userDoc.id;
        const checkInTimesSnapshot = await admin.firestore().collection('users').doc(userId).collection('checkInTimes').get();

        checkInTimesSnapshot.forEach(async (checkInTimeDoc) => {
            const checkInTimeData = checkInTimeDoc.data();
            const checkInTime = checkInTimeData.dateTime.toDate();

            if (checkInTime < now.toDate() && (checkInTimeData.status === 'pending' || checkInTimeData.status === 'open')) {
                await admin.firestore().collection('users').doc(userId).collection('checkInTimes').doc(checkInTimeDoc.id).update({
                    status: 'missed'
                });

                // Get the user document
                const userDoc = await admin.firestore().collection('users').doc(userId).get();
                const userData = userDoc.data();

                // Get the list of users that are watching this user
                const watching = userData.watching;

                // Send a notification to each user that is watching
                const payload = {
                    notification: {
                        title: 'Check-In Missed',
                        body: `${userData.name} has missed a check-in.`,
                    },
                };

                const tokens = [];
                for (const watcher of watching) {
                    const watcherDoc = await admin.firestore().collection('users').doc(watcher.uid).get();
                    const watcherData = watcherDoc.data();
                    if (watcherData.fcmToken) {
                        tokens.push(watcherData.fcmToken);
                    }
                }

                if (tokens.length > 0) {
                    await admin.messaging().sendToDevice(tokens, payload);
                    console.log('Notification sent to watchers:', tokens);
                } else {
                    console.log('No FCM tokens found for watchers.');
                }
            }
        });
    });
});
