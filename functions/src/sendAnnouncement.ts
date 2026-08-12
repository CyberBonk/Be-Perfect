import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import { FeedEvent, NotificationOutboxRecord, Room, SendAnnouncementRequest } from './types';

export async function handleSendAnnouncement(
  request: CallableRequest<SendAnnouncementRequest>
): Promise<{ eventId: string }> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const uid = request.auth.uid;
  const { roomId, clientCommandId, body, notifyDevices = true } = request.data;

  if (!roomId || !body) {
    throw new HttpsError('invalid-argument', 'roomId and announcement body are required.');
  }

  const trimmedBody = body.trim();
  if (trimmedBody.length < 1 || trimmedBody.length > 500) {
    throw new HttpsError('invalid-argument', 'Announcement body must be between 1 and 500 characters.');
  }

  const db = admin.firestore();
  const roomRef = db.collection('rooms').doc(roomId);

  const eventId = clientCommandId || db.collection(`rooms/${roomId}/feed`).doc().id;

  await db.runTransaction(async (tx) => {
    const roomSnap = await tx.get(roomRef);
    if (!roomSnap.exists) {
      throw new HttpsError('not-found', 'Room not found.');
    }
    const room = roomSnap.data() as Room;

    if (room.ownerUid !== uid) {
      throw new HttpsError('permission-denied', 'Only the room owner can send announcements.');
    }

    if (room.state === 'closed') {
      throw new HttpsError('failed-precondition', 'Cannot send announcements in a closed room.');
    }

    const now = Date.now();
    const feedDoc: FeedEvent = {
      eventId,
      type: 'announcement',
      senderUid: uid,
      title: 'G-man Announcement',
      body: trimmedBody,
      notifyDevices,
      timestamp: now,
    };

    tx.set(db.collection(`rooms/${roomId}/feed`).doc(eventId), feedDoc);

    if (notifyDevices) {
      const membersSnap = await tx.get(db.collection(`rooms/${roomId}/members`));
      const recipientUids = membersSnap.docs.map(d => d.id).filter(id => id !== uid);

      const outboxDoc: NotificationOutboxRecord = {
        eventId,
        roomId,
        runId: room.activeRunId || undefined,
        revision: room.revision,
        title: feedDoc.title,
        body: feedDoc.body,
        recipientUids,
        createdAt: now,
        processedAt: null,
      };

      tx.set(db.collection('notificationOutbox').doc(eventId), outboxDoc);
    }
  });

  return { eventId };
}
