import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import { JoinRoomRequest, JoinRoomResponse, Member, Room } from './types';

export async function handleJoinRoom(
  request: CallableRequest<JoinRoomRequest>
): Promise<JoinRoomResponse> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated to join a room.');
  }

  const uid = request.auth.uid;
  const { code, sectorName, notificationReadiness, exactAlarmReadiness, selectedSoundMode, fcmToken } = request.data;

  if (!code || !/^\d{6}$/.test(code.trim())) {
    throw new HttpsError('invalid-argument', 'Join code must be exactly 6 numeric digits.');
  }

  const trimmedSectorName = (sectorName || '').trim();
  if (trimmedSectorName.length < 1 || trimmedSectorName.length > 30) {
    throw new HttpsError('invalid-argument', 'Participant name must be 1 to 30 visible characters.');
  }
  const normalizedSectorName = trimmedSectorName.toLowerCase().replace(/\s+/g, ' ');

  const db = admin.firestore();
  const rtdb = admin.database();

  const codeRef = db.collection('roomCodes').doc(code.trim());
  const codeSnap = await codeRef.get();
  if (!codeSnap.exists) {
    throw new HttpsError('not-found', 'Invalid room PIN code.');
  }

  const roomId = codeSnap.data()?.roomId;
  if (!roomId) {
    throw new HttpsError('not-found', 'Room not found for PIN.');
  }

  const roomRef = db.collection('rooms').doc(roomId);
  const membersRef = roomRef.collection('members');

  await db.runTransaction(async (tx) => {
    const roomSnap = await tx.get(roomRef);
    if (!roomSnap.exists) {
      throw new HttpsError('not-found', 'Room does not exist.');
    }
    const room = roomSnap.data() as Room;

    if (room.state === 'closed') {
      throw new HttpsError('failed-precondition', 'This room is closed and no longer accepting members.');
    }

    const allMembersSnap = await tx.get(membersRef);
    const existingMembers = allMembersSnap.docs.map(d => d.data() as Member);

    // Participant-name uniqueness (case-insensitive & whitespace normalized)
    const nameCollision = existingMembers.some(
      m => m.uid !== uid && m.normalizedSectorName === normalizedSectorName
    );
    if (nameCollision) {
      throw new HttpsError('already-exists', `The participant name "${trimmedSectorName}" is already taken in this room.`);
    }

    const existingMember = existingMembers.find(m => m.uid === uid);
    let tokens = existingMember?.fcmTokens || [];
    if (fcmToken && !tokens.includes(fcmToken)) {
      tokens = [...tokens, fcmToken];
    }

    const now = Date.now();
    const memberDoc: Member = {
      uid,
      sectorName: trimmedSectorName,
      normalizedSectorName,
      joinedAt: existingMember?.joinedAt ?? now,
      updatedAt: now,
      notificationReadiness: notificationReadiness ?? false,
      exactAlarmReadiness: exactAlarmReadiness ?? false,
      selectedSoundMode: selectedSoundMode || 'be_perfect_sound',
      fcmTokens: tokens,
    };

    tx.set(membersRef.doc(uid), memberDoc, { merge: true });
  });

  // Mirror membership to RTDB for presence security checks
  await rtdb.ref(`roomAccess/${roomId}/members/${uid}`).set(true);

  return { roomId, sectorName: trimmedSectorName };
}
