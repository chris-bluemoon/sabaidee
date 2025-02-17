const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();

exports.checkInStatusUpdate = functions.firestore.document('users/{userId}/checkInTimes/{checkInTimeId}')
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // Check if the status has changed to "missed"
        if (beforeData.status !== 'missed' && afterData.status === 'missed') {
            const userId = context.params.userId;

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
