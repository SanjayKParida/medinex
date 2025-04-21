import { connect } from "./connect.js";
import { disconnect } from "./disconnect.js";
import { sendMessage } from "./sendMessage.js";

export const wsConnect = connect;
export const wsDisconnect = disconnect;
export const wsSendMessage = sendMessage;
