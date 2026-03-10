import express from "express"
import bodyParser from "body-parser";
import { verifyToken } from "../middleware/verify.ts";
import { getTutorRequiredVerifications } from "../controllers/verifications.ts";

const adminService = express.Router();

adminService.use(bodyParser.json());

adminService.get("/required-verifications", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  try {
    if (role != "admin") throw new Error(`This user ${userId} is not an admin`);
    const verifications = await getTutorRequiredVerifications();
    res.status(200).json(verifications);
  } catch (err) {
    res.status(500).json({message: "Error required verifications admin"});
  }
})

export default adminService