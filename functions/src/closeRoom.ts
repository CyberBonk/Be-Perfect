import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import { FeedEvent, NotificationOutboxRecord, Room } from './types';

export async function handleCloseRoom(
  request: CallableRequest<{ roomId: string; notifyDevices?: boolean }>
): Promise<{ success: boolean }> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const uid = request.auth.uid;
  const { roomId, notifyDevices = true } = request.data;

  if (!roomId) {
    throw new HttpsError('invalid-argument', 'roomId is required.');
  }

  const db = admin.firestore();
  const rtdb = admin.database();
  const roomRef = db.collection('rooms').doc(roomId);

  await db.runTransaction(async (tx) => {
    const roomSnap = await tx.get(roomRef);
    if (!roomSnap.exists) {
      throw new HttpsError('not-found', 'Room not found.');
    }
    const room = roomSnap.data() as Room;

    if (room.ownerUid !== uid) {
      throw new HttpsError('permission-denied', 'Only the room owner can close the room.');
    }

    if (room.state === 'closed') {
      return;
    }

    const now = Date.now();
    tx.update(roomRef, {
      state: 'closed',
      closedAt: now,
      updatedAt: now,
    });

    const eventId = db.collection(`rooms/${roomId}/feed`).doc().id;
    const feedDoc: FeedEvent = {
      eventId,
      type: 'system_control',
      senderUid: uid,
      title: 'Room Closed',
        body: 'Controller closed this room. Access has been revoked.',
      notifyDevices,
      timestamp: now,
      data: {
        action: 'close_room',
      },
    };

    tx.set(db.collection(`rooms/${roomId}/feed`).doc(eventId), feedDoc);

    if (notifyDevices) {
      const membersSnap = await tx.get(db.collection(`rooms/${roomId}/members`));
      const recipientUids = membersSnap.docs.map(d => d.id).filter(id => id !== uid);

      const outboxDoc: NotificationOutboxRecord = {
        eventId,
        roomId,
        revision: room.revision + 1,
        title: feedDoc.title,
        body: feedDoc.body,
        data: feedDoc.data,
        recipientUids,
        createdAt: now,
        processedAt: null,
      };

      tx.set(db.collection('notificationOutbox').doc(eventId), outboxDoc);
    }
  });

  // Clean up RTDB access mirror & presence for room
  await rtdb.ref(`roomAccess/${roomId}`).remove();
  await rtdb.ref(`presence/${roomId}`).remove();

  return { success: true };
}
