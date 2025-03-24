const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();
const firestore = admin.firestore();

exports.scheduledCheckInStatusUpdate = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now().toDate();
  const usersSnapshot = await firestore.collection('users').get();

  usersSnapshot.forEach(async (userDoc) => {
    const userData = userDoc.data();
    const checkInTimes = userData.checkInTimes;

    const updatedCheckInTimes = checkInTimes.map(checkInTime => {
      const checkInDateTime = new Date(checkInTime.dateTime);
      const missedDateTime = new Date(checkInDateTime.getTime() + checkInTime.duration * 60000); // Use duration from checkInTime
      if ((checkInTime.status === 'open' || checkInTime.status === 'pending') && now > missedDateTime) {
        checkInTime.status = 'missed';
        // Add another check-in time 24 hours in the future
        const newCheckInTime = {
          dateTime: new Date(checkInDateTime.getTime() + 24 * 60 * 60000).toISOString(),
          status: 'pending',
          duration: checkInTime.duration // Assuming duration is part of the check-in time object
        };
        checkInTimes.push(newCheckInTime);

        if (userData.fcmToken) {
          const notificationBody = userData.followers && Array.isArray(userData.followers) && userData.followers.length > 0
            ? "You missed a check-in, your followers have been notified."
            : "You missed a check-in, but have no followers, add a follower for future alerts.";

          const payload = {
            notification: {
              title: 'Check-In Missed!',
              body: notificationBody,
            },
            token: userData.fcmToken,
            data: {
              status: 'missed',
            },
          };
          admin.messaging().send(payload)
            .then(response => {
              console.log('Notification sent successfully:', response);
            })
            .catch(error => {
              console.log('Error sending notification:', error);
            });
        }

        // Notify followers
        if (userData.followers && Array.isArray(userData.followers)) {
          userData.followers.forEach(async follower => {
            if (follower.uid && typeof follower.uid === 'string' && follower.uid.trim() !== '') {
              const followerDoc = await firestore.collection('users').doc(follower.uid).get();
              if (followerDoc.exists) {
                const followerData = followerDoc.data();
                if (followerData.fcmToken) {
                  const followerPayload = {
                    notification: {
                      title: `${userData.name} missed a check-in.`,
                      body: `Please check in on them!`,
                    },
                    token: followerData.fcmToken,
                    data: {
                      status: 'missed',
                    },
                  };
                  admin.messaging().send(followerPayload)
                    .then(response => {
                      console.log('follower notification sent successfully:', response);
                    })
                    .catch(error => {
                      console.log('Error sending follower notification:', error);
                    });
                }
              }
            } else {
              console.log('Invalid follower ID:', follower.uid);
            }
          });
        }
      }
      if (checkInTime.status === 'pending' && now <= missedDateTime && now >= checkInDateTime) {
        checkInTime.status = 'open';

        // Send FCM notification to update user status
        if (userData.fcmToken) {
          const notificationBody = userData.followers && Array.isArray(userData.followers) && userData.followers.length > 0
            ? 'Please check in now!'
            : 'Check in now and add some followers so they can be alerted to any future missed check-ins.';

          const payload = {
            notification: {
              title: 'Check-In Reminder!',
              body: notificationBody,
            },
            token: userData.fcmToken,
            data: {
              status: 'open',
            },
          };
          admin.messaging().send(payload)
            .then(response => {
              console.log('Notification sent successfully:', response);
            })
            .catch(error => {
              console.log('Error sending notification:', error);
            });
        }
      }
      return checkInTime;
    });

    await firestore.collection('users').doc(userDoc.id).update({
      checkInTimes: checkInTimes,
    });
  });

  return null;
});