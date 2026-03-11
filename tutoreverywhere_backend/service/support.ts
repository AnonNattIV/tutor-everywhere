import express from "express";
import bodyParser from "body-parser";
import { verifyToken } from "../middleware/verify.ts";
import {
  archiveSupportTicket,
  ensureSupportTables,
  getOrCreateOpenSupportTicketForUser,
  getSupportTicketById,
  getSupportTicketDetails,
  listSupportMessages,
  listSupportTicketsByUserForAdmin,
  listSupportTicketsForUser,
  listSupportUsersForAdmin,
  sendSupportMessage,
} from "../controllers/support.ts";

const supportService = express.Router();

supportService.use(bodyParser.json());

ensureSupportTables().catch((err) => {
  console.error("Support table initialization failed", err);
});

function getAuthenticatedUserId(req: any) {
  const authData = req.body?.authData;
  return authData?.userId?.toString?.() ?? null;
}

function getAuthenticatedRole(req: any) {
  const authData = req.body?.authData;
  return authData?.role?.toString?.() ?? null;
}

function isOrdinaryRole(role: string | null) {
  return role === "student" || role === "tutor";
}

async function ensureTicketAccess(
  userId: string,
  role: string,
  ticketId: string,
) {
  const ticket = await getSupportTicketById(ticketId);
  if (!ticket) {
    return {
      ok: false,
      status: 404,
      body: { message: "Support ticket not found" },
    } as const;
  }

  const ticketUserId = ticket.user_id?.toString?.() ?? "";
  if (role !== "admin" && ticketUserId !== userId) {
    return {
      ok: false,
      status: 403,
      body: { message: "Forbidden support ticket access" },
    } as const;
  }

  return { ok: true, ticket } as const;
}

supportService.post("/tickets/start", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!isOrdinaryRole(role)) {
    return res
      .status(403)
      .json({ message: "Only student/tutor can start support ticket" });
  }

  try {
    const { ticket, created } = await getOrCreateOpenSupportTicketForUser(userId);
    const ticketId = ticket.ticket_id?.toString?.() ?? "";
    const details = ticketId ? await getSupportTicketDetails(ticketId) : null;
    return res.status(200).json({ ticket: details ?? ticket, created });
  } catch {
    return res.status(500).json({ message: "Error starting support ticket" });
  }
});

supportService.get("/tickets/mine", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!isOrdinaryRole(role)) {
    return res.status(403).json({ message: "Only student/tutor can view tickets" });
  }

  try {
    const tickets = await listSupportTicketsForUser(userId);
    return res.status(200).json(tickets);
  } catch {
    return res.status(500).json({ message: "Error loading support tickets" });
  }
});

supportService.get("/tickets/:ticketId/messages", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);
  const ticketId = req.params.ticketId?.toString?.() ?? "";

  if (!userId || !role) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!ticketId) {
    return res.status(400).json({ message: "Missing ticket id" });
  }

  try {
    const access = await ensureTicketAccess(userId, role, ticketId);
    if (!access.ok) {
      return res.status(access.status).json(access.body);
    }

    const ticket = await getSupportTicketDetails(ticketId);
    const messages = await listSupportMessages(ticketId);
    return res.status(200).json({ ticket, messages });
  } catch {
    return res.status(500).json({ message: "Error loading support messages" });
  }
});

supportService.post("/tickets/:ticketId/messages", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);
  const ticketId = req.params.ticketId?.toString?.() ?? "";

  if (!userId || !role) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!ticketId) {
    return res.status(400).json({ message: "Missing ticket id" });
  }

  try {
    const access = await ensureTicketAccess(userId, role, ticketId);
    if (!access.ok) {
      return res.status(access.status).json(access.body);
    }

    const status = access.ticket.status?.toString?.() ?? "";
    if (status === "archived") {
      return res.status(400).json({ message: "This support ticket is archived" });
    }

    const text = req.body.text?.toString?.().trim?.() ?? "";
    if (!text) {
      return res.status(400).json({ message: "Message cannot be empty" });
    }

    const message = await sendSupportMessage(ticketId, userId, text);
    return res.status(201).json(message);
  } catch {
    return res.status(500).json({ message: "Error sending support message" });
  }
});

supportService.post("/tickets/:ticketId/archive", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);
  const ticketId = req.params.ticketId?.toString?.() ?? "";

  if (!userId || !role) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!ticketId) {
    return res.status(400).json({ message: "Missing ticket id" });
  }

  try {
    const access = await ensureTicketAccess(userId, role, ticketId);
    if (!access.ok) {
      return res.status(access.status).json(access.body);
    }

    const ticket = await archiveSupportTicket(ticketId);
    return res.status(200).json(ticket);
  } catch {
    return res.status(500).json({ message: "Error archiving support ticket" });
  }
});

supportService.get("/admin/users", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);

  if (!userId || !role) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (role !== "admin") {
    return res.status(403).json({ message: "Admin only" });
  }

  try {
    const rows = await listSupportUsersForAdmin();
    return res.status(200).json(rows);
  } catch {
    return res.status(500).json({ message: "Error loading support users" });
  }
});

supportService.get("/admin/users/:userId/tickets", verifyToken, async (req: any, res) => {
  const userId = getAuthenticatedUserId(req);
  const role = getAuthenticatedRole(req);
  const ticketUserId = req.params.userId?.toString?.() ?? "";

  if (!userId || !role) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (role !== "admin") {
    return res.status(403).json({ message: "Admin only" });
  }

  if (!ticketUserId) {
    return res.status(400).json({ message: "Missing user id" });
  }

  try {
    const rows = await listSupportTicketsByUserForAdmin(ticketUserId);
    return res.status(200).json(rows);
  } catch {
    return res.status(500).json({ message: "Error loading user support tickets" });
  }
});

export default supportService;

