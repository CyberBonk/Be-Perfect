import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { NotificationOutboxRecord } from './types';

export const handleOutboxCreated = onDocumentCreated(
  {
    document: 'notificationOutbox/{eventId}',
    region: 'europe-west1',
    maxInstances: 5,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const record = snap.data() as NotificationOutboxRecord;
    if (record.processedAt) return; // Already processed

    const db = admin.firestore();
    const messaging = admin.messaging();

    const { roomId, runId, revision, eventId, title, body, data, recipientUids } = record;

    if (!recipientUids || recipientUids.length === 0) {
      await snap.ref.update({ processedAt: Date.now(), notes: 'No recipients' });
      return;
    }

    // Collect all valid FCM tokens for recipient members
    const tokensWithUids: { uid: string; token: string }[] = [];

    for (const uid of recipientUids) {
      const memberSnap = await db.collection(`rooms/${roomId}/members`).doc(uid).get();
      if (memberSnap.exists) {
        const tokens: string[] = memberSnap.data()?.fcmTokens || [];
        for (const token of tokens) {
          tokensWithUids.push({ uid, token });
        }
      }
    }

    if (tokensWithUids.length === 0) {
      await snap.ref.update({ processedAt: Date.now(), notes: 'No tokens found' });
      return;
    }

    const payloadData: Record<string, string> = {
      eventId,
      roomId,
      runId: runId || '',
      revision: revision.toString(),
      ...(data || {}),
    };

    const tokens = tokensWithUids.map(t => t.token);
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: payloadData,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'be_perfect_announcements_v1',
        },
      },
    });

    // Clean up invalid or unregistered tokens
    const invalidTokensByUid = new Map<string, string[]>();
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error) {
        const code = resp.error.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          const item = tokensWithUids[idx];
          const list = invalidTokensByUid.get(item.uid) || [];
          list.push(item.token);
          invalidTokensByUid.set(item.uid, list);
        }
      }
    });

    for (const [uid, badTokens] of invalidTokensByUid.entries()) {
      const memberRef = db.collection(`rooms/${roomId}/members`).doc(uid);
      const mSnap = await memberRef.get();
      if (mSnap.exists) {
        const currentTokens: string[] = mSnap.data()?.fcmTokens || [];
        const filtered = currentTokens.filter(t => !badTokens.includes(t));
        await memberRef.update({ fcmTokens: filtered });
      }
    }

    await snap.ref.update({
      processedAt: Date.now(),
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
);
