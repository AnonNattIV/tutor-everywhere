import express from "express"
import bodyParser from "body-parser";
import { viewStudentData, updateStudentBio, updateStudentProfilePicture } from "../controllers/students.ts";
import { verifyToken } from "../middleware/verify.ts";
import { upload } from "../middleware/multer.ts";
import path from "path";
import fs from "fs";
import { fileURLToPath } from 'url';
import { getAppointmentByStudentId } from "../controllers/appointments.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const uploadDir = path.join(__dirname, '../assets/pfp');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const studentService = express.Router();

studentService.use(bodyParser.json());
studentService.get("/profile/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorData = await viewStudentData(userId);
    res.status(200).json(tutorData[0]);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

studentService.patch(
  "/profile-picture",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body.authData;
    upload.single('profilePicture')(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res: any) => {
    const { userId, role } = req.body.authData;

    try {
      if (role !== "student") {
        return res.status(403).json({ message: `This user ${userId} is not a student` });
      }

      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const profilePicturePath = `assets/pfp/${req.file.filename}`;
      await updateStudentProfilePicture(userId, profilePicturePath);

      res.status(200).json({
        message: "Successfully updated profile picture",
        profilePicture: profilePicturePath
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Error uploading profile picture" });
    }
  }
);

studentService.post("/bio", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const bio = req.body.bio;
  try {
    if (role != "student") throw new Error(`This user ${userId} is not a student`);
    await updateStudentBio(userId, bio)
    res.status(200).json({message: "Successfully updated bio"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

studentService.get("/appointments/:userId", async (req, res) => {
  const query = req.query;
  const year = query.year?.toString();
  const month = query.month?.toString();
  const day = query.day?.toString();
  const formattedDateQuery = year + '-' + month + '-' + day;
  const params = req.params;
  const userId = params.userId;
  console.log(formattedDateQuery);
  try {
    const appointments = await getAppointmentByStudentId(userId, formattedDateQuery)
    res.status(200).json(appointments);
  } catch (err) {
    res.status(500).json({message: "Error find student appointment" });
  }
})

export default studentService