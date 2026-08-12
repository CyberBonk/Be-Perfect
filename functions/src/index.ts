import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';

admin.initializeApp();

import { handleCreateRoom } from './createRoom';
import { handleJoinRoom } from './joinRoom';
import { handleStartRun } from './startRun';
import { handleApplyRoomCommand } from './applyRoomCommand';
import { handleSendAnnouncement } from './sendAnnouncement';
import { handleUpdateMember } from './updateMember';
import { handleLeaveRoom } from './leaveRoom';
import { handleRemoveMember } from './removeMember';
import { handleCloseRoom } from './closeRoom';
import { handleOutboxCreated } from './outboxTrigger';

const opts = {
  region: 'europe-west1',
  maxInstances: 10,
};

export const createRoom = onCall(opts, (req) => handleCreateRoom(req));
export const joinRoom = onCall(opts, (req) => handleJoinRoom(req));
export const startRun = onCall(opts, (req) => handleStartRun(req));
export const applyRoomCommand = onCall(opts, (req) => handleApplyRoomCommand(req));
export const sendAnnouncement = onCall(opts, (req) => handleSendAnnouncement(req));
export const updateMember = onCall(opts, (req) => handleUpdateMember(req));
export const leaveRoom = onCall(opts, (req) => handleLeaveRoom(req));
export const removeMember = onCall(opts, (req) => handleRemoveMember(req));
export const closeRoom = onCall(opts, (req) => handleCloseRoom(req));
export const onOutboxCreated = handleOutboxCreated;
