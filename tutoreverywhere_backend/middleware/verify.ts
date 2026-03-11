import dotenv from "dotenv/config";
import jwt from "jsonwebtoken";

let secretKey = process.env.AUTH_SECRET_KEY || "defaultKey";

function extractToken(authHeader?: string) {
  if (!authHeader) return "";

  const trimmedHeader = authHeader.trim();
  if (!trimmedHeader) return "";

  if (/^bearer\s+/i.test(trimmedHeader)) {
    return trimmedHeader.replace(/^bearer\s+/i, "").trim();
  }

  return trimmedHeader;
}

const verifyToken = function (req: any, res: any, next: any) {
  const authHeader = req.header("Authorization") || req.header("authorization");
  const token = extractToken(authHeader);

  if (!token) {
    return res.status(401).json({ message: "Missing authorization token" });
  }

  try {
    const verifiedPayload = jwt.verify(token, secretKey);
    if (!req.body) req.body = {};
    req.body.authData = verifiedPayload;
    return next();
  } catch (err) {
    console.error(err);
    return res.status(401).json({ message: "Invalid or expired authorization token" });
  }
};

export { verifyToken };
