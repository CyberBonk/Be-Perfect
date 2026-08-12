import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

export async function handleRemoveMember(
  request: CallableRequest<{ roomId: string; targetUid: string }>
): Promise<{ success: boolean }> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const uid = request.auth.uid;
  const { roomId, targetUid } = request.data;

  if (!roomId || !targetUid) {
    throw new HttpsError('invalid-argument', 'roomId and targetUid are required.');
  }

  const db = admin.firestore();
  const rtdb = admin.database();

  const roomSnap = await db.collection('rooms').doc(roomId).get();
  if (!roomSnap.exists || roomSnap.data()?.ownerUid !== uid) {
    throw new HttpsError('permission-denied', 'Only the room owner can remove members.');
  }

  await db.collection(`rooms/${roomId}/members`).doc(targetUid).delete();
  await rtdb.ref(`roomAccess/${roomId}/members/${targetUid}`).remove();
  await rtdb.ref(`presence/${roomId}/${targetUid}`).remove();

  return { success: true };
}
