import dotenv from "dotenv/config";
import jwt from "jsonwebtoken";

let secretKey = process.env.AUTH_SECRET_KEY || "defaultKey";

const verifyToken = function (req: any, res: any, next: any) {
  let getToken = req.header("Authorization")!.split(" ")[0];
  if (!getToken) return;

  try {
    const token = jwt.verify(getToken, secretKey);
    req.body = token;
    next();
  } catch (err) {
    console.error(err);
    return false;
  }
};

export { verifyToken };
