import express from "express";
import bodyParser from "body-parser";
import { verifyToken } from "../middleware/verify.ts";
import { findUserByUserId } from "../controllers/users.ts";
import {
  ensureChatTables,
  getConversations,
  getMessages,
  sendLocationMessage,
  sendTextMessage,
} from "../controllers/chat.ts";

const chatService = express.Router();

chatService.use(bodyParser.json());

ensureChatTables().catch((err) => {
  console.error("Chat table initialization failed", err);
});

function getAuthenticatedUserId(req: any) {
  // verifyToken middleware injects auth payload into req.body.authData.
  const authData = req.body?.authData;
  return authData?.userId?.toString?.() ?? null;
}

function buildNavigationUrl(latitude: number, longitude: number) {
  return `https://www.google.com/maps/dir/?api=1&destination=${latitude},${longitude}&travelmode=driving`;
}

chatService.get("/conversations", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const conversations = await getConversations(userId);
    return res.status(200).json(conversations);
  } catch {
    return res.status(500).json({ message: "Error loading conversations" });
  }
});

chatService.get("/messages/:otherUserId", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const otherUserId = req.params.otherUserId?.toString();

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!otherUserId) {
    return res.status(400).json({ message: "Missing other user id" });
  }

  if (otherUserId === userId) {
    return res.status(400).json({ message: "Cannot load messages with yourself" });
  }

  try {
    const otherUser = await findUserByUserId(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ message: "Target user not found" });
    }

    const messages = await getMessages(userId, otherUserId);
    return res.status(200).json(messages);
  } catch {
    return res.status(500).json({ message: "Error loading messages" });
  }
});

chatService.post("/messages/:otherUserId", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const otherUserId = req.params.otherUserId?.toString();

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!otherUserId) {
    return res.status(400).json({ message: "Missing other user id" });
  }

  if (otherUserId === userId) {
    return res.status(400).json({ message: "Cannot send message to yourself" });
  }

  try {
    const otherUser = await findUserByUserId(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ message: "Target user not found" });
    }

    const type = (req.body.type ?? "text").toString().toLowerCase();
    // Single endpoint handles both text and location payloads.
    if (type === "location") {
      const latitude = Number(req.body.latitude);
      const longitude = Number(req.body.longitude);
      const text = req.body.text?.toString();

      if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return res.status(400).json({ message: "Invalid latitude/longitude" });
      }

      const message = await sendLocationMessage(userId, otherUserId, latitude, longitude, text);
      return res.status(201).json({
        ...message,
        map_url: buildNavigationUrl(latitude, longitude),
      });
    }

    if (type !== "text") {
      return res.status(400).json({ message: "Unsupported message type" });
    }

    const text = req.body.text?.toString().trim() ?? "";
    if (!text) {
      return res.status(400).json({ message: "Text message cannot be empty" });
    }

    const message = await sendTextMessage(userId, otherUserId, text);
    return res.status(201).json(message);
  } catch {
    return res.status(500).json({ message: "Error sending message" });
  }
});

export default chatService;
