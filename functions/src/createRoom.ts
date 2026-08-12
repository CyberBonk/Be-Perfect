import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import { CreateRoomRequest, CreateRoomResponse, Room } from './types';

function generateSixDigitPin(): string {
  const num = Math.floor(100000 + Math.random() * 900000);
  return num.toString();
}

export async function handleCreateRoom(
  request: CallableRequest<CreateRoomRequest>
): Promise<CreateRoomResponse> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated to create a room.');
  }

  const ownerUid = request.auth.uid;
  const capacity = request.data?.sectorCapacity ?? null;

  if (capacity !== null && (!Number.isInteger(capacity) || capacity < 1)) {
    throw new HttpsError('invalid-argument', 'Participant capacity must be a positive whole number when provided.');
  }

  const db = admin.firestore();
  const rtdb = admin.database();

  let pin = '';
  let roomId = '';
  let attempts = 0;
  const maxAttempts = 10;

  while (attempts < maxAttempts) {
    pin = generateSixDigitPin();
    roomId = db.collection('rooms').doc().id;

    const codeRef = db.collection('roomCodes').doc(pin);
    const roomRef = db.collection('rooms').doc(roomId);

    try {
      await db.runTransaction(async (tx) => {
        const codeSnap = await tx.get(codeRef);
        if (codeSnap.exists) {
          throw new Error('PIN_COLLISION');
        }

        const now = Date.now();
        const newRoom: Room = {
          roomId,
          ownerUid,
          state: 'lobby',
          sectorCapacity: capacity,
          activeRunId: null,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        };

        tx.set(codeRef, { roomId, createdAt: now });
        tx.set(roomRef, newRoom);
      });

      // Transaction succeeded
      await rtdb.ref(`roomAccess/${roomId}/ownerUid`).set(ownerUid);
      return { roomId, pin };
    } catch (err: any) {
      if (err.message === 'PIN_COLLISION') {
        attempts++;
        continue;
      }
      throw new HttpsError('internal', `Failed to create room: ${err.message}`);
    }
  }

  throw new HttpsError('resource-exhausted', 'Failed to allocate a unique room PIN after multiple attempts.');
}
