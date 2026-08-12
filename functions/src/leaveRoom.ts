import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

export async function handleLeaveRoom(
  request: CallableRequest<{ roomId: string }>
): Promise<{ success: boolean }> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const uid = request.auth.uid;
  const { roomId } = request.data;

  if (!roomId) {
    throw new HttpsError('invalid-argument', 'roomId is required.');
  }

  const db = admin.firestore();
  const rtdb = admin.database();

  await db.collection(`rooms/${roomId}/members`).doc(uid).delete();
  await rtdb.ref(`roomAccess/${roomId}/members/${uid}`).remove();
  await rtdb.ref(`presence/${roomId}/${uid}`).remove();

  return { success: true };
}
