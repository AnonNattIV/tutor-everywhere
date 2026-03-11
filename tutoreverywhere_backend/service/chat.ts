import express from "express";
import bodyParser from "body-parser";
import multer from "multer";
import { verifyToken } from "../middleware/verify.ts";
import { findUserByUserId } from "../controllers/users.ts";
import { uploadImageToObjectStorage } from "../helpers/objectStorage.ts";
import {
  ensureChatTables,
  getConversations,
  getTutorPromptPayPicturePath,
  getMessages,
  sendImageMessage,
  sendLocationMessage,
  sendRequestMoneyMessage,
  sendTextMessage,
  acceptRequestMoney,
} from "../controllers/chat.ts";

const chatService = express.Router();

chatService.use(bodyParser.json());

// Safe to call repeatedly because setup uses IF NOT EXISTS.
ensureChatTables().catch((err) => {
  console.error("Chat table initialization failed", err);
});

const chatImageUpload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      return cb(null, true);
    }

    cb(new Error("Only image files are allowed"));
  },
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

function getAuthenticatedUserId(req: any) {
  // verifyToken middleware injects auth payload into req.body.authData.
  const authData = req.body?.authData;
  return authData?.userId?.toString?.() ?? null;
}

function getAuthenticatedRole(req: any) {
  const authData = req.body?.authData;
  return authData?.role?.toString?.() ?? null;
}

function buildNavigationUrl(latitude: number, longitude: number) {
  return `https://www.google.com/maps/dir/?api=1&destination=${latitude},${longitude}&travelmode=driving`;
}

async function ensureChatPeer(userId: string, otherUserId: string | undefined) {
  if (!otherUserId) {
    return { ok: false, status: 400, body: { message: "Missing other user id" } } as const;
  }

  if (otherUserId === userId) {
    return { ok: false, status: 400, body: { message: "Cannot send message to yourself" } } as const;
  }

  const otherUser = await findUserByUserId(otherUserId);
  if (!otherUser) {
    return { ok: false, status: 404, body: { message: "Target user not found" } } as const;
  }

  return { ok: true } as const;
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

  try {
    const peerCheck = await ensureChatPeer(userId, otherUserId);
    if (!peerCheck.ok) {
      return res.status(peerCheck.status).json(peerCheck.body);
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

chatService.post(
  "/messages/:otherUserId/image",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body?.authData;
    chatImageUpload.single("image")(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res) => {
    const userId = getAuthenticatedUserId(req);
    const otherUserId = req.params.otherUserId?.toString();

    if (!userId) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    try {
      const peerCheck = await ensureChatPeer(userId, otherUserId);
      if (!peerCheck.ok) {
        return res.status(peerCheck.status).json(peerCheck.body);
      }

      const imagePath = await uploadImageToObjectStorage(req.file, "chat");
      const caption = req.body?.text?.toString?.();
      const message = await sendImageMessage(userId, otherUserId, imagePath, caption);
      return res.status(201).json(message);
    } catch (err: any) {
      console.error("Error sending image message", err);
      return res.status(500).json({
        message: err?.message || "Error sending image message",
      });
    }
  },
);

chatService.post("/messages/:otherUserId/request-money", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);
  const otherUserId = req.params.otherUserId?.toString();

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (role !== "tutor") {
    return res.status(403).json({ message: "Only tutor can send request money" });
  }

  try {
    const peerCheck = await ensureChatPeer(userId, otherUserId);
    if (!peerCheck.ok) {
      return res.status(peerCheck.status).json(peerCheck.body);
    }

    const subject = req.body.subject?.toString?.().trim?.() ?? "";
    const amount = Number(req.body.amount);
    const hours = Number(req.body.hours);
    const startAt = req.body.startAt?.toString?.() ?? "";
    const endAt = req.body.endAt?.toString?.() ?? "";
    const dateLabel = req.body.dateLabel?.toString?.() ?? "";
    const locationLabel = req.body.locationLabel?.toString?.() ?? "";
    const placeName = req.body.placeName?.toString?.() ?? "";
    const description = req.body.description?.toString?.() ?? "";
    const latitude = req.body.latitude == null ? null : Number(req.body.latitude);
    const longitude = req.body.longitude == null ? null : Number(req.body.longitude);

    if (!subject || !Number.isFinite(amount) || amount <= 0 || !Number.isFinite(hours) || hours <= 0) {
      return res.status(400).json({ message: "Invalid request money form data" });
    }

    const promptpayPicturePath = await getTutorPromptPayPicturePath(userId);
    if (!promptpayPicturePath) {
      return res.status(400).json({ message: "Please upload PromptPay QR before requesting money" });
    }

    const payload = {
      subject,
      amount,
      hours,
      startAt,
      endAt,
      dateLabel,
      locationLabel,
      placeName,
      description,
      latitude: Number.isFinite(latitude) ? latitude : null,
      longitude: Number.isFinite(longitude) ? longitude : null,
      promptpayPicturePath,
      tutorId: userId,
    };

    const message = await sendRequestMoneyMessage(userId, otherUserId, payload);
    return res.status(201).json(message);
  } catch {
    return res.status(500).json({ message: "Error sending request money message" });
  }
});

chatService.post("/accept", verifyToken, async (req: any, res) => {
  const tutorId = getAuthenticatedUserId(req)
  const message_id = req.body.message_id;
  try {
    await acceptRequestMoney(tutorId, message_id);
    res.status(200).json({message: "Successfully accepted request"});
  } catch {
    res.status(500).json({message: "Error Accept"});
  }
})

export default chatService;
