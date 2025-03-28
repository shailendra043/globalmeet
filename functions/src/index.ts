import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendNotification = functions.https.onCall(async (data, context) => {
  // Check if the request is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const { token, title, body, type, data: notificationData } = data;

  if (!token || !title || !body || !type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  const message = {
    notification: {
      title,
      body,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    data: {
      type,
      ...notificationData,
    },
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending message:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error sending notification'
    );
  }
}); 